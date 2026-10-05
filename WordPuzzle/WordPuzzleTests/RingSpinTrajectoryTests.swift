import Testing
import Foundation
@testable import WordPuzzle

@Suite struct RingSpinTrajectoryTests {
    static let velocities: [Double] = [0, 0.5, 1, 3, 10, 24, -3, -10, -24]
    static let starts: [Double] = [0, 0.3, -0.7, 2.5]
    static let grid: [[Double]] = velocities.flatMap { v in starts.map { [v, $0] } }

    @Test func continuousAtHandoff() {
        let tr = RingSpinTrajectory(startAngle: 0, velocity: 10)
        let h = tr.handoffTime
        #expect(abs(tr.angle(at: h - 1e-6) - tr.angle(at: h + 1e-6)) < 1e-4)
        #expect(abs(tr.velocity(at: h - 1e-6) - tr.velocity(at: h + 1e-6)) < 1e-3)
    }

    @Test func startsAtStartState() {
        let tr = RingSpinTrajectory(startAngle: 0.4, velocity: 10)
        #expect(abs(tr.angle(at: 0) - 0.4) < 1e-9)
        #expect(abs(tr.velocity(at: 0) - tr.releaseVelocity) < 1e-9)
    }

    @Test func durationMonotonic() {
        let ws: [Double] = [0.5, 1, 2, 3, 6, 10, 16, 24]
        let d = ws.map { RingSpinTrajectory(startAngle: 0, velocity: $0).duration }
        for i in 1..<d.count { #expect(d[i] >= d[i - 1]) }
        for i in 3..<d.count { #expect(d[i] > d[i - 1]) }   // 3...24 strictly (2 -> 3 too)
        #expect(d[3] > d[2])
    }

    @Test func maxFlickCoastsAtLeastFiveSeconds() {
        let tr = RingSpinTrajectory(startAngle: 0, velocity: 24)
        #expect(tr.duration >= 5.0)
        #expect(tr.handoffTime >= 5.0)
    }

    @Test func clampsReleaseVelocity() {
        let a = RingSpinTrajectory(startAngle: 0, velocity: 100)
        let b = RingSpinTrajectory(startAngle: 0, velocity: 24)
        #expect(a.releaseVelocity == 24)
        #expect(a.duration == b.duration)
    }

    @Test func smallReleaseIsNoFlick() {
        let tr = RingSpinTrajectory(startAngle: 0.2, velocity: 0.2)
        #expect(tr.releaseVelocity == 0)
        #expect(tr.handoffTime == 0)
        #expect(tr.targetAngle == SlotMath.nearestSlotAngle(0.2))
    }

    @Test(arguments: grid) func landsExactly(_ p: [Double]) {
        let tr = RingSpinTrajectory(startAngle: p[1], velocity: p[0])
        #expect(tr.angle(at: tr.duration) == tr.targetAngle)
        #expect(tr.velocity(at: tr.duration) == 0)
        let q = tr.targetAngle / SlotMath.slotAngle
        #expect(abs(q - q.rounded()) < 1e-12)
    }

    @Test(arguments: grid) func neverOvershoots(_ p: [Double]) {
        let w0 = p[0], start = p[1]
        let tr = RingSpinTrajectory(startAngle: start, velocity: w0)
        var prev = tr.angle(at: 0)
        var t = 0.0
        while t <= tr.duration {
            let a = tr.angle(at: t)
            if w0 > 0 {
                #expect(a >= prev - 1e-9)
                #expect(a <= tr.targetAngle + 1e-9)
            } else if w0 < 0 {
                #expect(a <= prev + 1e-9)
                #expect(a >= tr.targetAngle - 1e-9)
            } else {
                #expect(a >= min(start, tr.targetAngle) - 1e-9)
                #expect(a <= max(start, tr.targetAngle) + 1e-9)
            }
            prev = a
            t += 0.001
        }
    }

    @Test func signSymmetry() {
        #expect(RingSpinTrajectory(startAngle: 0, velocity: -10).targetAngle
                == -RingSpinTrajectory(startAngle: 0, velocity: 10).targetAngle)
    }

    @Test func jackpotReachable() {
        #expect(RingSpinTrajectory(startAngle: 0, velocity: 24).targetAngle >= 12 * .pi)
    }

    @Test func softPushIsShort() {
        #expect(RingSpinTrajectory(startAngle: 0, velocity: 1).duration <= 1.0)
    }
}
