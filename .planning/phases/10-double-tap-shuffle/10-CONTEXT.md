# Phase 10: Double-Tap Shuffle - Context

**Gathered:** 2026-10-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a double-tap-on-empty-space gesture on the game screen that shuffles the 6 outer letters — an *addition* to the existing Shuffle button, calling the same `GameViewModel.shuffleOuterLetters()`. Plus a light haptic on every shuffle (button and gesture). No other gestures, no hints/onboarding (Phase 12), no long-press (Phase 11).

</domain>

<decisions>
## Implementation Decisions

### Trigger zone (what counts as "empty")
- **D-01:** Trigger is a double-tap on empty space, NOT on a tile (locked in ROADMAP — double-tapping a tile still appends that letter twice).
- **D-02:** Gaps and corners inside `LetterGridView`'s flower-diameter square that are not on a tile COUNT as empty. Today the grid's `DragGesture(minimumDistance: 0)` captures those touches and no-ops (`hitIndex` returns nil); the implementation must let non-tile double-taps there trigger shuffle without breaking tile tap/drag input.
- **D-03:** All background area not covered by a control counts — top padding, spacers above/below the word display and grid, horizontal margins. No "near the grid only" restriction.
- **D-04:** The word display (`WordDisplayView`) is EXCLUDED — single-tap there clears the word and swipe-down submits; double-tap there must not shuffle.
- **D-05:** Buttons (stats, settings, debug menu, score bar, Shuffle, Delete, Finish Round) keep their own behavior; double-tapping them does not shuffle.

### Shuffle button
- **D-06:** Shuffle button stays exactly as-is. Gesture is additive.
- **D-07:** No custom VoiceOver accessibility action — the labeled "Shuffle Letters" button is the VoiceOver path (VoiceOver's own double-tap means the raw gesture can't apply).

### Feedback
- **D-08:** Add a light impact haptic on EVERY shuffle — both the button and the gesture paths — for consistency. Follow the project's existing counter-trigger `.sensoryFeedback` pattern (as used in GameView/WordDisplayView). Only fire when a shuffle actually happens (not when the `isShuffling` guard rejects it).
- **D-09:** No sound effect for shuffle.

### Edge states
- **D-10:** Gesture is active only during `.playing`. Inert during `.roundOver`, paywall, and while Stats/Settings/Found Words sheets are presented.
- **D-11:** The in-progress word is preserved on shuffle (same as button today).
- **D-12:** Gesture works during celebration overlays (overlay is `allowsHitTesting(false)`; matches button behavior).
- **D-13:** Rapid repeated double-taps during the 400ms shuffle animation are ignored via the existing `isShuffling` guard in `shuffleOuterLetters()` (Phase 3 D-03 / Pitfall 2).

### Claude's Discretion
- Gesture composition approach (e.g., `onTapGesture(count: 2)` on a background layer vs. extending the grid's single DragGesture with tap-count/timing detection for non-tile touches). Must respect Phase 3 Pitfall 1 (competing recognizers swallowing taps) — tile tap latency must not regress (no waiting for a possible second tap on tiles).
- Whether a "tile tap followed by gap tap" within the double-tap window counts (preferred: no — both taps must be on empty space).
- Haptic intensity specifics (`.impact(weight: .light)` or equivalent).
- Test strategy (unit tests for any hit-test/tap-count logic; on-device verification of gesture feel).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §"Phase 10: Double-Tap Shuffle" — goal, trigger decision, gesture-contention note
- `.planning/REQUIREMENTS.md` — PUZZ-04 (shuffle)

### Prior gesture/shuffle decisions
- `.planning/phases/03-core-game-ui/03-CONTEXT.md` — D-03 shuffle animates, never jumps
- `.planning/phases/03-core-game-ui/03-RESEARCH.md` §"Pitfall 1: Competing gesture recognizers on tap vs. drag" and §"Pitfall 2: PreferenceKey frames stale after shuffle animation" — MUST read before touching gestures
- `.planning/phases/03-core-game-ui/03-UI-SPEC.md` — game screen layout/interaction contract

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GameViewModel.shuffleOuterLetters()` (`WordPuzzle/WordPuzzle/Game/GameViewModel.swift`): already guarded by `isShuffling`; gesture just calls it.
- `GameTheme.shuffleAnimation` / `shuffleDurationMilliseconds` (`Game/GameTheme.swift`).
- `HexFlowerLayout.hitTest` + `TileFramePreferenceKey` in `Game/Views/LetterGridView.swift`: existing tile hit-testing — "not on any tile" = `hitIndex(at:) == nil`.

### Established Patterns
- `LetterGridView` uses exactly ONE `DragGesture(minimumDistance: 0)` for tap + drag; documented as intentional — do not add competing per-tile recognizers.
- `LetterGridView` is presentation-only (no view-model reference); new behavior should be exposed as a callback (e.g., `onEmptyDoubleTap`) bound in `GameView`.
- Haptics: counter-based `.sensoryFeedback(_, trigger:)` in `GameView` (`lengthHapticCount`, `sweepHapticCount`).
- `WordDisplayView` owns `.onTapGesture { onClear() }` + `submitDragGesture` (minDistance 10).

### Integration Points
- `GameView.playingLayout` (`Game/Views/GameView.swift` ~line 292): the VStack whose background hosts the empty-area recognizer.
- `GameView.iconButtonsRow` Shuffle button: add haptic trigger for D-08.

</code_context>

<specifics>
## Specific Ideas

No specific references — standard iOS feel. Phase 12 tutorial will teach this gesture.

</specifics>

<deferred>
## Deferred Ideas

- One-time "double-tap to shuffle" hint — belongs to Phase 12 (First-Launch Tutorial).

</deferred>

---

*Phase: 10-double-tap-shuffle*
*Context gathered: 2026-10-04*
