# Phase 10: Double-Tap Shuffle - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI gesture composition (tap vs. DragGesture), haptics, view-model shuffle contract
**Confidence:** MEDIUM (code facts HIGH; SwiftUI gesture-precedence behavior MEDIUM, needs on-device confirmation, same caveat as Phase 3)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Trigger is a double-tap on empty space, NOT on a tile (locked in ROADMAP — double-tapping a tile still appends that letter twice).
- **D-02:** Gaps and corners inside `LetterGridView`'s flower-diameter square that are not on a tile COUNT as empty. Today the grid's `DragGesture(minimumDistance: 0)` captures those touches and no-ops (`hitIndex` returns nil); the implementation must let non-tile double-taps there trigger shuffle without breaking tile tap/drag input.
- **D-03:** All background area not covered by a control counts — top padding, spacers above/below the word display and grid, horizontal margins. No "near the grid only" restriction.
- **D-04:** The word display (`WordDisplayView`) is EXCLUDED — single-tap there clears the word and swipe-down submits; double-tap there must not shuffle.
- **D-05:** Buttons (stats, settings, debug menu, score bar, Shuffle, Delete, Finish Round) keep their own behavior; double-tapping them does not shuffle.
- **D-06:** Shuffle button stays exactly as-is. Gesture is additive.
- **D-07:** No custom VoiceOver accessibility action — the labeled "Shuffle Letters" button is the VoiceOver path.
- **D-08:** Add a light impact haptic on EVERY shuffle — both the button and the gesture paths. Follow the project's existing counter-trigger `.sensoryFeedback` pattern. Only fire when a shuffle actually happens (not when the `isShuffling` guard rejects it).
- **D-09:** No sound effect for shuffle.
- **D-10:** Gesture is active only during `.playing`. Inert during `.roundOver`, paywall, and while Stats/Settings/Found Words sheets are presented.
- **D-11:** The in-progress word is preserved on shuffle.
- **D-12:** Gesture works during celebration overlays (overlay is `allowsHitTesting(false)`).
- **D-13:** Rapid repeated double-taps during the 400ms shuffle animation are ignored via the existing `isShuffling` guard.

### Claude's Discretion
- Gesture composition approach; must respect Phase 3 Pitfall 1 and not regress tile tap latency.
- Whether "tile tap followed by gap tap" within the double-tap window counts (preferred: no).
- Haptic intensity (`.impact(weight: .light)` or equivalent).
- Test strategy.

### Deferred Ideas (OUT OF SCOPE)
- One-time "double-tap to shuffle" hint — Phase 12.
</user_constraints>

<phase_requirements>
## Phase Requirements

No IDs mapped (TBD). Relates to PUZZ-04 (shuffle). Research supports: shuffle contract change (Bool return + counter), gesture composition, haptic, tests.
</phase_requirements>

## Summary

Everything is native SwiftUI; no new libraries. The work touches four spots: `GameViewModel.shuffleOuterLetters()` (report success, gate on `.playing`, bump a monotonic counter), `LetterGridView` (new `onEmptyDoubleTap` callback + non-tile double-tap detection), `GameView.playingLayout` (background double-tap for everywhere else, haptic modifier), and a small pure value type for double-tap detection (unit-testable).

Key code facts found. (1) `HexTileView` applies `.contentShape(HexagonShape())`, and the grid ZStack has only a `.frame` (no `contentShape`). So the grid gesture's hit region is the union of the six-plus-one hexagons; the true gaps between hexagons and the square's corners are probably NOT hit-testable today, so those touches likely already fall through to whatever is behind the grid (context's claim that the DragGesture "captures" them is only certainly true for the hexagon corners that lie outside the inscribed hit-circle, where `hitIndex` returns nil). This is MEDIUM confidence and must be confirmed on device; the recommended design is correct under either reading. (2) `shuffleOuterLetters()` has no `roundPhase` guard and `playingLayout` is also rendered while `.roundOver` (under the fullScreenCover), so D-10 needs an explicit guard. (3) Tests use Swift Testing (`import Testing`, `@Suite struct`, `@Test`, `#expect`), `@testable import WordPuzzle`; deployment target 17.6, Swift 5 mode.

**Primary recommendation:** Hybrid composition. (a) Inside `LetterGridView`, keep the single `DragGesture(minimumDistance: 0)` and add double-tap detection in `.onEnded` using a pure `EmptyDoubleTapDetector` (only taps that started and ended off-tile with tiny travel count; any tile touch or drag resets it); add `.contentShape(Rectangle())` on the grid ZStack so the whole square is owned by this one recognizer. (b) On `GameView.playingLayout`, add `.contentShape(Rectangle()).onTapGesture(count: 2) { performShuffle() }` for all remaining background. Both call one `performShuffle()` in GameView that is gated on `.playing`. Haptic via a view-model monotonic `shuffleCount` and one `.sensoryFeedback(.impact(weight: .light), trigger: viewModel.shuffleCount)`.

## Standard Stack

No new dependencies. All Apple SDK.

| API | Availability | Purpose |
|-----|--------------|---------|
| `View.onTapGesture(count: 2)` | iOS 13+ | Background double-tap on playingLayout |
| `DragGesture.Value.time / startLocation / location / translation` | iOS 13+ (`time` is a `Date`) | Timestamp + positions for detector inside existing grid gesture |
| `.sensoryFeedback(.impact(weight: .light), trigger:)` | iOS 17+ (target is 17.6, OK) | D-08 haptic, counter-trigger |
| Swift Testing | Xcode 16+ (already used) | Unit tests |

Test run (verified a booted simulator exists: iPhone 17 Pro):
`xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/<Suite>` (confirm scheme name in Wave 0; check how prior phases invoked it in their SUMMARY files).

## Architecture Patterns

### Why hybrid (answers Q1, Q2)

Option A: only background `onTapGesture(count: 2)` on the layout. Simple, but tile-region touches belong to the child DragGesture. If the grid gesture region (hexagon corners outside the hit circle) captures a touch, the parent never sees it, so D-02 corners would fail; and relying on parent-vs-child precedence for a min-distance-0 drag is exactly the Phase 3 Pitfall 1 area.

Option B: only grid-internal detection. Does not cover the rest of the screen (D-03).

Option C (contentShape tricks to make gaps fall through): fragile; gaps are already (probably) non-hit-testable, and the hexagon corners are inside tile shapes by design.

Hybrid covers both: the grid square (made fully hit-testable with `.contentShape(Rectangle())`) is handled by the one recognizer already there; everything outside it is handled by the parent. Touches in the grid square never reach the parent's tap recognizer (child gesture wins; min-distance-0 drag begins at touch-down), so no double-firing; and even if they did, `isShuffling` (D-13) plus the "count only real shuffles" haptic make a duplicate harmless. Do NOT add `simultaneousGesture(TapGesture(count: 2))` on tiles: Pitfall 1 says avoid extra recognizers on the grid, and a multi-tap recognizer in the same hierarchy is the main way tile latency could regress.

Gesture precedence facts (MEDIUM, official docs state child-over-parent for `gesture`; the exact min-distance-0 interplay is community knowledge, verify on device):
- Child gestures take precedence over a parent's `.gesture`/`.onTapGesture`. Buttons (stats, settings, score bar, Shuffle, Delete, Finish Round, debug Menu) and WordDisplayView's `.onTapGesture`/`DragGesture(minimumDistance: 10)` therefore win over the parent's double-tap. A double-tap on WordDisplayView fires two single taps = `onClear()` twice, no shuffle (D-04 satisfied without extra code).
- A parent `onTapGesture(count: 2)` does NOT delay a child Button's single tap: the child gesture has priority, the parent only recognizes if the child does not claim the touch. Buttons respond immediately. No ScrollView exists in playingLayout (ScrollViews live inside sheets, which are separate presentation contexts), so no scroll interference. Confirm Button tap latency by feel on device.
- Hit-testing: a background/ancestor gesture needs a hit-testable area. A `VStack` with `Spacer`s and padding is NOT hit-testable in empty areas. Add `.contentShape(Rectangle())` on the VStack BEFORE `.onTapGesture(count: 2)`. Also the outer ZStack applies `GameTheme.dominant.ignoresSafeArea()` as a sibling; the VStack respects safe area, so touches in the safe-area inset strips (above status bar / home indicator) will not count. Acceptable (D-03 says "background not covered by a control"); if desired attach the gesture to the outer ZStack case `.playing, .roundOver` branch instead. Recommend attaching to `playingLayout` only; mention in plan as minor.
- The celebration overlay is `.allowsHitTesting(false)`, so touches pass through it to the grid/parent (D-12).

### Detector (pure, testable) — answers Q4

```swift
// Game/DoubleTapDetector.swift (name flexible)
import CoreGraphics
import Foundation

/// Decides whether two consecutive "empty-space" taps form a double-tap.
/// Pure value type: time and positions are injected, so it is deterministic in unit tests.
struct EmptyDoubleTapDetector {
    var maxInterval: TimeInterval = 0.3      // discretion; UIKit/iOS system double-tap feel is ~0.3-0.35s
    var maxTapTravel: CGFloat = 10           // a "tap" moved less than this between touch-down and up
    var maxSeparation: CGFloat = 44          // two taps must land within one tap target of each other

    private var last: (time: Date, point: CGPoint)?

    /// Call on touch end when the touch began AND ended off every tile.
    /// Returns true exactly when this tap completes a double-tap.
    mutating func registerEmptyTap(start: CGPoint, end: CGPoint, at time: Date) -> Bool {
        guard hypot(end.x - start.x, end.y - start.y) < maxTapTravel else { last = nil; return false }
        if let prev = last,
           time.timeIntervalSince(prev.time) <= maxInterval,
           hypot(end.x - prev.point.x, end.y - prev.point.y) <= maxSeparation {
            last = nil          // a triple-tap must not fire twice in a row
            return true
        }
        last = (time, end)
        return false
    }

    /// Call for any tile touch or drag so "tile tap then gap tap" never counts (CONTEXT discretion).
    mutating func reset() { last = nil }
}
```

Grid integration (keeps ONE recognizer; `@State private var detector = EmptyDoubleTapDetector()`):

```swift
.contentShape(Rectangle())            // whole flower square is hit-testable (D-02)
.gesture(
    DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
        .onChanged { value in
            guard !isInputDisabled else { return }
            guard let index = hitIndex(at: value.location) else { return }
            detector.reset()                       // any tile touch breaks a double-tap chain
            guard index != lastTouchedIndex else { return }
            lastTouchedIndex = index
            onLetterTouched(letter(forIndex: index))
        }
        .onEnded { value in
            defer { lastTouchedIndex = nil }
            // Off-tile at both touch-down and touch-up, tiny travel -> an empty tap.
            if hitIndex(at: value.startLocation) == nil, hitIndex(at: value.location) == nil {
                if detector.registerEmptyTap(start: value.startLocation, end: value.location, at: value.time) {
                    onEmptyDoubleTap()
                }
            } else {
                detector.reset()
            }
        }
)
```

Notes: `onChanged` fires at touch-down with `value.location == startLocation`, so a tile touch resets the detector at down. `isInputDisabled` (shuffling) early-returns before reset in `onChanged`; that is fine because during shuffle `shuffleOuterLetters()` rejects anyway. Add `let onEmptyDoubleTap: () -> Void` as a new init parameter and update the `#Preview` and any other call sites (grep `LetterGridView(`).

Stale frames (Phase 3 Pitfall 2): while shuffling, `tileFrames` may lag; an empty-tap classification could be wrong, but shuffles are rejected during `isShuffling` anyway, and the detector resets on tile touches. A double-tap that straddles the end of the 400ms animation is the only exposure; negligible.

Time source: `DragGesture.Value.time` is a `Date` (event time). Use it rather than `Date()` so scheduling jitter does not matter.

### View-model contract — answers Q3 and Q5

```swift
// GameViewModel
/// Monotonic; bumped only when a shuffle actually happens (D-08). Not reset per round.
private(set) var shuffleCount: Int = 0

@discardableResult
func shuffleOuterLetters() -> Bool {
    guard roundPhase == .playing, outerLetters.count > 1, !isShuffling else { return false }  // D-10, D-13
    var shuffled = outerLetters
    repeat { shuffled.shuffle() } while shuffled == outerLetters
    outerLetters = shuffled
    isShuffling = true
    shuffleCount += 1
    Task { @MainActor [weak self] in ... }   // unchanged
    return true
}
```

Haptic (GameView, next to the existing `.sensoryFeedback(.success, ...)` lines):
`.sensoryFeedback(.impact(weight: .light), trigger: viewModel.shuffleCount)`.
Because the trigger is the view-model counter, both the button and the gesture share one haptic path with no duplication and it fires only on real shuffles. The button and gesture both just call `viewModel.shuffleOuterLetters()`. Existing test `testShufflePreservesLetterSetExcludesCenter` (GameViewModelTests ~line 159) must still pass: check it starts a round (so phase is `.playing`) before shuffling; if it shuffles with no puzzle, `outerLetters.count > 1` already fails, so it must be in `.playing`. Check any test shuffling in other phases when adding the `roundPhase` guard.

Gating on `.playing` (D-10): VM guard above is the authority. Additionally in GameView gate the gesture closure to avoid dead work: `{ if viewModel.roundPhase == .playing { viewModel.shuffleOuterLetters() } }` is optional; the VM guard suffices. Sheets (Stats, Settings, Found Words) and the fullScreenCover are modal presentations and block touches to the underlying view; no extra flag needed. Do not add `isShowing*` checks. `.roundOver` and `.paywalled` states: playingLayout is rendered behind the cover only for `.roundOver`; the VM guard covers it.

GameView wiring:
```swift
LetterGridView(..., onLetterTouched: { viewModel.append($0) },
               onEmptyDoubleTap: { viewModel.shuffleOuterLetters() })
...
// on playingLayout's VStack (after its last child, before the closing of the property):
.contentShape(Rectangle())
.onTapGesture(count: 2) { viewModel.shuffleOuterLetters() }
```
Order matters: `contentShape` must precede `onTapGesture`.

### Anti-Patterns to Avoid
- Per-tile or grid-level `TapGesture(count: 2)` / `simultaneousGesture` recognizers (Pitfall 1; risk of latency or swallowed taps).
- Using a Bool haptic trigger (Pitfall 3) or firing the haptic in the button/gesture closure unconditionally (violates D-08 "only when shuffle happens").
- Using wall-clock `Date()` in the detector (untestable).
- Putting the double-tap on `WordDisplayView` or adding exclusion hacks; child priority handles D-04/D-05.
- Adding `.onTapGesture(count: 2)` to a container that also hosts a ScrollView (none here, but do not move the gesture onto sheets).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic | `UIImpactFeedbackGenerator` call sites | `.sensoryFeedback(.impact(weight:.light), trigger: counter)` | Project pattern (D-08), declarative, counter semantic |
| Outside-grid double-tap | Custom UIKit recognizer / UIViewRepresentable | `onTapGesture(count: 2)` | Native, child-priority semantics handle buttons for free |
| Tile hit-testing | New geometry | Existing `hitIndex(at:)` / `HexFlowerLayout.hitTest` | Already correct and tested |

## Common Pitfalls

### Pitfall 1: Empty parent areas not hit-testable
**What goes wrong:** Double-tap on spacers/margins does nothing. **Why:** `VStack`/`Spacer` have no hit area. **Avoid:** `.contentShape(Rectangle())` before `.onTapGesture`. **Detect:** on-device test in top-padding, between word display and grid, left/right margins.

### Pitfall 2: Grid gaps assumed to be "captured" (or assumed to fall through)
**What goes wrong:** Either assumption can be wrong (tiles have `contentShape(HexagonShape())`, grid has none). **Avoid:** `.contentShape(Rectangle())` on the grid ZStack so the behavior is deterministic and owned by the grid's detector. **Detect:** double-tap in a gap between tiles, a square corner, and a hexagon corner outside the inscribed circle: all must shuffle.

### Pitfall 3: Tile double-tap shuffles
**What goes wrong:** Tap on tile twice shuffles instead of typing letter twice. **Avoid:** detector only counts taps whose start AND end are off-tile; tile touch resets. Test: tile-tile quick taps = 2 appended letters, no shuffle. Also tile tap then gap tap = no shuffle.

### Pitfall 4: Tile latency regression
**What goes wrong:** Adding a multi-tap recognizer over tiles makes SwiftUI wait to disambiguate. **Avoid:** no new recognizer on the grid; detector runs in `.onEnded` only. Verify tile taps append at touch-down as before.

### Pitfall 5: Double haptic or haptic on rejected shuffle
**Avoid:** single counter in VM, increments only on `return true` path; do not also add a haptic to the button. Rapid double-taps in 400ms yield one haptic.

### Pitfall 6: `.roundOver` layout still live
`playingLayout` renders in `.roundOver` (under the cover). The VM `.playing` guard is mandatory; do not rely on view structure.

### Pitfall 7: Drag that ends off-tile counted as tap
A swipe starting in a gap and ending in a gap with travel > 10pt must not count; the detector's `maxTapTravel` check handles it.

## Code Examples
See Detector, Grid integration, View-model contract and GameView wiring above (project code, verified against current files).

## State of the Art

| Old | Current | Impact |
|-----|---------|--------|
| `UIImpactFeedbackGenerator` | `.sensoryFeedback` (iOS 17) | Already the project pattern for success haptics; WordDisplayView still uses UIKit generators for rejection bursts (leave alone) |
| `ObservableObject` | `@Observable` | `shuffleCount` on the `@Observable` VM is observed automatically by `.sensoryFeedback(trigger:)` |

## Open Questions

1. **Are inter-tile gaps hit-testable today?** Likely not (no grid `contentShape`), contradicting CONTEXT's wording; design is robust either way. Confirm on device after adding `contentShape(Rectangle())`.
2. **Does the parent double-tap ever fire for touches inside the grid square?** Expected no. If it does, it is harmless (guarded) except it could shuffle on a tile double-tap: verify tile double-tap never shuffles on device. If it does, fallback: wrap the parent gesture so it ignores touches in the grid region (e.g., `.simultaneousGesture` is NOT the fix; instead move the parent gesture to background layers placed behind the grid via a `ZStack` background `Color.clear.contentShape(Rectangle()).onTapGesture(count: 2)` which sits behind children).
3. **Double-tap interval/separation values** (0.3s / 44pt) are discretion; tune on device.
4. **Safe-area strips** not covered by the VStack; decide whether to attach to the outer ZStack (minor).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | build + tests | yes (simulators listed) | — | — |
| iPhone 17 Pro simulator | unit tests | yes (booted) | iOS 26 SDK | — |
| Physical iPhone | gesture feel, haptics | per memory: Wi-Fi install script exists | — | Simulator cannot produce haptics or true tap feel |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) in `WordPuzzleTests`; XCUITest in `WordPuzzleUITests` |
| Config file | Xcode project `WordPuzzle/WordPuzzle.xcodeproj` (no separate config) |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WordPuzzleTests/EmptyDoubleTapDetectorTests -only-testing:WordPuzzleTests/GameViewModelTests` |
| Full suite command | same without `-only-testing` (confirm scheme name; UI tests may be a separate scheme/plan) |

### Behavior → Test Map
| Behavior | Test Type | Automated | Exists? |
|----------|-----------|-----------|---------|
| Two empty taps within interval and separation return true on second | unit | EmptyDoubleTapDetectorTests | Wave 0 |
| Interval too long / separation too far / travel too large (drag) return false | unit | same | Wave 0 |
| `reset()` (tile touch) between taps prevents double-tap | unit | same | Wave 0 |
| Triple tap fires once then restarts chain | unit | same | Wave 0 |
| `shuffleOuterLetters()` returns true and bumps `shuffleCount` once on real shuffle | unit | GameViewModelTests | Wave 0 (extend) |
| Returns false, no count bump while `isShuffling` (immediate second call) | unit | GameViewModelTests | Wave 0 |
| Returns false in `.roundOver` / `.loading` / `.paywalled` | unit | GameViewModelTests | Wave 0 |
| Center letter fixed, in-progress word preserved (D-11), letter set unchanged | unit | GameViewModelTests (existing test + extension) | partly exists |
| Double-tap on empty area shuffles | XCUITest optional (`coordinate(...).doubleTap()` on a margin; assert letter order change via accessibility) | optional | Wave 0 optional |
| Tile double-tap appends twice, no shuffle; tile latency unchanged | manual on-device | — | manual |
| Double-tap on word display, each button, stats/settings sheets does not shuffle | manual on-device | — | manual |
| Light haptic on button and gesture, none on rejected shuffle | manual on-device (simulator has no haptics) | — | manual |
| Gaps/corners/hexagon corners inside grid square count as empty | manual on-device | — | manual |

### Sampling Rate
- Per task commit: quick run command
- Per wave merge: full suite
- Phase gate: full suite green plus on-device checklist before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `WordPuzzleTests/EmptyDoubleTapDetectorTests.swift` — detector unit tests (new file must be added to the WordPuzzleTests target in the pbxproj; check whether the project uses file-system-synchronized groups, which would need no pbxproj edit)
- [ ] Extend `WordPuzzleTests/GameViewModelTests.swift` — shuffle return value, `shuffleCount`, phase gating, `isShuffling` rejection
- [ ] Framework install: none

## Project Constraints (from CLAUDE.md)
- SwiftUI only, iOS 17+ target, MVVM with `@Observable`; no third-party deps; no network.
- Views are presentation-only; only `GameView` touches `GameViewModel` (LetterGridView takes closures).
- Do not add TCA, RevenueCat, etc. (irrelevant here).
- Edits must go through a GSD workflow (`/gsd:execute-phase`).
- Persistence: shuffle state is in-memory only; do not persist.

## Sources

### Primary (HIGH — project code read this session)
- `Game/Views/LetterGridView.swift`, `GameView.swift`, `WordDisplayView.swift`, `HexTileView.swift` (contentShape(HexagonShape)), `Game/GameViewModel.swift`
- `.planning/phases/03-core-game-ui/03-RESEARCH.md` Pitfalls 1-3
- `WordPuzzleTests/HexGeometryTests.swift` (Swift Testing conventions)

### Secondary (MEDIUM)
- SwiftUI gesture precedence (child over parent; `contentShape` needed for hit-testing empty stack space) — training knowledge consistent with Apple docs; not re-fetched this session, so confirm on device.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — native APIs only, deployment target 17.6 verified in pbxproj
- Architecture: MEDIUM — hybrid design is robust to the two unknowns, but gesture precedence needs device confirmation
- Pitfalls: MEDIUM — derived from code reading plus Phase 3 research

**Research date:** 2026-10-04
**Valid until:** 2026-11-03
