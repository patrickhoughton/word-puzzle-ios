import SwiftUI

/// Reports each tile's frame in the "hexGrid" coordinate space so the container's
/// single DragGesture can hit-test against them (RESEARCH Pattern 3).
/// Key -1 is the center tile; keys 0...5 are the outer tiles by ring index.
struct TileFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

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

    @State private var emptyTapDetector = EmptyDoubleTapDetector()
    @State private var tileFrames: [Int: CGRect] = [:]
    @State private var lastTouchedIndex: Int?

    private let coordinateSpaceName = "hexGrid"

    var body: some View {
        ZStack {
            tile(letter: centerLetter, index: -1, isCenter: true)
                .offset(x: 0, y: 0)

            ForEach(Array(outerLetters.enumerated()), id: \.offset) { index, letter in
                let offset = HexFlowerLayout.outerOffsets()[index]
                tile(letter: letter, index: index, isCenter: false)
                    .offset(x: offset.width, y: offset.height)
            }
        }
        .frame(width: HexFlowerLayout.flowerDiameter(), height: HexFlowerLayout.flowerDiameter())
        // Phase 10 D-02: the whole flower square is hit-testable, so gaps and corners are owned by this one gesture.
        .contentShape(Rectangle())
        .animation(GameTheme.shuffleAnimation, value: outerLetters)
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(TileFramePreferenceKey.self) { tileFrames = $0 }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
                .onChanged { value in
                    let index = hitIndex(at: value.location)
                    // Any tile touch breaks an empty-tap chain ("tile tap then gap tap" never shuffles).
                    if index != nil { emptyTapDetector.reset() }
                    guard !isInputDisabled else { return }
                    guard let index else { return }
                    guard index != lastTouchedIndex else { return }
                    lastTouchedIndex = index
                    onLetterTouched(letter(forIndex: index))
                }
                .onEnded { value in
                    defer { lastTouchedIndex = nil }
                    // An "empty tap" began AND ended off every tile; the detector also rejects drags (>10pt travel).
                    if hitIndex(at: value.startLocation) == nil, hitIndex(at: value.location) == nil {
                        if emptyTapDetector.registerEmptyTap(start: value.startLocation, end: value.location, at: value.time) {
                            onEmptyDoubleTap()
                        }
                    } else {
                        emptyTapDetector.reset()
                    }
                }
        )
    }

    private func tile(letter: Character, index: Int, isCenter: Bool) -> some View {
        let isTarget = highlightedLetter.map { $0 == letter } ?? false
        return HexTileView(letter: letter, isCenter: isCenter)
            .tutorialHighlight(isTarget, in: HexagonShape())
            .opacity(dimsNonHighlighted && !isTarget ? GameTheme.tutorialDimmedOpacity : 1)
            .accessibilityHint(isTarget ? Text(highlightHint ?? "") : Text(""))
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TileFramePreferenceKey.self,
                        value: [index: geo.frame(in: .named(coordinateSpaceName))]
                    )
                }
            )
    }

    private func letter(forIndex index: Int) -> Character {
        index == -1 ? centerLetter : outerLetters[index]
    }

    /// Circular hit-test inscribed in each hexagon — see HexFlowerLayout.hitTest.
    private func hitIndex(at point: CGPoint) -> Int? {
        for (index, frame) in tileFrames {
            let center = CGPoint(x: frame.midX, y: frame.midY)
            if HexFlowerLayout.hitTest(point: point, tileCenter: center) {
                return index
            }
        }
        return nil
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
