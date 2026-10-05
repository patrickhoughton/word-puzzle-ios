import Testing
import Foundation
@testable import WordPuzzle

@Suite struct SpinSessionTests {
    @Test func sixRevolutionsHomeIsJackpot() {
        #expect(SpinSession.isJackpot(netAngle: 12 * .pi))
        #expect(SpinSession.isJackpot(netAngle: -12 * .pi))
    }

    @Test func exactlyFiveRevolutionsIsNot() {
        #expect(!SpinSession.isJackpot(netAngle: 10 * .pi))
    }

    @Test func notHomeIsNot() {
        #expect(!SpinSession.isJackpot(netAngle: 12 * .pi + .pi / 3))
    }

    @Test func smallOrZeroNetIsNot() {
        #expect(!SpinSession.isJackpot(netAngle: 2 * .pi))
        #expect(!SpinSession.isJackpot(netAngle: 0))
    }

    @Test func regrabKeepsSession() {
        var s = SpinSession()
        s.begin(at: 0)
        s.begin(at: 5)
        #expect(s.startAngle == 0)
        let r = s.end(finalAngle: 12 * .pi)
        #expect(r)
        #expect(!s.isOpen)
    }

    @Test func endWithoutBeginIsFalse() {
        var s = SpinSession()
        let r = s.end(finalAngle: 12 * .pi)
        #expect(!r)
    }

    @Test func netNotAbsolute() {
        var s = SpinSession()
        s.begin(at: .pi / 3)
        let r = s.end(finalAngle: .pi / 3 + 12 * .pi)
        #expect(r)
    }
}
