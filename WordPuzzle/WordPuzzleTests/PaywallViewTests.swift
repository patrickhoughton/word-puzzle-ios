import Testing
import Foundation
@testable import WordPuzzle

/// D-06 / 04-UI-SPEC.md Copywriting Contract: the countdown format rules are frozen
/// copy, so they are pinned by tests rather than eyeballed on device.
@MainActor
@Suite struct PaywallViewTests {

    @Test func testCountdownFormatsHoursAndMinutes() {
        #expect(PaywallView.countdownText(remaining: 2 * 3600 + 14 * 60) == "2h 14m")
        #expect(PaywallView.countdownText(remaining: 3600) == "1h 0m")
        #expect(PaywallView.countdownText(remaining: 23 * 3600 + 59 * 60) == "23h 59m")
    }

    @Test func testCountdownFormatsMinutesOnlyUnderAnHour() {
        #expect(PaywallView.countdownText(remaining: 3599) == "59m")
        #expect(PaywallView.countdownText(remaining: 42 * 60) == "42m")
        #expect(PaywallView.countdownText(remaining: 60) == "1m")
    }

    @Test func testCountdownClampsAtLessThanAMinute() {
        #expect(PaywallView.countdownText(remaining: 59) == "Less than a minute")
        #expect(PaywallView.countdownText(remaining: 0) == "Less than a minute")
        #expect(PaywallView.countdownText(remaining: -120) == "Less than a minute")
    }
}
