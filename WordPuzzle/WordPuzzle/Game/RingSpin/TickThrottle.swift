import Foundation

/// Phase 12 D-10/D-11: 6 detents per revolution means ~23 crossings/s at 24 rad/s. Minimum intervals stop clipped/buzzy feedback; above `decimateAboveRate` every 2nd event is skipped so a fast spin reads as a smooth whirr. Ticks space out naturally as the ring slows.
struct TickThrottle {
    struct Decision: Equatable {
        var haptic: Bool
        var sound: Bool
        static let none = Decision(haptic: false, sound: false)
    }

    var minHapticInterval: TimeInterval
    var minSoundInterval: TimeInterval
    var decimateAboveRate: Double

    private var lastHaptic: TimeInterval = -.infinity
    private var lastSound: TimeInterval = -.infinity
    private var eventIndex = 0

    init(minHapticInterval: TimeInterval = 0.045, minSoundInterval: TimeInterval = 0.055, decimateAboveRate: Double = 18) {
        self.minHapticInterval = minHapticInterval
        self.minSoundInterval = minSoundInterval
        self.decimateAboveRate = decimateAboveRate
    }

    mutating func register(crossings: Int, at time: TimeInterval, rate: Double) -> Decision {
        guard crossings > 0 else { return .none }
        eventIndex += 1
        if rate > decimateAboveRate && eventIndex % 2 == 0 { return .none }
        let haptic = time - lastHaptic >= minHapticInterval
        if haptic { lastHaptic = time }
        let sound = time - lastSound >= minSoundInterval
        if sound { lastSound = time }
        return Decision(haptic: haptic, sound: sound)
    }

    mutating func reset() {
        lastHaptic = -.infinity
        lastSound = -.infinity
        eventIndex = 0
    }
}
