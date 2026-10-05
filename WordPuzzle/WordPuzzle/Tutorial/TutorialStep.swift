import Foundation

/// Phase 11 D-05: the 9 displayed steps, in teaching order. Sub-steps (the post-miss
/// explanation, Delete-then-clear, pangram hints) are controller state, not extra steps.
enum TutorialStep: Int, CaseIterable, Equatable {
    case build = 1, centerMiss, swipe, fixMistake, drag, shuffle, pangram, scoreBar, ready
}

/// What the banner shows for the current state. Equatable so GameView can crossfade and
/// announce on change.
struct TutorialCopy: Equatable {
    let stepNumber: Int
    let title: String
    /// Full text, at most 2 sentences (UI-SPEC). Also the VoiceOver announcement.
    let instruction: String
    /// One sentence, shown instead of `instruction` at accessibility Dynamic Type sizes (UI-SPEC Layout at large sizes).
    let compactInstruction: String
    var isReady: Bool { stepNumber == TutorialText.stepCount }
}

enum TutorialText {
    /// UI-SPEC `tutorialStepCount` = 9, derived from the steps list.
    static var stepCount: Int { TutorialStep.allCases.count }
    static func stepLabel(_ number: Int) -> String { "Step \(number) of \(stepCount)" }
    static let readyTitle = "You're ready!"

    static func copy(for step: TutorialStep, hasMissed: Bool = false, pangramHintLevel: Int = 0) -> TutorialCopy {
        let build = PracticePuzzle.buildWord.uppercased()   // POND
        let miss = PracticePuzzle.missWord.uppercased()     // HOLD
        let drag = PracticePuzzle.dragWord.uppercased()     // PLOD
        let pangram = PracticePuzzle.pangram.uppercased()   // DOLPHIN
        let n = step.rawValue
        func make(_ title: String, _ full: String, _ compact: String) -> TutorialCopy {
            TutorialCopy(stepNumber: n, title: title, instruction: full, compactInstruction: compact)
        }
        switch step {
        case .build:
            return make("Build a word",
                        "Tap the glowing letters to spell \(build).",
                        "Tap the glowing letters to spell \(build).")
        case .centerMiss:
            if hasMissed {
                return make("Try this one",
                            "Oops! Every word must use the gold letter in the middle, so tap it to begin.",
                            "Every word needs the gold middle letter, so tap it.")
            }
            return make("Try this one",
                        "Now tap the glowing letters to spell \(miss), then swipe down on it.",
                        "Spell \(miss), then swipe down on it.")
        case .swipe:
            return make("Swipe down to submit",
                        "Spell \(build) again, then swipe down on your word to submit it.",
                        "Spell \(build), then swipe down to submit.")
        case .fixMistake:
            return make("Fix a mistake",
                        "Tap Delete to remove the last letter. Tap your word to clear it all.",
                        "Tap Delete, then tap your word to clear it.")
        case .drag:
            return make("Drag across letters",
                        "You can also slide your finger across the letters to spell \(drag). Then swipe down to submit it.",
                        "Slide across the letters to spell \(drag), then swipe down.")
        case .shuffle:
            return make("Shuffle the letters",
                        "Tap Shuffle, or double-tap empty space, to mix up the outer letters.",
                        "Tap Shuffle or double-tap empty space.")
        case .pangram:
            switch pangramHintLevel {
            case ..<1:
                return make("Find the pangram",
                            "A word using all 7 letters is a pangram, worth bonus points. Can you find it?",
                            "Find the word that uses all 7 letters.")
            case 1:
                return make("Find the pangram",
                            "A word using all 7 letters is worth bonus points. Hint: it starts with D and loves to swim.",
                            "Hint: it starts with D and loves to swim.")
            default:
                return make("Find the pangram",
                            "Follow the glowing letters to spell \(pangram), then swipe down.",
                            "Follow the glowing letters to spell \(pangram).")
            }
        case .scoreBar:
            return make("Track your progress",
                        "Your rank climbs as you find words. Tap the bar to see them all.",
                        "Tap the bar to see your words.")
        case .ready:
            return make(readyTitle,
                        "Keep playing this practice board if you like. When you're done, tap Finish Round to see the words you missed. Tap it now to start your first real puzzle!",
                        "Tap Finish Round to start your first real puzzle!")
        }
    }
}
