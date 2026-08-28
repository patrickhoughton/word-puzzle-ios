---
phase: 1
slug: word-engine-puzzle-generation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-28
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`, `#expect`) for unit tests; XCTest (`measure {}`) for performance |
| **Config file** | None — test targets configured in Xcode project settings |
| **Quick run command** | `Cmd+U` in Xcode (Simulator) |
| **Full suite command** | `xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Performance test** | Must run on physical iPhone device (not Simulator) — Cmd+U with device selected |
| **Estimated runtime** | ~10 seconds (unit tests) + manual step on device for performance test |

---

## Sampling Rate

- **After every task commit:** Run `Cmd+U` in Xcode (all tests in Simulator)
- **After every plan wave:** All Simulator tests + performance test on physical device
- **Before `/gsd:verify-work`:** Full suite must be green in Simulator + performance test green on physical device
- **Max feedback latency:** ~10 seconds per run

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 0 | — | project setup | Xcode builds without errors | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | PUZZ-01, PUZZ-02, PUZZ-03 | unit | `PuzzleGeneratorTests.testGenerates100ValidPuzzles` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | PUZZ-02 | unit | `ProfanityTests.testBlockedWordsNotInWordList` | ❌ W0 | ⬜ pending |
| 01-02-03 | 02 | 1 | PUZZ-03 | unit | `WordListTests.testWordSetLookupIsO1` | ❌ W0 | ⬜ pending |
| 01-02-04 | 02 | 2 | PUZZ-03 | performance | `PerformanceTests.testGenerationUnder500ms` (physical device) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `WordPuzzleTests/WordListTests.swift` — stubs for PUZZ-01, PUZZ-03 (O(1) lookup)
- [ ] `WordPuzzleTests/PuzzleGeneratorTests.swift` — stubs for PUZZ-01, PUZZ-03 (100 puzzles, pangram)
- [ ] `WordPuzzleTests/ProfanityTests.swift` — stubs for PUZZ-02
- [ ] `WordPuzzleTests/PerformanceTests.swift` — stubs for PUZZ-03 (500ms, XCTest only)

*Note: The Xcode project and test target are created in Plan 1 (Wave 0). Test stubs are created in Plan 2 alongside implementation.*

---

## Success Criteria → Test Mapping

| Success Criterion | Test | File | Assertion |
|------------------|------|------|-----------|
| 100 puzzles, ≥20 valid words, ≥1 pangram each | `testGenerates100ValidPuzzles` | `PuzzleGeneratorTests.swift` | Loop 100×; `#expect(puzzle.validWords.count >= 20)`; `#expect(puzzle.hasPangram)` |
| No profanity in bundled word list | `testBlockedWordsNotInWordList` | `ProfanityTests.swift` | Load LDNOOBW list; `#expect(wordSet.isDisjoint(with: profanitySet))` |
| Word validation is O(1) Set lookup | `testWordSetLookupIsO1` | `WordListTests.swift` | Call `contains()` 10,000 times; assert total < 10ms |
| Puzzle generation < 500ms on physical device | `testGenerationUnder500ms` | `PerformanceTests.swift` | `let start = Date(); generatePuzzle(); XCTAssertLessThan(Date().timeIntervalSince(start), 0.500)` |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Performance test on physical device | PUZZ-03 (500ms) | Simulator timings are not reliable for device benchmarks | Connect iPhone, select device in Xcode scheme, Cmd+U, read `testGenerationUnder500ms` result |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
