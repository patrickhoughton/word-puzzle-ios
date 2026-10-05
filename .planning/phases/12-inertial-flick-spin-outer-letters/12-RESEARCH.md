# Phase 12: Inertial Flick-to-Spin - Research

**Researched:** 2026-10-05
**Domain:** SwiftUI gesture-driven rotational physics, haptics/audio feedback, tutorial script extension (iOS 17.6 target, Xcode 27)
**Confidence:** MEDIUM-HIGH (code integration points verified in repo; physics numbers are computed starting values that MUST be tuned on device)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** A spin starts **only from a touch that begins off every tile**: the gaps between hexagons, the corners of the flower square, and a ring-shaped zone just outside the outer tiles. The zone may be enlarged beyond today's `flowerDiameter` square so there's comfortable room to grab.
- **D-02:** Touches that begin **on a tile behave exactly as today**: tap appends at touch-down, drag-to-connect spells. There's no tangential-swipe-from-a-tile detection, so a spin never types a letter by accident.
- **D-03:** Must coexist with Phase 10's empty-space double-tap in the same off-tile area. A quick tap with no travel is still a tap (it counts toward the double-tap shuffle). Any off-tile drag with travel turns the ring. `EmptyDoubleTapDetector` already rejects touches with more than 10pt of travel. Keep Phase 3 Pitfall 1 in mind: still ONE recognizer, and no tile-tap latency regression.
- **D-04:** The ring follows the finger 1:1 (a dial): wind slowly, wiggle back and forth, or flick. On release, angular velocity carries into a decaying coast.
- **D-05:** Long, prize-wheel coast: a hard flick spins for 5+ seconds. Friction curve must be continuous: soft push moves a little, hard flick spins long. Not just two speeds.
- **D-06:** Soft snap to the nearest whole slot (multiple of 60 deg) at the end of the slow-down, with a gentle spring "clunk". No bouncy overshoot. Once settled, tiles sit exactly at `HexFlowerLayout` slot positions, so hit-testing lines up.
- **D-07:** Letters stay upright while tiles orbit (Ferris-wheel). Only tile positions rotate, never glyph orientation.
- **D-08:** Landing back at the starting arrangement is fine. No forced nudge. Rotation keeps the letters' cyclic order; Shuffle is still the way to mix.
- **D-09:** After landing, the new slot order is committed to `GameViewModel.outerLetters` (a cyclic rotation), so board state, tutorial highlight and later shuffles see the real order.
- **D-10:** A haptic tick each time a tile passes a slot boundary, during both finger tracking and coast. Ticks space out naturally as the ring slows. A slightly firmer "clunk" haptic when it snaps into place.
- **D-11:** A soft click sound in sync with each tick, from CC0 Kenney packs (new `SoundEffect` case(s), clunk may get its own sound). Respects `soundEffectsEnabled` and the `.ambient` session/silent switch. Deliberately differs from Shuffle (silent, Phase 10 D-09). Fast spins need rate-limiting/voice handling that stays pleasant, not buzzy or clipped.
- **D-12:** "Full circle!" jackpot, cosmetic only. If a single spin covers more than 5 full rotations and lands every letter back in its pre-spin position: sparkle + "Full circle!" popup + distinct sound and haptic. No points, no score or rank change.
- **D-13:** Grab to stop: an off-tile touch during a coast catches the ring immediately. Player can wind it again or let go (then it snaps, or coasts if flicked again).
- **D-14:** Tiles are locked while the ring is moving (finger-tracking or coasting) and until it settles. Matches `isShuffling` input-disable rule (Phase 3 Pitfall 2 / Phase 10 D-13).
- **D-15:** The Shuffle button cancels a spin: tapping mid-spin stops the ring, snaps it, then performs a normal shuffle. Planner decides how double-tap shuffle interacts mid-spin. First off-tile tap grabs the ring per D-13; keep consistent and simple.
- **D-16:** The in-progress word is kept: spinning never clears or edits `currentWord`.
- **D-17:** Active only during `.playing`: inert on round-over, paywall, and while Stats/Settings/Found Words sheets are open. Works during celebration overlays. Same rules as Phase 10 D-10/D-12.
- **D-18:** Reduce Motion: dragging still turns the ring 1:1 with ticks, but no coast. On release it snaps to nearest slot.
- **D-19:** No custom VoiceOver action needed. Labeled Shuffle button stays the accessible rearrange path.
- **D-20:** Add a short guided step right after the Shuffle step in the Phase 11 practice script ("Stuck? Give the ring a spin."). Waits for one completed spin (any spin that settles counts), then advances. Follows Phase 11 strict-step input filtering (only the spin zone responds). Playful copy, banner must survive AX5.

### Claude's Discretion
- Physics model (decay vs friction constant, velocity-to-duration mapping, max-duration cap for "5s+" on hard flick) and animation driver (TimelineView, CADisplayLink, custom animatable, etc.).
- Exact spin-zone geometry (how far outside the outer tiles), within D-01 and without colliding with word display/controls.
- Haptic generator types and intensities for tick/clunk/jackpot. Specific Kenney clips and tick rate-limit strategy.
- Jackpot visual. Reuse existing celebration overlay patterns (`CompletionCelebrationViews.swift`).
- How "pre-spin position" and rotation count are tracked for D-12 (net rotation vs total angle travelled).
- Whether spin state lives in `LetterGridView` (presentation) with a commit callback, or in `GameViewModel`. Views stay value-in/closure-out (only `GameView` touches `GameViewModel`).
- Test strategy: unit tests for pure physics/slot-snap/rotation math (like `EmptyDoubleTapDetector` / `HexFlowerLayout`), plus on-device feel verification (Wi-Fi install script).

### Deferred Ideas (OUT OF SCOPE)
- Score points for the spin jackpot (user chose cosmetic-only; if revisited it is its own small phase with a once-per-round cap and a rank decision).
</user_constraints>

<phase_requirements>
## Phase Requirements

No REQ IDs are mapped (TBD). Must-haves are derived from the decisions. The planner should use D-01..D-20 as the requirement IDs.

| ID | Description | Research Support |
|----|-------------|------------------|
| D-01..D-03 | Off-tile spin start, tile behavior unchanged, double-tap coexistence | "Gesture Architecture" pattern, `SpinZone`/touch-mode classification, slop rule |
| D-04..D-06 | 1:1 tracking, long coast, soft snap | `RingSpinTrajectory` closed-form model + critically damped settle, `AngularVelocityTracker` |
| D-07, D-09 | Upright letters, commit cyclic rotation | Angle-parameterized `HexFlowerLayout.outerOffsets`, letter-keyed identity, `GameViewModel.rotateOuterLetters` |
| D-10, D-11 | Ticks + clicks, rate limited | `TickThrottle`, imperative `UIImpactFeedbackGenerator`, pooled tick players |
| D-12 | Full circle jackpot | `SpinSession` net-displacement predicate |
| D-13..D-17 | Grab, lock, shuffle cancel, word kept, active-state | `RingSpinController` state machine + GameView `performShuffle()` |
| D-18, D-19 | Reduce Motion, VoiceOver | Reduce Motion path in controller; no VO work |
| D-20 | Tutorial step | `TutorialStep.spin`, `TutorialAction.spin`, step count 9 -> 10 |
</phase_requirements>

## Summary

The phase is a presentation-layer physics feature with a small ViewModel hook (`rotateOuterLetters`). The entire design hinges on one decision: **make the ring angle a single source of truth in a `@MainActor @Observable RingSpinController`, driven by a `CADisplayLink`, whose angle is a pure function of time from a closed-form trajectory struct.** The pure trajectory (and velocity tracker, tick-crossing counter, throttle, settle-target chooser, jackpot predicate) are plain value types with injected time, unit-tested exactly like `EmptyDoubleTapDetector`. Everything impure (display link, haptics, sound, gesture glue) is thin.

The three highest-risk integration points, all verified in the repo: (1) the existing `.animation(GameTheme.shuffleAnimation, value: outerLetters)` plus `ForEach(..., id: \.offset)` would visibly animate/jump when the rotated order is committed; fix by keying tiles by letter and resetting the ring angle to 0 in the same transaction as the commit, so the commit is numerically a visual no-op. (2) The single `DragGesture` currently appends any tile the finger enters, so touches must be classified once at touch-down (tiles-mode vs spin-mode). (3) The tutorial adds a 10th step, which breaks hard-coded "9 steps" assertions in `TutorialCopyTests` and the UI test flow; these need updating in the same plan.

**Primary recommendation:** Implement `RingSpinTrajectory` (viscous + Coulomb friction decay, then critically damped settle to a computed target slot) + `RingSpinController` (CADisplayLink) + extend the one `DragGesture` with a per-touch mode; commit via a `onSpinSettled(slots:)` closure that `GameView` routes to `viewModel.rotateOuterLetters(by:)` (or `tutorial.send(.spin(slots:))`).

## Project Constraints (from CLAUDE.md)

- iOS only, SwiftUI, iOS 17 minimum (deployment target 17.6), MVVM with `@Observable`; no game engine, no third-party deps for this.
- No networking APIs (compliance-guards.sh Guard 1). Nothing here needs any.
- `Font.system(size:)` is only whitelisted in `HexTileView.swift` (compliance Guard); the new "Full circle!" popup and tutorial copy must use the semantic/scaled fonts (`GameTheme` fonts), not fixed sizes.
- Sounds: CC0 Kenney only, converted to 44.1 kHz mono 16-bit WAV, credited in `Sounds/LICENSE.txt`.
- GSD workflow: all edits go through GSD execute-phase; do not edit outside it.
- Memory: automate checkpoints where possible; device testing via the Wi-Fi install script `scripts/install-on-device.sh`.
- No project skills directory exists (`.claude/skills`, `.agents/skills` absent).

## Standard Stack

All first-party; no new packages.

| Framework | API | Purpose | Why |
|-----------|-----|---------|-----|
| SwiftUI | `DragGesture(minimumDistance: 0)` (existing) | Single recognizer, off-tile spin start | Phase 3 Pitfall 1; verified `DragGesture.Value` exposes `time`, `location`, `startLocation` (Apple docs) |
| QuartzCore | `CADisplayLink` | Per-frame angle + tick events | Need per-frame side effects (haptics/sound) that `TimelineView` closures cannot do cleanly |
| UIKit | `UIImpactFeedbackGenerator` (`impactOccurred(intensity:)`) | Per-tick haptic | Already used in `WordDisplayView`; imperative = no state-change/body-eval latency |
| UIKit | `UINotificationFeedbackGenerator` or `.sensoryFeedback(.success, trigger: counter)` | Jackpot haptic | Low frequency; counter-trigger pattern already used for length/sweep |
| AVFoundation | `AVAudioPlayer` pool | Tick click | Existing `SoundManager`; extend with a small round-robin pool |
| Swift Testing | `@Suite`, `@Test`, `#expect` | Unit tests | Existing convention (`EmptyDoubleTapDetectorTests`) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CADisplayLink | `TimelineView(.animation)` | Gets ProMotion cadence automatically but side effects (ticks) in the content closure are an anti-pattern; would need separate per-frame bookkeeping anyway |
| CADisplayLink | iOS 17 `CustomAnimation` | Elegant decay curve, but the SwiftUI-presented value is not readable for grab-to-stop or tick timing; rejected |
| Closed-form trajectory | Per-frame Euler integration | Frame-rate dependent, not exactly reproducible in tests, harder to hit exact end slot; rejected |
| Per-slot `.sensoryFeedback` | Imperative generator | `.sensoryFeedback` only fires after a state change is rendered; adds latency and is awkward at 20+/s; use only for jackpot/clunk if desired |
| `DragGesture.Value.velocity` | Own angular-velocity tracker | `velocity` is cartesian and (per the SDK swiftinterface) merely computed from `predictedEndLocation`, back-deployable via `@export(implementation)`; a tangential/angular estimate from timestamped samples is more accurate for a dial. Own tracker (~25 lines, testable) |

## Architecture Patterns

### Recommended Structure
```
WordPuzzle/WordPuzzle/Game/
├── RingSpin/                       (new folder; synchronized-folder project picks it up automatically)
│   ├── RingSpinTuning.swift        # all magic numbers in one struct (tune on device)
│   ├── RingSpinTrajectory.swift    # PURE: closed-form angle(at:)/velocity(at:)/duration/finalAngle
│   ├── SlotMath.swift              # PURE: detent index, crossings(from:to:), settleTarget, rotation k, array rotate
│   ├── AngularVelocityTracker.swift# PURE: timestamped samples -> signed rad/s, angle unwrapping
│   ├── TickThrottle.swift          # PURE: injected-time rate limiter (haptic + sound intervals, decimation)
│   ├── SpinSession.swift           # PURE: jackpot predicate (net displacement + home arrangement)
│   └── RingSpinController.swift    # @MainActor @Observable: state machine + CADisplayLink; events out via closure
├── Views/LetterGridView.swift      # extended: spin-zone gesture mode, angle-parameterized tile offsets
├── Views/HexFlowerLayout.swift     # + outerOffsets(radius:, rotation:), hitIndex math
└── Views/FullCircleView.swift      # jackpot popup (model on LengthCompletePill)
```

### Pattern 1: Gesture Architecture (one recognizer, per-touch mode)
**What:** Classify each touch ONCE, on its first `onChanged`, by hit-testing `value.startLocation`:
- `.tiles`: start hit a tile AND ring is at rest -> today's code path, byte-for-byte (tap appends at touch-down, no added latency).
- `.spin`: start off every tile (excluding the center tile's circle), OR ring currently moving (grab, D-13) -> never appends letters.
Store as `@State private var touchMode` reset in `onEnded` (and on cancel, see Pitfall 6).

Spin-mode rules:
1. Touch-down: if ring is moving, freeze it at its current angle immediately (grab-to-stop). Feed NOTHING to the double-tap detector for a grab touch (call `emptyTapDetector.reset()`); this keeps "first off-tile tap grabs the ring" (D-15) simple, and a double-tap shuffle only registers when the ring was at rest at touch-down.
2. Do not move the ring until travel from `startLocation` exceeds slop = `EmptyDoubleTapDetector.maxTapTravel` (10pt). On crossing, set the angular reference at the CURRENT point (prevents a 10pt visible jump). Record samples into `AngularVelocityTracker` from there.
3. Ring angle = angleAtGrab + unwrapped(atan2(touch - center) - atan2(refPoint - center)). Center = `flowerDiameter/2` in the "hexGrid" space (it is a fixed square, so no GeometryReader needed).
4. `onEnded`: if travel < slop: it is a tap -> existing `registerEmptyTap` path (unchanged); if the ring was grabbed, settle to nearest slot. If travel >= slop: `release(velocity:)`.
5. Ignore touches within the center tile's hit circle during a spin (radius < hexSize/2) since atan2 is unstable there.

**Hit-test change (recommended):** replace `TileFramePreferenceKey`/`onPreferenceChange` with pure math (`HexFlowerLayout.hitIndex(point:center:)` using slot positions at rest). Reason: with continuously changing tile offsets the `GeometryReader` preference fires every frame and writes `@State tileFrames` 60-120x/s for nothing. Touch classification only matters at rest (tiles-mode) or during spin (grab, any touch). Keep the existing `hitTest` circle (radius `hexSize/2`). Add a test in `HexGeometryTests`. (Only `LetterGridView` references the key, verified by grep; confirm before deleting.)

**Spin zone geometry:** keep layout size unchanged by enlarging only the hit area:
```swift
// Source: standard SwiftUI hit-area trick; VERIFY on device (Pitfall 5)
flowerContent                       // ZStack, frame(flowerDiameter), .coordinateSpace(name:)
  .padding(HexFlowerLayout.spinZoneMargin)     // e.g. 36pt (< GameTheme.xxl = 48 so it stays inside the Spacers)
  .contentShape(Rectangle())
  .gesture(spinAndTileDrag)
  .padding(-HexFlowerLayout.spinZoneMargin)    // layout footprint back to the original square
```
Locations stay in the "hexGrid" space because `coordinateSpace` is declared on the inner view; they can be negative or > diameter, which the math handles. Margin must not exceed the Spacer minLengths in `GameView` (`xxl` above the grid is 48; `xl` below it is smaller, so use a smaller bottom margin or clamp to `min(margin, available)`). The word display is above the `Spacer(minLength: xxl)`; the control row is below `Spacer(minLength: xl)`: check `GameTheme.xl` value and keep the margin below it. On narrow phones (375pt) keep `flowerDiameter + 2*margin <= screen width`; the hit rect may extend past the screen edge harmlessly.

### Pattern 2: Pure closed-form trajectory (physics)
**Model:** signed angular velocity w (rad/s); deceleration = k*|w| + c (viscous + Coulomb "dry" friction). Pure viscous decay never really stops (long creeping tail that feels dead); the constant term gives a prize-wheel tail.

Phase 1 (coast), with s = sign(w0), m = |w0|, A = m + c/k:
- `w(t) = s * (A*e^{-kt} - c/k)`
- `theta(t) = theta0 + s * ( A*(1 - e^{-kt})/k - (c/k)*t )`
- Hand off to settle when |w| <= w_h: `t_h = ln(A / (w_h + c/k)) / k` (if m <= w_h then t_h = 0).

Phase 2 (settle): critically damped spring toward target slot angle T (multiple of 60 deg) from (theta_h, v_h) with natural frequency L:
- `e(t) = (e0 + (v_h + L*e0)*t) * e^{-L t}`, `e0 = theta_h - T`; angle = `T + e(t)`.
- **No overshoot iff the target is chosen with `|e0| >= |v_h| / L`** (for the approach direction). Pure helper `settleTarget(angle:velocity:)` picks: if |v_h| < v_rest (~0.3 rad/s) the nearest slot either way; otherwise the first slot AHEAD in the direction of motion with `|e0| >= |v_h|/L + epsilon` (skipping one slot if the first is too close). This is the "gentle spring clunk with no bouncy overshoot" of D-06 and is deterministic and testable (monotonic non-overshooting property test).
- Settled when `|e| < 0.001 rad && |velocity| < 0.01` or t >= t_h + 6/L; then force angle = T exactly (float exactness matters for the commit, Pitfall 1).

**Starting constants (computed offline from the formulas; tune on device; keep in one `RingSpinTuning`):**
k = 0.55 /s, c = 0.35 rad/s^2, w_h = 1.5 rad/s, L = 10 /s, w_max (release clamp) = 24 rad/s, v_rest = 0.3 rad/s.

| Release w0 (rad/s) | ~rev/s | Coast to handoff | Total natural travel | Natural stop |
|---|---|---|---|---|
| 3 | 0.5 | 1.0 s | 0.55 rev | 3.2 s |
| 6 | 1.0 | 2.1 s | 1.3 rev | 4.3 s |
| 10 | 1.6 | 2.9 s | 2.4 rev | 5.1 s |
| 16 | 2.5 | 3.7 s | 4.0 rev | 5.9 s |
| 24 (cap) | 3.8 | 4.5 s | 6.3 rev | 6.6 s |

Continuous in w0 (satisfies D-05), flick of ~10 rad/s (about 1500pt/s at radius 150) already coasts 5+ s (counting the settle), and the clamp at 24 rad/s IS the max-duration cap (about 6.7 s total, so no separate timer cap is needed). The cap also means a jackpot (net > 5 rev) is only reachable by a max-strength flick or by re-flicking in one session. If it feels too short/long, change k (duration) and c (tail), not the structure.

**Reduce Motion (D-18):** release -> compute `settleTarget(angle, velocity: 0)` (nearest slot) and set angle to it immediately (instant snap; clunk haptic still plays). No coast. Honors the setting by not animating at all; if instant feels harsh on device, a 0.15 s ease is acceptable but is still motion, so prefer instant.

### Pattern 3: Display-link driver and the commit (no double-animate)
```swift
// Source: standard CADisplayLink usage; verify weak-target proxy compiles on Xcode 27 / Swift 6 mode
@MainActor @Observable
final class RingSpinController {
    private(set) var angle: Double = 0           // radians, positive = clockwise (SwiftUI y-down atan2 convention)
    private(set) var isActive = false            // tracking OR coasting OR settling  -> locks tiles (D-14)
    @ObservationIgnored var onEvent: ((RingSpinEvent) -> Void)?   // .tick(speedFraction), .clunk, .jackpot, .settled(slots: Int)
    // beginTracking(), track(angle:at:), release(velocity:), grab(), cancelAndSnap(), step(link:)
}
```
- The link callback computes `trajectory.angle(at: now - releaseTime)`, counts detent crossings since the last frame (`SlotMath.crossings(from:to:)`; handle >1 per frame), emits ticks through `TickThrottle`, assigns `angle`.
- `isActive` and `angle` must be set from the main actor; invalidate the link on settle, on `cancel`, and on `deinit`/scenePhase leaving `.active` (snap + commit). Use a weak proxy NSObject target for `CADisplayLink(target:selector:)` to avoid the retain cycle.
- ProMotion: an unconfigured `CADisplayLink` may be capped; `preferredFrameRateRange` and (on iPhone) the `CADisableMinimumFrameDurationOnPhone` Info.plist key govern >60 Hz for custom links (LOW confidence on exact behavior in current iOS; first cut at 60 Hz is acceptable because the angle is time-based, not frame-based, so it never "slows" at 60 Hz). Project uses a generated Info.plist; adding that key is an open question, not a blocker.

**Commit (D-09) without a visual jump:** at settle, in ONE synchronous main-actor pass: call `onEvent(.settled(slots: k))` (GameView rotates `outerLetters`) and set `angle = 0`. Because letter L moves from index i to (i+k) mod 6 and the ring had rotated L from slot(i) to slot(i)+k*60, the on-screen position is identical before and after IF tiles are keyed by letter identity. Current code uses `ForEach(Array(outerLetters.enumerated()), id: \.offset)`, i.e. keyed by slot index: committing would make each view's offset jump back by k slots while its glyph swaps, and the `.animation(GameTheme.shuffleAnimation, value: outerLetters)` modifier WOULD animate that (a visible spin-back). Therefore:
1. Change to `ForEach(outerLetters, id: \.self)` (letters are unique per puzzle: `Set<Character>` of 7 letters, verified in `GameViewModel`), offset = slot position of the letter's current index rotated by `angle`.
2. Wrap the commit in `withTransaction(Transaction(animation: nil))` / `disablesAnimations = true` as belt-and-braces.
3. Set the final angle to exactly `k * (pi/3)` before the commit so the reset is numerically exact.
Side effect (flag to user as an improvement): regular Shuffle now visibly slides tiles between slots (with the existing spring) instead of cross-fading glyphs in place, because identity now follows the letter. Check any UI test that relies on tile identity/accessibility ordering.

**Rotation direction/commit math:** slot index 0 = 12 o'clock, clockwise (`outerOffsets`). Positive (clockwise) rotation by k slots: `new[(i + k) mod 6] = old[i]`. Pure `SlotMath.rotated(_ letters:, by k:)` and `slotsMoved(finalAngle:) = Int((finalAngle / (pi/3)).rounded())` normalized with positive modulo (negative k for counter-clockwise).

### Pattern 4: Angular velocity from drag samples
- Keep a ring buffer of `(time: Date, angle: Double /*unwrapped*/)` from `value.time`.
- Unwrap each new atan2 sample against the previous (delta normalized into (-pi, pi]) so crossing +-pi never spikes.
- At release (use `onEnded` `value.time`): drop samples older than ~100 ms before release; if none remain (finger paused before lifting) -> w = 0 (settle, no coast); else `w = (last.angle - first.angle) / (last.time - first.time)` over >= 2 samples spanning >= ~16 ms; clamp to +-w_max; if |w| < v_rest treat as 0.
- Pure, injected-time, unit tested. Do not rely on `DragGesture.Value.velocity` (cartesian, derived from `predictedEndLocation`).

### Pattern 5: Tick feedback and rate limiting
- Detent index = `round(theta / 60deg)` (a tile is "passing a slot boundary" whenever the nearest-slot index changes, i.e. at the 30-deg midpoints; rest positions lie between pegs, like a prize-wheel clicker). Ticks fire in tracking and coast. The final settle plays the clunk (firmer `UIImpactFeedbackGenerator(.rigid)` or `.medium`, plus clunk sound) instead of a tick if the last detent change happens in the settle phase.
- Frequency: 6 detents/rev -> at w = 24 rad/s about 23 ticks/s (43 ms apart); at 10 rad/s about 10/s.
- `TickThrottle` (pure, injected time): minimum haptic interval ~45 ms, minimum sound interval ~55 ms; when instantaneous crossing rate exceeds ~18/s decimate (every 2nd tick) so it reads as a smooth whirr, not buzz. Scale intensity with speed (`impactOccurred(intensity: 0.4...0.8)`), softer at slow speeds. Re-call `prepare()` on the generator at spin start and every ~1 s while active.
- Haptic generators are imperative and held by the controller (or GameView); not gated by `soundEffectsEnabled` (that flag is sound only); the system Haptics setting applies automatically. Existing precedent: `WordDisplayView` uses `UIImpactFeedbackGenerator`.
- Sound: `SoundManager.play` does `stop(); currentTime = 0; play()` on ONE player per effect, which truncates overlapping clicks (acceptable only if the clip is very short). Add `case spinTick`, `spinClunk`, `fullCircle` to `SoundEffect`, and give `spinTick` a round-robin pool of ~4 `AVAudioPlayer`s (new `SoundManager.playTick(enabled:)`), so 20 ticks/s never cut each other off. Keep the `attemptedPlayCount`/`lastAttemptedEffect` test seam.
- Volume: Kenney tick clips are loud relative to ambient; apply `player.volume` ~0.5-0.7 scaled by speed.

### Pattern 6: Jackpot (D-12) tracking
- `SpinSession` starts at the first spin-mode movement/grab from REST (ring at a slot, record `preSpinOrder` implicitly as "slots = 0") and ends at settle. A re-grab and re-flick within the same coast stays the same session until settled.
- Predicate: `abs(netAngle) > 5 * 2*pi` AND `slotsMoved % 6 == 0`. Use NET signed displacement, not path length: path length lets a player farm it by wiggling back and forth; net displacement requires genuinely spinning one way. Since landing home forces net to a multiple of 360 deg, in practice it means >= 6 net revolutions landing home (about 1-in-6 of 5+ rev spins, as the user expected). Cosmetic only: fires `.jackpot` event; GameView shows `FullCircleView` + plays sound + success haptic; no `viewModel` scoring call.
- Reduce Motion: popup uses the existing opacity-only transition pattern (`GameView` lines ~235/239 branch on `reduceMotion`); no sparkle movement.
- Visual: model on `LengthCompletePill` (see `CompletionCelebrationViews.swift`), shown through the existing `celebrationOverlay` slot with `allowsHitTesting(false)`; ensure it does not queue behind/over the length/sweep celebration state machine (`activeCelebration`), or use its own small `@State`. Planner decides; simplest is its own state with a timed dismiss.

### Pattern 7: Tutorial integration (D-20)
Files: `TutorialStep.swift`, `TutorialController.swift`, `GameView.swift`, `LetterGridView.swift`, tests.
- `TutorialStep`: insert `case spin` after `.shuffle`; rawValues renumber to 1...10; `TutorialText.stepCount` derives automatically (10). **Existing tests hard-code 9** (`TutorialCopyTests` lines 25-28: count, order, `1...9`, "Step 3 of 9") and UI-SPEC says `tutorialStepCount = 9`: update both; also check `TutorialBannerViewTests`, `DynamicTypeTests`, `TutorialUITests` (step 6 shuffle flow at ~line 88 must continue to the new step).
- `TutorialAction`: add `case spin(slots: Int)`; `TutorialTarget`: add `.spinRing` (highlight drawn around the flower/spin zone via `tutorialHighlight(_, in: Circle())` on the grid; add a `highlightsRing: Bool` parameter to `LetterGridView`).
- `allows`: `.spin` returns true only on `.spin` and `.pangram` steps (and when not guided); on `.spin` step every other action false (strict filter, incl. `.shuffle` and `.letter`). `LetterGridView` must also receive `isSpinEnabled` so that off-tile drags in other strict steps do nothing (not just rejected at commit): GameView passes `tutorial.map { $0.allows(.spin(slots: 0)) } ?? true`, combined with `viewModel.roundPhase == .playing` (D-17).
- `send(.spin(slots:))`: `practice.rotateOuterLetters(by:)`, and `if step == .spin { step = .pangram; startHintTimer() }`. Move `step = .pangram; startHintTimer()` out of the `.shuffle` case into `.spin`; `.shuffle` success now sets `step = .spin`. Any settled spin counts, including net 0 slots (so commit/callback must fire even when k % 6 == 0).
- Copy (playful, matches existing tone; compact variant for AX): title "Give it a spin", full "Stuck? Flick the outer letters and watch them whirl.", compact "Flick the outer letters to spin them." Reuse `TutorialCopyTests` length/sentence rules (max 2 sentences). Also update the shuffle step's text? Not required.
- The practice board is a separate `GameViewModel(persistenceStore: nil)`, so `rotateOuterLetters` on it cannot persist anything.

### Pattern 8: GameView wiring (D-15, D-17)
- Controller owned by `GameView` as `@State private var ringSpin = RingSpinController()`, passed into `LetterGridView` (it is view state, not game state; `GameViewModel` remains the only model GameView touches). Alternative with the same effect: a `cancelToken: Int` binding; controller object is simpler.
- Introduce `private func performShuffle()` used by the Shuffle button, the background `onTapGesture(count: 2)`, and the grid's `onEmptyDoubleTap` (3 call sites today: ~lines 456, 480, 513): `ringSpin.cancelAndCommit()` (instant snap to nearest slot, fire `.settled` so the order is committed) THEN the existing `if let tutorial { tutorial.send(.shuffle) } else { viewModel.shuffleOuterLetters() }`. This resolves D-15 and the double-tap-mid-spin case uniformly (background double-tap outside the zone also cancels).
- `isInputDisabled: viewModel.isShuffling || ringSpin.isActive`.
- `onChange(of: viewModel.roundPhase)` (already exists): when `!= .playing`, `ringSpin.reset()` (angle 0, no commit). Also reset when `outerLetters` changes for any reason other than the commit (new round): `onChange(of: viewModel.outerLetters)` guarded by a controller `isCommitting` flag.
- Sheets (Stats/Settings/FoundWords) are presented over the board: add `ringSpin.cancelAndCommit()` when any sheet opens, or gate via the same `isSpinEnabled`; with a modal sheet, the grid receives no touches but a coast could still be running behind it. Simplest: cancel on sheet open (D-17).
- `GameViewModel.rotateOuterLetters(by k: Int) -> Bool`: `guard roundPhase == .playing, outerLetters.count == 6`; `outerLetters = SlotMath.rotated(...)`. Do NOT set `isShuffling` or bump `shuffleCount` (the shuffle haptic must not fire). Does not touch `currentWord` (D-16). Unit test in `GameViewModelTests` style.

### Anti-Patterns to Avoid
- **A second gesture recognizer** (`RotationGesture`, `.simultaneousGesture`, `onTapGesture` on the grid): Phase 3 Pitfall 1; taps get swallowed.
- **Per-frame Euler integration with `withAnimation`/`.animation` per frame**: fights the implicit animation and is frame-rate dependent.
- **Side effects inside `TimelineView` content / `body`** for haptics.
- **Reading `GeometryReader` frames for hit testing during spin.**
- **Using path length for the jackpot** (farmable by wiggling).
- **Rotating tiles with `.rotationEffect`** (glyphs rotate; also counter-rotation math gets fiddly). Compute offsets directly.
- **Setting the ring angle back to 0 with the implicit animation active** while tiles are index-keyed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Double-tap on empty space | A new timer/gesture | Existing `EmptyDoubleTapDetector` (fed only by no-travel taps) | Already tested; already rejects >10pt travel |
| Hit testing circle | New polygon test | Existing `HexFlowerLayout.hitTest` | Phase 3 Pitfall 4 |
| Celebration popup | New overlay system | Pattern of `LengthCompletePill` + `celebrationOverlay` | Reduce-Motion branches already handled |
| Sound playback/gating | New audio engine | `SoundManager` + a small pool extension | `.ambient` + enabled-flag + test seam already present |
| Counter-triggered haptics | Bool triggers | `.sensoryFeedback(..., trigger: counter)` for low-frequency events | Project convention |
| Tutorial gating | A parallel gate | `TutorialController.allows` | Single source of strict-step truth |
| Rotation math | Trig inline in views | `SlotMath`/`HexFlowerLayout` pure helpers | Unit-testable |

**Key insight:** the physics is deceptively fiddly at the seams (angle wrap, exact slot landing, tick counting across frames, commit continuity); making each seam a pure, tested function keeps the device-tuning loop limited to constants.

## Runtime State Inventory

Not a rename/refactor/migration phase. Skipped. (One note: no persisted state is added; spin angle/session are in-memory only; `outerLetters` already is in-memory and not persisted.)

## Common Pitfalls

### Pitfall 1: Commit "spins back" or double-animates
**What goes wrong:** Tiles keyed by `\.offset` + `.animation(value: outerLetters)` animate the angle reset.
**Why:** The commit changes both letters and the angle in one transaction.
**Avoid:** Letter-keyed identity, exact final angle `k*pi/3`, angle reset in the same pass, animation-disabled transaction.
**Warning signs:** a brief backward slide or a glyph crossfade at the landing moment (check frame by frame on device with screen recording).

### Pitfall 2: Tile-tap regressions
**What goes wrong:** Adding spin logic before the tile path delays or swallows tile taps.
**Avoid:** Classify the touch on first `onChanged` with a pure hit test (O(7)); the tiles-mode branch must remain identical to the current code; do not add `minimumDistance` > 0 or `highPriorityGesture`. Keep `emptyTapDetector.reset()` on tile hits. Check an existing UI test for tap latency/behavior still passes.

### Pitfall 3: Ring moves for a tap / jump at slop
Do not move on touches under 10pt; set the angular reference at slop crossing, not at touch-down.

### Pitfall 4: Spurious/zero velocity
Finger paused then lifted must NOT coast (stale-sample check against the `onEnded` time). Angle wrap at +-pi must not spike velocity (unwrap).

### Pitfall 5: Hit area outside parent bounds
`padding(m).contentShape(Rectangle()).gesture(...).padding(-m)` expands the hit region beyond the layout frame; confirm on device and in a UI test that touches in the margin start a spin and that margin does not steal touches from the word display/Delete/Shuffle (keep margin < the Spacer minLengths: `xxl` = 48 above the grid; verify `xl` below).

### Pitfall 6: Cancelled gesture leaves the ring stuck
SwiftUI can cancel a drag (system gesture, sheet, app switch) without `onEnded`. Use `@GestureState` (resets automatically) and observe its falling edge to call the same release/settle path; also settle on `scenePhase != .active`. The existing `lastTouchedIndex` has the same latent weakness; reset it there too.

### Pitfall 7: Tick buzz / clipped audio
At >20 ticks/s: throttle + decimate (haptics) and round-robin pool (sound). Never `stop()`/restart a single player per tick.

### Pitfall 8: Timer leaks and lifecycle
Invalidate the display link on settle/cancel/deinit/background; a running link on a non-playing screen wastes battery and keeps ticking haptics.

### Pitfall 9: Tutorial strict-step bypass
If the grid enables spin during other strict steps, `.spin` would start physically even though `allows` rejects the commit; pass `isSpinEnabled` into the grid (see Pattern 7). Also remember the strict `.shuffle` step no longer advances to `.pangram`.

### Pitfall 10: Floating-point landing
Compare slots with tolerances in tests; but in production force the exact final angle at settle so tiles sit exactly at `HexFlowerLayout` positions (D-06) and the hit test lines up.

## Code Examples

### Angle-parameterized layout (extend `HexFlowerLayout`)
```swift
static func outerOffsets(radius: CGFloat = GameTheme.outerRingRadius, rotation: Angle = .zero) -> [CGSize] {
    (0..<6).map { i in
        let a = Angle(degrees: Double(i) * 60 - 90).radians + rotation.radians
        return CGSize(width: radius * cos(a), height: radius * sin(a))
    }
}
```
The existing zero-rotation behavior (and `HexGeometryTests`) must be unchanged (default argument).

### Detent crossing counter (pure)
```swift
enum SlotMath {
    static let slot = Double.pi / 3
    static func detent(_ angle: Double) -> Int { Int((angle / slot).rounded()) }
    /// Number of detent changes between two unwrapped angles (signed direction not needed for ticks).
    static func crossings(from a: Double, to b: Double) -> Int { abs(detent(b) - detent(a)) }
    static func slotsMoved(finalAngle: Double) -> Int { detent(finalAngle) }   // signed; normalize with ((n % 6) + 6) % 6 for rotation
}
```

### Trajectory skeleton (pure)
```swift
struct RingSpinTrajectory {
    let theta0: Double, w0: Double        // rad, rad/s (signed)
    let tuning: RingSpinTuning
    // derived once in init: s, A, handoffTime, handoffAngle, handoffVelocity, target, duration
    func angle(at t: TimeInterval) -> Double { /* phase 1 closed form, then critically damped to `target` */ }
    func velocity(at t: TimeInterval) -> Double { /* derivative */ }
    var finalAngle: Double { target }      // exact multiple of pi/3
    var duration: TimeInterval { handoffTime + tuning.settleDuration }
}
```

### Gesture classification skeleton (inside the existing single DragGesture)
```swift
.onChanged { value in
    if touchMode == .undecided {
        let startOnTile = hitIndex(at: value.startLocation) != nil
        touchMode = (ringSpin.isActive || !startOnTile) && isSpinEnabled ? .spin : .tiles
        if touchMode == .spin { ringSpin.grabIfMoving(); emptyTapDetector.reset() /* only when it was moving */ }
    }
    if touchMode == .spin { ringSpin.track(point: value.location, startedAt: value.startLocation, time: value.time, center: center); return }
    /* ... existing tiles-mode body unchanged ... */
}
.onEnded { value in
    defer { touchMode = .undecided; lastTouchedIndex = nil }
    if touchMode == .spin, ringSpin.didExceedSlop { ringSpin.release(at: value.time); return }
    if touchMode == .spin { ringSpin.releaseWithoutTravel() }   // settle if it was grabbed
    /* existing empty-tap / detector path unchanged */
}
```
(A drag that starts off-tile and wanders over a tile no longer types it; this is the intended D-02 consequence and a behavior change from today where any entered tile appended.)

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `ObservableObject`/`@Published` | `@Observable` (iOS 17) | Controller reads only `angle`/`isActive` in the grid body; per-frame updates re-render just that view |
| `DragGesture.Value.velocity` | Available (computed from `predictedEndLocation`, back-deployed) | Usable but coarse for rotation; own angular tracker preferred |
| `UIFeedbackGenerator` only | `.sensoryFeedback` (iOS 17) | Use sensoryFeedback for low-frequency events; imperative generators for the high-rate ticks |

## Open Questions

1. **ProMotion cadence for `CADisplayLink` on iPhone** (needs `CADisableMinimumFrameDurationOnPhone`?). Recommendation: ship at the default cadence; the angle is time-based, so 60 Hz still looks right. Revisit only if on-device feel is steppy.
2. **Final friction constants.** Table above is computed, not felt. Plan a dedicated on-device tuning task (checkpoint) with constants isolated in `RingSpinTuning`; consider a DEBUG-only slider or launch argument.
3. **Which Kenney clips.** Candidates from the Kenney "Interface Sounds" pack (same pack as existing clips): tick/click family for `spinTick` (`tick_001`/`click_00x`; `sweep_tick` already uses `tick_002`, so choose a different, softer one), a lower "drop/bong/close" clip for the clunk, a short bright confirmation/maximize clip for "Full circle!". Audition on device. Not verified here (LOW).
4. **Audio conversion tooling.** The Kenney pack ships OGG; `afconvert` (present) cannot read Ogg Vorbis and `ffmpeg`/`sox` are NOT installed. Plan: `brew install ffmpeg` (brew present) then `ffmpeg -i in.ogg -ar 44100 -ac 1 -sample_fmt s16 out.wav`; update `Sounds/LICENSE.txt` source map. Alternative fallback with no conversion: reuse `sweep_tick.wav` for the tick temporarily.
5. **Touch on a tile while the ring is moving.** CONTEXT D-13 says off-tile touch grabs; D-14 says tiles locked. Recommended interpretation: during motion ANY touch (except the stationary center tile) grabs the ring and never types, since tiles are moving targets. Confirm with user if desired.
6. **Spin through sheets/background.** Recommended: cancel+commit when a sheet opens or the scene leaves active.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | build/test | yes | 27.0 | none needed |
| iOS Simulators | unit/UI tests | yes | iPhone 17 Pro / 17e booted | none |
| Physical iPhone + `scripts/install-on-device.sh` | feel + haptics verification | not probed here (device/pairing state unknown) | n/a | Simulator cannot produce haptics or judge feel; manual checkpoint required |
| ffmpeg | OGG -> WAV for Kenney clips | no | n/a | `brew install ffmpeg` (brew at /opt/homebrew/bin/brew), or reuse `sweep_tick.wav` |
| afconvert | WAV re-encode | yes | system | n/a |
| python3 | helper scripts | yes | 3.11 | n/a |

**Missing with fallback:** ffmpeg (install via brew).
**Blocking:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Suite`/`@Test`/`#expect`), XCUITest for UI |
| Config file | Xcode project, unit target `WordPuzzleTests`, UI target `WordPuzzleUITests` (file-system-synchronized groups; new files auto-included) |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/RingSpinTrajectoryTests -only-testing:WordPuzzleTests/SlotMathTests` (run once from repo root to confirm scheme name) |
| Full suite command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` plus `bash scripts/compliance-guards.sh` |

### Phase Requirements -> Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| D-04/D-05 | angle/velocity continuity at handoff; duration monotonic in w0; w0=cap total >= 5 s; w0 small -> short; sign symmetry | unit | `-only-testing:WordPuzzleTests/RingSpinTrajectoryTests` | Wave 0 |
| D-06 | final angle is an exact multiple of pi/3; sampled angle never overshoots target (monotone); settleTarget ahead-distance >= v/L | unit | same | Wave 0 |
| D-04 | velocity tracker: unwrap across +-pi, stale-sample -> 0, clamp, direction sign | unit | `-only-testing:WordPuzzleTests/AngularVelocityTrackerTests` | Wave 0 |
| D-10/D-11 | detent crossings across frames (including multi-crossing); TickThrottle min interval + decimation with injected time | unit | `-only-testing:WordPuzzleTests/SlotMathTests` / `TickThrottleTests` | Wave 0 |
| D-07/D-09 | `outerOffsets(rotation:)` zero == old; k*60 rotation equals shifted slots; `rotated(by:)` letter mapping for +-k; commit continuity (position of letter before == after) | unit | `HexGeometryTests` additions + `SlotMathTests` | Extend existing |
| D-12 | jackpot predicate: net > 5 rev AND slots%6==0; wiggle path length does not qualify; < 5 rev no; counter-clockwise too | unit | `SpinSessionTests` | Wave 0 |
| D-09/D-16/D-17 | `rotateOuterLetters`: only in `.playing`, preserves `currentWord`, does not bump `shuffleCount`/`isShuffling` | unit | `GameViewModelTests` additions | Extend |
| D-01..D-03 | hit classification at rest: tile -> tiles mode; gap/corner/margin -> spin; center circle excluded | unit (pure helper) | `HexGeometryTests` | Extend |
| D-11 | `SoundEffect.allCases.count`, all files bundled, enabled gate for new effects | unit | `SoundManagerTests` (update count 7 -> 10; `testAllEffectsAreBundled` needs WAVs) | Extend |
| D-20 | step count 10, order, copy sentence/AX compact, `allows(.spin)` per step, `.shuffle` -> `.spin` -> `.pangram`, spin of 0 slots advances | unit | `TutorialCopyTests`, `TutorialControllerTests` (update the hard-coded 9) | Extend |
| D-01/D-13/D-14 | UI: off-tile drag in margin rotates ring (letters change order after settle); tile tap latency path unaffected; Shuffle mid-spin | UI (flick via `XCUICoordinate.press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)`) | `TutorialUITests`/`WordPuzzleUITests` additions | Extend |
| D-05, D-06, D-10, D-11, D-12, D-18 | Feel: smoothness, coast length, tick/clunk, jackpot, Reduce Motion | manual on device | `scripts/install-on-device.sh` | manual-only (haptics/audio/feel cannot be automated) |

### Sampling Rate
- **Per task commit:** the quick run command for the touched pure-helper suites (< 30 s).
- **Per wave merge:** full unit suite + `scripts/compliance-guards.sh`.
- **Phase gate:** full suite green, UI tests for tutorial flow updated and green, then the on-device feel checkpoint.

### Wave 0 Gaps
- [ ] `WordPuzzleTests/RingSpinTrajectoryTests.swift` (D-04/05/06)
- [ ] `WordPuzzleTests/SlotMathTests.swift` (crossings, rotate, settleTarget)
- [ ] `WordPuzzleTests/AngularVelocityTrackerTests.swift`
- [ ] `WordPuzzleTests/TickThrottleTests.swift`
- [ ] `WordPuzzleTests/SpinSessionTests.swift`
- [ ] Update `TutorialCopyTests` (9 -> 10, order array, "Step N of 10"), `TutorialControllerTests`, `SoundManagerTests` (count), `TutorialUITests` shuffle flow
- No framework install needed.

## Sources

### Primary (HIGH confidence)
- Repo code read directly: `LetterGridView.swift`, `HexFlowerLayout.swift`, `EmptyDoubleTapDetector.swift`, `SoundManager.swift`, `TutorialStep.swift`, `TutorialController.swift`, `GameView.swift` (lines ~160-215, 420-530), `GameViewModel.swift` (shuffle), `HexTileView.swift`, tests (`TutorialCopyTests`, `SoundManagerTests`, `EmptyDoubleTapDetectorTests`), `Sounds/LICENSE.txt`, `scripts/compliance-guards.sh`, project deployment target (17.6).
- Apple docs, DragGesture.Value (https://developer.apple.com/documentation/swiftui/draggesture/value.md): `time`, `location`, `startLocation`, `predictedEndLocation`, `velocity`.
- iOS SDK `SwiftUI.swiftinterface` (local Xcode 27): `DragGesture.Value.velocity` is an `@export(implementation)` computed from `predictedEndLocation` (so it back-deploys, but is derived/cartesian).

### Secondary (MEDIUM confidence)
- Closed-form friction/critically-damped-spring math: standard mechanics; numeric table computed with a local script (python3) from the formulas above.

### Tertiary (LOW confidence, validate on device)
- `CADisplayLink` ProMotion/Info.plist-key behavior on current iOS.
- Specific Kenney clip choices and the exact haptic intensities.
- Hit-area-outside-bounds behavior of the `padding(m)...padding(-m)` trick (widely used; verify).
- All physics constants (feel).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, first-party APIs already used in the repo.
- Architecture: MEDIUM-HIGH, integration hazards verified against the actual source; constants and hit-area trick need device confirmation.
- Pitfalls: HIGH for code-derived ones (commit identity, hard-coded test counts, single-recognizer), MEDIUM for platform-behavior ones.

**Research date:** 2026-10-05
**Valid until:** 2026-11-05 (stable platform APIs; constants are tuning, not research)
