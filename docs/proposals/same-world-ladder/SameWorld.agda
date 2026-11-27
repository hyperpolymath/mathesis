{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
-- Scratch sketch, not a receipt. Ladder A, rungs A0 to A3, A5 and A6.
-- No coinduction here. The import cone is Agda.Builtin only.
module SameWorld where

open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Unit using (⊤; tt)

data ⊥ : Set where

infixr 2 _×_
_×_ : Set → Set → Set
A × B = Σ A (λ _ → B)

sym : {A : Set} {x y : A} → x ≡ y → y ≡ x
sym refl = refl

trans : {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans refl q = q

subst : {A : Set} (C : A → Set) {x y : A} → x ≡ y → C x → C y
subst C refl c = c

------------------------------------------------------------------------
-- A0. Vocabulary. A world is a deterministic machine.
-- In is the input of one tick. W is the world state.

module World (In W : Set) (step : W → In → W) where

  run : W → List In → W
  run w []       = w
  run w (i ∷ is) = run (step w i) is

  -- A view (an Umwelt) is a function from the world state to a percept.
  module View {P : Set} (see : W → P) where

    -- The experience of the subject: the percept after each input word.
    beh : W → List In → P
    beh w is = see (run w is)

    -- A3. Two states that this subject cannot tell apart, whatever happens.
    _~_ : W → W → Set
    w ~ w′ = ∀ is → beh w is ≡ beh w′ is

    ~-refl : ∀ {w} → w ~ w
    ~-refl is = refl

    ~-sym : ∀ {w w′} → w ~ w′ → w′ ~ w
    ~-sym e is = sym (e is)

    ~-trans : ∀ {w w′ w″} → w ~ w′ → w′ ~ w″ → w ~ w″
    ~-trans e f is = trans (e is) (f is)

    record Bisimulation (R : W → W → Set) : Set where
      field
        now   : ∀ {w w′} → R w w′ → see w ≡ see w′
        later : ∀ {w w′} → R w w′ → ∀ i → R (step w i) (step w′ i)
    open Bisimulation

    ~-bisim : Bisimulation _~_
    now   ~-bisim e      = e []
    later ~-bisim e i is = e (i ∷ is)

    -- The coinduction principle, proved by induction on the input word:
    -- every bisimulation is inside _~_.
    greatest : ∀ {R} → Bisimulation R → ∀ {w w′} → R w w′ → w ~ w′
    greatest b r []       = now b r
    greatest b r (i ∷ is) = greatest b (later b r i) is

  ----------------------------------------------------------------------
  -- Two subjects.

  module Two {P₁ P₂ : Set} (see₁ : W → P₁) (see₂ : W → P₂) where
    open View see₁ using () renaming (beh to beh₁)
    open View see₂ using () renaming (beh to beh₂)

    -- A1. Two percepts of one state. The witness is the state.
    Coherent : P₁ → P₂ → Set
    Coherent p₁ p₂ = Σ W (λ w → (see₁ w ≡ p₁) × (see₂ w ≡ p₂))

    -- A2. Two experiences of one world. The witness is the start state.
    SameWorld : (List In → P₁) → (List In → P₂) → Set
    SameWorld b₁ b₂ =
      Σ W (λ w → (∀ is → beh₁ w is ≡ b₁ is) × (∀ is → beh₂ w is ≡ b₂ is))

    -- What a host shows to two seats from one state is of the same world.
    sound : ∀ w → SameWorld (beh₁ w) (beh₂ w)
    sound w = w , (λ _ → refl) , (λ _ → refl)

    after : {P : Set} → (List In → P) → In → List In → P
    after b i is = b (i ∷ is)

    -- The same world stays the same world after any input.
    stable : ∀ {b₁ b₂} → SameWorld b₁ b₂ →
             ∀ i → SameWorld (after b₁ i) (after b₂ i)
    stable (w , e₁ , e₂) i =
      step w i , (λ is → e₁ (i ∷ is)) , (λ is → e₂ (i ∷ is))

    -- A5. Coherent at each moment. This is weaker than SameWorld.
    Moments : (List In → P₁) → (List In → P₂) → Set
    Moments b₁ b₂ = ∀ is → Coherent (b₁ is) (b₂ is)

    weaker : ∀ {b₁ b₂} → SameWorld b₁ b₂ → Moments b₁ b₂
    weaker (w , e₁ , e₂) is = run w is , e₁ is , e₂ is

  ----------------------------------------------------------------------
  -- A6. Unwinding: a hidden input does not change what a seat sees.

  module Secret {P : Set} (see : W → P) (hidden : In → Bool)
                (_≈_ : W → W → Set)
                (≈-trans : ∀ {a b c} → a ≈ b → b ≈ c → a ≈ c)
                (out  : ∀ {w w′} → w ≈ w′ → see w ≡ see w′)
                (same : ∀ {w w′} → w ≈ w′ → ∀ i → step w i ≈ step w′ i)
                (hide : ∀ w i → hidden i ≡ true → step w i ≈ w) where

    purge : List In → List In
    purge [] = []
    purge (i ∷ is) with hidden i
    ... | true  = purge is
    ... | false = i ∷ purge is

    lemma : ∀ {w w′} → w ≈ w′ → ∀ is → run w is ≈ run w′ (purge is)
    lemma r [] = r
    lemma {w} r (i ∷ is) with hidden i in eq
    ... | true  = lemma (≈-trans (hide w i eq) r) is
    ... | false = lemma (same r i) is

    no-leak : ∀ {w} → w ≈ w → ∀ is → see (run w is) ≡ see (run w (purge is))
    no-leak r is = out (lemma r is)

------------------------------------------------------------------------
-- A5, the converse fails. Each moment is possible. The story is not.

module Gaslight where

  -- The world is one bit that never changes.
  -- Subject 1 sees the bit. Subject 2 sees nothing.
  still : Bool → ⊤ → Bool
  still b _ = b

  open World ⊤ Bool still
  open Two (λ b → b) (λ _ → tt)

  -- An experience that shows true first, and false after that.
  turn : List ⊤ → Bool
  turn []      = true
  turn (_ ∷ _) = false

  blank : List ⊤ → ⊤
  blank _ = tt

  moments : Moments turn blank
  moments []      = true  , refl , refl
  moments (_ ∷ _) = false , refl , refl

  T : Bool → Set
  T true  = ⊤
  T false = ⊥

  not-same : SameWorld turn blank → ⊥
  not-same (w , e₁ , _) = subst T (trans (sym (e₁ [])) (e₁ (tt ∷ []))) tt
