---
phase: 11
slug: first-launch-tutorial
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-04
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`WordPuzzleTests`) + XCTest/XCUITest (`WordPuzzleUITests`) |
| **Config file** | Scheme `WordPuzzle` (`WordPuzzle/WordPuzzle.xcodeproj/xcshareddata/xcschemes/WordPuzzle.xcscheme`); no test plan |
| **Quick run command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests -quiet` |
| **Full suite command** | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet && bash scripts/compliance-guards.sh` |
| **Estimated runtime** | ~120 seconds (unit), ~360 seconds (full incl. UI) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (targeting new suites + `SettingsViewTests`, `PersistenceStoreTests` where relevant)
- **After every plan wave:** Run full `-only-testing:WordPuzzleTests` + `bash scripts/compliance-guards.sh`
- **Before `/gsd:verify-work`:** Full suite (incl. UI tests) must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| TBD (filled by planner) | — | — | TUT-01 | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | ❌ W0 | ⬜ pending |
| TBD | — | — | TUT-01 | unit | `-only-testing:WordPuzzleTests/PracticePuzzleTests` | ❌ W0 | ⬜ pending |
| TBD | — | — | TUT-02 | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | ❌ W0 | ⬜ pending |
| TBD | — | — | TUT-03 | unit | `-only-testing:WordPuzzleTests/TutorialLaunchGateTests` | ❌ W0 | ⬜ pending |
| TBD | — | — | TUT-03 | unit | `-only-testing:WordPuzzleTests/PersistenceStoreTests` | ✅ extend | ⬜ pending |
| TBD | — | — | TUT-04/05 | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | ❌ W0 | ⬜ pending |
| TBD | — | — | TUT-05 | unit | `-only-testing:WordPuzzleTests/SettingsViewTests` | ✅ extend | ⬜ pending |
| TBD | — | — | TUT-06 | unit | `TutorialControllerTests` / `DynamicTypeTests` | ✅ extend | ⬜ pending |
| TBD | — | — | TUT-07 | UI | `-only-testing:WordPuzzleUITests` (existing suites with `-hasSeenTutorial YES`) | ✅ edit | ⬜ pending |
| TBD | — | — | TUT-01..05 | UI | `-only-testing:WordPuzzleUITests/TutorialUITests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/TutorialControllerTests.swift` — state machine, gating, free/unrecorded guarantees
- [ ] `WordPuzzleTests/PracticePuzzleTests.swift` — curated puzzle validity against bundled list
- [ ] `WordPuzzleTests/TutorialLaunchGateTests.swift` — tri-state flag + history probe, isolated `UserDefaults(suiteName:)`
- [ ] `WordPuzzleUITests/TutorialUITests.swift` — end-to-end tutorial, skip, replay (launch `-hasSeenTutorial NO`)
- [ ] Add `-hasSeenTutorial YES` to `WordPuzzleUITests.swift` (2 launches), `StatsPresentationUITests.swift`, `AppStoreScreenshotTests.swift`; check `WordPuzzleUITestsLaunchTests.swift`

*Framework install: none needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AX5 banner layout on smallest screen | TUT-06 | Visual fit judgment; no iPhone SE simulator | Run on iPhone 17e simulator at AX5; banner + Skip readable, board not obscured |
| Reduce Motion pulse | TUT-06 | Visual | Enable Reduce Motion; highlight uses static/0.5 pulse |
| VoiceOver step announcements + Skip reachability | TUT-06 | Assistive tech behavior | Enable VoiceOver; each step announced; Skip reachable |
| Full tutorial on device (Wi-Fi install) + dark mode | TUT-01..05 | Feel / gesture fidelity | `bash scripts/install-on-device.sh`; delete app first for fresh install |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
