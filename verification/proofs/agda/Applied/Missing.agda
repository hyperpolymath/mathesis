{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- APP-1 (missing propagates) and APP-4 (status never upgrades) for the
-- cohort model (Applied.Cohort), for any number structure.
--
-- One statement carries both. `Covers u v` says that v is given with a
-- status at least u. Each theorem below says: if an output is given with
-- status u, then every input that it depends on is given, with a status at
-- least u. Read one way, an output is missing when an input it depends on
-- is missing (APP-1): it is the constructor `missing`, never a number such
-- as zero. Read the other way, an output is never more certain than an
-- input it depends on (APP-4).

module Applied.Missing where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Nat using (Nat; zero; suc) renaming (_-_ to _∸_; _<_ to _<ℕ_)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Applied.Cohort
open import Applied.Status

------------------------------------------------------------------------
-- Lists

-- Every element satisfies P. A function, not an indexed type, so that no
-- match needs the injectivity of _∷_ (--cubical-compatible).
All : {A : Set} → (A → Set) → List A → Set
All P []       = ⊤
All P (x ∷ xs) = P x × All P xs

data _⊎_ (A B : Set) : Set where
  inj₁ : A → A ⊎ B
  inj₂ : B → A ⊎ B

-- Some element satisfies P. A function, not an indexed type, so that no
-- match needs the injectivity of _∷_ (--cubical-compatible).
Any : {A : Set} → (A → Set) → List A → Set
Any P []       = ⊥
Any P (x ∷ xs) = P x ⊎ Any P xs

All-map : ∀ {A} {P Q : A → Set} → (∀ {x} → P x → Q x) → ∀ xs → All P xs → All Q xs
All-map f []       _        = tt
All-map f (x ∷ xs) (p , ps) = f p , All-map f xs ps

if-false : ∀ {A : Set} {b : Bool} {x y : A} → b ≡ false → (if b then x else y) ≡ y
if-false refl = refl

------------------------------------------------------------------------
-- Cohorts

joined-needs : ∀ {u scale contacts conversion} →
  Covers u (joined scale contacts conversion) → Covers u contacts × Covers u conversion
joined-needs c with zipWith-needs c
... | cl , cc = map-needs cl , cc

-- The members after any number of renewals need the members who joined;
-- after at least one renewal they need the retention rate too.
renewed-joined : ∀ {u scale start retention} k →
  Covers u (renewed scale start retention k) → Covers u start
renewed-joined zero    c = c
renewed-joined (suc k) c = renewed-joined k (Σ.fst (zipWith-needs c))

renewed-retention : ∀ {u scale start retention} k →
  Covers u (renewed scale start retention (suc k)) → Covers u retention
renewed-retention k c = Σ.snd (zipWith-needs c)

-- A modelled cohort that has started needs its contacts and its
-- conversion rate, and from its first renewal its retention rate.
modelled-needs : ∀ {u scale t start contacts conversion retention} → (t <ℕ start) ≡ false →
  Covers u (cohortAt scale t (modelled start contacts conversion retention)) →
  Covers u contacts × Covers u conversion
modelled-needs {u} {scale} {t} {start} {contacts} {conversion} {retention} eq c =
  joined-needs (renewed-joined {u} {scale} {joined scale contacts conversion} {retention} (t ∸ start)
    (subst (Covers u) (if-false eq) c))

modelled-renewal-needs : ∀ {u scale t start contacts conversion retention} k →
  (t <ℕ start) ≡ false → (t ∸ start) ≡ suc k →
  Covers u (cohortAt scale t (modelled start contacts conversion retention)) →
  Covers u retention
modelled-renewal-needs {u} {scale} {t} {start} {contacts} {conversion} {retention} k eq gap c =
  renewed-retention {u} {scale} {joined scale contacts conversion} {retention} k
    (subst (λ n → Covers u (renewed scale (joined scale contacts conversion) retention n)) gap
      (subst (Covers u) (if-false eq) c))

-- An observed cohort that has started needs its count for the period.
observed-needs : ∀ {u scale t start counts} → (t <ℕ start) ≡ false →
  Covers u (cohortAt scale t (observed start counts)) → Covers u (at (t ∸ start) counts)
observed-needs eq c = map-needs (subst (Covers _) (if-false eq) c)

-- The active members of a period need every cohort's members.
sum-needs : ∀ {u scale t} cs → Covers u (sumAt scale t cs) → All (λ c → Covers u (cohortAt scale t c)) cs
sum-needs []       c = tt
sum-needs (x ∷ cs) c with zipWith-needs c
... | cx , rest = cx , sum-needs cs rest

------------------------------------------------------------------------
-- The model

module Proofs (N : Number) where
  open Number N
  open Model N

  -- Kleene conjunction: a "yes" needs both sides to be a known "yes".
  Yes : Status → Val Bool → Set
  Yes u v = Σ Status (λ s → (v ≡ given s true) × (u ≤ˢ s))

  Yes-weaken : ∀ {u w v} → u ≤ˢ w → Yes w v → Yes u v
  Yes-weaken {u} {w} le (s , eq , le′) = s , eq , ≤ˢ-trans u w s le le′

  private
    truth : Val Bool → Bool
    truth missing     = false
    truth (given _ b) = b

    false≢true : false ≡ true → ⊥
    false≢true ()

    ⊥-elim : ∀ {A : Set} → ⊥ → A
    ⊥-elim ()

  ∧-yes : ∀ {x y u} → x ∧ᵏ y ≡ given u true → Yes u x × Yes u y
  ∧-yes {given s true}  {given t b} eq =
    (s , refl , subst (λ w → w ≤ˢ s) (cong statusOr eq) (⊓-≤ˡ s t)) ,
    (t , cong (given t) (cong truth eq) , subst (λ w → w ≤ˢ t) (cong statusOr eq) (⊓-≤ʳ s t))
  ∧-yes {given s true}  {missing}         ()
  ∧-yes {given s false}                   eq = ⊥-elim (false≢true (cong truth eq))
  ∧-yes {missing}       {given t false}   eq = ⊥-elim (false≢true (cong truth eq))
  ∧-yes {missing}       {given t true}    ()
  ∧-yes {missing}       {missing}         ()

  ∧-false-left : ∀ {x y s} → x ≡ given s false → x ∧ᵏ y ≡ given s false
  ∧-false-left refl = refl

  ∧-false-right : ∀ {x y t} → y ≡ given t false → Σ Status (λ u → x ∧ᵏ y ≡ given u false)
  ∧-false-right {given s false} refl = s , refl
  ∧-false-right {given s true}  {t = t} refl = s ⊓ t , refl
  ∧-false-right {missing}       {t = t} refl = t , refl

  module _ (i : Inputs) where
    open Inputs i
    open Run i

    -- Each output of a period, and the inputs it needs. `previous` is the
    -- closing cash of the period before.

    members-needs : ∀ {u} t previous → Covers u (Row.members (rowAt t previous)) →
      Covers u (sumAt scale t cohorts)
    members-needs t previous c = map-needs c

    receipts-needs : ∀ {u} t previous → Covers u (Row.receipts (rowAt t previous)) →
      Covers u price × Covers u (sumAt scale t cohorts)
    receipts-needs t previous c with zipWith-needs c
    ... | cp , cm = cp , map-needs cm

    payments-needs : ∀ {u} t previous → Covers u (Row.payments (rowAt t previous)) →
      Covers u (at (t ∸ 1) fixed) × Covers u unitCost × Covers u (sumAt scale t cohorts)
    payments-needs t previous c with zipWith-needs c
    ... | cf , cv with zipWith-needs cv
    ... | cu , cm = map-needs cf , cu , map-needs cm

    closing-needs : ∀ {u} t previous → Covers u (Row.closing (rowAt t previous)) →
      Covers u previous × Covers u price × Covers u (at (t ∸ 1) fixed) ×
      Covers u unitCost × Covers u (sumAt scale t cohorts)
    closing-needs t previous c with zipWith-needs c
    ... | cpr , cpay with zipWith-needs cpr | payments-needs t previous cpay
    ... | cprev , crec | cf , cu , cm = cprev , Σ.fst (zipWith-needs crec) , cf , cu , cm

    shortfall-needs : ∀ {u} t previous → Covers u (Row.shortfall (rowAt t previous)) →
      Covers u (at (t ∸ 1) floor) × Covers u (Row.closing (rowAt t previous))
    shortfall-needs t previous c with zipWith-needs c
    ... | cfl , cc = map-needs cfl , cc

    cashOk-needs : ∀ {u} t previous → Covers u (Row.cashOk (rowAt t previous)) →
      Covers u (at (t ∸ 1) floor) × Covers u (Row.closing (rowAt t previous))
    cashOk-needs t previous c with zipWith-needs c
    ... | cfl , cc = map-needs cfl , cc

    hours-needs : ∀ {u} t previous → Covers u (Row.hours (rowAt t previous)) →
      Covers u minutes × Covers u (sumAt scale t cohorts)
    hours-needs t previous c with zipWith-needs c
    ... | cmin , cm = cmin , map-needs cm

    capacityOk-needs : ∀ {u} t previous → Covers u (Row.capacityOk (rowAt t previous)) →
      Covers u minutes × Covers u (sumAt scale t cohorts) × Covers u (at (t ∸ 1) capacity)
    capacityOk-needs t previous c with zipWith-needs c
    ... | ch , ccap with hours-needs t previous ch
    ... | cmin , cm = cmin , cm , map-needs ccap

    -- The first period starts from the opening cash.
    opening-needs : ∀ {u} → Covers u (scaled opening) → Covers u opening
    opening-needs = map-needs

    -- Missing in every period after it: once a closing balance is
    -- missing, every later closing balance is missing.
    closings-missing : ∀ t n → All (λ r → Row.closing r ≡ missing) (rowsFrom t n missing)
    closings-missing t zero    = tt
    closings-missing t (suc n) = refl , closings-missing (suc t) n

    missing-persists : ∀ t n previous → Row.closing (rowAt t previous) ≡ missing →
      All (λ r → Row.closing r ≡ missing) (rowsFrom (suc t) n (Row.closing (rowAt t previous)))
    missing-persists t n previous eq =
      subst (λ p → All (λ r → Row.closing r ≡ missing) (rowsFrom (suc t) n p)) (sym eq) (closings-missing (suc t) n)

    -- A verdict is "yes" only when every period is a known "yes", with a
    -- status at least that of the verdict.
    verdict-yes : ∀ {u} (f : Row → Val Bool) rs → verdict f rs ≡ given u true → All (λ r → Yes u (f r)) rs
    verdict-yes f []       eq = tt
    verdict-yes {u} f (r ∷ rs) eq with ∧-yes {f r} {verdict f rs} eq
    ... | yr , (s , eq′ , le) = yr , All-map (λ {x} y → Yes-weaken {u} {s} {f x} le y) rs (verdict-yes f rs eq′)

    -- A known breach decides a verdict: it is "no", whatever is missing.
    breach-decides : ∀ (f : Row → Val Bool) rs →
      Any (λ r → Σ Status (λ s → f r ≡ given s false)) rs →
      Σ Status (λ u → verdict f rs ≡ given u false)
    breach-decides f []       ()
    breach-decides f (r ∷ rs) (inj₁ (s , eq)) = s , ∧-false-left {f r} {verdict f rs} eq
    breach-decides f (r ∷ rs) (inj₂ p) with breach-decides f rs p
    ... | t , eq = ∧-false-right {f r} {verdict f rs} eq

    -- The funding gap is given only when every shortfall is given, with a
    -- status at least that of the gap.
    gap-needs : ∀ {u} rs → Covers u (worst rs) → All (λ r → Covers u (Row.shortfall r)) rs
    gap-needs []       c = tt
    gap-needs (r ∷ rs) c with zipWith-needs c
    ... | cs , rest = cs , gap-needs rs rest
