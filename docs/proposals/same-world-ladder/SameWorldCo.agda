{-# OPTIONS --safe --without-K --cubical-compatible --guardedness #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
-- Scratch sketch, not a receipt. Ladder A, rung A4: the coinductive form.
-- This rung needs --guardedness, which is outside the section 2.1 invocation.
module SameWorldCo where

open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Sigma using (_,_)
open import Agda.Builtin.List using (List; []; _∷_)
open import SameWorld using (module World)

-- The experience as one infinite object (the final coalgebra).
record Beh (In P : Set) : Set where
  coinductive
  field
    head : P
    tail : In → Beh In P
open Beh public

-- Bisimilar experiences. In this profile it is a relation, not equality.
record _≋_ {In P : Set} (b b′ : Beh In P) : Set where
  coinductive
  field
    head≡ : head b ≡ head b′
    tail≋ : ∀ i → tail b i ≋ tail b′ i
open _≋_ public

-- Two percept alphabets: bisimilar up to a relation between percepts.
record Lift {In P₁ P₂ : Set} (T : P₁ → P₂ → Set)
            (b₁ : Beh In P₁) (b₂ : Beh In P₂) : Set where
  coinductive
  field
    headT : T (head b₁) (head b₂)
    tailT : ∀ i → Lift T (tail b₁ i) (tail b₂ i)
open Lift public

module _ (In W : Set) (step : W → In → W) where
  open World In W step

  module _ {P : Set} (see : W → P) where
    open View see

    unfold : W → Beh In P
    head (unfold w)   = see w
    tail (unfold w) i = unfold (step w i)

    -- The coinductive relation and the word relation agree.
    ~→≋ : ∀ {w w′} → w ~ w′ → unfold w ≋ unfold w′
    head≡ (~→≋ e)   = e []
    tail≋ (~→≋ e) i = ~→≋ (λ is → e (i ∷ is))

    ≋→~ : ∀ {w w′} → unfold w ≋ unfold w′ → w ~ w′
    ≋→~ r []       = head≡ r
    ≋→~ r (i ∷ is) = ≋→~ (tail≋ r i) is

  module _ {P₁ P₂ : Set} (see₁ : W → P₁) (see₂ : W → P₂) where
    open Two see₁ see₂

    -- One world gives two experiences that agree up to Coherent, for ever.
    one-world : ∀ w → Lift Coherent (unfold see₁ w) (unfold see₂ w)
    headT (one-world w)   = w , refl , refl
    tailT (one-world w) i = one-world (step w i)
