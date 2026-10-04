---
phase: 09-player-stats-screen
plan: 04
subsystem: ui
tags: [swiftui, settings, stats, round-over]
requires: [09-02]
provides:
  - SettingsView Stats row (stats: PlayerStats param)
  - MissedWordsView best/streak summary (bestScore, currentStreak, onShowStats params)
affects: [09-05]
key-files:
  modified:
    - WordPuzzle/WordPuzzle/Settings/SettingsView.swift
    - WordPuzzle/WordPuzzle/Game/Views/MissedWordsView.swift
    - WordPuzzle/WordPuzzleTests/SettingsViewTests.swift
  created:
    - WordPuzzle/WordPuzzleTests/MissedWordsViewTests.swift
requirements-completed: [P9-D]
duration: 10min
completed: 2026-10-04
---

# Phase 9 Plan 04: Stats Entry Points Summary

Settings "Stats" NavigationLink row (pushes StatsView with no second Done) and a tappable "Best B · Streak S" line on the round-over screen, both value-in/closure-out with defaulted params.

## Tasks
1. Settings Stats row: commit see git log ("feat(09-04): add Stats NavigationLink row to Settings"). Identifier `settingsStatsRow`.
2. MissedWordsView summary line: commit "feat(09-04): add tappable Best/Streak summary to round-over screen". Identifier `roundOverStatsSummary`; hidden when `onShowStats` is nil.

## Deviations from Plan
None. Full WordPuzzleTests suite passed (TEST SUCCEEDED). GameView wiring remains for 09-05.

## Self-Check: PASSED
