---
phase: 05-polish-compliance-app-store
plan: 04
subsystem: infra
tags: [pbxproj, appstoreconnect, encryption-export-compliance, device-family, compliance-automation]

# Dependency graph
requires:
  - phase: 05-02
    provides: "Font.system(size:) migration completed and HexTileView.swift established as the one sanctioned exception, which this plan's Guard 4 depends on"
provides:
  - "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO on both app-target build configurations (Debug/Release)"
  - "Explicit, recorded confirmation that TARGETED_DEVICE_FAMILY stays \"1,2\" (iPhone + iPad) -- device-family-keep-ipad decision"
  - "scripts/compliance-guards.sh -- committed, executable regression guard for all four Phase 5 source-level invariants (no networking APIs, encryption declaration, device family, Font.system(size:) exception)"
affects: [05-06-manual-device-pass, 05-07-screenshots, 05-08-app-store-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "scripts/compliance-guards.sh consolidates all Phase 5 source/config compliance invariants into one command, run from repo root as `bash scripts/compliance-guards.sh`; explicitly does not and cannot check runtime behavior (Airplane Mode, AX5, audible SFX remain plan 05-06 manual checks)"
    - "Decision ids referenced in code comments (device-family-keep-ipad) so future readers can distinguish deliberate choices from drift"

key-files:
  created:
    - scripts/compliance-guards.sh
  modified:
    - WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj

key-decisions:
  - "device-family-keep-ipad: Patrick chose to KEEP TARGETED_DEVICE_FAMILY = \"1,2\" (iPhone + iPad) rather than restrict to iPhone-only (device-family-iphone-only). No pbxproj change was needed for this decision itself since it preserves the existing value. Patrick explicitly accepted the scope cost: plan 05-07 must add a 13\" iPad (2064x2752) screenshot set, and an iPad layout smoke test is now in scope that is not currently in any Phase 5 plan."
  - "Encryption export compliance: INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO added to both app-target configuration blocks (Debug/Release) in project.pbxproj, immediately after GENERATE_INFOPLIST_FILE = YES. The app makes zero network calls and uses no encryption of any kind, exempt or otherwise. This stops App Store Connect from prompting for export compliance on every build upload."

patterns-established:
  - "Pattern: any future compliance-invariant regression can be caught by `bash scripts/compliance-guards.sh` before it reaches App Store Connect"

requirements-completed: [UX-01, UX-05]

# Metrics
duration: ~7min (this continuation session; Task 1 decision + Task 2 pbxproj edit were completed in a prior cut-off session)
completed: 2026-09-07
---

# Phase 05 Plan 04: Compliance Decisions Summary

**Encryption export compliance declared (ITSAppUsesNonExemptEncryption = NO) and the iPhone+iPad device-family scope explicitly confirmed and locked in with a committed four-guard regression script**

## Performance

- **Duration:** ~7 min of active execution in this continuation session (Task 3: verifying and committing `scripts/compliance-guards.sh`). Tasks 1 and 2 (device-family decision + pbxproj encryption/device-family edits) were completed in a prior session that was cut off by a rate limit before Task 3's file could be committed.
- **Started:** 2026-09-07T11:32:32-05:00 (070fcc7, Task 2's commit, carried over from prior session)
- **Completed:** 2026-09-07T11:34:40-05:00 (661a1ac, Task 3's commit)
- **Tasks:** 3 (1 checkpoint:decision, 2 auto)
- **Files modified:** 2 (project.pbxproj + compliance-guards.sh)

## Accomplishments
- Task 1 (prior session): Patrick decided `device-family-keep-ipad` — iPhone + iPad stays enabled, accepting the added iPad screenshot and layout-smoke-test scope this creates for plans 05-07/05-06.
- Task 2 (prior session, commit `070fcc7`): Added `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` to both app-target build configurations. No `TARGETED_DEVICE_FAMILY` edit was needed since the decision preserved the existing `"1,2"` value.
- Task 3 (this session, commit `661a1ac`): Verified the on-disk `scripts/compliance-guards.sh` (found untracked from the interrupted session) against the plan's exact spec line by line — all four guards, fail-message wording, decision-id comment, `set -uo pipefail` preamble, and `FAILURES` counter all matched — then ran it, confirmed all four PASS lines and exit 0, ran the required negative check (temporarily appending `let x = URLSession.shared` to `HexTileView.swift`), confirmed Guard 1 correctly failed with the UX-01 message, reverted the scratch change, confirmed `git status --porcelain WordPuzzle/WordPuzzle` was clean, and committed the script as-is with no further edits needed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Confirm the app's targeted device family** - checkpoint, no commit (decision `device-family-keep-ipad` recorded above and in the prior session's summary notes)
2. **Task 2: Apply the encryption and device-family build settings** - `070fcc7` (feat) — carried over from the interrupted prior session
3. **Task 3: Commit scripts/compliance-guards.sh as a permanent regression guard** - `661a1ac` (feat) — completed this session

## Files Created/Modified
- `WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` - Added `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` to both app-target configuration blocks (Debug/Release). `TARGETED_DEVICE_FAMILY = "1,2"` unchanged (6 occurrences, per device-family-keep-ipad).
- `scripts/compliance-guards.sh` - New 105-line executable regression guard; four guards (no networking APIs / encryption declaration / device family / Font.system(size:) exception), `FAILURES` counter, `set -uo pipefail`, docstring stating it checks source/config invariants only.

## Decisions Made

**Task 1 decision (device-family-keep-ipad), verbatim per resume instructions:**

Patrick chose to KEEP iPhone + iPad (`TARGETED_DEVICE_FAMILY` stays `"1,2"` — no pbxproj change needed, this was a no-op confirmation). Patrick explicitly accepted the scope cost: plan 05-07 needs an added 13" iPad screenshot set, and an iPad layout smoke test is needed that isn't in any current Phase 5 plan.

**Task 2 decision (encryption export compliance):**

Resolved by commit `070fcc7`, already verified against plan spec: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` present exactly 2 times in `project.pbxproj` (both app-target configs, not the Tests/UITests blocks), immediately after `GENERATE_INFOPLIST_FILE = YES;`. `TARGETED_DEVICE_FAMILY = "1,2";` confirmed unchanged at 6 occurrences.

**Observed grep counts (for plan 05-08's App Store Connect export-compliance answer):**
- `grep -c "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;" project.pbxproj` → 2
- `grep -c 'TARGETED_DEVICE_FAMILY = "1,2";' project.pbxproj` → 6
- `bash scripts/compliance-guards.sh` → exit 0, all 4 guards PASS

## Deviations from Plan

None - plan executed exactly as written. The only wrinkle was operational (a rate-limit cutoff between sessions), not a plan deviation: Task 3's script existed untracked on disk from the interrupted prior session, was verified line-by-line against the plan's exact spec (all four guards, fail-message text, decision-id comment, preamble, counter), found to already match completely, and was committed with zero edits.

## Issues Encountered

None. The negative-check verification (temporarily injecting `URLSession.shared` into `HexTileView.swift`) worked as specified on the first attempt: Guard 1 failed with the exact UX-01 message, the other three guards still passed, and reverting left `WordPuzzle/WordPuzzle` clean.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both UX-01 and UX-05 requirements are now locked in with a committed regression guard (`bash scripts/compliance-guards.sh`) that will catch any future drift in networking APIs, the encryption declaration, the device family value, or the Font.system(size:) exception.
- **Scope drift flagged for downstream plans:** the device-family-keep-ipad decision adds unbudgeted scope to plan 05-07 (13" iPad 2064x2752 screenshot set) and plan 05-06 (iPad layout smoke test) that was not present when those plans were originally written iPhone-only. This is recorded as a Blocker/Concern in STATE.md so it is visible before Wave 3 executes, not a silent gap discovered mid-plan.
- No other blockers.

---
*Phase: 05-polish-compliance-app-store*
*Completed: 2026-09-07*

## Self-Check: PASSED

`scripts/compliance-guards.sh` found on disk and executable; commits `070fcc7` and `661a1ac` found in git history; `bash scripts/compliance-guards.sh` exits 0 with all four guards passing.
