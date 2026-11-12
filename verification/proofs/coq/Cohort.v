(* SPDX-License-Identifier: MPL-2.0 *)
(* Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> *)

(** APP-1 to APP-4, Rocq leg (re-proved by hand), and the integer laws.

    Source of truth: verification/proofs/agda/Applied/ (Cohort, Status,
    Missing, Cash, IntNumber, IntLaws). This file restates the same
    definitions, clause for clause, and proves the same theorems again; it
    is not a translation. docs/status/PROOF-STATUS.adoc records how the
    statements were compared.

    Correspondence choices, all mirrored from the Agda source:
    - Agda's [_<_] and [_-_] on Nat are [natLt] and [monus] here, with the
      same clauses, recursive on the second argument as in Agda.
    - Agda's [T b] is [b = true]. Agda's proof-relevant records [Covers] and
      [Bounded] are existential propositions here.
    - Agda's [All] and [Any] (functions on lists) are [Forall'] and [Exists'].
    - The integers are Agda's: [Z'] with [pos] and [negsuc], and the same
      operations, not the standard library's [Z].
    - [lia] (standard library) proves the natural-number arithmetic; it adds
      no axiom, as the gate's [Print Assumptions] audit checks. *)

From Coq Require Import PeanoNat Lia.

(* Keep lia from writing a cache file beside the sources. *)
Unset Lia Cache.

(** * Natural numbers, as Agda.Builtin.Nat defines them *)

Fixpoint natLt (n m : nat) {struct m} : bool :=
  match m with
  | 0 => false
  | S m' => match n with 0 => true | S n' => natLt n' m' end
  end.

Fixpoint monus (n m : nat) {struct m} : nat :=
  match m with
  | 0 => n
  | S m' => match n with 0 => 0 | S n' => monus n' m' end
  end.

(** * Evidence status *)

Inductive Status : Type :=
  | illustrative | estimate | reported | verified | definitional.

Definition meet (s t : Status) : Status :=
  match s, t with
  | illustrative, _ => illustrative
  | _, illustrative => illustrative
  | estimate, _ => estimate
  | _, estimate => estimate
  | reported, _ => reported
  | _, reported => reported
  | verified, _ => verified
  | _, verified => verified
  | definitional, definitional => definitional
  end.

Definition rank (s : Status) : nat :=
  match s with
  | illustrative => 0 | estimate => 1 | reported => 2 | verified => 3 | definitional => 4
  end.

Fixpoint leB (m n : nat) : bool :=
  match m, n with
  | 0, _ => true
  | S _, 0 => false
  | S m', S n' => leB m' n'
  end.

(** [stLe s t]: status s is no stronger than status t. *)
Definition stLe (s t : Status) : Prop := leB (rank s) (rank t) = true.

Lemma leB_trans : forall a b c, leB a b = true -> leB b c = true -> leB a c = true.
Proof.
  intro a; induction a as [|a IH]; intros [|b] [|c] p q; simpl in *; try reflexivity; try discriminate.
  exact (IH b c p q).
Qed.

Lemma stLe_refl : forall s, stLe s s.
Proof. intros []; reflexivity. Qed.

Lemma stLe_trans : forall s t u, stLe s t -> stLe t u -> stLe s u.
Proof. intros s t u. apply leB_trans. Qed.

Lemma meet_le_left : forall s t, stLe (meet s t) s.
Proof. intros [] []; reflexivity. Qed.

Lemma meet_le_right : forall s t, stLe (meet s t) t.
Proof. intros [] []; reflexivity. Qed.

Lemma meet_assoc : forall s t u, meet (meet s t) u = meet s (meet t u).
Proof. intros [] [] []; reflexivity. Qed.

Lemma meet_definitional : forall s, meet s definitional = s.
Proof. intros []; reflexivity. Qed.

(** * Values that may be missing *)

Inductive Val (A : Type) : Type :=
  | missing : Val A
  | given : Status -> A -> Val A.
Arguments missing {A}.
Arguments given {A}.

Definition vpure {A : Type} (a : A) : Val A := given definitional a.

Definition vmap {A B : Type} (f : A -> B) (x : Val A) : Val B :=
  match x with missing => missing | given s a => given s (f a) end.

Definition zipWith {A B C : Type} (f : A -> B -> C) (x : Val A) (y : Val B) : Val C :=
  match x, y with
  | given s a, given t b => given (meet s t) (f a b)
  | _, _ => missing
  end.

(** Kleene conjunction: a known [false] decides the result. *)
Definition kand (x y : Val bool) : Val bool :=
  match x, y with
  | given s false, _ => given s false
  | given s true, given t b => given (meet s t) b
  | given _ true, missing => missing
  | missing, given t false => given t false
  | missing, _ => missing
  end.

Fixpoint at' {A : Type} (n : nat) (l : list (Val A)) {struct l} : Val A :=
  match l with
  | nil => missing
  | cons x xs => match n with 0 => x | S n' => at' n' xs end
  end.

(** * Cohorts and rates *)

Inductive Rate : Type :=
  | perMille : nat -> Rate
  | fraction : nat -> nat -> Rate.

Inductive Cohort : Type :=
  | observed : nat -> list (Val nat) -> Cohort
  | modelled : nat -> Val nat -> Val Rate -> Val Rate -> Cohort.

Definition denominator (r : Val Rate) : nat :=
  match r with given _ (fraction _ d) => d | _ => 1 end.

Fixpoint scaleOf (periods : nat) (cs : list Cohort) : nat :=
  match cs with
  | nil => 1
  | cons (observed _ _) cs' => scaleOf periods cs'
  | cons (modelled _ _ c r) cs' => denominator c * Nat.pow (denominator r) periods * scaleOf periods cs'
  end.

Definition applyRate (scale x : nat) (r : Rate) : nat :=
  match r with
  | perMille m => Nat.div (Nat.div x scale * m) 1000 * scale
  | fraction n d => Nat.div (x * n) d
  end.

Definition joined (scale : nat) (contacts : Val nat) (conversion : Val Rate) : Val nat :=
  zipWith (applyRate scale) (vmap (fun n => n * scale) contacts) conversion.

Fixpoint renewed (scale : nat) (start : Val nat) (retention : Val Rate) (k : nat) : Val nat :=
  match k with
  | 0 => start
  | S k' => zipWith (applyRate scale) (renewed scale start retention k') retention
  end.

Definition cohortAt (scale t : nat) (c : Cohort) : Val nat :=
  match c with
  | observed start counts =>
      if natLt t start then vpure 0 else vmap (fun n => n * scale) (at' (monus t start) counts)
  | modelled start contacts conversion retention =>
      if natLt t start then vpure 0
      else renewed scale (joined scale contacts conversion) retention (monus t start)
  end.

Fixpoint sumAt (scale t : nat) (cs : list Cohort) : Val nat :=
  match cs with
  | nil => vpure 0
  | cons c cs' => zipWith Nat.add (cohortAt scale t c) (sumAt scale t cs')
  end.

(** * The model *)

Record Number : Type := mkNumber {
  R : Type;
  zero : R;
  add : R -> R -> R;
  sub : R -> R -> R;
  mul : R -> R -> R;
  le : R -> R -> bool;
  fromNat : nat -> R
}.

Definition Covers {A : Type} (u : Status) (v : Val A) : Prop :=
  exists s a, v = given s a /\ stLe u s.

Fixpoint Forall' {A : Type} (P : A -> Prop) (l : list A) : Prop :=
  match l with nil => True | cons x xs => P x /\ Forall' P xs end.

Fixpoint Exists' {A : Type} (P : A -> Prop) (l : list A) : Prop :=
  match l with nil => False | cons x xs => P x \/ Exists' P xs end.

Lemma forall_map : forall {A : Type} (P Q : A -> Prop), (forall x, P x -> Q x) ->
  forall xs, Forall' P xs -> Forall' Q xs.
Proof.
  intros A P Q f. induction xs as [|x xs IH]; simpl; [auto|].
  intros [p ps]. split; [apply f, p | apply IH, ps].
Qed.

Lemma covers_weaken : forall {A : Type} (u w : Status) (v : Val A),
  stLe u w -> Covers w v -> Covers u v.
Proof.
  intros A u w v le [s [a [e le']]]. exists s, a. split; [exact e | exact (stLe_trans u w s le le')].
Qed.

Lemma zipWith_given : forall {A B C : Type} (f : A -> B -> C) x y u c,
  zipWith f x y = given u c -> Covers u x /\ Covers u y.
Proof.
  intros A B C f [|s a] [|t b] u c e; simpl in e; try discriminate.
  injection e as <- <-. split.
  - exists s, a. split; [reflexivity | apply meet_le_left].
  - exists t, b. split; [reflexivity | apply meet_le_right].
Qed.

Lemma zipWith_needs : forall {A B C : Type} (f : A -> B -> C) x y u,
  Covers u (zipWith f x y) -> Covers u x /\ Covers u y.
Proof.
  intros A B C f x y u [s [c [e le]]].
  destruct (zipWith_given f x y s c e) as [cx cy].
  split; [exact (covers_weaken u s x le cx) | exact (covers_weaken u s y le cy)].
Qed.

Lemma map_needs : forall {A B : Type} (f : A -> B) x u, Covers u (vmap f x) -> Covers u x.
Proof.
  intros A B f [|s a] u [s' [c [e le]]]; simpl in e; [discriminate|].
  injection e as <- _. exists s, a. split; [reflexivity | exact le].
Qed.

Lemma missing_uncovered : forall {A : Type} (u : Status), ~ Covers u (@missing A).
Proof. intros A u [s [a [e _]]]. discriminate. Qed.

Lemma joined_needs : forall u scale contacts conversion,
  Covers u (joined scale contacts conversion) -> Covers u contacts /\ Covers u conversion.
Proof.
  intros u scale contacts conversion c. unfold joined in c.
  destruct (zipWith_needs _ _ _ u c) as [cl cc]. split; [exact (map_needs _ _ u cl) | exact cc].
Qed.

Lemma renewed_joined : forall u scale start retention k,
  Covers u (renewed scale start retention k) -> Covers u start.
Proof.
  intros u scale start retention. induction k as [|k IH]; simpl; intro c; [exact c|].
  apply IH. exact (proj1 (zipWith_needs _ _ _ u c)).
Qed.

Lemma renewed_retention : forall u scale start retention k,
  Covers u (renewed scale start retention (S k)) -> Covers u retention.
Proof. intros u scale start retention k c. exact (proj2 (zipWith_needs _ _ _ u c)). Qed.

Lemma modelled_needs : forall u scale t start contacts conversion retention,
  natLt t start = false ->
  Covers u (cohortAt scale t (modelled start contacts conversion retention)) ->
  Covers u contacts /\ Covers u conversion.
Proof.
  intros u scale t start contacts conversion retention h c. simpl in c. rewrite h in c.
  exact (joined_needs _ _ _ _ (renewed_joined _ _ _ _ _ c)).
Qed.

Lemma modelled_renewal_needs : forall u scale t start contacts conversion retention k,
  natLt t start = false -> monus t start = S k ->
  Covers u (cohortAt scale t (modelled start contacts conversion retention)) -> Covers u retention.
Proof.
  intros u scale t start contacts conversion retention k h gap c. simpl in c. rewrite h, gap in c.
  exact (renewed_retention _ _ _ _ _ c).
Qed.

Lemma observed_needs : forall u scale t start counts,
  natLt t start = false -> Covers u (cohortAt scale t (observed start counts)) ->
  Covers u (at' (monus t start) counts).
Proof.
  intros u scale t start counts h c. simpl in c. rewrite h in c. exact (map_needs _ _ u c).
Qed.

Lemma sum_needs : forall u scale t cs,
  Covers u (sumAt scale t cs) -> Forall' (fun c => Covers u (cohortAt scale t c)) cs.
Proof.
  intros u scale t. induction cs as [|c cs IH]; simpl; intro h; [exact I|].
  destruct (zipWith_needs _ _ _ u h) as [hc hr]. split; [exact hc | exact (IH hr)].
Qed.

(** A "yes" needs both sides to be a known "yes". *)
Definition Yes (u : Status) (v : Val bool) : Prop := exists s, v = given s true /\ stLe u s.

Lemma kand_yes : forall x y u, kand x y = given u true -> Yes u x /\ Yes u y.
Proof.
  intros [|s [|]] [|t [|]] u e; simpl in e; try discriminate.
  - injection e as <-. split; [exists s | exists t]; split; try reflexivity;
      [apply meet_le_left | apply meet_le_right].
Qed.

Lemma kand_false_left : forall x y s, x = given s false -> kand x y = given s false.
Proof. intros x y s ->. reflexivity. Qed.

Lemma kand_false_right : forall x y t, y = given t false -> exists u, kand x y = given u false.
Proof.
  intros [|s [|]] y t ->; simpl.
  - exists t. reflexivity.
  - exists (meet s t). reflexivity.
  - exists s. reflexivity.
Qed.

Section Model.

Variable N : Number.

Definition nmax (a b : R N) : R N := if le N a b then b else a.

Record Inputs : Type := mkInputs {
  periods : nat;
  opening : Val (R N);
  price : Val (R N);
  unitCost : Val (R N);
  minutes : Val (R N);
  fixed : list (Val (R N));
  floor : list (Val (R N));
  capacity : list (Val (R N));
  cohorts : list Cohort
}.

Record Row : Type := mkRow {
  members : Val (R N);
  receipts : Val (R N);
  payments : Val (R N);
  closing : Val (R N);
  shortfall : Val (R N);
  hours : Val (R N);
  cashOk : Val bool;
  capacityOk : Val bool
}.

Definition scale (i : Inputs) : nat := scaleOf (periods i) (cohorts i).

Definition scaled (i : Inputs) : Val (R N) -> Val (R N) :=
  vmap (fun x => mul N x (fromNat N (scale i))).

Definition rowAt (i : Inputs) (t : nat) (previous : Val (R N)) : Row :=
  let m := vmap (fromNat N) (sumAt (scale i) t (cohorts i)) in
  let rec_ := zipWith (mul N) (price i) m in
  let pay := zipWith (add N) (scaled i (at' (monus t 1) (fixed i))) (zipWith (mul N) (unitCost i) m) in
  let clo := zipWith (sub N) (zipWith (add N) previous rec_) pay in
  let hrs := zipWith (mul N) (minutes i) m in
  let flo := scaled i (at' (monus t 1) (floor i)) in
  mkRow m rec_ pay clo (zipWith (sub N) flo clo) hrs (zipWith (le N) flo clo)
    (zipWith (le N) hrs (scaled i (at' (monus t 1) (capacity i)))).

Fixpoint rowsFrom (i : Inputs) (t n : nat) (previous : Val (R N)) : list Row :=
  match n with
  | 0 => nil
  | S n' => cons (rowAt i t previous) (rowsFrom i (S t) n' (closing (rowAt i t previous)))
  end.

Definition allRows (i : Inputs) : list Row := rowsFrom i 1 (periods i) (scaled i (opening i)).

Fixpoint verdict (f : Row -> Val bool) (rs : list Row) : Val bool :=
  match rs with nil => vpure true | cons r rs' => kand (f r) (verdict f rs') end.

Fixpoint worst (rs : list Row) : Val (R N) :=
  match rs with nil => vpure (zero N) | cons r rs' => zipWith nmax (shortfall r) (worst rs') end.

(** * APP-1 and APP-4: what a given output needs *)

Section Needs.

Variable i : Inputs.

Lemma members_needs : forall u t previous,
  Covers u (members (rowAt i t previous)) -> Covers u (sumAt (scale i) t (cohorts i)).
Proof. intros u t previous c. exact (map_needs _ _ u c). Qed.

Lemma receipts_needs : forall u t previous,
  Covers u (receipts (rowAt i t previous)) -> Covers u (price i) /\ Covers u (sumAt (scale i) t (cohorts i)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cp cm].
  split; [exact cp | exact (map_needs _ _ u cm)].
Qed.

Lemma payments_needs : forall u t previous,
  Covers u (payments (rowAt i t previous)) ->
  Covers u (at' (monus t 1) (fixed i)) /\ Covers u (unitCost i) /\ Covers u (sumAt (scale i) t (cohorts i)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cf cv].
  destruct (zipWith_needs _ _ _ u cv) as [cu cm].
  split; [exact (map_needs _ _ u cf) | split; [exact cu | exact (map_needs _ _ u cm)]].
Qed.

Lemma closing_needs : forall u t previous,
  Covers u (closing (rowAt i t previous)) ->
  Covers u previous /\ Covers u (price i) /\ Covers u (at' (monus t 1) (fixed i)) /\
  Covers u (unitCost i) /\ Covers u (sumAt (scale i) t (cohorts i)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cpr cpay].
  destruct (zipWith_needs _ _ _ u cpr) as [cprev crec].
  destruct (payments_needs u t previous cpay) as [cf [cu cm]].
  repeat split; try assumption. exact (proj1 (zipWith_needs _ _ _ u crec)).
Qed.

Lemma shortfall_needs : forall u t previous,
  Covers u (shortfall (rowAt i t previous)) ->
  Covers u (at' (monus t 1) (floor i)) /\ Covers u (closing (rowAt i t previous)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cfl cc].
  split; [exact (map_needs _ _ u cfl) | exact cc].
Qed.

Lemma cashOk_needs : forall u t previous,
  Covers u (cashOk (rowAt i t previous)) ->
  Covers u (at' (monus t 1) (floor i)) /\ Covers u (closing (rowAt i t previous)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cfl cc].
  split; [exact (map_needs _ _ u cfl) | exact cc].
Qed.

Lemma hours_needs : forall u t previous,
  Covers u (hours (rowAt i t previous)) -> Covers u (minutes i) /\ Covers u (sumAt (scale i) t (cohorts i)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [cmin cm].
  split; [exact cmin | exact (map_needs _ _ u cm)].
Qed.

Lemma capacityOk_needs : forall u t previous,
  Covers u (capacityOk (rowAt i t previous)) ->
  Covers u (minutes i) /\ Covers u (sumAt (scale i) t (cohorts i)) /\ Covers u (at' (monus t 1) (capacity i)).
Proof.
  intros u t previous c. destruct (zipWith_needs _ _ _ u c) as [ch ccap].
  destruct (hours_needs u t previous ch) as [cmin cm].
  split; [exact cmin | split; [exact cm | exact (map_needs _ _ u ccap)]].
Qed.

Lemma opening_needs : forall u, Covers u (scaled i (opening i)) -> Covers u (opening i).
Proof. intros u c. exact (map_needs _ _ u c). Qed.

Lemma closings_missing : forall n t, Forall' (fun r => closing r = missing) (rowsFrom i t n missing).
Proof.
  induction n as [|n IH]; intro t; simpl; [exact I|]. split; [reflexivity | apply IH].
Qed.

Lemma missing_persists : forall t n previous, closing (rowAt i t previous) = missing ->
  Forall' (fun r => closing r = missing) (rowsFrom i (S t) n (closing (rowAt i t previous))).
Proof. intros t n previous h. rewrite h. apply closings_missing. Qed.

Lemma verdict_yes : forall (f : Row -> Val bool) rs u,
  verdict f rs = given u true -> Forall' (fun r => Yes u (f r)) rs.
Proof.
  intro f. induction rs as [|r rs IH]; simpl; intros u e; [exact I|].
  destruct (kand_yes _ _ _ e) as [yr [s [e' le]]]. split; [exact yr|].
  apply (forall_map (fun r => Yes s (f r))).
  - intros x [s' [ex le']]. exists s'. split; [exact ex | exact (stLe_trans u s s' le le')].
  - exact (IH s e').
Qed.

Lemma breach_decides : forall (f : Row -> Val bool) rs,
  Exists' (fun r => exists s, f r = given s false) rs -> exists u, verdict f rs = given u false.
Proof.
  intro f. induction rs as [|r rs IH]; simpl; intro h; [destruct h|].
  destruct h as [[s e] | p].
  - exists s. exact (kand_false_left _ _ _ e).
  - destruct (IH p) as [t e]. exact (kand_false_right _ _ _ e).
Qed.

Lemma gap_needs : forall u rs, Covers u (worst rs) -> Forall' (fun r => Covers u (shortfall r)) rs.
Proof.
  intro u. induction rs as [|r rs IH]; simpl; intro c; [exact I|].
  destruct (zipWith_needs _ _ _ u c) as [cs rest]. split; [exact cs | exact (IH rest)].
Qed.

End Needs.

(** * APP-2 and APP-3: ordered abelian groups *)

Record Laws : Type := mkLaws {
  neg : R N -> R N;
  add_assoc : forall a b c, add N (add N a b) c = add N a (add N b c);
  add_comm : forall a b, add N a b = add N b a;
  add_zero : forall a, add N a (zero N) = a;
  add_neg : forall a, add N a (neg a) = zero N;
  sub_def : forall a b, sub N a b = add N a (neg b);
  le_refl : forall a, le N a a = true;
  le_trans : forall a b c, le N a b = true -> le N b c = true -> le N a c = true;
  le_total : forall a b, le N a b = false -> le N b a = true;
  le_add : forall a b c, le N a b = true -> le N (add N a c) (add N b c) = true
}.

Section Cash.

Variable L : Laws.

Lemma step_law : forall a r q x,
  add N (sub N (add N a r) q) x = add N a (add N (sub N r q) x).
Proof.
  intros a r q x. rewrite !(sub_def L), (add_assoc L a r (neg L q)), (add_assoc L a (add N r (neg L q)) x).
  reflexivity.
Qed.

Lemma shift_law : forall a g r q,
  sub N (add N (add N a g) r) q = add N (sub N (add N a r) q) g.
Proof.
  intros a g r q. rewrite !(sub_def L), (add_assoc L a g r), (add_comm L g r), <- (add_assoc L a r g),
    (add_assoc L (add N a r) g (neg L q)), (add_comm L g (neg L q)), <- (add_assoc L (add N a r) (neg L q) g).
  reflexivity.
Qed.

Lemma cancel_right : forall f c, add N (sub N f c) c = f.
Proof.
  intros f c. rewrite (sub_def L), (add_assoc L), (add_comm L (neg L c) c), (add_neg L), (add_zero L).
  reflexivity.
Qed.

Lemma cancel_left : forall c g, add N (add N c g) (neg L c) = g.
Proof.
  intros c g. rewrite (add_comm L c g), (add_assoc L), (add_neg L), (add_zero L). reflexivity.
Qed.

Lemma below_shift : forall f c g, le N (sub N f c) g = true -> le N f (add N c g) = true.
Proof.
  intros f c g h. pose proof (le_add L _ _ c h) as k.
  rewrite cancel_right, (add_comm L g c) in k. exact k.
Qed.

Lemma shift_below : forall f c g, le N f (add N c g) = true -> le N (sub N f c) g = true.
Proof.
  intros f c g h. pose proof (le_add L _ _ (neg L c) h) as k.
  rewrite cancel_left, <- (sub_def L) in k. exact k.
Qed.

Lemma meet4 : forall s t v w, meet (meet (meet s t) v) w = meet s (meet (meet t v) w).
Proof. intros [] [] [] []; reflexivity. Qed.

Lemma step_val : forall p r q n : Val (R N),
  zipWith (add N) (zipWith (sub N) (zipWith (add N) p r) q) n =
  zipWith (add N) p (zipWith (add N) (zipWith (sub N) r q) n).
Proof.
  intros [|s a] [|t b] [|v c] [|w d]; simpl; try reflexivity.
  rewrite meet4, step_law. reflexivity.
Qed.

Lemma base_val : forall p : Val (R N), p = zipWith (add N) p (vpure (zero N)).
Proof.
  intros [|s a]; simpl; [reflexivity|]. rewrite meet_definitional, (add_zero L). reflexivity.
Qed.

Lemma shift_val : forall (p r q : Val (R N)) g,
  zipWith (sub N) (zipWith (add N) (vmap (fun x => add N x g) p) r) q =
  vmap (fun x => add N x g) (zipWith (sub N) (zipWith (add N) p r) q).
Proof.
  intros [|s a] [|t b] [|v c] g; simpl; try reflexivity. rewrite shift_law. reflexivity.
Qed.

Lemma floor_met : forall (F C : Val (R N)) g s d,
  zipWith (sub N) F C = given s d -> le N d g = true ->
  exists s', zipWith (le N) F (vmap (fun x => add N x g) C) = given s' true.
Proof.
  intros [|sf f] [|sc c] g s d e h; simpl in e; try discriminate.
  injection e as <- <-. exists (meet sf sc). simpl. rewrite (below_shift f c g h). reflexivity.
Qed.

Lemma floor_needs : forall (F C : Val (R N)) g s s' d,
  zipWith (sub N) F C = given s d ->
  zipWith (le N) F (vmap (fun x => add N x g) C) = given s' true -> le N d g = true.
Proof.
  intros [|sf f] [|sc c] g s s' d e ok; simpl in e, ok; try discriminate.
  injection e as <- <-. injection ok as _ h. exact (shift_below f c g h).
Qed.

Lemma max_left : forall a b, le N a (nmax a b) = true.
Proof.
  intros a b. unfold nmax. destruct (le N a b) eqn:h; [exact h | exact (le_refl L a)].
Qed.

Lemma max_right : forall a b, le N b (nmax a b) = true.
Proof.
  intros a b. unfold nmax. destruct (le N a b) eqn:h; [exact (le_refl L b) | exact (le_total L a b h)].
Qed.

Lemma max_least : forall a b c, le N a c = true -> le N b c = true -> le N (nmax a b) c = true.
Proof. intros a b c ha hb. unfold nmax. destruct (le N a b); assumption. Qed.

Variable i : Inputs.

Fixpoint lastClosing (p : Val (R N)) (rs : list Row) : Val (R N) :=
  match rs with nil => p | cons r rs' => lastClosing (closing r) rs' end.

Fixpoint netSum (rs : list Row) : Val (R N) :=
  match rs with
  | nil => vpure (zero N)
  | cons r rs' => zipWith (add N) (zipWith (sub N) (receipts r) (payments r)) (netSum rs')
  end.

(** APP-2: the closing cash of the last period is the opening cash plus,
    summed over the periods, receipts minus payments. Both sides are missing
    together, with the same status when given. *)
Lemma cash_identity : forall n t p,
  lastClosing p (rowsFrom i t n p) = zipWith (add N) p (netSum (rowsFrom i t n p)).
Proof.
  induction n as [|n IH]; intros t p; simpl; [apply base_val|].
  rewrite IH. apply step_val.
Qed.

(** Adding g to the previous balance adds g to the closing balance. *)
Lemma shifted_closing : forall t p g,
  closing (rowAt i t (vmap (fun x => add N x g) p)) = vmap (fun x => add N x g) (closing (rowAt i t p)).
Proof. intros t p g. apply shift_val. Qed.

Definition Bounded (g : R N) (v : Val (R N)) : Prop := exists s d, v = given s d /\ le N d g = true.

Definition Met (r : Row) : Prop := exists s, cashOk r = given s true.

Lemma worst_bounds : forall rs u g, worst rs = given u g -> Forall' (fun r => Bounded g (shortfall r)) rs.
Proof.
  induction rs as [|r rs IH]; simpl; intros u g e; [exact I|].
  destruct (zipWith_given _ _ _ _ _ e) as [[s [d [eqd _]]] [w [m [eqm _]]]].
  rewrite eqd, eqm in e. simpl in e. injection e as _ hg.
  split.
  - exists s, d. split; [exact eqd|]. rewrite <- hg. apply max_left.
  - apply (forall_map (fun r => Bounded m (shortfall r))).
    + intros x [s' [d' [e2 t2]]]. exists s', d'. split; [exact e2|].
      apply (le_trans L d' m g t2). rewrite <- hg. apply max_right.
    + exact (IH w m eqm).
Qed.

(** APP-3, sound: when every shortfall is at most g, adding g to the previous
    balance meets the floor in every period. *)
Lemma meets_floor : forall n t p g,
  Forall' (fun r => Bounded g (shortfall r)) (rowsFrom i t n p) ->
  Forall' Met (rowsFrom i t n (vmap (fun x => add N x g) p)).
Proof.
  induction n as [|n IH]; intros t p g h; cbn [rowsFrom Forall'] in h |- *; [exact I|].
  destruct h as [[s [d [eq hle]]] rest]. split.
  - unfold Met. change (cashOk (rowAt i t (vmap (fun x => add N x g) p))) with
      (zipWith (le N) (scaled i (at' (monus t 1) (floor i))) (closing (rowAt i t (vmap (fun x => add N x g) p)))).
    rewrite shifted_closing. exact (floor_met _ _ g s d eq hle).
  - rewrite shifted_closing. exact (IH (S t) (closing (rowAt i t p)) g rest).
Qed.

Lemma gap_sound : forall n t p u g, worst (rowsFrom i t n p) = given u g ->
  Forall' Met (rowsFrom i t n (vmap (fun x => add N x g) p)).
Proof. intros n t p u g e. exact (meets_floor n t p g (worst_bounds _ u g e)). Qed.

(** APP-3, least: no smaller non-negative addition meets every floor. *)
Lemma gap_least : forall n t p u g g', worst (rowsFrom i t n p) = given u g -> le N (zero N) g' = true ->
  Forall' Met (rowsFrom i t n (vmap (fun x => add N x g') p)) -> le N g g' = true.
Proof.
  induction n as [|n IH]; intros t p u g g' e z h; cbn [rowsFrom worst Forall'] in e, h |- * .
  - injection e as _ hg. rewrite <- hg. exact z.
  - destruct (zipWith_given _ _ _ _ _ e) as [[s [d [eqd _]]] [w [m [eqm _]]]].
    rewrite eqd, eqm in e. simpl in e. injection e as _ hg.
    destruct h as [[s' ok] rest].
    change (cashOk (rowAt i t (vmap (fun x => add N x g') p))) with
      (zipWith (le N) (scaled i (at' (monus t 1) (floor i))) (closing (rowAt i t (vmap (fun x => add N x g') p)))) in ok.
    rewrite shifted_closing in ok, rest.
    pose proof (floor_needs _ _ g' _ _ _ eqd ok) as head.
    pose proof (IH (S t) (closing (rowAt i t p)) w m g' eqm z rest) as tail.
    rewrite <- hg. exact (max_least d m g' head tail).
Qed.

End Cash.

End Model.

(** * The integer instance satisfies the laws *)

Inductive Z' : Type :=
  | pos : nat -> Z'
  | negsuc : nat -> Z'.

Definition ominus (m n : nat) : Z' :=
  if natLt m n then negsuc (monus (monus n m) 1) else pos (monus m n).

Definition zneg (z : Z') : Z' :=
  match z with pos 0 => pos 0 | pos (S n) => negsuc n | negsuc n => pos (S n) end.

Definition zadd (i j : Z') : Z' :=
  match i, j with
  | pos m, pos n => pos (m + n)
  | pos m, negsuc n => ominus m (S n)
  | negsuc m, pos n => ominus n (S m)
  | negsuc m, negsuc n => negsuc (S (m + n))
  end.

Definition zsub (a b : Z') : Z' := zadd a (zneg b).

Definition zmul (i j : Z') : Z' :=
  match i, j with
  | pos m, pos n => pos (m * n)
  | pos m, negsuc n => zneg (pos (m * S n))
  | negsuc m, pos n => zneg (pos (S m * n))
  | negsuc m, negsuc n => pos (S m * S n)
  end.

Definition zle (i j : Z') : bool :=
  match i, j with
  | pos m, pos n => natLt m (S n)
  | pos _, negsuc _ => false
  | negsuc _, pos _ => true
  | negsuc m, negsuc n => natLt n (S m)
  end.

Definition intNumber : Number := mkNumber Z' (pos 0) zadd zsub zmul zle pos.

(** m <= n, as the integer order uses it. *)
Definition leq (m n : nat) : bool := natLt m (S n).

Lemma leq_refl : forall n, leq n n = true.
Proof. induction n as [|n IH]; [reflexivity | exact IH]. Qed.

Lemma leq_trans : forall a b c, leq a b = true -> leq b c = true -> leq a c = true.
Proof.
  intro a; induction a as [|a IH]; intros b c p q; [reflexivity|].
  destruct b as [|b]; [simpl in p; destruct a; discriminate p|].
  destruct c as [|c]; [simpl in q; destruct b; discriminate q|].
  exact (IH b c p q).
Qed.

Lemma leq_total : forall a b, leq a b = false -> leq b a = true.
Proof.
  intro a; induction a as [|a IH]; intros b h; [discriminate h|].
  destruct b as [|b]; [reflexivity|].
  exact (IH b h).
Qed.

Lemma leq_cancel : forall k x y, leq (k + x) (k + y) = leq x y.
Proof. induction k as [|k IH]; intros x y; [reflexivity | exact (IH x y)]. Qed.

Lemma ominus_cancel : forall k a b, ominus (k + a) (k + b) = ominus a b.
Proof. induction k as [|k IH]; intros a b; [reflexivity | exact (IH a b)]. Qed.

Lemma ominus_diff : forall a b c d, a + d = c + b -> ominus a b = ominus c d.
Proof.
  intros a b c d h.
  rewrite <- (ominus_cancel d a b), <- (ominus_cancel b c d).
  replace (d + a) with (b + c) by lia. replace (d + b) with (b + d) by lia. reflexivity.
Qed.

Lemma ominus_self : forall n, ominus n n = pos 0.
Proof. induction n as [|n IH]; [reflexivity | exact IH]. Qed.

Definition P (z : Z') : nat := match z with pos m => m | negsuc _ => 0 end.
Definition Q (z : Z') : nat := match z with pos _ => 0 | negsuc n => S n end.

Lemma asDiff : forall z, z = ominus (P z) (Q z).
Proof. intros [m|n]; reflexivity. Qed.

Lemma ominus_parts : forall a b, P (ominus a b) + b = a + Q (ominus a b).
Proof.
  induction a as [|m IH]; intros [|n]; try reflexivity.
  change (P (ominus m n) + S n = S m + Q (ominus m n)).
  pose proof (IH n). lia.
Qed.

Lemma add_parts : forall i j, zadd i j = ominus (P i + P j) (Q i + Q j).
Proof.
  intros [m|m] [n|n]; simpl.
  - reflexivity.
  - rewrite Nat.add_0_r. reflexivity.
  - rewrite Nat.add_0_r. reflexivity.
  - change (negsuc (S (m + n)) = negsuc (m + S n)). f_equal. lia.
Qed.

Lemma ominus_add : forall a b c d, zadd (ominus a b) (ominus c d) = ominus (a + c) (b + d).
Proof.
  intros a b c d. rewrite add_parts. apply ominus_diff.
  pose proof (ominus_parts a b). pose proof (ominus_parts c d). lia.
Qed.

Lemma ord : forall i j, zle i j = leq (P i + Q j) (P j + Q i).
Proof.
  intros [m|m] [n|n]; simpl.
  - rewrite !Nat.add_0_r. reflexivity.
  - rewrite Nat.add_comm. reflexivity.
  - reflexivity.
  - reflexivity.
Qed.

Lemma ord_ominus : forall a b c d, zle (ominus a b) (ominus c d) = leq (a + d) (c + b).
Proof.
  intros a b c d. rewrite ord, <- (leq_cancel (b + d)).
  pose proof (ominus_parts a b). pose proof (ominus_parts c d).
  replace (b + d + (P (ominus a b) + Q (ominus c d)))
    with (Q (ominus a b) + Q (ominus c d) + (a + d)) by lia.
  replace (b + d + (P (ominus c d) + Q (ominus a b)))
    with (Q (ominus a b) + Q (ominus c d) + (c + b)) by lia.
  apply leq_cancel.
Qed.

Lemma zadd_comm : forall i j, zadd i j = zadd j i.
Proof.
  intros i j. rewrite (add_parts i j), (add_parts j i).
  replace (P i + P j) with (P j + P i) by lia. replace (Q i + Q j) with (Q j + Q i) by lia. reflexivity.
Qed.

Lemma zadd_assoc : forall i j k, zadd (zadd i j) k = zadd i (zadd j k).
Proof.
  intros i j k.
  rewrite (add_parts i j), (asDiff k), ominus_add, (add_parts j (ominus (P k) (Q k))), <- (asDiff k).
  rewrite (asDiff i), ominus_add, <- (asDiff i).
  replace (P i + P j + P k) with (P i + (P j + P k)) by lia.
  replace (Q i + Q j + Q k) with (Q i + (Q j + Q k)) by lia. reflexivity.
Qed.

Lemma zadd_zero : forall i, zadd i (pos 0) = i.
Proof. intros [m|m]; simpl; [rewrite Nat.add_0_r|]; reflexivity. Qed.

Lemma zadd_neg : forall i, zadd i (zneg i) = pos 0.
Proof. intros [[|n]|m]; simpl; [reflexivity | apply ominus_self | apply ominus_self]. Qed.

Lemma zle_add_same : forall i j k, zle (zadd i k) (zadd j k) = zle i j.
Proof.
  intros i j k. rewrite (add_parts i k), (add_parts j k), ord_ominus, (ord i j).
  replace (P i + P k + (Q j + Q k)) with (P k + Q k + (P i + Q j)) by lia.
  replace (P j + P k + (Q i + Q k)) with (P k + Q k + (P j + Q i)) by lia.
  apply leq_cancel.
Qed.

Lemma zle_refl : forall i, zle i i = true.
Proof. intros [m|m]; apply leq_refl. Qed.

Lemma zle_trans : forall i j k, zle i j = true -> zle j k = true -> zle i k = true.
Proof.
  intros [m|m] [n|n] [k|k] p q; simpl in *; try discriminate; try reflexivity.
  - exact (leq_trans m n k p q).
  - exact (leq_trans k n m q p).
Qed.

Lemma zle_total : forall i j, zle i j = false -> zle j i = true.
Proof.
  intros [m|m] [n|n] h; simpl in *; try reflexivity; try discriminate.
  - exact (leq_total m n h).
  - exact (leq_total n m h).
Qed.

Definition intLaws : Laws intNumber :=
  mkLaws intNumber zneg zadd_assoc zadd_comm zadd_zero zadd_neg (fun _ _ => eq_refl)
    zle_refl zle_trans zle_total (fun i j k h => eq_trans (zle_add_same i j k) h).

(** APP-2 and APP-3 for the model as it runs on the worked examples. *)

Lemma cash_identity_int : forall (i : Inputs intNumber) n t p,
  lastClosing intNumber p (rowsFrom intNumber i t n p) =
  zipWith zadd p (netSum intNumber (rowsFrom intNumber i t n p)).
Proof. intros i n t p. exact (cash_identity intNumber intLaws i n t p). Qed.

Lemma gap_sound_int : forall (i : Inputs intNumber) n t p u g,
  worst intNumber (rowsFrom intNumber i t n p) = given u g ->
  Forall' (Met intNumber) (rowsFrom intNumber i t n (vmap (fun x => zadd x g) p)).
Proof. intros i n t p u g e. exact (gap_sound intNumber intLaws i n t p u g e). Qed.

Lemma gap_least_int : forall (i : Inputs intNumber) n t p u g g',
  worst intNumber (rowsFrom intNumber i t n p) = given u g -> zle (pos 0) g' = true ->
  Forall' (Met intNumber) (rowsFrom intNumber i t n (vmap (fun x => zadd x g') p)) -> zle g g' = true.
Proof. intros i n t p u g g' e z m. exact (gap_least intNumber intLaws i n t p u g g' e z m). Qed.
