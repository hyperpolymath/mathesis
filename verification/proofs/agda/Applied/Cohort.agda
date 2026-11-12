{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- A cohort model for the applied shelf (re-anchoring plan WO 4.2).
--
-- What it computes. Recruitment cohorts join and renew once in each
-- period. Their active members bring receipts and cost support time. The
-- model computes, for each period: active members, receipts, payments,
-- the closing cash balance, the shortfall below the cash floor, support
-- minutes, and whether the floor and the support capacity hold. Over all
-- periods it computes a verdict for each, and the funding gap: the least
-- amount that, added to the opening cash, keeps every closing balance at
-- or above its floor. The method is
-- applied-systems/finance/cohort-economics/README.adoc.
--
-- Missing values. Every input is `missing` or `given` with an evidence
-- status. An output is `missing` when any input that it depends on is
-- missing; it never becomes zero. Its status is never stronger than the
-- weakest input it depends on. A verdict is three-valued: a known breach
-- decides it even when other periods are missing (Kleene conjunction).
--
-- Number modes. The arithmetic is any `Number`. A cohort is `observed`
-- (counts per period: mode simple) or `modelled` from contacts, a
-- conversion rate and a retention rate. A rate is `perMille` (mode
-- approximate: whole members, rounded down at each step) or a `fraction`
-- (mode exact). In mode exact the model multiplies every quantity by one
-- common denominator, `scaleOf`, so that each value is a whole number and
-- nothing is rounded. Each output is then that number divided by the
-- scale.
--
-- The obligations APP-1 to APP-4 (docs/status/PROOF-NEEDS.adoc) are about
-- this module. They are open; this module states the model only.
--
-- The import cone is this file and Agda's built-in modules.

module Applied.Cohort where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Nat using (Nat; zero; suc; div-helper)
  renaming (_+_ to _+ℕ_; _*_ to _*ℕ_; _-_ to _∸_; _<_ to _<ℕ_)

if_then_else_ : {A : Set} → Bool → A → A → A
if true  then x else y = x
if false then x else y = y

------------------------------------------------------------------------
-- Evidence status (applied-systems/methods/evidence-and-assumptions.adoc)

-- From weakest to strongest. `missing` is not a status: a missing value
-- is the constructor `missing` of `Val`. `definitional` marks a value that
-- the model fixes itself (a cohort before its start, an empty sum); no
-- input carries it.
data Status : Set where
  illustrative estimate reported verified definitional : Status

-- The weaker of two statuses.
infixr 7 _⊓_
_⊓_ : Status → Status → Status
illustrative ⊓ _            = illustrative
_            ⊓ illustrative = illustrative
estimate     ⊓ _            = estimate
_            ⊓ estimate     = estimate
reported     ⊓ _            = reported
_            ⊓ reported     = reported
verified     ⊓ _            = verified
_            ⊓ verified     = verified
definitional ⊓ definitional = definitional

------------------------------------------------------------------------
-- Values that may be missing

data Val (A : Set) : Set where
  missing : Val A
  given   : Status → A → Val A

pure : {A : Set} → A → Val A
pure = given definitional

map : {A B : Set} → (A → B) → Val A → Val B
map f missing     = missing
map f (given s a) = given s (f a)

zipWith : {A B C : Set} → (A → B → C) → Val A → Val B → Val C
zipWith f (given s a) (given t b) = given (s ⊓ t) (f a b)
zipWith f _           _           = missing

-- Kleene conjunction: a known `false` decides the result.
infixr 6 _∧ᵏ_
_∧ᵏ_ : Val Bool → Val Bool → Val Bool
given s false ∧ᵏ _              = given s false
given s true  ∧ᵏ given t b      = given (s ⊓ t) b
given s true  ∧ᵏ missing        = missing
missing       ∧ᵏ given t false  = given t false
missing       ∧ᵏ _              = missing

-- The element at a position, counted from zero; `missing` past the end.
at : {A : Set} → Nat → List (Val A) → Val A
at _       []       = missing
at zero    (x ∷ _)  = x
at (suc n) (_ ∷ xs) = at n xs

------------------------------------------------------------------------
-- Natural-number helpers

_div_ : Nat → Nat → Nat
n div zero    = zero
n div (suc m) = div-helper 0 m n m

_^_ : Nat → Nat → Nat
b ^ zero  = 1
b ^ suc e = b *ℕ (b ^ e)

------------------------------------------------------------------------
-- Cohorts and rates

data Rate : Set where
  perMille : Nat → Rate         -- n per 1000; whole members, rounded down
  fraction : Nat → Nat → Rate   -- numerator and denominator; exact

data Cohort : Set where
  -- Mode simple: the first period, and the active members in that period
  -- and each one after it.
  observed : Nat → List (Val Nat) → Cohort
  -- Modes approximate and exact: the first period, the contacts, the
  -- conversion rate and the retention rate at each renewal.
  modelled : Nat → Val Nat → Val Rate → Val Rate → Cohort

denominator : Val Rate → Nat
denominator (given _ (fraction _ d)) = d
denominator _                        = 1

-- The common denominator of a run of `periods` periods: for each exact
-- cohort, the conversion denominator times the retention denominator to
-- the power `periods`. It is 1 when no rate is a fraction.
scaleOf : Nat → List Cohort → Nat
scaleOf periods []                       = 1
scaleOf periods (observed _ _ ∷ cs)      = scaleOf periods cs
scaleOf periods (modelled _ _ c r ∷ cs) =
  denominator c *ℕ (denominator r ^ periods) *ℕ scaleOf periods cs

-- Apply a rate to a count multiplied by the scale.
applyRate : Nat → Nat → Rate → Nat
applyRate scale x (perMille m)   = (((x div scale) *ℕ m) div 1000) *ℕ scale
applyRate scale x (fraction n d) = (x *ℕ n) div d

-- Active members of one cohort in period t (counted from 1), multiplied by
-- the scale.
cohortAt : Nat → Nat → Cohort → Val Nat
cohortAt scale t (observed start counts) =
  if t <ℕ start then pure 0
  else map (λ n → n *ℕ scale) (at (t ∸ start) counts)
cohortAt scale t (modelled start contacts conversion retention) =
  if t <ℕ start then pure 0 else renew (t ∸ start)
  where
  joined : Val Nat
  joined = zipWith (applyRate scale) (map (λ n → n *ℕ scale) contacts) conversion
  renew : Nat → Val Nat
  renew zero    = joined
  renew (suc k) = zipWith (applyRate scale) (renew k) retention

sumAt : Nat → Nat → List Cohort → Val Nat
sumAt scale t []       = pure 0
sumAt scale t (c ∷ cs) = zipWith _+ℕ_ (cohortAt scale t c) (sumAt scale t cs)

------------------------------------------------------------------------
-- The arithmetic of money, minutes and members

record Number : Set₁ where
  field
    R       : Set
    0#      : R
    _+_     : R → R → R
    _-_     : R → R → R
    _*_     : R → R → R
    _≤ᵇ_    : R → R → Bool
    fromNat : Nat → R

------------------------------------------------------------------------
-- The model

module Model (N : Number) where
  open Number N

  max : R → R → R
  max a b = if a ≤ᵇ b then b else a

  record Inputs : Set where
    field
      periods  : Nat
      opening  : Val R          -- cash at the start, in pence
      price    : Val R          -- receipts per active member per period, pence
      unitCost : Val R          -- avoidable cost per active member per period, pence
      minutes  : Val R          -- support minutes per active member per period
      fixed    : List (Val R)   -- fixed payments in each period, pence
      floor    : List (Val R)   -- agreed cash floor at the end of each period, pence
      capacity : List (Val R)   -- support minutes available in each period
      cohorts  : List Cohort

  -- Every money, minute and member value below is multiplied by the scale.
  record Row : Set where
    field
      members    : Val R
      receipts   : Val R
      payments   : Val R
      closing    : Val R
      shortfall  : Val R        -- floor minus closing; positive is a breach
      hours      : Val R        -- support minutes needed
      cashOk     : Val Bool     -- closing at or above the floor
      capacityOk : Val Bool     -- support minutes within capacity

  record Result : Set where
    field
      scale           : Nat
      rows            : List Row
      cashVerdict     : Val Bool
      capacityVerdict : Val Bool
      gap             : Val R   -- least addition to the opening cash that meets every floor

  module Run (i : Inputs) where
    open Inputs i

    scale : Nat
    scale = scaleOf periods cohorts

    scaled : Val R → Val R
    scaled = map (λ x → x * fromNat scale)

    -- The row of period t, after a closing balance of `previous`.
    rowAt : Nat → Val R → Row
    rowAt t previous = record
      { members    = m
      ; receipts   = rec
      ; payments   = pay
      ; closing    = clo
      ; shortfall  = zipWith _-_ flo clo
      ; hours      = hrs
      ; cashOk     = zipWith _≤ᵇ_ flo clo
      ; capacityOk = zipWith _≤ᵇ_ hrs (scaled (at (t ∸ 1) capacity))
      }
      where
      m   = map fromNat (sumAt scale t cohorts)
      rec = zipWith _*_ price m
      pay = zipWith _+_ (scaled (at (t ∸ 1) fixed)) (zipWith _*_ unitCost m)
      clo = zipWith _-_ (zipWith _+_ previous rec) pay
      hrs = zipWith _*_ minutes m
      flo = scaled (at (t ∸ 1) floor)

    -- Rows from period t onwards, `left` of them.
    rowsFrom : Nat → Nat → Val R → List Row
    rowsFrom t zero     previous = []
    rowsFrom t (suc n)  previous = r ∷ rowsFrom (suc t) n (Row.closing r)
      where r = rowAt t previous

    allRows : List Row
    allRows = rowsFrom 1 periods (scaled opening)

    verdict : (Row → Val Bool) → List Row → Val Bool
    verdict f []       = pure true
    verdict f (r ∷ rs) = f r ∧ᵏ verdict f rs

    worst : List Row → Val R
    worst []       = pure 0#
    worst (r ∷ rs) = zipWith max (Row.shortfall r) (worst rs)

    result : Result
    result = record
      { scale           = scale
      ; rows            = allRows
      ; cashVerdict     = verdict Row.cashOk allRows
      ; capacityVerdict = verdict Row.capacityOk allRows
      ; gap             = worst allRows
      }

  run : Inputs → Result
  run i = Run.result i
