---
phase: 05-polish-compliance-app-store
plan: 08
subsystem: app-store
tags: [app-store-connect, screenshots, iap, privacy-label, submission, xcodebuild]

# Dependency graph
requires:
  - phase: 05-04
    provides: ITSAppUsesNonExemptEncryption = NO, device-family-keep-ipad, compliance guards
  - phase: 05-07
    provides: Automated screenshot capture pipeline (AppStoreScreenshotTests + compositor)
  - phase: 06-12
    provides: Features shipped into v1.0 before submission (rejection messaging, found words, bonuses, stats, double-tap shuffle, tutorial, flick-to-spin)
provides:
  - v1.0 (build 2) + Unlimited Puzzles IAP submitted for App Review (WAITING_FOR_REVIEW, Manual Release)
  - 05-08-APP-STORE-LISTING.md recording every live listing value, API read-backs and ASC lessons
  - Four-shot screenshot sets (iPhone 6.9" + iPad 13") including the Phase 7 found-words sheet
  - scripts/asc_upload_assets.py (screenshot set / IAP review screenshot reserve-upload-commit)
affects: [v1.0 release, 999.9 word-list review]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "App Store Connect writes via scripts/appstoreconnect.py (PATCH) and scripts/asc_upload_assets.py (asset uploads), payloads checked against Apple's OpenAPI spec, every write read back with a GET"
    - "Build upload: xcodebuild archive + -exportArchive (method app-store-connect, destination upload) with -allowProvisioningUpdates and the API key flags"

key-files:
  created:
    - scripts/asc_upload_assets.py
    - Marketing/screenshots/final/02-found-words.png
    - Marketing/screenshots/final/ipad/02-found-words.png
    - .planning/phases/05-polish-compliance-app-store/05-08-APP-STORE-LISTING.md
  modified:
    - WordPuzzle/WordPuzzleUITests/AppStoreScreenshotTests.swift
    - scripts/capture-app-store-screenshots.sh
    - Marketing/screenshots/README.md
    - WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj

key-decisions:
  - "Fourth screenshot (found-words sheet) added; shots renamed 01-gameplay/02-found-words/03-round-end/04-paywall; IAP review shot is raw/04-paywall.png"
  - "Build number bumped to 1.0 (2) because build 1 was already VALID in App Store Connect"
  - "Content Rights answered Yes (third-party content, rights held) because the ENABLE word list is public domain"
  - "App price set to Free (USD base); the $2.99 lives on the non-consumable IAP"

patterns-established:
  - "First IAP must be explicitly added to the same draft review submission as the version"

requirements-completed: [UX-04, UX-05]

# Metrics
duration: ~2 sessions (2026-10-03..2026-10-05, on hold 10-04 for Phases 6-12)
completed: 2026-10-05
---

# Phase 5 Plan 08: App Store Listing & Submission Summary

**Word Puzzle Unlimited v1.0 (build 2) and its $2.99 non-consumable IAP are submitted for App Review (submission `3699c1dc-…`, both WAITING_FOR_REVIEW, Manual Release). The privacy label is Data Not Collected, there are four captioned screenshots per device, and every value is recorded in the repo.**

## Performance
- **Started:** 2026-10-03 (Task 1). On hold 2026-10-04 while Phases 6-12 shipped. Resumed and completed 2026-10-05.
- **Tasks:** 2 of 2 (Task 1 drafted the listing; Task 2 covered the App Store Connect listing, uploads and submission)

## Accomplishments
- **Screenshots:** re-captured against the post-Phase-12 UI.
  - Added a found-words shot. On iPad the sheet is dragged to the large detent.
  - The capture script now clears stale raw captures before it runs.
  - Uploaded via the API: 4 x `APP_IPHONE_67` (1320x2868) and 4 x `APP_IPAD_PRO_3GEN_129` (2064x2752), all `COMPLETE`.
- **IAP review screenshot:** uploaded, which moved the IAP from `MISSING_METADATA` to `READY_TO_SUBMIT`.
- **Listing text:** description (1824/4000) and promo text (168/170) were refreshed for Phases 6-12. Review notes now explain how to skip the first-launch tutorial. All were PATCHed and read back verbatim.
- **Build 1.0 (2):** archived and uploaded. It was `VALID` within about 5 minutes with `usesNonExemptEncryption false`, then attached to version 1.0.
- **Submission:** Patrick completed the App Privacy questionnaire (Data Not Collected), Content Rights and the app price, then submitted version and IAP together. The appInfo reads back `WAITING_FOR_REVIEW`, age rating `FOUR_PLUS`.

## Task Commits
1. **Task 1 (2026-10-03/04):** listing draft and earlier API pushes. These are recorded in the listing doc's progress log.
2. **Task 2 (2026-10-05):**
   - `dd670b5` feat: re-capture App Store screenshots with found-words shot
   - `7bee163` chore: bump build number to 1.0 (2)
   - `83ff825` docs: refresh listing copy, fix stale URLs/copyright, record API read-back
   - `1f4b46e` chore: add App Store Connect asset upload helper
   - `615d42c` docs: record screenshot and IAP review screenshot uploads
   - `ab6a848` docs: record metadata push, build 1.0 (2) upload and attach

## What App Store Connect rejected or handled unexpectedly (for the next submission)
1. **The first IAP was not included automatically.**
   - The 7:04 PM submission contained only the version, so Patrick cancelled it. The version became `DEVELOPER_REJECTED`, which can be resubmitted.
   - Fix: add the IAP to a draft submission from the IAP page. Then add the version to the same draft via Add for Review → "Draft Submission (1)".
2. **"Add for Review" was blocked by two settings that were never set:**
   - Content Rights (answered Yes: third-party content, rights held, since ENABLE is public domain)
   - The app price tier (now Free, USD base)
3. **The 6.9" screenshot set is hidden in the new media UI.** It only appears under "View All Sizes in Media Manager"; the default view is "iPhone with Dynamic Island (medium display)". The "iPhone Duo" tab was not required.
4. **The Claude Code permission check blocked App Store Connect writes until Patrick added Bash allow rules.** Commands must match those rules exactly: no pipes, no `cd`, no env prefixes.
5. **The Bash tool turned JSON `'` escapes into bare apostrophes and broke the shell quoting.** Use the shell `'\''` idiom instead.

## Availability
Mac (Apple silicon) and Apple Vision Pro availability are **confirmed unchecked**; Patrick's Pricing and Availability screenshot (2026-10-05) shows both boxes unchecked. iPad stays available (05-04 device-family-keep-ipad).

## Export compliance
No prompt appeared. Builds 1 and 2 both report `usesNonExemptEncryption false`, which confirms plan 05-04's Info.plist key reaches the uploaded build.

## Published URLs
- Privacy Policy: https://apps.threemilebridge.com/wordpuzzle/privacy/
- Support: https://apps.threemilebridge.com/wordpuzzle/support/

## Deviations from Plan
- **Plan said screenshots would be uploaded by hand; they were uploaded via the API** (`scripts/asc_upload_assets.py`) after Patrick approved it. The payloads were checked against Apple's OpenAPI spec v4.5.
- **[Rule 2] `marrano` (a historical slur) was kept out of the round-end screenshot.** The test submits it during staging, so it only appears below the visible part of the found-words sheet.
- **[Rule 1] The iPad found-words sheet at medium height covered the honeycomb.** The test now drags the sheet to full height on iPad.

## Remaining items / follow-ups
- [ ] **After approval:** press **Release** in App Store Connect (Manual Release is set).
- [ ] **Word list (999.9):** `marrano` (a slur) is in `enable-clean.txt` and shows up as a valid and missed word in the HARMONY/R puzzle. Add it to the 999.9 word-list review / profanity filter.
- [ ] **Swift 6 readiness:** the Release archive emits actor-isolation warnings. They are not errors in Swift 5 mode, but will be in Swift 6 mode:
  - `RingSpinController` uses `RingSpinTuning.standard` as a default argument
  - `SpinFeedback` uses `SoundManager.shared` and `TickThrottle()` as default arguments
  - `TutorialController` uses `TutorialTiming.standard` as a default argument
- Cosmetic: the iPadOS window-resize corner mark appears in the iPad screenshots. It was also in the 05-07 shots.

## Known Stubs
None.

## Self-Check: PASSED
- All six task commits exist (dd670b5, 7bee163, 83ff825, 1f4b46e, 615d42c, ab6a848).
- The 05-08-APP-STORE-LISTING.md verify printed `LISTING_SUBMITTED`.
- `bash scripts/compliance-guards.sh` exits 0.
- `git status --porcelain WordPuzzle/` is empty.
