{-# OPTIONS --cubical --safe #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
-- Scratch sketch. Rung B0: a Cubical module imports the Ladder A module.
module Bridge where

open import Agda.Builtin.Cubical.Path using (_≡_)
import Agda.Builtin.Equality as Id
open import Agda.Builtin.List using (List)
open import SameWorld using (module World)

toPath : {A : Set} {x y : A} → x Id.≡ y → x ≡ y
toPath {x = x} Id.refl = λ _ → x

module _ (In W : Set) (step : W → In → W) {P : Set} (see : W → P) where
  open World In W step
  open View see

  -- The Ladder A relation gives a path between experiences.
  lift : ∀ {w w′} → w ~ w′ → beh w ≡ beh w′
  lift e k is = toPath (e is) k
