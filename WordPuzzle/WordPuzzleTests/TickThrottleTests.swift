import Testing
import Foundation
@testable import WordPuzzle

@Suite struct TickThrottleTests {
    private let both = TickThrottle.Decision(haptic: true, sound: true)

    @Test func zeroCrossingsIsNone() {
        var t = TickThrottle()
        do { let d = t.register(crossings: 0, at: 10, rate: 5); #expect(d == .none) }
        do { let d = t.register(crossings: 1, at: 10, rate: 5); #expect(d == both) }
    }

    @Test func intervalsGateIndependently() {
        var t = TickThrottle()
        do { let d = t.register(crossings: 1, at: 10, rate: 5); #expect(d == both) }
        do { let d = t.register(crossings: 1, at: 10.03, rate: 5); #expect(d == .none) }
        do { let d = t.register(crossings: 1, at: 10.05, rate: 5); #expect(d == TickThrottle.Decision(haptic: true, sound: false)) }
        do { let d = t.register(crossings: 1, at: 10.06, rate: 5); #expect(d == TickThrottle.Decision(haptic: false, sound: true)) }
    }

    @Test func decimatesAboveRate() {
        var t = TickThrottle()
        var results: [TickThrottle.Decision] = []
        for i in 0..<5 { results.append(t.register(crossings: 1, at: 10 + 0.1 * Double(i), rate: 25)) }
        #expect(results == [both, .none, both, .none, both])
    }

    @Test func noDecimationAtLowRate() {
        var t = TickThrottle()
        for i in 0..<5 { let d = t.register(crossings: 1, at: 10 + 0.1 * Double(i), rate: 10); #expect(d == both) }
    }

    @Test func multiCrossingIsOneEvent() {
        var t = TickThrottle()
        do { let d = t.register(crossings: 3, at: 10, rate: 5); #expect(d == both) }
        do { let d = t.register(crossings: 1, at: 10.01, rate: 5); #expect(d == .none) }
    }

    @Test func resetFiresImmediately() {
        var t = TickThrottle()
        _ = t.register(crossings: 1, at: 10, rate: 5)
        t.reset()
        do { let d = t.register(crossings: 1, at: 10.001, rate: 5); #expect(d == both) }
    }
}
