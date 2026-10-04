# Phase 6: Differentiated Invalid-Word Messaging - Research

**Researched:** 2026-10-04
**Domain:** SwiftUI / @Observable view-model feedback plumbing (codebase-local)
**Confidence:** HIGH (all findings read directly from the repo; no external libraries)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Four player-facing reasons. Mapping: `word.count < 4` -> too short; missing `puzzle.centerLetter` -> missing center letter; `foundWordSet.contains(word)` -> already found; letters not subset of `puzzle.letters` -> not a word; `!wordList.contains(word)` -> not a word.
- **D-02:** `SubmissionOutcome.rejected` becomes `.rejected(reason: RejectionReason)` (or equivalent) with an enum of the four reasons. View maps reason -> text. Unit tests in `GameViewModelTests` assert each reason. Later features (999.10) key off a `.notInWordList`-style reason only.
- **D-03:** Exact strings: Too short "Too tiny!"; Missing center "Forgot the middle!"; Already found "Got that one already"; Not a word (dictionary or outside letter) "Hmm, not a word".
- **D-04:** Fixed text only; no interpolation of word or center letter.
- **D-05:** Already found = gentler: no shake, single light haptic (not double heavy burst), NO `wordRejected` sound, message in neutral/secondary color (not `GameTheme.errorColor`).
- **D-06:** Too short, missing center, not a word keep today's full rejection feedback (shake + double heavy haptic + `wordRejected` sound + error color); only text changes.
- **D-07:** Precedence = first failure in rule order: too short -> missing center -> (outside letter / already found / not in word list, existing guard order).

### Claude's Discretion
- Exact enum/case names; whether `rejectedSubmissionCount` still increments for duplicates or a separate counter is used (duplicate path must NOT play reject sound; `SoundEffect.forSubmission` may need the reason).
- Neutral color token for duplicate message; which light haptic.
- Message display duration (keep current timing unless it reads poorly).
- VoiceOver announcement of reason (nice to have).

### Deferred Ideas (OUT OF SCOPE)
- Rejected-word logging (backlog 999.10).
- Separate "uses a letter not in the puzzle" message (revisit only if keyboard input is added).
</user_constraints>

<phase_requirements>
## Phase Requirements

No requirement IDs are mapped (TBD). Derive from decisions:

| ID | Description | Research Support |
|----|-------------|------------------|
| D-01/D-02 | Typed rejection reason from view model | Enum + guard split below |
| D-03/D-04 | Exact fixed strings | View-side `message` mapping |
| D-05/D-06 | Per-reason intensity | WordDisplayView + GameView/SoundManager changes below |
| D-07 | Precedence | Guard order below |
</phase_requirements>

## Summary

Entirely codebase-local; no new libraries. Four files change in production (`GameViewModel.swift`, `WordDisplayView.swift`, `GameView.swift`, `SoundManager.swift`) plus two test files. The compile-breaking surface from adding an associated value to `.rejected` is tiny: only ONE existing reference to `.rejected` exists in all Swift sources outside the producer: `GameViewModelTests.swift:47` (`#expect(vm.lastOutcome == .rejected)`), plus the producer at `GameViewModel.swift:185`. No `switch` over `SubmissionOutcome` exists; consumers use `guard case let .accepted(...)` pattern matches (`GameView.swift:96`, `WordDisplayView.swift:101`), which keep compiling.

**Primary recommendation:** Add `enum RejectionReason: Equatable { case tooShort, missingCenterLetter, alreadyFound, notAWord }`, make `.rejected(RejectionReason)`, keep `rejectedSubmissionCount` incrementing for ALL four reasons (it is the change-trigger for the view's feedback), and gate the SOUND and the HAPTIC/shake/color by reason at the consumers. Put the reason -> sound decision in `SoundEffect` (testable pure function), not inline in the view.

## Existing Code Inventory (verified by grep/read)

| Location | What | Impact |
|----------|------|--------|
| `Game/GameViewModel.swift:5-8` | `enum SubmissionOutcome: Equatable { accepted(word:points:isPangram:), rejected }` | Change `rejected` -> `rejected(RejectionReason)`; synthesized Equatable still works if `RejectionReason` is Equatable |
| `GameViewModel.swift:52,56` | `lastOutcome`, `rejectedSubmissionCount` (private(set)) | Keep both |
| `GameViewModel.swift:173-197` `submitCurrentWord() -> Bool` | One combined `guard` (lines 180-184) sets `lastOutcome = .rejected`, increments counter, returns false | Split into ordered per-reason guards; each sets reason; return type stays `Bool` (existing tests rely on it) |
| `GameViewModel.swift:140` | `lastOutcome = nil` on new round | No change |
| `Game/Views/GameView.swift:96` | `guard case let .accepted(_, _, isPangram)` | Unaffected |
| `GameView.swift:102-107` | `.onChange(of: rejectedSubmissionCount)` plays `forSubmission(accepted:false,isPangram:false)` unconditionally | MUST change: skip sound for `.alreadyFound` |
| `GameView.swift:152-154` | passes `outcome: viewModel.lastOutcome`, `rejectedCount:` to WordDisplayView | No signature change needed |
| `Game/Views/WordDisplayView.swift:38,46` | `@State feedbackIsError` toggles font + error color | Replace/extend with a style state (error vs neutral) |
| `WordDisplayView.swift:79` | `.onChange(of: rejectedCount) { showRejectedFeedback() }` | Read `outcome` inside; `lastOutcome` is set BEFORE the counter increments (same synchronous call), so `outcome` is already current when onChange fires (same pattern `showAcceptedFeedback` already relies on) |
| `WordDisplayView.swift:113-134` `showRejectedFeedback()` | hardcoded "Not a valid word", shake, double heavy `UIImpactFeedbackGenerator`, clears text after ~1.1s | Branch by reason |
| `WordDisplayView.swift:138,144` | `#Preview`s construct `WordDisplayView(... outcome: nil ...)` | Unaffected; add a previews per reason (optional) |
| `Services/SoundManager.swift:16` `SoundEffect.forSubmission(accepted:isPangram:)` | returns `.wordRejected` when not accepted | Existing 4 tests (`SoundManagerTests.swift:44-57`) call this signature; keep it working |
| `WordPuzzleTests/GameViewModelTests.swift:47` | `#expect(vm.lastOutcome == .rejected)` | BREAKS; update to `.rejected(.notAWord)` (zzzz: 4 chars, no center 'a', so actually -> `.missingCenterLetter`! see Pitfall 1) |
| `GameTheme.swift:45` | `errorColor = Color(.systemRed)`; `Color.secondary` is already used in WordDisplayView:55 for placeholder | Neutral color: use `Color.secondary` (or add `GameTheme.neutralFeedbackColor = Color.secondary`) |

## Standard Stack

No new dependencies. Swift Testing (`import Testing`, `@Test`, `#expect`) is the existing test framework; SwiftUI `.sensoryFeedback` and UIKit `UIImpactFeedbackGenerator` already in use.

## Architecture Patterns

### Recommended changes

```swift
// GameViewModel.swift
enum RejectionReason: Equatable {
    case tooShort, missingCenterLetter, alreadyFound, notAWord
}
enum SubmissionOutcome: Equatable {
    case accepted(word: String, points: Int, isPangram: Bool)
    case rejected(RejectionReason)
}

// in submitCurrentWord(), replacing the combined guard:
func reject(_ reason: RejectionReason) -> Bool {   // or a private method
    lastOutcome = .rejected(reason)
    rejectedSubmissionCount += 1
    return false
}
// order MUST be: (D-07)
if word.count < 4 { return reject(.tooShort) }
if !word.contains(puzzle.centerLetter) { return reject(.missingCenterLetter) }
if !Set(word).isSubset(of: puzzle.letters) { return reject(.notAWord) }
if foundWordSet.contains(word) { return reject(.alreadyFound) }
if !wordList.contains(word) { return reject(.notAWord) }
```
Keep the comment about agreement with `PuzzleGenerator.isValidPuzzleWord`.

Sound gating (testable, pure):
```swift
// SoundManager.swift -- add overload; keep existing forSubmission for compat
static func forRejection(_ reason: RejectionReason) -> SoundEffect? {
    reason == .alreadyFound ? nil : .wordRejected
}
```
GameView `onChange(of: rejectedSubmissionCount)`:
```swift
guard case let .rejected(reason) = viewModel.lastOutcome,
      let effect = SoundEffect.forRejection(reason) else { return }
SoundManager.shared.play(effect, enabled: soundEffectsEnabled)
```
(Check `SoundEffect` is not in a file where `RejectionReason` is not visible: same module, fine.)

WordDisplayView: add a `RejectionReason.message` extension (in the view file, or a small extension) with the four D-03 strings; `showRejectedFeedback()` does `guard case let .rejected(reason) = outcome else { return }`, then:
- set `feedbackText = reason.message`; `feedbackIsError = reason != .alreadyFound` (keep font `bodyFont` for both; color `errorColor` vs `Color.secondary`). Note current line 45-46 ties font AND color to `feedbackIsError`; for duplicates the font must still be `bodyFont` (not displayFont, which is the accept style). Introduce a 3-state style (`.accept/.error/.neutral`) or a second Bool `feedbackIsRejection`; recommend a small private enum `FeedbackStyle`.
- `.alreadyFound`: no shake; single light haptic via `UIImpactFeedbackGenerator(style: .light).impactOccurred()` (consistent with existing manual generator code; `.sensoryFeedback(.impact(weight:.light), trigger:)` would need a dedicated duplicate counter and is more plumbing); then clear text after the same 700ms-ish delay.
- other reasons: existing code unchanged.

### Anti-Patterns to Avoid
- **Do not use a Bool or "reason changed" trigger.** Two identical consecutive rejections (e.g., duplicate twice) must still fire; keep the monotonic counter (Phase 3 Pitfall 3).
- **Do not decide sound by comparing feedback text.** Use the enum.
- **Do not interpolate** the word/center letter (D-04).
- **Do not add a separate duplicate counter** unless needed: incrementing `rejectedSubmissionCount` for all reasons is the simplest, keeps the single onChange path, and leaves 999.10 a single hook.

## Don't Hand-Roll

| Problem | Use Instead |
|---------|-------------|
| Haptics | Existing `UIImpactFeedbackGenerator` (.light) |
| Neutral color | `Color.secondary` / GameTheme token, not a hard-coded RGB |
| Sound selection | Pure static func on `SoundEffect` so it is unit-testable |

## Common Pitfalls

### Pitfall 1: Existing test word "zzzz" now yields `.missingCenterLetter`, not `.notAWord`
`zzzz` has 4 letters, no 'a' (fixture center). Under D-07 precedence it reports missing center. Update the existing test to assert that, and choose fixtures per reason:
- tooShort: "can" (3 chars)  (also "ca")
- missingCenterLetter: "lend" (4 letters, subset of acdelnt, no 'a'; real word) or "zzzz"
- notAWord (outside letter): "zane"? (z not in letters); in-letters-but-not-a-word: "cnld"... must contain 'a', 4+ letters, subset, not in ENABLE, e.g. "ncla"/"tcaa" (verify not in list at test time, or assert `wordList.contains` false first)
- alreadyFound: submit "cane" twice
- Precedence: "cat" (3 chars, valid letters) -> tooShort; "lend"-style short and missing center, e.g. "len" -> tooShort (not missingCenter).
- Duplicate precedence over dictionary: submit valid word twice -> second is alreadyFound.

### Pitfall 2: Duplicate must also not increment `acceptedSubmissionCount`, score, or `foundWords` (already true; assert in test).

### Pitfall 3: Overlapping feedback timers
`showRejectedFeedback` clears `feedbackText` via un-cancelled `Task` after ~1.1s; a rapid second rejection (or accept) can have the earlier Task clear the newer text early. Existing behavior for accepts/rejects; duplicates make rapid repeat more likely (user re-swipes). Optional hardening: keep a `@State feedbackTask: Task<Void,Never>?` and cancel before starting a new one. Not required by CONTEXT; flag as optional.

### Pitfall 4: Dynamic Type (Phase 5 D-04)
Longest message "Got that one already" must not truncate at accessibility sizes. The feedback `Text` has `frame(minHeight: 40)` and no lineLimit, so it wraps and the box grows; keep `GameTheme.bodyFont`, consider `.lineLimit(1).minimumScaleFactor(0.7)` to mirror the word box and avoid pushing the hex grid down (UX-03 fix note in file).

### Pitfall 5: Shake state
`.alreadyFound` must not touch `shakeAmount`; a prior shake always resets to 0 after ~420ms, so no leak, but verify a duplicate right after a shake doesn't leave residual offset.

### Pitfall 6: Accessibility (optional)
VoiceOver: could post `AccessibilityNotification.Announcement(reason.message).post()` (iOS 17+). Optional; no existing usage of accessibility announcements in the codebase (grep found none).

## Code Examples
See "Recommended changes" above (all derived from existing patterns in the repo).

## Runtime State Inventory
Not a rename/migration phase: omitted. No persisted data stores `SubmissionOutcome` (it is in-memory only; `lastOutcome` reset per round), so no data migration.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | build + tests | yes | scheme `WordPuzzle` (only scheme) | - |
| iOS Simulator | tests | yes | iOS 26.5 runtime; iPhone 17 (69610FE7-0679-4A4E-9A92-66ACC9F97EDB), iPhone 17 Pro, iPhone Air, iPhone 17e etc., all Shutdown | xcodebuild boots on demand |

Haptic and sound behavior cannot be verified in Simulator (haptics are no-ops there); needs on-device check (project memory: automate checkpoints, install to device via Wi-Fi install script).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`, `#expect`) in `WordPuzzleTests`; `@Suite(.serialized) @MainActor` for GameViewModelTests (loads ENABLE WordList once) |
| Config file | `WordPuzzle/WordPuzzle.xcodeproj` scheme `WordPuzzle` (autocreated test plan) |
| Quick run command | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/GameViewModelTests -only-testing:WordPuzzleTests/SoundManagerTests` |
| Full suite command | `cd WordPuzzle && xcodebuild test -project WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests` (UI tests in WordPuzzleUITests are slower; exclude for per-task runs) |

(Simulator name/ID verified present via `xcrun simctl list devices available`. Test execution itself was not run during research.)

### Phase Requirements -> Test Map
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| D-01/D-02/D-07 | Each reason produced; precedence order | unit | quick run, GameViewModelTests | extend existing file (update line 47) |
| D-02 | duplicate does not change score/foundWords/acceptedCount; still increments rejectedSubmissionCount | unit | same | add |
| D-05 | `SoundEffect.forRejection(.alreadyFound) == nil`, others `.wordRejected` | unit | `-only-testing:WordPuzzleTests/SoundManagerTests` | add to existing file; keep 4 existing `forSubmission` tests green |
| D-03/D-04 | message strings exact | unit (test the `RejectionReason.message` mapping if placed in a non-View extension, which is recommended for testability) | quick run | add |
| D-05/D-06 | shake/haptic/color intensity | manual (device) | n/a - haptics/animation not observable in unit tests | manual-only; justify: UIKit haptics are no-ops in Simulator |

### Sampling Rate
- Per task commit: quick run command
- Per wave merge: full unit suite
- Phase gate: full suite green before `/gsd:verify-work`; plus one manual on-device pass for duplicate (light haptic, no sound, gray text, no shake) vs invalid (full feedback)

### Wave 0 Gaps
None for infrastructure; only the existing test at `GameViewModelTests.swift:47` must be updated in the same task as the enum change or the test target won't compile.

## Open Questions

1. **Where to put the reason -> message mapping.** Recommendation: `extension RejectionReason { var message: String }` in a non-View file (e.g. GameViewModel.swift or a new small file) so it is unit-testable; view just reads it. Note new files must be added to the Xcode project (check whether the project uses file-system synchronized groups; if not, pbxproj edit needed).
2. **"zzzz" semantics** - resolved above (missing center).

## Sources

### Primary (HIGH confidence)
- Direct repo reads/grep: `GameViewModel.swift`, `WordDisplayView.swift`, `GameView.swift`, `SoundManager.swift`, `GameTheme.swift`, `GameViewModelTests.swift`, `SoundManagerTests.swift`, `06-CONTEXT.md`
- `xcrun simctl list devices available`, `xcodebuild -list`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH (no new deps)
- Architecture: HIGH (derived from existing patterns)
- Pitfalls: HIGH for 1,2,5; MEDIUM for timer overlap and Dynamic Type (reasoned from code, not run)

**Research date:** 2026-10-04
**Valid until:** 30 days (stable)

## Project Constraints (from CLAUDE.md)
- SwiftUI iOS 17+, MVVM with `@Observable`; no third-party deps; no network calls; no analytics of rejected words in v1.
- Work through GSD commands for file edits; fonts via `GameTheme` relative text styles (Dynamic Type).
- No `.claude/skills` or `.agents/skills` present.
