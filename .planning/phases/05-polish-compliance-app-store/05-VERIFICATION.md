---
phase: 05-polish-compliance-app-store
verified: 2026-10-05T23:59:00Z
status: human_needed
score: 5/5 requirements verified (automated); App Review outcome pending
human_verification:
  - test: "Apple App Review decision on v1.0 build 2 + IAP"
    expected: "Approved on first submission (the phase goal's 'passes App Review on first submission')"
    why_human: "Submission is WAITING_FOR_REVIEW (release MANUAL). Outcome cannot be known yet. Not a gap."
  - test: "Re-run AX5 Dynamic Type on screens added in Phases 6-12 (found words, stats, tutorial, spin/ring UI, overflow/pangram bonus UI) on a physical iPhone"
    expected: "No clipping or truncation at AX5"
    why_human: "05-06 QA predates these screens. Phases 7, 9, 11 did AX5 checks on their own screens, but 11-06 SUMMARY records that on iPhone 17e at AX5 the game score card clips at top and Finish Round clips at bottom (logged as a future accessibility pass). Phase 12 and the Phase 8 bonus UI have no AX5 re-check recorded. Build 2 ships these."
  - test: "Airplane Mode pass on the shipped build 2 (Phases 6-12 features)"
    expected: "Full gameplay incl. tutorial, stats, found words works offline"
    why_human: "05-06 offline QA predates Phases 6-12. Source-level guard still passes (no networking APIs), so risk is low. Paywall-offline (price, Restore) was never exercised on-device (device holds an entitlement)."
  - test: "Settings gear on iPad and Mac/Vision Pro availability"
    expected: "Gear visible on a real iPad; ASC Mac/Vision Pro availability unchecked"
    why_human: "iPad gear only checked on Simulator (quirk assumed). Availability is recorded as unchecked by Patrick via UI, not API-verified here."
---

# Phase 5: Polish, Compliance and App Store Verification Report

**Phase Goal:** The app passes App Review on first submission: fully offline, supports Dynamic Type, has a completed privacy label, and has App Store metadata (icon, screenshots, keywords) that accurately represents the product.
**Verified:** 2026-10-05
**Status:** human_needed
**Re-verification:** No, initial verification

## Observable Truths (from the 8 PLANs' must_haves and requirements)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | UX-01 Fully offline | VERIFIED | `scripts/compliance-guards.sh` Guard 1 PASS (no URLSession/URLRequest/NWPathMonitor etc.). Airplane Mode gameplay QA on iPhone 15 Pro passed (05-06). Predates Phases 6-12 (see human items). |
| 2 | UX-02 Sound toggle in Settings, persisted, mute-switch respected | VERIFIED | `Settings/SettingsView.swift` has `Toggle` bound to `soundEffectsEnabled`; `GameView.swift` presents it (line ~158) and stores via `@AppStorage(SoundManager.soundEffectsEnabledKey)`. 10 bundled .wav files in `Sounds/`. Device QA: all events audible on, silent off, persists across restart, silenced by mute switch. |
| 3 | UX-03 Dynamic Type | VERIFIED (with caveat) | Guard 4 PASS (`Font.system(size:)` only in HexTileView, clamped). AX5 device QA passed for Game, Settings, MissedWords, Paywall after fix 8ee88d6. Later phases added screens; see human items. |
| 4 | UX-04 Custom icon + screenshots | VERIFIED | 3 AppIcon PNGs (universal, dark, tinted) present in `AppIcon.appiconset`; build 2 has an `iconAssetToken` in ASC. Listing doc and 05-08 SUMMARY record 4 screenshots per device (iPhone 6.9" and iPad sets, all COMPLETE) plus IAP review screenshot. Keywords (97 chars) and description pushed. |
| 5 | UX-05 Privacy label / no personal data / export compliance | VERIFIED | App Privacy "Data Not Collected" completed by Patrick in the UI (submission accepted, which requires it). ASC read-back: build 2 `usesNonExemptEncryption: false`, Guard 2 PASS (Info.plist key set). Privacy policy and support URLs set. |
| 6 | Submitted to review, MANUAL release | VERIFIED | ASC read-back: version 1.0 `appStoreState: WAITING_FOR_REVIEW`, `releaseType: MANUAL`, build 2 `processingState: VALID`, minOs 17.6. IAP also WAITING_FOR_REVIEW per orchestrator context. |
| 7 | Passes App Review on first submission | UNCERTAIN | Pending Apple's decision. Recorded as human verification, not a gap. |

**Score:** 5/5 requirement-level truths verified; truth 7 pending.

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| UX-01 | 05-04, 05-06 | SATISFIED | Guard 1, Airplane Mode QA |
| UX-02 | 05-01, 05-05, 05-06 | SATISFIED | SoundManager, SettingsView, device QA |
| UX-03 | 05-02, 05-05, 05-06 | SATISFIED (re-check advised for Phases 6-12 UI) | Guard 4, AX5 QA |
| UX-04 | 05-03, 05-06, 05-07, 05-08 | SATISFIED | Icon assets, screenshots in ASC, iPad layout QA |
| UX-05 | 05-04, 05-08 | SATISFIED | Export key, privacy label, ASC read-back |

All five IDs (UX-01..05) appear in PLAN frontmatter and are marked complete in REQUIREMENTS.md. No orphaned requirements; 05-01 through 05-08 all map to IDs listed above.

## Behavioral Spot-Checks

| Check | Command | Result |
|-------|---------|--------|
| Compliance guards | `bash scripts/compliance-guards.sh` | All 4 guards PASS |
| ASC version state | `get /v1/apps/6806385553/appStoreVersions?include=build` | WAITING_FOR_REVIEW, MANUAL, build 2 VALID, no non-exempt encryption |

Unit tests not run (optional).

## Anti-Patterns

None found in Phase 5 artifacts. Noted warning: TARGETED_DEVICE_FAMILY is "1,2" (iPad included by recorded decision, guard 3), so iPad review risk exists; iPad layout was only Simulator-checked and is sparse but functional.

## Gaps Summary

No gaps. Phase 5 deliverables exist, are wired, and the app is submitted. Remaining items are human verification: Apple's decision, and AX5/offline re-checks of UI added after 05-06 (notably the iPhone 17e AX5 clipping of the score card and Finish Round noted in 11-06 SUMMARY). Privacy label and Mac/Vision Pro availability were set via UI and are confirmed here only through submission acceptance and recorded notes (not independently API-readable here).

_Verified: 2026-10-05_
_Verifier: Claude (gsd-verifier)_
