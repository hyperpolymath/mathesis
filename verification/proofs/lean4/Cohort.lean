/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

APP-1 to APP-4, Lean leg (re-proved by hand), and the integer laws.

Source of truth: verification/proofs/agda/Applied/ (Cohort, Status,
Missing, Cash, IntNumber, IntLaws). This file restates the same definitions,
clause for clause, and proves the same theorems again; it is not a
translation. docs/status/PROOF-STATUS.adoc records how the statements were
compared.

Correspondence choices, all mirrored from the Agda source:
- Agda's `_<_` and `_-_` on Nat (Agda.Builtin.Nat) are `natLt` and `monus`
  here, with the same clauses; Agda's `if_then_else_` on Bool is `cond`.
- Clauses that overlap in Agda (`meet`, `zipWith`, `kand`, `denominator`)
  are listed here case by case: Lean compiles overlapping patterns with
  `propext`. Each function is the same, case for case.
- Agda's `n div suc m` is Lean's `n / (m + 1)` (both round down; both give
  0 for a zero divisor).
- Agda's `T b` is `b = true`. Agda's proof-relevant records `Covers` and
  `Bounded` are existential propositions here, so that every result is a
  theorem that the axiom audit inspects.
- Agda's `All` and `Any` (functions on lists) are `Forall` and `Exists'`.
- The integers are Agda's: `Z` with `pos` and `negsuc`, and the same
  operations, not Lean's `Int`, whose core lemmas use `propext`.

Only Lean core is used: no `import`, no Mathlib, no `simp`, no `omega`.
-/

namespace Applied

/-! ## Natural numbers, as Agda.Builtin.Nat defines them -/

/-- Agda.Builtin.Nat `_<_`. It splits on the second argument first, as
    Agda's does, so `natLt m 0` reduces to `false` for any m. -/
def natLt (n m : Nat) : Bool :=
  match m, n with
  | 0,     _     => false
  | _ + 1, 0     => true
  | m + 1, n + 1 => natLt n m
termination_by structural m

/-- Agda.Builtin.Nat `_-_` (truncated subtraction), split as `natLt` is. -/
def monus (n m : Nat) : Nat :=
  match m, n with
  | 0,     n     => n
  | _ + 1, 0     => 0
  | m + 1, n + 1 => monus n m
termination_by structural m

def ndiv (n : Nat) : Nat → Nat
  | 0     => 0
  | m + 1 => n / (m + 1)

def pow (b : Nat) : Nat → Nat
  | 0     => 1
  | e + 1 => b * pow b e

/-! ## Evidence status -/

inductive Status
  | illustrative | estimate | reported | verified | definitional

open Status

def meet : Status → Status → Status
  | illustrative, illustrative => illustrative
  | illustrative, estimate => illustrative
  | illustrative, reported => illustrative
  | illustrative, verified => illustrative
  | illustrative, definitional => illustrative
  | estimate, illustrative => illustrative
  | estimate, estimate => estimate
  | estimate, reported => estimate
  | estimate, verified => estimate
  | estimate, definitional => estimate
  | reported, illustrative => illustrative
  | reported, estimate => estimate
  | reported, reported => reported
  | reported, verified => reported
  | reported, definitional => reported
  | verified, illustrative => illustrative
  | verified, estimate => estimate
  | verified, reported => reported
  | verified, verified => verified
  | verified, definitional => verified
  | definitional, illustrative => illustrative
  | definitional, estimate => estimate
  | definitional, reported => reported
  | definitional, verified => verified
  | definitional, definitional => definitional


def rank : Status → Nat
  | illustrative => 0
  | estimate     => 1
  | reported     => 2
  | verified     => 3
  | definitional => 4

def leB : Nat → Nat → Bool
  | 0,     _     => true
  | _ + 1, 0     => false
  | m + 1, n + 1 => leB m n

/-- `stLe s t`: status s is no stronger than status t. -/
def stLe (s t : Status) : Prop := leB (rank s) (rank t) = true

theorem leB_refl : ∀ n, leB n n = true
  | 0     => rfl
  | n + 1 => leB_refl n

theorem leB_trans : ∀ a b c, leB a b = true → leB b c = true → leB a c = true
  | 0,     _,     _,     _, _ => rfl
  | _ + 1, 0,     _,     h, _ => nomatch h
  | _ + 1, _ + 1, 0,     _, h => nomatch h
  | a + 1, b + 1, c + 1, p, q => leB_trans a b c p q

theorem stLe_refl (s : Status) : stLe s s := leB_refl (rank s)

theorem stLe_trans (s t u : Status) : stLe s t → stLe t u → stLe s u :=
  leB_trans (rank s) (rank t) (rank u)

theorem meet_le_left (s t : Status) : stLe (meet s t) s := by
  cases s <;> cases t <;> rfl

theorem meet_le_right (s t : Status) : stLe (meet s t) t := by
  cases s <;> cases t <;> rfl

theorem meet_assoc (s t u : Status) : meet (meet s t) u = meet s (meet t u) := by
  cases s <;> cases t <;> cases u <;> rfl

theorem meet_definitional (s : Status) : meet s definitional = s := by
  cases s <;> rfl

/-! ## Values that may be missing -/

inductive Val (α : Type)
  | missing : Val α
  | given : Status → α → Val α

open Val

def Val.pure {α : Type} (a : α) : Val α := given definitional a

def Val.map {α β : Type} (f : α → β) : Val α → Val β
  | missing   => missing
  | given s a => given s (f a)

def zipWith {α β γ : Type} (f : α → β → γ) (x : Val α) (y : Val β) : Val γ :=
  match x with
  | missing   => missing
  | given s a =>
    match y with
    | missing   => missing
    | given t b => given (meet s t) (f a b)

/-- Kleene conjunction: a known `false` decides the result. -/
def kand (x y : Val Bool) : Val Bool :=
  match x with
  | given s false => given s false
  | given s true  =>
    match y with
    | given t b => given (meet s t) b
    | missing   => missing
  | missing =>
    match y with
    | given t false => given t false
    | given _ true  => missing
    | missing       => missing

def at' {α : Type} : Nat → List (Val α) → Val α
  | _,     []      => missing
  | 0,     x :: _  => x
  | n + 1, _ :: xs => at' n xs

/-! ## Cohorts and rates -/

inductive Rate
  | perMille : Nat → Rate
  | fraction : Nat → Nat → Rate

inductive Cohort
  | observed : Nat → List (Val Nat) → Cohort
  | modelled : Nat → Val Nat → Val Rate → Val Rate → Cohort

open Rate Cohort

def denominator : Val Rate → Nat
  | given _ (fraction _ d) => d
  | given _ (perMille _)   => 1
  | missing                => 1

def scaleOf (periods : Nat) : List Cohort → Nat
  | []                         => 1
  | observed _ _ :: cs         => scaleOf periods cs
  | modelled _ _ c r :: cs     => denominator c * pow (denominator r) periods * scaleOf periods cs

def applyRate (scale x : Nat) : Rate → Nat
  | perMille m   => ndiv (ndiv x scale * m) 1000 * scale
  | fraction n d => ndiv (x * n) d

def joined (scale : Nat) (contacts : Val Nat) (conversion : Val Rate) : Val Nat :=
  zipWith (applyRate scale) (Val.map (fun n => n * scale) contacts) conversion

def renewed (scale : Nat) (start : Val Nat) (retention : Val Rate) : Nat → Val Nat
  | 0     => start
  | k + 1 => zipWith (applyRate scale) (renewed scale start retention k) retention

def cohortAt (scale t : Nat) : Cohort → Val Nat
  | observed start counts =>
      cond (natLt t start) (Val.pure 0) (Val.map (fun n => n * scale) (at' (monus t start) counts))
  | modelled start contacts conversion retention =>
      cond (natLt t start) (Val.pure 0) (renewed scale (joined scale contacts conversion) retention (monus t start))

def sumAt (scale t : Nat) : List Cohort → Val Nat
  | []      => Val.pure 0
  | c :: cs => zipWith (· + ·) (cohortAt scale t c) (sumAt scale t cs)

/-! ## The model -/

structure Number where
  R       : Type
  zero    : R
  add     : R → R → R
  sub     : R → R → R
  mul     : R → R → R
  le      : R → R → Bool
  fromNat : Nat → R

section Model

variable (N : Number)

def nmax (a b : N.R) : N.R := cond (N.le a b) b a

structure Inputs where
  periods  : Nat
  opening  : Val N.R
  price    : Val N.R
  unitCost : Val N.R
  minutes  : Val N.R
  fixed    : List (Val N.R)
  floor    : List (Val N.R)
  capacity : List (Val N.R)
  cohorts  : List Cohort

structure Row where
  members    : Val N.R
  receipts   : Val N.R
  payments   : Val N.R
  closing    : Val N.R
  shortfall  : Val N.R
  hours      : Val N.R
  cashOk     : Val Bool
  capacityOk : Val Bool

variable {N}

def scale (i : Inputs N) : Nat := scaleOf i.periods i.cohorts

def scaled (i : Inputs N) : Val N.R → Val N.R :=
  Val.map (fun x => N.mul x (N.fromNat (scale i)))

def rowAt (i : Inputs N) (t : Nat) (previous : Val N.R) : Row N :=
  let m   := Val.map N.fromNat (sumAt (scale i) t i.cohorts)
  let rec_ := zipWith N.mul i.price m
  let pay := zipWith N.add (scaled i (at' (monus t 1) i.fixed)) (zipWith N.mul i.unitCost m)
  let clo := zipWith N.sub (zipWith N.add previous rec_) pay
  let hrs := zipWith N.mul i.minutes m
  let flo := scaled i (at' (monus t 1) i.floor)
  { members    := m
    receipts   := rec_
    payments   := pay
    closing    := clo
    shortfall  := zipWith N.sub flo clo
    hours      := hrs
    cashOk     := zipWith N.le flo clo
    capacityOk := zipWith N.le hrs (scaled i (at' (monus t 1) i.capacity)) }

def rowsFrom (i : Inputs N) : Nat → Nat → Val N.R → List (Row N)
  | _, 0,     _        => []
  | t, n + 1, previous => rowAt i t previous :: rowsFrom i (t + 1) n (rowAt i t previous).closing

def allRows (i : Inputs N) : List (Row N) := rowsFrom i 1 i.periods (scaled i i.opening)

def verdict (f : Row N → Val Bool) : List (Row N) → Val Bool
  | []      => Val.pure true
  | r :: rs => kand (f r) (verdict f rs)

def worst : List (Row N) → Val N.R
  | []      => Val.pure N.zero
  | r :: rs => zipWith (nmax N) r.shortfall (worst rs)

end Model

/-! ## APP-1 and APP-4: what a given output needs -/

/-- `Covers u v`: v is given, with a status at least u. -/
def Covers {α : Type} (u : Status) (v : Val α) : Prop :=
  ∃ s a, v = given s a ∧ stLe u s

def Forall {α : Type} (P : α → Prop) : List α → Prop
  | []      => True
  | x :: xs => P x ∧ Forall P xs

def Exists' {α : Type} (P : α → Prop) : List α → Prop
  | []      => False
  | x :: xs => P x ∨ Exists' P xs

theorem forall_map {α : Type} {P Q : α → Prop} (f : ∀ x, P x → Q x) :
    ∀ xs, Forall P xs → Forall Q xs
  | [],      _      => True.intro
  | x :: xs, ⟨p, ps⟩ => ⟨f x p, forall_map f xs ps⟩

theorem covers_weaken {α : Type} {u w : Status} {v : Val α} (le : stLe u w) :
    Covers w v → Covers u v
  | ⟨s, a, e, le'⟩ => ⟨s, a, e, stLe_trans u w s le le'⟩

theorem zipWith_given {α β γ : Type} {f : α → β → γ} :
    ∀ {x : Val α} {y : Val β} {u : Status} {c : γ},
      zipWith f x y = given u c → Covers u x ∧ Covers u y
  | given s a, given t b, _, _, e => by
      cases e
      exact ⟨⟨s, a, rfl, meet_le_left s t⟩, ⟨t, b, rfl, meet_le_right s t⟩⟩
  | given _ _, missing, _, _, e => nomatch e
  | missing,   _,       _, _, e => nomatch e

theorem zipWith_needs {α β γ : Type} {f : α → β → γ} {x : Val α} {y : Val β} {u : Status}
    (c : Covers u (zipWith f x y)) : Covers u x ∧ Covers u y :=
  match c with
  | ⟨_, _, e, le⟩ =>
    match zipWith_given e with
    | ⟨cx, cy⟩ => ⟨covers_weaken le cx, covers_weaken le cy⟩

theorem map_needs {α β : Type} {f : α → β} :
    ∀ {x : Val α} {u : Status}, Covers u (Val.map f x) → Covers u x
  | given s a, _, ⟨_, _, e, le⟩ => by
      cases e
      exact ⟨s, a, rfl, le⟩
  | missing,   _, ⟨_, _, e, _⟩  => nomatch e

theorem missing_uncovered {α : Type} {u : Status} : ¬ Covers u (missing : Val α)
  | ⟨_, _, e, _⟩ => nomatch e

theorem cond_false {α : Type} {b : Bool} {x y : α} (h : b = false) : cond b x y = y := by
  cases h; rfl

theorem joined_needs {u : Status} {scale : Nat} {contacts : Val Nat} {conversion : Val Rate}
    (c : Covers u (joined scale contacts conversion)) : Covers u contacts ∧ Covers u conversion :=
  match zipWith_needs c with
  | ⟨cl, cc⟩ => ⟨map_needs cl, cc⟩

theorem renewed_joined {u : Status} {scale : Nat} {start : Val Nat} {retention : Val Rate} :
    ∀ k, Covers u (renewed scale start retention k) → Covers u start
  | 0,     c => c
  | k + 1, c => renewed_joined k (zipWith_needs c).1

theorem renewed_retention {u : Status} {scale : Nat} {start : Val Nat} {retention : Val Rate}
    (k : Nat) (c : Covers u (renewed scale start retention (k + 1))) : Covers u retention :=
  (zipWith_needs c).2

theorem modelled_needs {u : Status} {scale t start : Nat} {contacts : Val Nat}
    {conversion retention : Val Rate} (h : natLt t start = false)
    (c : Covers u (cohortAt scale t (modelled start contacts conversion retention))) :
    Covers u contacts ∧ Covers u conversion := by
  have e : cohortAt scale t (modelled start contacts conversion retention) =
      renewed scale (joined scale contacts conversion) retention (monus t start) :=
    cond_false h
  rw [e] at c
  exact joined_needs (renewed_joined _ c)

theorem modelled_renewal_needs {u : Status} {scale t start : Nat} {contacts : Val Nat}
    {conversion retention : Val Rate} (k : Nat) (h : natLt t start = false)
    (gap : monus t start = k + 1)
    (c : Covers u (cohortAt scale t (modelled start contacts conversion retention))) :
    Covers u retention := by
  have e : cohortAt scale t (modelled start contacts conversion retention) =
      renewed scale (joined scale contacts conversion) retention (monus t start) :=
    cond_false h
  rw [e, gap] at c
  exact renewed_retention k c

theorem observed_needs {u : Status} {scale t start : Nat} {counts : List (Val Nat)}
    (h : natLt t start = false) (c : Covers u (cohortAt scale t (observed start counts))) :
    Covers u (at' (monus t start) counts) := by
  have e : cohortAt scale t (observed start counts) =
      Val.map (fun n => n * scale) (at' (monus t start) counts) :=
    cond_false h
  rw [e] at c
  exact map_needs c

theorem sum_needs {u : Status} {scale t : Nat} :
    ∀ cs, Covers u (sumAt scale t cs) → Forall (fun c => Covers u (cohortAt scale t c)) cs
  | [],      _ => True.intro
  | _ :: cs, c => ⟨(zipWith_needs c).1, sum_needs cs (zipWith_needs c).2⟩

section Needs

variable {N : Number} (i : Inputs N)

theorem members_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).members) : Covers u (sumAt (scale i) t i.cohorts) :=
  map_needs c

theorem receipts_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).receipts) :
    Covers u i.price ∧ Covers u (sumAt (scale i) t i.cohorts) :=
  match zipWith_needs c with
  | ⟨cp, cm⟩ => ⟨cp, map_needs cm⟩

theorem payments_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).payments) :
    Covers u (at' (monus t 1) i.fixed) ∧ Covers u i.unitCost ∧ Covers u (sumAt (scale i) t i.cohorts) :=
  match zipWith_needs c with
  | ⟨cf, cv⟩ =>
    match zipWith_needs cv with
    | ⟨cu, cm⟩ => ⟨map_needs cf, cu, map_needs cm⟩

theorem closing_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).closing) :
    Covers u previous ∧ Covers u i.price ∧ Covers u (at' (monus t 1) i.fixed) ∧
      Covers u i.unitCost ∧ Covers u (sumAt (scale i) t i.cohorts) :=
  match zipWith_needs c with
  | ⟨cpr, cpay⟩ =>
    match zipWith_needs cpr, payments_needs i t previous cpay with
    | ⟨cprev, crec⟩, ⟨cf, cu, cm⟩ => ⟨cprev, (zipWith_needs crec).1, cf, cu, cm⟩

theorem shortfall_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).shortfall) :
    Covers u (at' (monus t 1) i.floor) ∧ Covers u (rowAt i t previous).closing :=
  match zipWith_needs c with
  | ⟨cfl, cc⟩ => ⟨map_needs cfl, cc⟩

theorem cashOk_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).cashOk) :
    Covers u (at' (monus t 1) i.floor) ∧ Covers u (rowAt i t previous).closing :=
  match zipWith_needs c with
  | ⟨cfl, cc⟩ => ⟨map_needs cfl, cc⟩

theorem hours_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).hours) :
    Covers u i.minutes ∧ Covers u (sumAt (scale i) t i.cohorts) :=
  match zipWith_needs c with
  | ⟨cmin, cm⟩ => ⟨cmin, map_needs cm⟩

theorem capacityOk_needs {u : Status} (t : Nat) (previous : Val N.R)
    (c : Covers u (rowAt i t previous).capacityOk) :
    Covers u i.minutes ∧ Covers u (sumAt (scale i) t i.cohorts) ∧ Covers u (at' (monus t 1) i.capacity) :=
  match zipWith_needs c with
  | ⟨ch, ccap⟩ =>
    match hours_needs i t previous ch with
    | ⟨cmin, cm⟩ => ⟨cmin, cm, map_needs ccap⟩

theorem opening_needs {u : Status} (c : Covers u (scaled i i.opening)) : Covers u i.opening :=
  map_needs c

theorem closings_missing : ∀ t n, Forall (fun r : Row N => r.closing = missing) (rowsFrom i t n missing)
  | _, 0     => True.intro
  | t, n + 1 => ⟨rfl, closings_missing (t + 1) n⟩

theorem missing_persists (t n : Nat) (previous : Val N.R) (h : (rowAt i t previous).closing = missing) :
    Forall (fun r : Row N => r.closing = missing) (rowsFrom i (t + 1) n (rowAt i t previous).closing) := by
  rw [h]
  exact closings_missing i (t + 1) n

/-- A "yes" needs both sides to be a known "yes". -/
def Yes (u : Status) (v : Val Bool) : Prop := ∃ s, v = given s true ∧ stLe u s

theorem kand_yes : ∀ {x y : Val Bool} {u : Status}, kand x y = given u true → Yes u x ∧ Yes u y
  | given s true,  given t b,     _, e => by
      cases e
      exact ⟨⟨s, rfl, meet_le_left s t⟩, ⟨t, rfl, meet_le_right s t⟩⟩
  | given _ true,  missing,       _, e => nomatch e
  | given _ false, _,             _, e => nomatch e
  | missing,       given _ false, _, e => nomatch e
  | missing,       given _ true,  _, e => nomatch e
  | missing,       missing,       _, e => nomatch e

theorem verdict_yes {u : Status} (f : Row N → Val Bool) :
    ∀ rs, verdict f rs = given u true → Forall (fun r => Yes u (f r)) rs
  | [],      _ => True.intro
  | _ :: rs, e =>
    match kand_yes e with
    | ⟨yr, ⟨s, e', le⟩⟩ =>
      ⟨yr, forall_map (fun _ ⟨s', ex, le'⟩ => ⟨s', ex, stLe_trans u s s' le le'⟩) rs (verdict_yes f rs e')⟩

theorem kand_false_left : ∀ {x y : Val Bool} {s : Status}, x = given s false → kand x y = given s false
  | _, _, _, rfl => rfl

theorem kand_false_right : ∀ {x y : Val Bool} {t : Status}, y = given t false →
    ∃ u, kand x y = given u false
  | given s false, _, _, rfl => ⟨s, rfl⟩
  | given s true,  _, t, rfl => ⟨meet s t, rfl⟩
  | missing,       _, t, rfl => ⟨t, rfl⟩

theorem breach_decides (f : Row N → Val Bool) :
    ∀ rs, Exists' (fun r => ∃ s, f r = given s false) rs → ∃ u, verdict f rs = given u false
  | [],      h                   => nomatch h
  | _ :: _,  Or.inl ⟨s, e⟩       => ⟨s, kand_false_left e⟩
  | _ :: rs, Or.inr p            =>
    match breach_decides f rs p with
    | ⟨_, e⟩ => kand_false_right e

theorem gap_needs {u : Status} : ∀ rs : List (Row N), Covers u (worst rs) →
    Forall (fun r => Covers u r.shortfall) rs
  | [],      _ => True.intro
  | _ :: rs, c => ⟨(zipWith_needs c).1, gap_needs rs (zipWith_needs c).2⟩

end Needs


/-! ## APP-2 and APP-3: ordered abelian groups -/

structure Laws (N : Number) where
  neg       : N.R → N.R
  add_assoc : ∀ a b c, N.add (N.add a b) c = N.add a (N.add b c)
  add_comm  : ∀ a b, N.add a b = N.add b a
  add_zero  : ∀ a, N.add a N.zero = a
  add_neg   : ∀ a, N.add a (neg a) = N.zero
  sub_def   : ∀ a b, N.sub a b = N.add a (neg b)
  le_refl   : ∀ a, N.le a a = true
  le_trans  : ∀ a b c, N.le a b = true → N.le b c = true → N.le a c = true
  le_total  : ∀ a b, N.le a b = false → N.le b a = true
  le_add    : ∀ a b c, N.le a b = true → N.le (N.add a c) (N.add b c) = true

section Cash

variable {N : Number} (L : Laws N)
include L

theorem step_law (a r q x : N.R) :
    N.add (N.sub (N.add a r) q) x = N.add a (N.add (N.sub r q) x) := by
  rw [L.sub_def, L.sub_def, L.add_assoc a r (L.neg q), L.add_assoc a (N.add r (L.neg q)) x]

theorem shift_law (a g r q : N.R) :
    N.sub (N.add (N.add a g) r) q = N.add (N.sub (N.add a r) q) g := by
  rw [L.sub_def, L.sub_def, L.add_assoc a g r, L.add_comm g r, ← L.add_assoc a r g,
    L.add_assoc (N.add a r) g (L.neg q), L.add_comm g (L.neg q), ← L.add_assoc (N.add a r) (L.neg q) g]

theorem cancel_right (f c : N.R) : N.add (N.sub f c) c = f := by
  rw [L.sub_def, L.add_assoc, L.add_comm (L.neg c) c, L.add_neg, L.add_zero]

theorem cancel_left (c g : N.R) : N.add (N.add c g) (L.neg c) = g := by
  rw [L.add_comm c g, L.add_assoc, L.add_neg, L.add_zero]

/-- f − c ≤ g gives f ≤ c + g. -/
theorem below_shift (f c g : N.R) (h : N.le (N.sub f c) g = true) : N.le f (N.add c g) = true := by
  have k := L.le_add _ _ c h
  rw [cancel_right L, L.add_comm g c] at k
  exact k

/-- f ≤ c + g gives f − c ≤ g. -/
theorem shift_below (f c g : N.R) (h : N.le f (N.add c g) = true) : N.le (N.sub f c) g = true := by
  have k := L.le_add _ _ (L.neg c) h
  rw [cancel_left L, ← L.sub_def] at k
  exact k

omit L in
theorem meet4 (s t v w : Status) : meet (meet (meet s t) v) w = meet s (meet (meet t v) w) := by
  rw [meet_assoc (meet s t) v w, meet_assoc s t (meet v w), meet_assoc t v w]

theorem step_val : ∀ p r q n : Val N.R,
    zipWith N.add (zipWith N.sub (zipWith N.add p r) q) n =
      zipWith N.add p (zipWith N.add (zipWith N.sub r q) n)
  | given s a, given t b, given v c, given w d => by
      show given (meet (meet (meet s t) v) w) (N.add (N.sub (N.add a b) c) d) =
        given (meet s (meet (meet t v) w)) (N.add a (N.add (N.sub b c) d))
      rw [meet4, step_law L]
  | missing,   _,         _,         _         => rfl
  | given _ _, missing,   _,         _         => rfl
  | given _ _, given _ _, missing,   _         => rfl
  | given _ _, given _ _, given _ _, missing   => rfl

theorem base_val : ∀ p : Val N.R, p = zipWith N.add p (Val.pure N.zero)
  | missing   => rfl
  | given s a => by
      show given s a = given (meet s definitional) (N.add a N.zero)
      rw [meet_definitional, L.add_zero]

theorem shift_val : ∀ (p r q : Val N.R) (g : N.R),
    zipWith N.sub (zipWith N.add (Val.map (fun x => N.add x g) p) r) q =
      Val.map (fun x => N.add x g) (zipWith N.sub (zipWith N.add p r) q)
  | given s a, given t b, given v c, g => by
      show given (meet (meet s t) v) (N.sub (N.add (N.add a g) b) c) =
        given (meet (meet s t) v) (N.add (N.sub (N.add a b) c) g)
      rw [shift_law L]
  | missing,   _,         _,         _ => rfl
  | given _ _, missing,   _,         _ => rfl
  | given _ _, given _ _, missing,   _ => rfl

theorem floor_met : ∀ (F C : Val N.R) (g : N.R) {s : Status} {d : N.R},
    zipWith N.sub F C = given s d → N.le d g = true →
      ∃ s', zipWith N.le F (Val.map (fun x => N.add x g) C) = given s' true
  | given sf f, given sc c, g, _, _, e, h => by
      cases e
      exact ⟨meet sf sc, congrArg (given (meet sf sc)) (below_shift L f c g h)⟩
  | given _ _,  missing,    _, _, _, e, _ => nomatch e
  | missing,    _,          _, _, _, e, _ => nomatch e

theorem floor_needs : ∀ (F C : Val N.R) (g : N.R) {s s' : Status} {d : N.R},
    zipWith N.sub F C = given s d →
      zipWith N.le F (Val.map (fun x => N.add x g) C) = given s' true → N.le d g = true
  | given sf f, given sc c, g, _, _, _, e, ok => by
      cases e
      injection ok with _ h
      exact shift_below L f c g h
  | given _ _,  missing,    _, _, _, _, e, _ => nomatch e
  | missing,    _,          _, _, _, _, e, _ => nomatch e

theorem max_left (a b : N.R) : N.le a (nmax N a b) = true := by
  show N.le a (cond (N.le a b) b a) = true
  cases h : N.le a b
  · exact L.le_refl a
  · exact h

theorem max_right (a b : N.R) : N.le b (nmax N a b) = true := by
  show N.le b (cond (N.le a b) b a) = true
  cases h : N.le a b
  · exact L.le_total a b h
  · exact L.le_refl b

omit L in
theorem max_least (a b c : N.R) (ha : N.le a c = true) (hb : N.le b c = true) :
    N.le (nmax N a b) c = true := by
  show N.le (cond (N.le a b) b a) c = true
  cases N.le a b
  · exact ha
  · exact hb

variable (i : Inputs N)

omit L in
def lastClosing : Val N.R → List (Row N) → Val N.R
  | p, []      => p
  | _, r :: rs => lastClosing r.closing rs

omit L in
def netSum : List (Row N) → Val N.R
  | []      => Val.pure N.zero
  | r :: rs => zipWith N.add (zipWith N.sub r.receipts r.payments) (netSum rs)

/-- APP-2: the closing cash of the last period is the opening cash plus,
    summed over the periods, receipts minus payments. Both sides are
    missing together, with the same status when given. -/
theorem cash_identity : ∀ (t n : Nat) (p : Val N.R),
    lastClosing p (rowsFrom i t n p) = zipWith N.add p (netSum (rowsFrom i t n p))
  | _, 0,     p => base_val L p
  | t, n + 1, p =>
    (cash_identity (t + 1) n (rowAt i t p).closing).trans
      (step_val L p (rowAt i t p).receipts (rowAt i t p).payments
        (netSum (rowsFrom i (t + 1) n (rowAt i t p).closing)))

/-- Adding g to the previous balance adds g to the closing balance. -/
theorem shifted_closing (t : Nat) (p : Val N.R) (g : N.R) :
    (rowAt i t (Val.map (fun x => N.add x g) p)).closing =
      Val.map (fun x => N.add x g) (rowAt i t p).closing :=
  shift_val L p (rowAt i t p).receipts (rowAt i t p).payments g

omit L in
/-- A shortfall bounded by g. -/
def Bounded (g : N.R) (v : Val N.R) : Prop := ∃ s d, v = given s d ∧ N.le d g = true

omit L in
/-- The floor holds in a row. -/
def Met (r : Row N) : Prop := ∃ s, r.cashOk = given s true

theorem worst_bounds : ∀ (rs : List (Row N)) {u : Status} {g : N.R},
    worst rs = given u g → Forall (fun r => Bounded g r.shortfall) rs
  | [],      _, _, _ => True.intro
  | r :: rs, _, g, e =>
    match zipWith_given e with
    | ⟨⟨s, d, eqd, _⟩, ⟨w, m, eqm, _⟩⟩ => by
      have e' : zipWith (nmax N) r.shortfall (worst rs) = given _ g := e
      rw [eqd, eqm] at e'
      injection e' with _ hg
      refine ⟨⟨s, d, eqd, ?_⟩, forall_map (fun _ ⟨s', d', e2, t2⟩ => ⟨s', d', e2, ?_⟩) rs (worst_bounds rs eqm)⟩
      · rw [← hg]; exact max_left L d m
      · exact L.le_trans d' m g t2 (by rw [← hg]; exact max_right L d m)

/-- APP-3, sound: when every shortfall is at most g, adding g to the
    previous balance meets the floor in every period. -/
theorem meets_floor : ∀ (t n : Nat) (p : Val N.R) (g : N.R),
    Forall (fun r => Bounded g r.shortfall) (rowsFrom i t n p) →
      Forall Met (rowsFrom i t n (Val.map (fun x => N.add x g) p))
  | _, 0,     _, _, _                            => True.intro
  | t, n + 1, p, g, ⟨⟨_, _, eq, le⟩, rest⟩ => by
    have hc := shifted_closing L i t p g
    refine ⟨?_, ?_⟩
    · show ∃ s', zipWith N.le (scaled i (at' (monus t 1) i.floor))
          (rowAt i t (Val.map (fun x => N.add x g) p)).closing = given s' true
      rw [hc]
      exact floor_met L (scaled i (at' (monus t 1) i.floor)) (rowAt i t p).closing g eq le
    · show Forall Met (rowsFrom i (t + 1) n (rowAt i t (Val.map (fun x => N.add x g) p)).closing)
      rw [hc]
      exact meets_floor (t + 1) n (rowAt i t p).closing g rest

theorem gap_sound (t n : Nat) (p : Val N.R) {u : Status} {g : N.R}
    (e : worst (rowsFrom i t n p) = given u g) :
    Forall Met (rowsFrom i t n (Val.map (fun x => N.add x g) p)) :=
  meets_floor L i t n p g (worst_bounds L _ e)

/-- APP-3, least: no smaller non-negative addition meets every floor. -/
theorem gap_least : ∀ (t n : Nat) (p : Val N.R) {u : Status} {g : N.R} (g' : N.R),
    worst (rowsFrom i t n p) = given u g → N.le N.zero g' = true →
      Forall Met (rowsFrom i t n (Val.map (fun x => N.add x g') p)) → N.le g g' = true
  | _, 0,     _, _, _, _,  e, z, _ => by
      injection e with _ hg
      rw [← hg]; exact z
  | t, n + 1, p, _, g, g', e, z, ⟨⟨s', ok⟩, rest⟩ =>
    match zipWith_given e with
    | ⟨⟨_, d, eqd, _⟩, ⟨_, m, eqm, _⟩⟩ => by
      have e' : zipWith (nmax N) (rowAt i t p).shortfall
          (worst (rowsFrom i (t + 1) n (rowAt i t p).closing)) = given _ g := e
      rw [eqd, eqm] at e'
      injection e' with _ hg
      have ok' : zipWith N.le (scaled i (at' (monus t 1) i.floor))
          (Val.map (fun x => N.add x g') (rowAt i t p).closing) = given s' true := by
        rw [← shifted_closing L i t p g']; exact ok
      have head := floor_needs L (scaled i (at' (monus t 1) i.floor)) (rowAt i t p).closing g' eqd ok'
      have rest' : Forall Met (rowsFrom i (t + 1) n (Val.map (fun x => N.add x g') (rowAt i t p).closing)) := by
        rw [← shifted_closing L i t p g']; exact rest
      have tail := gap_least (t + 1) n (rowAt i t p).closing g' eqm z rest'
      rw [← hg]
      exact max_least d m g' head tail

end Cash


/-! ## The integer instance satisfies the laws -/

inductive Z
  | pos : Nat → Z
  | negsuc : Nat → Z

open Z

def ominus (m n : Nat) : Z := cond (natLt m n) (negsuc (monus (monus n m) 1)) (pos (monus m n))

def zneg : Z → Z
  | pos 0       => pos 0
  | pos (n + 1) => negsuc n
  | negsuc n    => pos (n + 1)

def zadd : Z → Z → Z
  | pos m,    pos n    => pos (m + n)
  | pos m,    negsuc n => ominus m (n + 1)
  | negsuc m, pos n    => ominus n (m + 1)
  | negsuc m, negsuc n => negsuc (m + n + 1)

def zsub (a b : Z) : Z := zadd a (zneg b)

def zmul : Z → Z → Z
  | pos m,    pos n    => pos (m * n)
  | pos m,    negsuc n => zneg (pos (m * (n + 1)))
  | negsuc m, pos n    => zneg (pos ((m + 1) * n))
  | negsuc m, negsuc n => pos ((m + 1) * (n + 1))

def zle : Z → Z → Bool
  | pos m,    pos n    => natLt m (n + 1)
  | pos _,    negsuc _ => false
  | negsuc _, pos _    => true
  | negsuc m, negsuc n => natLt n (m + 1)

def intNumber : Number :=
  { R := Z, zero := pos 0, add := zadd, sub := zsub, mul := zmul, le := zle, fromNat := pos }

/-- m ≤ n, as the integer order uses it. -/
def leq (m n : Nat) : Bool := natLt m (n + 1)

theorem leq_refl : ∀ n, leq n n = true
  | 0     => rfl
  | n + 1 => leq_refl n

theorem leq_trans : ∀ a b c, leq a b = true → leq b c = true → leq a c = true
  | 0,     _,     _,     _, _ => rfl
  | _ + 1, 0,     _,     h, _ => nomatch h
  | _ + 1, _ + 1, 0,     _, h => nomatch h
  | a + 1, b + 1, c + 1, p, q => leq_trans a b c p q

theorem leq_total : ∀ a b, leq a b = false → leq b a = true
  | 0,     _,     h => nomatch h
  | _ + 1, 0,     _ => rfl
  | a + 1, b + 1, h => leq_total a b h

theorem leq_cancel_right : ∀ k x y, leq (x + k) (y + k) = leq x y
  | 0,     _, _ => rfl
  | k + 1, x, y => leq_cancel_right k x y

theorem leq_cancel (k x y : Nat) : leq (k + x) (k + y) = leq x y := by
  rw [Nat.add_comm k x, Nat.add_comm k y]
  exact leq_cancel_right k x y

/-- (w + x) + (y + z) = (w + y) + (x + z) -/
theorem swap (w x y z : Nat) : (w + x) + (y + z) = (w + y) + (x + z) := by
  rw [Nat.add_assoc w x (y + z), Nat.add_left_comm x y z, ← Nat.add_assoc w y (x + z)]

theorem ominus_cancel_right : ∀ k a b, ominus (a + k) (b + k) = ominus a b
  | 0,     _, _ => rfl
  | k + 1, a, b => ominus_cancel_right k a b

theorem ominus_diff (a b c d : Nat) (h : a + d = c + b) : ominus a b = ominus c d := by
  rw [← ominus_cancel_right d a b, h, Nat.add_comm b d, ominus_cancel_right b c d]

theorem ominus_self : ∀ n, ominus n n = pos 0
  | 0     => rfl
  | n + 1 => ominus_self n

def P : Z → Nat
  | pos m    => m
  | negsuc _ => 0

def Q : Z → Nat
  | pos _    => 0
  | negsuc n => n + 1

theorem asDiff : ∀ i, i = ominus (P i) (Q i)
  | pos _    => rfl
  | negsuc _ => rfl

theorem ominus_parts : ∀ a b, P (ominus a b) + b = a + Q (ominus a b)
  | 0,     0     => rfl
  | _ + 1, 0     => rfl
  | 0,     _ + 1 => rfl
  | m + 1, n + 1 => by
    show P (ominus m n) + n + 1 = m + 1 + Q (ominus m n)
    rw [ominus_parts m n, Nat.add_right_comm m 1 (Q (ominus m n))]

theorem add_parts : ∀ i j, zadd i j = ominus (P i + P j) (Q i + Q j)
  | pos _,    pos _    => rfl
  | pos m,    negsuc n => by
    show ominus m (n + 1) = ominus m (0 + (n + 1))
    rw [Nat.zero_add]
  | negsuc m, pos n    => by
    show ominus n (m + 1) = ominus (0 + n) (m + 1)
    rw [Nat.zero_add]
  | negsuc m, negsuc n => by
    show negsuc (m + n + 1) = negsuc (m + 1 + n)
    rw [Nat.add_right_comm m 1 n]

theorem ominus_add (a b c d : Nat) : zadd (ominus a b) (ominus c d) = ominus (a + c) (b + d) := by
  rw [add_parts]
  apply ominus_diff
  rw [swap, ominus_parts a b, ominus_parts c d, swap a (Q (ominus a b)) c (Q (ominus c d))]

theorem ord : ∀ i j, zle i j = leq (P i + Q j) (P j + Q i)
  | pos _,    pos _    => rfl
  | pos _,    negsuc _ => rfl
  | negsuc _, pos _    => rfl
  | negsuc m, negsuc n => by
    show natLt n (m + 1) = leq (0 + (n + 1)) (0 + (m + 1))
    rw [Nat.zero_add, Nat.zero_add]
    rfl

theorem ord_ominus (a b c d : Nat) : zle (ominus a b) (ominus c d) = leq (a + d) (c + b) := by
  rw [ord, ← leq_cancel (b + d)]
  have left : b + d + (P (ominus a b) + Q (ominus c d)) =
      Q (ominus a b) + Q (ominus c d) + (a + d) := by
    rw [Nat.add_comm (b + d), swap (P (ominus a b)) (Q (ominus c d)) b d, ominus_parts a b,
      Nat.add_comm a (Q (ominus a b)), swap (Q (ominus a b)) a (Q (ominus c d)) d]
  have right : b + d + (P (ominus c d) + Q (ominus a b)) =
      Q (ominus a b) + Q (ominus c d) + (c + b) := by
    rw [Nat.add_comm (b + d), swap (P (ominus c d)) (Q (ominus a b)) b d,
      Nat.add_comm (Q (ominus a b)) d, swap (P (ominus c d)) b d (Q (ominus a b)), ominus_parts c d,
      swap c (Q (ominus c d)) b (Q (ominus a b)), Nat.add_comm (c + b),
      Nat.add_comm (Q (ominus c d)) (Q (ominus a b))]
  rw [left, right, leq_cancel]

theorem zadd_comm (i j : Z) : zadd i j = zadd j i := by
  rw [add_parts i j, add_parts j i, Nat.add_comm (P i), Nat.add_comm (Q i)]

theorem zadd_assoc (i j k : Z) : zadd (zadd i j) k = zadd i (zadd j k) :=
  calc zadd (zadd i j) k
      = zadd (ominus (P i + P j) (Q i + Q j)) (ominus (P k) (Q k)) := by
        rw [add_parts i j, ← asDiff k]
    _ = ominus (P i + P j + P k) (Q i + Q j + Q k) := ominus_add _ _ _ _
    _ = ominus (P i + (P j + P k)) (Q i + (Q j + Q k)) := by
        rw [Nat.add_assoc (P i), Nat.add_assoc (Q i)]
    _ = zadd (ominus (P i) (Q i)) (ominus (P j + P k) (Q j + Q k)) := (ominus_add _ _ _ _).symm
    _ = zadd i (zadd j k) := by rw [← asDiff i, ← add_parts j k]

theorem zadd_zero : ∀ i, zadd i (pos 0) = i
  | pos _    => rfl
  | negsuc _ => rfl

theorem zadd_neg : ∀ i, zadd i (zneg i) = pos 0
  | pos 0       => rfl
  | pos (n + 1) => ominus_self n
  | negsuc m    => ominus_self m

theorem zle_add_same (i j k : Z) : zle (zadd i k) (zadd j k) = zle i j := by
  rw [add_parts i k, add_parts j k, ord_ominus, ord i j]
  have r : ∀ a k b l, a + k + (b + l) = k + l + (a + b) := fun a k b l => by
    rw [swap, Nat.add_comm]
  rw [r (P i) (P k) (Q j) (Q k), r (P j) (P k) (Q i) (Q k), leq_cancel]

theorem zle_refl : ∀ i, zle i i = true
  | pos m    => leq_refl m
  | negsuc m => leq_refl m

theorem zle_trans : ∀ i j k, zle i j = true → zle j k = true → zle i k = true
  | pos m,    pos n,    pos k,    p, q => leq_trans m n k p q
  | pos _,    pos _,    negsuc _, _, q => nomatch q
  | pos _,    negsuc _, _,        p, _ => nomatch p
  | negsuc _, pos _,    pos _,    _, _ => rfl
  | negsuc _, negsuc _, pos _,    _, _ => rfl
  | negsuc _, pos _,    negsuc _, _, q => nomatch q
  | negsuc m, negsuc n, negsuc k, p, q => leq_trans k n m q p

theorem zle_total : ∀ i j, zle i j = false → zle j i = true
  | pos m,    pos n,    h => leq_total m n h
  | pos _,    negsuc _, _ => rfl
  | negsuc _, pos _,    h => nomatch h
  | negsuc m, negsuc n, h => leq_total n m h

def intLaws : Laws intNumber :=
  { neg       := zneg
    add_assoc := zadd_assoc
    add_comm  := zadd_comm
    add_zero  := zadd_zero
    add_neg   := zadd_neg
    sub_def   := fun _ _ => rfl
    le_refl   := zle_refl
    le_trans  := zle_trans
    le_total  := zle_total
    le_add    := fun i j k h => (zle_add_same i j k).trans h }

/-! APP-2 and APP-3 for the model as it runs on the worked examples. -/

theorem cash_identity_int (i : Inputs intNumber) (t n : Nat) (p : Val Z) :
    lastClosing p (rowsFrom i t n p) = zipWith zadd p (netSum (rowsFrom i t n p)) :=
  cash_identity intLaws i t n p

theorem gap_sound_int (i : Inputs intNumber) (t n : Nat) (p : Val Z) {u : Status} {g : Z}
    (e : worst (rowsFrom i t n p) = given u g) :
    Forall Met (rowsFrom i t n (Val.map (fun x => zadd x g) p)) :=
  gap_sound intLaws i t n p e

theorem gap_least_int (i : Inputs intNumber) (t n : Nat) (p : Val Z) {u : Status} {g : Z} (g' : Z)
    (e : worst (rowsFrom i t n p) = given u g) (z : zle (pos 0) g' = true)
    (m : Forall Met (rowsFrom i t n (Val.map (fun x => zadd x g') p))) : zle g g' = true :=
  gap_least intLaws i t n p g' e z m

end Applied
