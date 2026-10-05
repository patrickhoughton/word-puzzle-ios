import XCTest

/// Drives real gameplay to the three App Store screenshot states (05-07 / UX-04)
/// and writes each full-screen capture as a PNG into SCREENSHOT_DIR.
///
/// Skipped unless SCREENSHOT_DIR is set, so ordinary test runs never touch it.
/// Run via `bash scripts/capture-app-store-screenshots.sh`, which resets the app's
/// data first: the paywall shot depends on starting the day with 0 puzzles played.
///
/// Every round is pinned to one known puzzle via the app's DEBUG-only
/// `-ScreenshotPuzzle` launch argument, so the captures are reproducible and the
/// words on screen are curated rather than whatever the generator happened to pick.
/// Launches with -hasSeenTutorial YES so the Phase 11 tutorial never intercepts the staged puzzle.
final class AppStoreScreenshotTests: XCTestCase {

    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !dir.isEmpty else {
            throw XCTSkip("SCREENSHOT_DIR not set — App Store screenshot capture runs only on demand")
        }
        outputDirectory = URL(fileURLWithPath: dir, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    /// The staged puzzle (DEBUG-only `-ScreenshotPuzzle` launch argument): HARMONY with
    /// center R — 56 everyday words and a single, readable pangram.
    private let stagedPuzzle = "harmony:r"
    /// Submitted before shot 1. Hand-picked so the round-end missed list (shot 2) shows
    /// only friendly words; the pangram is deliberately left unfound for its badge.
    private let stagedWords = ["honorary", "armory", "hooray", "horror", "maroon", "mayor",
                               "manor", "honor", "mammary", "moron", "roomy", "marry"]
    /// Left assembled but unsubmitted in shot 1, hinting at the pangram.
    private let inProgressWord = "harmo"

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        app = XCUIApplication()
        app.launchArguments += ["-ScreenshotPuzzle", stagedPuzzle, "-hasSeenTutorial", "YES"]
        app.launch()

        // 1 — Mid-round gameplay: several words found, a partial word in progress.
        let centerTile = app.staticTexts["Center letter R"]
        XCTAssertTrue(centerTile.waitForExistence(timeout: 30), "staged HARMONY puzzle never loaded")
        for word in stagedWords {
            enter(word)
            submit()
        }
        // Let the last "+N" feedback fade so it does not cover the in-progress word.
        sleep(2)
        enter(inProgressWord)
        XCTAssertTrue(app.staticTexts["Assembled word \(inProgressWord)"].exists)
        save("01-gameplay")

        // 2 — Round-end reveal scrolled to a missed pangram badge. Pangrams are
        // deliberately never submitted above, so at least one is always missed.
        app.buttons["Finish Round"].tap()
        XCTAssertTrue(app.buttons["Next Puzzle"].waitForExistence(timeout: 5))
        // MissedWordsView is a LazyVStack grouped shortest-first, so the pangram row
        // does not exist in the hierarchy until it has been scrolled near.
        let pangramRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label ENDSWITH %@", ", pangram")).firstMatch
        var swipes = 0
        while !(pangramRow.exists && pangramRow.isHittable) && swipes < 40 {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            swipes += 1
        }
        XCTAssertTrue(pangramRow.exists && pangramRow.isHittable, "could not scroll a missed pangram into view")
        // The longest words (including the pangram) are last, so settle at the very
        // bottom; a merely hittable row can still be clipped by the list's edge.
        for _ in 0..<3 { app.scrollViews.firstMatch.swipeUp(velocity: .fast) }
        sleep(3)  // let the scroll indicator fade out
        save("02-round-end")

        // 3 — Paywall: rounds 2 and 3 use up the free daily limit (3 started rounds).
        for _ in 0..<2 {
            app.buttons["Next Puzzle"].tap()
            XCTAssertTrue(app.buttons["Finish Round"].waitForExistence(timeout: 30))
            app.buttons["Finish Round"].tap()
            XCTAssertTrue(app.buttons["Next Puzzle"].waitForExistence(timeout: 5))
        }
        app.buttons["Next Puzzle"].tap()
        XCTAssertTrue(app.buttons["Unlock Unlimited Puzzles"].waitForExistence(timeout: 10))
        // A dash means the StoreKit product never loaded — never ship that shot.
        let price = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "$")).firstMatch
        XCTAssertTrue(price.waitForExistence(timeout: 20), "paywall price did not load (still showing a dash)")
        sleep(1)
        save("03-paywall")
    }

    // MARK: - Input

    @MainActor
    private func enter(_ word: String) {
        for letter in word.uppercased() {
            let tile = app.staticTexts.matching(
                NSPredicate(format: "label == %@ OR label == %@", "Letter \(letter)", "Center letter \(letter)")
            ).firstMatch
            tile.tap()
        }
    }

    /// Swipe down on the assembled word past WordDisplayView's 60pt submit threshold.
    @MainActor
    private func submit() {
        let display = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Assembled word")).firstMatch
        let start = display.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 140)))
        usleep(400_000)
    }

    // MARK: - Output

    @MainActor
    private func save(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = outputDirectory.appendingPathComponent("\(name).png")
        XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: url))
    }
}
