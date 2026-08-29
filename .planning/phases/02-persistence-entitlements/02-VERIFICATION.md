---
phase: 02-persistence-entitlements
verified: 2026-08-29T16:54:07Z
status: passed
score: 5/5 must-haves verified
---

# Phase 2: Persistence & Entitlements Verification Report

**Phase Goal:** Game history and daily usage are stored in SwiftData; premium status is read from StoreKit 2 `Transaction.currentEntitlements` on every app launch
**Verified:** 2026-08-29T16:54:07Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `PersistenceStore.puzzlesPlayedToday()` returns correct count and persists across app restarts | ✓ VERIFIED | `PersistenceStore.swift:49-58` uses `fetchCount` + date-range `#Predicate`; `PersistenceStoreTests.testPuzzlesPlayedTodayPersistsAcrossRestart` opens a real on-disk store at a temp URL, releases the container, reopens it, and re-asserts the count — test passes. Also demonstrated on a physical device (02-05-SUMMARY item 8: 7/7 survived force-quit + relaunch). |
| 2 | Daily streak counter increments on consecutive days and resets after a missed day | ✓ VERIFIED | `PersistenceStore.currentStreak(now:)` (`PersistenceStore.swift:95-132`) derives streak from `GameRecord.date`, bounded 400-day window, grace-day logic. `PersistenceStoreTests.testStreakIncrementsOnConsecutiveDays`, `testStreakResetsAfterMissedDay`, `testStreakSurvivesGraceDayBeforePlayingToday` all pass (verified by direct test run). |
| 3 | Lifetime stats (total words found, best score, total games played) accumulate correctly across sessions | ✓ VERIFIED | `totalGamesPlayed()` (COUNT), `bestScore()` (sort + fetchLimit=1), `totalWordsFound()` (fetch+reduce) in `PersistenceStore.swift:63-83`. `PersistenceStoreTests.testLifetimeStatsAccumulate` asserts accumulation across 4 recorded sessions including a lower-scoring session not lowering `bestScore` — passes. |
| 4 | `EntitlementStore.isPremium` reads `Transaction.currentEntitlements` (not UserDefaults) and is correct after a sandbox purchase and a restore | ✓ VERIFIED (dual proof) | Code: `EntitlementStore.swift:41-50` derives `isPremium` solely from `for await result in Transaction.currentEntitlements`; `grep -Ec "AppStorage\|UserDefaults\|SKPaymentQueue\|restoreCompletedTransactions"` on the file returns 0. Automated: 2/5 `SKTestSession` tests pass in this Simulator environment (`testIsPremiumIsFalseWithoutAPurchase`, `testUnlimitedProductResolvesFromConfiguration`); 3/5 (`testPurchaseUnlocksPremium`, `testRestoreUnlocksPremiumAfterFreshInstall`, `testClearingTransactionsRevokesPremium`) fail with `SKInternalErrorDomain Code=3 / "notEntitled"` — reproduced independently during this verification (see Known Issue below). Real-device proof: 02-05-SUMMARY documents a genuine App Store Connect sandbox purchase and restore on a physical iPhone 15 Pro, both setting `isPremium == true`, surviving force-quit/relaunch and delete/reinstall. |
| 5 | Sandbox IAP product created and attached in App Store Connect before any StoreKit code was written | ✓ VERIFIED | 02-01-SUMMARY records Patrick's verbatim report-back: Paid Applications Agreement Active, app record exists, IAP product `com.patrickhoughton.wordpuzzle.unlimited` created at $2.99 (status: Prepare for Submission) — all completed in 02-01 before 02-04's `EntitlementStore.swift` was written. Product ID string matches identically across `WordPuzzle.storekit`, `EntitlementStore.swift`, and (per report-back) App Store Connect. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `WordPuzzle/WordPuzzle/WordPuzzle.storekit` | Local StoreKit product config, `com.patrickhoughton.wordpuzzle.unlimited` | ✓ VERIFIED | 54 lines, contains matching productID, NonConsumable, $2.99 |
| `WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` | `WordPuzzle.storekit` in `WordPuzzleTests` target | ✓ VERIFIED | `PBXFileSystemSynchronizedBuildFileExceptionSet` lists `WordPuzzle.storekit` |
| `WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme` | Run/Test StoreKit Configuration reference | ✓ VERIFIED | `StoreKitConfigurationFileReference` present under both `<TestAction>` and `<LaunchAction>` |
| `WordPuzzle/WordPuzzle/Services/GameRecord.swift` | SwiftData `@Model`, date/score/wordsFoundCount | ✓ VERIFIED | 17 lines, `@Model final class GameRecord` with exactly 3 stored properties |
| `WordPuzzle/WordPuzzle/Services/PersistenceStore.swift` | `@Observable` service: makeContainer, record, puzzlesPlayedToday, totalGamesPlayed, bestScore, totalWordsFound, currentStreak | ✓ VERIFIED | 133 lines, all 7 methods present and substantive (no stubs) |
| `WordPuzzle/WordPuzzleTests/PersistenceStoreTests.swift` | Swift Testing coverage of RET-01/RET-02 | ✓ VERIFIED | 150 lines, 9 `@Test` functions, all pass |
| `WordPuzzle/WordPuzzle/Services/ScoreCalculator.swift` | Pure D-02 scoring function | ✓ VERIFIED | 25 lines, `points(for:isPangram:)` and `score(for:pangrams:)` |
| `WordPuzzle/WordPuzzleTests/ScoreCalculatorTests.swift` | D-02 branch coverage | ✓ VERIFIED | 35 lines, 5 `@Test` functions, all pass |
| `WordPuzzle/WordPuzzle/Services/EntitlementStore.swift` | `@Observable` StoreKit 2 service: refreshEntitlements, loadProduct, purchase, restore | ✓ VERIFIED | 120 lines, `Transaction.currentEntitlements` iteration present, no UserDefaults/AppStorage in code |
| `WordPuzzle/WordPuzzleTests/EntitlementStoreTests.swift` | XCTest + SKTestSession coverage | ✓ VERIFIED (partial pass, documented) | 88 lines, 5 XCTest cases; 2/5 pass in this environment, 3/5 fail with a documented, reproduced, environment-level Simulator bug (see below) |
| `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` | Service instantiation, `.environment()` injection, `.modelContainer`, launch `.task` | ✓ VERIFIED | 52 lines, both services constructed once, injected, `.task` fires `refreshEntitlements()` + `loadProduct()` on every launch |
| `WordPuzzle/WordPuzzle/ContentView.swift` | DEBUG-only entitlement harness | ✓ VERIFIED | 86 lines, `#if DEBUG` `EntitlementDebugPanel` reads both stores via `@Environment`, marked TEMPORARY with a Phase-3 deletion note |
| `WordPuzzle/WordPuzzleTests/AppWiringTests.swift` | Regression test for production on-disk container | ✓ VERIFIED | 27 lines, `testProductionContainerCanBeCreated` calls `PersistenceStore.makeContainer()` (no `inMemory:`/`url:` args — the real production path) and exercises every query method |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `WordPuzzle.storekit` | `WordPuzzleTests` target | `PBXFileSystemSynchronizedBuildFileExceptionSet` | ✓ WIRED | Confirmed in `project.pbxproj` line 36 |
| App Store Connect IAP record | `WordPuzzle.storekit` productID | identical string `com.patrickhoughton.wordpuzzle.unlimited` | ✓ WIRED | Matches 02-01 report-back and file content |
| `PersistenceStore.swift` | `GameRecord` | `FetchDescriptor<GameRecord>` | ✓ WIRED | Used in `puzzlesPlayedToday`, `totalGamesPlayed`, `bestScore`, `totalWordsFound`, `currentStreak` |
| `PersistenceStore.swift` | SQLite COUNT pushdown | `context.fetchCount` with date-range `#Predicate` | ✓ WIRED | Lines 57, 64 |
| `EntitlementStore.swift` | StoreKit `Transaction.currentEntitlements` | `for await result in Transaction.currentEntitlements` | ✓ WIRED | Line 43 |
| `EntitlementStore.swift` | App Store restore | `AppStore.sync()` in `restore()` | ✓ WIRED | Line 90 |
| `EntitlementStoreTests.swift` | `WordPuzzle.storekit` | `SKTestSession(configurationFileNamed: "WordPuzzle")` | ✓ WIRED | Line 19; confirmed to resolve correctly (2/5 tests that don't call `buyProduct` pass) |
| `WordPuzzleApp.swift` | `EntitlementStore.refreshEntitlements()` | `.task` on WindowGroup content | ✓ WIRED | Lines 42-48 |
| `WordPuzzleApp.swift` | `PersistenceStore` | `.environment(persistenceStore)` | ✓ WIRED | Line 40 |
| `ContentView.swift` | `EntitlementStore` | `@Environment(EntitlementStore.self)` | ✓ WIRED | Line 34 |
| `ContentView.swift` | `PersistenceStore` | `@Environment(PersistenceStore.self)` | ✓ WIRED | Line 35 |

### Data-Flow Trace (Level 4)

Not applicable in the strict sense — Phase 2 has no rendering UI beyond the temporary DEBUG-only `EntitlementDebugPanel`. That panel's displayed values (`isPremium`, product price, played-today, streak, lifetime stats) are traced directly to live method calls on the injected `@Environment` stores (`entitlementStore.isPremium`, `persistenceStore.puzzlesPlayedToday()`, etc.) — no hardcoded/static values found. This was exercised end-to-end on a physical device in 02-05 (real sandbox purchase changed the on-screen `isPremium` value; `record()` taps changed the on-screen played-today count from 0 to 7).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite passes (excluding known Simulator issue) | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` | 35/38 passed, 3 failed (`EntitlementStoreTests.testPurchaseUnlocksPremium`, `testRestoreUnlocksPremiumAfterFreshInstall`, `testClearingTransactionsRevokesPremium`, all `caught error: "notEntitled"`) | ✓ PASS (matches documented, non-blocking known issue) |
| No forbidden premium-flag patterns in EntitlementStore.swift | `grep -Ec "AppStorage\|UserDefaults\|SKPaymentQueue\|restoreCompletedTransactions" EntitlementStore.swift` | 0 | ✓ PASS |
| No `AppStorage`/`premium` UserDefaults flag anywhere in app source | `grep -rn "AppStorage" WordPuzzle/WordPuzzle --include="*.swift"` | no matches | ✓ PASS |
| All referenced commits exist in git history | 15 commit hashes checked against `git log --all` | all 15 FOUND | ✓ PASS |

Re-running the full suite independently during this verification reproduced the exact same 3 failures with the exact same error signature (`SKInternalErrorDomain Code=3` / `"notEntitled"`) documented in 02-04-SUMMARY.md and 02-05-SUMMARY.md — confirming this is a stable, already-diagnosed environment issue, not a regression or a fabricated claim.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|-------------|--------|----------|
| MON-02 | 02-01, 02-04, 02-05 | User can purchase a one-time non-consumable IAP ($2.99) to unlock unlimited puzzles permanently | ✓ SATISFIED | `EntitlementStore.purchaseUnlimited()` implemented against real StoreKit 2 API; App Store Connect product created (02-01); real sandbox purchase completed and verified on physical device (02-05, isPremium: true after purchase, survives relaunch) |
| MON-03 | 02-04, 02-05 | Paywall screen includes a visible "Restore Purchases" button (Guideline 3.1.1) | ✓ SATISFIED (structurally; UI paywall is Phase 4 scope) | `EntitlementStore.restore()` calls `AppStore.sync()`; `EntitlementDebugPanel` exposes a working "Restore Purchases" button used to verify the flow on-device (02-05, isPremium: true after restore). Note: the *visible paywall screen* itself is explicitly Phase 4 scope per ROADMAP — Phase 2 only needed the underlying restore mechanism, which is proven working. |
| MON-04 | 02-04, 02-05 | Premium unlock status is verified via `Transaction.currentEntitlements` on every app launch (no UserDefaults flag) | ✓ SATISFIED | `EntitlementStore.isPremium` derived exclusively from `Transaction.currentEntitlements`; grep-verified absence of `AppStorage`/`UserDefaults` in the file; `.task` on `WindowGroup` fires `refreshEntitlements()` on every launch (`WordPuzzleApp.swift`); account-scoped re-derivation behavior confirmed on-device (02-05 item 6) |
| RET-01 | 02-03, 02-05 | App tracks and displays a daily streak counter | ✓ SATISFIED | `PersistenceStore.currentStreak(now:)` implemented with grace-day/bounded-window logic; 4 dedicated streak tests pass; on-device "Streak" display in `EntitlementDebugPanel` |
| RET-02 | 02-02, 02-03, 02-05 | App shows lifetime stats: total words found, best score, total games played | ✓ SATISFIED | `totalGamesPlayed()`, `bestScore()`, `totalWordsFound()` implemented; `testLifetimeStatsAccumulate` passes; on-device "Games / Best / Words" display in `EntitlementDebugPanel` |

No orphaned requirements — REQUIREMENTS.md maps exactly MON-02, MON-03, MON-04, RET-01, RET-02 to Phase 2, and every one of those IDs appears in at least one plan's `requirements:` frontmatter field, with the union covering the full set.

### Anti-Patterns Found

None. Scanned all six phase-2 source files (`PersistenceStore.swift`, `GameRecord.swift`, `ScoreCalculator.swift`, `EntitlementStore.swift`, `WordPuzzleApp.swift`, `ContentView.swift`) for TODO/FIXME/PLACEHOLDER/"not yet implemented"/empty-implementation patterns — zero matches.

One item worth noting as an ℹ️ Info, not a blocker: `ContentView.swift`'s `EntitlementDebugPanel` is explicitly self-documented as `TEMPORARY — Phase 2 only` scaffolding that "MUST be deleted when Phase 3 replaces ContentView." This is intentional, disclosed scaffolding (not a stub hiding missing functionality) — the actual services it exercises (`EntitlementStore`, `PersistenceStore`) are fully implemented and were proven working through this panel on a physical device.

### Known Issue (Non-Blocking, Disclosed)

**3 of 5 `EntitlementStoreTests` fail in this machine's iOS Simulator** (`testPurchaseUnlocksPremium`, `testRestoreUnlocksPremiumAfterFreshInstall`, `testClearingTransactionsRevokesPremium`), all with `SKInternalErrorDomain Code=3` / `"notEntitled"` when `SKTestSession.buyProduct(identifier:)` is called. This verification independently reproduced the identical failure signature.

This was extensively diagnosed in 02-04-SUMMARY.md: parallel-executor contention, wrong simulator, stale simulator state, sandboxed Bash, headless vs GUI simulator, orphaned `storekitd` processes, Developer Mode (enabled), and a full OS reboot were all ruled out. The same purchase code, run against a physical iPhone, gets further (a different, later-stage error), confirming this is a Simulator-hosted `storekitd`/`SKTestSession` daemon issue specific to this Xcode 26.6 / iOS 26.5 combination on this machine — not a defect in `EntitlementStore.swift` or its test file.

Per CONTEXT decision D-06, Phase 2's plan always required a real-device sandbox purchase/restore test as the authoritative proof for MON-02/MON-03, independent of `SKTestSession`. That real-device test was completed in plan 02-05 and is documented with a verbatim, itemized report-back in 02-05-SUMMARY.md, including two correctly-explained deviations from the plan's literal scripted expectations (account-scoped entitlement visibility before an explicit Restore tap, and a UI-refresh-only display quirk in the disposable debug panel — neither is a data or entitlement-logic bug).

Given the real-device proof exists and the Simulator failure is well-diagnosed as an environment artifact (not a code defect), this is treated as **non-blocking** for Phase 2 goal achievement, consistent with the orchestrator's guidance for this verification.

### Human Verification Required

None required beyond what has already been completed. The one item that would normally require human verification — a real sandbox purchase and restore on a physical device — has already been performed and documented verbatim in 02-05-SUMMARY.md (Patrick's iPhone 15 Pro, iOS 26.6).

### Gaps Summary

No gaps found. All 5 ROADMAP success criteria are verified against actual code, all 13 phase-2 artifacts exist and are substantive (no stubs), all key links are wired, all 5 requirement IDs (MON-02, MON-03, MON-04, RET-01, RET-02) are satisfied, and 15 referenced commits were confirmed present in git history. The one automated-test shortfall (3/5 `EntitlementStoreTests` failing under `SKTestSession` in this Simulator environment) is a disclosed, reproduced, non-blocking environment issue with independent real-device proof covering the same requirements.

---

*Verified: 2026-08-29T16:54:07Z*
*Verifier: Claude (gsd-verifier)*
