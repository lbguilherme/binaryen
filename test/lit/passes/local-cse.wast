;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; NOTE: This test was ported using port_test.py and could be cleaned up.

;; RUN: foreach %s %t wasm-opt --local-cse -S -o - | filecheck %s
;; RUN: foreach %s %t wasm-opt --cse       -S -o - | filecheck %s --check-prefix NONLC

(module
  (memory 100 100)
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (type $i32_=>_none (func (param i32)))

  ;; CHECK:      (type $i32_=>_i32 (func (param i32) (result i32)))

  ;; CHECK:      (type $none_=>_i64 (func (result i64)))

  ;; CHECK:      (memory $0 100 100)

  ;; CHECK:      (func $basics
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local $y i32)
  ;; CHECK-NEXT:  (local $2 i32)
  ;; CHECK-NEXT:  (local $3 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $2
  ;; CHECK-NEXT:    (i32.add
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:     (i32.const 2)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (nop)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (i32.const 1)
  ;; CHECK-NEXT:    (i32.const 2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $3
  ;; CHECK-NEXT:    (i32.add
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:     (local.get $y)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call $basics)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (i32.const 100)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:    (local.get $y)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (type $none_=>_none (func))

  ;; NONLC:      (type $i32_=>_none (func (param i32)))

  ;; NONLC:      (type $i32_=>_i32 (func (param i32) (result i32)))

  ;; NONLC:      (type $none_=>_i64 (func (result i64)))

  ;; NONLC:      (memory $0 100 100)

  ;; NONLC:      (func $basics
  ;; NONLC-NEXT:  (local $x i32)
  ;; NONLC-NEXT:  (local $y i32)
  ;; NONLC-NEXT:  (local $2 i32)
  ;; NONLC-NEXT:  (local $3 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $3
  ;; NONLC-NEXT:    (i32.add
  ;; NONLC-NEXT:     (i32.const 1)
  ;; NONLC-NEXT:     (i32.const 2)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $3)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (i32.const 0)
  ;; NONLC-NEXT:   (nop)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $3)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $2
  ;; NONLC-NEXT:    (i32.add
  ;; NONLC-NEXT:     (local.get $x)
  ;; NONLC-NEXT:     (local.get $y)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (call $basics)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (local.set $x
  ;; NONLC-NEXT:   (i32.const 100)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (local.get $x)
  ;; NONLC-NEXT:    (local.get $y)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $basics
    (local $x i32)
    (local $y i32)
    ;; These two adds can be optimized.
    (drop
      (i32.add (i32.const 1) (i32.const 2))
    )
    (drop
      (i32.add (i32.const 1) (i32.const 2))
    )
    (if (i32.const 0) (nop))
    ;; This add is after an if, which means we are no longer in the same basic
    ;; block - which means we cannot optimize it with the previous identical
    ;; adds.
    (drop
      (i32.add (i32.const 1) (i32.const 2))
    )
    ;; More adds with different contents than the previous, but all three are
    ;; identical.
    (drop
      (i32.add (local.get $x) (local.get $y))
    )
    (drop
      (i32.add (local.get $x) (local.get $y))
    )
    (drop
      (i32.add (local.get $x) (local.get $y))
    )
    ;; Calls have side effects, but that is not a problem for these adds which
    ;; only use locals, so we can optimize the add after the call.
    (call $basics)
    (drop
      (i32.add (local.get $x) (local.get $y))
    )
    ;; Modify $x, which means we cannot optimize the add after the set.
    (local.set $x (i32.const 100))
    (drop
      (i32.add (local.get $x) (local.get $y))
    )
  )

  ;; CHECK:      (func $recursive1
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local $y i32)
  ;; CHECK-NEXT:  (local $2 i32)
  ;; CHECK-NEXT:  (local $3 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $3
  ;; CHECK-NEXT:    (i32.add
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:     (local.tee $2
  ;; CHECK-NEXT:      (i32.add
  ;; CHECK-NEXT:       (i32.const 2)
  ;; CHECK-NEXT:       (i32.const 3)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $recursive1
  ;; NONLC-NEXT:  (local $x i32)
  ;; NONLC-NEXT:  (local $y i32)
  ;; NONLC-NEXT:  (local $2 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (i32.const 1)
  ;; NONLC-NEXT:    (local.tee $2
  ;; NONLC-NEXT:     (i32.add
  ;; NONLC-NEXT:      (i32.const 2)
  ;; NONLC-NEXT:      (i32.const 3)
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (i32.const 1)
  ;; NONLC-NEXT:    (local.get $2)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $recursive1
    (local $x i32)
    (local $y i32)
    ;; The first two dropped things are identical and can be optimized.
    (drop
      (i32.add
        (i32.const 1)
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
      )
    )
    (drop
      (i32.add
        (i32.const 1)
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
      )
    )
    ;; The last thing here appears inside the previous pattern, and can still
    ;; be optimized, with another local.
    (drop
      (i32.add
        (i32.const 2)
        (i32.const 3)
      )
    )
  )

  ;; CHECK:      (func $recursive2
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local $y i32)
  ;; CHECK-NEXT:  (local $2 i32)
  ;; CHECK-NEXT:  (local $3 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $3
  ;; CHECK-NEXT:    (i32.add
  ;; CHECK-NEXT:     (i32.const 1)
  ;; CHECK-NEXT:     (local.tee $2
  ;; CHECK-NEXT:      (i32.add
  ;; CHECK-NEXT:       (i32.const 2)
  ;; CHECK-NEXT:       (i32.const 3)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $recursive2
  ;; NONLC-NEXT:  (local $x i32)
  ;; NONLC-NEXT:  (local $y i32)
  ;; NONLC-NEXT:  (local $2 i32)
  ;; NONLC-NEXT:  (local $3 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $2
  ;; NONLC-NEXT:    (i32.add
  ;; NONLC-NEXT:     (i32.const 1)
  ;; NONLC-NEXT:     (local.tee $3
  ;; NONLC-NEXT:      (i32.add
  ;; NONLC-NEXT:       (i32.const 2)
  ;; NONLC-NEXT:       (i32.const 3)
  ;; NONLC-NEXT:      )
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $3)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $recursive2
    (local $x i32)
    (local $y i32)
    ;; As before, but the order is different, with the sub-pattern in the
    ;; middle.
    (drop
      (i32.add
        (i32.const 1)
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
      )
    )
    (drop
      (i32.add
        (i32.const 2)
        (i32.const 3)
      )
    )
    (drop
      (i32.add
        (i32.const 1)
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
      )
    )
  )

  ;; CHECK:      (func $self
  ;; CHECK-NEXT:  (local $x i32)
  ;; CHECK-NEXT:  (local $y i32)
  ;; CHECK-NEXT:  (local $2 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (local.tee $2
  ;; CHECK-NEXT:     (i32.add
  ;; CHECK-NEXT:      (i32.const 2)
  ;; CHECK-NEXT:      (i32.const 3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.get $2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $self
  ;; NONLC-NEXT:  (local $x i32)
  ;; NONLC-NEXT:  (local $y i32)
  ;; NONLC-NEXT:  (local $2 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (local.tee $2
  ;; NONLC-NEXT:     (i32.add
  ;; NONLC-NEXT:      (i32.const 2)
  ;; NONLC-NEXT:      (i32.const 3)
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:    (local.get $2)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $2)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $self
    (local $x i32)
    (local $y i32)
    ;; As before, with just the large pattern and the sub pattern, but no
    ;; repeats of the large pattern.
    (drop
      (i32.add
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
        (i32.add
          (i32.const 2)
          (i32.const 3)
        )
      )
    )
    (drop
      (i32.add
        (i32.const 2)
        (i32.const 3)
      )
    )
  )

  ;; CHECK:      (func $loads
  ;; CHECK-NEXT:  (local $0 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $0
  ;; CHECK-NEXT:    (i32.load
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $loads
  ;; NONLC-NEXT:  (local $0 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $0
  ;; NONLC-NEXT:    (i32.load
  ;; NONLC-NEXT:     (i32.const 10)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $0)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $loads
    ;; The possible trap on loads does not prevent optimization, since if we
    ;; trap then it doesn't matter that we replaced the later expression.
    (drop
      (i32.load (i32.const 10))
    )
    (drop
      (i32.load (i32.const 10))
    )
  )

  ;; CHECK:      (func $calls (param $x i32) (result i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $calls
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $calls
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (i32.const 10)
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $calls (param $x i32) (result i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (call $calls
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (call $calls
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (i32.const 10)
  ;; NONLC-NEXT: )
  (func $calls (param $x i32) (result i32)
    ;; The side effects of calls prevent optimization.
    (drop
      (call $calls (i32.const 10))
    )
    (drop
      (call $calls (i32.const 10))
    )
    (i32.const 10)
  )

  ;; CHECK:      (func $many-sets (result i64)
  ;; CHECK-NEXT:  (local $temp i64)
  ;; CHECK-NEXT:  (local $1 i64)
  ;; CHECK-NEXT:  (local.set $temp
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (i64.add
  ;; CHECK-NEXT:     (i64.const 1)
  ;; CHECK-NEXT:     (i64.const 2)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $temp
  ;; CHECK-NEXT:   (i64.const 9999)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $temp
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.get $temp)
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $many-sets (result i64)
  ;; NONLC-NEXT:  (local $temp i64)
  ;; NONLC-NEXT:  (local $1 i64)
  ;; NONLC-NEXT:  (local.set $temp
  ;; NONLC-NEXT:   (local.tee $1
  ;; NONLC-NEXT:    (i64.add
  ;; NONLC-NEXT:     (i64.const 1)
  ;; NONLC-NEXT:     (i64.const 2)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (local.set $temp
  ;; NONLC-NEXT:   (i64.const 9999)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (local.set $temp
  ;; NONLC-NEXT:   (local.get $1)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (local.get $temp)
  ;; NONLC-NEXT: )
  (func $many-sets (result i64)
    (local $temp i64)
    ;; Assign to $temp three times here. We can optimize the add regardless of
    ;; that, and should not be confused by the sets themselves having effects
    ;; that are in conflict (the value is what matters).
    (local.set $temp
      (i64.add
        (i64.const 1)
        (i64.const 2)
      )
    )
    (local.set $temp
      (i64.const 9999)
    )
    (local.set $temp
      (i64.add
        (i64.const 1)
        (i64.const 2)
      )
    )
    (local.get $temp)
  )

  ;; CHECK:      (func $switch-children (param $x i32) (result i32)
  ;; CHECK-NEXT:  (local $1 i32)
  ;; CHECK-NEXT:  (block $label$1 (result i32)
  ;; CHECK-NEXT:   (br_table $label$1 $label$1
  ;; CHECK-NEXT:    (local.tee $1
  ;; CHECK-NEXT:     (i32.and
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:      (i32.const 3)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $switch-children (param $x i32) (result i32)
  ;; NONLC-NEXT:  (local $1 i32)
  ;; NONLC-NEXT:  (block $label$1 (result i32)
  ;; NONLC-NEXT:   (br_table $label$1 $label$1
  ;; NONLC-NEXT:    (local.tee $1
  ;; NONLC-NEXT:     (i32.and
  ;; NONLC-NEXT:      (local.get $x)
  ;; NONLC-NEXT:      (i32.const 3)
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:    (local.get $1)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $switch-children (param $x i32) (result i32)
    (block $label$1 (result i32)
      ;; We can optimize the two children of this switch. This test verifies
      ;; that we do so properly and do not hit an assertion involving the
      ;; ordering of the switch's children, which was incorrect in the past.
      (br_table $label$1 $label$1
        (i32.and
          (local.get $x)
          (i32.const 3)
        )
        (i32.and
          (local.get $x)
          (i32.const 3)
        )
      )
    )
  )

  ;; CHECK:      (func $dominated (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.load
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $dominated (param $x i32)
  ;; NONLC-NEXT:  (local $1 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $1
  ;; NONLC-NEXT:    (i32.load
  ;; NONLC-NEXT:     (i32.const 10)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (local.get $x)
  ;; NONLC-NEXT:   (drop
  ;; NONLC-NEXT:    (local.get $1)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $dominated (param $x i32)
    ;; This load is not in the same basic block as the later one, but it
    ;; dominates it, so we can optimize here in cse (but not local-cse).
    (drop
      (i32.load (i32.const 10))
    )
    (if
      (local.get $x)
      (drop
        (i32.load (i32.const 10))
      )
    )
  )

  ;; CHECK:      (func $dominated-if-condition
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.load
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $dominated-if-condition
  ;; NONLC-NEXT:  (local $0 i32)
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (local.tee $0
  ;; NONLC-NEXT:    (i32.load
  ;; NONLC-NEXT:     (i32.const 10)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:   (drop
  ;; NONLC-NEXT:    (local.get $0)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $dominated-if-condition
    ;; As above, but now the load is in the if condition, which still works.
    (if
      (i32.load (i32.const 10))
      (drop
        (i32.load (i32.const 10))
      )
    )
  )

  ;; CHECK:      (func $dominated-if-condition-interference
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (block $block
  ;; CHECK-NEXT:    (call $basics)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.load
  ;; CHECK-NEXT:      (i32.const 10)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $dominated-if-condition-interference
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (i32.load
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:   (block $block
  ;; NONLC-NEXT:    (call $basics)
  ;; NONLC-NEXT:    (drop
  ;; NONLC-NEXT:     (i32.load
  ;; NONLC-NEXT:      (i32.const 10)
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $dominated-if-condition-interference
    (if
      (i32.load (i32.const 10))
      (block
        ;; This call interferes along the path between the two loads.
        (call $basics)
        (drop
          (i32.load (i32.const 10))
        )
      )
    )
  )

  ;; CHECK:      (func $dominated-if-condition-interference-later
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (call $basics)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $dominated-if-condition-interference-later
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (i32.load
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:   (call $basics)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.load
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $dominated-if-condition-interference-later
    (if
      (i32.load (i32.const 10))
      ;; This call interferes along the path between the two loads.
      (call $basics)
    )
    (drop
      (i32.load (i32.const 10))
    )
  )

  ;; CHECK:      (func $dominated-if-condition-later
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:   (nop)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $dominated-if-condition-later
  ;; NONLC-NEXT:  (local $0 i32)
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (local.tee $0
  ;; NONLC-NEXT:    (i32.load
  ;; NONLC-NEXT:     (i32.const 10)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:   (nop)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $0)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $dominated-if-condition-later
    (if
      (i32.load (i32.const 10))
      ;; As before, but the call is removed, so we can optimize.
      (nop)
    )
    (drop
      (i32.load (i32.const 10))
    )
  )

  ;; CHECK:      (func $non-dominated-if-condition-later (param $x i32)
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:   (drop
  ;; CHECK-NEXT:    (i32.load
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.load
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $non-dominated-if-condition-later (param $x i32)
  ;; NONLC-NEXT:  (if
  ;; NONLC-NEXT:   (local.get $x)
  ;; NONLC-NEXT:   (drop
  ;; NONLC-NEXT:    (i32.load
  ;; NONLC-NEXT:     (i32.const 10)
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.load
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $non-dominated-if-condition-later (param $x i32)
    (if
      (local.get $x)
      ;; This load does not dominate the later load, sadly.
      (drop
        (i32.load (i32.const 10))
      )
    )
    (drop
      (i32.load (i32.const 10))
    )
  )

  ;; CHECK:      (func $large-with-control-flow (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (i32.eqz
  ;; CHECK-NEXT:       (i32.eqz
  ;; CHECK-NEXT:        (i32.eqz
  ;; CHECK-NEXT:         (i32.const 20)
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if (result i32)
  ;; CHECK-NEXT:     (i32.add
  ;; CHECK-NEXT:      (i32.const 30)
  ;; CHECK-NEXT:      (i32.const 40)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 50)
  ;; CHECK-NEXT:     (i32.sub
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:      (i32.const 60)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block0 (result i32)
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.const 10)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (i32.eqz
  ;; CHECK-NEXT:      (i32.eqz
  ;; CHECK-NEXT:       (i32.eqz
  ;; CHECK-NEXT:        (i32.eqz
  ;; CHECK-NEXT:         (i32.const 20)
  ;; CHECK-NEXT:        )
  ;; CHECK-NEXT:       )
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (if (result i32)
  ;; CHECK-NEXT:     (i32.add
  ;; CHECK-NEXT:      (i32.const 30)
  ;; CHECK-NEXT:      (i32.const 40)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:     (i32.const 50)
  ;; CHECK-NEXT:     (i32.sub
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:      (i32.const 60)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $large-with-control-flow (param $x i32)
  ;; NONLC-NEXT:  (local $1 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $1
  ;; NONLC-NEXT:    (block $block (result i32)
  ;; NONLC-NEXT:     (drop
  ;; NONLC-NEXT:      (i32.const 10)
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:     (drop
  ;; NONLC-NEXT:      (i32.eqz
  ;; NONLC-NEXT:       (i32.eqz
  ;; NONLC-NEXT:        (i32.eqz
  ;; NONLC-NEXT:         (i32.eqz
  ;; NONLC-NEXT:          (i32.const 20)
  ;; NONLC-NEXT:         )
  ;; NONLC-NEXT:        )
  ;; NONLC-NEXT:       )
  ;; NONLC-NEXT:      )
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:     (if (result i32)
  ;; NONLC-NEXT:      (i32.add
  ;; NONLC-NEXT:       (i32.const 30)
  ;; NONLC-NEXT:       (i32.const 40)
  ;; NONLC-NEXT:      )
  ;; NONLC-NEXT:      (i32.const 50)
  ;; NONLC-NEXT:      (i32.sub
  ;; NONLC-NEXT:       (local.get $x)
  ;; NONLC-NEXT:       (i32.const 60)
  ;; NONLC-NEXT:      )
  ;; NONLC-NEXT:     )
  ;; NONLC-NEXT:    )
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $1)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $large-with-control-flow (param $x i32)
    (drop
      (block (result i32)
        (drop
          (i32.const 10)
        )
        (drop
          (i32.eqz
            (i32.eqz
              (i32.eqz
                (i32.eqz
                  (i32.const 20)
                )
              )
            )
          )
        )
        (if (result i32)
          (i32.add
            (i32.const 30)
            (i32.const 40)
          )
          (i32.const 50)
          (i32.sub
            (local.get $x)
            (i32.const 60)
          )
        )
      )
    )

    (drop
      (block (result i32)
        (drop
          (i32.const 10)
        )
        (drop
          (i32.eqz
            (i32.eqz
              (i32.eqz
                (i32.eqz
                  (i32.const 20)
                )
              )
            )
          )
        )
        (if (result i32)
          (i32.add
            (i32.const 30)
            (i32.const 40)
          )
          (i32.const 50)
          (i32.sub
            (local.get $x)
            (i32.const 60)
          )
        )
      )
    )
  )

  ;; CHECK:      (func $unreachable-1
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $unreachable-1
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $unreachable-1
    ;; We should not optimize unreachable code.
    (drop
      (i32.add
        (unreachable)
        (i32.const 10)
      )
    )
    (drop
      (i32.add
        (unreachable)
        (i32.const 10)
      )
    )
  )

  ;; CHECK:      (func $unreachable-2
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (i32.add
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $unreachable-2
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (i32.add
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $unreachable-2
    ;; As above, but with children flipped.
    (drop
      (i32.add
        (i32.const 10)
        (unreachable)
      )
    )
    (drop
      (i32.add
        (i32.const 10)
        (unreachable)
      )
    )
  )

  ;; CHECK:      (func $unreachable-3
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (select
  ;; CHECK-NEXT:    (i32.const 10)
  ;; CHECK-NEXT:    (unreachable)
  ;; CHECK-NEXT:    (i32.const 20)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $unreachable-3
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (select
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:    (i32.const 20)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (select
  ;; NONLC-NEXT:    (i32.const 10)
  ;; NONLC-NEXT:    (unreachable)
  ;; NONLC-NEXT:    (i32.const 20)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $unreachable-3
    ;; As above, but with with a select.
    (drop
      (select
        (i32.const 10)
        (unreachable)
        (i32.const 20)
      )
    )
    (drop
      (select
        (i32.const 10)
        (unreachable)
        (i32.const 20)
      )
    )
  )
)

(module
  ;; CHECK:      (type $none_=>_none (func))

  ;; CHECK:      (global $glob (mut i32) (i32.const 1))
  ;; NONLC:      (type $none_=>_none (func))

  ;; NONLC:      (global $glob (mut i32) (i32.const 1))
  (global $glob (mut i32) (i32.const 1))

  ;; CHECK:      (global $other-glob (mut i32) (i32.const 1))
  ;; NONLC:      (global $other-glob (mut i32) (i32.const 1))
  (global $other-glob (mut i32) (i32.const 1))

  ;; CHECK:      (func $global
  ;; CHECK-NEXT:  (local $0 i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $0
  ;; CHECK-NEXT:    (global.get $glob)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $other-glob
  ;; CHECK-NEXT:   (i32.const 100)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $0)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $glob
  ;; CHECK-NEXT:   (i32.const 200)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (global.get $glob)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  ;; NONLC:      (func $global
  ;; NONLC-NEXT:  (local $0 i32)
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.tee $0
  ;; NONLC-NEXT:    (global.get $glob)
  ;; NONLC-NEXT:   )
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $0)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (global.set $other-glob
  ;; NONLC-NEXT:   (i32.const 100)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (local.get $0)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (global.set $glob
  ;; NONLC-NEXT:   (i32.const 200)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT:  (drop
  ;; NONLC-NEXT:   (global.get $glob)
  ;; NONLC-NEXT:  )
  ;; NONLC-NEXT: )
  (func $global
    ;; We should optimize redundant global.get operations.
    (drop (global.get $glob))
    (drop (global.get $glob))
    ;; We can do it past a write to another global
    (global.set $other-glob (i32.const 100))
    (drop (global.get $glob))
    ;; But we can't do it past a write to our global.
    (global.set $glob (i32.const 200))
    (drop (global.get $glob))
  )
)
