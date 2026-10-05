import Testing
import Foundation
import CoreGraphics
@testable import WordPuzzle

@MainActor
@Suite struct RingSpinControllerTests {
    final class Clock { var now: TimeInterval = 100 }

    let center = CGPoint(x: 175, y: 175)
    let t0 = Date(timeIntervalSinceReferenceDate: 1000)
    let clock = Clock()
    let c: RingSpinController
    let log: EventLog

    final class EventLog { var events: [RingSpinEvent] = [] }

    init() {
        let clk = clock
        c = RingSpinController(clock: { clk.now }, usesDisplayLink: false)
        let l = EventLog()
        log = l
        c.onEvent = { l.events.append($0) }
    }

    func p(_ theta: Double) -> CGPoint {
        CGPoint(x: 175 + 160 * cos(theta), y: 175 + 160 * sin(theta))
    }
    var start: CGPoint { p(-.pi / 2) }
    func tr(_ theta: Double, _ dt: TimeInterval) {
        c.track(point: p(theta), start: start, center: center, time: t0.addingTimeInterval(dt))
    }
    /// Cross the slop; returns the theta at which angle == 0.
    @discardableResult func crossSlop() -> Double {
        c.touchDown()
        tr(-.pi / 2 + 0.02, 0)
        tr(-.pi / 2 + 0.08, 0.01)
        return -.pi / 2 + 0.08
    }
    func runToIdle() -> Int {
        var n = 0
        while c.phase != .idle && n < 2000 {
            clock.now += 1.0 / 60; c.step(); n += 1
        }
        return n
    }
    var settledCount: Int { log.events.filter { if case .settled = $0 { return true }; return false }.count }
    var tickTotal: Int { log.events.reduce(0) { if case .ticks(let n, _) = $1 { return $0 + n }; return $0 } }

    @Test func tapDoesNothing() {
        c.touchDown()
        tr(-.pi / 2 + 0.018, 0)
        c.release(time: t0.addingTimeInterval(0.1))
        #expect(log.events.isEmpty)
        #expect(c.phase == .idle)
        #expect(c.angle == 0)
    }

    @Test func slopNoJump() {
        c.touchDown()
        tr(-.pi / 2 + 0.02, 0)
        #expect(c.angle == 0)
        tr(-.pi / 2 + 0.08, 0.01)
        #expect(c.angle == 0)
        #expect(log.events == [.began])
        tr(-.pi / 2 + 0.58, 0.02)
        #expect(abs(c.angle - 0.5) < 1e-6)
        #expect(c.phase == .tracking)
    }

    @Test func seamIsContinuous() {
        c.touchDown()
        let s = CGPoint(x: p(.pi - 0.3).x, y: p(.pi - 0.3).y)
        func t(_ th: Double, _ dt: Double) { c.track(point: p(th), start: s, center: center, time: t0.addingTimeInterval(dt)) }
        t(.pi - 0.2, 0)
        t(.pi - 0.1, 0.01)
        t(.pi, 0.02)
        t(.pi + 0.1, 0.03)
        t(.pi + 0.2, 0.04)
        #expect(abs(c.angle - 0.4) < 1e-6)
    }

    @Test func ticksOnBoundary() {
        let base = crossSlop()
        tr(base + 0.3, 0.02)
        tr(base + 0.6, 0.03)
        #expect(tickTotal == 1)
    }

    @Test func pausedReleaseSettles() {
        let base = crossSlop()
        tr(base + 0.35, 0.05)
        tr(base + 0.7, 0.1)
        c.release(time: t0.addingTimeInterval(0.4))
        #expect(c.phase == .coasting)
        clock.now += 1.0
        c.step()
        #expect(Array(log.events.suffix(2)) == [.clunk, .settled(slots: 1)])
        #expect(c.phase == .idle)
        #expect(c.angle == 0)
    }

    func flick(_ sign: Double) {
        let base = crossSlop()
        for i in 1...5 { tr(base + sign * 0.2 * Double(i), 0.01 + 0.0125 * Double(i)) }
        c.release(time: t0.addingTimeInterval(0.01 + 0.0625))
    }

    @Test func flickCoasts() {
        flick(1)
        #expect(c.phase == .coasting)
        let n = runToIdle()
        #expect(Double(n) / 60 >= 4.0)
        #expect(settledCount == 1)
        #expect(tickTotal >= 10)
        let evs = log.events
        #expect(evs[evs.count - 2] == .clunk)
        if case .settled(let s) = evs.last! { #expect(s > 0) } else { Issue.record("last not settled: \(evs.last!)") }
        #expect(c.angle == 0)
    }

    @Test func counterClockwiseFlickNegative() {
        flick(-1)
        _ = runToIdle()
        if case .settled(let s) = log.events.last! { #expect(s < 0) } else { Issue.record("no settle") }
    }

    @Test func grabFreezes() {
        flick(1)
        clock.now += 0.5; c.step()
        let a = c.angle
        c.touchDown()
        #expect(c.phase == .tracking)
        clock.now += 0.5; c.step()
        #expect(c.angle == a)
        c.release(time: t0.addingTimeInterval(5))
        _ = runToIdle()
        #expect(settledCount == 1)
        #expect(c.phase == .idle)
    }

    @Test func cancelAndCommitMidCoast() {
        flick(1)
        clock.now += 0.5; c.step()
        let before = c.angle
        c.cancelAndCommit()
        #expect(Array(log.events.suffix(2)) == [.clunk, .settled(slots: SlotMath.detent(before))])
        #expect(!log.events.contains(.jackpot))
        #expect(c.phase == .idle)
        #expect(c.angle == 0)
        let count = log.events.count
        tr(0.3, 9)
        #expect(log.events.count == count)
    }

    @Test func cancelWhenIdleNoEvents() {
        c.cancelAndCommit()
        #expect(log.events.isEmpty)
    }

    @Test func resetEmitsNothing() {
        flick(1)
        clock.now += 0.3; c.step()
        let count = log.events.count
        c.reset()
        #expect(log.events.count == count)
        #expect(c.phase == .idle)
        #expect(c.angle == 0)
    }

    @Test func reduceMotionSnaps() {
        c.reduceMotion = true
        flick(1)
        #expect(c.phase == .idle)
        let evs = log.events
        #expect(tickTotal >= 1)
        #expect(evs.suffix(2).first == .clunk)
        if case .settled = evs.last! {} else { Issue.record("expected settled") }
    }

    func windRevs(extra: Double) {
        let base = crossSlop()
        let total = 6 * 2 * Double.pi + extra
        var a = 0.0, i = 0
        while a < total {
            a = min(total, a + 0.2); i += 1
            tr(base + a, 0.01 + 0.02 * Double(i))
        }
        c.release(time: t0.addingTimeInterval(0.01 + 0.02 * Double(i) + 0.3))
        _ = runToIdle()
    }

    @Test func jackpot() {
        windRevs(extra: 0.1)
        let evs = log.events
        #expect(evs.last == .jackpot)
        #expect(evs[evs.count - 2] == .settled(slots: 36))
    }

    @Test func noJackpotWhenNotAligned() {
        windRevs(extra: SlotMath.slotAngle)
        #expect(log.events.contains(.settled(slots: 37)))
        #expect(!log.events.contains(.jackpot))
    }

    @Test func zeroSlotSessionSettles() {
        let base = crossSlop()
        tr(base + 0.2, 0.05)
        tr(base, 0.1)
        c.release(time: t0.addingTimeInterval(0.5))
        _ = runToIdle()
        #expect(settledCount == 1)
        #expect(log.events.last == .settled(slots: 0))
    }
}
