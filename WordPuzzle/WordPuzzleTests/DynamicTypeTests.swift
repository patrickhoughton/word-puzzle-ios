import Testing
import SwiftUI
@testable import WordPuzzle

@MainActor
@Suite struct DynamicTypeTests {

    @Test func testDefaultCategoryIsUnchangedFromPhase3() {
        #expect(HexTileView.clampedLetterSize(scaled: 34) == 34)
    }

    @Test func testSmallDynamicTypeValuesPassThroughUntouched() {
        #expect(HexTileView.clampedLetterSize(scaled: 20) == 20)
    }

    @Test func testExactlyAtCeilingPassesThrough() {
        #expect(HexTileView.clampedLetterSize(scaled: 40) == 40)
    }

    @Test func testJustOverCeilingClamps() {
        #expect(HexTileView.clampedLetterSize(scaled: 41) == 40)
    }

    @Test func testAX5MagnitudeValueClamps() {
        #expect(HexTileView.clampedLetterSize(scaled: 90) == 40)
    }

    @Test func testBaseLetterSizeIs34() {
        #expect(HexTileView.baseLetterSize == 34)
    }

    @Test func testMaxLetterSizeIs40() {
        #expect(HexTileView.maxLetterSize == 40)
    }

    @Test func testMaxLetterSizeIsGreaterThanBase() {
        // The letter does grow — the clamp is not a disguised freeze.
        #expect(HexTileView.maxLetterSize > HexTileView.baseLetterSize)
    }

    @Test func testCeilingLeavesHeadroomInsideTheHexagon() {
        #expect(HexTileView.maxLetterSize < GameTheme.hexSize * 0.6)
    }
}
