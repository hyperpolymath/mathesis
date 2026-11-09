{-# OPTIONS --safe --without-K --cubical-compatible #-}
-- SPDX-License-Identifier: MPL-2.0
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
--
-- Additive features: reachability in a dependency graph is monotone in
-- the set of requested features.
--
-- Why it matters. The estate's upstream dependency watch
-- (metadatastician/standards, docs/UPSTREAM-DEPENDENCY-WATCH.adoc) says to
-- run every `cargo tree` check with `--target all --workspace
-- --all-features`, and to read a crate missing there as missing from
-- every build. That reading is the corollary `absent-under-all-features`
-- below: if features only ever add dependencies, a crate unreachable with
-- every feature on is unreachable with any subset of them, on that target.
--
-- What is modelled. Features are requested as a predicate. Feature
-- implications (Cargo's `[features]` table, including `dep:x`, `x/f` and
-- weak `x?/f` entries, and default features) are Horn rules, and the
-- enabled features are the least set closed under them. A dependency edge
-- is active when every feature in its guard is enabled and its target
-- condition holds on the target in question. Target conditions may be
-- arbitrary, `not(...)` included, because each target is treated
-- separately and `--target all` is the union over targets.
--
-- What is not modelled, and so is assumed when the result is applied to
-- Cargo: that Cargo's resolver activates exactly these edges (features
-- unify by union; no feature removes a dependency), and that the version
-- graph is the fixed one in Cargo.lock. Under resolver 2, build and dev
-- dependency units unify features separately; the theorem applies to each
-- unit's graph on its own.
--
-- The module imports nothing, so its import cone is this file alone.

module FeatureReachability where

------------------------------------------------------------------------
-- Logic, defined here so that no library enters the import cone

data ⊥ : Set where

record ⊤ : Set where
  constructor tt

¬_ : Set → Set
¬ A = A → ⊥

infix 4 _≡_
data _≡_ {A : Set} (x : A) : A → Set where
  refl : x ≡ x

infixr 5 _∷_
data List (A : Set) : Set where
  []  : List A
  _∷_ : A → List A → List A

-- Every element of the list satisfies P.
data All {A : Set} (P : A → Set) : List A → Set where
  []  : All P []
  _∷_ : ∀ {x xs} → P x → All P xs → All P (x ∷ xs)

------------------------------------------------------------------------
-- 1. The abstract result: reachability over a monotone family of edges

module Monotone
  (Node : Set)
  (Ctx  : Set₁)
  (_≤_  : Ctx → Ctx → Set)
  (Edge : Ctx → Node → Node → Set)
  (edge-mono : ∀ {F G u v} → F ≤ G → Edge F u v → Edge G u v)
  where

  -- v is reachable from root using edges active under F.
  data Reach (F : Ctx) (root : Node) : Node → Set where
    here : Reach F root root
    step : ∀ {u v} → Reach F root u → Edge F u v → Reach F root v

  reach-mono : ∀ {F G root v} → F ≤ G → Reach F root v → Reach G root v
  reach-mono F≤G here       = here
  reach-mono F≤G (step r e) = step (reach-mono F≤G r) (edge-mono F≤G e)

  -- Contrapositive: absent above means absent below.
  absent-below : ∀ {F G root v} → F ≤ G → ¬ Reach G root v → ¬ Reach F root v
  absent-below F≤G absent r = absent (reach-mono F≤G r)

------------------------------------------------------------------------
-- 2. The Cargo-shaped instance

module Cargo
  (Node Feat Target : Set)
  -- Feature implications as Horn rules: all premises on ⇒ conclusion on.
  (Rule : Set) (premises : Rule → List Feat) (conclusion : Rule → Feat)
  -- Dependency edges with a feature guard and a per-target condition.
  (Dep : Set) (from to : Dep → Node) (guard : Dep → List Feat)
  (targetOk : Target → Dep → Set)
  where

  -- A request: which features the user asked for.
  Request : Set₁
  Request = Feat → Set

  infix 4 _⊑_
  _⊑_ : Request → Request → Set
  S ⊑ T = ∀ {f} → S f → T f

  -- The features enabled by a request: least set containing the request
  -- and closed under the rules.
  data On (S : Request) : Feat → Set where
    asked   : ∀ {f} → S f → On S f
    implied : (r : Rule) → All (On S) (premises r) → On S (conclusion r)

  mutual
    on-mono : ∀ {S T f} → S ⊑ T → On S f → On T f
    on-mono S⊑T (asked s)      = asked (S⊑T s)
    on-mono S⊑T (implied r ps) = implied r (on-mono* S⊑T ps)

    on-mono* : ∀ {S T fs} → S ⊑ T → All (On S) fs → All (On T) fs
    on-mono* S⊑T []       = []
    on-mono* S⊑T (p ∷ ps) = on-mono S⊑T p ∷ on-mono* S⊑T ps

  -- An edge u → v active on target t under request S.
  record Edge (t : Target) (S : Request) (u v : Node) : Set where
    field
      dep     : Dep
      src     : from dep ≡ u
      dst     : to dep ≡ v
      onT     : targetOk t dep
      enabled : All (On S) (guard dep)

  edge-mono : ∀ {t S T u v} → S ⊑ T → Edge t S u v → Edge t T u v
  edge-mono S⊑T e = record
    { dep     = Edge.dep e
    ; src     = Edge.src e
    ; dst     = Edge.dst e
    ; onT     = Edge.onT e
    ; enabled = on-mono* S⊑T (Edge.enabled e)
    }

  module OnTarget (t : Target) =
    Monotone Node Request _⊑_ (Edge t) (edge-mono {t})

  -- `--all-features`: every feature requested.
  all-features : Request
  all-features _ = ⊤

  below-all : ∀ (S : Request) → S ⊑ all-features
  below-all S _ = tt

  -- The watch page's rule. A crate unreachable from a root with every
  -- feature on, on every target, is unreachable from that root under
  -- any request on any target.
  absent-under-all-features :
    ∀ {root v} →
    (∀ t → ¬ OnTarget.Reach t all-features root v) →
    ∀ t (S : Request) → ¬ OnTarget.Reach t S root v
  absent-under-all-features absent t S =
    OnTarget.absent-below t (below-all S) (absent t)
