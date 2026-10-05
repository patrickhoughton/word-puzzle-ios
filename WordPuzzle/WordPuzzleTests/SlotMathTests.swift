import Testing
import Foundation
@testable import WordPuzzle

@Suite struct SlotMathTests {
    let sa = SlotMath.slotAngle
    let tuning = RingSpinTuning.standard

    @Test func detentRounding() {
        #expect(SlotMath.detent(0) == 0)
        #expect(SlotMath.detent(sa * 0.49) == 0)
        #expect(SlotMath.detent(sa * 0.51) == 1)
        #expect(SlotMath.detent(-sa * 0.51) == -1)
        #expect(SlotMath.detent(2 * .pi) == 6)
    }

    @Test func crossingsAreDirectionAgnostic() {
        #expect(SlotMath.crossings(from: 0, to: 2 * .pi) == 6)
        #expect(SlotMath.crossings(from: 0.1, to: -0.1) == 0)
        #expect(SlotMath.crossings(from: 0, to: sa * 3.4) == 3)
        #expect(SlotMath.crossings(from: sa * 3.4, to: 0) == 3)
    }

    @Test func slotsMovedIsSigned() {
        #expect(SlotMath.slotsMoved(finalAngle: -2 * sa) == -2)
        #expect(SlotMath.slotsMoved(finalAngle: 12 * .pi) == 36)
    }

    @Test func normalizedSlotsWrap() {
        #expect(SlotMath.normalizedSlots(-1) == 5)
        #expect(SlotMath.normalizedSlots(7) == 1)
        #expect(SlotMath.normalizedSlots(-12) == 0)
        #expect(SlotMath.normalizedSlots(0) == 0)
    }

    @Test func nearestSlotAngleExact() {
        #expect(SlotMath.nearestSlotAngle(sa * 1.3) == sa * 1)
        #expect(SlotMath.nearestSlotAngle(-sa * 1.7) == -sa * 2)
    }

    @Test func settleTargetAtRestIsNearest() {
        #expect(SlotMath.settleTarget(angle: sa * 1.3, velocity: 0.1, tuning: tuning) == sa)
        #expect(SlotMath.settleTarget(angle: sa * 1.3, velocity: -0.1, tuning: tuning) == sa)
    }

    @Test func settleTargetSkipsTooCloseSlotForward() {
        let angle = sa * 0.99
        let r = SlotMath.settleTarget(angle: angle, velocity: 1.5, tuning: tuning)
        #expect(r > angle)
        #expect(r - angle >= 1.5 / tuning.settleFrequency)
        #expect(r == sa * 2)
    }

    @Test func settleTargetMirrorsBackward() {
        #expect(SlotMath.settleTarget(angle: -sa * 0.99, velocity: -1.5, tuning: tuning) == -sa * 2)
    }

    @Test func settleTargetIsExactSlotMultiple() {
        for v in [-24.0, -3, -1.5, 0.5, 1.5, 7, 24] {
            for a in [0.0, 0.3, -0.7, 2.5, 40.1] {
                let r = SlotMath.settleTarget(angle: a, velocity: v, tuning: tuning)
                let q = r / sa
                #expect(abs(q - q.rounded()) < 1e-12)
            }
        }
    }

    @Test func settleDurationIsPointEight() {
        #expect(abs(RingSpinTuning.standard.settleDuration - 0.8) < 1e-12)
    }
}
