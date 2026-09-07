---
phase: 5
slug: polish-compliance-app-store
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-09-07
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`/`@Suite`), matching all existing test files in `WordPuzzleTests/` |
| **Config file** | none — test target configured directly in `project.pbxproj`/scheme |
| **Quick run command** | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios && xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/<SuiteName> 2>&1 | tail -30` |
| **Full suite command** | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios && xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 | tail -30` |
| **Estimated runtime** | ~60-120 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run the relevant quick-run test suite (e.g. `SoundManagerTests` after SoundManager work) plus grep-based regression guards (no `Font.system(size:` outside `HexTileView`'s clamp code; no `URLSession`/`URLRequest` anywhere in `WordPuzzle/WordPuzzle`).
- **After every plan wave:** Full `xcodebuild test` suite green.
- **Before `/gsd:verify-work`:** Full suite green, plus the manual verification checklist below (Airplane Mode device test, AX5 Dynamic Type visual pass on every screen, silent-switch SFX behavior, App Store Connect privacy questionnaire, icon/screenshots uploaded).
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-XX | 01 | 0/1 | UX-02 | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/SoundManagerTests` | ❌ Wave 0 | ⬜ pending |
| 05-02-XX | 02 | 1 | UX-03 | grep guard | `grep -c "Font.system(size:" GameTheme.swift` (expect 0 outside clamp code) | ❌ Wave 0 | ⬜ pending |
| 05-03-XX | 03 | 1 | UX-01 | grep guard | `grep -rn "URLSession\|URLRequest" WordPuzzle/WordPuzzle` (expect no matches) | ❌ Wave 0 | ⬜ pending |
| 05-04-XX | 04 | 1 | UX-05 | grep guard | `grep -n "ITSAppUsesNonExemptEncryption" WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` (expect `NO`) | ❌ Wave 0 | ⬜ pending |
| 05-05-XX | 05 | manual | UX-04 | manual | App Store Connect upload validates icon/screenshot format & size automatically | — | ⬜ pending |

*Exact task IDs assigned by the planner; this table is the requirement→verification mapping the planner must instantiate.*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/SoundManagerTests.swift` — new suite covering the `@AppStorage`-gated `enabled` logic (assert `play()` is a no-op when disabled via an injectable "did attempt to play" seam; do not assert actual audio output)
- [ ] Grep-based regression guard scripts (can be inline shell steps in task `<automated>` verify, not separate files) for:
  - No `Font.system(size:` outside `HexTileView`'s clamp code
  - No `URLSession`/`URLRequest` anywhere in `WordPuzzle/WordPuzzle`
  - `ITSAppUsesNonExemptEncryption` present and set to `NO` in `project.pbxproj`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All game features work in Airplane Mode | UX-01 | Runtime network behavior isn't reliably assertable via Swift Testing; StoreKit's local entitlement cache requires a prior sync before offline testing is valid | Launch app once online (let StoreKit sync entitlements), enable Airplane Mode, exercise puzzle generation, word entry, scoring, paywall, and restore-purchases flows — confirm no silent failures or crashes |
| Text scales correctly at largest Dynamic Type size | UX-03 | SwiftUI's declarative view hierarchy is not introspectable for rendered font sizes via Swift Testing | iOS Settings > Accessibility > Larger Text, max (AX5) setting; visually inspect every screen (game, settings, paywall, missed words) for clipping/overflow, especially hex tile letters |
| Sound toggle audibly mutes/plays SFX | UX-02 | Audio output isn't assertable via unit test | Toggle setting on/off, trigger each of the 4 SFX events (word accepted, word rejected, pangram, round end/paywall), confirm audible behavior matches toggle state |
| App icon + screenshots correctly sized and uploaded | UX-04 | App Store Connect performs its own upload-time format/size validation | Upload 1024x1024 icon (all 3 appearance slots) and ≥3 captioned screenshots to App Store Connect; confirm no format rejection |
| Privacy label reflects zero data collection | UX-05 | App Store Connect questionnaire is a web form, not testable via code | Complete App Store Connect privacy questionnaire declaring "Data Not Collected" across all categories; confirm submission accepted |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
