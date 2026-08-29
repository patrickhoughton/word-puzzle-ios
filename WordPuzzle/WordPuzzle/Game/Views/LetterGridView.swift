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
        .animation(GameTheme.shuffleAnimation, value: outerLetters)
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(TileFramePreferenceKey.self) { tileFrames = $0 }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
                .onChanged { value in
                    guard !isInputDisabled else { return }
                    guard let index = hitIndex(at: value.location) else { return }
                    guard index != lastTouchedIndex else { return }
                    lastTouchedIndex = index
                    onLetterTouched(letter(forIndex: index))
                }
                .onEnded { _ in
                    lastTouchedIndex = nil
                }
        )
    }

    private func tile(letter: Character, index: Int, isCenter: Bool) -> some View {
        HexTileView(letter: letter, isCenter: isCenter)
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
        onLetterTouched: { print($0) }
    )
}
