-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Agda Proof Template: Inductive and coinductive properties
-- Replace with your project's domain-specific proofs.
-- All proofs must be total (no postulate, no {-# TERMINATING #-}).
--
-- No library imports: only the Agda.Builtin modules that ship with Agda.
-- The agda-stdlib 2.3 package of the pinned Guix does not build (re-anchoring
-- plan WO 1.4, owner ruling 2026-11-10), and these examples need little of it.

module Properties where

open import Agda.Builtin.Nat using (Nat; zero; suc; _+_)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Equality using (_≡_; refl)

cong : ∀ {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong f refl = refl

length : ∀ {A : Set} → List A → Nat
length []       = zero
length (_ ∷ xs) = suc (length xs)

_++_ : ∀ {A : Set} → List A → List A → List A
[]       ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)

data _≤_ : Nat → Nat → Set where
  z≤n : ∀ {n} → zero ≤ n
  s≤s : ∀ {m n} → m ≤ n → suc m ≤ suc n

-- Example: Proof that list append preserves total length
-- Replace with your project's domain proofs.

append-length : ∀ {A : Set} (xs ys : List A) →
  length (xs ++ ys) ≡ length xs + length ys
append-length []       ys = refl
append-length (_ ∷ xs) ys = cong suc (append-length xs ys)

-- Example: Monotonicity proof template
-- Use for state machines, confidence scores, trust levels
record Monotone {A : Set} (_≤A_ : A → A → Set) (f : A → A) : Set where
  field
    preserves : ∀ {x y} → x ≤A y → f x ≤A f y

-- Example: Idempotence proof template
-- Use for normalisation, deduplication, formatting
record Idempotent {A : Set} (_≡A_ : A → A → Set) (f : A → A) : Set where
  field
    idem : ∀ (x : A) → f (f x) ≡A f x

-- Example: Natural number successor is monotone
suc-monotone : Monotone _≤_ suc
suc-monotone = record { preserves = s≤s }
