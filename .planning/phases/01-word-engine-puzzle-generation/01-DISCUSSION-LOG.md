# Phase 1: Word Engine & Puzzle Generation — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 01-word-engine-puzzle-generation
**Areas discussed:** Project Setup, Generator Algorithm, Word Length Floor, Profanity Filtering

---

## Project Setup

| Option | Description | Selected |
|--------|-------------|----------|
| Full App project now | Create one Xcode App project with engine in a folder inside the app target; XCTest unit tests in existing test target. Simpler for first-timer. | ✓ |
| Swift Package first | Build PuzzleEngine as standalone SPM package, add Xcode app in Phase 3. Cleaner separation but more complexity. | |

**User's choice:** Full App project now (recommended)

**Follow-up — where code lives:**

| Option | Description | Selected |
|--------|-------------|----------|
| Engine folder inside app target | `PuzzleEngine/` group inside app target. No extra targets, no linking. | ✓ |
| Separate framework target | Add `PuzzleEngineKit.framework` target inside same `.xcodeproj`. Adds linking complexity. | |

**User's choice:** Engine folder inside app target (recommended)

**Notes:** User noted this is their first iOS/Swift app and they need Xcode guidance. Plans must include step-by-step Xcode instructions.

---

## Generator Algorithm

| Option | Description | Selected |
|--------|-------------|----------|
| Pangram-word-first | Pick a 7-letter pangram word → use its letters as the puzzle set → random center letter → find valid words. Guarantees pangram by construction. | ✓ |
| Letter-set-first | Pick 7 random letters → search for pangrams → retry if none found. Higher rejection rate. | |

**User's choice:** Pangram-word-first (recommended)

**Follow-up — center letter selection:**

| Option | Description | Selected |
|--------|-------------|----------|
| Random from the 7 | Pick any of the 7 letters randomly; retry with another if <20 valid words. | ✓ |
| Maximize valid word count | Test all 7 letters, pick the one producing the most valid words. More deterministic. | |

**User's choice:** Random from the 7 (recommended)

---

## Word Length Floor

| Option | Description | Selected |
|--------|-------------|----------|
| 4 letters | NYT Spelling Bee standard. Good spread of easy and hard words. | ✓ |
| 3 letters | More words, but many are obscure or trivial. | |
| 5 letters | Harder, risks not hitting 20-word minimum. | |

**User's choice:** 4 letters (recommended)

---

## Profanity Filtering

| Option | Description | Selected |
|--------|-------------|----------|
| Static blocklist in code | ~200-500 word Swift Set subtracted at startup. No dependency. | |
| Filter at build time | One-time script to strip bad words; ship pre-cleaned list. | |
| You decide | Claude picks simplest approach satisfying PUZZ-02. | ✓ |

**User's choice:** You decide (Claude's discretion)

---

## Claude's Discretion

- Profanity filtering: pre-filter at build time (ship clean word list)
- Retry cap for generator: planner decides (1000 attempts is a reasonable bound)
- PuzzleEngine/ internal file structure: planner decides based on simplicity for first-time iOS dev

## Deferred Ideas

None.
