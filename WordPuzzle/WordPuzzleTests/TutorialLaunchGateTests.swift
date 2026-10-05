import Testing
import Foundation
@testable import WordPuzzle

@MainActor
@Suite struct TutorialLaunchGateTests {

    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let name = "TutorialLaunchGateTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        body(defaults)
    }

    @Test func testAbsentKeyNoHistoryShowsAndLeavesKeyAbsent() {
        withDefaults { d in
            #expect(TutorialFlag.state(in: d) == nil)
            #expect(TutorialFlag.shouldShowOnLaunch(defaults: d, hasHistory: { false }) == true)
            #expect(TutorialFlag.state(in: d) == nil)
        }
    }

    @Test func testAbsentKeyWithHistoryMarksSeenAndSkips() {
        withDefaults { d in
            #expect(TutorialFlag.shouldShowOnLaunch(defaults: d, hasHistory: { true }) == false)
            #expect(TutorialFlag.state(in: d) == true)
        }
    }

    @Test func testSeenTrueSkipsWithoutProbingHistory() {
        withDefaults { d in
            d.set(true, forKey: TutorialFlag.seenKey)
            var probed = false
            let show = TutorialFlag.shouldShowOnLaunch(defaults: d, hasHistory: { probed = true; return false })
            #expect(show == false)
            #expect(probed == false)
        }
    }

    @Test func testForcedFalseShowsEvenWithHistory() {
        withDefaults { d in
            d.set(false, forKey: TutorialFlag.seenKey)
            #expect(TutorialFlag.shouldShowOnLaunch(defaults: d, hasHistory: { true }) == true)
        }
    }

    @Test func testStringYesReadsAsTrue() {
        withDefaults { d in
            d.set("YES", forKey: TutorialFlag.seenKey)
            #expect(TutorialFlag.state(in: d) == true)
        }
    }

    @Test func testStringNoReadsAsFalse() {
        withDefaults { d in
            d.set("NO", forKey: TutorialFlag.seenKey)
            #expect(TutorialFlag.state(in: d) == false)
        }
    }

    @Test func testMarkSeenSetsTrue() {
        withDefaults { d in
            TutorialFlag.markSeen(in: d)
            #expect(TutorialFlag.state(in: d) == true)
        }
    }
}
