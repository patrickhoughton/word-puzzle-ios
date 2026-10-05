import SwiftUI

/// The 7-hex honeycomb flower (D-01) with unified tap + drag input (D-02).
///
/// GESTURE DESIGN (RESEARCH Pitfall 1 — read before changing):
/// There is exactly ONE gesture recognizer here: a `DragGesture(minimumDistance: 0)`
/// on the container. A plain tap fires `.onChanged` once at touch-down (because
/// minimumDistance is 0) and appends that letter; a drag fires `.onChanged`
/// repeatedly and appends each newly-entered tile. Deliberately no separate
/// per-tile tap gesture recognizer — two recognizers competing for the same
/// touch is exactly the documented failure mode where taps get silently swallowed.
///
/// Phase 10: the same gesture also detects empty-space double-taps. `.onEnded` feeds touches
/// that began and ended off every tile to `EmptyDoubleTapDetector`. There is still no second
/// recognizer. A rectangular contentShape makes the gaps between hexagons part of this gesture.
///
/// Phase 12: still one recognizer. Each touch is classified exactly once, at the first `onChanged`, as
/// tiles mode (the Phase 3/10 behavior) or spin mode (turns the outer ring, never appends a letter). The hit
/// area is the flower square plus `spinZoneMargin`. Hit testing is pure math (`HexFlowerLayout.tileIndex`), with
/// no per-tile frame reporting, which would fire every frame during a spin.
///
/// This view is presentation-only: it never imports or references the game's
/// view-model type. GameView (plan 03-04) binds `onLetterTouched` to `viewModel.append`.
struct LetterGridView: View {
    let centerLetter: Character
    /// Exactly 6 letters, in current display order. Changing this array animates
    /// the tiles into their new positions (D-03: animate, never jump).
    let outerLetters: [Character]
    /// True while a shuffle animation is interpolating — drag input is ignored so a
    /// stale frame dictionary cannot append the wrong letter (RESEARCH Pitfall 2).
    let isInputDisabled: Bool
    let onLetterTouched: (Character) -> Void
    /// Phase 10 D-02: fired when two quick taps land on empty space inside the flower's
    /// square (gaps, square corners, hexagon corners outside the hit circle). Never fired
    /// for tile touches: a tile double-tap still appends the letter twice (D-01).
    let onEmptyDoubleTap: () -> Void
    /// Phase 11: the single tile the tutorial wants touched next (letters are unique per puzzle).
    var highlightedLetter: Character? = nil
    /// Phase 11 D-02 visual: dim every tile except the highlighted one to GameTheme.tutorialDimmedOpacity.
    var dimsNonHighlighted: Bool = false
    /// Phase 11 UI-SPEC Accessibility: the step instruction, read as the highlighted tile's hint.
    var highlightHint: String? = nil

    /// Phase 12: the ring-spin state. Only this view reads `angle` (per-frame re-render stays local to the grid).
    var ringSpin: RingSpinController? = nil
    /// Phase 12 D-17/D-20: GameView passes false outside .playing, while shuffling, behind sheets, and on strict tutorial steps that do not allow a spin.
    var isSpinEnabled: Bool = false
    /// Phase 12 D-20: tutorial highlight around the whole ring on the spin step.
    var highlightsRing: Bool = false

    @State private var emptyTapDetector = EmptyDoubleTapDetector()
    @State private var lastTouchedIndex: Int?
    private enum TouchMode { case undecided, tiles, spin }
    @State private var touchMode: TouchMode = .undecided
    @State private var touchGrabbedMovingRing = false
    @GestureState private var isTouching = false

    var body: some View {
        let offsets = HexFlowerLayout.outerOffsets(rotation: ringSpin?.angle ?? 0)
        return ZStack {
            tile(letter: centerLetter, isCenter: true)
            // Phase 12 Pitfall 1: keyed by LETTER (letters are unique per puzzle), so committing a spin of k slots
            // (letters rotate by k, angle resets to 0) leaves every tile exactly where it was. Side effect: Shuffle now
            // slides tiles between slots instead of cross-fading glyphs (flagged for the on-device checkpoint).
            ForEach(Array(outerLetters.enumerated()), id: \.element) { index, letter in
                tile(letter: letter, isCenter: false)
                    .offset(x: offsets[index].width, y: offsets[index].height)   // D-07: positions orbit, glyphs stay upright
            }
        }
        .frame(width: HexFlowerLayout.flowerDiameter(), height: HexFlowerLayout.flowerDiameter())
        .tutorialHighlight(highlightsRing, in: Circle())
        .animation(GameTheme.shuffleAnimation, value: outerLetters)
        // Phase 12 D-01: grab room beyond the flower square. padding(m) ... padding(-m) enlarges ONLY the hit area;
        // the layout footprint is unchanged (research Pitfall 5). Gesture locations are in this padded view's local space.
        .padding(HexFlowerLayout.spinZoneMargin)
        // Phase 10 D-02: the whole square is hit-testable, so gaps and corners are owned by this one gesture.
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onChange(of: isTouching) { _, touching in handleTouchingChange(touching) }
        .padding(-HexFlowerLayout.spinZoneMargin)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                if touchMode == .undecided { classify(value) }
                if touchMode == .spin {
                    ringSpin?.track(point: value.location, start: value.startLocation,
                                    center: HexFlowerLayout.spinZoneCenter, time: value.time)
                    return
                }
                // Tiles mode: the Phase 3/10 path, unchanged except the pure hit test.
                let index = hit(value.location)
                // Any tile touch breaks an empty-tap chain ("tile tap then gap tap" never shuffles).
                if index != nil { emptyTapDetector.reset() }
                guard !isInputDisabled else { return }
                guard let index else { return }
                guard index != lastTouchedIndex else { return }
                lastTouchedIndex = index
                onLetterTouched(letter(forIndex: index))
            }
            .onEnded { value in
                defer { touchMode = .undecided; touchGrabbedMovingRing = false; lastTouchedIndex = nil }
                if touchMode == .spin {
                    ringSpin?.release(time: value.time)   // no-op for a tap on a resting ring; settles a grab; coasts a flick
                    // A touch that grabbed a MOVING ring never counts toward the double-tap.
                    if touchGrabbedMovingRing { emptyTapDetector.reset(); return }
                }
                // Phase 10 D-02/D-03: an "empty tap" began AND ended off every tile; the detector rejects travel >= 10pt,
                // so a spin drag can never shuffle.
                if hit(value.startLocation) == nil, hit(value.location) == nil {
                    if emptyTapDetector.registerEmptyTap(start: value.startLocation, end: value.location, at: value.time) {
                        onEmptyDoubleTap()
                    }
                } else {
                    emptyTapDetector.reset()
                }
            }
    }

    private func classify(_ value: DragGesture.Value) {
        let startIndex = hit(value.startLocation)
        let ringMoving = ringSpin?.isActive ?? false
        // D-01/D-02: at rest only a touch that STARTS off every tile spins. While the ring is moving,
        // any touch except the (stationary) center tile grabs it (D-13) and never types (D-14).
        let wantsSpin = startIndex == nil || (ringMoving && startIndex != -1)
        if let ringSpin, isSpinEnabled, wantsSpin {
            touchMode = .spin
            touchGrabbedMovingRing = ringMoving
            ringSpin.touchDown()
        } else {
            touchMode = .tiles
        }
    }

    private func hit(_ p: CGPoint) -> Int? {
        HexFlowerLayout.tileIndex(at: p, center: HexFlowerLayout.spinZoneCenter, rotation: ringSpin?.angle ?? 0)
    }

    /// Pitfall 6: a cancelled drag may never call onEnded.
    private func handleTouchingChange(_ touching: Bool) {
        guard !touching else { return }
        // Defer one run-loop turn: if onEnded fires it resets touchMode first and this is a no-op.
        DispatchQueue.main.async {
            guard touchMode != .undecided else { return }
            if touchMode == .spin { ringSpin?.release(time: .now) }
            touchMode = .undecided
            touchGrabbedMovingRing = false
            lastTouchedIndex = nil
        }
    }

    private func tile(letter: Character, isCenter: Bool) -> some View {
        let isTarget = highlightedLetter.map { $0 == letter } ?? false
        return HexTileView(letter: letter, isCenter: isCenter)
            .tutorialHighlight(isTarget, in: HexagonShape())
            .opacity(dimsNonHighlighted && !isTarget ? GameTheme.tutorialDimmedOpacity : 1)
            .accessibilityHint(isTarget ? Text(highlightHint ?? "") : Text(""))
    }

    private func letter(forIndex index: Int) -> Character {
        index == -1 ? centerLetter : outerLetters[index]
    }
}

#Preview {
    LetterGridView(
        centerLetter: "a",
        outerLetters: ["c", "d", "e", "l", "n", "t"],
        isInputDisabled: false,
        onLetterTouched: { print($0) },
        onEmptyDoubleTap: { print("empty double-tap") }
    )
}
