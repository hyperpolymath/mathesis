{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- APP-2 (cash identity) and APP-3 (the funding gap is sound and least) for
-- the cohort model (Applied.Cohort).
--
-- Both hold for any number structure that is an ordered abelian group:
-- `Laws` below. The theorems need only these laws, not the laws of one
-- number type. Each is stated on `rowsFrom`, the rows from any period and
-- any previous balance, so it covers `allRows` and every tail of it.
-- Values are in the scaled units of the model (Applied.Cohort, `scaleOf`).

module Applied.Cash where

open import Agda.Builtin.Bool using (Bool; true; false)
open import Agda.Builtin.Equality using (_≡_; refl)
open import Agda.Builtin.List using (List; []; _∷_)
open import Agda.Builtin.Nat using (Nat; zero; suc) renaming (_-_ to _∸_)
open import Agda.Builtin.Sigma using (Σ; _,_)
open import Applied.Cohort
open import Applied.Status using (T; tt; ⊥; _×_; sym; cong; subst; covers; zipWith-given; ⊓-assoc; ⊓-identityʳ)
open import Applied.Missing using (All)

trans : ∀ {A : Set} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans refl q = q

cong₂ : ∀ {A B C : Set} (f : A → B → C) {x y u v} → x ≡ y → u ≡ v → f x u ≡ f y v
cong₂ f refl refl = refl

------------------------------------------------------------------------
-- Ordered abelian groups

record Laws (N : Number) : Set where
  open Number N
  field
    neg         : R → R
    +-assoc     : ∀ a b c → (a + b) + c ≡ a + (b + c)
    +-comm      : ∀ a b → a + b ≡ b + a
    +-identityʳ : ∀ a → a + 0# ≡ a
    +-inverseʳ  : ∀ a → a + neg a ≡ 0#
    -‿def       : ∀ a b → a - b ≡ a + neg b
    ≤-refl      : ∀ a → T (a ≤ᵇ a)
    ≤-trans     : ∀ a b c → T (a ≤ᵇ b) → T (b ≤ᵇ c) → T (a ≤ᵇ c)
    ≤-total     : ∀ a b → (a ≤ᵇ b) ≡ false → T (b ≤ᵇ a)
    ≤-+         : ∀ a b c → T (a ≤ᵇ b) → T ((a + c) ≤ᵇ (b + c))

module Proofs (N : Number) (L : Laws N) where
  open Number N
  open Laws L
  open Model N

  ----------------------------------------------------------------------
  -- Group lemmas

  private
    -- ((a + r) − q) + x ≡ a + ((r − q) + x)
    step-law : ∀ a r q x → ((a + r) - q) + x ≡ a + ((r - q) + x)
    step-law a r q x =
      trans (cong (λ y → y + x) (-‿def (a + r) q))
     (trans (cong (λ y → y + x) (+-assoc a r (neg q)))
     (trans (+-assoc a (r + neg q) x)
            (cong (λ y → a + (y + x)) (sym (-‿def r q)))))

    -- ((a + g) + r) − q ≡ ((a + r) − q) + g
    shift-law : ∀ a g r q → ((a + g) + r) - q ≡ ((a + r) - q) + g
    shift-law a g r q =
      trans (-‿def ((a + g) + r) q)
     (trans (cong (λ y → y + neg q) (+-assoc a g r))
     (trans (cong (λ y → (a + y) + neg q) (+-comm g r))
     (trans (cong (λ y → y + neg q) (sym (+-assoc a r g)))
     (trans (+-assoc (a + r) g (neg q))
     (trans (cong (λ y → (a + r) + y) (+-comm g (neg q)))
     (trans (sym (+-assoc (a + r) (neg q) g))
            (cong (λ y → y + g) (sym (-‿def (a + r) q)))))))))

    -- (f − c) + c ≡ f
    cancel-right : ∀ f c → (f - c) + c ≡ f
    cancel-right f c =
      trans (cong (λ y → y + c) (-‿def f c))
     (trans (+-assoc f (neg c) c)
     (trans (cong (λ y → f + y) (+-comm (neg c) c))
     (trans (cong (λ y → f + y) (+-inverseʳ c))
            (+-identityʳ f))))

    -- (c + g) + neg c ≡ g
    cancel-left : ∀ c g → (c + g) + neg c ≡ g
    cancel-left c g =
      trans (cong (λ y → y + neg c) (+-comm c g))
     (trans (+-assoc g c (neg c))
     (trans (cong (λ y → g + y) (+-inverseʳ c))
            (+-identityʳ g)))

    T-subst : ∀ {a b c d} → a ≡ c → b ≡ d → T (a ≤ᵇ b) → T (c ≤ᵇ d)
    T-subst refl refl t = t

    T→true : ∀ {b} → T b → b ≡ true
    T→true {true} _ = refl

    true→T : ∀ {b} → b ≡ true → T b
    true→T refl = tt

  -- f − c ≤ g  if and only if  f ≤ c + g
  below-shift : ∀ f c g → T ((f - c) ≤ᵇ g) → T (f ≤ᵇ (c + g))
  below-shift f c g t = T-subst (cancel-right f c) (+-comm g c) (≤-+ (f - c) g c t)

  shift-below : ∀ f c g → T (f ≤ᵇ (c + g)) → T ((f - c) ≤ᵇ g)
  shift-below f c g t = T-subst (sym (-‿def f c)) (cancel-left c g) (≤-+ f (c + g) (neg c) t)

  ----------------------------------------------------------------------
  -- Values that may be missing

  private
    valueOr : R → Val R → R
    valueOr d missing     = d
    valueOr _ (given _ x) = x

    truthOr : Val Bool → Bool
    truthOr missing     = false
    truthOr (given _ b) = b

    meet4 : ∀ s t v w → ((s ⊓ t) ⊓ v) ⊓ w ≡ s ⊓ ((t ⊓ v) ⊓ w)
    meet4 s t v w =
      trans (⊓-assoc (s ⊓ t) v w)
     (trans (⊓-assoc s t (v ⊓ w))
            (cong (λ y → s ⊓ y) (sym (⊓-assoc t v w))))

  -- One period of the cash identity, for values that may be missing.
  step-val : ∀ (p r q n : Val R) →
    zipWith _+_ (zipWith _-_ (zipWith _+_ p r) q) n ≡ zipWith _+_ p (zipWith _+_ (zipWith _-_ r q) n)
  step-val (given s a) (given t b) (given v c) (given w d) = cong₂ given (meet4 s t v w) (step-law a b c d)
  step-val missing     r           q           n           = refl
  step-val (given s a) missing     q           n           = refl
  step-val (given s a) (given t b) missing     n           = refl
  step-val (given s a) (given t b) (given v c) missing     = refl

  base-val : ∀ (p : Val R) → p ≡ zipWith _+_ p (pure 0#)
  base-val missing     = refl
  base-val (given s a) = sym (cong₂ given (⊓-identityʳ s) (+-identityʳ a))

  -- Adding g to the previous balance adds g to the closing balance.
  shift-val : ∀ (p r q : Val R) g →
    zipWith _-_ (zipWith _+_ (map (λ x → x + g) p) r) q ≡ map (λ x → x + g) (zipWith _-_ (zipWith _+_ p r) q)
  shift-val (given s a) (given t b) (given v c) g = cong (given ((s ⊓ t) ⊓ v)) (shift-law a g b c)
  shift-val missing     r           q           g = refl
  shift-val (given s a) missing     q           g = refl
  shift-val (given s a) (given t b) missing     g = refl

  -- The floor test after adding g, against the shortfall before.
  floor-met : ∀ (F C : Val R) g {s d} → zipWith _-_ F C ≡ given s d → T (d ≤ᵇ g) →
    Σ Status (λ s′ → zipWith _≤ᵇ_ F (map (λ x → x + g) C) ≡ given s′ true)
  floor-met (given sf f) (given sc c) g eq t =
    sf ⊓ sc , cong (given (sf ⊓ sc)) (T→true (below-shift f c g (subst (λ y → T (y ≤ᵇ g)) (sym (cong (valueOr 0#) eq)) t)))
  floor-met (given sf f) missing      g ()
  floor-met missing      C            g ()

  floor-needs : ∀ (F C : Val R) g {s d s′} → zipWith _-_ F C ≡ given s d →
    zipWith _≤ᵇ_ F (map (λ x → x + g) C) ≡ given s′ true → T (d ≤ᵇ g)
  floor-needs (given sf f) (given sc c) g eq ok =
    subst (λ y → T (y ≤ᵇ g)) (cong (valueOr 0#) eq) (shift-below f c g (true→T (cong truthOr ok)))
  floor-needs (given sf f) missing      g ()
  floor-needs missing      C            g ()

  -- The larger of two values bounds both, and is below any common bound.
  max-left : ∀ a b → T (a ≤ᵇ max a b)
  max-left a b with a ≤ᵇ b in eq
  ... | true  = true→T eq
  ... | false = ≤-refl a

  max-right : ∀ a b → T (b ≤ᵇ max a b)
  max-right a b with a ≤ᵇ b in eq
  ... | true  = ≤-refl b
  ... | false = ≤-total a b eq

  max-least : ∀ a b c → T (a ≤ᵇ c) → T (b ≤ᵇ c) → T (max a b ≤ᵇ c)
  max-least a b c ta tb with a ≤ᵇ b
  ... | true  = tb
  ... | false = ta

  module _ (i : Inputs) where
    open Inputs i
    open Run i

    -- The closing balance after a list of rows, and the sum over the rows
    -- of receipts minus payments.
    lastClosing : Val R → List Row → Val R
    lastClosing p []       = p
    lastClosing p (r ∷ rs) = lastClosing (Row.closing r) rs

    netSum : List Row → Val R
    netSum []       = pure 0#
    netSum (r ∷ rs) = zipWith _+_ (zipWith _-_ (Row.receipts r) (Row.payments r)) (netSum rs)

    -- APP-2. The closing cash of the last period equals the opening cash
    -- plus, summed over the periods, receipts minus payments. Both sides
    -- are missing together, with the same status when given.
    cash-identity : ∀ t n p → lastClosing p (rowsFrom t n p) ≡ zipWith _+_ p (netSum (rowsFrom t n p))
    cash-identity t zero    p = base-val p
    cash-identity t (suc n) p =
      trans (cash-identity (suc t) n (Row.closing (rowAt t p)))
            (step-val p (Row.receipts (rowAt t p)) (Row.payments (rowAt t p)) (netSum (rowsFrom (suc t) n (Row.closing (rowAt t p)))))

    -- Adding g to the previous balance adds g to every closing balance:
    -- the rows from p + g are the rows from p, shifted.
    shifted-closing : ∀ t p g → Row.closing (rowAt t (map (λ x → x + g) p)) ≡ map (λ x → x + g) (Row.closing (rowAt t p))
    shifted-closing t p g = shift-val p (Row.receipts (rowAt t p)) (Row.payments (rowAt t p)) g

    -- A shortfall bounded by g.
    Bounded : R → Val R → Set
    Bounded g v = Σ Status (λ s → Σ R (λ d → (v ≡ given s d) × T (d ≤ᵇ g)))

    Met : Row → Set
    Met r = Σ Status (λ s → Row.cashOk r ≡ given s true)

    -- The worst shortfall bounds every shortfall.
    worst-bounds : ∀ rs {u g} → worst rs ≡ given u g → All (λ r → Bounded g (Row.shortfall r)) rs
    worst-bounds []       eq = tt
    worst-bounds (r ∷ rs) {u} {g} eq with zipWith-given {f = max} {x = Row.shortfall r} {y = worst rs} eq
    ... | covers s d eqd _ , covers w m eqm _ =
      (s , d , eqd , subst (λ y → T (d ≤ᵇ y)) gval (max-left d m)) ,
      All-weaken rs (worst-bounds rs eqm)
      where
      gval : max d m ≡ g
      gval = trans (cong (valueOr 0#) (sym (cong₂ (zipWith max) eqd eqm))) (cong (valueOr 0#) eq)
      raise : ∀ {v} → Bounded m v → Bounded g v
      raise (s′ , d′ , e , t) = s′ , d′ , e , ≤-trans d′ m g t (subst (λ y → T (m ≤ᵇ y)) gval (max-right d m))
      All-weaken : ∀ xs → All (λ x → Bounded m (Row.shortfall x)) xs → All (λ x → Bounded g (Row.shortfall x)) xs
      All-weaken []       _        = tt
      All-weaken (x ∷ xs) (b , bs) = raise b , All-weaken xs bs

    -- APP-3, sound: when every shortfall is at most g, adding g to the
    -- previous balance meets the floor in every period.
    meets-floor : ∀ t n p g → All (λ r → Bounded g (Row.shortfall r)) (rowsFrom t n p) →
      All Met (rowsFrom t n (map (λ x → x + g) p))
    meets-floor t zero    p g _                            = tt
    meets-floor t (suc n) p g ((s , d , eq , le) , rest) =
      subst (λ c → Σ Status (λ s′ → zipWith _≤ᵇ_ (scaled (at (t ∸ 1) floor)) c ≡ given s′ true))
        (sym (shifted-closing t p g))
        (floor-met (scaled (at (t ∸ 1) floor)) (Row.closing (rowAt t p)) g eq le) ,
      subst (λ q → All Met (rowsFrom (suc t) n q)) (sym (shifted-closing t p g)) (meets-floor (suc t) n (Row.closing (rowAt t p)) g rest)

    gap-sound : ∀ t n p {u g} → worst (rowsFrom t n p) ≡ given u g →
      All Met (rowsFrom t n (map (λ x → x + g) p))
    gap-sound t n p eq = meets-floor t n p _ (worst-bounds (rowsFrom t n p) eq)

    -- APP-3, least: no smaller non-negative addition meets every floor.
    gap-least : ∀ t n p {u g} g′ → worst (rowsFrom t n p) ≡ given u g → T (0# ≤ᵇ g′) →
      All Met (rowsFrom t n (map (λ x → x + g′) p)) → T (g ≤ᵇ g′)
    gap-least t zero    p g′ eq z _ = subst (λ y → T (y ≤ᵇ g′)) (cong (valueOr 0#) eq) z
    gap-least t (suc n) p {u} {g} g′ eq z ((s′ , ok) , rest)
      with zipWith-given {f = max} {x = Row.shortfall (rowAt t p)} {y = worst (rowsFrom (suc t) n (Row.closing (rowAt t p)))} eq
    ... | covers s d eqd _ , covers w m eqm _ =
      subst (λ y → T (y ≤ᵇ g′)) gval (max-least d m g′ head tail)
      where
      gval : max d m ≡ g
      gval = trans (cong (valueOr 0#) (sym (cong₂ (zipWith max) eqd eqm))) (cong (valueOr 0#) eq)
      head : T (d ≤ᵇ g′)
      head = floor-needs (scaled (at (t ∸ 1) floor)) (Row.closing (rowAt t p)) g′ eqd
        (subst (λ c → zipWith _≤ᵇ_ (scaled (at (t ∸ 1) floor)) c ≡ given s′ true) (shifted-closing t p g′) ok)
      tail : T (m ≤ᵇ g′)
      tail = gap-least (suc t) n (Row.closing (rowAt t p)) g′ eqm z
        (subst (λ q → All Met (rowsFrom (suc t) n q)) (shifted-closing t p g′) rest)
