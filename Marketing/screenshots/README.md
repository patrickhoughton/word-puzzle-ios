# App Store Screenshots

Captioned App Store screenshots (UX-04 / D-09). Every image here regenerates from
committed scripts — nothing is hand-edited.

| Set | Simulator | App Store slot | Size |
|---|---|---|---|
| `raw/`, `final/` | iPhone 17 Pro Max | 6.9" iPhone (mandatory) | 1320x2868 |
| `raw/ipad/`, `final/ipad/` | iPad Pro 13-inch (M5) | 13" iPad | 2064x2752 |

The iPad set is required because plan 05-04 chose `device-family-keep-ipad`
(`TARGETED_DEVICE_FAMILY = "1,2"`).

## 1. Capture the raws (automated)

```bash
bash scripts/capture-app-store-screenshots.sh iphone
bash scripts/capture-app-store-screenshots.sh ipad
```

This resets the app on the Simulator, sets default Dynamic Type, light mode and a
9:41 status bar, then runs `WordPuzzleUITests/AppStoreScreenshotTests`, which plays
real gameplay on the staged HARMONY puzzle (center R, via the DEBUG-only
`-ScreenshotPuzzle harmony:r` launch argument) and writes `01-gameplay.png`,
`02-found-words.png` (Phase 7 sheet; medium detent on iPhone, dragged to large on
iPad), `03-round-end.png` and `04-paywall.png`. It also passes
`-hasSeenTutorial YES` so the Phase 11 first-launch tutorial never intercepts the
fresh install (an ordinary UserDefaults argument-domain value for the same flag the
app sets itself after the tutorial; it adds no code path to Release). The paywall price comes from
`WordPuzzle.storekit`, loaded by the scheme's Test action.

`scripts/capture-screenshot.sh <out.png> [iphone|ipad]` captures the booted
Simulator's current screen manually, with the same size check.

## 2. Composite the finals

```bash
for sub in "" "ipad/"; do
swift scripts/FrameScreenshot.swift \
  Marketing/screenshots/raw/${sub}01-gameplay.png \
  "Endless word puzzles, fresh every round" \
  Marketing/screenshots/final/${sub}01-gameplay.png

swift scripts/FrameScreenshot.swift \
  Marketing/screenshots/raw/${sub}02-found-words.png \
  "Track every word you find, sorted by length" \
  Marketing/screenshots/final/${sub}02-found-words.png

swift scripts/FrameScreenshot.swift \
  Marketing/screenshots/raw/${sub}03-round-end.png \
  "See every word you missed, pangrams too" \
  Marketing/screenshots/final/${sub}03-round-end.png

swift scripts/FrameScreenshot.swift \
  Marketing/screenshots/raw/${sub}04-paywall.png \
  "Unlock unlimited puzzles — no subscription, just \$2.99" \
  Marketing/screenshots/final/${sub}04-paywall.png
done
```

Keep the `\$` escape — unescaped, the shell expands `$2` to nothing and the caption
loses its price (the compositor does not catch a partially-empty caption).

A copy change is a re-run of step 2; a UI change is a re-run of steps 1 and 2.

The IAP App Review screenshot (App Store Connect, In-App Purchases > Unlimited Puzzles >
Review Information) is the uncaptioned `raw/04-paywall.png`.

Upload order in App Store Connect = 01, 02, 03, 04 (last re-captured 2026-10-05, 05-08,
after Phases 6-12).
