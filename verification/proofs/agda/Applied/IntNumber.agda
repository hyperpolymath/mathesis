{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Integer arithmetic for the cohort model (Applied.Cohort), and the
-- checks that the generated worked examples use. All three number modes
-- run on these integers: mode exact multiplies every value by a common
-- denominator first. Each operation uses Agda's built-in natural-number
-- primitives, so large values check quickly.

module Applied.IntNumber where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Int using (Int; pos; negsuc)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Nat using (Nat; zero; suc)
  renaming (_+_ to _+ℕ_; _*_ to _*ℕ_; _-_ to _∸_; _<_ to _<ℕ_; _==_ to _==ℕ_)
open import Applied.Cohort

------------------------------------------------------------------------
-- Integers

_⊖_ : Nat → Nat → Int
m ⊖ n = if m <ℕ n then negsuc ((n ∸ m) ∸ 1) else pos (m ∸ n)

neg : Int → Int
neg (pos zero)    = pos zero
neg (pos (suc n)) = negsuc n
neg (negsuc n)    = pos (suc n)

_+ℤ_ : Int → Int → Int
pos m    +ℤ pos n    = pos (m +ℕ n)
pos m    +ℤ negsuc n = m ⊖ suc n
negsuc m +ℤ pos n    = n ⊖ suc m
negsuc m +ℤ negsuc n = negsuc (suc (m +ℕ n))

_-ℤ_ : Int → Int → Int
a -ℤ b = a +ℤ neg b

_*ℤ_ : Int → Int → Int
pos m    *ℤ pos n    = pos (m *ℕ n)
pos m    *ℤ negsuc n = neg (pos (m *ℕ suc n))
negsuc m *ℤ pos n    = neg (pos (suc m *ℕ n))
negsuc m *ℤ negsuc n = pos (suc m *ℕ suc n)

_≤ℤ_ : Int → Int → Bool
pos m    ≤ℤ pos n    = m <ℕ suc n
pos m    ≤ℤ negsuc n = false
negsuc m ≤ℤ pos n    = true
negsuc m ≤ℤ negsuc n = n <ℕ suc m

_==ℤ_ : Int → Int → Bool
pos m    ==ℤ pos n    = m ==ℕ n
negsuc m ==ℤ negsuc n = m ==ℕ n
_        ==ℤ _        = false

intNumber : Number
intNumber = record
  { R       = Int
  ; 0#      = pos 0
  ; _+_     = _+ℤ_
  ; _-_     = _-ℤ_
  ; _*_     = _*ℤ_
  ; _≤ᵇ_    = _≤ℤ_
  ; fromNat = pos
  }

open Model intNumber public

------------------------------------------------------------------------
-- Checks for the worked examples

_&&_ : Bool → Bool → Bool
true  && b = b
false && _ = false

sameStatus : Status → Status → Bool
sameStatus illustrative illustrative = true
sameStatus estimate     estimate     = true
sameStatus reported     reported     = true
sameStatus verified     verified     = true
sameStatus definitional definitional = true
sameStatus _            _            = false

sameBool : Bool → Bool → Bool
sameBool true  true  = true
sameBool false false = true
sameBool _     _     = false

-- An expected output of a worked example: absent (missing), a number
-- n / d with its status, or a truth value with its status.
data Expect : Set where
  absent : Expect
  number : Status → Int → Nat → Expect
  truth  : Status → Bool → Expect

-- A computed value, multiplied by `scale`, agrees with an expectation.
agrees : Nat → Val Int → Expect → Bool
agrees scale missing     absent         = true
agrees scale (given s x) (number t n d) =
  sameStatus s t && ((x *ℤ pos d) ==ℤ (n *ℤ pos scale))
agrees _     _           _              = false

agreesB : Val Bool → Expect → Bool
agreesB missing     absent      = true
agreesB (given s b) (truth t c) = sameStatus s t && sameBool b c
agreesB _           _           = false

data Field : Set where
  members receipts payments closing shortfall hours : Field
  cashOk capacityOk : Field

-- The value of one field in period t (counted from 1) agrees with an
-- expectation; false when the period does not exist.
check : Result → Nat → Field → Expect → Bool
check res t f e = inRange t (Result.rows res) && field' f (pick t (Result.rows res))
  where
  inRange : Nat → List Row → Bool
  inRange zero          _        = false
  inRange (suc zero)    (_ ∷ _)  = true
  inRange (suc (suc n)) (_ ∷ rs) = inRange (suc n) rs
  inRange _             []       = false
  pick : Nat → List Row → Row
  pick _ [] = record
    { members = missing ; receipts = missing ; payments = missing
    ; closing = missing ; shortfall = missing ; hours = missing
    ; cashOk = missing ; capacityOk = missing }
  pick (suc zero) (r ∷ _)  = r
  pick (suc n)    (_ ∷ rs) = pick n rs
  pick zero       (r ∷ _)  = r
  field' : Field → Row → Bool
  field' members    r = agrees (Result.scale res) (Row.members r) e
  field' receipts   r = agrees (Result.scale res) (Row.receipts r) e
  field' payments   r = agrees (Result.scale res) (Row.payments r) e
  field' closing    r = agrees (Result.scale res) (Row.closing r) e
  field' shortfall  r = agrees (Result.scale res) (Row.shortfall r) e
  field' hours      r = agrees (Result.scale res) (Row.hours r) e
  field' cashOk     r = agreesB (Row.cashOk r) e
  field' capacityOk r = agreesB (Row.capacityOk r) e

data Summary : Set where
  cashVerdict capacityVerdict gap : Summary

checkSummary : Result → Summary → Expect → Bool
checkSummary res cashVerdict     e = agreesB (Result.cashVerdict res) e
checkSummary res capacityVerdict e = agreesB (Result.capacityVerdict res) e
checkSummary res gap             e = agrees (Result.scale res) (Result.gap res) e
