import Testing
import Foundation
@testable import WordPuzzle

/// Phase 9 D-04: pins the round-over "Best B · Streak S" summary copy.
@MainActor
@Suite struct MissedWordsViewTests {

    @Test func testSummaryLineCopy() {
        #expect(MissedWordsView.statsSummaryLine(bestScore: 142, currentStreak: 4) == "Best 142 · Streak 4")
        #expect(MissedWordsView.statsSummaryLine(bestScore: 0, currentStreak: 0) == "Best 0 · Streak 0")
    }

    @Test func testSummaryAccessibilityHint() {
        #expect(MissedWordsView.statsSummaryAccessibilityHint == "Opens your stats")
    }

    @Test func testSummaryAccessibilityLabelPluralisation() {
        #expect(MissedWordsView.statsSummaryAccessibilityLabel(bestScore: 142, currentStreak: 4) == "Best score 142, streak 4 days")
        #expect(MissedWordsView.statsSummaryAccessibilityLabel(bestScore: 142, currentStreak: 1) == "Best score 142, streak 1 day")
    }

    @Test func testDefaultsHideSummaryLine() {
        let view = MissedWordsView(groups: [], pangrams: [], rank: .novice, foundCount: 0, totalCount: 0, onContinue: {})
        #expect(view.onShowStats == nil)
        #expect(view.bestScore == 0)
        #expect(view.currentStreak == 0)
    }
}
