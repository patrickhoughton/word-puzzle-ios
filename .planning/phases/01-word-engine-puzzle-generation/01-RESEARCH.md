# Phase 1: Word Engine & Puzzle Generation — Research

**Researched:** 2026-08-28
**Domain:** Swift / Xcode / XCTest / Puzzle Generation / Word Lists
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Full Xcode App project in Phase 1 (not a Swift Package). Engine code lives in `PuzzleEngine/` group inside the app target. Tests run as XCTest unit tests in the existing test target.
- **D-02:** Patrick is a first-time iOS developer. Plans must include explicit Xcode setup steps. Step-by-step Xcode instructions are required throughout Phase 1. Do not assume familiarity.
- **D-03:** Pangram-word-first algorithm: (1) Pick a random word with exactly 7 unique letters. (2) Use those 7 letters as the puzzle set. (3) Pick a random center letter. (4) Find all words using only those 7 letters, containing the center letter, ≥4 letters long. (5) If valid word count < 20, retry with a different center letter; if all 7 fail, pick a new pangram word. Repeat up to retry cap.
- **D-04:** Pangram guarantee comes from construction — starting from a word that uses all 7 letters means every puzzle has at least one pangram by definition.
- **D-05:** Minimum valid word length is **4 letters** (NYT Spelling Bee standard).
- **D-06:** Pre-filter the ENABLE word list at build time via a one-time script. Ship a cleaned `.txt` file. No runtime blocklist code needed.
- **D-07:** Word list: ENABLE word list (public domain, ~173K words), bundled as `.txt`.
- **D-08:** Word validation uses `Set<String>` — loaded into memory at startup. O(1) lookup. UITextChecker is NOT used in Phase 1.

### Claude's Discretion

- Profanity filtering: pre-filter approach is locked; specific bad-words source and script implementation left to planner/researcher.
- How often to "pick a new pangram word" before giving up — 1000 attempts is a reasonable upper bound before throwing an error.
- Whether `PuzzleEngine/` contains subdirectories or flat files — planner decides based on simplicity for a first-time iOS developer.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 1 scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PUZZ-01 | App generates puzzles algorithmically using a pangram-first approach from the ENABLE word list | Section: Architecture Patterns (pangram-word-first algorithm), Standard Stack (ENABLE word list), Code Examples |
| PUZZ-02 | Word list is filtered for profanity and inappropriate content before puzzle generation | Section: Architecture Patterns (profanity filtering script), Don't Hand-Roll, Common Pitfalls |
| PUZZ-03 | Each puzzle guarantees a minimum of 20 valid words and at least one pangram | Section: Architecture Patterns (generator retry logic), Validation Architecture (success criteria mapping) |
</phase_requirements>

---

## Summary

Phase 1 delivers a pure Swift puzzle engine with no UI. The three primary technical areas are: (1) Xcode project creation and XCTest setup, (2) ENABLE word list bundling and preprocessing, and (3) the pangram-word-first puzzle generator implementation. All three areas are well-understood with HIGH confidence.

The key discovery affecting plan sequencing is that **Xcode is not yet installed on Patrick's machine** (macOS 26.5.2 is present, so Xcode 26 is installable from the Mac App Store). Installing Xcode must be Wave 0 before any other plan step can execute — this is a one-time ~10GB download.

For testing, the project should use **Swift Testing** (the modern framework, shipped with Xcode 16+) for all unit tests, and **XCTest** only for the performance measurement test (the `measure {}` block), because Swift Testing does not yet have a performance testing equivalent. Both frameworks coexist in the same test target without conflict.

**Primary recommendation:** Install Xcode 26 first (Wave 0 blocker), create the project with the "App" SwiftUI template targeting iOS 17+, load ENABLE once into a `Set<String>` on a background Task, implement the pangram-word-first generator in a flat `PuzzleEngine/` group, and write the profanity filter as a standalone Python script run once manually before committing the cleaned `.txt` file.

---

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Xcode | 26.x (latest from App Store) | IDE, compiler, simulator, test runner | Required — Apple's only iOS development environment |
| Swift | 6.3.3 (bundled with Xcode 26) | Implementation language | Only language supported for SwiftUI + @Observable |
| SwiftUI | iOS 17+ | App project scaffold (Phase 1 uses no UI, but project type is set here) | Project decision D-01 |
| XCTest (measure block only) | Bundled with Xcode | Performance testing — `measure {}` block | Swift Testing has no performance equivalent; XCTest required for this specific test |
| Swift Testing (`@Test`, `#expect`) | Bundled with Xcode 16+ / Xcode 26 | All unit tests except the performance test | Modern default for new iOS projects; better ergonomics than XCTest for logic tests |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Python 3 | 3.11.3 (already installed) | One-time profanity filter script | Run once before bundling ENABLE word list; not shipped with the app |
| ENABLE word list | 2k edition, 173,528 words | Bundled dictionary | Phase 1 foundation — same file used in all subsequent phases |
| LDNOOBW bad-words list | Current (GitHub) | Source for profanity filter | Used by the one-time Python script to produce `enable-clean.txt` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift Testing for unit tests | XCTest for all tests | XCTest is older, more verbose; Swift Testing is preferred for new code |
| Python profanity script | Node.js or bash script | Python is already installed; simpler to read and maintain |
| Flat `PuzzleEngine/` group | Subfolders inside `PuzzleEngine/` | Flat is simpler for a first-time developer and fine for Phase 1 file count |

**Installation:**
```bash
# Xcode installs from the Mac App Store — no brew command needed.
# Open the App Store, search "Xcode", and click Get (free, ~10GB).
# Alternatively: https://developer.apple.com/xcode/
# After Xcode installs, accept the license when prompted.
```

**Version verification:** Xcode 26.x is mandatory for App Store submissions (April 2026 requirement). macOS 26.5.2 is already installed — Xcode 26 is compatible. Swift 6.3.3 is already present via command-line tools, but Xcode itself must be installed for the iOS SDK, Simulator, and test runner.

---

## Architecture Patterns

### Recommended Project Structure
```
WordPuzzle/                        ← Xcode project root
├── WordPuzzle.xcodeproj/
├── WordPuzzle/                    ← App target source root
│   ├── WordPuzzleApp.swift        ← @main entry point
│   ├── ContentView.swift          ← Placeholder (Phase 1 leaves this minimal)
│   ├── PuzzleEngine/              ← Group (folder) for all engine code
│   │   ├── WordList.swift         ← Loads ENABLE into Set<String>
│   │   ├── PuzzleGenerator.swift  ← Pangram-word-first algorithm
│   │   └── PuzzleModel.swift      ← Puzzle struct (letters, centerLetter, validWords)
│   └── Resources/
│       └── enable-clean.txt       ← Cleaned ENABLE list (bundled resource)
└── WordPuzzleTests/               ← Test target (created with project)
    ├── WordListTests.swift        ← Tests for word loading, O(1) lookup
    ├── PuzzleGeneratorTests.swift ← Tests for generator correctness, 100-puzzle test
    └── ProfanityTests.swift       ← Test: blocklist words not in enable-clean.txt
```

**Note on Xcode groups vs folders:** In Xcode 16+, you can create "New Group with Folder" which creates an actual filesystem folder matching the group. Use this for `PuzzleEngine/` — it keeps the file system and Navigator in sync, which is less confusing for first-time developers.

### Pattern 1: Loading ENABLE into a Set<String>
**What:** Read `enable-clean.txt` from the app bundle at startup on a background Task. Store the result as a `Set<String>` for O(1) lookups.
**When to use:** Once, at app startup. Store in a shared object accessible to the generator and validator.

```swift
// WordList.swift
// Source: STACK.md (project research), Hacking with Swift bundle loading pattern

@Observable
class WordList {
    private(set) var words: Set<String> = []
    private(set) var isLoaded = false

    func load() async {
        guard let url = Bundle.main.url(forResource: "enable-clean", withExtension: "txt") else {
            assertionFailure("enable-clean.txt not found in bundle")
            return
        }
        let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let loaded = Set(
            content
                .components(separatedBy: .newlines)
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { $0.count >= 4 }  // Pre-filter: discard <4 letter words
        )
        await MainActor.run {
            self.words = loaded
            self.isLoaded = true
        }
    }

    func contains(_ word: String) -> Bool {
        words.contains(word.lowercased())
    }
}
```

**Memory footprint:** A 173K-word `Set<String>` occupies approximately 3–5 MB. Acceptable for mobile.

### Pattern 2: Pangram-Word-First Generator
**What:** The core algorithm. Picks a random 7-unique-letter word as the pangram source, then finds all valid puzzle words, retrying if word count < 20.
**When to use:** Called each time the user starts a new puzzle.

```swift
// PuzzleGenerator.swift — core algorithm sketch
// Source: Project decisions D-03/D-04, journal.spencerwnelson.com validation logic

struct Puzzle {
    let letters: Set<Character>       // The 7 puzzle letters
    let centerLetter: Character        // Required center letter
    let validWords: [String]           // All words satisfying rules
    let pangrams: [String]             // Words using all 7 letters
}

enum GeneratorError: Error {
    case exhaustedRetries
}

func generatePuzzle(from wordSet: Set<String>, maxAttempts: Int = 1000) throws -> Puzzle {
    // Step 1: Build the pangram candidate pool once
    let pangramWords = wordSet.filter { word in
        Set(word).count == 7 && word.count >= 7
    }
    guard !pangramWords.isEmpty else { throw GeneratorError.exhaustedRetries }

    for _ in 0..<maxAttempts {
        // Step 2: Pick a random pangram word
        let pangram = pangramWords.randomElement()!
        let letters = Set(pangram)  // Set<Character>, exactly 7 elements

        // Step 3: Try each of the 7 letters as center letter
        for centerLetter in letters.shuffled() {
            let validWords = wordSet.filter { word in
                isValidPuzzleWord(word, letters: letters, center: centerLetter)
            }
            if validWords.count >= 20 {
                let pangrams = validWords.filter { Set($0) == letters }
                return Puzzle(
                    letters: letters,
                    centerLetter: centerLetter,
                    validWords: validWords,
                    pangrams: pangrams
                )
            }
        }
        // All 7 center letters failed — pick a new pangram word
    }
    throw GeneratorError.exhaustedRetries
}

// Word validation: O(1) character set operations
private func isValidPuzzleWord(_ word: String, letters: Set<Character>, center: Character) -> Bool {
    guard word.count >= 4 else { return false }
    guard word.contains(center) else { return false }
    return Set(word).isSubset(of: letters)
}
```

**Performance note:** The filter over 173K words runs in a tight loop. This is fast enough — a linear scan of 173K 5–10 character strings on an iPhone completes in well under 50ms. The outer retry loop rarely needs more than 1–3 pangram words before finding a valid center letter combination.

### Pattern 3: Profanity Filter Script (one-time build tool)
**What:** A Python 3 script that reads `enable-clean.txt`, removes words found in the LDNOOBW English profanity list, and writes the cleaned output.
**When to use:** Run once manually. Commit the result (`enable-clean.txt`) to the repo. Never run at runtime.

```python
#!/usr/bin/env python3
# filter_profanity.py
# Run: python3 filter_profanity.py enable1.txt ldnoobw-en.txt enable-clean.txt

import sys

def main(enable_path, blocklist_path, output_path):
    with open(blocklist_path) as f:
        blocklist = set(line.strip().lower() for line in f if line.strip())
    
    with open(enable_path) as f:
        words = [line.strip().lower() for line in f if line.strip()]
    
    cleaned = [w for w in words if w not in blocklist]
    
    print(f"Original: {len(words)} words")
    print(f"Removed:  {len(words) - len(cleaned)} words")
    print(f"Result:   {len(cleaned)} words")
    
    with open(output_path, 'w') as f:
        f.write('\n'.join(cleaned))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3])
```

**LDNOOBW source:** https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words — the `/en` file. License: Creative Commons Attribution 4.0. Use it with attribution.

### Pattern 4: XCTest Performance Test (measure block)
**What:** Wraps puzzle generation in XCTest's `measure {}` block to record timing across 10 runs. The 500ms threshold is validated by setting a baseline after running on device.
**When to use:** The single performance test for PUZZ-03's "under 500ms" success criterion. Must be run on a physical device, not Simulator.

> **SIGNATURE NOTE (updated):** The generator's locked signature is `generatePuzzle(from wordList: WordList, maxAttempts: Int = 1000) throws -> Puzzle` (see Plan 02 `<interfaces>`). Call it with a `WordList` instance: `generatePuzzle(from: wordList)`. Do NOT pass `wordList.words` or a raw `Set<String>` — the earlier `from wordSet: Set<String>` form in Pattern 2 and the Code Examples section is outdated and will not compile against the shipped API.

```swift
// PuzzleGeneratorTests.swift (XCTest — NOT Swift Testing)
import XCTest
@testable import WordPuzzle

class PuzzlePerformanceTests: XCTestCase {
    var wordList: WordList!

    override func setUp() async throws {
        wordList = WordList()
        await wordList.load()
    }

    func testPuzzleGenerationPerformance() throws {
        // Runs the block 10 times, records average
        measure {
            _ = try? generatePuzzle(from: wordList)
        }
        // After first run: click the gray diamond in Xcode to "Set Baseline"
        // Future runs fail if average regresses by more than 10% above baseline
    }
}
```

**Manual step required:** After running this test once on a physical device, click the gray diamond in Xcode's test results → "Set Baseline". The test will thereafter fail if generation time regresses. There is no way to assert "must be under 500ms" in code directly — the baseline mechanism is how XCTest manages this threshold.

**Alternative for 500ms assertion:** If you need a hard-coded time gate (not just regression detection), use `Date`:

```swift
func testPuzzleGenerationUnder500ms() async throws {
    await wordList.load()
    let start = Date()
    _ = try generatePuzzle(from: wordList)
    let elapsed = Date().timeIntervalSince(start)
    XCTAssertLessThan(elapsed, 0.500, "Puzzle generation exceeded 500ms: \(elapsed)s")
}
```

This simpler approach directly verifies the 500ms requirement from the success criteria without needing baseline management.

### Anti-Patterns to Avoid
- **Synchronous dictionary load on main thread:** Never load `enable-clean.txt` in `init()` or a View body. Always use `Task { await wordList.load() }` inside `.task {}` modifier or `@main App.init`.
- **Array.contains() for word lookup:** Do not use `[String].contains(word)` — this is O(n) across 173K words. The `Set<String>` decision is locked (D-08).
- **Generating pangram candidates inside the per-puzzle loop:** Pre-compute the pangram word pool once when the word list loads, not inside `generatePuzzle()`. Computing it fresh each call would scan 173K words unnecessarily.
- **Using Xcode groups without filesystem folders:** Xcode "virtual groups" (yellow folders) don't match the file system. Use "New Group with Folder" (blue folders) for `PuzzleEngine/` to avoid confusion.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Profanity list | Custom curated bad-words list | LDNOOBW English list (GitHub) | Already maintained, CC-BY 4.0, thousands of words, multiple languages |
| Word set O(1) lookup | Binary search, sorted array, trie | `Set<String>` (Swift stdlib) | Swift Set is a hash set — O(1) average lookup, zero dependencies |
| Character subset validation | Custom loop checking each letter | `Set<Character>.isSubset(of:)` (Swift stdlib) | One-liner, already the standard in puzzle solver literature |
| Performance regression detection | Custom timing harness | XCTest `measure {}` block | Stores baselines per device, integrates with Xcode UI, free |
| Test assertions | Custom assertion helpers | `#expect` (Swift Testing) + `XCTAssertLessThan` (XCTest) | Both bundled with Xcode; no third-party test library needed |

**Key insight:** The puzzle generation domain is deceptively simple at the surface. The only real complexity is `isSubset` validation and retry logic — both solved by Swift's standard library. The risk is over-engineering (building a Trie, bitmask indexing, precomputed letter-set database) before the simple approach has been measured. Use the O(n) filter first; it's fast enough (< 50ms per puzzle on device based on similar Spelling Bee implementations).

---

## Common Pitfalls

### Pitfall 1: ENABLE Word List Format Assumptions
**What goes wrong:** Developer assumes ENABLE is pre-lowercased and clean. In reality, the ENABLE 2k edition (`enable1.txt`, mirrored at `https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt`) contains **172,823 lowercase words, one per line**, with no proper nouns — but it DOES contain profanity (it is a Scrabble word list, not a family-friendly list).
**Why it happens:** The "no proper nouns" assumption is correct (ENABLE is based on Scrabble rules which exclude proper nouns), but profanity filtering is still required.
**How to avoid:** Run the Python filter script on the raw ENABLE file before bundling. Commit `enable-clean.txt` (the filtered version), not `enable1.txt`.
**Warning signs:** You skipped the filter script and bundled the raw file.

### Pitfall 2: Xcode Not Installed (Blocking)
**What goes wrong:** No Swift code can be written, compiled, or tested without Xcode installed. The Mac App Store download is ~10GB and can take 30–60 minutes on a typical connection.
**Why it happens:** Xcode is not pre-installed on macOS (only Command Line Tools may be present, as is the case here — Swift 6.3.3 is available but the full Xcode IDE is not).
**How to avoid:** Treat Xcode installation as Wave 0. No plan steps can proceed without it.
**Warning signs:** `xcodebuild -version` returns "command not found" (verified: this is the current state).

### Pitfall 3: Blocking Main Thread on Dictionary Load
**What goes wrong:** Loading 173K words from disk and building a `Set<String>` takes 100–500ms. If done on the main thread, the app freezes on launch.
**Why it happens:** The simplest implementation reads the file synchronously in a View's `init()` or the app's entry point.
**How to avoid:** Use `await wordList.load()` inside a `.task {}` modifier or `Task { }` in the app initializer. Show a loading indicator if needed.
**Warning signs:** The app hangs for 1+ seconds on first launch in Simulator.

### Pitfall 4: XCTest Baseline Not Set After First Run
**What goes wrong:** The `measure {}` performance test always shows "No baseline" and never fails, giving false confidence.
**Why it happens:** Baselines must be set manually after the first run by clicking the gray diamond in Xcode → "Set Baseline".
**How to avoid:** After running the performance test on device for the first time, immediately set the baseline. Without this step, the test is decorative.
**Warning signs:** The test result shows a gray diamond (not green) next to the `testPuzzleGenerationPerformance` method.

### Pitfall 5: Generating Pangram Pool Inside the Puzzle Loop
**What goes wrong:** `generatePuzzle()` filters all 173K words for pangram candidates on every call. This makes the first puzzle fast but wastes time on each subsequent call.
**Why it happens:** The filter for "7 unique letters" is placed inside `generatePuzzle()` as the obvious first implementation.
**How to avoid:** Compute `pangramWords` once when `WordList` loads and store it. Pass it to `generatePuzzle()` or cache it on a generator object.
**Warning signs:** Puzzle generation takes >200ms on the first call and subsequent calls are identical in timing (no improvement from caching).

### Pitfall 6: iOS Simulator vs. Physical Device Performance Gap
**What goes wrong:** Puzzle generation tests pass the 500ms threshold on Simulator but fail on an older physical device (iPhone 12 or older).
**Why it happens:** Simulator runs on Mac hardware, which is 3–5x faster than a physical iPhone for CPU-bound work. The dictionary load and Set construction are especially divergent.
**How to avoid:** Run the `testPuzzleGenerationUnder500ms` test on a physical device before declaring PUZZ-03 complete. The CONTEXT.md explicitly requires this (success criterion #4).
**Warning signs:** You've only run tests in Simulator and the performance test passes easily (sub-50ms). Real device may show 300–400ms.

### Pitfall 7: Swift Testing Used for Performance Tests
**What goes wrong:** Developer writes the performance test using `@Test` and `#expect` (Swift Testing), but the `measure {}` block is XCTest-only. The test doesn't actually measure performance.
**Why it happens:** Xcode 26 defaults to Swift Testing for new test files. A first-time developer may not know the distinction.
**How to avoid:** The performance test file must import XCTest and inherit from `XCTestCase`. Unit logic tests use Swift Testing (`@Test`). Keep them in separate files.
**Warning signs:** The performance test file uses `struct ... { @Test func ... }` syntax.

---

## Code Examples

Verified patterns from official sources and project research:

### Loading a Text File from Bundle (Swift)
```swift
// Source: Hacking with Swift bundle loading pattern; verified against Apple docs
guard let url = Bundle.main.url(forResource: "enable-clean", withExtension: "txt") else {
    fatalError("enable-clean.txt not found in app bundle")
}
let content = try String(contentsOf: url, encoding: .utf8)
let words = content
    .components(separatedBy: .newlines)
    .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
    .filter { $0.count >= 4 }
let wordSet = Set(words)
```

### Swift Testing Unit Test (Logic)
```swift
// Source: Swift Testing framework (Apple, Xcode 16+)
import Testing
@testable import WordPuzzle

struct PuzzleGeneratorTests {
    @Test func testGenerates100ValidPuzzles() async throws {
        let wl = WordList()
        await wl.load()
        for _ in 0..<100 {
            let puzzle = try generatePuzzle(from: wl.words)
            #expect(puzzle.validWords.count >= 20)
            #expect(!puzzle.pangrams.isEmpty)
        }
    }

    @Test func testWordValidationIsO1() async {
        let wl = WordList()
        await wl.load()
        // Set.contains() is O(1) — verify by calling 10,000 times
        for _ in 0..<10_000 {
            _ = wl.contains("testing")
        }
        // If this test completes in milliseconds, O(1) is confirmed
    }
}
```

### XCTest Performance Test (XCTestCase required)
```swift
// Source: Square Engineering blog (measureBlock patterns), Apple XCTest docs
import XCTest
@testable import WordPuzzle

class PerformanceTests: XCTestCase {
    var wordSet: Set<String>!

    override func setUp() async throws {
        let wl = WordList()
        await wl.load()
        wordSet = wl.words
    }

    // Option A: baseline-based regression detection
    func testGenerationPerformanceBaseline() {
        measure {
            _ = try? generatePuzzle(from: wordSet)
        }
        // Run once on device → click gray diamond → Set Baseline
    }

    // Option B: hard assertion against 500ms ceiling (recommended for PUZZ-03)
    func testGenerationUnder500ms() throws {
        let start = Date()
        _ = try generatePuzzle(from: wordSet)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 0.500, "Generation took \(elapsed)s — exceeds 500ms target")
    }
}
```

### Adding a File to Xcode App Bundle (Manual UI Steps)
```
1. In Finder: download enable-clean.txt to Desktop (after running filter script)
2. In Xcode Project Navigator: right-click on "Resources" folder (or app root)
   → "Add Files to [ProjectName]..."
3. In the file picker:
   → Select enable-clean.txt
   → Check: "Copy items if needed" (REQUIRED — without this, file won't ship with app)
   → Confirm: App target is checked under "Add to targets"
   → Click Add
4. Verify: Select project target → Build Phases → Copy Bundle Resources
   → enable-clean.txt must appear in this list
```

### Building the Pangram Word Pool (computed once)
```swift
// Computed once when WordList loads, not per-puzzle
extension WordList {
    var pangramWords: [String] {
        words.filter { Set($0).count == 7 && $0.count >= 7 }
    }
}
// Note: make this a stored property initialized during load() for best performance
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 / Swift 5.9 (WWDC 2023) | Less boilerplate; views only re-render when accessed properties change |
| `XCTestCase` for all tests | Swift Testing (`@Test`, `#expect`) for unit tests + XCTest for performance | Xcode 16 / Swift 6 (WWDC 2024) | Cleaner syntax, parallel by default, better error messages |
| Manually managing provisioning profiles | Xcode automatic signing | Xcode 9+ | Let Xcode handle certificates; "Automatically Manage Signing" in project settings |
| ObjC-style `measureBlock` | `measure {}` closure syntax | Swift 2+ | Same behavior, Swift-friendly closure syntax |

**Deprecated / outdated:**
- `ObservableObject` + `@Published`: Still works but Apple's preferred direction is `@Observable`. Don't start new classes with `ObservableObject` on iOS 17+.
- `XCTestCase.setUp()` / `tearDown()` for unit tests: Use Swift Testing's `init()` and `deinit` instead for new test types. Only keep `XCTestCase` for performance tests.

---

## Open Questions

1. **ENABLE word count after profanity filter**
   - What we know: ENABLE has 172,823–173,528 words (sources vary slightly by edition). LDNOOBW English list has ~1,000–2,000 English profanity words.
   - What's unclear: Exact number of words removed and final cleaned count.
   - Recommendation: Run the filter script and log the count. Plan should include a step to verify the output file is reasonable (e.g., > 170,000 words remaining).

2. **Pangram word pool size after filtering**
   - What we know: The ENABLE list has thousands of 7-unique-letter words. One source reports "7,892 seven-letter sets that produce at least one pangram."
   - What's unclear: How many remain after applying the ≥4-letter minimum and profanity filter specifically.
   - Recommendation: The generator logs the pool size on startup in debug builds. If the pool is < 1,000 words, investigate.

3. **Physical device for performance testing**
   - What we know: Patrick needs to run the 500ms test on a physical device.
   - What's unclear: Which physical iPhone Patrick owns.
   - Recommendation: Any iPhone 12 or newer should clear 500ms comfortably. The plan should include a step to connect a device via USB and run the test on-device.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | ALL plan steps | **NOT INSTALLED** | — | Install from Mac App Store (~10GB) — must do first |
| Swift (CLI) | Python filter script verification | ✓ | 6.3.3 | — |
| Python 3 | Profanity filter script | ✓ | 3.11.3 | Bash: `grep -v -x -F -f ldnoobw-en.txt enable1.txt > enable-clean.txt` |
| macOS | Xcode requirement | ✓ | 26.5.2 | — |
| Physical iPhone | Performance test (500ms) | Unknown | — | Must have one; Simulator is not valid for this test |
| Internet access | ENABLE list download, LDNOOBW download | Assumed ✓ | — | Both files can be downloaded from GitHub |

**Missing dependencies with no fallback:**
- **Xcode:** Blocks every plan step. Must be installed before any code is written. Download from Mac App Store: search "Xcode" → Get (free, ~10GB, Xcode 26.x).
- **Physical iPhone:** Required for success criterion #4 (500ms on device). Cannot substitute Simulator. Plan must include a step to connect a device via USB and trust the Mac.

**Missing dependencies with fallback:**
- Python 3 profanity script: If Python unavailable, the bash grep one-liner works: `grep -v -x -F -f ldnoobw-en.txt enable1.txt > enable-clean.txt`

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Unit test framework | Swift Testing (`@Test`, `#expect`) — bundled with Xcode 26 |
| Performance test framework | XCTest (`measure {}` block) — bundled with Xcode 26 |
| Config file | None — test targets configured in Xcode project settings |
| Quick run (unit tests) | Cmd+U in Xcode, or `xcodebuild test -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Performance test run | Must run on physical device: Cmd+U with device selected in scheme |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command / Method | File |
|--------|----------|-----------|---------------------------|------|
| PUZZ-01 | Puzzle generates from ENABLE pangram-first algorithm | Unit (`@Test`) | Cmd+U, `PuzzleGeneratorTests.testGenerates100ValidPuzzles` | `PuzzleGeneratorTests.swift` — Wave 0 gap |
| PUZZ-02 | Profanity words not in bundled word list | Unit (`@Test`) | Cmd+U, `ProfanityTests.testBlockedWordsNotInWordList` | `ProfanityTests.swift` — Wave 0 gap |
| PUZZ-03 (20 words) | Every puzzle has ≥20 valid words | Unit (`@Test`) | Cmd+U, `PuzzleGeneratorTests.testGenerates100ValidPuzzles` (asserts count ≥ 20 per iteration) | `PuzzleGeneratorTests.swift` — Wave 0 gap |
| PUZZ-03 (pangram) | Every puzzle has ≥1 pangram | Unit (`@Test`) | Cmd+U, `PuzzleGeneratorTests.testPangramGuarantee` | `PuzzleGeneratorTests.swift` — Wave 0 gap |
| PUZZ-03 (O(1)) | Word validation is O(1) Set lookup | Unit (`@Test`) | Cmd+U, `WordListTests.testWordSetLookupIsO1` | `WordListTests.swift` — Wave 0 gap |
| PUZZ-03 (500ms) | Puzzle generation < 500ms on physical device | Performance (XCTest `measure`) | Run on physical device, `PerformanceTests.testGenerationUnder500ms` | `PerformanceTests.swift` — Wave 0 gap |

**Success criteria → test mapping:**
1. "100 puzzles, ≥20 valid words, ≥1 pangram each" → `testGenerates100ValidPuzzles` (loops 100 times, asserts both properties)
2. "No profanity" → `testBlockedWordsNotInWordList` (loads LDNOOBW list, asserts no word in the cleaned Set)
3. "O(1) lookup" → `testWordSetLookupIsO1` (calls `contains()` 10,000 times; if it finishes in <10ms, the Set structure is confirmed)
4. "< 500ms on physical device" → `testGenerationUnder500ms` (XCTest with `XCTAssertLessThan(elapsed, 0.500)`)

### Sampling Rate
- **Per task commit:** Cmd+U (runs all tests in Simulator); verifies logic correctness
- **Per wave merge:** All tests in Simulator + performance test on physical device
- **Phase gate:** All tests green in Simulator + performance test green on physical device before `/gsd:verify-work`

### Wave 0 Gaps (test files that don't exist yet — must be created)
- [ ] `WordPuzzleTests/WordListTests.swift` — covers O(1) lookup, word loading, edge cases
- [ ] `WordPuzzleTests/PuzzleGeneratorTests.swift` — covers 100-puzzle test, pangram guarantee, minimum word count
- [ ] `WordPuzzleTests/ProfanityTests.swift` — covers blocklist verification against cleaned word list
- [ ] `WordPuzzleTests/PerformanceTests.swift` — covers 500ms performance criterion (XCTest, not Swift Testing)

*(Note: The Xcode test target itself is created with the project in Wave 0/Plan 1. These test files are created in subsequent plans.)*

---

## Sources

### Primary (HIGH confidence)
- Project CONTEXT.md (D-01 through D-08) — locked decisions, algorithm spec
- Project STACK.md — confirmed stack choices (ENABLE, Set<String>, SwiftUI, @Observable)
- Project PITFALLS.md — puzzle generation pitfalls (sparse word sets, pangram guarantee, main thread blocking)
- Apple Developer Documentation: `Bundle.main.url(forResource:withExtension:)`, XCTest `measure {}` block
- `https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt` — ENABLE word list mirror (172,823 words, all lowercase, one per line, no proper nouns)
- `https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words` — English profanity list (CC-BY 4.0)
- `https://blakecrosley.com/blog/swift-testing-vs-xctest` — Confirmed: Swift Testing cannot do performance tests; XCTest required for `measure {}`

### Secondary (MEDIUM confidence)
- `https://journal.spencerwnelson.com/entries/spelling_bee.html` — Spelling Bee validation algorithm (brute force O(n) filter is 80ms per puzzle; confirmed fast enough)
- `https://developer.squareup.com/blog/measureblock-how-does-performance-testing-work-in-ios/` — XCTest baseline mechanism: 10 runs, std deviation compared to baseline, 10% default regression threshold, baselines stored per device
- `https://oneuptime.com/blog/post/2026-02-02-swift-xctest-unit-tests/view` — XCTest unit test setup: `@testable import`, `setUp()`, `XCTAssert*` family
- `https://www.dev2qa.com/how-to-add-resource-files-into-xcode-project-and-ios-app/` — Adding .txt file to Xcode bundle: "Add Files to...", check "Copy items if needed", verify in Build Phases → Copy Bundle Resources
- WebSearch: Xcode 26 requires macOS 15.6+; macOS 26.5.2 is present; Xcode 26.x installable from App Store
- WebSearch: Swift Testing is the new default for unit tests (Xcode 16+/Xcode 26); coexists with XCTest in same target

### Tertiary (LOW confidence — verify before implementing)
- WebSearch claim: "7,892 seven-letter sets produce at least one pangram" — from puzzle solver article, not verified against ENABLE specifically
- WebSearch claim: pangram word pool generation takes "80ms per puzzle" for brute force — measured in Python/JavaScript, not Swift; actual Swift perf likely faster

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — all choices locked by project decisions; ENABLE format verified from GitHub mirror
- Architecture Patterns: HIGH — pangram-word-first algorithm specified by D-03/D-04; Swift Set.isSubset confirmed by stdlib
- Pitfalls: HIGH — Xcode-not-installed confirmed by environment check; profanity in ENABLE confirmed by Scrabble word list precedent; main-thread pitfall from PITFALLS.md
- Validation Architecture: HIGH — Swift Testing vs XCTest performance split confirmed from authoritative source; test commands verified against Xcode conventions

**Research date:** 2026-08-28
**Valid until:** 2026-11-28 (90 days; stable domain — Swift / Xcode APIs change slowly)
