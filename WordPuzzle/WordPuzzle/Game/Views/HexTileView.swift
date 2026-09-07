import SwiftUI

/// One hexagonal letter tile. Center tile is accent-filled (#F5B800) to satisfy
/// GAME-01's "center letter visually distinguished" and D-01.
/// Outer tiles use the Secondary surface color — 03-UI-SPEC.md explicitly forbids
/// introducing a third tile color.
/// This is the ONLY sanctioned fixed-point-size font in the app after the D-04
/// typography migration — plan 05-04's `scripts/compliance-guards.sh` whitelists
/// this file by name and will fail the build guard if the pattern appears
/// anywhere else.
struct HexTileView: View {
    /// D-05: the hexagon geometry stays FIXED at GameTheme.hexSize (70pt) — only the
    /// letter glyph inside it responds to Dynamic Type, and only up to a hard ceiling.
    /// Base matches the Phase 3 displayFont size so the default category renders
    /// pixel-identically to before this migration.
    static let baseLetterSize: CGFloat = 34
    /// RESEARCH Pitfall 1: @ScaledMetric has NO built-in maximum. At accessibility
    /// sizes (AX1-AX5) an unclamped 34pt base scales past 90pt — larger than the whole
    /// 70pt tile. This min() is the load-bearing overflow protection.
    static let maxLetterSize: CGFloat = 40

    /// Extracted as a static so the clamp is unit-testable without rendering a view
    /// (same rationale as HexFlowerLayout's extracted trigonometry).
    static func clampedLetterSize(scaled: CGFloat) -> CGFloat {
        min(scaled, maxLetterSize)
    }

    let letter: Character
    let isCenter: Bool

    @ScaledMetric(relativeTo: .largeTitle)
    private var scaledLetterSize: CGFloat = HexTileView.baseLetterSize

    var body: some View {
        Text(String(letter).uppercased())
            .font(Font.system(size: Self.clampedLetterSize(scaled: scaledLetterSize),
                               weight: .semibold))
            // Defense in depth only — the min() clamp above is the primary mechanism.
            .lineLimit(1)
            .minimumScaleFactor(0.5)
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
