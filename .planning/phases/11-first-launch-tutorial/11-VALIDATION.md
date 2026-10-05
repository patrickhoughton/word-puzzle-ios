---
phase: 11
slug: first-launch-tutorial
status: draft
nyquist_compliant: true
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
| 11-01-T1 | 11-01 | 1 | TUT-03 | unit | `-only-testing:WordPuzzleTests/TutorialLaunchGateTests -only-testing:WordPuzzleTests/PersistenceStoreTests` | ❌ W0 (created in task, TDD) / ✅ extend | ⬜ pending |
| 11-01-T2 | 11-01 | 1 | TUT-07 | build | grep for `"-hasSeenTutorial", "YES"` (>= 5) + `xcodebuild build-for-testing` | ✅ edit | ⬜ pending |
| 11-02-T1 | 11-02 | 1 | TUT-01 | unit | `-only-testing:WordPuzzleTests/PracticePuzzleTests` | ❌ W0 (created in task, TDD) | ⬜ pending |
| 11-02-T2 | 11-02 | 1 | TUT-01, TUT-06 | unit | `-only-testing:WordPuzzleTests/TutorialCopyTests` | ❌ W0 (created in task, TDD) | ⬜ pending |
| 11-03-T1 | 11-03 | 1 | TUT-06 | build + guard | `xcodebuild build` + `bash scripts/compliance-guards.sh` | n/a | ⬜ pending |
| 11-03-T2 | 11-03 | 1 | TUT-06 | unit | `-only-testing:WordPuzzleTests/TutorialBannerViewTests` | ❌ W0 (created in task, TDD) | ⬜ pending |
| 11-03-T3 | 11-03 | 1 | TUT-05 | unit | `-only-testing:WordPuzzleTests/SettingsViewTests` | ✅ extend | ⬜ pending |
| 11-04-T1 | 11-04 | 2 | TUT-01 | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | ❌ W0 (created in task, TDD) | ⬜ pending |
| 11-04-T2 | 11-04 | 2 | TUT-02, TUT-04, TUT-05 | unit | `-only-testing:WordPuzzleTests/TutorialControllerTests` | ✅ (from T1) | ⬜ pending |
| 11-05-T1 | 11-05 | 3 | TUT-03, TUT-04 | grep | grep `shouldShowOnLaunch(hasHistory:` / `.environment(tutorial.practice)` (build in T2) | n/a | ⬜ pending |
| 11-05-T2 | 11-05 | 3 | TUT-01..06 | unit + guard | `-only-testing:WordPuzzleTests` + `bash scripts/compliance-guards.sh` | ✅ | ⬜ pending |
| 11-06-T1 | 11-06 | 4 | TUT-01..05, TUT-07 | UI | `-only-testing:WordPuzzleUITests/TutorialUITests` (after `simctl uninstall`) + existing UI suites + screenshot test | ❌ W0 (created in task) | ⬜ pending |
| 11-06-T2 | 11-06 | 4 | TUT-06 | screenshot | `simctl` AX5 screenshots on iPhone 17e (light + dark), reviewed | n/a | ⬜ pending |
| 11-06-T3 | 11-06 | 4 | TUT-01..06 | manual | on-device checkpoint (Wi-Fi install) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Test files are created test-first inside the task that needs them (TDD tasks), so no separate Wave 0 plan:
- [ ] `WordPuzzleTests/TutorialLaunchGateTests.swift` — 11-01 Task 1
- [ ] `WordPuzzleTests/PracticePuzzleTests.swift` — 11-02 Task 1
- [ ] `WordPuzzleTests/TutorialCopyTests.swift` — 11-02 Task 2
- [ ] `WordPuzzleTests/TutorialBannerViewTests.swift` — 11-03 Task 2
- [ ] `WordPuzzleTests/TutorialControllerTests.swift` — 11-04 Task 1/2
- [ ] `WordPuzzleUITests/TutorialUITests.swift` — 11-06 Task 1
- [ ] `-hasSeenTutorial YES` on all 5 existing UI-test launches (incl. `WordPuzzleUITestsLaunchTests.swift`) — 11-01 Task 2

*Framework install: none needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AX5 banner layout on smallest screen | TUT-06 | Visual fit judgment; no iPhone SE simulator | Automated capture in 11-06 Task 2 (`simctl ui content_size accessibility-extra-extra-extra-large` on iPhone 17e, light + dark), screenshots reviewed by the executor |
| Reduce Motion pulse | TUT-06 | Visual | Enable Reduce Motion; highlight uses static/0.5 pulse |
| VoiceOver step announcements + Skip reachability | TUT-06 | Assistive tech behavior | Enable VoiceOver; each step announced; Skip reachable |
| Full tutorial on device (Wi-Fi install) | TUT-01..05 | Feel / gesture fidelity | `bash scripts/install-on-device.sh`, then Settings > How to Play (do NOT delete the app; it holds real history). 11-06 Task 3 checkpoint |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
