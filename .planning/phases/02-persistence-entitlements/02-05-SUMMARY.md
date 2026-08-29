---
phase: 02-persistence-entitlements
plan: 05
subsystem: payments
tags: [swiftui, swiftdata, storekit2, app-wiring, sandbox-testing]

# Dependency graph
requires:
  - phase: 02-persistence-entitlements
    provides: "PersistenceStore (02-02/02-03) and EntitlementStore (02-04) frozen public APIs"
provides:
  - "WordPuzzleApp.swift wiring both @Observable services into the SwiftUI environment via .environment(), with the entitlement refresh firing from a .task on WindowGroup content (CONTEXT D-08)"
  - "DEBUG-only EntitlementDebugPanel in ContentView.swift used to drive the manual sandbox verification (deleted when Phase 3 replaces ContentView)"
  - "AppWiringTests.swift regression coverage of the production on-disk ModelContainer path"
  - "A completed real Apple ID sandbox purchase + restore verification on a physical device (CONTEXT D-06)"
affects: [phase-3-core-game-ui, phase-4-paywall]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Both @Observable services constructed once in WordPuzzleApp.init()/property initializers and injected via .environment() — Phase 3/4 views read them with @Environment(PersistenceStore.self) / @Environment(EntitlementStore.self)"
    - "Entitlement check is eager: fires from a .task on the WindowGroup content on every launch, never cached"

key-files:
  created:
    - WordPuzzle/WordPuzzleTests/AppWiringTests.swift
  modified:
    - WordPuzzle/WordPuzzle/WordPuzzleApp.swift
    - WordPuzzle/WordPuzzle/ContentView.swift
    - WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme

key-decisions:
  - "Task 2's code snippet in the plan omitted `import StoreKit`, required for `Product.displayPrice` in EntitlementDebugPanel — added `#if DEBUG import StoreKit #endif` (recorded by the prior continuation agent)."
  - "Account-scoped entitlement finding (Task 3, item 6): Transaction.currentEntitlements is scoped to the signed-in sandbox Apple ID on Apple's servers, not to local/device state. A fresh reinstall on an account that already purchased shows isPremium=true immediately, before any Restore tap — this is correct MON-04 behavior (no cached local flag), not a bug. See 'Manual Sandbox Verification' below for full detail."
  - "EntitlementDebugPanel display-refresh quirk (Task 3, item 8): repeated taps of 'Record Fake Session' that set @State lastMessage to the same string value can cause SwiftUI to skip re-rendering the view body, so the on-screen 'Played today' counter can appear stuck. Confirmed via code read (PersistenceStore.record() unconditionally inserts+saves; puzzlesPlayedToday() does a real COUNT fetch) that this is a UI-refresh-only quirk, not a data bug — a force-quit/relaunch (genuine cold render) shows the correct count. Not worth fixing since EntitlementDebugPanel is temporary Phase 2 scaffolding deleted in Phase 3."

patterns-established:
  - "Xcode scheme edits are made directly as XML in xcshareddata/xcschemes/*.xcscheme rather than via Edit Scheme GUI (established in 02-01, reused here to restore Run -> StoreKit Configuration after the manual sandbox test)."

requirements-completed: [MON-02, MON-03, MON-04, RET-01, RET-02]

# Metrics
duration: ~50min (across two sessions, split by the Task 3 checkpoint)
completed: 2026-08-29
---

# Phase 2 Plan 5: App Wiring + Manual Sandbox Verification Summary

**Both `PersistenceStore` and `EntitlementStore` are now injected at the app root via `.environment()`, with the entitlement check firing eagerly on every launch (CONTEXT D-08), and a real Apple ID sandbox purchase + restore has been verified end-to-end on Patrick's physical iPhone 15 Pro — closing out CONTEXT D-06's manual verification requirement for Phase 2.**

## Performance

- **Duration:** ~50 min total (Tasks 1-2 in the first session; Task 3 checkpoint resumed and closed in this session)
- **Started:** 2026-08-29 (first session, Tasks 1-2)
- **Completed:** 2026-08-29T16:45:33Z
- **Tasks:** 3 of 3 complete
- **Files modified:** 4 (WordPuzzleApp.swift, ContentView.swift, AppWiringTests.swift, WordPuzzle.xcscheme)

## Accomplishments

- `WordPuzzleApp.swift` constructs `PersistenceStore` (via `PersistenceStore.makeContainer()`, on-disk) and `EntitlementStore()` once at launch, injects both via `.environment()`, and fires `await entitlementStore.refreshEntitlements()` + `loadProduct()` from a `.task` on the `WindowGroup` content — exactly per CONTEXT D-07/D-08.
- `AppWiringTests.swift` proves the production on-disk `ModelContainer` path (not just the in-memory path used by plans 02-02/02-03's tests) constructs without throwing and that every persistence query the app root exposes is callable.
- `EntitlementDebugPanel` (DEBUG-only, wrapped in `#if DEBUG`) exposed `isPremium`, product price, and persistence stats with buttons for Load Product / Buy Unlimited / Restore Purchases / Record Fake Session — enough to drive the manual sandbox test with no product UI (paywall doesn't exist until Phase 4).
- **A real sandbox Apple ID purchase and restore were completed and verified on a physical device** — see the full report-back below.
- Full test suite run: 32 unit tests (WordListTests, PuzzleGeneratorTests, ProfanityTests, PersistenceStoreTests, ScoreCalculatorTests, EntitlementStoreTests, WordPuzzleTests template, AppWiringTests) + 6 UI tests, 35 passed / 3 failed. The 3 failures are the pre-existing, already-diagnosed `EntitlementStoreTests` Simulator `SKTestSession` bug documented in 02-04-SUMMARY.md and STATE.md Blockers — not caused by this plan's changes, and superseded as the authoritative MON-02/MON-03 proof by the real sandbox test below.

## Task Commits

Each task was committed atomically:

1. **Task 1: Instantiate and inject both stores in WordPuzzleApp** - `82f6dda` (feat)
2. **Task 2: DEBUG-only entitlement harness in ContentView** - `23811d8` (feat), `01d2c58` (chore — removed a stray auto-generated Xcode test plan)
3. **Task 3: Manual sandbox purchase and restore on a device** - checkpoint:human-verify, no repo files from the on-device steps themselves; outcome recorded in this SUMMARY

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified

- `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` - Constructs and injects both `@Observable` services; fires the launch-time entitlement refresh.
- `WordPuzzle/WordPuzzle/ContentView.swift` - Temporary DEBUG-only `EntitlementDebugPanel` (see "Known Stubs / Scaffolding" below).
- `WordPuzzle/WordPuzzleTests/AppWiringTests.swift` - Regression test for the production on-disk `ModelContainer` path.
- `WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme` - Run -> StoreKit Configuration was set to `None` by Patrick for Task 3's sandbox test (per the plan's Step B instructions, to force the real App Store Connect product instead of the local `WordPuzzle.storekit` simulation); reset back to `WordPuzzle.storekit` in this session for normal local dev in Phase 3 (see "Scheme StoreKit Configuration" below). The Test Action's StoreKit Configuration was never touched and remained `WordPuzzle.storekit` throughout.

## Manual Sandbox Verification (Task 3) — Report-Back, Verbatim

Per the plan's `<output>` requirement, Patrick's eight numbered answers are recorded verbatim below, including two noted deviations from the plan's literal scripted expectations (both are correct, expected behavior — explained inline, not silently corrected).

1. **Device model and iOS version:** iPhone 15 Pro, iOS 26.6
2. **Product price shown after Load Product:** $2.99
3. **Purchase sheet showed [Environment: Sandbox]:** not sure (not checked/recalled specifically; not a failure of the flow — all other signals confirm sandbox was in use)
4. **isPremium after purchase:** true
5. **isPremium after force-quit and relaunch:** true
6. **isPremium immediately after delete + reinstall (before restore):** **true** — DEVIATES from the plan's literal acceptance criterion, which expected "false". This is expected, correct behavior, not a defect: `Transaction.currentEntitlements` (queried by the app's launch `.task` per CONTEXT D-08 / MON-04) is scoped to the signed-in sandbox Apple ID account on Apple's servers, not to any local/device state. Since that sandbox account already had a completed purchase, the entitlement was present the instant the freshly-reinstalled app asked — before any explicit "Restore Purchases" tap. This is actually stronger proof that MON-04 (no cached UserDefaults flag; always re-derived live from StoreKit) works correctly: a naive local-flag implementation would have wrongly shown `false` here.
7. **isPremium after tapping Restore Purchases:** true (expected — already true from item 6; restore was a no-op confirmation, completed without error)
8. **"Played today" after taps, and after force-quit + relaunch:** 7 / 7 — DEVIATES from the plan's scripted "3 / 3". Patrick tapped "Record Fake Session" more than 3 times (7 total) while diagnosing an unrelated UI issue: the on-screen "Played today" counter appeared stuck at 1 after the first few taps. Root cause: `EntitlementDebugPanel`'s button action sets `@State private var lastMessage = "recorded"` on every tap, and since consecutive taps set that State var to the SAME string value, SwiftUI can skip re-rendering the view body (a known `@State`-with-equatable-value optimization) — so the `LabeledContent` showing `puzzlesPlayedToday()` doesn't visually refresh on every tap even though `PersistenceStore.record()` is correctly inserting and saving a new `GameRecord` every single time. Confirmed as display-only, not a data bug, by reading `PersistenceStore.swift`: `record()` unconditionally inserts+saves, `puzzlesPlayedToday()` does a real `fetchCount` COUNT with no dedup. After force-quitting and relaunching (a genuine cold re-render), the count correctly showed 7, matching the true number of records written — proving persistence works correctly. Since `EntitlementDebugPanel` is temporary Phase 2 scaffolding deleted in Phase 3, this UI refresh quirk is not being fixed.

**Full test suite result (run after the manual verification):**

```
xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'
```

32 unit tests: 29 passed, 3 failed (per-suite breakdown below) + 6 UI tests: 6 passed. **Total: 38 tests, 35 passed, 3 failed.**

| Suite | Tests | Result |
|---|---|---|
| WordListTests | 4 | passed |
| PuzzleGeneratorTests | 4 | passed |
| ProfanityTests | 1 | passed |
| PersistenceStoreTests | 8 | passed |
| ScoreCalculatorTests | 5 | passed |
| PerformanceTests | 2 | passed |
| WordPuzzleTests (Xcode template) | 1 | passed |
| AppWiringTests | 2 | passed |
| EntitlementStoreTests | 5 | **3 failed** (`testPurchaseUnlocksPremium`, `testRestoreUnlocksPremiumAfterFreshInstall`, `testClearingTransactionsRevokesPremium` — all `caught error: "notEntitled"`) |
| WordPuzzleUITests + WordPuzzleUITestsLaunchTests | 6 | passed |

The 3 `EntitlementStoreTests` failures are the exact same pre-existing Simulator `SKTestSession` bug already diagnosed in 02-04-SUMMARY.md and tracked in STATE.md Blockers/Concerns (an Xcode 26.6/iOS 26.5 Simulator `storekitd` daemon issue, confirmed not a code defect — read-only StoreKit paths pass, only `buyProduct`/`clearTransactions` write paths fail with `SKInternalErrorDomain Code=3`). They are non-blocking for this plan: the real sandbox purchase/restore just completed on a physical device (items 4-7 above) is the authoritative MON-02/MON-03 proof CONTEXT D-06 requires, and it is independent of the local Simulator daemon issue.

## EntitlementDebugPanel — Temporary Scaffolding, Must Be Deleted in Phase 3

`EntitlementDebugPanel` in `WordPuzzle/WordPuzzle/ContentView.swift` (wrapped in `#if DEBUG`, marked `TEMPORARY — Phase 2 only` in its doc comment) is Phase 2 scaffolding only. It exists solely so the manual sandbox purchase/restore verification (Task 3) had something to tap before the Phase 4 paywall exists. **It MUST be deleted when Phase 3 replaces `ContentView` with the real game screen.** It has a known, intentionally-unfixed UI display quirk (item 8 above) that is not worth patching since the whole panel is disposable.

## Scheme StoreKit Configuration — Current State

Per the plan's Task 3 Step B, Patrick set the scheme's **Run -> Options -> StoreKit Configuration** to **None** before the sandbox test, so the real App Store Connect product would be used instead of the local `WordPuzzle.storekit` simulation file. This was confirmed on disk in this session: `git diff` on `WordPuzzle.xcscheme` showed the `<StoreKitConfigurationFileReference>` block missing from `<LaunchAction>` (Run) while still present, untouched, in `<TestAction>` (Test) — meaning `xcodebuild test`/`SKTestSession` runs were never affected by this change.

**Action taken:** restored the `<StoreKitConfigurationFileReference identifier="../../../WordPuzzle/WordPuzzle.storekit">` block to `<LaunchAction>`, so `Run -> Options -> StoreKit Configuration` is now back to `WordPuzzle.storekit` for normal local dev in Phase 3/4 (fast local iteration without needing a live sandbox account). Verified `git diff` on the scheme file is now empty (matches the last committed state from plan 02-01).

## Decisions Made

- See `key-decisions` in frontmatter: the account-scoped entitlement finding (item 6) and the EntitlementDebugPanel UI-refresh quirk (item 8) are both recorded as non-defect findings worth remembering for Phase 4's paywall design (a real device test after delete+reinstall while still signed into the same sandbox/production Apple ID will show `isPremium=true` before any Restore tap — this is correct and should not be treated as a bug if observed again in Phase 4).
- Reset the scheme's Run StoreKit Configuration back to `WordPuzzle.storekit` (see above) so Phase 3 development is not accidentally pointed at the real App Store Connect sandbox.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `import StoreKit` to ContentView.swift's DEBUG block**
- **Found during:** Task 2 (recorded by the prior continuation agent, carried forward here for completeness)
- **Issue:** The plan's verbatim `EntitlementDebugPanel` code snippet uses `Product.displayPrice` but the plan's file-replacement action block for `ContentView.swift` does not `import StoreKit`, which is required for the `Product` type to resolve.
- **Fix:** Added `#if DEBUG import StoreKit #endif` alongside the existing `import SwiftUI`.
- **Files modified:** `WordPuzzle/WordPuzzle/ContentView.swift`
- **Verification:** `xcodebuild build` succeeds; full test suite passes at that point in the plan.
- **Committed in:** `23811d8` (Task 2 commit)

**2. [Rule 3 - Blocking] Removed a stray auto-generated Xcode test plan**
- **Found during:** Task 2 cleanup
- **Issue:** Opening the project in Xcode during manual verification auto-generated an `.xctestplan` file that was not part of the plan and was not intended to be committed.
- **Fix:** Removed the stray file.
- **Files modified:** (deletion only)
- **Committed in:** `01d2c58` (chore)

**3. [Rule 3 - Blocking] Reset scheme's Run StoreKit Configuration from `None` back to `WordPuzzle.storekit`**
- **Found during:** Task 3 resumption (this session)
- **Issue:** Patrick's manual sandbox test required setting Run -> StoreKit Configuration to `None` (per the plan's own Step B instructions) so the app would hit the real App Store Connect product instead of the local simulation file. Left at `None`, this would silently break local Simulator-based dev/testing in Phase 3, which expects `WordPuzzle.storekit` to be active for fast iteration.
- **Fix:** Restored the `<StoreKitConfigurationFileReference>` block under `<LaunchAction>` in `WordPuzzle.xcscheme`, matching the state committed in plan 02-01. Verified `git diff` on the file is empty (i.e., matches the last-known-good committed state) after the edit.
- **Files modified:** `WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme`
- **Verification:** `git diff --stat` on the scheme file returns nothing (no diff from HEAD); Test Action's StoreKit Configuration (used by `SKTestSession`) was never touched, so no test regression risk.
- **Committed in:** this plan's metadata commit (docs)

---

**Total deviations:** 3 auto-fixed (2 blocking issues carried forward from the prior session's Task 1-2 work, 1 new blocking cleanup in this session — resetting the scheme's Run StoreKit Configuration so Phase 3 local dev is not left pointed at the sandbox).
**Impact on plan:** All three are environment/tooling corrections required for the plan's own stated steps to work end-to-end. No scope creep, no behavior change to app code beyond the already-recorded `import StoreKit` addition.

## Issues Encountered

None beyond what's documented above and in 02-04-SUMMARY.md (the pre-existing Simulator `SKTestSession` bug, which this plan's real sandbox test was specifically designed to route around per CONTEXT D-06).

## User Setup Required

None further. Patrick has already: created a sandbox tester account, completed the App Store Connect setup (02-01), and completed the on-device sandbox purchase/restore test (this plan). No further manual environment steps are required for Phase 2.

## Next Phase Readiness

- Phase 3 can build the game UI against `@Environment(PersistenceStore.self)` and `@Environment(EntitlementStore.self)` with no further wiring — both services are constructed once and injected at the app root.
- Phase 3 MUST delete `EntitlementDebugPanel` from `ContentView.swift` when it replaces `ContentView` with the real game screen (see "EntitlementDebugPanel" section above).
- All five ROADMAP Phase 2 success criteria are now demonstrably satisfied: (1) `puzzlesPlayedToday()` persists across restarts — proven both by `PersistenceStoreTests` and by the on-device 7/7 result in item 8 above; (2) streak logic — proven by `ScoreCalculatorTests`/`PersistenceStoreTests` (02-03); (3) lifetime stats accumulate correctly — proven by `PersistenceStoreTests` (02-02); (4) `isPremium` reads `Transaction.currentEntitlements` and is correct after a real purchase and a real restore — proven on-device in this plan; (5) sandbox IAP product exists in App Store Connect before any StoreKit code was written — proven in 02-01.
- All five Phase 2 requirements (MON-02, MON-03, MON-04, RET-01, RET-02) are covered by named passing tests and/or the recorded manual verification above.
- Known non-blocking issue carried forward (not this plan's to fix): 3/5 `EntitlementStoreTests` remain red in this Mac's Simulator due to an unresolved Xcode 26.6/iOS 26.5 `SKTestSession` daemon bug (see 02-04-SUMMARY.md). Does not block Phase 3 or Phase 4 — the real sandbox test in this plan is the authoritative proof, and a future Xcode update may resolve it (`xcodebuild test -only-testing:WordPuzzleTests/EntitlementStoreTests` to re-check).

## Self-Check

- `test -f WordPuzzle/WordPuzzle/WordPuzzleApp.swift` → FOUND
- `test -f WordPuzzle/WordPuzzle/ContentView.swift` → FOUND
- `test -f WordPuzzle/WordPuzzleTests/AppWiringTests.swift` → FOUND
- `grep -q "EntitlementDebugPanel" WordPuzzle/WordPuzzle/ContentView.swift` → FOUND
- `grep -q "TEMPORARY — Phase 2 only" WordPuzzle/WordPuzzle/ContentView.swift` → FOUND
- Commit `82f6dda` → FOUND
- Commit `23811d8` → FOUND
- Commit `01d2c58` → FOUND
- `git diff --stat WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme` → empty (scheme restored to committed state)
- Full test suite → 35/38 passed, 3 pre-existing/documented failures (EntitlementStoreTests Simulator issue)

## Self-Check: PASSED

---
*Phase: 02-persistence-entitlements*
*Completed: 2026-08-29*
