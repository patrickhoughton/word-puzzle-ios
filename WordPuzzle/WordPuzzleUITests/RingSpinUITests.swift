import XCTest

/// Phase 12 end-to-end gesture checks. Requires a fresh install (free tier: 3 rounds/day); uninstall first.
/// One launch, one round.
final class RingSpinUITests: XCTestCase {
    private var app: XCUIApplication!

    private var centerElement: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Center letter")).firstMatch
    }
    private var wordDisplay: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@",
                                             "No word assembled", "Assembled word")).firstMatch
    }

    private func centerPoint() -> CGPoint {
        let f = centerElement.frame
        return CGPoint(x: f.midX, y: f.midY)
    }

    private func outerTiles() -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        let tiles = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Letter "))
        for i in 0..<tiles.count {
            let t = tiles.element(boundBy: i)
            let f = t.frame
            result[t.label] = CGPoint(x: f.midX, y: f.midY)
        }
        return result
    }

    private func slotPosition(_ i: Int, center: CGPoint) -> CGPoint {
        let a = (Double(i) * 60 - 90) * .pi / 180
        return CGPoint(x: center.x + 112 * cos(a), y: center.y + 112 * sin(a))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double { hypot(Double(a.x - b.x), Double(a.y - b.y)) }

    private func isOnASlot(_ p: CGPoint, center: CGPoint) -> Bool {
        (0..<6).contains { distance(p, slotPosition($0, center: center)) <= 6 }
    }

    private func spinRing(degrees: Double, velocity: XCUIGestureVelocity, hold: TimeInterval) {
        let center = centerElement.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let r = 160.0, a0 = -Double.pi / 2, a1 = a0 + degrees * .pi / 180
        let start = center.withOffset(CGVector(dx: r * cos(a0), dy: r * sin(a0)))
        let end = center.withOffset(CGVector(dx: r * cos(a1), dy: r * sin(a1)))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: velocity, thenHoldForDuration: hold)
    }

    @MainActor
    func testRingSpinGestures() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-hasSeenTutorial", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Finish Round"].waitForExistence(timeout: 60), "board never loaded")
        XCTAssertTrue(centerElement.waitForExistence(timeout: 5))
        let center = centerPoint()

        // a. D-02: a tile tap still types.
        let firstTile = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Letter ")).firstMatch
        firstTile.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Assembled word")).firstMatch
            .waitForExistence(timeout: 3), "tile tap should type")
        wordDisplay.tap()
        XCTAssertTrue(app.staticTexts["No word assembled"].waitForExistence(timeout: 3), "tap clears the word")

        // b. D-01/D-02/D-16: a slow off-tile drag moves every letter one slot and types nothing.
        let before = outerTiles()
        XCTAssertEqual(before.count, 6)
        let topLabel = before.min { $0.value.y < $1.value.y }!.key
        spinRing(degrees: 60, velocity: .slow, hold: 0.4)
        sleep(2); usleep(500_000)
        let after = outerTiles()
        XCTAssertEqual(after.count, 6)
        let target = slotPosition(1, center: center)
        XCTAssertLessThanOrEqual(distance(after[topLabel]!, target), 6, "top letter should move exactly one slot clockwise")
        for (label, p) in after {
            XCTAssertTrue(isOnASlot(p, center: center), "\(label) not on a slot: \(p)")
        }
        XCTAssertEqual(wordDisplay.label, "No word assembled", "a spin must never type")

        // c. D-15: Shuffle mid-spin leaves every tile on a slot.
        spinRing(degrees: 120, velocity: .fast, hold: 0)
        app.buttons["Shuffle Letters"].tap()
        sleep(1); usleep(500_000)
        for (label, p) in outerTiles() {
            XCTAssertTrue(isOnASlot(p, center: center), "\(label) not on a slot after shuffle: \(p)")
        }
    }
}
