---
phase: 05-polish-compliance-app-store
plan: 03
subsystem: ui
tags: [swiftui, imagerenderer, appicon, appstore, assets-xcassets]

# Dependency graph
requires: []
provides:
  - "Reproducible scripts/GenerateAppIcon.swift generator (concept a/b x light/dark/tinted)"
  - "Three committed, opaque, 1024x1024 AppIcon appearance-slot PNGs (light, dark, tinted) for concept-a"
  - "Wired Contents.json referencing all three PNGs by filename"
affects: [05-06-manual-device-pass, app-store-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "App icon is generated, never hand-painted: scripts/GenerateAppIcon.swift is the source of truth, PNGs are regenerated outputs"
    - "ImageRenderer output is always alpha-flattened via an opaque CGContext (CGImageAlphaInfo.noneSkipLast) before writing, since iOS app icons must not contain alpha"

key-files:
  created:
    - WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
    - WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png
    - WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png
  modified:
    - WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/Contents.json
    - scripts/GenerateAppIcon.swift

key-decisions:
  - "D-08: Patrick chose Concept A (single gold hexagon, bold black 'W') over Concept B (seven-hexagon honeycomb), no refinements requested — shipped exactly as generated"
  - "Concept A chosen for legibility at the 40x40 Settings-icon size and in the tinted monochrome slot; Concept B's honeycomb collapsed into an indistinct dot cluster at 40x40"

patterns-established:
  - "Pattern: any future icon iteration is `swift scripts/GenerateAppIcon.swift a <light|dark|tinted> <path>` — never edit the PNGs directly"

requirements-completed: [UX-04]

# Metrics
duration: 10min
completed: 2026-09-07
---

# Phase 05 Plan 03: App Icon Summary

**Concept-A app icon (single #F5B800 gold hexagon, bold black "W") generated via a reproducible SwiftUI/ImageRenderer script and wired into all three AppIcon appearance slots (light, dark, tinted)**

## Performance

- **Duration:** ~10 min of active execution across Task 1 and Task 3 (Task 2 was a human decision checkpoint, not execution time)
- **Started:** 2026-09-07T16:13:45Z (Task 1 commit)
- **Completed:** 2026-09-07T16:23:04Z (Task 3 commit)
- **Tasks:** 3 (1 auto, 1 checkpoint:decision, 1 auto)
- **Files modified:** 5 (1 script + 3 PNGs + 1 Contents.json)

## Accomplishments
- Built `scripts/GenerateAppIcon.swift`, a standalone `swift scripts/GenerateAppIcon.swift <a|b> <light|dark|tinted> <out.png>` generator using SwiftUI `ImageRenderer`, producing alpha-flattened 1024x1024 PNGs with no third-party tooling
- Rendered both concept drafts (A: single hex + "W"; B: seven-hexagon honeycomb) across all three appearance slots plus 120x120/40x40 downscales for Patrick's review
- Patrick selected Concept A at the Task 2 checkpoint (D-08 satisfied — direction chosen before final assets were produced)
- Generated the three final opaque 1024x1024 PNGs for Concept A directly into `AppIcon.appiconset/` and wired `Contents.json` with `filename` keys for all three appearance entries
- Verified via Simulator build: `BUILD SUCCEEDED`, no `actool` AppIcon warnings, derived `AppIcon60x60@2x.png` and `AppIcon76x76@2x~ipad.png` present in the built bundle, `CFBundleIcons` present in `Info.plist`

## Task Commits

Each task was committed atomically (Task 1 committed by a prior executor agent in this same worktree; Task 2 was a non-code checkpoint recorded in this document):

1. **Task 1: Build the icon generator and render both concept drafts** - `d839b34` (feat)
2. **Task 2: Patrick picks the icon concept direction (D-08)** - checkpoint, no commit (decision recorded below)
3. **Task 3: Generate the final three appearance slots and wire Contents.json** - `d7f6a97` (feat)

_Note: no plan-metadata commit hash yet — created after this SUMMARY.md is written._

## Files Created/Modified
- `scripts/GenerateAppIcon.swift` - Reproducible generator; `ConceptAView`/`ConceptBView` render the two directions, `Appearance` enum drives light/dark/tinted palettes, alpha-flattening via opaque `CGContext`
- `WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` - Universal (light) slot, Concept A, opaque, 1024x1024
- `WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png` - Dark appearance slot, Concept A, opaque, 1024x1024
- `WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png` - Tinted (monochrome) slot, Concept A, opaque, 1024x1024
- `WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/Contents.json` - Added `filename` key to each of the three existing image entries; no other structural change

## Decisions Made

**D-08 decision (Task 2 checkpoint), Patrick's response verbatim:**

> Concept A (single gold hexagon with bold black "W"). No refinements requested — ship it as generated.
>
> Rationale: Concept A stays legible at every size including the 40x40 Settings-icon slot and the tinted monochrome variant. Concept B (seven-hexagon honeycomb) collapsed into an indistinct dot cluster at 40x40, failing the exact risk the UI spec flagged.

No refinements were applied to `scripts/GenerateAppIcon.swift` for Task 3 — Concept A shipped exactly as the Task 1 generator already produced it.

**Exact reproduction commands** (byte-for-byte regeneration of the three shipped PNGs):

```
swift scripts/GenerateAppIcon.swift a light  WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
swift scripts/GenerateAppIcon.swift a dark   WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Dark.png
swift scripts/GenerateAppIcon.swift a tinted WordPuzzle/WordPuzzle/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-Tinted.png
```

## Deviations from Plan

None - plan executed exactly as written. Concept A was shipped with zero refinements, so no changes to `scripts/GenerateAppIcon.swift` were needed in Task 3 beyond what Task 1 already built.

## Issues Encountered

None. The Simulator build succeeded on the first attempt with no `actool` warnings about `AppIcon`, and the derived icon files (`AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png`) plus `CFBundleIcons` in `Info.plist` confirmed the asset catalog wiring was correct without iteration.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- App icon is fully wired and builds correctly for the Simulator; ready for on-device visual confirmation on the Home screen, in Settings, and in dark/tinted appearance modes, which is explicitly deferred to plan 05-06's manual pass per this plan's `<verification>` section.
- No blockers. The generator script (not the PNG binaries) is the source of truth for any future icon revision.

---
*Phase: 05-polish-compliance-app-store*
*Completed: 2026-09-07*

## Self-Check: PASSED

All 5 files found on disk, both task commits (`d839b34`, `d7f6a97`) found in git history.
