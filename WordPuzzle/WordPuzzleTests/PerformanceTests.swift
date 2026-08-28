import XCTest
@testable import WordPuzzle

final class PerformanceTests: XCTestCase {
    var wordList: WordList!

    override func setUp() async throws {
        wordList = WordList()
        await wordList.load()   // load once; NOT part of the measured window
    }

    // Primary PUZZ-03 gate: hard 500ms ceiling
    func testGenerationUnder500ms() throws {
        let start = Date()
        _ = try generatePuzzle(from: wordList)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 0.500, "Puzzle generation took \(elapsed)s — exceeds 500ms target")
    }

    // Secondary: regression baseline (10 runs). Set baseline on device after first run.
    func testGenerationPerformanceBaseline() {
        measure {
            _ = try? generatePuzzle(from: wordList)
        }
    }
}
