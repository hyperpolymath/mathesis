(* SPDX-License-Identifier: MPL-2.0 *)
(* Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> *)

(** THY-1, Rocq leg (re-proved by hand).

    Source of truth: verification/proofs/agda/FeatureReachability.agda.
    This file restates the same definitions and theorems and proves them
    again; it is not a translation. docs/status/PROOF-STATUS.adoc records
    how the statements were compared.

    Correspondence choices, all mirrored from the Agda source:
    - Agda's [Set] is [Type] here, so relations stay proof-relevant.
    - Agda's empty type [⊥] is [Bot], and [¬ A] is [A -> Bot].
    - Agda's [_≡_] is Rocq's [eq]; it appears only in the [src] and [dst]
      fields of [Edge], where proof relevance plays no part.
    - [All (On S)] is nested inside [On], as in the Agda.

    Only the prelude is used: no library is required. *)

Inductive Bot : Type := .

Definition Not (A : Type) : Type := A -> Bot.

Inductive All {A : Type} (P : A -> Type) : list A -> Type :=
| All_nil  : All P nil
| All_cons : forall x xs, P x -> All P xs -> All P (cons x xs).

(** * 1. The abstract result *)

Section Monotone.
  Variables (Node Ctx : Type) (le : Ctx -> Ctx -> Type)
            (Edge : Ctx -> Node -> Node -> Type)
            (edge_mono : forall F G u v, le F G -> Edge F u v -> Edge G u v).

  Inductive Reach (F : Ctx) (root : Node) : Node -> Type :=
  | here : Reach F root root
  | step : forall u v, Reach F root u -> Edge F u v -> Reach F root v.

  Fixpoint reach_mono F G root v (h : le F G) (r : Reach F root v)
    {struct r} : Reach G root v :=
    match r in Reach _ _ w return Reach G root w with
    | here _ _ => here G root
    | step _ _ u w r' e =>
        step G root u w (reach_mono F G root u h r') (edge_mono F G u w h e)
    end.

  Definition absent_below F G root v (h : le F G)
    (absent : Not (Reach G root v)) : Not (Reach F root v) :=
    fun r => absent (reach_mono F G root v h r).
End Monotone.

(** * 2. The Cargo-shaped instance *)

Section Cargo.
  Variables (Node Feat Target Rule Dep : Type)
            (premises : Rule -> list Feat) (conclusion : Rule -> Feat)
            (from to : Dep -> Node) (guard : Dep -> list Feat)
            (targetOk : Target -> Dep -> Type).

  Definition Request : Type := Feat -> Type.

  Definition sub (S T : Request) : Type := forall f, S f -> T f.

  Inductive On (S : Request) : Feat -> Type :=
  | asked   : forall f, S f -> On S f
  | implied : forall r, All (On S) (premises r) -> On S (conclusion r).

  Fixpoint on_mono S T (h : sub S T) f (o : On S f) {struct o} : On T f :=
    match o in On _ g return On T g with
    | asked _ g s => asked T g (h g s)
    | implied _ r ps =>
        implied T r
          ((fix go fs (a : All (On S) fs) {struct a} : All (On T) fs :=
              match a in All _ gs return All (On T) gs with
              | All_nil _ => All_nil _
              | All_cons _ x xs p ps' =>
                  All_cons _ x xs (on_mono S T h x p) (go xs ps')
              end) (premises r) ps)
    end.

  Fixpoint on_mono_all S T (h : sub S T) fs (a : All (On S) fs) {struct a}
    : All (On T) fs :=
    match a in All _ gs return All (On T) gs with
    | All_nil _ => All_nil _
    | All_cons _ x xs p ps => All_cons _ x xs (on_mono S T h x p)
                                          (on_mono_all S T h xs ps)
    end.

  Record Edge (t : Target) (S : Request) (u v : Node) : Type := MkEdge {
    dep     : Dep;
    src     : from dep = u;
    dst     : to dep = v;
    onT     : targetOk t dep;
    enabled : All (On S) (guard dep)
  }.

  Definition edge_mono t S T u v (h : sub S T) (e : Edge t S u v)
    : Edge t T u v :=
    match e with
    | MkEdge _ _ _ _ d s1 s2 o en =>
        MkEdge t T u v d s1 s2 o (on_mono_all S T h (guard d) en)
    end.

  Definition all_features : Request := fun _ => unit.

  Definition below_all (S : Request) : sub S all_features := fun _ _ => tt.

  (** The watch page's rule, per target. *)
  Theorem absent_under_all_features :
    forall root v,
      (forall t, Not (Reach Node Request (Edge t) all_features root v)) ->
      forall t (S : Request), Not (Reach Node Request (Edge t) S root v).
  Proof.
    intros root v absent t S.
    exact (absent_below Node Request sub (Edge t)
             (fun F G u w h e => edge_mono t F G u w h e)
             S all_features root v (below_all S) (absent t)).
  Qed.
End Cargo.
