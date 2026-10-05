import Testing
import Foundation
@testable import WordPuzzle

@MainActor
@Suite struct SpinFeedbackTests {
    final class Box { var t: TimeInterval = 0 }

    func make() -> (SpinFeedback, SoundManager, Box) {
        let s = SoundManager(preloadPlayers: false)
        let b = Box()
        return (SpinFeedback(sound: s, clock: { b.t }), s, b)
    }

    @Test func singleTickPlays() {
        let (f, s, _) = make()
        f.ticks(count: 1, speed: 5, soundEnabled: true)
        #expect(s.attemptedPlayCount == 1)
        #expect(s.lastAttemptedEffect == .spinTick)
    }

    @Test func burstIsThrottled() {
        let (f, s, _) = make()
        for _ in 0..<10 { f.ticks(count: 1, speed: 5, soundEnabled: true) }
        #expect(s.attemptedPlayCount == 1)
    }

    @Test func spacedTicksAllPlay() {
        let (f, s, b) = make()
        for t in [0.0, 0.06, 0.12] { b.t = t; f.ticks(count: 1, speed: 5, soundEnabled: true) }
        #expect(s.attemptedPlayCount == 3)
    }

    @Test func soundDisabledNoAttempt() {
        let (f, s, _) = make()
        f.ticks(count: 1, speed: 5, soundEnabled: false)
        #expect(s.attemptedPlayCount == 0)
    }

    @Test func clunkAndGate() {
        let (f, s, _) = make()
        f.clunk(soundEnabled: false)
        #expect(s.attemptedPlayCount == 0)
        f.clunk(soundEnabled: true)
        #expect(s.lastAttemptedEffect == .spinClunk)
    }

    @Test func jackpotPlaysFullCircle() {
        let (f, s, _) = make()
        f.jackpot(soundEnabled: true)
        #expect(s.lastAttemptedEffect == .fullCircle)
    }

    @Test func prepareResetsThrottle() {
        let (f, s, _) = make()
        f.ticks(count: 1, speed: 5, soundEnabled: true)
        f.prepare()
        f.ticks(count: 1, speed: 5, soundEnabled: true)
        #expect(s.attemptedPlayCount == 2)
    }
}
