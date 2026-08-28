---
plan: 01-01
phase: 01-word-engine-puzzle-generation
status: complete
completed: 2026-08-28
commits:
  - 8675994  # word list generation
  - fc7959d  # Xcode project + bundle
self_check: PASSED
---

## What Was Built

Xcode 26 project scaffold and profanity-filtered word list bundled as an app resource. All four tasks complete.

## Key Files

| File | Purpose |
|------|---------|
| `WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` | Xcode project (nested one level — see paths below) |
| `WordPuzzle/WordPuzzle/WordPuzzleApp.swift` | App entry point |
| `WordPuzzle/WordPuzzle/ContentView.swift` | Default SwiftUI content view |
| `WordPuzzle/WordPuzzle/PuzzleEngine/` | Empty group — ready for engine code in Plan 02 |
| `WordPuzzle/WordPuzzle/enable-clean.txt` | Profanity-filtered word list, 172,678 words |
| `scripts/filter_profanity.py` | One-time build script (ENABLE − LDNOOBW set-difference) |
| `scripts/enable1.txt` | ENABLE source list (172,823 words) |
| `scripts/ldnoobw-en.txt` | LDNOOBW blocklist |

## Critical Paths for Plan 02

**Project nesting (Xcode placed project one level deep):**
- Repo root: `/Users/patrickhoughton/Documents/GitHub/word-puzzle-ios/`
- Xcode project: `WordPuzzle/WordPuzzle.xcodeproj`
- App source directory: `WordPuzzle/WordPuzzle/` ← create engine files here
- PuzzleEngine group: `WordPuzzle/WordPuzzle/PuzzleEngine/` ← place engine Swift files here
- Test target directory: `WordPuzzle/WordPuzzleTests/` ← place test files here

**Bundle resource name for WordList.swift:**
```swift
Bundle.main.url(forResource: "enable-clean", withExtension: "txt")
```
The file is at `WordPuzzle/WordPuzzle/enable-clean.txt` in the synchronized group.

**Xcode 26 file format:** Uses `PBXFileSystemSynchronizedRootGroup` — no per-file entries in pbxproj. Any `.swift` file placed under `WordPuzzle/WordPuzzle/` is automatically compiled. Resource files (`.txt`) are automatically bundled. No manual "Add Files" step needed for Plan 02 engine files — just write them to disk.

**Scheme name for xcodebuild:** `WordPuzzle`
**Deployment target:** iOS 17.6

## Word List Stats

- Source (ENABLE): 172,823 words
- Removed by blocklist: 145 words  
- Final count: 172,678 words (all ≥ 4 letters after WordList.load() filters)
- Filter: whole-word exact match (case-insensitive), no substring removal

## Deviations from Plan

1. **Xcode 26 testing dropdown vs "Include Tests" checkbox** — plan expected a checkbox; Xcode 26 shows a "Testing System" dropdown. Selected "Swift Testing with XCTest UI Tests", which created both `WordPuzzleTests` (unit) and `WordPuzzleUITests` targets.
2. **Xcode project nested one level deep** — plan assumed `WordPuzzle.xcodeproj` at repo root; Xcode created it at `WordPuzzle/WordPuzzle.xcodeproj`. All downstream paths adjusted accordingly.
3. **`PBXFileSystemSynchronizedRootGroup` format** — Xcode 26 uses automatic file-system sync instead of explicit per-file pbxproj references. No explicit Copy Bundle Resources section; Xcode manages it automatically.
4. **Deployment target 17.6 not 17.0** — Xcode 26 offered 17.6 as the earliest iOS 17 option. @Observable requires iOS 17+; 17.6 satisfies this.
5. **WordPuzzle/ folder trashed during project creation** — Xcode prompted to trash the existing folder (created by Task 2 for the word list). Trashed and restored `enable-clean.txt` from git after project creation.
