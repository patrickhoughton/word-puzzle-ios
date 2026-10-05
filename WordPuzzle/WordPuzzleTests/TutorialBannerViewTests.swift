import Testing
import SwiftUI
@testable import WordPuzzle

@MainActor @Suite struct TutorialBannerViewTests {

    @Test func testSkipLabelIsFrozen() {
        #expect(TutorialBannerView.skipLabel == "Skip tutorial")
    }

    @Test func testStepLabelHiddenAtAccessibilitySizes() {
        #expect(TutorialBannerView.showsStepLabel(for: .large))
        #expect(!TutorialBannerView.showsStepLabel(for: .accessibility1))
        #expect(!TutorialBannerView.showsStepLabel(for: .accessibility5))
    }

    @Test func testCompactInstructionAtAccessibilitySizes() {
        #expect(TutorialBannerView.displayedInstruction(full: "A. B.", compact: "C.", size: .xxxLarge) == "A. B.")
        #expect(TutorialBannerView.displayedInstruction(full: "A. B.", compact: "C.", size: .accessibility5) == "C.")
    }
}
