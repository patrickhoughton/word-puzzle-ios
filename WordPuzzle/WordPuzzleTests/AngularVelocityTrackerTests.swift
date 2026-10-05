import Testing
import Foundation
@testable import WordPuzzle

@Suite struct AngularVelocityTrackerTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 1000)

    private func steadyWind(_ sign: Double = 1) -> AngularVelocityTracker {
        var t = AngularVelocityTracker()
        for i in 0...10 {
            t.add(rawAngle: sign * 0.05 * Double(i), at: t0.addingTimeInterval(0.01 * Double(i)))
        }
        return t
    }

    @Test func normalizedDeltaWraps() {
        #expect(AngularVelocityTracker.normalizedDelta(0.1) == 0.1)
        #expect(abs(AngularVelocityTracker.normalizedDelta(2 * .pi - 0.1) - -0.1) < 1e-9)
        #expect(abs(AngularVelocityTracker.normalizedDelta(-2 * .pi + 0.1) - 0.1) < 1e-9)
        #expect(AngularVelocityTracker.normalizedDelta(.pi) == .pi)
    }

    @Test func seamCrossingDoesNotSpike() {
        var t = AngularVelocityTracker()
        t.add(rawAngle: 3.0, at: t0)
        t.add(rawAngle: -3.0, at: t0.addingTimeInterval(0.01))
        #expect(abs(t.accumulatedAngle - (2 * .pi - 6.0)) < 1e-9)
    }

    @Test func firstSampleIsZero() {
        var t = AngularVelocityTracker()
        t.add(rawAngle: 1.2, at: t0)
        #expect(t.accumulatedAngle == 0)
    }

    @Test func steadyClockwise() {
        let t = steadyWind()
        #expect(abs(t.velocity(at: t0.addingTimeInterval(0.1)) - 5.0) < 0.01)
    }

    @Test func steadyCounterClockwise() {
        let t = steadyWind(-1)
        #expect(abs(t.velocity(at: t0.addingTimeInterval(0.1)) + 5.0) < 0.01)
    }

    @Test func oldSamplesIgnored() {
        var t = AngularVelocityTracker()
        // slow start: 0.1 rad/s for 0.5 s, then fast 10 rad/s for the last 0.1 s
        var angle = 0.0
        for i in 0..<50 {
            t.add(rawAngle: angle, at: t0.addingTimeInterval(0.01 * Double(i)))
            angle += 0.001
        }
        for i in 50...60 {
            t.add(rawAngle: angle, at: t0.addingTimeInterval(0.01 * Double(i)))
            angle += 0.1
        }
        let v = t.velocity(at: t0.addingTimeInterval(0.6))
        #expect(abs(v - 10.0) < 0.5)
    }

    @Test func staleReleaseIsZero() {
        let t = steadyWind()
        #expect(t.velocity(at: t0.addingTimeInterval(0.1 + 0.2)) == 0)
    }

    @Test func tooFewSamplesOrShortSpanIsZero() {
        var t = AngularVelocityTracker()
        t.add(rawAngle: 0, at: t0)
        #expect(t.velocity(at: t0) == 0)
        t.add(rawAngle: 1, at: t0.addingTimeInterval(0.005))
        #expect(t.velocity(at: t0.addingTimeInterval(0.005)) == 0)
    }

    @Test func clampsToMaxSpeed() {
        var t = AngularVelocityTracker()
        t.add(rawAngle: 0, at: t0)
        t.add(rawAngle: 2, at: t0.addingTimeInterval(0.02))
        #expect(t.velocity(at: t0.addingTimeInterval(0.02)) == 24)
        var m = AngularVelocityTracker()
        m.add(rawAngle: 0, at: t0)
        m.add(rawAngle: -2, at: t0.addingTimeInterval(0.02))
        #expect(m.velocity(at: t0.addingTimeInterval(0.02)) == -24)
    }

    @Test func slowIsRest() {
        var t = AngularVelocityTracker()
        t.add(rawAngle: 0, at: t0)
        t.add(rawAngle: 0.002, at: t0.addingTimeInterval(0.01))
        #expect(t.velocity(at: t0.addingTimeInterval(0.01)) == 0)
    }

    @Test func resetClears() {
        var t = steadyWind()
        t.reset()
        #expect(t.sampleCount == 0)
        #expect(t.accumulatedAngle == 0)
    }
}
