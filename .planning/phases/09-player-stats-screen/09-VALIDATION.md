---
phase: 9
slug: player-stats-screen
status: draft
nyquist_compliant: false
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
| 9-xx-xx | — | — | P9-A | unit | `-only-testing:WordPuzzleTests/PersistenceStatsTests` | ❌ W0 | ⬜ pending |
| 9-xx-xx | — | — | P9-A | unit | `-only-testing:WordPuzzleTests/StatsMigrationTests` | ❌ W0 | ⬜ pending |
| 9-xx-xx | — | — | P9-A | unit | `-only-testing:WordPuzzleTests/GameViewModelTests` | ✅ extend | ⬜ pending |
| 9-xx-xx | — | — | P9-B | unit | `-only-testing:WordPuzzleTests/PersistenceStatsTests` | ❌ W0 | ⬜ pending |
| 9-xx-xx | — | — | P9-C | unit | `-only-testing:WordPuzzleTests/StatsViewTests` | ❌ W0 | ⬜ pending |
| 9-xx-xx | — | — | P9-D | unit | `-only-testing:WordPuzzleTests/SettingsViewTests` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/PersistenceStatsTests.swift` — new store methods (longest streak, averages, best rank, totals, at-risk helper, record() new fields)
- [ ] `WordPuzzleTests/StatsMigrationTests.swift` — legacy-schema store opens under new schema (spike nested VersionedSchema technique first; fallback: committed sqlite fixture)
- [ ] `WordPuzzleTests/StatsViewTests.swift` — copy constants + pure presentation functions
- [ ] Extend `GameViewModelTests` (finishRound writes rank/pangrams/sweep) and `SettingsViewTests` (stats row label/accessibility)

Framework install: none.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stats sheet presents over round-over fullScreenCover; icon visible | P9-D | Presentation stacking; simulator gear icon rendering unreliable | Finish a round on device, tap stats entry on MissedWordsView, confirm sheet appears and dismisses back to cover |
| Count-up honors Reduce Motion; Mythic glow steady | P9-E | Visual/animation | Toggle Reduce Motion in simulator/device; open stats; confirm no roll animation |
| AX5 layout (1 column, shrink-to-fit) | P9-E | Simulator width misleading (STATE) | iPhone 15 Pro at AX5 text size; open stats; confirm no truncation/overlap |
| Existing-install upgrade keeps history | P9-A | Real store migration | Note games played, install over via `scripts/install-on-device.sh`, confirm totals unchanged |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
