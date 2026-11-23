/-
SPDX-License-Identifier: MPL-2.0
Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

THY-1, Lean leg (re-proved by hand).

Source of truth: verification/proofs/agda/FeatureReachability.agda. This
file restates the same definitions and theorems and proves them again; it
is not a translation. docs/status/PROOF-STATUS.adoc records how the
statements were compared.

Correspondence choices, all mirrored from the Agda source:
- Agda's `Set` is `Type` here, so relations stay proof-relevant.
- Agda's empty type `⊥` is `Empty`, and `¬ A` is `A → Empty`.
- Agda's `_≡_` is Lean's `Eq`; it appears only in the `src` and `dst`
  fields of `Edge`, where proof relevance plays no part.
- `All (On S)` is nested inside `On`, as in the Agda.

Every result is therefore a `def`, and a Lean `theorem` must be a
proposition. So each result is also stated about inhabitation (`Nonempty`)
as a `theorem` proved by the definition it names (sections 1 and 2, under
"As propositions"). Absence reads the same either way (`not'_iff`), and the
theorems put every definition here inside a theorem's axiom report, as the
Rocq leg's `Theorem absent_under_all_features` does. The gate also audits
the definitions directly.

Only Lean core is used: no `import`, no Mathlib.
-/

namespace FeatureReachability

def Not' (A : Type) : Type := A → Empty

inductive All {α : Type u} (P : α → Type v) : List α → Type (max u v)
  | nil : All P []
  | cons {x : α} {xs : List α} : P x → All P xs → All P (x :: xs)

/-- `Not'` and `¬ Nonempty` say the same thing: absence is proof-irrelevant. -/
theorem not'_iff {A : Type} : Nonempty (Not' A) ↔ ¬ Nonempty A :=
  ⟨fun ⟨n⟩ ⟨a⟩ => (n a).elim, fun h => ⟨fun a => (h ⟨a⟩).elim⟩⟩

/-! ## 1. The abstract result -/

section Monotone

variable {Node : Type} {Ctx : Type 1}

inductive Reach (Edge : Ctx → Node → Node → Type) (F : Ctx) (root : Node) :
    Node → Type
  | here : Reach Edge F root root
  | step {u v : Node} : Reach Edge F root u → Edge F u v → Reach Edge F root v

def reachMono (le : Ctx → Ctx → Type) (Edge : Ctx → Node → Node → Type)
    (edgeMono : ∀ {F G : Ctx} {u v : Node}, le F G → Edge F u v → Edge G u v)
    {F G : Ctx} {root v : Node} (h : le F G) :
    Reach Edge F root v → Reach Edge G root v
  | .here => .here
  | .step r e => .step (reachMono le Edge edgeMono h r) (edgeMono h e)

def absentBelow (le : Ctx → Ctx → Type) (Edge : Ctx → Node → Node → Type)
    (edgeMono : ∀ {F G : Ctx} {u v : Node}, le F G → Edge F u v → Edge G u v)
    {F G : Ctx} {root v : Node} (h : le F G)
    (absent : Not' (Reach Edge G root v)) : Not' (Reach Edge F root v) :=
  fun r => absent (reachMono le Edge edgeMono h r)

/-! As propositions. -/

theorem reach_mono (le : Ctx → Ctx → Type) (Edge : Ctx → Node → Node → Type)
    (edgeMono : ∀ {F G : Ctx} {u v : Node}, le F G → Edge F u v → Edge G u v)
    {F G : Ctx} {root v : Node} (h : le F G) :
    Nonempty (Reach Edge F root v) → Nonempty (Reach Edge G root v) :=
  fun ⟨r⟩ => ⟨reachMono le Edge edgeMono h r⟩

theorem absent_below (le : Ctx → Ctx → Type) (Edge : Ctx → Node → Node → Type)
    (edgeMono : ∀ {F G : Ctx} {u v : Node}, le F G → Edge F u v → Edge G u v)
    {F G : Ctx} {root v : Node} (h : le F G)
    (absent : ¬ Nonempty (Reach Edge G root v)) : ¬ Nonempty (Reach Edge F root v) :=
  fun ⟨r⟩ => (absentBelow le Edge edgeMono h (fun r' => (absent ⟨r'⟩).elim) r).elim

end Monotone

/-! ## 2. The Cargo-shaped instance -/

section Cargo

variable {Node Feat Target Rule Dep : Type}
  (premises : Rule → List Feat) (conclusion : Rule → Feat)
  (src' dst' : Dep → Node) (guard : Dep → List Feat)
  (targetOk : Target → Dep → Type)

def Request (Feat : Type) : Type 1 := Feat → Type

def Sub (S T : Request Feat) : Type := ∀ {f : Feat}, S f → T f

inductive On (premises : Rule → List Feat) (conclusion : Rule → Feat)
    (S : Request Feat) : Feat → Type
  | asked {f : Feat} : S f → On premises conclusion S f
  | implied (r : Rule) :
      All (On premises conclusion S) (premises r) →
      On premises conclusion S (conclusion r)

mutual
  def onMono {S T : Request Feat} (h : Sub S T) :
      {f : Feat} → On premises conclusion S f → On premises conclusion T f
    | _, .asked s => .asked (h s)
    | _, .implied r ps => .implied r (onMonoAll h ps)

  def onMonoAll {S T : Request Feat} (h : Sub S T) :
      {fs : List Feat} → All (On premises conclusion S) fs →
      All (On premises conclusion T) fs
    | _, .nil => .nil
    | _, .cons p ps => .cons (onMono h p) (onMonoAll h ps)
end

structure Edge (t : Target) (S : Request Feat) (u v : Node) : Type where
  dep     : Dep
  src     : src' dep = u
  dst     : dst' dep = v
  onT     : targetOk t dep
  enabled : All (On premises conclusion S) (guard dep)

def edgeMono (t : Target) {S T : Request Feat} {u v : Node} (h : Sub S T)
    (e : Edge premises conclusion src' dst' guard targetOk t S u v) :
    Edge premises conclusion src' dst' guard targetOk t T u v :=
  { dep := e.dep, src := e.src, dst := e.dst, onT := e.onT
    enabled := onMonoAll premises conclusion h e.enabled }

def allFeatures : Request Feat := fun _ => Unit

def belowAll (S : Request Feat) : Sub S (allFeatures (Feat := Feat)) :=
  fun _ => ()

/-- The watch page's rule, per target. -/
def absentUnderAllFeatures {root v : Node}
    (absent : ∀ t : Target,
      Not' (Reach (Edge premises conclusion src' dst' guard targetOk t)
        allFeatures root v)) :
    ∀ (t : Target) (S : Request Feat),
      Not' (Reach (Edge premises conclusion src' dst' guard targetOk t)
        S root v) :=
  fun t S =>
    absentBelow Sub (Edge premises conclusion src' dst' guard targetOk t)
      (fun h e => edgeMono premises conclusion src' dst' guard targetOk t h e)
      (belowAll S) (absent t)

/-! As propositions. -/

theorem on_mono {S T : Request Feat} (h : Sub S T) {f : Feat} :
    Nonempty (On premises conclusion S f) → Nonempty (On premises conclusion T f) :=
  fun ⟨o⟩ => ⟨onMono premises conclusion h o⟩

theorem edge_mono (t : Target) {S T : Request Feat} {u v : Node} (h : Sub S T) :
    Nonempty (Edge premises conclusion src' dst' guard targetOk t S u v) →
    Nonempty (Edge premises conclusion src' dst' guard targetOk t T u v) :=
  fun ⟨e⟩ => ⟨edgeMono premises conclusion src' dst' guard targetOk t h e⟩

/-- The watch page's rule, per target, as a proposition. -/
theorem absent_under_all_features {root v : Node}
    (absent : ∀ t : Target,
      ¬ Nonempty (Reach (Edge premises conclusion src' dst' guard targetOk t)
        allFeatures root v)) :
    ∀ (t : Target) (S : Request Feat),
      ¬ Nonempty (Reach (Edge premises conclusion src' dst' guard targetOk t)
        S root v) :=
  fun t S ⟨r⟩ =>
    (absentUnderAllFeatures premises conclusion src' dst' guard targetOk
      (fun t' r' => (absent t' ⟨r'⟩).elim) t S r).elim

end Cargo

end FeatureReachability
