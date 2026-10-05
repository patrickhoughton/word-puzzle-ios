import XCTest

/// End-to-end tests for the Phase 11 first-launch tutorial (TUT-01..TUT-07).
final class TutorialUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Helpers

    private var banner: XCUIElement { app.descendants(matching: .any)["tutorialBanner"] }
    private var skipLink: XCUIElement { app.descendants(matching: .any)["tutorialSkipLink"] }

    private var wordDisplay: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@",
                                             "No word assembled", "Assembled word")).firstMatch
    }

    private func waitForBanner(containing text: String, timeout: TimeInterval = 10) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", text), object: banner)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    private func enter(_ word: String) {
        for letter in word.uppercased() {
            app.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@", "Letter \(letter)", "Center letter \(letter)")).firstMatch.tap()
        }
    }

    private func submit() {
        let display = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Assembled word")).firstMatch
        let start = display.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 140)))
        usleep(400_000)
    }

    // MARK: - Tests

    @MainActor
    func testFullTutorialHandsOffToRealPuzzle() throws {
        app.launchArguments += ["-hasSeenTutorial", "NO"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Center letter P"].waitForExistence(timeout: 60), "practice board")
        XCTAssertTrue(waitForBanner(containing: "POND"), "step 1 banner")

        // Gating: a wrong tile does nothing.
        app.staticTexts["Letter D"].tap()
        XCTAssertEqual(wordDisplay.label, "No word assembled", "wrong tile must be ignored")

        // Step 1: build
        enter("POND")
        XCTAssertTrue(waitForBanner(containing: "HOLD"), "step 2 banner")

        // Step 2: center miss
        enter("HOLD")
        submit()
        XCTAssertTrue(waitForBanner(containing: "gold letter", timeout: 5), "center-miss explanation")
        app.staticTexts["Center letter P"].tap()

        // Step 3: swipe
        XCTAssertTrue(waitForBanner(containing: "Swipe down"), "step 3 banner")
        enter("OND")
        submit()

        // Step 4: fix a mistake
        XCTAssertTrue(waitForBanner(containing: "Delete"), "step 4 banner")
        XCTAssertTrue(app.staticTexts["Assembled word polo"].exists, "pre-filled polo")
        app.buttons["Delete Last Letter"].tap()
        XCTAssertTrue(app.staticTexts["Assembled word pol"].waitForExistence(timeout: 3), "delete last letter")
        wordDisplay.tap()
        XCTAssertTrue(waitForBanner(containing: "PLOD"), "step 5 banner")

        // Step 5: drag word (entered by taps)
        enter("PLOD")
        submit()
        XCTAssertTrue(waitForBanner(containing: "Shuffle"), "step 6 banner")

        // Step 6: shuffle
        app.buttons["Shuffle Letters"].tap()
        XCTAssertTrue(waitForBanner(containing: "pangram"), "step 7 banner")

        // Step 7: pangram
        enter("DOLPHIN")
        submit()
        XCTAssertTrue(waitForBanner(containing: "Tap the bar", timeout: 10), "step 8 banner")

        // Step 8: score bar
        app.buttons["scoreBarButton"].tap()
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "found words sheet")
        done.tap()
        XCTAssertTrue(waitForBanner(containing: "You're ready!"), "step 9 banner")

        // Step 9: finish hands off to a real board
        app.buttons["Finish Round"].tap()
        XCTAssertFalse(app.buttons["Next Puzzle"].waitForExistence(timeout: 3), "no missed-words cover after tutorial")
        XCTAssertTrue(waitForDisappearance(banner), "banner gone")
        XCTAssertTrue(waitForDisappearance(skipLink), "skip link gone")
        XCTAssertTrue(app.buttons["Finish Round"].exists, "real board shown")
    }

    @MainActor
    func testSkipStartsRealPuzzle() throws {
        app.launchArguments += ["-hasSeenTutorial", "NO"]
        app.launch()

        XCTAssertTrue(skipLink.waitForExistence(timeout: 60), "skip link")
        skipLink.tap()
        XCTAssertTrue(waitForDisappearance(banner, timeout: 10), "banner gone after skip")
        XCTAssertTrue(app.buttons["Finish Round"].waitForExistence(timeout: 10), "real board")
        XCTAssertFalse(app.buttons["Next Puzzle"].exists)
    }

    @MainActor
    func testReplayFromSettingsResumesRealRound() throws {
        app.launchArguments += ["-hasSeenTutorial", "YES"]
        app.launch()

        XCTAssertTrue(app.buttons["Finish Round"].waitForExistence(timeout: 60), "real round")
        let center = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Center letter")).firstMatch
        XCTAssertTrue(center.exists)
        let before = center.label

        app.buttons["Settings"].tap()
        let row = app.descendants(matching: .any)["settingsHowToPlayRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "How to Play row")
        row.tap()

        XCTAssertTrue(banner.waitForExistence(timeout: 10), "tutorial banner")
        XCTAssertTrue(app.staticTexts["Center letter P"].waitForExistence(timeout: 10), "practice board")
        skipLink.tap()
        XCTAssertTrue(waitForDisappearance(banner, timeout: 10), "banner gone")

        let after = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Center letter")).firstMatch
        XCTAssertTrue(after.waitForExistence(timeout: 10))
        XCTAssertEqual(after.label, before, "same real round resumed")
    }
}
