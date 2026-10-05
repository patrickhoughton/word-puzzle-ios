import Foundation

/// Phase 12 D-05/D-06: closed-form, frame-rate independent trajectory. Deceleration = k*|w| + c
/// (viscous + dry friction: pure viscous decay never really stops). When |w| drops to handoffSpeed a
/// critically damped spring takes over toward a slot chosen by SlotMath.settleTarget so it cannot
/// overshoot. The release clamp (maxReleaseSpeed) is the max-duration cap.
/// Angles in radians, positive = clockwise on screen.
struct RingSpinTrajectory: Equatable {
    let tuning: RingSpinTuning
    let startAngle: Double
    let releaseVelocity: Double      // after clamping to +-maxReleaseSpeed and zeroing |w| < restSpeed
    let handoffTime: TimeInterval
    let handoffAngle: Double
    let handoffVelocity: Double
    let targetAngle: Double          // exact multiple of SlotMath.slotAngle

    private let sign: Double
    private let magnitudeBoost: Double   // A = |w0| + c/k

    var duration: TimeInterval { handoffTime + tuning.settleDuration }

    init(startAngle: Double, velocity: Double, tuning: RingSpinTuning = .standard) {
        self.tuning = tuning
        self.startAngle = startAngle
        var w = max(-tuning.maxReleaseSpeed, min(tuning.maxReleaseSpeed, velocity))
        if abs(w) < tuning.restSpeed { w = 0 }
        self.releaseVelocity = w

        let k = tuning.viscousFriction
        let c = tuning.dryFriction
        let wh = tuning.handoffSpeed
        let s: Double = w >= 0 ? 1 : -1
        let a = abs(w) + c / k
        self.sign = s
        self.magnitudeBoost = a

        if abs(w) <= wh {
            handoffTime = 0
            handoffAngle = startAngle
            handoffVelocity = w
        } else {
            let th = log(a / (wh + c / k)) / k
            handoffTime = th
            handoffAngle = startAngle + s * (a * (1 - exp(-k * th)) / k - (c / k) * th)
            handoffVelocity = s * (a * exp(-k * th) - c / k)
        }
        targetAngle = SlotMath.settleTarget(angle: handoffAngle, velocity: handoffVelocity, tuning: tuning)
    }

    func angle(at t: TimeInterval) -> Double {
        if t <= 0 { return startAngle }
        if t >= duration { return targetAngle }
        let k = tuning.viscousFriction
        let c = tuning.dryFriction
        if t < handoffTime {
            return startAngle + sign * (magnitudeBoost * (1 - exp(-k * t)) / k - (c / k) * t)
        }
        let l = tuning.settleFrequency
        let u = t - handoffTime
        let e0 = handoffAngle - targetAngle
        let e = (e0 + (handoffVelocity + l * e0) * u) * exp(-l * u)
        return targetAngle + e
    }

    func velocity(at t: TimeInterval) -> Double {
        if t <= 0 { return releaseVelocity }
        if t >= duration { return 0 }
        let k = tuning.viscousFriction
        let c = tuning.dryFriction
        if t < handoffTime {
            return sign * (magnitudeBoost * exp(-k * t) - c / k)
        }
        let l = tuning.settleFrequency
        let u = t - handoffTime
        let e0 = handoffAngle - targetAngle
        return exp(-l * u) * (handoffVelocity - l * u * (handoffVelocity + l * e0))
    }

    func isFinished(at t: TimeInterval) -> Bool { t >= duration }
}
