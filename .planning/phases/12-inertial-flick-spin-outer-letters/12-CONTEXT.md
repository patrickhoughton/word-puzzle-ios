# Phase 12: Inertial Flick-to-Spin - Context

**Gathered:** 2026-10-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Push or flick the outer ring of 6 letters in either direction. The ring spins around the center letter with momentum, slows down, and settles into whole slots, so the letters end up in new positions. The Shuffle button and double-tap-to-shuffle (Phase 10) stay as they are. This is an additional interaction, not a replacement.

**Guiding principle (user-stated):** the feature is **purely ASMR engagement, especially when the player is stumped**. It's a fidget toy. Tactile feel (smooth 1:1 tracking, satisfying ticks, a long luxurious coast) comes first. Rearranging the letters is a side effect, not the goal. When a trade-off isn't covered below, choose whatever feels more satisfying to fiddle with.

</domain>

<decisions>
## Implementation Decisions

### Where a Spin Starts (gesture disambiguation)
- **D-01:** A spin starts **only from a touch that begins off every tile**: the gaps between hexagons, the corners of the flower square, and a ring-shaped zone just outside the outer tiles. The zone may be enlarged beyond today's `flowerDiameter` square so there's comfortable room to grab.
- **D-02:** Touches that begin **on a tile behave exactly as today**: tap appends at touch-down, drag-to-connect spells. There's no tangential-swipe-from-a-tile detection, so a spin never types a letter by accident.
- **D-03:** This must coexist with Phase 10's empty-space double-tap in the same off-tile area. A quick tap with no travel is still a tap (it counts toward the double-tap shuffle). Any off-tile drag with travel turns the ring. `EmptyDoubleTapDetector` already rejects touches with more than 10pt of travel. Keep Phase 3 Pitfall 1 in mind: still ONE recognizer, and no tile-tap latency regression.

### Spin Feel & Landing
- **D-04:** **The ring follows the finger 1:1** (a dial), so you can wind it slowly, wiggle it back and forth, or flick it. On release, the angular velocity carries into a decaying coast.
- **D-05:** **Long, prize-wheel coast: a hard flick spins for 5+ seconds.** The friction curve must be continuous: a soft push moves a little, a hard flick spins a long time. Not just two speeds.
- **D-06:** **Soft snap to the nearest whole slot** (a multiple of 60°) at the end of the slow-down, with a gentle spring "clunk". No bouncy overshoot. Once settled, tiles sit exactly at `HexFlowerLayout` slot positions, so hit-testing lines up.
- **D-07:** **Letters stay upright** while tiles orbit (Ferris-wheel style). Only tile positions rotate, never the glyph orientation.
- **D-08:** **Landing back at the starting arrangement is fine.** No forced nudge. Rotation keeps the letters' order around the circle; Shuffle is still the way to actually mix them.
- **D-09:** After landing, the new slot order is committed to `GameViewModel.outerLetters` (a cyclic rotation), so the board state, tutorial highlight and later shuffles all see the real order.

### Feedback
- **D-10:** **A haptic tick each time a tile passes a slot boundary**, during both finger tracking and the coast. The ticks space out naturally as the ring slows (a prize-wheel clicker). A **slightly firmer "clunk" haptic plays when it snaps** into place.
- **D-11:** **A soft click sound in sync with each tick**, from the CC0 Kenney packs (new `SoundEffect` case, or cases if the clunk gets its own sound). It respects the `soundEffectsEnabled` setting and the `.ambient` session/silent switch. This deliberately differs from Shuffle, which stays silent (Phase 10 D-09). Fast spins can pass slots very quickly, so ticks and clicks need rate-limiting or voice handling that stays pleasant, not buzzy or clipped.
- **D-12:** **"Full circle!" jackpot, cosmetic only.** If a single spin covers **more than 5 full rotations** and lands every letter back in its **pre-spin** position, play a special celebration: sparkle + "Full circle!" popup + a distinct sound and haptic. **No points, no score or rank change.** (User first proposed bonus points. They chose cosmetic-only after discussing farm risk (about a 1-in-6 landing chance per spin) and Phase 8's rule that bonuses count toward rank and Mythic Grandmaster.)

### Control & Round State
- **D-13:** **Grab to stop:** an off-tile touch during a coast catches the ring immediately. The player can wind it again or let go, which then snaps (or coasts if they flicked again).
- **D-14:** **Tiles are locked while the ring is moving** (finger-tracking or coasting) and until it settles. This matches the `isShuffling` input-disable rule (Phase 3 Pitfall 2 / Phase 10 D-13), so a sliding letter is never typed.
- **D-15:** **The Shuffle button cancels a spin**: tapping it mid-spin stops the ring, snaps it, then performs a normal shuffle. The planner decides how double-tap shuffle interacts mid-spin. The first off-tile tap grabs the ring per D-13; keep it consistent and simple.
- **D-16:** **The in-progress word is kept**: spinning never clears or edits `currentWord` (same as Phase 10 D-11).
- **D-17:** **Active only during `.playing`**: inert on round-over, the paywall, and while the Stats/Settings/Found Words sheets are open. It works during celebration overlays. Same rules as Phase 10 D-10/D-12.

### Accessibility
- **D-18:** **Reduce Motion:** dragging still turns the ring 1:1 with ticks, but there's **no coast**. On release it snaps to the nearest slot.
- **D-19:** No custom VoiceOver action is needed. The labeled Shuffle button stays the accessible rearrange path (same reasoning as Phase 10 D-07).

### Tutorial
- **D-20:** **Add a short guided step right after the Shuffle step** in the Phase 11 practice script, for example "Stuck? Give the ring a spin." It waits for one completed spin (any spin that settles counts), then advances. It follows Phase 11's strict-step input filtering (D-02 there), so only the spin zone responds during that step. Copy should be playful and consistent with Phase 6/11 tone, and the banner must survive AX5.

### Claude's Discretion
- The physics model (exponential decay versus friction constant, the velocity-to-duration mapping, and the max-duration cap needed to hit "5s+" on a hard flick) and the animation driver (`TimelineView`, `CADisplayLink`, a custom animatable modifier, and so on).
- The exact spin-zone geometry (how far outside the outer tiles it extends), within D-01 and without colliding with the word display or controls.
- Haptic generator types and intensities for tick, clunk and jackpot. The specific Kenney clips, and the tick rate-limit strategy.
- The jackpot visual. Reuse the existing celebration overlay patterns (`CompletionCelebrationViews.swift`) where possible.
- How "pre-spin position" and the rotation count are tracked for D-12. Net rotation versus total angle travelled: pick whichever matches "spun more than 5 times and came back home".
- Whether the spin state lives in `LetterGridView` (presentation) with a commit callback, or in `GameViewModel`. Views stay value-in/closure-out (only `GameView` touches `GameViewModel`).
- Test strategy: unit tests for pure physics, slot-snap and rotation math (like `EmptyDoubleTapDetector` / `HexFlowerLayout`), plus on-device verification of the feel. The feel can only be judged on a physical device (Wi-Fi install script).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` § "Phase 12: Inertial Flick-to-Spin": the goal plus the design complexity notes (gesture disambiguation, physics model, discreteness, 999.5 history)

### Prior decisions this phase builds on
- `.planning/phases/10-double-tap-shuffle/10-CONTEXT.md`: empty-space gesture zone (D-02/D-03), shuffle haptic (D-08), silent shuffle (D-09), active-state rules (D-10/D-12), `isShuffling` guard (D-13)
- `.planning/phases/10-double-tap-shuffle/10-RESEARCH.md`: how the single DragGesture was extended for empty-space taps without a second recognizer
- `.planning/phases/11-first-launch-tutorial/11-CONTEXT.md`: tutorial script (D-05), strict guided steps (D-02)
- `.planning/phases/11-first-launch-tutorial/11-UI-SPEC.md`: tutorial banner/highlight contract and AX5 rules
- `.planning/phases/08-all-pangrams-bonus/08-CONTEXT.md` D-04..D-06: why the jackpot is cosmetic (bonuses count toward rank/Mythic)

No external specs. The requirements are fully captured in the decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WordPuzzle/WordPuzzle/Game/Views/LetterGridView.swift`: the single `DragGesture(minimumDistance: 0)` in the "hexGrid" coordinate space, with `hitIndex(at:)` and the `.onEnded` empty-tap path. The spin gesture extends this same recognizer.
- `WordPuzzle/WordPuzzle/Game/Views/HexFlowerLayout.swift`: `outerOffsets(radius:)` (index 0 = 12 o'clock, clockwise every 60°), `flowerDiameter`, `hitTest`. It needs an angle-parameterized variant to place tiles at arbitrary ring angles mid-spin.
- `WordPuzzle/WordPuzzle/Game/EmptyDoubleTapDetector.swift`: a pure, unit-tested gesture helper. A spin/physics helper should follow the same pattern.
- `WordPuzzle/WordPuzzle/Game/GameViewModel.swift` `shuffleOuterLetters()` / `isShuffling` / `shuffleCount`: the input-lock and counter-trigger haptic pattern to mirror (or extend) for spin.
- `WordPuzzle/WordPuzzle/Services/SoundManager.swift` `SoundEffect`: where new click/clunk/jackpot cases go.
- `WordPuzzle/WordPuzzle/Game/Views/CompletionCelebrationViews.swift`: existing celebration popups (length complete, sweep) to model "Full circle!" on.
- `WordPuzzle/WordPuzzle/Tutorial/TutorialController.swift` / `TutorialStep.swift`: where the new spin step and its input filtering go.

### Established Patterns
- **One gesture recognizer** on the grid (Phase 3 Pitfall 1); tile taps append at touch-down with zero latency.
- **Counter-based `.sensoryFeedback` triggers** (not Bool) so repeated events still fire.
- **Input disabled while letters move** (`isInputDisabled: viewModel.isShuffling`).
- Today `.animation(GameTheme.shuffleAnimation, value: outerLetters)` animates slot changes. Spin positions are continuous, so make sure this implicit animation doesn't fight the spin's own driver when the final order is committed.
- Views are presentation-only. `GameView` wires callbacks with `if let tutorial { tutorial.send(...) } else { viewModel... }`.

### Integration Points
- `WordPuzzle/WordPuzzle/Game/Views/GameView.swift` around line 446: the `LetterGridView(...)` construction, which needs new spin callbacks or state. The Shuffle button paths are near lines 480/513 (D-15 cancel).
- The tutorial `send(...)` event enum needs a spin event for D-20.

</code_context>

<specifics>
## Specific Ideas

- "Purely ASMR engagement, especially when the user's stumped." Feel is the whole point.
- Prize-wheel / combination-lock dial references: a clicker that ticks per slot, slows naturally, and lands with a soft clunk.
- "Full circle!" jackpot for more than 5 rotations landing back home, cosmetic only.

</specifics>

<deferred>
## Deferred Ideas

- **Score points for the spin jackpot**: the user raised it and chose cosmetic-only for now. If revisited, it's a scoring change for its own small phase, with a once-per-round cap and a decision on whether it counts toward rank.

</deferred>

---

*Phase: 12-inertial-flick-spin-outer-letters*
*Context gathered: 2026-10-05*
