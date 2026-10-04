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

    // MARK: - Typography (05-UI-SPEC.md "Typography" — 4 roles, 2 weights)
    // UX-03 / D-04: these are Dynamic Type TEXT STYLES, not fixed point sizes.
    // Only text-style-based fonts participate in Dynamic Type; a fixed-point-size
    // font never scales regardless of the user's setting (RESEARCH Pitfall 6).
    // At the default ("Large") category these render at exactly the Phase 3 sizes —
    // largeTitle 34, title3 20, body 17, footnote 13 — so the visual hierarchy is
    // unchanged, but all four now scale together with the system setting.
    // Never reintroduce a fixed-point-size font here; HexTileView's clamped letter
    // size is the ONLY sanctioned exception in the app (D-05).
    static let displayFont = Font.largeTitle.weight(.semibold)
    static let headingFont = Font.title3.weight(.semibold)
    static let bodyFont    = Font.body
    static let labelFont   = Font.footnote

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

    // MARK: - Phase 8 completion celebrations (08-UI-SPEC §2, §4, §5)
    /// Delay before the first celebration so its haptic doesn't land on WordDisplayView's per-word .success haptic (RESEARCH Pitfall 4).
    static let celebrationLeadInSeconds: Double = 0.25
    static let sweepCardInSeconds: Double = 0.15
    static let sweepTallyMaxSeconds: Double = 1.2
    static let sweepStepMinSeconds: Double = 0.03
    static let sweepStepMaxSeconds: Double = 0.3
    static let sweepWordVisibleMinStepSeconds: Double = 0.08
    static let sweepHeadlineHoldSeconds: Double = 0.8
    static let celebrationFadeOutSeconds: Double = 0.3
    static let lengthPillInSeconds: Double = 0.2
    static let lengthPillHoldSeconds: Double = 1.0
    static let lengthPillSlideOffset: CGFloat = 8
    static let reduceMotionCrossfadeSeconds: Double = 0.2
    static let reduceMotionHoldSeconds: Double = 1.0
    static let sweepMaxTicks: Int = 12
    static let sweepCardInScale: CGFloat = 0.9
    static let sweepCardAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.7)
    static let celebrationCornerRadius: CGFloat = 12
    static let celebrationShadowOpacity: Double = 0.15
    static let celebrationShadowRadius: CGFloat = 8
    static let overflowShimmerSeconds: Double = 2.0
    static let overflowShimmerWidthFraction: CGFloat = 0.4
    static let overflowShimmerOpacity: Double = 0.6
    static let overflowGlowOpacity: Double = 0.6
    static let overflowGlowRadius: CGFloat = 8
}
