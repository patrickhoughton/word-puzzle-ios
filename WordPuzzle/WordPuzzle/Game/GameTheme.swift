import SwiftUI

/// Design tokens from `.planning/phases/03-core-game-ui/03-UI-SPEC.md` (approved 2026-08-29).
/// Every Phase 3 view reads spacing/typography/color from here — no inline magic numbers.
enum GameTheme {

    // MARK: - Spacing scale (UI-SPEC "Spacing Scale", all multiples of 4)
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Component geometry (UI-SPEC "Component Geometry")
    /// Hex tile diameter. Tune on-device within 64–72pt.
    static let hexSize: CGFloat = 70
    /// Distance from grid center to each outer tile center.
    static let outerRingRadius: CGFloat = hexSize * 1.6
    /// Apple HIG minimum tap target.
    static let minTapTarget: CGFloat = 44

    // MARK: - Typography (UI-SPEC "Typography" — exactly 4 sizes, 2 weights)
    static let displayFont = Font.system(size: 34, weight: .semibold)
    static let headingFont = Font.system(size: 20, weight: .semibold)
    static let bodyFont = Font.system(size: 17, weight: .regular)
    static let labelFont = Font.system(size: 13, weight: .regular)

    // MARK: - Color (UI-SPEC "Color" — 60/30/10 split)
    /// Dominant 60% — screen backgrounds.
    static let dominant = Color(.systemBackground)
    /// Secondary 30% — card/row/container surfaces AND outer (non-center) hex tiles.
    static let secondarySurface = Color(.secondarySystemBackground)
    /// Accent 10% — honeycomb gold #F5B800, sourced from Assets.xcassets/AccentColor.
    static let accent = Color.accentColor
    /// Error — invalid-word message text only (D-07).
    static let errorColor = Color(.systemRed)

    // MARK: - Motion
    /// Shuffle animation (D-03: animate, never jump).
    static let shuffleAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.7)
    /// Duration used by GameViewModel to gate input during shuffle (RESEARCH Pitfall 2).
    static let shuffleDurationMilliseconds: Int = 400
}
