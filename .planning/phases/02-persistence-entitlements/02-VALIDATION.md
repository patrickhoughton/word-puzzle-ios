---
phase: 2
slug: persistence-entitlements
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-28
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Split: Swift Testing (`@Test`, `#expect`) for `PersistenceStoreTests.swift`; XCTest (`XCTestCase`) for `EntitlementStoreTests.swift` — StoreKitTest's `SKTestSession` has no verified Swift Testing interop |
| **Config file** | none — runs via the existing `WordPuzzleTests` target in `WordPuzzle/WordPuzzle.xcodeproj` |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/PersistenceStoreTests` (or `EntitlementStoreTests` for the StoreKit side) |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |
| **Estimated runtime** | ~60-90 seconds (adds to existing Phase 1 suite: WordListTests, PuzzleGeneratorTests, PerformanceTests) |

---

## Sampling Rate

- **After every task commit:** Run the specific new test file (`-only-testing:WordPuzzleTests/PersistenceStoreTests` or `EntitlementStoreTests`)
- **After every plan wave:** Run the full suite command (regression check against Phase 1 tests)
- **Before `/gsd:verify-work`:** Full suite must be green, plus the manual sandbox purchase/restore test confirmed
- **Max feedback latency:** ~90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-0X-0X | TBD | TBD | RET-01 | unit | `...-only-testing:WordPuzzleTests/PersistenceStoreTests/testStreakIncrementsOnConsecutiveDays` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | RET-01 | unit | `...-only-testing:WordPuzzleTests/PersistenceStoreTests/testStreakResetsAfterMissedDay` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | RET-02 | unit | `...-only-testing:WordPuzzleTests/PersistenceStoreTests/testLifetimeStatsAccumulate` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | RET-02 / SC-1 | integration | `...-only-testing:WordPuzzleTests/PersistenceStoreTests/testPuzzlesPlayedTodayPersistsAcrossRestart` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | MON-04 / SC-4 | integration | `...-only-testing:WordPuzzleTests/EntitlementStoreTests/testPurchaseUnlocksPremium` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | MON-03 / MON-04 / SC-4 | integration | `...-only-testing:WordPuzzleTests/EntitlementStoreTests/testRestoreUnlocksPremiumAfterFreshInstall` | ❌ W0 | ⬜ pending |
| 02-0X-0X | TBD | TBD | SC-5 | manual-only | N/A — App Store Connect is a web UI, not automatable | ❌ W0 (process task) | ⬜ pending |

*Plan/wave/task IDs to be filled in by gsd-planner when PLAN.md files are created.*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — stubs for RET-01, RET-02, SC-1 (in-memory `ModelContainer`, Swift Testing `@Suite`)
- [ ] `WordPuzzleTests/EntitlementStoreTests.swift` — stubs for MON-03, MON-04, SC-4 (XCTest `XCTestCase`, `SKTestSession`)
- [ ] `WordPuzzle/WordPuzzle.storekit` — StoreKit Configuration File; must exist before `EntitlementStoreTests.swift` can run at all
- [ ] `WordPuzzle/WordPuzzle/Services/GameRecord.swift`, `PersistenceStore.swift`, `EntitlementStore.swift` — no existing `Services/` group; net-new
- [ ] App Store Connect: Paid Applications Agreement acceptance + IAP product `com.patrickhoughton.wordpuzzle.unlimited` created — prerequisite to all of the above; process gap, not a code artifact

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|--------------------|
| Sandbox IAP product created and attached in App Store Connect | SC-5 | App Store Connect is a web UI, not automatable from this codebase | Complete first-timer walkthrough in the Phase 2 plan: accept Paid Applications Agreement, create app record, create non-consumable IAP product `com.patrickhoughton.wordpuzzle.unlimited`; confirm product appears as "Ready to Submit" in App Store Connect before writing StoreKit code |
| Manual sandbox purchase/restore test (real Apple ID, physical device) | MON-03, MON-04, D-06 | StoreKitTest automated tests simulate purchases locally; a real sandbox account exercises the actual App Store Connect product end-to-end, which automated tests cannot | Before marking Phase 2 complete: sign in with a sandbox Apple ID on a device/simulator, purchase the IAP, confirm `isPremium` becomes true; delete and reinstall app, tap Restore Purchases, confirm `isPremium` becomes true again |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
