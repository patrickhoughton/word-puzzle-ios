import Testing
@testable import WordPuzzle

@MainActor @Suite struct CompletionCelebrationTests {

    @Test func testSweepHeadlineCopyIsExact() {
        #expect(CompletionCelebration.sweepHeadline(bonus: 21) == "Pangram sweep! +21")
        #expect(CompletionCelebration.sweepHeadline(bonus: 7) == "Pangram sweep! +7")
    }

    @Test func testLengthPillCopyIsExact() {
        #expect(CompletionCelebration.lengthPillLabel(length: 5) == "5 Letters complete!")
        #expect(CompletionCelebration.bonusText(5) == "+5")
        #expect(CompletionCelebration.lengthPillText(length: 5, bonus: 5) == "5 Letters complete! +5")
    }

    @Test func testAnnouncements() {
        #expect(CompletionCelebration.sweepAnnouncement(bonus: 21) == "Pangram sweep! plus 21 points")
        #expect(CompletionCelebration.lengthAnnouncement(length: 5, bonus: 5) == "5 letters complete, plus 5 points")
    }

    @Test func testSweepStepDurationClamps() {
        #expect(CompletionCelebration.sweepStepDuration(pangramCount: 0) == 0)
        #expect(abs(CompletionCelebration.sweepStepDuration(pangramCount: 1) - 0.3) < 1e-9)
        #expect(abs(CompletionCelebration.sweepStepDuration(pangramCount: 4) - 0.3) < 1e-9)
        #expect(abs(CompletionCelebration.sweepStepDuration(pangramCount: 5) - 0.24) < 1e-9)
        #expect(abs(CompletionCelebration.sweepStepDuration(pangramCount: 40) - 0.03) < 1e-9)
        #expect(abs(CompletionCelebration.sweepStepDuration(pangramCount: 86) - 0.03) < 1e-9)
    }

    @Test func testSweepNeverExceedsBudgetExceptViaMinFloor() {
        for n in 1...100 {
            let step = CompletionCelebration.sweepStepDuration(pangramCount: n)
            #expect(Double(n) * step <= max(1.2, Double(n) * 0.03) + 1e-9)
        }
    }

    @Test func testSweepShowsWordsThreshold() {
        #expect(CompletionCelebration.sweepShowsWords(pangramCount: 1))
        #expect(CompletionCelebration.sweepShowsWords(pangramCount: 15))
        #expect(!CompletionCelebration.sweepShowsWords(pangramCount: 16))
    }

    @Test func testTickInterval() {
        #expect(CompletionCelebration.tickInterval(pangramCount: 1) == 1)
        #expect(CompletionCelebration.tickInterval(pangramCount: 12) == 1)
        #expect(CompletionCelebration.tickInterval(pangramCount: 13) == 2)
        #expect(CompletionCelebration.tickInterval(pangramCount: 40) == 4)
        #expect(CompletionCelebration.tickInterval(pangramCount: 86) == 8)
    }

    @Test func testTickCountWithinOneToTwelve() {
        for n in 1...100 {
            #expect((1...12).contains(CompletionCelebration.tickCount(pangramCount: n)))
        }
        #expect(CompletionCelebration.shouldTick(step: 4, pangramCount: 40))
        #expect(!CompletionCelebration.shouldTick(step: 5, pangramCount: 40))
    }

    @Test func testTallyValue() {
        #expect(CompletionCelebration.tallyValue(step: 3) == 21)
    }

    @Test func testCompletionEventEquality() {
        #expect(CompletionEvent.lengthComplete(length: 5, bonus: 5) == .lengthComplete(length: 5, bonus: 5))
        #expect(CompletionEvent.pangramSweep(bonus: 14, pangrams: ["a", "b"]) != .pangramSweep(bonus: 14, pangrams: ["b", "a"]))
    }
}
