---
phase: 9
slug: player-stats-screen
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-10-04
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`import Testing`, `@Test`, `#expect`); XCUITest target `WordPuzzleUITests` exists but is a screenshot harness |
| **Config file** | `WordPuzzle/WordPuzzle.xcodeproj`, shared scheme `WordPuzzle` |
| **Quick run command** | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/<Suite>` |
| **Full suite command** | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests` |
| **Estimated runtime** | ~120 seconds (full unit suite, incl. build) |

---

## Sampling Rate

- **After every task commit:** Run quick command on the touched suite
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green (plus `scripts/compliance-guards.sh` if part of the project gate)
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

Filled by planner/executor as tasks are defined. Requirement IDs P9-A..P9-E are derived in 09-RESEARCH.md.

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 9-01-01 | 01 | 1 | P9-A | unit (migration spike) | `-only-testing:WordPuzzleTests/StatsMigrationTests` | created in task | ⬜ pending |
| 9-01-02 | 01 | 1 | P9-A | unit | `-only-testing:WordPuzzleTests/StatsMigrationTests -only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ (01-01) | ⬜ pending |
| 9-01-03 | 01 | 1 | P9-A | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` | ✅ extend | ⬜ pending |
| 9-02-01 | 02 | 1 | P9-C, P9-E | unit | `-only-testing:WordPuzzleTests/StatsViewTests -only-testing:WordPuzzleTests/ScoreBarViewTests` | created in task | ⬜ pending |
| 9-02-02 | 02 | 1 | P9-C, P9-E | unit + build | `-only-testing:WordPuzzleTests/StatsViewTests -only-testing:WordPuzzleTests/DynamicTypeTests` | ✅ (02-01) | ⬜ pending |
| 9-03-01 | 03 | 2 | P9-B | unit | `-only-testing:WordPuzzleTests/PersistenceStatsTests` | created in task | ⬜ pending |
| 9-03-02 | 03 | 2 | P9-B | unit | `-only-testing:WordPuzzleTests/PersistenceStatsTests` | ✅ (03-01) | ⬜ pending |
| 9-04-01 | 04 | 2 | P9-D | unit | `-only-testing:WordPuzzleTests/SettingsViewTests` | ✅ extend | ⬜ pending |
| 9-04-02 | 04 | 2 | P9-D | unit | `-only-testing:WordPuzzleTests/MissedWordsViewTests` | created in task | ⬜ pending |
| 9-05-01 | 05 | 3 | P9-D | full unit suite | `-only-testing:WordPuzzleTests` | ✅ | ⬜ pending |
| 9-05-02 | 05 | 3 | P9-D, P9-E | XCUITest (fresh install) | `-only-testing:WordPuzzleUITests/StatsPresentationUITests` | created in task | ⬜ pending |
| 9-06-01 | 06 | 4 | P9-A | device store diff (sqlite3 before/after) | `compliance-guards.sh` + devicectl copy + sqlite3 | n/a | ⬜ pending |
| 9-06-02 | 06 | 4 | P9-D, P9-E | manual (device) | Manual-only | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/PersistenceStatsTests.swift` — new store methods (longest streak, averages, best rank, totals, at-risk helper); record() new-field tests live in StatsMigrationTests (plan 09-01)
- [ ] `WordPuzzleTests/StatsMigrationTests.swift` — legacy-schema store opens under new schema (spike nested VersionedSchema technique first; fallback: committed sqlite fixture)
- [ ] `WordPuzzleTests/StatsViewTests.swift` — copy constants + pure presentation functions
- [ ] Extend `GameViewModelTests` (finishRound writes rank/pangrams/sweep) and `SettingsViewTests` (stats row label/accessibility)

Framework install: none.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stats sheet presents over round-over fullScreenCover; icon visible | P9-D | Automated in Simulator by StatsPresentationUITests (09-05); device re-check because simulator icon rendering is unreliable | Finish a round on device, tap stats entry on MissedWordsView, confirm sheet appears and dismisses back to cover |
| Count-up honors Reduce Motion; Mythic glow steady | P9-E | Visual/animation | Toggle Reduce Motion in simulator/device; open stats; confirm no roll animation |
| AX5 layout (1 column, shrink-to-fit) | P9-E | Simulator width misleading (STATE) | iPhone 15 Pro at AX5 text size; open stats; confirm no truncation/overlap |
| Existing-install upgrade keeps history | P9-A | Real store migration (now automated in 09-06 Task 1 via devicectl store copy + sqlite3 diff) | Copy store off device, install over via `scripts/install-on-device.sh`, copy again, compare row count / max score / word sum |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
