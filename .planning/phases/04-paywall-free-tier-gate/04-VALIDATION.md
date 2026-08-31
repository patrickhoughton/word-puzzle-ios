---
phase: 4
slug: paywall-free-tier-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-31
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Suite`/`@Test`/`#expect`) |
| **Config file** | none — standard Xcode test target (`WordPuzzleTests`) |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/PersistenceStoreTests -only-testing:WordPuzzleTests/GameViewModelTests` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |
| **Estimated runtime** | ~60-90 seconds (quick), ~3-4 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (`PersistenceStoreTests` + `GameViewModelTests`)
- **After every plan wave:** Run the full suite command
- **Before `/gsd:verify-work`:** Full suite must be green, PLUS both manual QA scripts (paywall-after-3rd-puzzle, restore-on-reinstall) executed and recorded
- **Max feedback latency:** ~90 seconds for the per-task quick run; the per-wave full-suite gate is expected to take ~3-4 minutes (see Full suite command estimate above) and is an accepted exception to the 90s budget since it only runs once per wave, not per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-xx | 01 | 0 | MON-01 | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ (extend, update 3 existing tests) | ⬜ pending |
| 04-01-xx | 01 | 0/1 | MON-01, D-07 | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ (extend existing file) | ⬜ pending |
| 04-02-xx | 02 | 1 | MON-01, D-02 | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` | ✅ (extend existing file) | ⬜ pending |
| 04-03-xx | 03 | 1/2 | MON-01 | manual | N/A — StoreKit sandbox + relaunch | ❌ Wave 0 manual QA script | ⬜ pending |
| 04-03-xx | 03 | 1/2 | MON-01 | manual | N/A — requires real sandbox Apple ID | ❌ Wave 0 manual QA script | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — update `testPuzzlesPlayedTodayCountsTodaysSessions`, `testPuzzlesPlayedTodayExcludesEarlierDays`, `testPuzzlesPlayedTodayPersistsAcrossRestart` to call `recordRoundStarted()` (not just `record()`) — the semantics of `puzzlesPlayedToday()` change from counting `GameRecord` to counting `RoundStartRecord`
- [ ] `WordPuzzleTests/PersistenceStoreTests.swift` — new test cases for `todayTotalScore()`, `todayTotalWordsFound()`, `recordRoundStarted()`
- [ ] `WordPuzzleTests/GameViewModelTests.swift` — new test cases for `requestNextRound(isPremium:)` (both branches: blocked at limit vs. premium bypass) and `startNewRound(with:)`'s new `recordRoundStarted()` side effect
- [ ] Manual QA script (not a Wave 0 file, must exist before phase gate): play 3 puzzles (including one abandoned), see paywall, verify live countdown, sandbox-purchase, verify persists across restart, reinstall + Restore Purchases

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Paywall appears exactly after the 3rd puzzle's MissedWordsView, not before, not after a restart | MON-01 | Cross-launch state + real app lifecycle; not automatable without UI test infra this project doesn't have | Play 3 rounds (mix of finished and one abandoned via backgrounding), confirm paywall shows on the would-be 4th round and again on relaunch; confirm countdown ticks live and matches local midnight |
| Restore Purchases restores premium status on a device with a prior sandbox purchase | MON-01, success criterion 4 | Requires a real sandbox Apple ID and StoreKit sandbox environment | Purchase unlimited via sandbox account, delete/reinstall app (or reset entitlements), tap Restore Purchases, confirm premium status returns without re-purchase — mirrors Phase 02-05's manual sandbox test |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
