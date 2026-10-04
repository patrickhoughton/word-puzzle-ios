import Testing
import Foundation
@testable import WordPuzzle

/// Phase 7: Found Words sheet copy is frozen (07-UI-SPEC.md Copywriting Contract),
/// pinned by tests mirroring SettingsViewTests.
@MainActor
@Suite struct FoundWordsViewTests {

    @Test func testStaticCopyIsFrozen() {
        #expect(FoundWordsView.title == "Found Words")
        #expect(FoundWordsView.emptyNudge == "No words yet \u{2014} get swiping!")
        #expect(FoundWordsView.doneButtonLabel == "Done")
        #expect(FoundWordsView.scoreBarAccessibilityHint == "Shows the words you've found")
    }

    @Test func testSubtitle() {
        #expect(FoundWordsView.subtitle(rank: .adept, foundCount: 12, totalCount: 31)
                == "\(RankTier.adept.displayName) \u{2014} 12 of 31 words")
    }

    @Test func testGroupTitle() {
        #expect(FoundWordsView.groupTitle(length: 4, found: 3, total: 9) == "4 Letters \u{00B7} 3 of 9")
        #expect(FoundWordsView.groupTitle(length: 7, found: 0, total: 2) == "7 Letters \u{00B7} 0 of 2")
    }

    @Test func testGroupAccessibilityLabel() {
        #expect(FoundWordsView.groupAccessibilityLabel(length: 4, found: 3, total: 9) == "4 letters, 3 of 9 found")
        #expect(FoundWordsView.groupAccessibilityLabel(length: 5, found: 4, total: 4) == "5 letters, 4 of 4 found, complete, plus 5 bonus points")
    }

    @Test func testPointsText() {
        #expect(FoundWordsView.pointsText(14) == "+14")
    }

    @Test func testRowAccessibilityLabel() {
        #expect(FoundWordsView.rowAccessibilityLabel(FoundWord(text: "candles", points: 14, isPangram: true)) == "candles, pangram, 14 points")
        #expect(FoundWordsView.rowAccessibilityLabel(FoundWord(text: "lance", points: 5, isPangram: false)) == "lance, 5 points")
        #expect(FoundWordsView.rowAccessibilityLabel(FoundWord(text: "cane", points: 1, isPangram: false)) == "cane, 1 point")
    }

    @Test func testPangramLine() {
        #expect(FoundWordsView.pangramLine(found: 1, total: 3) == "Pangrams \u{00B7} 1 of 3")
        #expect(FoundWordsView.pangramLineAccessibilityLabel(found: 1, total: 3) == "1 of 3 pangrams found")
    }

    @Test func testGroupBonusText() {
        #expect(FoundWordsView.groupBonusText(length: 5) == "+5")
    }

    @Test func testMissedWordsBonusLines() {
        #expect(MissedWordsView.sweepLine(bonus: 21) == "Pangram sweep! +21")
        #expect(MissedWordsView.lengthBonusLine(total: 12) == "Length bonuses +12")
    }
}
