import Testing
import Foundation
@testable import WordPuzzle

@Suite struct TutorialCopyTests {
    private func sentences(_ s: String) -> Int { s.filter { ".!?".contains($0) }.count }

    private var bannerVariants: [TutorialCopy] {
        var out: [TutorialCopy] = []
        for step in TutorialStep.allCases where step != .ready {
            switch step {
            case .centerMiss:
                out.append(TutorialText.copy(for: step, hasMissed: false))
                out.append(TutorialText.copy(for: step, hasMissed: true))
            case .pangram:
                for l in 0...2 { out.append(TutorialText.copy(for: step, pangramHintLevel: l)) }
            default:
                out.append(TutorialText.copy(for: step))
            }
        }
        return out
    }

    @Test func testStepOrderAndCount() {
        #expect(TutorialStep.allCases.count == 9)
        #expect(TutorialStep.allCases == [.build, .centerMiss, .swipe, .fixMistake, .drag, .shuffle, .pangram, .scoreBar, .ready])
        #expect(TutorialStep.allCases.map(\.rawValue) == Array(1...9))
        #expect(TutorialText.stepLabel(3) == "Step 3 of 9")
    }

    @Test func testBannerCopyLimits() {
        for c in bannerVariants {
            #expect(sentences(c.instruction) <= 2, "\(c.instruction)")
            #expect(sentences(c.compactInstruction) == 1, "\(c.compactInstruction)")
            #expect(!c.title.isEmpty)
            for s in [c.title, c.instruction, c.compactInstruction] { #expect(!s.contains("{")) }
        }
    }

    @Test func testCenterMissDoesNotPreAnnounceRule() {
        let pre = TutorialText.copy(for: .centerMiss, hasMissed: false)
        #expect(!pre.instruction.lowercased().contains("gold"))
        let post = TutorialText.copy(for: .centerMiss, hasMissed: true)
        #expect(post.instruction.contains("gold letter in the middle"))
    }

    @Test func testBuildInstructionFrozen() {
        #expect(TutorialText.copy(for: .build).instruction == "Tap the glowing letters to spell POND.")
    }

    @Test func testReadyCopy() {
        let c = TutorialText.copy(for: .ready)
        #expect(c.title == "You're ready!")
        #expect(c.instruction.contains("Tap it now to start your first real puzzle!"))
        #expect(c.isReady)
    }

    @Test func testStepNumberMatchesRawValue() {
        for step in TutorialStep.allCases {
            #expect(TutorialText.copy(for: step).stepNumber == step.rawValue)
        }
    }
}
