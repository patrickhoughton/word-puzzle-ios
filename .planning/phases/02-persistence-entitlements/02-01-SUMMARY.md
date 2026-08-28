---
phase: 02-persistence-entitlements
plan: 01
subsystem: payments
tags: [storekit2, iap, app-store-connect, non-consumable]

# Dependency graph
requires:
  - phase: 01-word-engine-puzzle-generation
    provides: "WordPuzzle.xcodeproj with PBXFileSystemSynchronizedRootGroup app/test targets"
provides:
  - "Local WordPuzzle.storekit configuration declaring com.patrickhoughton.wordpuzzle.unlimited (NonConsumable, $2.99)"
  - "App Store Connect app record and matching non-consumable IAP product record"
affects: [02-01-task-3, 02-04-entitlement-store, 02-05-app-wiring, phase-4-paywall]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "StoreKit Configuration file written directly as JSON (not via Xcode wizard) for determinism"

key-files:
  created:
    - WordPuzzle/WordPuzzle/WordPuzzle.storekit
  modified: []

key-decisions:
  - "App Store Connect app display name is 'Word Puzzle Unlimited' (the originally planned 'WordPuzzle' name was taken) — display name only, does not affect bundle ID, product ID, or any code"

patterns-established: []

requirements-completed: []  # MON-02 not yet complete: Task 3 (Xcode target/scheme wiring) still pending human action

# Metrics
duration: in progress (Task 3 pending checkpoint)
completed: null
---

# Phase 2 Plan 1: StoreKit Setup Summary

**STATUS: IN PROGRESS — Task 1 and Task 2 complete; paused at Task 3 (Xcode target membership + scheme wiring) checkpoint:human-action.**

**Non-consumable IAP product `com.patrickhoughton.wordpuzzle.unlimited` ($2.99) declared locally in WordPuzzle.storekit and confirmed live in App Store Connect; Xcode target/scheme wiring remains.**

## Performance

- **Tasks:** 2 of 3 completed (Task 3 pending human action in Xcode GUI)
- **Files modified:** 1 (WordPuzzle/WordPuzzle/WordPuzzle.storekit)

## Accomplishments

- Created `WordPuzzle/WordPuzzle/WordPuzzle.storekit`, a valid StoreKit Configuration file declaring exactly one `NonConsumable` product (`com.patrickhoughton.wordpuzzle.unlimited`, display price `2.99`), matching CONTEXT decision D-04's locked product identifier.
- Confirmed the App Store Connect prerequisites for MON-02 are in place: Paid Applications Agreement, app record, and IAP product record with matching Product ID and price (see report-back answers below).

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the WordPuzzle.storekit configuration file** - `492dd27` (feat) — cherry-picked from prior worktree session commit `c372baf` (branch `worktree-agent-ad94b8c8990c99c4f`), which was created and verified but not yet merged to `main` when this continuation session started.
2. **Task 2: App Store Connect — agreement, app record, and IAP product** - no repo files (App Store Connect web UI action); outcome recorded below and in this SUMMARY commit.

Task 3 (Xcode target membership + scheme wiring) has NOT started — see Checkpoint below.

## Files Created/Modified

- `WordPuzzle/WordPuzzle/WordPuzzle.storekit` - Local StoreKit Configuration declaring `com.patrickhoughton.wordpuzzle.unlimited` as a NonConsumable product at $2.99, enabling `SKTestSession` simulation without a sandbox Apple ID.

## App Store Connect Report-Back (Task 2 — verbatim)

Patrick's four report-back answers, copied verbatim per the plan's `<output>` requirement:

1. Paid Applications agreement status: Active
2. App record exists: yes — app name used: Word Puzzle Unlimited
3. IAP product created with Product ID com.patrickhoughton.wordpuzzle.unlimited: yes
4. IAP price shown: USD 2.99 (base country pricing) and product status: Prepare for Submission

**Agreement status note:** The Paid Applications Agreement is Active, so plan 02-05 Task 3 (manual sandbox purchase test) is NOT blocked by agreement status.

**App name note:** The originally planned app record name "WordPuzzle" was taken on the App Store, so "Word Puzzle Unlimited" was used per the plan's own documented fallback instruction (Task 2, Step B). This is a display-name-only difference — it does not affect the bundle ID (`com.patrickhoughton.WordPuzzle`), the IAP Product ID (`com.patrickhoughton.wordpuzzle.unlimited`), or any code in this or future plans.

## Decisions Made

- App Store Connect app display name is "Word Puzzle Unlimited" instead of the originally planned "WordPuzzle" (name collision on the App Store). No code impact — bundle ID and IAP Product ID are unchanged and match WordPuzzle.storekit exactly.

## Deviations from Plan

None - Task 1 and Task 2 executed exactly as written. The app-name substitution in Task 2 was explicitly anticipated and pre-approved by the plan's own Step B fallback instructions, so it is not tracked as a deviation.

## Issues Encountered

- This continuation session's worktree started from an earlier commit than `main` (missing the Phase 1/Phase 2 planning commits and the parallel 02-02 plan's work). Resolved by fast-forward merging `main` into this branch, then cherry-picking Task 1's commit (`c372baf`, originally made in worktree branch `worktree-agent-ad94b8c8990c99c4f`, which had not yet been merged to `main`) forward as `492dd27`. No content changes — Task 1's file and commit message are unchanged from the original.

## User Setup Required

None further for Task 1/Task 2 — App Store Connect setup (agreement, app record, IAP product) is complete. Task 3 requires manual Xcode GUI steps (Target Membership checkboxes, Edit Scheme StoreKit Configuration dropdowns) — see Checkpoint below.

## Next Phase Readiness

- `com.patrickhoughton.wordpuzzle.unlimited` now appears identically in both the App Store Connect record and `WordPuzzle.storekit` (2 of the 3 places RESEARCH Pitfall 2 requires; the 3rd — `EntitlementStore.swift` — comes in plan 02-04).
- ROADMAP Phase 2 success criterion 5 (sandbox IAP product exists in App Store Connect before StoreKit code is written) is satisfied.
- STATE.md blocker "Paid Applications Agreement must be accepted before writing any StoreKit 2 code" is RESOLVED (status: Active).
- BLOCKED: Task 3 (Xcode target membership for WordPuzzleTests + scheme StoreKit Configuration dropdowns) must be completed before plan 02-04's `SKTestSession(configurationFileNamed: "WordPuzzle")` will resolve the file at test runtime. This is a genuine manual Xcode GUI step with no CLI equivalent.

---
*Phase: 02-persistence-entitlements*
*Status: IN PROGRESS — awaiting Task 3 human action*
