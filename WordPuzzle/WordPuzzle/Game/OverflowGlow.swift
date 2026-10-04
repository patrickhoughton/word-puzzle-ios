import Foundation

/// Shared glow math for the Mythic Grandmaster / overflow treatment (Phase 8), reused by
/// the Stats screen's best-rank glow (Phase 9 D-17) so both pulse identically.
enum OverflowGlow {
    static func lerp<T: BinaryFloatingPoint>(_ r: ClosedRange<T>, _ f: Double) -> T {
        r.lowerBound + (r.upperBound - r.lowerBound) * T(f)
    }
    /// 0...1 pulse phase. Reduce Motion: a steady 0.5 (mirrors OverflowBar).
    static func pulse(time t: TimeInterval, reduceMotion: Bool) -> Double {
        reduceMotion ? 0.5 : 0.5 + 0.5 * sin(2 * .pi * t / GameTheme.overflowGlowPulseSeconds)
    }
    static func opacity(pulse: Double) -> Double { lerp(GameTheme.overflowGlowOpacityRange, pulse) }
    static func radius(pulse: Double) -> CGFloat { lerp(GameTheme.overflowGlowRadiusRange, pulse) }
}
