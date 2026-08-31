---
phase: 04-paywall-free-tier-gate
verified: 2026-08-31T22:45:00Z
status: passed
score: 5/5 must-haves verified
---

# Phase 4: Paywall & Free Tier Gate Verification Report

**Phase Goal:** Free users can play exactly 3 puzzles per day before hitting a paywall; the paywall has a working purchase flow, a visible Restore Purchases button, and passes Apple Review requirements.
**Verified:** 2026-08-31
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria 1-4)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A free user who completes their third puzzle sees the paywall screen — not before, not after a restart | ✓ VERIFIED | `GameViewModel.requestNextRound(isPremium:)` (GameViewModel.swift:96-103) gates on `startedToday >= freePuzzlesPerDay` (3), funneled from both `MissedWordsView.onContinue` (GameView.swift:69) and the sequenced launch `.task` (WordPuzzleApp.swift:70). Human QA (04-04-SUMMARY.md steps 2-14) confirms round 3 finishes to missed-words (not paywall), round 4 request shows paywall, and force-quit/relaunch after the limit goes straight to paywall. Unit tests `testRequestNextRoundPaywallsFreeUserAtDailyLimit`, `testRequestNextRoundAllowsFreeUserBelowDailyLimit` pass. |
| 2 | The paywall screen displays the price, a clear unlock CTA, and a "Restore Purchases" button that calls `AppStore.sync()` | ✓ VERIFIED | `PaywallView.swift` renders `priceText` (line 120), "Unlock Unlimited Puzzles" CTA (line 131), "Restore Purchases" link (line 157) wired to `onRestore` → `EntitlementStore.restore()` which calls `try await AppStore.sync()` (EntitlementStore.swift:90). Human QA steps 11-12 confirm real `$2.99` price and correct visual hierarchy. |
| 3 | A sandbox purchase grants unlimited puzzles immediately and survives an app restart (verified via StoreKit 2, not UserDefaults) | ✓ VERIFIED | `EntitlementStore.isPremium` is derived from `Transaction.currentEntitlements` on every launch (unchanged Phase 2 code, MON-04). Human QA on physical device (04-04-SUMMARY.md Task 2, step 4-5) confirms a real sandbox purchase unlocks immediately and a subsequent reinstall on the same account shows premium without repurchase. |
| 4 | Tapping Restore Purchases on a device with a prior sandbox purchase restores premium status without requiring re-purchase | ✓ VERIFIED | `PaywallView.onRestore` → `EntitlementStore.restore()` → `AppStore.sync()`; on success `GameView` calls `viewModel.requestNextRound(isPremium: true)` (GameView.swift:56-59). Human QA (04-04-SUMMARY.md Task 2, steps 6-9) confirms both the positive restore path (paywall dismisses, no repurchase) and the negative path (exact error string `"No previous purchase found for this Apple ID."`) render correctly. |

**Score:** 4/4 ROADMAP success criteria verified (plus 1 additional plan-level truth below)

### Additional Plan-Level Truth

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 5 | A round that is started but never finished still counts toward the daily 3-puzzle limit, but does not affect lifetime stats/best score | ✓ VERIFIED | `RoundStartRecord` (insert-only `@Model`) is written by `PersistenceStore.recordRoundStarted()`, called as the first statement of `GameViewModel.startNewRound(with:)` (GameViewModel.swift:120-121). `puzzlesPlayedToday()` counts `RoundStartRecord` (PersistenceStore.swift:62-68); `totalGamesPlayed()`/`bestScore()`/`totalWordsFound()` remain `GameRecord`-based (finished rounds only, PersistenceStore.swift:115-135). Confirmed by unit test `testStartNewRoundRecordsRoundStartWithoutRecordingAGame` and human QA (04-04-SUMMARY.md Task 1, steps 5-6: abandoned round 2 consumed a free puzzle, counter read `0 of 3` on relaunch). |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `WordPuzzle/WordPuzzle/Services/RoundStartRecord.swift` | Insert-only SwiftData model recording round starts (D-02) | ✓ VERIFIED | Exists, 16 lines, `@Model` with `date` field, no mutation methods. |
| `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` | `recordRoundStarted()`, `RoundStartRecord`-backed `puzzlesPlayedToday()`, `todayTotalScore()`, `todayTotalWordsFound()`, `nextResetDate()` | ✓ VERIFIED | All five present; `todayBounds()` shared helper used by all four day-scoped queries. |
| `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` | `RoundPhase.paywalled`, `freePuzzlesPerDay`, `requestNextRound(isPremium:)`, round-start side effect | ✓ VERIFIED | All present at lines 25, 29, 96, 121. |
| `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` | Single sequenced launch `.task` gating the first round | ✓ VERIFIED | One `.task` block (lines 51-71): `refreshEntitlements()` → `loadProduct()` → `wordList.load()` → `requestNextRound(isPremium:)`, sequential (no parallel `.task` race). |
| `WordPuzzle/WordPuzzle/Game/Views/PaywallView.swift` | Countdown, today's stats, price, Unlock CTA, Restore link, inline error slots | ✓ VERIFIED | 231 lines. All elements present; `countdownText(remaining:)` static formatter matches D-06 contract exactly (`{H}h {M}m` / `{M}m` / `"Less than a minute"`). `.interactiveDismissDisabled()` present (line 57) — true dead-end. |
| `WordPuzzle/WordPuzzle/Game/Views/ScoreBarView.swift` | Free-puzzle counter (D-03/D-04) | ✓ VERIFIED | `freePuzzlesRemaining`/`freePuzzlesPerDay` params render `"{n} of {total} free puzzles today"`; `nil` renders nothing for premium users. |
| `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` | `fullScreenCover` branching on `.paywalled` vs `.roundOver`, gated `onContinue`, ScoreBar wiring | ✓ VERIFIED | Branch logic at lines 32-72; gated `onContinue` at line 69; counter wiring at lines 82-86. |
| `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift`, `GameViewModelTests.swift`, `PaywallViewTests.swift`, `AppWiringTests.swift` | Test coverage for all of the above | ✓ VERIFIED | 59/59 tests pass across 11 suites (see Behavioral Spot-Checks). |
| `.planning/phases/04-paywall-free-tier-gate/04-04-SUMMARY.md` | Recorded manual QA outcome — authoritative proof for ROADMAP criteria 1, 3, 4 | ✓ VERIFIED | Exists; documents step-by-step PASS results for both the Simulator free-tier-gate script and the physical-device sandbox purchase/restore script, with 1 explicitly environment-blocked item (local Simulator `.storekit` purchase, a pre-existing dev-machine Xcode/StoreKit-testing bug per STATE.md 02-04, not a code defect — superseded by the real sandbox purchase in Task 2). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `PersistenceStore.makeContainer` | `RoundStartRecord` | `ModelContainer(for: GameRecord.self, RoundStartRecord.self, ...)` | ✓ WIRED | PersistenceStore.swift:29 |
| `PersistenceStore.puzzlesPlayedToday()` | `RoundStartRecord` | `FetchDescriptor<RoundStartRecord>` | ✓ WIRED | PersistenceStore.swift:64 |
| `GameViewModel.startNewRound(with:)` | `PersistenceStore.recordRoundStarted()` | direct call, first statement | ✓ WIRED | GameViewModel.swift:121 |
| `GameViewModel.requestNextRound(isPremium:)` | `PersistenceStore.puzzlesPlayedToday()` | gate check | ✓ WIRED | GameViewModel.swift:97 |
| `WordPuzzleApp` launch `.task` | `GameViewModel.requestNextRound(isPremium:)` | sequenced call after entitlement refresh + word list load | ✓ WIRED | WordPuzzleApp.swift:70 |
| `GameView` `fullScreenCover` | `PaywallView` | content-closure branch on `roundPhase == .paywalled` | ✓ WIRED | GameView.swift:33,38 |
| `MissedWordsView.onContinue` | `GameViewModel.requestNextRound(isPremium:)` | gated closure (replaces ungated `startNewRound()`) | ✓ WIRED | GameView.swift:69 |
| `GameView` | `PersistenceStore.nextResetDate()` | passed into `PaywallView.resetDate` | ✓ WIRED | GameView.swift:41 |
| `PaywallView.onUnlock`/`onRestore` | `EntitlementStore.purchaseUnlimited()`/`.restore()` | closures supplied by `GameView`, no environment reach-through | ✓ WIRED | GameView.swift:47,56; PaywallView.swift:21,23 |
| `EntitlementStore.restore()` | `AppStore.sync()` | direct call | ✓ WIRED | EntitlementStore.swift:90 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full unit + UI test suite builds and passes | `xcodebuild test -scheme WordPuzzle -destination 'iPhone 17'` | 59/59 unit tests (11 suites) + 6/6 UI tests pass, 0 failures | ✓ PASS |
| Gate logic unit-covered both branches | `testRequestNextRoundPaywallsFreeUserAtDailyLimit`, `testRequestNextRoundAllowsPremiumUserAtDailyLimit`, `testRequestNextRoundAllowsFreeUserBelowDailyLimit` | All pass | ✓ PASS |
| Abandoned-round side effect unit-covered | `testStartNewRoundRecordsRoundStartWithoutRecordingAGame` | Pass | ✓ PASS |
| Launch-time paywall race unit-covered | `testLaunchGatePaywallsFreeUserAlreadyAtDailyLimit` | Pass | ✓ PASS |
| Countdown format contract unit-covered | `PaywallViewTests` (3 cases) | Pass | ✓ PASS |
| Production schema includes `RoundStartRecord` | `testRoundStartRecordIsRegisteredInProductionSchema` | Pass | ✓ PASS |

Real StoreKit sandbox purchase/restore flows (requires a signed-in sandbox Apple ID and cannot be automated in CI) were exercised via human verification in plan 04-04 — see Human Verification Required below and 04-04-SUMMARY.md.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| MON-01 | 04-01, 04-02, 04-03, 04-04 | Free users can play 3 puzzles per day; a paywall gate appears after the 3rd puzzle ends | ✓ SATISFIED | Full gate + UI + human-verified end-to-end flow, see Truths 1 and 5 above. |

No orphaned requirements: REQUIREMENTS.md maps MON-02/MON-03/MON-04 to Phase 2 (already Complete), and only MON-01 to Phase 4, matching the single requirement ID declared across all four Phase 4 plans.

### Anti-Patterns Found

None. Scanned all 7 phase-modified source files (`RoundStartRecord.swift`, `PersistenceStore.swift`, `GameViewModel.swift`, `WordPuzzleApp.swift`, `GameView.swift`, `PaywallView.swift`, `ScoreBarView.swift`) for TODO/FIXME/HACK/PLACEHOLDER/"not yet implemented" markers — zero matches. No stub returns, no hardcoded empty data flowing to render paths, no handlers that only call `preventDefault`-equivalent no-ops.

One unrelated, pre-existing uncommitted local change was noted: `WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme` has an uncommitted one-line relative-path difference in the `StoreKitConfigurationFileReference` (path depth only, still resolves to `WordPuzzle.storekit`) — a benign Xcode-GUI artifact from the 04-04 manual QA session, not a Phase 4 code defect, and does not affect app behavior.

### Human Verification Required

Both of the following were already executed and recorded during plan 04-04 (see `.planning/phases/04-paywall-free-tier-gate/04-04-SUMMARY.md`), per the orchestrator's instruction that this SUMMARY is authoritative evidence for the human-verification success criteria. No further human action is required to close Phase 4; these are documented here for completeness only.

### 1. Real StoreKit sandbox purchase (physical device)

**Test:** Tap "Unlock Unlimited Puzzles" against a real sandbox tester account.
**Expected:** Purchase completes, `isPremium` becomes true, paywall dismisses into a new round, and the entitlement survives an app restart/reinstall.
**Why human:** Requires a signed-in sandbox Apple ID and real StoreKit purchase sheet interaction; not automatable in CI.
**Recorded result:** PASS (04-04-SUMMARY.md Task 2, steps 3-5).

### 2. Restore Purchases positive and negative cases (physical device)

**Test:** Tap "Restore Purchases" on a device signed into (a) an account with a prior purchase and (b) a never-purchased account.
**Expected:** (a) Premium restored silently, no repurchase/charge; (b) exact error text "No previous purchase found for this Apple ID." shown, paywall remains.
**Why human:** Requires real sandbox Apple ID account switching and `AppStore.sync()` against Apple's live sandbox servers.
**Recorded result:** PASS for both cases (04-04-SUMMARY.md Task 2, steps 6-9).

Two items were recorded as environment-blocked/inconclusive rather than PASS/FAIL, not a code defect:
- Local Simulator `.storekit`-configuration purchase (steps 15-17 of Task 1) — repeatedly hit an unresolvable "Apple Account Verification" loop, the same class of pre-existing Xcode 26.6/iOS 26.5 Simulator StoreKit-testing bug already documented in STATE.md from Phase 2 (02-04 blocker). Superseded by the real sandbox purchase in Task 2, which is authoritative per the established 02-05 precedent.
- Negative-restore-case reproduction via App Store Connect "Clear Purchase History" on an already-owning tester — sandbox propagation lag made this unreliable; worked around by using a freshly created never-purchased tester account instead (successfully reproduced the exact error string).

### Gaps Summary

No gaps found. All ROADMAP Phase 4 success criteria are verified either through automated tests and static code inspection (gate logic, UI contract, wiring) or through recorded human verification (real sandbox purchase/restore, cross-launch persistence). The two environment-blocked items are attributable to a documented, pre-existing local-machine tooling limitation (not reproducible on physical devices) and do not block the phase goal, consistent with the Phase 2 precedent for the same class of issue.

---
*Verified: 2026-08-31*
*Verifier: Claude (gsd-verifier)*
