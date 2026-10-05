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
    // Overflow (> 100%) bar: thick molten-gold capsule drawn over the plain bar's slot (no layout change).
    static let overflowBarHeight: CGFloat = 10
    static let overflowGold = Color(red: 0.96, green: 0.72, blue: 0.00)       // #F5B800, explicit (not tint-dependent)
    static let overflowGoldDeep = Color(red: 0.88, green: 0.52, blue: 0.00)   // amber
    static let overflowGoldLight = Color(red: 1.00, green: 0.89, blue: 0.48)  // pale gold
    static let overflowFlowSeconds: Double = 2.4          // gradient drift period
    static let overflowShimmerSeconds: Double = 1.4
    static let overflowShimmerWidthFraction: CGFloat = 0.35
    static let overflowShimmerOpacity: Double = 0.85
    static let overflowGlowOpacityRange: ClosedRange<Double> = 0.45...0.9
    static let overflowGlowRadiusRange: ClosedRange<CGFloat> = 5...14
    static let overflowGlowPulseSeconds: Double = 1.6
    static let overflowSparkleCount: Int = 14
    static let overflowSparkleRise: CGFloat = 34          // pts sparkles drift above the bar
    static let overflowBurstSeconds: Double = 0.9
    static let overflowBurstParticles: Int = 22
    static let overflowBurstScale: CGFloat = 1.8          // bar's vertical pop on first crossing 100%
    static let overflowBurstAnimation: Animation = .spring(response: 0.25, dampingFraction: 0.45)

    // MARK: - Tutorial (Phase 11, 11-UI-SPEC)

    static let tutorialDimmedOpacity: Double = 0.35
    static let tutorialHighlightStroke: CGFloat = 4
    /// At accessibility sizes the banner scrolls inside at most this fraction of the screen height.
    static let tutorialBannerMaxHeightFraction: CGFloat = 0.2

    // MARK: - Phase 9 stats screen (09-UI-SPEC)

    /// Zero-streak hero flame: `.secondary` at this opacity (D-22).
    static let dimmedFlameOpacity: Double = 0.4
    /// Stat numbers count up 0, 1, 2 ... N on appear (D-18) at a steady rate within each count.
    /// Up to `statsCountUpLinearLimit` every step takes `statsCountUpSecondsPerUnit`; past it the
    /// total grows with sqrt(N) so big totals don't drag (45 -> 0.45s, 760 -> ~2.8s, 1169 -> ~3.4s).
    /// Patrick, 2026-10-04: a fixed-length roll read as near-instant; pure linear was too slow for big numbers.
    static let statsCountUpSecondsPerUnit: Double = 0.01
    static let statsCountUpLinearLimit: Double = 100

    static func statsCountUpSeconds(for value: Int) -> Double {
        let n = Double(max(value, 0))
        let linearCap = statsCountUpLinearLimit * statsCountUpSecondsPerUnit
        return n <= statsCountUpLinearLimit
            ? n * statsCountUpSecondsPerUnit
            : linearCap * (n / statsCountUpLinearLimit).squareRoot()
    }
}
