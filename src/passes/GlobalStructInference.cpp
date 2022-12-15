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
// Finds types which are only created in assignments to immutable globals. For
// such types we can replace a struct.get with a global.get when there is a
// single possible global, or if there are two then with this pattern:
//
//  (struct.get $foo i
//    (..ref..))
//  =>
//  (select
//    (value1)
//    (value2)
//    (ref.eq
//      (..ref..)
//      (global.get $global1)))
//
// That is a valid transformation if there are only two struct.news of $foo, it
// is created in two immutable globals $global1 and $global2, the field is
// immutable, the values of field |i| in them are value1 and value2
// respectively, and $foo has no subtypes. In that situation, the reference must
// be one of those two, so we can compare the reference to the globals and pick
// the right value there. (We can also handle subtypes, if we look at their
// values as well, see below.)
//
// The benefit of this optimization is primarily in the case of constant values
// that we can heavily optimize, like function references (constant function
// refs let us inline, etc.). Function references cannot be directly compared,
// so we cannot use ConstantFieldPropagation or such with an extension to
// multiple values, as the select pattern shown above can't be used - it needs a
// comparison. But we can compare structs, so if the function references are in
// vtables, and the vtables follow the above pattern, then we can optimize.
//
// TODO: Only do the case with a select when shrinkLevel == 0?
//

#include "ir/find_all.h"
#include "ir/module-utils.h"
#include "ir/subtypes.h"
#include "pass.h"
#include "wasm-builder.h"
#include "wasm.h"

namespace wasm {

namespace {

struct GlobalStructInference : public Pass {
  // Only modifies struct.get operations.
  bool requiresNonNullableLocalFixups() override { return false; }

  // Maps optimizable struct types to the globals whose init is a struct.new of
  // them. If a global is not present here, it cannot be optimized.
  std::unordered_map<HeapType, std::vector<Name>> typeGlobals;

  void run(Module* module) override {
    if (!module->features.hasGC()) {
      return;
    }

    // First, find all the information we need. We need to know which struct
    // types are created in functions, because we will not be able to optimize
    // those.

    using HeapTypes = std::unordered_set<HeapType>;

    ModuleUtils::ParallelFunctionAnalysis<HeapTypes> analysis(
      *module, [&](Function* func, HeapTypes& types) {
        if (func->imported()) {
          return;
        }

        for (auto* structNew : FindAll<StructNew>(func->body).list) {
          auto type = structNew->type;
          if (type.isRef()) {
            types.insert(type.getHeapType());
          }
        }
      });

    // We cannot optimize types that appear in a struct.new in a function, which
    // we just collected and merge now.
    HeapTypes unoptimizable;

    for (auto& [func, types] : analysis.map) {
      for (auto type : types) {
        unoptimizable.insert(type);
      }
    }

    // Process the globals.
    for (auto& global : module->globals) {
      if (global->imported()) {
        continue;
      }

      // We cannot optimize a type that appears in a non-toplevel location in a
      // global init.
      for (auto* structNew : FindAll<StructNew>(global->init).list) {
        auto type = structNew->type;
        if (type.isRef() && structNew != global->init) {
          unoptimizable.insert(type.getHeapType());
        }
      }

      if (!global->init->type.isRef()) {
        continue;
      }

      auto type = global->init->type.getHeapType();

      // The global's declared type must match the init's type. If not, say if
      // we had a global declared as type |any| but that contains (ref $A), then
      // that is not something we can optimize, as ref.eq on a global.get of
      // that global will not validate. (This should not be a problem after
      // GlobalSubtyping runs, which will specialize the type of the global.)
      if (global->type != global->init->type) {
        unoptimizable.insert(type);
        continue;
      }

      // We cannot optimize mutable globals.
      if (global->mutable_) {
        unoptimizable.insert(type);
        continue;
      }

      // Finally, if this is a struct.new then it is one we can optimize; note
      // it.
      if (global->init->is<StructNew>()) {
        typeGlobals[type].push_back(global->name);
      }
    }

    // A struct.get might also read from any of the subtypes. As a result, an
    // unoptimizable type makes all its supertypes unoptimizable as well.
    // TODO: this could be specific per field (and not all supers have all
    //       fields)
    for (auto type : unoptimizable) {
      while (1) {
        typeGlobals.erase(type);
        auto super = type.getSuperType();
        if (!super) {
          break;
        }
        type = *super;
      }
    }

    // Similarly, propagate global names: if one type has [global1], then a get
    // of any supertype might access that, so propagate to them.
    auto typeGlobalsCopy = typeGlobals;
    for (auto& [type, globals] : typeGlobalsCopy) {
      auto curr = type;
      while (1) {
        auto super = curr.getSuperType();
        if (!super) {
          break;
        }
        curr = *super;
        for (auto global : globals) {
          typeGlobals[curr].push_back(global);
        }
      }
    }

    if (typeGlobals.empty()) {
      // We found nothing we can optimize.
      return;
    }

    // The above loop on typeGlobalsCopy is on an unsorted data structure, and
    // that can lead to nondeterminism in typeGlobals. Sort the vectors there to
    // ensure determinism.
    for (auto& [type, globals] : typeGlobals) {
      std::sort(globals.begin(), globals.end());
    }

    // Optimize based on the above.
    struct FunctionOptimizer
      : public WalkerPass<PostWalker<FunctionOptimizer>> {
      bool isFunctionParallel() override { return true; }

      std::unique_ptr<Pass> create() override {
        return std::make_unique<FunctionOptimizer>(parent);
      }

      FunctionOptimizer(GlobalStructInference& parent) : parent(parent) {}

      void visitStructGet(StructGet* curr) {
        auto type = curr->ref->type;
        if (type == Type::unreachable) {
          return;
        }

        auto heapType = type.getHeapType();
        auto iter = parent.typeGlobals.find(heapType);
        if (iter == parent.typeGlobals.end()) {
          return;
        }

        // This cannot be a bottom type as we found it in the typeGlobals map,
        // which only contains types of struct.news.
        assert(heapType.isStruct());

        // The field must be immutable.
        auto fieldIndex = curr->index;
        auto& field = heapType.getStruct().fields[fieldIndex];
        if (field.mutable_ == Mutable) {
          return;
        }

        const auto& globals = iter->second;
        if (globals.size() == 0) {
          return;
        }

        auto& wasm = *getModule();
        Builder builder(wasm);

        if (globals.size() == 1) {
          // Leave it to other passes to infer the constant value of the field,
          // if there is one: just change the reference to the global, which
          // will unlock those other optimizations. Note we must trap if the ref
          // is null, so add RefAsNonNull here.
          auto global = globals[0];
          curr->ref = builder.makeSequence(
            builder.makeDrop(builder.makeRefAs(RefAsNonNull, curr->ref)),
            builder.makeGlobalGet(global, wasm.getGlobal(globals[0])->type));
          return;
        }

        // We are looking for the case where we can pick between two values
        // using a single comparison. More than two values, or more than a
        // single comparison, add tradeoffs that may not be worth it, and a
        // single value (or no value) is already handled by other passes.
        //
        // That situation may involve more than two globals. For example we may
        // have three relevant globals, but two may have the same value. In that
        // case we can compare against the third:
        //
        //  $global0: (struct.new $Type (i32.const 42))
        //  $global1: (struct.new $Type (i32.const 42))
        //  $global2: (struct.new $Type (i32.const 1337))
        //
        // (struct.get $Type (ref))
        //   =>
        // (select
        //   (i32.const 1337)
        //   (i32.const 42)
        //   (ref.eq (ref) $global2))

        // Find the constant values and which globals correspond to them.
        // TODO: SmallVectors?
        std::vector<Literal> values;
        std::vector<std::vector<Name>> globalsForValue;

        // Check if the relevant fields contain constants.
        auto fieldType = field.type;
        for (Index i = 0; i < globals.size(); i++) {
          Name global = globals[i];
          auto* structNew = wasm.getGlobal(global)->init->cast<StructNew>();
          Literal value;
          if (structNew->isWithDefault()) {
            value = Literal::makeZero(fieldType);
          } else {
            auto* init = structNew->operands[fieldIndex];
            if (!Properties::isConstantExpression(init)) {
              // Non-constant; give up entirely.
              return;
            }
            value = Properties::getLiteral(init);
          }

          // Process the current value, comparing it against the previous.
          auto found = std::find(values.begin(), values.end(), value);
          if (found == values.end()) {
            // This is a new value.
            assert(values.size() <= 2);
            if (values.size() == 2) {
              // Adding this value would mean we have too many, so give up.
              return;
            }
            values.push_back(value);
            globalsForValue.push_back({global});
          } else {
            // This is an existing value.
            Index index = found - values.begin();
            globalsForValue[index].push_back(global);
          }
        }

        // We have some globals (at least 2), and so must have at least one
        // value. And we have already exited if we have more than 2 values (see
        // the early return above) so that only leaves 1 and 2.
        if (values.size() == 1) {
          // The case of 1 value is simple: trap if the ref is null, and
          // otherwise return the value.
          replaceCurrent(builder.makeSequence(
            builder.makeDrop(builder.makeRefAs(RefAsNonNull, curr->ref)),
            builder.makeConstantExpression(values[0])));
          return;
        }
        assert(values.size() == 2);

        // We have two values. Check that we can pick between them using a
        // single comparison. While doing so, ensure that the index we can check
        // on is 0, that is, the first value has a single global.
        if (globalsForValue[0].size() == 1) {
          // The checked global is already in index 0.
        } else if (globalsForValue[1].size() == 1) {
          std::swap(values[0], values[1]);
          std::swap(globalsForValue[0], globalsForValue[1]);
        } else {
          // Both indexes have more than one option, so we'd need more than one
          // comparison. Give up.
          return;
        }

        // Excellent, we can optimize here! Emit a select.
        //
        // Note that we must trap on null, so add a ref.as_non_null here.
        auto checkGlobal = globalsForValue[0][0];
        replaceCurrent(builder.makeSelect(
          builder.makeRefEq(builder.makeRefAs(RefAsNonNull, curr->ref),
                            builder.makeGlobalGet(
                              checkGlobal, wasm.getGlobal(checkGlobal)->type)),
          builder.makeConstantExpression(values[0]),
          builder.makeConstantExpression(values[1])));
      }

      // Information regarding an expression that might be equal to a global.
      struct SingletonGlobalInfo {
        // If set, this is the name of a global that the expression must be
        // equal to (or possibly null, see below).
        std::optional<Name> global;

        // Whether this can be null or not.
        bool null;

        SingletonGlobalInfo(Type type) : null(type.isNullable()) {}
      };

      SingletonGlobalInfo getSingletonGlobalInfo(Type type) {
        SingletonGlobalInfo info(type);

        if (!type.isRef()) {
          return info;
        }

        auto heapType = type.getHeapType();
        auto iter = parent.typeGlobals.find(heapType);
        if (iter == parent.typeGlobals.end()) {
          return info;
        }

        const auto& globals = iter->second;
        if (globals.size() != 1) {
          return info;
        }

        info.global = globals[0];
        return info;
      }

      SingletonGlobalInfo getSingletonGlobalInfo(Expression* curr) {
        return getSingletonGlobalInfo(curr->type);
      }

      void visitRefCast(RefCast* curr) {
        if (!getPassOptions().trapsNeverHappen) {
          // TODO: Optimize without this assumption (which is less efficient/
          //       simple).
          return;
        }

        // Find information about whether the intended type has only a single
        // relevant global that fits that type.
        auto info = getSingletonGlobalInfo(curr->type);

        if (!info.global) {
          // This cast does not refer to a single global.
          return;
        }

        auto global = *info.global;
        auto globalType = getModule()->getGlobal(global)->type;

        Builder builder(*getModule());

        // As we assume traps never happen, we know that we flow out either a
        // null or the singleton possible global.
        if (curr->ref->type.isNullable()) {
          replaceCurrent(
            builder.makeSelect(builder.makeRefIs(RefIsNull, curr->ref),
                               builder.makeRefNull(curr->intendedType),
                               builder.makeGlobalGet(global, globalType)));
        } else {
          replaceCurrent(
            builder.makeSequence(builder.makeDrop(curr->ref),
                                 builder.makeGlobalGet(global, globalType)));
        }
      }

      void visitRefEq(RefEq* curr) {
        auto left = getSingletonGlobalInfo(curr->left);
        auto right = getSingletonGlobalInfo(curr->right);

        Builder builder(*getModule());

        if (left.global && right.global && left.global == right.global &&
            !left.null && !right.null) {
          // The same global appears on both sides.
          replaceCurrent(builder.makeBlock({builder.makeDrop(curr->left),
                                            builder.makeDrop(curr->right),
                                            builder.makeConst(int32_t(1))}));
          return;
        }

        // If an arm is equal to a singleton global, replace it with that.
        auto maybeReplaceWithGlobal = [&](const SingletonGlobalInfo& info,
                                          Expression*& arm) {
          if (arm->is<GlobalGet>()) {
            // Don't repeat work: our output here is a global.get, so if we are
            // already in that form, do nothing.
            return;
          }
          if (info.global && !info.null) {
            auto global = *info.global;
            arm = builder.makeSequence(
              builder.makeDrop(arm),
              builder.makeGlobalGet(global,
                                    getModule()->getGlobal(global)->type));
            return;
          }
        };

        // One or both of the sides may be equal to a known singleton global.
        // Replace them if so. Later optimizations can then do things like turn
        // globalA == globalB into a constant 0 or 1.
        maybeReplaceWithGlobal(left, curr->left);
        maybeReplaceWithGlobal(right, curr->right);

        if (left.global && right.global && left.global != right.global &&
            !(left.null && right.null)) {
          // We have two different globals, and both cannot be null. These
          // cannot be equal: both cannot be null, and the only non-null
          // possible values differ on each side.
          replaceCurrent(builder.makeBlock({builder.makeDrop(curr->left),
                                            builder.makeDrop(curr->right),
                                            builder.makeConst(int32_t(0))}));
          return;
        }

        // We could also optimize the case of the same global on both sides,
        // plus a possible null on one side. In that case we can just check if
        // the nullable side is not a null (if it isn't, they are equal).
        // However, it's not clear that is beneficial: we'd need to replace a
        // single RefEq with a RefIsNull + EqZ, which is two operations, so
        // ignore that case.
      }

    private:
      GlobalStructInference& parent;
    };

    FunctionOptimizer(*this).run(getPassRunner(), module);
  }
};

} // anonymous namespace

Pass* createGlobalStructInferencePass() { return new GlobalStructInference(); }

} // namespace wasm
