# Phase 1: Word Engine & Puzzle Generation — Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a pure Swift puzzle engine — a generator that produces valid, pangram-guaranteed puzzles from a clean word list. No UI, no SwiftData, no StoreKit. The output of this phase is a set of Swift types and functions that are fully exercised by XCTest unit tests, including a performance test confirming generation completes under 500ms on a physical device.

</domain>

<decisions>
## Implementation Decisions

### Project Scaffolding
- **D-01:** Create a full Xcode App project in Phase 1 (not a standalone Swift Package). All engine code lives in a `PuzzleEngine/` group inside the app target. Tests run as XCTest unit tests in the existing test target.
- **D-02:** This is Patrick's first iOS/SwiftUI project. Plans must include explicit Xcode setup steps — do not assume familiarity with project creation, target configuration, or test target setup. Step-by-step Xcode instructions are required throughout Phase 1.

### Generator Algorithm
- **D-03:** Pangram-word-first approach:
  1. Pick a random word from the ENABLE list that has exactly 7 unique letters (this is the pangram word)
  2. Use those 7 letters as the complete puzzle letter set
  3. Pick a random center letter from the 7
  4. Find all words from the ENABLE list that: (a) use only the 7 letters, (b) contain the center letter, (c) are ≥4 letters long
  5. If the valid word count is <20, retry with a different center letter from the same set; if all 7 fail, pick a new pangram word and repeat
- **D-04:** The pangram guarantee comes from construction, not validation — by starting from a word that uses all 7 letters, every puzzle has at least one pangram by definition.

### Word Length Floor
- **D-05:** Minimum valid word length is **4 letters** (NYT Spelling Bee standard). Shorter words are excluded from both puzzle generation and word validation.

### Profanity Filtering
- **D-06:** Claude's discretion — pre-filter the ENABLE word list at build time via a one-time script rather than runtime filtering. Ship a cleaned `.txt` file. No runtime blocklist code needed. Planner should include the filtering script as a plan step.

### Word List & Validation (from research — already locked)
- **D-07:** Word list: ENABLE word list (public domain, ~173K words), bundled as a `.txt` file in the app bundle.
- **D-08:** Word validation uses a `Set<String>` — the entire ENABLE list loaded into memory at startup. O(1) lookup. UITextChecker is NOT used in Phase 1 (that's a Phase 3+ concern for rejecting proper nouns at the UI layer if needed).

### Claude's Discretion
- Profanity filtering: pre-filter approach, specific bad-words source and script implementation left to planner/researcher
- How often to "pick a new pangram word" before giving up (retry cap) — planner decides; 1000 attempts is a reasonable upper bound before throwing an error
- Whether the `PuzzleEngine/` folder contains subdirectories (e.g., `Sources/`, `Tests/`) or flat files — planner decides based on what's simplest for a first-time iOS developer

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — PUZZ-01, PUZZ-02, PUZZ-03 define the acceptance criteria for Phase 1; these three requirements are the source of truth for what "done" means

### Roadmap
- `.planning/ROADMAP.md` §"Phase 1: Word Engine & Puzzle Generation" — success criteria (100-puzzle test, profanity check, O(1) lookup, <500ms on physical device)

### Research
- `.planning/research/STACK.md` — confirmed stack choices: ENABLE word list, Set<String> validation, SwiftUI + @Observable MVVM, iOS 17+ target, UserDefaults for persistence (relevant to know for project creation even though Phase 1 doesn't use it)
- `.planning/research/PITFALLS.md` — App Store pitfalls relevant to word list licensing (ENABLE is public domain) and Guideline 4.3 clone risk; skim the "CRITICAL" items before writing App Review notes
- `.planning/research/FEATURES.md` — Confirms pangram highlight and minimum word threshold are high-priority features; informs why the generator must guarantee ≥20 words per puzzle

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — this is Phase 1; no existing Swift code in the repo

### Established Patterns
- None yet — patterns established in this phase will carry forward

### Integration Points
- The `PuzzleEngine/` types created in Phase 1 become the foundation imported by Phase 3 (Game UI) and tested independently in Phase 2 (Persistence & Entitlements)
- The cleaned ENABLE word list file (`.txt`) bundled in Phase 1 is the same file used in all subsequent phases — its path and loading mechanism become a stable contract

</code_context>

<specifics>
## Specific Ideas

- Patrick is new to iOS development — all plans should include first-time-friendly Xcode steps (File → New Project, where to add files, how to run tests, etc.)
- The word engine is "fully testable without any UI" — Phase 1 XCTest tests should be comprehensive enough that the planner doesn't need to open Simulator to verify correctness
- Success criterion #4 explicitly requires testing on a physical device for the 500ms performance benchmark — plans should include a step for running the XCTest performance test on-device, not just in Simulator

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 1 scope.

</deferred>

---

*Phase: 01-word-engine-puzzle-generation*
*Context gathered: 2026-08-28*
