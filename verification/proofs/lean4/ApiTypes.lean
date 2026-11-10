-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Typing Proof: Public API type safety
-- Template — replace with your project's API types.
-- Proves properties about exported function signatures.

-- Example: Result type used across API boundaries
inductive ApiResult (α : Type) where
  | ok    : α → ApiResult α
  | error : Nat → String → ApiResult α

namespace ApiResult
  -- Proof: map preserves structure (functor law: map id = id)
  def map (f : α → β) : ApiResult α → ApiResult β
    | .ok v      => .ok (f v)
    | .error c m => .error c m

  -- By `rfl` after `cases`: under Lean 4.29.0 `simp [map]` brings in `propext`.
  theorem map_id : ∀ (r : ApiResult α), map id r = r := by
    intro r
    cases r <;> rfl

  -- Proof: map composition (functor law: map (g ∘ f) = map g ∘ map f)
  theorem map_comp (f : α → β) (g : β → γ) :
      ∀ (r : ApiResult α), map (g ∘ f) r = map g (map f r) := by
    intro r
    cases r <;> rfl
end ApiResult

-- Example: Bounded confidence value (0.0 to 1.0 modelled as Nat/1000)
-- Replace with your project's numeric invariants
structure BoundedNat (max : Nat) where
  val : Nat
  le_max : val ≤ max

theorem bounded_nat_le {max : Nat} (b : BoundedNat max) : b.val ≤ max :=
  b.le_max

-- Proof: zero is always bounded
def zeroBounded {max : Nat} (h : 0 < max) : BoundedNat max :=
  ⟨0, Nat.zero_le max⟩
