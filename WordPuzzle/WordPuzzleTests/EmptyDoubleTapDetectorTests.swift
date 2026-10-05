import Testing
import Foundation
import CoreGraphics
@testable import WordPuzzle

@Suite struct EmptyDoubleTapDetectorTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 1000)
    let p = CGPoint(x: 10, y: 10)

    private func tap(_ d: inout EmptyDoubleTapDetector, at offset: TimeInterval, _ pt: CGPoint) -> Bool {
        d.registerEmptyTap(start: pt, end: pt, at: t0.addingTimeInterval(offset))
    }

    @Test func firesOnSecondQuickCloseTap() {
        var d = EmptyDoubleTapDetector()
        #expect(tap(&d, at: 0, p) == false)
        #expect(tap(&d, at: 0.2, CGPoint(x: 15, y: 15)) == true)
    }

    @Test func firstTapNeverFires() {
        var d = EmptyDoubleTapDetector()
        #expect(tap(&d, at: 0, p) == false)
    }

    @Test func rejectsWhenIntervalTooLong() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        #expect(tap(&d, at: 0.31, p) == false)
    }

    @Test func acceptsJustInsideInterval() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        #expect(tap(&d, at: 0.29, p) == true)
    }

    @Test func rejectsWhenTapsTooFarApart() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        #expect(tap(&d, at: 0.1, CGPoint(x: 70, y: 10)) == false)
    }

    @Test func rejectsDragTravel() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        let dragged = d.registerEmptyTap(start: p, end: CGPoint(x: 25, y: 10), at: t0.addingTimeInterval(0.1))
        #expect(dragged == false)
        #expect(tap(&d, at: 0.15, p) == false)
    }

    @Test func resetBreaksChain() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        d.reset()
        #expect(tap(&d, at: 0.1, p) == false)
    }

    @Test func tripleTapFiresOnceThenRestarts() {
        var d = EmptyDoubleTapDetector()
        #expect(tap(&d, at: 0, p) == false)
        #expect(tap(&d, at: 0.1, p) == true)
        #expect(tap(&d, at: 0.2, p) == false)
        #expect(tap(&d, at: 0.3, p) == true)
    }

    @Test func slowSecondTapStartsNewChain() {
        var d = EmptyDoubleTapDetector()
        _ = tap(&d, at: 0, p)
        #expect(tap(&d, at: 0.5, p) == false)
        #expect(tap(&d, at: 0.7, p) == true)
    }
}
