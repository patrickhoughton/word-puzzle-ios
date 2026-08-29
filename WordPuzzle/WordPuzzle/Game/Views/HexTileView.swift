import SwiftUI

/// One hexagonal letter tile. Center tile is accent-filled (#F5B800) to satisfy
/// GAME-01's "center letter visually distinguished" and D-01.
/// Outer tiles use the Secondary surface color — 03-UI-SPEC.md explicitly forbids
/// introducing a third tile color.
struct HexTileView: View {
    let letter: Character
    let isCenter: Bool

    var body: some View {
        Text(String(letter).uppercased())
            .font(GameTheme.displayFont)
            .foregroundStyle(isCenter ? Color.black : Color.primary)
            .frame(width: GameTheme.hexSize, height: GameTheme.hexSize)
            .background(isCenter ? GameTheme.accent : GameTheme.secondarySurface)
            .clipShape(HexagonShape())
            // RESEARCH Pitfall 4: clipShape restricts rendering only. contentShape
            // is what restricts hit-testing, so taps in the bounding-box corners
            // (outside the visible hexagon) do not register on the wrong tile.
            .contentShape(HexagonShape())
            .accessibilityLabel(Text(isCenter ? "Center letter \(String(letter).uppercased())"
                                              : "Letter \(String(letter).uppercased())"))
    }
}

#Preview {
    HStack(spacing: GameTheme.md) {
        HexTileView(letter: "a", isCenter: true)
        HexTileView(letter: "b", isCenter: false)
    }
    .padding()
}
