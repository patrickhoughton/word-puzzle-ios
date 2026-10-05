import XCTest

/// Phase 9 (RESEARCH Open Question 2 / Pitfall 2): proves the stats sheet presents from all
/// three entry points, in particular ON TOP of the round-over fullScreenCover.
/// Requires a FRESH app install (0 games, 0 started rounds today); uninstall the app first.
/// Starts only 2 rounds (free tier allows 3).
final class StatsPresentationUITests: XCTestCase {
    @MainActor
    func testStatsSheetPresentsFromTopBarRoundOverAndSettings() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-hasSeenTutorial", "YES"]
        app.launch()

        let finish = app.buttons["Finish Round"]
        XCTAssertTrue(finish.waitForExistence(timeout: 60), "board never loaded")

        // 1. Top bar -> sheet (fresh install: nudge visible, 0 games)
        app.buttons["topBarStatsButton"].tap()
        XCTAssertTrue(app.staticTexts["Finish a round to start your stats!"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["Games played, 0"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(finish.waitForExistence(timeout: 5))

        // 2. Finish round -> round-over cover -> summary line -> sheet ON TOP of the cover
        finish.tap()
        let next = app.buttons["Next Puzzle"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        let summary = app.buttons["roundOverStatsSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        summary.tap()
        // Snapshot includes the round just finished (D-04 ordering).
        XCTAssertTrue(app.descendants(matching: .any)["Games played, 1"].waitForExistence(timeout: 5),
                      "stats sheet did not present over the round-over cover")
        app.buttons["Done"].tap()
        XCTAssertTrue(next.waitForExistence(timeout: 5), "dismiss did not return to round-over")

        // 3. Next round -> Settings -> Stats row push
        next.tap()
        XCTAssertTrue(finish.waitForExistence(timeout: 60))
        app.buttons["Settings"].tap()
        let row = app.buttons["settingsStatsRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.descendants(matching: .any)["Games played, 1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Stats"].exists)
    }
}
