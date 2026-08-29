# Phase 3: Core Game UI - Research

**Researched:** 2026-08-29
**Domain:** SwiftUI game UI (hex tile input, gesture-driven word building, haptics, animation, scoring/rank display)
**Confidence:** MEDIUM-HIGH

## Summary

Phase 3 replaces the Phase 2 debug panel with the actual game screen. The hard technical problems are not the visuals but the **gesture system**: a single continuous drag across multiple hex letter tiles must append letters in the order the finger passes over them, AND separately, a drag-down on the assembled word (not on the tiles) must trigger submission. SwiftUI has no built-in "drag across siblings" gesture — it must be built from a single `DragGesture` on a parent container plus a hit-test against each tile's globally-tracked frame (`GeometryReader` + `PreferenceKey`/anchor pattern). This is a well-documented pattern (multiple independent sources agree) but is the single highest-risk item in this phase for a first-time iOS developer.

Haptics and scoring math are comparatively simple: iOS 17+ ships `.sensoryFeedback(_:trigger:)`, a SwiftUI-native replacement for the `UINotificationFeedbackGenerator`/`UIImpactFeedbackGenerator` classes CLAUDE.md mentions — since this project's deployment target is iOS 17.6 (confirmed in `project.pbxproj`), use the modifier, not the UIKit classes directly. The NYT Spelling Bee rank-tier percentages locked in CONTEXT.md D-09 were independently verified against multiple current sources and match exactly.

One structural conflict was found and must be flagged to the planner: `.planning/REQUIREMENTS.md` lists **"NYT-style hex honeycomb layout"** under "Out of Scope" citing App Store Guideline 4.3 clone risk, but `03-CONTEXT.md` D-01 explicitly locks in a honeycomb hex layout with a center hex "per CLAUDE.md's recommended... approach." CONTEXT.md is dated the same day and represents an explicit, discussed decision, so per the locked-decisions rule this research does not second-guess it — but the planner and user should be aware this decision reverses an earlier written requirement, and it carries a genuine (if debatable) App Store risk worth a one-line acknowledgment in the plan or PROJECT.md decision log.

**Primary recommendation:** Build a single `GameViewModel` (`@Observable`) owning puzzle/round state; build the hex grid as a `ZStack` of a custom `HexagonShape` positioned via trigonometry (not the SwiftUI `Layout` protocol, which is overkill for a fixed 7-tile flower); implement letter input via one `DragGesture(minimumDistance: 0)` on the tile-container `ZStack` using a `PreferenceKey`-collected frame dictionary for hit-testing, with plain `.onTapGesture` on each tile for the tap path; implement submission as a *separate* `DragGesture` scoped only to the word-display `Text`/container, gated on `translation.height` exceeding a threshold; use `.sensoryFeedback(.success, trigger:)` for correct-word haptics.

## User Constraints

### Locked Decisions
- **D-01:** Honeycomb hex layout — one center hex visually distinguished (color/border) surrounded by 6 outer hexes, per CLAUDE.md's recommended custom `Shape`/hex-clipped `ZStack` approach.
- **D-02:** Input supports BOTH tap-to-append (tap letters in sequence) AND swipe/drag-to-connect across letters (NYT-style continuous drag). Either path appends to the current word. User explicitly chose this over tap-only despite the added gesture-handling complexity for a first iOS project.
- **D-03:** Shuffle button (PUZZ-04) animates the 6 outer letters into new random positions (`withAnimation` + position swap) — not an instant jump.
- **D-04:** The in-progress word displays above the hex grid, updating live as letters are tapped/dragged.
- **D-05:** A Delete button removes the last letter; tapping the assembled word itself clears it entirely.
- **D-06:** Submission is a swipe-down gesture on the assembled word (drag it downward past a threshold) — there is NO dedicated Submit button. This was a deliberate, explicit user choice (initially proposed as a two-finger pinch, then revised to swipe-down) — do not substitute a button in planning or research.
- **D-07:** Invalid word: the word display shakes and shows a generic "Not a valid word" message. Phase 3 does NOT distinguish reasons (already found / too short / missing center letter / not in list) — that granularity is out of scope for this pass.
- **D-08:** Valid word: the word display briefly highlights/pops and shows the points earned ("+N") before clearing, in addition to the required haptic (RET-03).
- **D-09:** Score/progress uses a rank/tier system, not a plain number. Uses an original 10-tier ladder (NOT NYT Spelling Bee's tier names — avoided for App Store 4.3 clone-risk), at NYT's same percentage thresholds:
  - Novice: 0% / Rookie: 2% / Apprentice: 5% / Wordsmith: 8% / Adept: 15% / Skilled: 25% / Expert: 40% / Virtuoso: 50% / Master: 70% / Legend: 100%
  - Maximum possible score for a puzzle = `ScoreCalculator.score(for:pangrams:)` applied to ALL of `Puzzle.validWords`, using `Puzzle.pangrams` as the pangram set — computed once when the puzzle is generated.
- **D-10:** A round ends only when the user taps a manual "Finish"/"End Round" button. No timer, no auto-end when all words are found.
- **D-11:** The missed-words reveal screen groups missed words by word length, with any missed pangram(s) specially highlighted.
- **D-12:** Dismissing the missed-words screen immediately starts a new puzzle via the existing `generatePuzzle(from:)` — no separate start/menu screen exists in Phase 3.

### Claude's Discretion
- Exact hex tile sizing/spacing and color palette for center vs. outer letters
- Exact wording of the "+N" points popup and the generic invalid-word message
- Swipe-down gesture distance/velocity threshold to trigger submission, and any visual cue that a word is "armed" to submit
- Whether `persistenceStore.record(score:wordsFoundCount:)` is called at Finish-tap time before or after the missed-words screen renders — planner picks whichever is simplest to test
- Whether `UITextChecker` (CLAUDE.md's secondary validator, intended for rejecting proper nouns) is actually needed in Phase 3 — since the bundled ENABLE word list (`enable-clean.txt`, loaded by `WordList`) only contains valid lowercase dictionary words already, proper nouns would not validate against it regardless of `UITextChecker`. Planner/researcher should confirm whether this makes `UITextChecker` unnecessary for the MVP round-play flow.
  - **Research finding: confirmed unnecessary.** `WordList.load()` (`WordPuzzle/PuzzleEngine/WordList.swift`) builds `words: Set<String>` exclusively from `enable-clean.txt` lines lowercased/trimmed/length-filtered — there is no code path where a proper noun could enter this set (ENABLE is a common-word list; it does not contain capitalized proper nouns as separate entries, and everything is lowercased on load anyway). `GameViewModel`'s validation only needs `wordList.contains(word)` + the puzzle's letter/center-letter rule (mirroring `isValidPuzzleWord` in `PuzzleGenerator.swift`). `UITextChecker` can be skipped entirely for Phase 3 — no code should import it.
- GameViewModel structure and how puzzle/round state (current word, found words, score) is owned — follow CLAUDE.md's MVVM + `@Observable` pattern

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within Phase 3 scope. Per-reason invalid-word messaging (already found / too short / missing center letter / not in list) was considered and explicitly deferred past Phase 3 (see D-07) rather than dropped — a future polish phase could add it.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GAME-01 | User can view 7 letters (center highlighted) and submit words | Hex layout pattern (Architecture §1), tap + drag gesture pattern (Architecture §2) |
| GAME-02 | App validates submitted words against bundled dictionary, immediate feedback | `WordList.contains(_:)` already O(1); validation rule mirrors `PuzzleGenerator.isValidPuzzleWord` (see Code Examples) |
| GAME-03 | Score and found-word count update in real time | `GameViewModel` `@Observable` state + `ScoreCalculator.points(for:isPangram:)` per submission (see Code Examples) |
| GAME-04 | User sees all missed words at round end | `Puzzle.validWords` minus found-words `Set`, grouped by `word.count` (see Code Examples) |
| PUZZ-04 | User can shuffle displayed letters | `withAnimation` + `Array.shuffled()` restricted to the 6 non-center letters (Architecture §3) |
| RET-03 | Haptic feedback on correct word submission | `.sensoryFeedback(.success, trigger:)`, iOS 17.4+ (Standard Stack; confirmed against deployment target 17.6) |

## Standard Stack

### Core
| API / Framework | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI `Shape` protocol | iOS 17.6 (project target) | Custom hexagon tile | Apple's documented path for arbitrary vector shapes; no library needed |
| SwiftUI `DragGesture` | iOS 17.6 | Drag-to-connect letter input + swipe-down submit | Native gesture type; supports `minimumDistance`, `.onChanged`/`.onEnded`, translation |
| SwiftUI `.sensoryFeedback(_:trigger:)` | iOS 17.0+ (general), some cases 17.4+ | RET-03 haptic feedback | SwiftUI-native replacement for `UINotificationFeedbackGenerator`; no UIKit bridging needed |
| SwiftUI `PreferenceKey` + `GeometryReader`/`.background(GeometryReader{...})` | iOS 17.6 | Collect each hex tile's global frame for drag hit-testing | Standard SwiftUI technique for cross-sibling geometry communication; no library needed |
| `withAnimation` / `.animation(_:value:)` | iOS 17.6 | Shuffle animation (D-03), shake (D-07), pop/+N (D-08) | Native declarative animation; sufficient for all Phase 3 motion needs |
| `@Observable` (Observation framework) | iOS 17.6 | `GameViewModel` state | Matches established `WordList`/`PersistenceStore`/`EntitlementStore` convention already in the codebase |

### Supporting
| API | Purpose | When to Use |
|-----|---------|-------------|
| `GeometryEffect` (custom `Shake: GeometryEffect`) | Shake animation for invalid word (D-07) | If `.sensoryFeedback` + a simple `.offset`/`.animation` combo feels insufficiently "shake-like"; a sine-wave `GeometryEffect` driven by `animatableData` is the standard technique (objc.io pattern) — first try the simpler `withAnimation(.default.repeatCount(3, autoreverses: true))` on a small horizontal offset before reaching for `GeometryEffect` |
| `ScrollView` + `LazyVStack` | Missed-words list (GAME-04), grouped by length | Per CLAUDE.md explicit guidance — never `List` (row separators/chrome) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual trig-positioned `ZStack` for the 7-hex flower | SwiftUI `Layout` protocol (custom `Layout` conformance) | `Layout` is the "correct" modern tool for arbitrary custom arrangements and is reusable/testable in isolation, but is more ceremony (needs `sizeThatFits`/`placeSubviews`) for a **fixed 7-tile cluster that never changes shape** — a `ZStack` + `.offset(x:y:)` computed once from `cos`/`sin` is simpler and sufficient here. Reconsider `Layout` only if a future phase needs a resizable/reflowable grid. |
| Custom `DragGesture` + `PreferenceKey` hit-testing for drag-to-connect | A third-party gesture/path-tracing library | No mature, actively maintained SPM library specifically targets "drag across sibling views to build a path" for word games; CLAUDE.md's "no third-party dependency" preference and the Don't Hand-Roll analysis below both favor the native approach — this is not a solved-problem-with-a-library situation |
| `UINotificationFeedbackGenerator` (UIKit, CLAUDE.md's originally documented API) | `.sensoryFeedback(_:trigger:)` (SwiftUI, iOS 17+) | CLAUDE.md documents the UIKit class because it predates iOS 17 general availability assumptions; since Phase 3 targets iOS 17.6 exclusively, the SwiftUI modifier is strictly simpler (no `UIFeedbackGenerator` instance lifecycle, no manual `.prepare()`) and should be preferred. See State of the Art section. |

**Installation:** None — all APIs used are part of the iOS 17.6 SDK shipped with Xcode 26.6. No SPM packages need to be added for Phase 3 (confirmed: `project.pbxproj` currently has zero `XCRemoteSwiftPackageReference` entries).

**Version verification:** N/A (no third-party packages). SDK APIs verified against Apple's current documentation via WebFetch (see Sources) and against this project's actual `IPHONEOS_DEPLOYMENT_TARGET = 17.6` (confirmed via `grep` on `project.pbxproj`).

## Architecture Patterns

### Recommended Project Structure
```
WordPuzzle/WordPuzzle/
├── Game/                          # NEW group for Phase 3
│   ├── GameViewModel.swift        # @Observable round/puzzle state, submit/shuffle/finish logic
│   ├── RankTier.swift             # original tier enum + percentage-of-max lookup (D-09)
│   └── Views/
│       ├── GameView.swift         # top-level screen; replaces ContentView's DEBUG panel
│       ├── HexagonShape.swift     # custom Shape conforming to Shape protocol
│       ├── LetterGridView.swift   # 7-hex flower + tap/drag gesture handling + shuffle
│       ├── WordDisplayView.swift  # in-progress word + swipe-down-to-submit gesture + shake/pop feedback
│       ├── ScoreBarView.swift     # rank tier + found-word count (GAME-03)
│       └── MissedWordsView.swift  # round-end reveal, grouped by length (GAME-04/D-11)
├── PuzzleEngine/                  # existing, unchanged
├── Services/                      # existing, unchanged
└── WordPuzzleApp.swift            # add GameViewModel + WordList instantiation/.environment()
```

### Pattern 1: Hexagon Shape via Trigonometry
**What:** A `Shape` that draws a regular hexagon by placing 6 points at 60° increments around the rect's center.
**When to use:** For each of the 7 tiles (1 center + 6 outer).
**Example:**
```swift
// Source: standard SwiftUI Shape technique, cross-verified across multiple
// independent tutorials (Medium/devtechie, TechChee, dhiwise) — HIGH confidence,
// this is basic trigonometry, not a fragile API detail.
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            // Flat-top hexagon: start angle -30° so two sides are horizontal
            let angle = Angle(degrees: Double(i) * 60 - 30)
            let point = CGPoint(
                x: center.x + radius * cos(angle.radians),
                y: center.y + radius * sin(angle.radians)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
```

### Pattern 2: Fixed 7-Tile Flower Positioning
**What:** Position the 6 outer hexes around a fixed center hex using the same angle math, at a radius large enough to avoid overlap (~1.5–1.75× the hex's own radius, tune visually).
**When to use:** `LetterGridView` layout.
**Example:**
```swift
// Source: derived from standard "points touch at flat sides, offset row by
// sqrt(3) * size" honeycomb math (Caleb Hearth, "Drawing a Hex Grid in
// SwiftUI") adapted to a single fixed ring rather than a tiled grid.
// MEDIUM confidence on exact radius multiplier — tune visually on device.
struct LetterGridView: View {
    let centerLetter: Character
    let outerLetters: [Character]  // exactly 6, order = current shuffle state
    let hexSize: CGFloat = 70

    var body: some View {
        ZStack {
            HexTileView(letter: centerLetter, isCenter: true)
            ForEach(Array(outerLetters.enumerated()), id: \.offset) { index, letter in
                let angle = Angle(degrees: Double(index) * 60)
                let radius = hexSize * 1.6
                HexTileView(letter: letter, isCenter: false)
                    .offset(
                        x: radius * cos(angle.radians),
                        y: radius * sin(angle.radians)
                    )
                    .animation(.spring, value: outerLetters) // D-03 shuffle animates, doesn't jump
            }
        }
    }
}
```

### Pattern 3: Drag-to-Connect Across Tiles (D-02)
**What:** A single `DragGesture` on the tile container, hit-tested against each tile's globally-tracked frame.
**When to use:** `LetterGridView` — this satisfies the "swipe/drag-to-connect" half of D-02 (the tap half is a plain `.onTapGesture` per tile, which is much simpler and needs no special pattern).
**Example:**
```swift
// Source: pattern cross-verified across multiple independent sources (SwiftUI
// Lab "Communicating with the View Tree", Medium "Preference System in
// SwiftUI", Apple Developer Forums thread 127002 on adjacent-view drag) —
// MEDIUM confidence (no single official Apple doc demonstrates this exact
// composition, but the constituent APIs — PreferenceKey, coordinateSpace:
// .global, DragGesture(minimumDistance:) — are all official and the
// composition pattern is consistent across sources).
struct TileFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// Each HexTileView reports its own frame:
// .background(GeometryReader { geo in
//     Color.clear.preference(key: TileFramePreferenceKey.self,
//                             value: [tileIndex: geo.frame(in: .named("grid"))])
// })

// Parent LetterGridView:
// .coordinateSpace(name: "grid")
// .onPreferenceChange(TileFramePreferenceKey.self) { frames = $0 }
// .gesture(
//     DragGesture(minimumDistance: 0, coordinateSpace: .named("grid"))
//         .onChanged { value in
//             if let hitIndex = frames.first(where: { $0.value.contains(value.location) })?.key,
//                hitIndex != lastAppendedIndex {
//                 viewModel.append(letterAt: hitIndex)
//                 lastAppendedIndex = hitIndex
//             }
//         }
//         .onEnded { _ in lastAppendedIndex = nil }
// )
```
**Critical detail:** `minimumDistance: 0` on this gesture is required so a plain tap-and-release without movement doesn't get swallowed — but this can also fight with each tile's individual `.onTapGesture`. Use `.simultaneousGesture` (not `.gesture`) for the container drag, or attach the drag gesture only to a full-size invisible overlay above the tiles rather than composing it with per-tile tap gestures, to avoid the two gesture recognizers cancelling each other. Verify this interaction manually on-device early — SwiftUI gesture composition ambiguity here is a documented pitfall (see Common Pitfalls).

### Pattern 4: Swipe-Down-to-Submit (D-06)
**What:** A `DragGesture` scoped ONLY to the word-display view (not the tile grid), checking `translation.height` in `.onEnded`.
**Example:**
```swift
// Source: pattern verified against fatbobman.com "SwiftUI Gestures" and
// createwithswift.com "Responding to gestures: Dragging" — MEDIUM confidence,
// standard technique, exact threshold value is a UX tuning choice (Claude's
// Discretion per CONTEXT.md).
Text(viewModel.currentWord)
    .gesture(
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Optional: drive a "armed to submit" visual as translation.height increases
                isArmedToSubmit = value.translation.height > armThreshold
            }
            .onEnded { value in
                if value.translation.height > submitThreshold {
                    viewModel.submitCurrentWord()
                }
                isArmedToSubmit = false
            }
    )
```

### Pattern 5: Haptic Feedback (RET-03)
**What:** `.sensoryFeedback(.success, trigger:)` fires when a trigger value changes.
**Example:**
```swift
// Source: Apple official docs (developer.apple.com/documentation/swiftui/
// view/sensoryfeedback(_:trigger:)) — HIGH confidence.
// Requires iOS 17.0+ for the modifier itself; project target is 17.6 — no
// availability guard needed. (Some SensoryFeedback cases document 17.4+;
// .success is available from 17.0.)
.sensoryFeedback(.success, trigger: viewModel.lastSubmissionWasCorrect)
.sensoryFeedback(.error, trigger: viewModel.lastSubmissionWasIncorrect)
```
Bind these triggers to `Equatable` state in `GameViewModel` (e.g. an incrementing counter or a toggled `Bool`) that changes exactly once per submission — do not reuse a single Bool that could fail to toggle on back-to-back identical outcomes.

### Anti-Patterns to Avoid
- **Recomputing tile frames every `body` evaluation without caching:** the `PreferenceKey` pattern already handles this correctly (frames update only when layout changes), but don't add redundant `GeometryReader` calls inside the drag handler itself — read from the already-collected `frames` dictionary.
- **Using `List` for the missed-words screen:** CLAUDE.md explicitly forbids this (row separators/chrome); use `ScrollView` + `LazyVStack`.
- **Storing full found-word list in SwiftData mid-round:** `GameRecord` (Phase 2, locked D-01) intentionally stores only `date`, `score`, `wordsFoundCount` — found words during a round belong in `GameViewModel`'s in-memory state only, written to `PersistenceStore.record(...)` once at Finish-tap.
- **A single shared `DragGesture` for both drag-to-connect and swipe-to-submit:** these must be two independent gesture recognizers scoped to different views (tile grid vs. word display) — conflating them will cause one to swallow the other's touches.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Haptic feedback triggering/lifecycle | Manual `UIImpactFeedbackGenerator` instance management (`.prepare()`, retain/release timing) | `.sensoryFeedback(_:trigger:)` | SwiftUI manages the generator lifecycle; iOS 17.6 target has no reason to touch UIKit haptics directly |
| Word validity checking (dictionary + puzzle rules) | A second, separate validator | Reuse the exact predicate from `PuzzleGenerator.isValidPuzzleWord` (private today — either duplicate the 3-line rule in `GameViewModel` or extract it to a shared internal function) plus `WordList.contains(_:)` | The puzzle generator and the round's live validator must agree on what counts as valid, or a puzzle could contain "valid" words the UI rejects. This is a correctness risk, not just a style preference. |
| Percentage-of-max-score rank lookup | Ad-hoc if/else chain scattered across views | A single `RankTier` type (enum or struct) with a static lookup table matching D-09's 10 tiers, computed once from `(currentScore, maxScore)` | Keeps the tier table in one testable place; avoids drift if tier logic is needed in both the live score bar and (later) a results screen |

**Key insight:** Nothing in this phase needs a third-party library — every mechanic (hex shape, gesture-to-path tracking, haptics, shake/pop animation) is achievable with stock SwiftUI/UIKit-bridged APIs at the iOS 17.6 target. The complexity is entirely in gesture composition, not missing tooling.

## Common Pitfalls

### Pitfall 1: Competing gesture recognizers on tap vs. drag
**What goes wrong:** A per-tile `.onTapGesture` and a container-level `DragGesture(minimumDistance: 0)` can both claim the same touch, causing taps to be silently swallowed by the drag gesture (or vice versa) — D-02 requires both paths to work.
**Why it happens:** SwiftUI's gesture disambiguation system picks one winner by default (`.gesture` composition is exclusive); `minimumDistance: 0` makes the drag gesture recognize immediately on touch-down, competing directly with taps.
**How to avoid:** Use `.simultaneousGesture(...)` instead of `.gesture(...)` for the container drag so both can fire; alternatively, implement "tap" as `.onChanged`/`.onEnded` logic within the single drag gesture itself (treat a drag that starts and ends on the same tile with near-zero movement as a tap) rather than using two separate gesture recognizers at all. The latter is more robust and is the pattern several sources on complex SwiftUI gestures recommend for exactly this kind of ambiguity.
**Warning signs:** Taps feel unresponsive or inconsistent on-device (simulator touch behavior can differ from a real trackpad-click-as-tap); test on the real iPhone per this phase's goal ("...works on a real iPhone").

### Pitfall 2: `PreferenceKey` frames stale after shuffle animation
**What goes wrong:** After D-03's shuffle animates outer letters to new positions, the drag-hit-test frames dictionary may briefly reflect old positions if the preference update lags the animation.
**Why it happens:** `.onPreferenceChange` fires on layout pass, and if the shuffle animation is still interpolating, the "final" frame preference may not have posted yet while a fast double-gesture starts.
**How to avoid:** Disable/ignore drag-to-connect input for the ~duration of the shuffle animation (a simple `isShuffling` guard flag in `GameViewModel`), since a user swiping mid-shuffle-animation is a rare edge case not worth solving precisely.
**Warning signs:** Occasional wrong-letter-appended bug reports specifically right after tapping Shuffle.

### Pitfall 3: `.sensoryFeedback` trigger not changing on repeated identical outcomes
**What goes wrong:** If the trigger value is, e.g., a `Bool` set to `true` on every correct word, back-to-back correct submissions after the first won't re-fire the modifier (SwiftUI feedback fires on *change*, not on every set).
**Why it happens:** `sensoryFeedback(_:trigger:)` is documented as firing "when the trigger value changes" — setting the same value twice is not a change.
**How to avoid:** Use an incrementing counter (`var submissionID: Int`) or a toggled state as the trigger, guaranteed to differ between consecutive submissions regardless of outcome.
**Warning signs:** Haptic works on the first correct word of a round, then silently stops working for subsequent correct words.

### Pitfall 4: Hex tile hit-testing area vs. visual clip mismatch
**What goes wrong:** `.clipShape(HexagonShape())` clips the *visual* rendering, but the underlying view's tappable/hit-testable frame remains its full bounding rectangle unless `.contentShape(HexagonShape())` is also applied — causing taps in the rectangle's corners (outside the visible hexagon) to register.
**Why it happens:** SwiftUI hit-testing and rendering clipping are separate systems; `clipShape` alone does not restrict hit-testing (this is documented SwiftUI hit-testing behavior).
**How to avoid:** Apply `.contentShape(HexagonShape())` in addition to `.clipShape(HexagonShape())` on each tile.
**Warning signs:** Tapping visually "outside" a hex tile but inside its bounding square still selects that letter, especially where two adjacent tiles' rectangles overlap near the honeycomb seams.

### Pitfall 5: Requirements/CONTEXT.md conflict on hex honeycomb layout
**What goes wrong:** Planner builds exactly what D-01 says (honeycomb hex, NYT-style) without noticing `.planning/REQUIREMENTS.md`'s "Out of Scope" table explicitly warns against this for App Store Guideline 4.3 clone-risk reasons.
**Why it happens:** CONTEXT.md (2026-08-29, same day) supersedes an earlier written constraint from REQUIREMENTS.md (2026-08-27) — likely a conscious trade-off made during `/gsd:discuss-phase`, but it is not stated as such anywhere.
**How to avoid:** Not a code fix — a documentation/awareness fix. Recommend the plan or PROJECT.md decision log record that this was a deliberate, discussed override of the original Out-of-Scope note, so a future reviewer (or App Store reviewer research pass) doesn't rediscover this as a surprise late in the project.
**Warning signs:** None at build time — this is a compliance/product risk, not a technical one.

## Code Examples

### GameViewModel skeleton (word submission + scoring)
```swift
// Illustrative — not verified against a compiled build; follows the
// @Observable convention already established in WordList/PersistenceStore.
@Observable
final class GameViewModel {
    private(set) var puzzle: Puzzle
    private(set) var currentWord: String = ""
    private(set) var foundWords: Set<String> = []
    private(set) var score: Int = 0
    let maxPossibleScore: Int   // computed once at puzzle generation (D-09)

    private let wordList: WordList

    init(puzzle: Puzzle, wordList: WordList) {
        self.puzzle = puzzle
        self.wordList = wordList
        self.maxPossibleScore = ScoreCalculator.score(
            for: puzzle.validWords,
            pangrams: Set(puzzle.pangrams)
        )
    }

    func append(_ letter: Character) {
        currentWord.append(letter)
    }

    func deleteLast() {
        guard !currentWord.isEmpty else { return }
        currentWord.removeLast()
    }

    func clearCurrentWord() {
        currentWord = ""
    }

    @discardableResult
    func submitCurrentWord() -> Bool {
        defer { currentWord = "" }
        let word = currentWord.lowercased()
        // Mirror PuzzleGenerator.isValidPuzzleWord's rule set + dictionary + not-already-found:
        guard word.count >= 4,
              word.contains(puzzle.centerLetter),
              Set(word).isSubset(of: puzzle.letters),
              wordList.contains(word),
              !foundWords.contains(word) else {
            return false
        }
        foundWords.insert(word)
        let isPangram = puzzle.pangrams.contains(word)
        score += ScoreCalculator.points(for: word, isPangram: isPangram)
        return true
    }

    var missedWords: [String] {
        puzzle.validWords.filter { !foundWords.contains($0) }
    }

    var missedWordsGroupedByLength: [Int: [String]] {
        Dictionary(grouping: missedWords, by: \.count)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `UINotificationFeedbackGenerator()` / `UIImpactFeedbackGenerator()` (UIKit, manually managed) | `.sensoryFeedback(_:trigger:)` (SwiftUI modifier) | iOS 17.0 (WWDC 2023) | CLAUDE.md documents the UIKit classes as the plan; since project deployment target is 17.6, prefer the SwiftUI modifier — simpler, no lifecycle management, matches the project's SwiftUI-first architecture direction. Not a breaking change — UIKit classes still work if ever needed, but there's no reason to reach for them here. |

**Deprecated/outdated:** Nothing else in this phase's domain is deprecated as of iOS 17.6 — `Shape`, `DragGesture`, `PreferenceKey`, `@Observable` are all current, actively-recommended APIs.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Xcode | Build/run/test | ✓ | 26.6 (Build 17F113) | — |
| iOS SDK / Simulator | On-device gesture/haptic testing | ✓ | iOS 26.5 simulators available (per Phase 1 STATE.md decision: use iPhone 17 simulator) | — |
| Real iPhone (physical device) | This phase's stated success bar ("...works on a real iPhone"), haptic feedback verification (simulator cannot produce real haptics) | Not verified from this environment — assume available per phase goal wording; flag if not | — | If no physical device is available at execution time, haptic (RET-03) and true drag-gesture feel can only be manually verified via Simulator's limited haptic preview / trackpad-as-touch approximation — this is a real gap, not a false negative |
| Swift Testing framework (`import Testing`) | Unit tests for `GameViewModel`, `RankTier`, missed-words grouping | ✓ | Built into Swift 6.3.3 toolchain, already used throughout `WordPuzzleTests/` | — |
| SPM third-party packages | None required for this phase | N/A | — | — |

**Missing dependencies with no fallback:** None identified from static inspection — the one open item (physical device access) is a process question, not an environment-detection question, and should be confirmed with the user before execution if uncertain.

**Missing dependencies with fallback:** Physical-device-only verifications (haptics, real touch drag feel) — Simulator can approximate but not fully substitute.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`, `@Test`, `#expect`) — confirmed in use across `WordPuzzleTests/` (e.g. `ScoreCalculatorTests.swift`, `PuzzleGeneratorTests.swift`) |
| Config file | None — no `.xctestplan`; tests run via the `WordPuzzle` scheme's default test action |
| Quick run command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/GameViewModelTests` |
| Full suite command | `xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17'` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| GAME-01 | Letters displayed, tap builds word, submit works | unit (word-building/submit logic in `GameViewModel`) + manual (visual layout, real gesture feel) | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testAppendAndSubmitBuildsWord` | ❌ Wave 0 |
| GAME-02 | Valid/invalid word feedback, no crash on invalid | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testSubmitInvalidWordReturnsFalse` | ❌ Wave 0 |
| GAME-03 | Score/found-count update live | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testScoreAndFoundCountUpdateOnCorrectSubmit` | ❌ Wave 0 |
| GAME-04 | Missed words revealed at round end, grouped by length | unit | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testMissedWordsGroupedByLength` | ❌ Wave 0 |
| PUZZ-04 | Shuffle rearranges non-center letters | unit (shuffle produces a permutation containing the same 6 letters, center untouched) + manual (animation feel) | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testShufflePreservesLetterSetExcludesCenter` | ❌ Wave 0 |
| RET-03 | Haptic feedback on correct submission | manual-only (simulator cannot verify real haptic hardware output) — automatable proxy: assert the `sensoryFeedback` trigger value changes on a correct submission | `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests/testCorrectSubmissionTogglesHapticTrigger` (proxy only — does not prove haptic actually fires) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test ... -only-testing:WordPuzzleTests/GameViewModelTests` (and `RankTierTests` once created)
- **Per wave merge:** Full suite command above
- **Phase gate:** Full suite green before `/gsd:verify-work`, PLUS a manual on-device pass (per this phase's explicit success criteria wording: "works on a real iPhone") covering: drag-to-connect across tiles, tap-to-append, swipe-down submit, shuffle animation, haptic feel, shake/pop feedback

### Wave 0 Gaps
- [ ] `WordPuzzleTests/GameViewModelTests.swift` — covers GAME-01, GAME-02, GAME-03, GAME-04, PUZZ-04, RET-03 (proxy)
- [ ] `WordPuzzleTests/RankTierTests.swift` — covers D-09's percentage-of-max tier lookup (not a numbered requirement but load-bearing for GAME-03's UI display)
- [ ] No shared fixture gap — existing `@Suite(.serialized)` + `WordList()`/`.load()` pattern from `PuzzleGeneratorTests.swift` is directly reusable for constructing a real `Puzzle` in `GameViewModelTests`
- [ ] Framework install: none — Swift Testing already present, no `xcodebuild -resolvePackageDependencies` needed (zero SPM deps)

## Sources

### Primary (HIGH confidence)
- [developer.apple.com — sensoryFeedback(_:trigger:) view modifier](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:)) — cases, iOS 17.4+ note, usage pattern
- Direct code inspection: `WordPuzzle/WordPuzzle/PuzzleEngine/{PuzzleModel,PuzzleGenerator,WordList}.swift`, `WordPuzzle/WordPuzzle/Services/{ScoreCalculator,PersistenceStore,GameRecord}.swift`, `WordPuzzle/WordPuzzle/{WordPuzzleApp,ContentView}.swift`, `WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` (deployment target, scheme, absence of SPM deps), `WordPuzzleTests/{PuzzleGeneratorTests,ScoreCalculatorTests,AppWiringTests}.swift`

### Secondary (MEDIUM confidence)
- [spellingbeesolver.net/faq/levels](https://spellingbeesolver.net/faq/levels) — NYT Spelling Bee 10-tier percentage table, cross-verified against WebSearch aggregate of beebom.com, connectionshintz.com, nytspellingbeeanswers.com, spellingbeetimes.com (all agree on the same percentages listed in D-09)
- SwiftUI hexagon `Shape` technique — cross-verified across Medium (devtechie, dhiwise, TechChee) tutorials; standard trigonometry, not a fragile API
- Drag-across-siblings hit-testing pattern (`PreferenceKey` + `.coordinateSpace(.global/.named)`) — cross-verified across SwiftUI Lab, Medium (Ancestry Product & Technology "SwiftUI Pro Tips: PreferenceKey"), Apple Developer Forums thread 127002
- Shake animation via `GeometryEffect`/`animatableData` — objc.io "SwiftUI: Shake Animation" (well-known, widely cited reference implementation)
- Swipe-down-to-dismiss/trigger threshold pattern — fatbobman.com "SwiftUI Gestures", createwithswift.com "Responding to gestures: Dragging"
- `.contentShape` vs `.clipShape` hit-testing distinction — general SwiftUI hit-testing documentation summarized via WebSearch (dev.to "SwiftUI Hit-Testing & Event Propagation Internals")

### Tertiary (LOW confidence)
- None — all findings above were either verified via official docs, cross-verified across ≥2 independent sources, or verified directly against this project's own code/config.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs confirmed against Apple's official docs and this project's actual deployment target (17.6); zero third-party dependencies needed
- Architecture (hex shape, positioning, tap gesture, shuffle, haptics): HIGH — standard, well-documented SwiftUI techniques
- Architecture (drag-to-connect hit-testing composition, swipe-down submit gesture priority): MEDIUM — the constituent APIs are official/HIGH confidence, but the exact composition of multiple simultaneous gestures on a fixed 7-tile cluster has no single canonical Apple example; flagged explicitly in Pitfall 1 as the phase's highest-risk item, expect on-device iteration
- Pitfalls: MEDIUM-HIGH — gesture composition and hit-testing pitfalls are well-documented SwiftUI community knowledge; the REQUIREMENTS/CONTEXT.md conflict pitfall is a direct textual finding from this project's own docs (HIGH confidence that the conflict exists, not a judgment call about which is "right")

**Research date:** 2026-08-29
**Valid until:** ~2026-09-28 (30 days — SwiftUI gesture/shape APIs are stable; re-verify sooner only if Xcode/iOS SDK version changes)
