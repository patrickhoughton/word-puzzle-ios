---
status: resolved
trigger: "Stats do not seem accurate; Puzzles today/score/words found zero when game spans days"
created: 2026-11-02
updated: 2026-11-02
---

## Current Focus
hypothesis: CONFIRMED. todayTotalScore/Words read only finished GameRecords (written at Finish Round); puzzlesToday counts RoundStartRecord dated at round start.
next_action: add WordEventRecord (per accepted word, dated when found), derive today stats from it; carried-over round counts as a puzzle today.

## Symptoms
expected: split-by-day attribution; puzzles today not 0 while playing
actual: all zero for in-progress round started earlier day
errors: none
reproduction: start round day N, resume day N+1
started: always

## Eliminated
- hypothesis: daily reset wipes in-progress state
  evidence: RoundSnapshotStore restore is date-independent; no reset logic touches score

## Evidence
- PersistenceStore.todayTotalScore/WordsFound sum GameRecord (finished only) -> in-progress always 0, even same day
- puzzlesPlayedToday counts RoundStartRecord.date in today -> 0 for carried-over round

## Resolution
root_cause: see above
fix:
verification:
files_changed: []

## Resolution
verified: 2026-11-02 on device (iPhone, Wi-Fi Debug install). Puzzles today shows 1 for an in-progress round carried over from an earlier day; existing save opened fine with the added WordEventRecord model.
tests: full WordPuzzleTests suite passed on iPhone 17 simulator (359 tests, incl. 4 MidnightStatsTests) after `xcodebuild -runFirstLaunch` fixed the CoreSimulator mismatch.
behavior_changes: words found in abandoned rounds now count toward today's score/words; words found before upgrade in an in-progress round are not counted in today's totals.
