;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --coalesce-locals -all -S -o - \
;; RUN:   | filecheck %s

(module
 ;; CHECK:      (type $array (array (mut i8)))
 (type $array (array (mut i8)))
 ;; CHECK:      (global $global (ref null $array) (ref.null $array))
 (global $global (ref null $array) (ref.null $array))

 ;; CHECK:      (func $test-dead-get-non-nullable (param $0 dataref)
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (block (result dataref)
 ;; CHECK-NEXT:    (unreachable)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $test-dead-get-non-nullable (param $func (ref data))
  (unreachable)
  (drop
   ;; A useless get (that does not read from any set, or from the inputs to the
   ;; function). Normally we replace such gets with nops as best we can, but in
   ;; this case the type is non-nullable, so we must leave it alone.
   (local.get $func)
  )
 )

 ;; CHECK:      (func $br_on_null (param $0 (ref null $array)) (result (ref null $array))
 ;; CHECK-NEXT:  (block $label$1 (result (ref null $array))
 ;; CHECK-NEXT:   (block $label$2
 ;; CHECK-NEXT:    (br $label$1
 ;; CHECK-NEXT:     (br_on_null $label$2
 ;; CHECK-NEXT:      (local.get $0)
 ;; CHECK-NEXT:     )
 ;; CHECK-NEXT:    )
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (local.set $0
 ;; CHECK-NEXT:    (global.get $global)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:   (local.get $0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $br_on_null (param $ref (ref null $array)) (result (ref null $array))
  (local $1 (ref null $array))
  (block $label$1 (result (ref null $array))
   (block $label$2
    (br $label$1
     ;; Test that we properly model the basic block connections around a
     ;; BrOnNull. There should be a branch to $label$2, and also a fallthrough.
     ;; As a result, the local.set below is reachable, and should not be
     ;; eliminated (turned into a drop).
     (br_on_null $label$2
      (local.get $ref)
     )
    )
   )
   (local.set $1
    (global.get $global)
   )
   (local.get $1)
  )
 )

 ;; CHECK:      (func $nn-dead
 ;; CHECK-NEXT:  (local $0 (ref func))
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (ref.func $nn-dead)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (block $inner
 ;; CHECK-NEXT:   (local.set $0
 ;; CHECK-NEXT:    (ref.func $nn-dead)
 ;; CHECK-NEXT:   )
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (local.get $0)
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $nn-dead
  (local $x (ref func))
  (local.set $x ;; this will become a drop, as it is not needed.
   (ref.func $nn-dead)
  )
  (block $inner
   (local.set $x
    (ref.func $nn-dead) ;; this is not enough for validation of the get, as it
                        ;; is inside a block. later passes will fix that up;
                        ;; here nothing changes and the local remains non-
                        ;; nullable for now.
   )
  )
  (drop
   (local.get $x)
  )
 )
)
