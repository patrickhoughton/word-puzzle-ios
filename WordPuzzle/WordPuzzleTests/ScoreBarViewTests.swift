import Testing
import Foundation
@testable import WordPuzzle

/// Phase 8: ScoreBarView pangram counter, overflow detection and a11y copy.
@MainActor
@Suite struct ScoreBarViewTests {

    @Test func testPangramCounterText() {
        #expect(ScoreBarView.pangramCounterText(found: 1, total: 3) == "1/3")
    }

    @Test func testIsOverflow() {
        #expect(ScoreBarView.isOverflow(progress: 1.0) == false)
        #expect(ScoreBarView.isOverflow(progress: 1.0001) == true)
        #expect(ScoreBarView.isOverflow(progress: .infinity) == false)
        #expect(ScoreBarView.isOverflow(progress: .nan) == false)
        #expect(ScoreBarView.isOverflow(progress: 0.5) == false)
    }

    @Test func testAccessibilityText() {
        #expect(ScoreBarView.accessibilityText(rank: .adept, foundCount: 12, totalCount: 31, foundPangrams: 1, totalPangrams: 3, progress: 0.4, freePuzzlesRemaining: nil, freePuzzlesPerDay: 3)
                == "Rank Adept. 12 of 31 words found. 1 of 3 pangrams found.")
        #expect(ScoreBarView.accessibilityText(rank: .adept, foundCount: 12, totalCount: 31, foundPangrams: 1, totalPangrams: 3, progress: 1.2, freePuzzlesRemaining: 2, freePuzzlesPerDay: 3)
                == "Rank Adept. 12 of 31 words found. 1 of 3 pangrams found. Progress beyond maximum. 2 of 3 free puzzles remaining today.")
        #expect(ScoreBarView.accessibilityText(rank: .adept, foundCount: 12, totalCount: 31, foundPangrams: 0, totalPangrams: 0, progress: 0.4, freePuzzlesRemaining: nil, freePuzzlesPerDay: 3)
                == "Rank Adept. 12 of 31 words found.")
    }
}
