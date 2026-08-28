---
plan: 01-03
phase: 01-word-engine-puzzle-generation
status: complete
completed: 2026-08-28
commits:
  - d73579a  # PerformanceTests.swift
self_check: PASSED
---

## What Was Built

XCTest performance gate verifying PUZZ-03's "puzzle generation completes in under 500ms on a physical device" success criterion.

## Key Files

| File | Purpose |
|------|---------|
| `WordPuzzle/WordPuzzleTests/PerformanceTests.swift` | XCTest hard 500ms gate + measure{} baseline |

## On-Device Result

| Field | Value |
|-------|-------|
| Device | iPhone 15 Pro |
| iOS | 26.6 |
| `testGenerationUnder500ms` | **0.28s (280ms)** — PASSED |
| Margin | 220ms under the 500ms ceiling |
| Full suite on device | 15/15 tests green |

## PUZZ-03 Closed

Puzzle generation on physical hardware: **280ms** — well within the 500ms target. The `XCTAssertLessThan(elapsed, 0.500)` hard gate passed. `measure{}` baseline set on device for regression tracking.

## Deviations from Plan

1. **iPhone 15 Pro used instead of "any iPhone 12+"** — plan mentioned iPhone 12+ as the target class; 15 Pro is well within that range.
2. **iOS 26.6 on device** — plan assumed iOS 17+; 26.6 satisfies the requirement.
3. **Simulator showed only PerformanceTests in filtered run** — full suite (15 tests) confirmed green in the unfiltered Cmd+U run on device.
