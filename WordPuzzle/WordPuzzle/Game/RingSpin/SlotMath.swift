// Phase 12: pure slot/detent math for the ring spin. Angles in radians, positive = clockwise on screen, slot 0 = 12 o'clock.
import Foundation

enum SlotMath {
    static let slotAngle: Double = .pi / 3

    /// Index of the nearest slot (schoolbook rounding).
    static func detent(_ angle: Double) -> Int { Int((angle / slotAngle).rounded()) }

    /// A tile passes a slot boundary whenever the nearest-slot index changes (at the 30-degree
    /// midpoints), like the pegs of a prize-wheel clicker (D-10). Handles several crossings in one frame.
    static func crossings(from a: Double, to b: Double) -> Int { abs(detent(b) - detent(a)) }

    /// Signed number of slots the ring moved.
    static func slotsMoved(finalAngle: Double) -> Int { detent(finalAngle) }

    static func normalizedSlots(_ k: Int) -> Int { ((k % 6) + 6) % 6 }

    static func nearestSlotAngle(_ angle: Double) -> Double { Double(detent(angle)) * slotAngle }

    /// Picks the slot a critically damped settle spring will land on. With error e0 = angle - target
    /// and velocity v, a critically damped spring with rate L does not overshoot iff |e0| >= |v|/L
    /// (12-RESEARCH Pattern 2), so the target must be at least |v|/L ahead in the direction of motion.
    static func settleTarget(angle: Double, velocity: Double, tuning: RingSpinTuning) -> Double {
        if abs(velocity) < tuning.restSpeed { return nearestSlotAngle(angle) }
        let s: Double = velocity > 0 ? 1 : -1
        let minDistance = abs(velocity) / tuning.settleFrequency + 0.01
        var n = s > 0 ? (angle / slotAngle).rounded(.up) : (angle / slotAngle).rounded(.down)
        while abs(n * slotAngle - angle) < minDistance { n += s }
        return n * slotAngle
    }
}
