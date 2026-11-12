{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- The integer instance of the cohort model (Applied.IntNumber) is an
-- ordered abelian group: it satisfies `Laws` (Applied.Cash). So APP-2 and
-- APP-3 hold for the model as it runs on the worked examples, and the laws
-- are not vacuous. Built on Agda.Builtin only.
--
-- Method. Every integer i equals P i ⊖ Q i for two natural numbers. Sums
-- and comparisons then reduce to natural numbers: (a ⊖ b) + (c ⊖ d) is
-- (a + c) ⊖ (b + d), and i ≤ j compares P i + Q j with P j + Q i.

module Applied.IntLaws where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.Int using (Int; pos; negsuc)
open import Agda.Builtin.Nat using (Nat; zero; suc)
  renaming (_+_ to _+ℕ_; _-_ to _∸_; _<_ to _<ℕ_)
open import Applied.Cohort using (Number)
open import Applied.IntNumber using (intNumber; _⊖_; neg; _+ℤ_; _≤ℤ_)
open import Applied.Status using (T; tt; sym; cong; subst)
open import Applied.Cash using (Laws; trans; cong₂)

------------------------------------------------------------------------
-- Natural numbers

+0 : ∀ n → n +ℕ 0 ≡ n
+0 zero    = refl
+0 (suc n) = cong suc (+0 n)

+suc : ∀ m n → m +ℕ suc n ≡ suc (m +ℕ n)
+suc zero    n = refl
+suc (suc m) n = cong suc (+suc m n)

+comm : ∀ m n → m +ℕ n ≡ n +ℕ m
+comm zero    n = sym (+0 n)
+comm (suc m) n = trans (cong suc (+comm m n)) (sym (+suc n m))

+assoc : ∀ m n k → (m +ℕ n) +ℕ k ≡ m +ℕ (n +ℕ k)
+assoc zero    n k = refl
+assoc (suc m) n k = cong suc (+assoc m n k)

-- (w + x) + (y + z) ≡ (w + y) + (x + z)
swap : ∀ w x y z → (w +ℕ x) +ℕ (y +ℕ z) ≡ (w +ℕ y) +ℕ (x +ℕ z)
swap w x y z =
  trans (+assoc w x (y +ℕ z))
 (trans (cong (w +ℕ_) (trans (sym (+assoc x y z)) (trans (cong (_+ℕ z) (+comm x y)) (+assoc y x z))))
        (sym (+assoc w y (x +ℕ z))))

-- m ≤ n, as the integer order uses it: m < n + 1.
leq : Nat → Nat → Bool
leq m n = m <ℕ suc n

leq-refl : ∀ n → T (leq n n)
leq-refl zero    = tt
leq-refl (suc n) = leq-refl n

leq-trans : ∀ a b c → T (leq a b) → T (leq b c) → T (leq a c)
leq-trans zero    b       c       _ _ = tt
leq-trans (suc a) zero    c       () _
leq-trans (suc a) (suc b) zero    _ ()
leq-trans (suc a) (suc b) (suc c) p q = leq-trans a b c p q

leq-total : ∀ a b → leq a b ≡ false → T (leq b a)
leq-total zero    b       ()
leq-total (suc a) zero    _  = tt
leq-total (suc a) (suc b) eq = leq-total a b eq

leq-cancel : ∀ k x y → leq (k +ℕ x) (k +ℕ y) ≡ leq x y
leq-cancel zero    x y = refl
leq-cancel (suc k) x y = leq-cancel k x y

------------------------------------------------------------------------
-- Integers as differences

-- (k + a) ⊖ (k + b) ≡ a ⊖ b: one step is definitional.
⊖-cancelˡ : ∀ k a b → (k +ℕ a) ⊖ (k +ℕ b) ≡ a ⊖ b
⊖-cancelˡ zero    a b = refl
⊖-cancelˡ (suc k) a b = ⊖-cancelˡ k a b

⊖-cancelʳ : ∀ k a b → (a +ℕ k) ⊖ (b +ℕ k) ≡ a ⊖ b
⊖-cancelʳ k a b = trans (cong₂ _⊖_ (+comm a k) (+comm b k)) (⊖-cancelˡ k a b)

-- a ⊖ b depends only on the difference of a and b.
⊖-diff : ∀ a b c d → a +ℕ d ≡ c +ℕ b → a ⊖ b ≡ c ⊖ d
⊖-diff a b c d eq =
  trans (sym (⊖-cancelʳ d a b))
 (trans (cong (_⊖ (b +ℕ d)) eq)
 (trans (cong ((c +ℕ b) ⊖_) (+comm b d))
        (⊖-cancelʳ b c d)))

⊖-self : ∀ n → n ⊖ n ≡ pos 0
⊖-self zero    = refl
⊖-self (suc n) = ⊖-self n

P Q : Int → Nat
P (pos m)    = m
P (negsuc n) = 0
Q (pos m)    = 0
Q (negsuc n) = suc n

asDiff : ∀ i → i ≡ P i ⊖ Q i
asDiff (pos m)    = refl
asDiff (negsuc n) = refl

-- The parts of a ⊖ b have the difference of a and b.
⊖-parts : ∀ a b → P (a ⊖ b) +ℕ b ≡ a +ℕ Q (a ⊖ b)
⊖-parts zero    zero    = refl
⊖-parts (suc m) zero    = refl
⊖-parts zero    (suc n) = refl
⊖-parts (suc m) (suc n) = trans (+suc (P (m ⊖ n)) n) (cong suc (⊖-parts m n))

add-parts : ∀ i j → i +ℤ j ≡ (P i +ℕ P j) ⊖ (Q i +ℕ Q j)
add-parts (pos m)    (pos n)    = refl
add-parts (pos m)    (negsuc n) = cong (_⊖ suc n) (sym (+0 m))
add-parts (negsuc m) (pos n)    = cong (λ x → n ⊖ suc x) (sym (+0 m))
add-parts (negsuc m) (negsuc n) = cong negsuc (sym (+suc m n))

-- (a ⊖ b) + (c ⊖ d) ≡ (a + c) ⊖ (b + d)
⊖-+ : ∀ a b c d → (a ⊖ b) +ℤ (c ⊖ d) ≡ (a +ℕ c) ⊖ (b +ℕ d)
⊖-+ a b c d = trans (add-parts (a ⊖ b) (c ⊖ d)) (⊖-diff (p₁ +ℕ p₂) (q₁ +ℕ q₂) (a +ℕ c) (b +ℕ d) arith)
  where
  p₁ = P (a ⊖ b) ; q₁ = Q (a ⊖ b) ; p₂ = P (c ⊖ d) ; q₂ = Q (c ⊖ d)
  arith : (p₁ +ℕ p₂) +ℕ (b +ℕ d) ≡ (a +ℕ c) +ℕ (q₁ +ℕ q₂)
  arith =
    trans (swap p₁ p₂ b d)
   (trans (cong₂ _+ℕ_ (⊖-parts a b) (⊖-parts c d))
          (swap a q₁ c q₂))

------------------------------------------------------------------------
-- The order

ord : ∀ i j → (i ≤ℤ j) ≡ leq (P i +ℕ Q j) (P j +ℕ Q i)
ord (pos m)    (pos n)    = sym (cong₂ leq (+0 m) (+0 n))
ord (pos m)    (negsuc n) = sym (cong (λ x → leq x 0) (+suc m n))
ord (negsuc m) (pos n)    = refl
ord (negsuc m) (negsuc n) = refl

-- Comparing two differences.
ord-⊖ : ∀ a b c d → ((a ⊖ b) ≤ℤ (c ⊖ d)) ≡ leq (a +ℕ d) (c +ℕ b)
ord-⊖ a b c d =
  trans (ord (a ⊖ b) (c ⊖ d))
 (trans (sym (leq-cancel (b +ℕ d) _ _))
 (trans (cong₂ leq left right)
        (leq-cancel (q₁ +ℕ q₂) (a +ℕ d) (c +ℕ b))))
  where
  p₁ = P (a ⊖ b) ; q₁ = Q (a ⊖ b) ; p₂ = P (c ⊖ d) ; q₂ = Q (c ⊖ d)
  left : (b +ℕ d) +ℕ (p₁ +ℕ q₂) ≡ (q₁ +ℕ q₂) +ℕ (a +ℕ d)
  left =
    trans (+comm (b +ℕ d) (p₁ +ℕ q₂))
   (trans (swap p₁ q₂ b d)
   (trans (cong (_+ℕ (q₂ +ℕ d)) (⊖-parts a b))
   (trans (swap a q₁ q₂ d)
   (trans (cong ((a +ℕ q₂) +ℕ_) (+comm q₁ d))
   (trans (swap a q₂ d q₁)
   (trans (+comm (a +ℕ d) (q₂ +ℕ q₁))
          (cong (_+ℕ (a +ℕ d)) (+comm q₂ q₁))))))))
  right : (b +ℕ d) +ℕ (p₂ +ℕ q₁) ≡ (q₁ +ℕ q₂) +ℕ (c +ℕ b)
  right =
    trans (+comm (b +ℕ d) (p₂ +ℕ q₁))
   (trans (swap p₂ q₁ b d)
   (trans (cong ((p₂ +ℕ b) +ℕ_) (+comm q₁ d))
   (trans (swap p₂ b d q₁)
   (trans (+comm (p₂ +ℕ d) (b +ℕ q₁))
   (trans (cong ((b +ℕ q₁) +ℕ_) (⊖-parts c d))
   (trans (swap b q₁ c q₂)
   (trans (+comm (b +ℕ c) (q₁ +ℕ q₂))
          (cong ((q₁ +ℕ q₂) +ℕ_) (+comm b c)))))))))

------------------------------------------------------------------------
-- The laws

private
  open Number intNumber

  +-comm : ∀ i j → i +ℤ j ≡ j +ℤ i
  +-comm i j = trans (add-parts i j) (trans (cong₂ _⊖_ (+comm (P i) (P j)) (+comm (Q i) (Q j))) (sym (add-parts j i)))

  +-assoc : ∀ i j k → (i +ℤ j) +ℤ k ≡ i +ℤ (j +ℤ k)
  +-assoc i j k =
    trans (cong₂ _+ℤ_ (add-parts i j) (asDiff k))
   (trans (⊖-+ (P i +ℕ P j) (Q i +ℕ Q j) (P k) (Q k))
   (trans (cong₂ _⊖_ (+assoc (P i) (P j) (P k)) (+assoc (Q i) (Q j) (Q k)))
   (trans (sym (⊖-+ (P i) (Q i) (P j +ℕ P k) (Q j +ℕ Q k)))
          (sym (cong₂ _+ℤ_ (asDiff i) (add-parts j k))))))

  +-identityʳ : ∀ i → i +ℤ pos 0 ≡ i
  +-identityʳ (pos m)    = cong pos (+0 m)
  +-identityʳ (negsuc m) = refl

  +-inverseʳ : ∀ i → i +ℤ neg i ≡ pos 0
  +-inverseʳ (pos zero)    = refl
  +-inverseʳ (pos (suc n)) = ⊖-self n
  +-inverseʳ (negsuc m)    = ⊖-self m

  ≤-refl : ∀ i → T (i ≤ℤ i)
  ≤-refl (pos m)    = leq-refl m
  ≤-refl (negsuc m) = leq-refl m

  ≤-trans : ∀ i j k → T (i ≤ℤ j) → T (j ≤ℤ k) → T (i ≤ℤ k)
  ≤-trans (pos m)    (pos n)    (pos k)    p q = leq-trans m n k p q
  ≤-trans (pos m)    (pos n)    (negsuc k) p ()
  ≤-trans (pos m)    (negsuc n) k          () q
  ≤-trans (negsuc m) j          (pos k)    p q = tt
  ≤-trans (negsuc m) (pos n)    (negsuc k) p ()
  ≤-trans (negsuc m) (negsuc n) (negsuc k) p q = leq-trans k n m q p

  ≤-total : ∀ i j → (i ≤ℤ j) ≡ false → T (j ≤ℤ i)
  ≤-total (pos m)    (pos n)    eq = leq-total m n eq
  ≤-total (pos m)    (negsuc n) eq = tt
  ≤-total (negsuc m) (pos n)    ()
  ≤-total (negsuc m) (negsuc n) eq = leq-total n m eq

  -- Adding the same k to both sides leaves the comparison unchanged.
  ≤-+-same : ∀ i j k → ((i +ℤ k) ≤ℤ (j +ℤ k)) ≡ (i ≤ℤ j)
  ≤-+-same i j k =
    trans (cong₂ _≤ℤ_ (add-parts i k) (add-parts j k))
   (trans (ord-⊖ (P i +ℕ P k) (Q i +ℕ Q k) (P j +ℕ P k) (Q j +ℕ Q k))
   (trans (cong₂ leq (rearrange (P i) (P k) (Q j) (Q k)) (rearrange (P j) (P k) (Q i) (Q k)))
   (trans (leq-cancel (P k +ℕ Q k) (P i +ℕ Q j) (P j +ℕ Q i))
          (sym (ord i j)))))
    where
    rearrange : ∀ a k b l → (a +ℕ k) +ℕ (b +ℕ l) ≡ (k +ℕ l) +ℕ (a +ℕ b)
    rearrange a k b l = trans (swap a k b l) (+comm (a +ℕ b) (k +ℕ l))

  ≤-+ : ∀ i j k → T (i ≤ℤ j) → T ((i +ℤ k) ≤ℤ (j +ℤ k))
  ≤-+ i j k t = subst T (sym (≤-+-same i j k)) t

intLaws : Laws intNumber
intLaws = record
  { neg         = neg
  ; +-assoc     = +-assoc
  ; +-comm      = +-comm
  ; +-identityʳ = +-identityʳ
  ; +-inverseʳ  = +-inverseʳ
  ; -‿def       = λ a b → refl
  ; ≤-refl      = ≤-refl
  ; ≤-trans     = ≤-trans
  ; ≤-total     = ≤-total
  ; ≤-+         = ≤-+
  }

-- APP-2 and APP-3 for the model as it runs on the worked examples.
module OnIntegers = Applied.Cash.Proofs intNumber intLaws
