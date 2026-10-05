import Foundation

/// Phase 12: every magic number of the ring spin in one place. Starting values computed in
/// 12-RESEARCH Pattern 2 (k lowered from 0.55 to 0.45 so a max flick coasts ~6 s); tune ON DEVICE,
/// change constants not structure.
struct RingSpinTuning: Equatable {
    var viscousFriction: Double = 0.45      // k (1/s): main duration knob
    var dryFriction: Double = 0.35          // c (rad/s^2): prize-wheel tail
    var handoffSpeed: Double = 1.5          // w_h (rad/s): coast hands off to the settle spring
    var settleFrequency: Double = 10        // L (1/s): critically damped settle
    var settleTimeConstants: Double = 8     // settle lasts settleTimeConstants / settleFrequency seconds
    var maxReleaseSpeed: Double = 24        // w_max (rad/s): release clamp == max-duration cap
    var restSpeed: Double = 0.3             // below this a release counts as "no flick"

    static let standard = RingSpinTuning()

    var settleDuration: TimeInterval { settleTimeConstants / settleFrequency }   // 0.8 s
}
