import Testing
import Foundation
@testable import WordPuzzle

@Suite struct FullCircleViewTests {
    @Test func titleIsFullCircle() { #expect(FullCircleView.title == "Full circle!") }

    @Test func announcementText() {
        #expect(FullCircleView.announcement == "Full circle! Every letter spun all the way home.")
    }

    @Test func copyIsCosmeticNoPoints() {
        for s in [FullCircleView.title, FullCircleView.announcement] {
            #expect(!s.contains("+"))
            #expect(s.rangeOfCharacter(from: .decimalDigits) == nil)
        }
    }

    @Test func themeConstants() {
        #expect(GameTheme.fullCircleHoldSeconds == 1.6)
        #expect(GameTheme.fullCircleSparkleCount == 12)
        #expect(GameTheme.fullCircleBurstSeconds == 0.9)
        #expect(GameTheme.fullCircleBurstRadius == 90)
    }
}
