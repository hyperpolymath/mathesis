{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- The order of evidence statuses, and what a given value tells about the
-- values it was computed from. Used by the proofs of APP-1 and APP-4
-- (Applied.CohortProofs).

module Applied.Status where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Nat using (Nat; zero; suc)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Applied.Cohort

------------------------------------------------------------------------
-- Logic

record ⊤ : Set where
  constructor tt

data ⊥ : Set where

T : Bool → Set
T true  = ⊤
T false = ⊥

infixr 2 _×_
_×_ : Set → Set → Set
A × B = Σ A (λ _ → B)

------------------------------------------------------------------------
-- The order of statuses: illustrative < estimate < reported < verified
-- < definitional.

rank : Status → Nat
rank illustrative = 0
rank estimate     = 1
rank reported     = 2
rank verified     = 3
rank definitional = 4

_≤ᵇ_ : Nat → Nat → Bool
zero  ≤ᵇ _     = true
suc m ≤ᵇ zero  = false
suc m ≤ᵇ suc n = m ≤ᵇ n

≤ᵇ-refl : ∀ n → T (n ≤ᵇ n)
≤ᵇ-refl zero    = tt
≤ᵇ-refl (suc n) = ≤ᵇ-refl n

≤ᵇ-trans : ∀ m n k → T (m ≤ᵇ n) → T (n ≤ᵇ k) → T (m ≤ᵇ k)
≤ᵇ-trans zero    _       _       _ _ = tt
≤ᵇ-trans (suc m) zero    _       () _
≤ᵇ-trans (suc m) (suc n) zero    _ ()
≤ᵇ-trans (suc m) (suc n) (suc k) p q = ≤ᵇ-trans m n k p q

-- s ≤ˢ t: status s is no stronger than status t.
infix 4 _≤ˢ_
_≤ˢ_ : Status → Status → Set
s ≤ˢ t = T (rank s ≤ᵇ rank t)

≤ˢ-refl : ∀ s → s ≤ˢ s
≤ˢ-refl s = ≤ᵇ-refl (rank s)

≤ˢ-trans : ∀ s t u → s ≤ˢ t → t ≤ˢ u → s ≤ˢ u
≤ˢ-trans s t u = ≤ᵇ-trans (rank s) (rank t) (rank u)

-- The meet is below each of its arguments.
⊓-≤ˡ : ∀ s t → (s ⊓ t) ≤ˢ s
⊓-≤ˡ illustrative illustrative = tt
⊓-≤ˡ illustrative estimate = tt
⊓-≤ˡ illustrative reported = tt
⊓-≤ˡ illustrative verified = tt
⊓-≤ˡ illustrative definitional = tt
⊓-≤ˡ estimate illustrative = tt
⊓-≤ˡ estimate estimate = tt
⊓-≤ˡ estimate reported = tt
⊓-≤ˡ estimate verified = tt
⊓-≤ˡ estimate definitional = tt
⊓-≤ˡ reported illustrative = tt
⊓-≤ˡ reported estimate = tt
⊓-≤ˡ reported reported = tt
⊓-≤ˡ reported verified = tt
⊓-≤ˡ reported definitional = tt
⊓-≤ˡ verified illustrative = tt
⊓-≤ˡ verified estimate = tt
⊓-≤ˡ verified reported = tt
⊓-≤ˡ verified verified = tt
⊓-≤ˡ verified definitional = tt
⊓-≤ˡ definitional illustrative = tt
⊓-≤ˡ definitional estimate = tt
⊓-≤ˡ definitional reported = tt
⊓-≤ˡ definitional verified = tt
⊓-≤ˡ definitional definitional = tt

⊓-≤ʳ : ∀ s t → (s ⊓ t) ≤ˢ t
⊓-≤ʳ illustrative illustrative = tt
⊓-≤ʳ illustrative estimate = tt
⊓-≤ʳ illustrative reported = tt
⊓-≤ʳ illustrative verified = tt
⊓-≤ʳ illustrative definitional = tt
⊓-≤ʳ estimate illustrative = tt
⊓-≤ʳ estimate estimate = tt
⊓-≤ʳ estimate reported = tt
⊓-≤ʳ estimate verified = tt
⊓-≤ʳ estimate definitional = tt
⊓-≤ʳ reported illustrative = tt
⊓-≤ʳ reported estimate = tt
⊓-≤ʳ reported reported = tt
⊓-≤ʳ reported verified = tt
⊓-≤ʳ reported definitional = tt
⊓-≤ʳ verified illustrative = tt
⊓-≤ʳ verified estimate = tt
⊓-≤ʳ verified reported = tt
⊓-≤ʳ verified verified = tt
⊓-≤ʳ verified definitional = tt
⊓-≤ʳ definitional illustrative = tt
⊓-≤ʳ definitional estimate = tt
⊓-≤ʳ definitional reported = tt
⊓-≤ʳ definitional verified = tt
⊓-≤ʳ definitional definitional = tt

------------------------------------------------------------------------
-- Covers u v: the value v is given, with a status at least u.

record Covers {A : Set} (u : Status) (v : Val A) : Set where
  constructor covers
  field
    status  : Status
    value   : A
    isGiven : v ≡ given status value
    atLeast : u ≤ˢ status

-- A given value covers its own status.
self : ∀ {A} {s : Status} {a : A} → Covers s (given s a)
self {s = s} {a} = covers s a refl (≤ˢ-refl s)

weaken : ∀ {A} {u w : Status} {v : Val A} → u ≤ˢ w → Covers w v → Covers u v
weaken {u = u} {w} le (covers s a eq le′) = covers s a eq (≤ˢ-trans u w s le le′)

------------------------------------------------------------------------
-- Equality, without injectivity of constructors (--cubical-compatible)

sym : ∀ {A : Set} {x y : A} → x ≡ y → y ≡ x
sym refl = refl

cong : ∀ {A B : Set} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong f refl = refl

subst : ∀ {A : Set} (P : A → Set) {x y : A} → x ≡ y → P x → P y
subst P refl p = p

-- The status of a given value; `definitional` for a missing one.
statusOr : ∀ {A} → Val A → Status
statusOr missing     = definitional
statusOr (given s _) = s

-- When zipWith gives a value, both arguments were given, each with a
-- status at least that of the result.
zipWith-given : ∀ {A B C} {f : A → B → C} {x : Val A} {y : Val B} {u : Status} {c : C} →
  zipWith f x y ≡ given u c → Covers u x × Covers u y
zipWith-given {x = given s a} {given t b} eq =
  covers s a refl (subst (λ w → w ≤ˢ s) (cong statusOr eq) (⊓-≤ˡ s t)) ,
  covers t b refl (subst (λ w → w ≤ˢ t) (cong statusOr eq) (⊓-≤ʳ s t))
zipWith-given {x = given s a} {missing}   ()
zipWith-given {x = missing}               ()

zipWith-needs : ∀ {A B C} {f : A → B → C} {x : Val A} {y : Val B} {u : Status} →
  Covers u (zipWith f x y) → Covers u x × Covers u y
zipWith-needs (covers s c eq le) with zipWith-given eq
... | cx , cy = weaken le cx , weaken le cy

map-needs : ∀ {A B} {f : A → B} {x : Val A} {u : Status} → Covers u (map f x) → Covers u x
map-needs {x = given s a} {u} (covers s′ c eq le) =
  covers s a refl (subst (λ w → u ≤ˢ w) (cong statusOr (sym eq)) le)
map-needs {x = missing}   (covers _ _ () _)

-- Nothing covers a missing value.
missing-uncovered : ∀ {A} {u : Status} → Covers {A} u missing → ⊥
missing-uncovered (covers _ _ () _)

-- The meet is associative, and `definitional` is its unit.
⊓-assoc : ∀ s t u → (s ⊓ t) ⊓ u ≡ s ⊓ (t ⊓ u)
⊓-assoc illustrative illustrative illustrative = refl
⊓-assoc illustrative illustrative estimate = refl
⊓-assoc illustrative illustrative reported = refl
⊓-assoc illustrative illustrative verified = refl
⊓-assoc illustrative illustrative definitional = refl
⊓-assoc illustrative estimate illustrative = refl
⊓-assoc illustrative estimate estimate = refl
⊓-assoc illustrative estimate reported = refl
⊓-assoc illustrative estimate verified = refl
⊓-assoc illustrative estimate definitional = refl
⊓-assoc illustrative reported illustrative = refl
⊓-assoc illustrative reported estimate = refl
⊓-assoc illustrative reported reported = refl
⊓-assoc illustrative reported verified = refl
⊓-assoc illustrative reported definitional = refl
⊓-assoc illustrative verified illustrative = refl
⊓-assoc illustrative verified estimate = refl
⊓-assoc illustrative verified reported = refl
⊓-assoc illustrative verified verified = refl
⊓-assoc illustrative verified definitional = refl
⊓-assoc illustrative definitional illustrative = refl
⊓-assoc illustrative definitional estimate = refl
⊓-assoc illustrative definitional reported = refl
⊓-assoc illustrative definitional verified = refl
⊓-assoc illustrative definitional definitional = refl
⊓-assoc estimate illustrative illustrative = refl
⊓-assoc estimate illustrative estimate = refl
⊓-assoc estimate illustrative reported = refl
⊓-assoc estimate illustrative verified = refl
⊓-assoc estimate illustrative definitional = refl
⊓-assoc estimate estimate illustrative = refl
⊓-assoc estimate estimate estimate = refl
⊓-assoc estimate estimate reported = refl
⊓-assoc estimate estimate verified = refl
⊓-assoc estimate estimate definitional = refl
⊓-assoc estimate reported illustrative = refl
⊓-assoc estimate reported estimate = refl
⊓-assoc estimate reported reported = refl
⊓-assoc estimate reported verified = refl
⊓-assoc estimate reported definitional = refl
⊓-assoc estimate verified illustrative = refl
⊓-assoc estimate verified estimate = refl
⊓-assoc estimate verified reported = refl
⊓-assoc estimate verified verified = refl
⊓-assoc estimate verified definitional = refl
⊓-assoc estimate definitional illustrative = refl
⊓-assoc estimate definitional estimate = refl
⊓-assoc estimate definitional reported = refl
⊓-assoc estimate definitional verified = refl
⊓-assoc estimate definitional definitional = refl
⊓-assoc reported illustrative illustrative = refl
⊓-assoc reported illustrative estimate = refl
⊓-assoc reported illustrative reported = refl
⊓-assoc reported illustrative verified = refl
⊓-assoc reported illustrative definitional = refl
⊓-assoc reported estimate illustrative = refl
⊓-assoc reported estimate estimate = refl
⊓-assoc reported estimate reported = refl
⊓-assoc reported estimate verified = refl
⊓-assoc reported estimate definitional = refl
⊓-assoc reported reported illustrative = refl
⊓-assoc reported reported estimate = refl
⊓-assoc reported reported reported = refl
⊓-assoc reported reported verified = refl
⊓-assoc reported reported definitional = refl
⊓-assoc reported verified illustrative = refl
⊓-assoc reported verified estimate = refl
⊓-assoc reported verified reported = refl
⊓-assoc reported verified verified = refl
⊓-assoc reported verified definitional = refl
⊓-assoc reported definitional illustrative = refl
⊓-assoc reported definitional estimate = refl
⊓-assoc reported definitional reported = refl
⊓-assoc reported definitional verified = refl
⊓-assoc reported definitional definitional = refl
⊓-assoc verified illustrative illustrative = refl
⊓-assoc verified illustrative estimate = refl
⊓-assoc verified illustrative reported = refl
⊓-assoc verified illustrative verified = refl
⊓-assoc verified illustrative definitional = refl
⊓-assoc verified estimate illustrative = refl
⊓-assoc verified estimate estimate = refl
⊓-assoc verified estimate reported = refl
⊓-assoc verified estimate verified = refl
⊓-assoc verified estimate definitional = refl
⊓-assoc verified reported illustrative = refl
⊓-assoc verified reported estimate = refl
⊓-assoc verified reported reported = refl
⊓-assoc verified reported verified = refl
⊓-assoc verified reported definitional = refl
⊓-assoc verified verified illustrative = refl
⊓-assoc verified verified estimate = refl
⊓-assoc verified verified reported = refl
⊓-assoc verified verified verified = refl
⊓-assoc verified verified definitional = refl
⊓-assoc verified definitional illustrative = refl
⊓-assoc verified definitional estimate = refl
⊓-assoc verified definitional reported = refl
⊓-assoc verified definitional verified = refl
⊓-assoc verified definitional definitional = refl
⊓-assoc definitional illustrative illustrative = refl
⊓-assoc definitional illustrative estimate = refl
⊓-assoc definitional illustrative reported = refl
⊓-assoc definitional illustrative verified = refl
⊓-assoc definitional illustrative definitional = refl
⊓-assoc definitional estimate illustrative = refl
⊓-assoc definitional estimate estimate = refl
⊓-assoc definitional estimate reported = refl
⊓-assoc definitional estimate verified = refl
⊓-assoc definitional estimate definitional = refl
⊓-assoc definitional reported illustrative = refl
⊓-assoc definitional reported estimate = refl
⊓-assoc definitional reported reported = refl
⊓-assoc definitional reported verified = refl
⊓-assoc definitional reported definitional = refl
⊓-assoc definitional verified illustrative = refl
⊓-assoc definitional verified estimate = refl
⊓-assoc definitional verified reported = refl
⊓-assoc definitional verified verified = refl
⊓-assoc definitional verified definitional = refl
⊓-assoc definitional definitional illustrative = refl
⊓-assoc definitional definitional estimate = refl
⊓-assoc definitional definitional reported = refl
⊓-assoc definitional definitional verified = refl
⊓-assoc definitional definitional definitional = refl

⊓-identityʳ : ∀ s → s ⊓ definitional ≡ s
⊓-identityʳ illustrative = refl
⊓-identityʳ estimate = refl
⊓-identityʳ reported = refl
⊓-identityʳ verified = refl
⊓-identityʳ definitional = refl
