/*
 * Copyright 2022 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// Find struct fields that are always equal, and convert all reads to the first
// of them. For example:
//
//   x = new Foo(a: 5, b: 5);
//   y = new Foo(a: 7, b: 7);
//
// The fields a and b are always equal, so we can read either one to get the
// value, which means we can do this:
//
//   x.b  =>  x.a
//   y.b  =>  y.a
//
// By always reading from the earlier field we increase the chance for the later
// field to be pruned as unused.
//

#include "ir/module-utils.h"
#include "ir/possible-constant.h"
#include "pass.h"
#include "support/small_set.h"
#include "wasm-builder.h"
#include "wasm.h"

namespace wasm {

namespace {

// To find things we can optimize, we focus on pairs of immutable fields that
// always - in all struct.news - begin identical. We find all such pairs in each
// struct.new by scanning all the code, then we'll merge that together and
// optimize using that information.

struct IndexPair {
  // A pair of indexes (of fields), canonicalized to be in order.
  Index low;
  Index high;
  IndexPair(Index low, Index high) : low(low), high(high) {
    assert(low <= high);
  }
};

using EquivalentFields = std::unordered_set<IndexPair>;

using EquivalentFieldsMap = std::unordered_map<HeapType, EquilvalentFields>;

struct FieldFinder : public PostWalker<FieldFinder> {
  EquivalentFieldsMap map;

  void visitStructNew(StructNew* curr) {
    if (curr->type == Type::unreachable) {
      return;
    }

    // Find pairs of immutable fields with equal values.
    auto& fields = curr->type.getHeapType().getStruct().fields;
    for (Index i = 0; i < fields.size(); i++) {
      auto& iField = fields[i];
      if (iField.mutability == Mutable) {
        continue;
      }
      for (Index j = i + 1; j < fields.size(); j++) {
        auto& jField = fields[j];
        if (jField.mutability == Mutable) {
          continue;
        }

        // Great, fields i and j are both immutable.

        // See if they have the same declaration (type and packing).
        if (iField != jField) {
          continue;
        }

        // Finally, see if their values match.
        if (curr->isWithDefault() || areEqual(curr->operands, i, j)) {
          map[curr->type.getHeapType()].insert(IndexPair(i, j));
        }
      }
    }
  }

  bool areEqual(const ExpressionList& list, Index i, Index j) {
    // TODO Handle more cases like a tee and a get (with nothing in the middle).
    //      See related code in OptimizeInstructions that can perhaps be
    //      shared. For now just handle immutable globals and constants.
    PossibleConstantValues iValue;
    iValue.note(list[i], module);
    if (!iValue.isConstantLiteral() && !iValue.isConstantGlobal()) {
      return false;
    }
    PossibleConstantValues jValue;
    iValue.note(list[j], module);
    return iValue == jValue;
  }
};

struct EquivalentFieldOptimization : public Pass {
  // Only modifies types.
  bool requiresNonNullableLocalFixups() override { return false; }

  Module* module;

  // The types we can merge. We map each such type to merge with the type we
  // want to merge it with.
  using TypeUpdates = std::unordered_map<HeapType, HeapType>;
  TypeUpdates merges;

  void run(Module* module_) override {
    module = module_;

    if (!module->features.hasGC()) {
      return;
    }

    // First, find all the cast types.

    ModuleUtils::ParallelFunctionAnalysis<ReferredTypes> analysis(
      *module, [&](Function* func, ReferredTypes& referredTypes) {
        if (func->imported()) {
          return;
        }

        FieldFinder finder;
        finder.walk(func->body);
        referredTypes = std::move(finder.referredTypes);
      });

    // Also find cast types in the module scope (not possible in the current
    // spec, but do it to be future-proof).
    FieldFinder moduleFinder;
    moduleFinder.walkModuleCode(module);

    // Accumulate all the referredTypes.
    auto& allReferredTypes = moduleFinder.referredTypes;
    for (auto& [k, referredTypes] : analysis.map) {
      for (auto type : referredTypes) {
        allReferredTypes.insert(type);
      }
    }

    // Find all the heap types.
    std::vector<HeapType> types = ModuleUtils::collectHeapTypes(*module);

    // TODO: There may be more opportunities after this loop. Imagine that we
    //       decide to merge A and B into C, and there are types X and Y that
    //       contain a nested reference to A and B respectively, then after A
    //       and B become identical so do X and Y. The recursive case is not
    //       trivial, however, and needs more thought.
    for (auto type : types) {
      if (allReferredTypes.count(type)) {
        // This has a cast, so it is distinguishable nominally.
        continue;
      }

      auto super = type.getSuperType();
      if (!super) {
        // This has no supertype, so there is nothing to merge it into.
        continue;
      }

      if (type.isStruct()) {
        auto& fields = type.getStruct().fields;
        auto& superFields = super->getStruct().fields;
        if (fields == superFields) {
          // We can merge! This is identical structurally to the super, and also
          // not distinguishable nominally.
          merges[type] = *super;
        }
      } else if (type.isArray()) {
        auto element = type.getArray().element;
        auto superElement = super->getArray().element;
        if (element == superElement) {
          merges[type] = *super;
        }
      }
    }

    if (merges.empty()) {
      return;
    }

    // We found things to optimize! Rewrite types in the module to apply those
    // changes.

    // First, close over the map, so if X can be merged into Y and Y into Z then
    // we map X into Z.
    for (auto type : types) {
      if (!merges.count(type)) {
        continue;
      }

      auto newType = merges[type];
      while (merges.count(newType)) {
        newType = merges[newType];
      }
      // Apply the findings to all intermediate types as well, to avoid
      // duplicate work in later iterations. That is, all the types we saw in
      // the above loop will all get merged into newType.
      auto curr = type;
      while (1) {
        auto iter = merges.find(curr);
        if (iter == merges.end()) {
          break;
        }
        auto& currMerge = iter->second;
        curr = currMerge;
        currMerge = newType;
      }
    }

    // Apply the merges.

    class TypeInternalsUpdater : public GlobalTypeRewriter {
      const TypeUpdates& merges;

      std::unordered_map<HeapType, Signature> newSignatures;

    public:
      TypeInternalsUpdater(Module& wasm, const TypeUpdates& merges)
        : GlobalTypeRewriter(wasm), merges(merges) {

        // Map the types of expressions (curr->type, etc.) to their merged
        // types.
        mapTypes(merges);

        // Update the internals of types (struct fields, signatures, etc.) to
        // refer to the merged types.
        update();
      }

      Type getNewType(Type type) {
        if (!type.isRef()) {
          return type;
        }
        auto heapType = type.getHeapType();
        auto iter = merges.find(heapType);
        if (iter != merges.end()) {
          return getTempType(Type(iter->second, type.getNullability()));
        }
        return getTempType(type);
      }

      void modifyStruct(HeapType oldType, Struct& struct_) override {
        auto& oldFields = oldType.getStruct().fields;
        for (Index i = 0; i < oldFields.size(); i++) {
          auto& oldField = oldFields[i];
          auto& newField = struct_.fields[i];
          newField.type = getNewType(oldField.type);
        }
      }
      void modifyArray(HeapType oldType, Array& array) override {
        array.element.type = getNewType(oldType.getArray().element.type);
      }
      void modifySignature(HeapType oldSignatureType, Signature& sig) override {
        auto getUpdatedTypeList = [&](Type type) {
          std::vector<Type> vec;
          for (auto t : type) {
            vec.push_back(getNewType(t));
          }
          return getTempTupleType(vec);
        };

        auto oldSig = oldSignatureType.getSignature();
        sig.params = getUpdatedTypeList(oldSig.params);
        sig.results = getUpdatedTypeList(oldSig.results);
      }
    } rewriter(*module, merges);
  }
};

} // anonymous namespace

Pass* createEquivalentFieldOptimizationPass() { return new EquivalentFieldOptimization(); }

} // namespace wasm
