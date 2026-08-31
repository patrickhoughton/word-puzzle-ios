---
phase: 04-paywall-free-tier-gate
plan: 04
subsystem: payments
tags: [storekit, in-app-purchase, manual-qa, sandbox]

requires:
  - phase: 04-paywall-free-tier-gate
    provides: RoundStartRecord persistence (04-01), requestNextRound gate (04-02), PaywallView UI (04-03)
provides:
  - Human-verified end-to-end proof of the free-tier gate, paywall content, real sandbox purchase, and restore-across-reinstall flows
affects: [phase-05, future-IAP-work]

tech-stack:
  added: []
  patterns: []

key-files:
  created: [.planning/phases/04-paywall-free-tier-gate/04-04-SUMMARY.md]
  modified: []

key-decisions:
  - "Local Simulator .storekit purchase (steps 15-17) could not be completed on this dev machine — same class of Xcode 26.6/iOS 26.5 StoreKit-testing environment bug already documented for this machine in Phase 2 (STATE.md 02-04 blocker). Deferred to the real sandbox purchase in Task 2 as authoritative proof, per the Phase 2 precedent (02-05)."
  - "Restoring on an account that already purchased the product (from Phase 2's real sandbox test) correctly shows premium immediately on reinstall with no paywall/counter and without tapping Restore — confirmed as intended MON-04 behavior, not a bug, matching the STATE.md 02-05 decision."
  - "The negative-restore-case error string ('No previous purchase found for this Apple ID.') could not be forced via App Store Connect 'Clear Purchase History' on an already-owning tester, even after a device-level sandbox sign-out/sign-in cycle — Apple's sandbox propagation lag made this unreliable. A freshly created, never-purchased sandbox tester account was used instead and successfully triggered the exact error string."

patterns-established: []

requirements-completed: [MON-01]

duration: ~75min
completed: 2026-08-31
---

# Phase 4 Plan 04: Manual Verification Summary

**End-to-end human verification of the free-tier paywall gate, paywall UI contract, real StoreKit sandbox purchase, and restore-across-reinstall — all steps PASS except two environment-blocked/inconclusive items tied to a pre-existing dev-machine StoreKit-testing bug, not app defects.**

## Performance

- **Duration:** ~75 min (interactive, spanning Simulator and physical-device testing)
- **Tasks:** 2/2 (both checkpoint:human-verify)
- **Files modified:** 0 (verification only) + this SUMMARY.md
- **Device (Task 2):** iPhone 15 Pro, iOS 26.6
- **Simulator (Task 1):** iPhone 17 Pro, iOS 26.5

## Task 1: Free-tier gate end-to-end (Simulator)

| Step | Description | Result |
|------|-------------|--------|
| 2 | Fresh launch shows `2 of 3 free puzzles today`, grey/secondary | **PASS** |
| 3 | Finish round 1 → missed-words screen (not paywall) | **PASS** |
| 4 | Next Puzzle → round 2, counter reads `1 of 3 free puzzles today` | **PASS** |
| 5 | Round 2 backgrounded + force-quit without finishing (abandoned) | done (setup step) |
| 6 | Relaunch starts round 3, counter reads `0 of 3 free puzzles today` — abandoned round consumed a free puzzle (D-02) | **PASS** |
| 7 | Finish round 3 → missed-words screen (not paywall — wall is on 4th, not 3rd) | **PASS** |
| 8 | Next Puzzle → PAYWALL appears | **PASS** |
| 9 | Countdown live-ticking; observed `7h 39m` at 4:20 PM and `7h 38m` at 4:21 PM — consistent with local midnight | **PASS** |
| 10 | Today's Stats shows Puzzles today / Streak / Score / Words found in order (3 / 1 / 0 / 0 — no words found in the two finished test rounds; nonzero-sum arithmetic already covered by automated `testTodayTotalsSumFinishedRoundsForTodayOnly`) | **PASS** |
| 11 | Price line shows `$2.99` in gold, not `—` | **PASS** |
| 12 | "Unlock Unlimited Puzzles" prominent gold button; "Restore Purchases" smaller grey link below | **PASS** |
| 13 | No dismiss affordance; swipe-down confirmed does not dismiss | **PASS** |
| 14 | Force-quit + relaunch → paywall appears directly, no puzzle-screen flash | **PASS** |
| 15-17 | Simulated (local `.storekit` config) purchase — repeatedly triggered a real "Sign in to Apple Account" / "Apple Account Verification" loop that never resolved into a completed local test purchase, even after a full Simulator erase (Device → Erase All Content and Settings) | **ENVIRONMENT-BLOCKED** — see Issues Encountered |

## Task 2: Real sandbox purchase + restore-across-reinstall (physical device)

| Step | Description | Result |
|------|-------------|--------|
| 3 | Paywall price line showed real App Store Connect price `$2.99` | **PASS** |
| 4 | Real sandbox purchase (new, never-purchased tester) completed via "Unlock Unlimited Puzzles" → paywall dismissed, new round started | **PASS** |
| 5 | Reinstall on original sandbox tester (already owned the product from Phase 2's 02-05 test) → premium recognized immediately on launch, no paywall, no counter, without tapping Restore — matches documented STATE.md 02-05 expectation | **PASS** |
| 6-8 | Sign out original tester → delete/reinstall → reach paywall → sign back in → tap Restore Purchases → paywall dismissed into new round, no error text, no re-purchase prompt/charge | **PASS** |
| 9 | Negative case: fresh never-purchased sandbox tester taps Restore Purchases → exact red inline text `No previous purchase found for this Apple ID.` shown, paywall stays | **PASS** (see Issues Encountered for the path that didn't work) |
| 10 | Teardown: scheme's Run StoreKit Configuration confirmed restored to `WordPuzzle.storekit` (verified directly in the `.xcscheme` XML on disk, both LaunchAction and TestAction) | **PASS** |

## Accomplishments

- Confirmed D-02 (abandoned rounds count toward the daily limit but not lifetime stats) end-to-end via real background/force-quit behavior, not just unit tests
- Confirmed the paywall triggers on exactly the 4th round request, never the 3rd, on both the post-finish and cold-launch trigger points
- Confirmed a real StoreKit sandbox purchase and a real Restore-Purchases-after-reinstall flow both work correctly on a physical device
- Confirmed the Restore Purchases negative-case error copy renders exactly as specified

## Decisions Made

See `key-decisions` in frontmatter.

## Issues Encountered

1. **Local Simulator `.storekit` purchase never completed (steps 15-17).** Tapping "Unlock Unlimited Puzzles" against the local `WordPuzzle.storekit` configuration file repeatedly surfaced a real "Sign in to Apple Account" dialog, and after entering placeholder credentials, an "Apple Account Verification — Open Settings to continue signing in" loop that never resolved into a completed local test purchase. This reproduced identically after a full Simulator erase (Device → Erase All Content and Settings). This is the same class of environment issue already diagnosed and documented in STATE.md from Phase 2 (`02-04: EntitlementStoreTests ... likely an Xcode 26.6/iOS 26.5 Simulator SKTestSession bug, not a code defect`). Per that established precedent, this was deferred to Task 2's real sandbox purchase as the authoritative proof rather than continuing to chase a tooling bug. `EntitlementStore.purchaseUnlimited()` is unchanged Phase-2 code that was already sandbox-verified in 02-05.

2. **Xcode GUI build failure unrelated to Phase 4 code.** Early in this session, an Xcode GUI build (not command-line `xcodebuild`, which succeeded both before and after) failed with `Build input file cannot be found: '.../WordPuzzle.entitlements'`. No such file, and no `CODE_SIGN_ENTITLEMENTS` reference, exists anywhere in the project or git history — this was stale Xcode-side build-graph/DerivedData state. Resolved by clearing `~/Library/Developer/Xcode/DerivedData/WordPuzzle-*` and restarting Xcode.

3. **Negative restore case required a fresh sandbox tester.** Clearing purchase history for the already-owning sandbox tester via App Store Connect, even combined with a device-level Settings → Developer → Sandbox Apple Account sign-out/sign-in cycle, did not produce the "no previous purchase" error — Restore kept succeeding, consistent with Apple's sandbox purchase-history-clear propagation being unreliable/delayed. Creating a brand-new, never-purchased sandbox tester account and using that instead reliably reproduced the exact expected error string.

## Next Phase Readiness

MON-01 (free-tier paywall) is fully implemented, unit-tested, and now human-verified end-to-end across both the free-tier gate mechanics and the real StoreKit purchase/restore flows. Phase 4 is complete. No blockers carried forward beyond the pre-existing, already-documented dev-machine StoreKit local-testing limitation (Simulator-only; does not affect real devices or production).

---
*Phase: 04-paywall-free-tier-gate*
*Completed: 2026-08-31*
