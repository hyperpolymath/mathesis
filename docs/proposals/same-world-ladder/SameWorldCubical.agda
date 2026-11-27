{-# OPTIONS --cubical --safe --guardedness #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
-- Scratch sketch, not a receipt. Ladder B, rungs B1 to B4, full Cubical Agda.
-- The import cone is Agda.Primitive and Agda.Builtin only (no cubical library).
module SameWorldCubical where

open import Agda.Primitive.Cubical
  using (I; i0; i1)
  renaming (primINeg to ~_; primHComp to hcomp)
open import Agda.Builtin.Cubical.Path using (_≡_)
open import Agda.Builtin.Sigma using (Σ; _,_; fst; snd)
open import Agda.Builtin.List using (List; []; _∷_)

infixr 2 _×_
_×_ : Set → Set → Set
A × B = Σ A (λ _ → B)

refl : {A : Set} {x : A} → x ≡ x
refl {x = x} _ = x

sym : {A : Set} {x y : A} → x ≡ y → y ≡ x
sym p k = p (~ k)

cong : {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong f p k = f (p k)

infixr 30 _∙_
_∙_ : {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
_∙_ {x = x} p q k = hcomp (λ j → λ { (k = i0) → x ; (k = i1) → q j }) (p k)

isSet : Set → Set
isSet A = (x y : A) (p q : x ≡ y) → p ≡ q

------------------------------------------------------------------------
-- B1. Function extensionality is a theorem. So "cannot tell apart" is
-- the same thing as "equal experience".

module World (In W : Set) (step : W → In → W) where

  run : W → List In → W
  run w []       = w
  run w (i ∷ is) = run (step w i) is

  module View {P : Set} (see : W → P) where

    beh : W → List In → P
    beh w is = see (run w is)

    _~_ : W → W → Set
    w ~ w′ = ∀ is → beh w is ≡ beh w′ is

    ~→≡ : ∀ {w w′} → w ~ w′ → beh w ≡ beh w′
    ~→≡ e k is = e is k

    ≡→~ : ∀ {w w′} → beh w ≡ beh w′ → w ~ w′
    ≡→~ p is k = p k is

    -- The two maps are inverse by computation alone.
    there-back : ∀ {w w′} (e : w ~ w′) → ≡→~ (~→≡ e) ≡ e
    there-back e = refl

    back-there : ∀ {w w′} (p : beh w ≡ beh w′) → ~→≡ (≡→~ p) ≡ p
    back-there p = refl

------------------------------------------------------------------------
-- B2. Coinduction is a theorem. Bisimilar experiences are equal.

record Beh (In P : Set) : Set where
  coinductive
  field
    head : P
    tail : In → Beh In P
open Beh

record _≋_ {In P : Set} (b b′ : Beh In P) : Set where
  coinductive
  field
    head≡ : head b ≡ head b′
    tail≋ : ∀ i → tail b i ≋ tail b′ i
open _≋_

path : ∀ {In P} {b b′ : Beh In P} → b ≋ b′ → b ≡ b′
head (path r k)   = head≡ r k
tail (path r k) i = path (tail≋ r i) k

bisim : ∀ {In P} {b b′ : Beh In P} → b ≡ b′ → b ≋ b′
head≡ (bisim p) k = head (p k)
tail≋ (bisim p) i = bisim (λ k → tail (p k) i)

path-bisim : ∀ {In P} {b b′ : Beh In P} (p : b ≡ b′) → path (bisim p) ≡ p
head (path-bisim p j k)   = head (p k)
tail (path-bisim p j k) i = path-bisim (λ k → tail (p k) i) j k

bisim-path : ∀ {In P} {b b′ : Beh In P} (r : b ≋ b′) → bisim (path r) ≡ r
head≡ (bisim-path r j)   = head≡ r
tail≋ (bisim-path r j) i = bisim-path (tail≋ r i) j

-- Finality: unfold is the only map that respects head and tail.
module Final (In W : Set) (step : W → In → W) {P : Set} (see : W → P) where

  unfold : W → Beh In P
  head (unfold w)   = see w
  tail (unfold w) i = unfold (step w i)

  module _ (h : W → Beh In P)
           (hh : ∀ w → head (h w) ≡ see w)
           (ht : ∀ w i → tail (h w) i ≡ h (step w i)) where

    lemma : ∀ b w → b ≡ h w → b ≋ unfold w
    head≡ (lemma b w p)   = cong head p ∙ hh w
    tail≋ (lemma b w p) i =
      lemma (tail b i) (step w i) (cong (λ x → tail x i) p ∙ ht w i)

    unique : ∀ w → h w ≡ unfold w
    unique w = path (lemma (h w) w refl)

------------------------------------------------------------------------
-- B3. The world as one subject can know it is a type: a set quotient.

data _/_ (A : Set) (R : A → A → Set) : Set where
  [_]     : A → A / R
  eq/     : ∀ a b → R a b → [ a ] ≡ [ b ]
  squash/ : (x y : A / R) (p q : x ≡ y) → p ≡ q

rec : {A B : Set} {R : A → A → Set} → isSet B →
      (f : A → B) → (∀ a b → R a b → f a ≡ f b) → A / R → B
rec s f e [ a ]                 = f a
rec s f e (eq/ a b r k)         = e a b r k
rec s f e (squash/ x y p q j k) =
  s (rec s f e x) (rec s f e y)
    (λ k → rec s f e (p k)) (λ k → rec s f e (q k)) j k

module Seen (In W : Set) (step : W → In → W)
            {P : Set} (Pset : isSet P) (see : W → P) where
  open World In W step
  open View see

  Known : Set
  Known = W / _~_

  step/ : Known → In → Known
  step/ x i = rec squash/ (λ w → [ step w i ])
                  (λ a b e → eq/ _ _ (λ is → e (i ∷ is))) x

  see/ : Known → P
  see/ = rec Pset see (λ a b e → e [])

  -- The quotient is a world again, and the experience does not change.
  module K  = World In Known step/
  module KV = K.View see/

  same : ∀ w is → KV.beh [ w ] is ≡ beh w is
  same w []       = refl
  same w (i ∷ is) = same (step w i) is

  -- In the known world, "cannot tell apart" gives "equal".
  cls : W → Known
  cls = [_]

  collapse : ∀ w w′ → KV._~_ (cls w) (cls w′) → cls w ≡ cls w′
  collapse w w′ e = eq/ w w′ (λ is → sym (same w is) ∙ e is ∙ same w′ is)

------------------------------------------------------------------------
-- B4. "Same world" is the fibre (the Echo) of the joint view.

fiber : {A B : Set} (f : A → B) → B → Set
fiber {A = A} f y = Σ A (λ x → f x ≡ y)

data ∥_∥ (A : Set) : Set where
  ∣_∣    : A → ∥ A ∥
  squash : (x y : ∥ A ∥) → x ≡ y

module Two (In W : Set) (step : W → In → W)
           {P₁ P₂ : Set} (see₁ : W → P₁) (see₂ : W → P₂) where
  open World In W step
  open View see₁ using () renaming (beh to beh₁; _~_ to _~₁_)
  open View see₂ using () renaming (beh to beh₂; _~_ to _~₂_)

  both : W → (List In → P₁) × (List In → P₂)
  both w = beh₁ w , beh₂ w

  SameWorld : (List In → P₁) → (List In → P₂) → Set
  SameWorld b₁ b₂ = fiber both (b₁ , b₂)

  -- The mere statement. The witness (the residue) is forgotten.
  MerelySameWorld : (List In → P₁) → (List In → P₂) → Set
  MerelySameWorld b₁ b₂ = ∥ SameWorld b₁ b₂ ∥

  sound : ∀ w → SameWorld (beh₁ w) (beh₂ w)
  sound w = w , refl

  -- The residue is exactly the set of states that neither subject can
  -- tell apart from w.
  Hidden : W → Set
  Hidden w = Σ W (λ w′ → (w′ ~₁ w) × (w′ ~₂ w))

  to : ∀ {w} → SameWorld (beh₁ w) (beh₂ w) → Hidden w
  to (w′ , p) = w′ , (λ is k → fst (p k) is) , (λ is k → snd (p k) is)

  from : ∀ {w} → Hidden w → SameWorld (beh₁ w) (beh₂ w)
  from (w′ , e₁ , e₂) = w′ , (λ k → (λ is → e₁ is k) , (λ is → e₂ is k))

  to-from : ∀ {w} (h : Hidden w) → to (from h) ≡ h
  to-from h = refl

  from-to : ∀ {w} (s : SameWorld (beh₁ w) (beh₂ w)) → from (to s) ≡ s
  from-to s = refl
