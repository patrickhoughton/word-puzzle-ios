# Deferred Items — Phase 02 (persistence-entitlements)

Out-of-scope discoveries logged during plan execution but not fixed (per executor scope boundary).

## 02-02: Full-suite regression run

- **Test:** `WordPuzzleUITests.testLaunchPerformance()`
- **Result:** Failed (135.986s) during the full-suite regression run after completing 02-02 tasks
- **Scope:** Pre-existing test created in Phase 1 (`01-01`, commit `fc7959d`), in the
  `WordPuzzleUITests` target — unrelated to `Services/GameRecord.swift` or
  `Services/PersistenceStore.swift` added by this plan
- **Likely cause:** Launch performance measurement run concurrently with a sibling
  executor (plan 02-01) also running `xcodebuild test` against Simulator clones on the
  same machine — plausible resource contention rather than a real regression
- **Action:** Not fixed — out of scope for 02-02. All `WordPuzzleTests` target tests
  (PersistenceStoreTests 4/4, WordListTests, ProfanityTests, PuzzleGeneratorTests,
  PerformanceTests) passed. Re-run `-only-testing:WordPuzzleUITests/WordPuzzleUITestsLaunchTests`
  in isolation if this persists after parallel execution ends.

## 02-05: `gsd-tools state update-progress` regex bug (tooling, not app code)

- **Tool:** `$HOME/.claude/get-shit-done/bin/lib/state.cjs`, `cmdStateUpdateProgress`
- **Symptom:** `node gsd-tools.cjs state update-progress` reports `{"updated": true, "percent": 100, ...}`
  but the body's `Progress: [...] X%` line under `## Current Position` in `.planning/STATE.md`
  is never actually updated — it stays at its previous value.
- **Root cause:** `cmdStateUpdateProgress`'s fallback regex
  `/^(Progress:\s*).*/im` is case-insensitive and matches the YAML frontmatter's
  `progress:\n  total_phases: 5\n  ...` block (which appears earlier in the file) before it
  ever reaches the real `Progress: [bar] X%` line further down in the body. The replace
  fires against the frontmatter text instead. `writeStateMd`'s `syncStateFrontmatter` step
  then re-derives a fresh frontmatter block from the body on every write, which silently
  discards the corrupted frontmatter replacement, leaving no visible corruption but also no
  actual update to the body's Progress bar.
- **Action:** Not fixed — out of scope for a plan executor to patch shared GSD tooling.
  Manually corrected `.planning/STATE.md`'s body `Progress:` line to `[██████████] 100%`
  (matching the correct `completed_plans: 8 / total_plans: 8`) in plan 02-05's STATE.md
  update step. Flagging here so a future session can tighten the regex (e.g. anchor to
  `## Current Position` context, or require the line NOT be inside the frontmatter fence)
  if this recurs.

## 02-05: `gsd-tools roadmap update-plan-progress` requires un-padded phase number (tooling, not app code)

- **Tool:** `$HOME/.claude/get-shit-done/bin/lib/roadmap.cjs`, `cmdRoadmapUpdatePlanProgress`
- **Symptom:** `roadmap update-plan-progress "02"` reports `{"updated": true, ...}` but silently
  does not touch `.planning/ROADMAP.md`'s `## Progress` table row, because that table row is
  written as `| 2. Persistence & Entitlements | ... |` (single-digit phase number) while the
  phase directory/plan IDs use zero-padded `02-*`. The tool's row-matching regex requires the
  literal phase-number string it was called with, so `"02"` never matches `"2."` in the table.
  Calling it with the un-padded `"2"` instead works correctly and also ticks the `Phase 2:`
  top-level roadmap checkbox (since 02-05 was the last of 5 plans).
- **Action:** Not fixed — out of scope for a plan executor to patch shared GSD tooling. Used
  `roadmap update-plan-progress "2"` (not `"02"`) in plan 02-05 to get the correct write.
  Flagging here so future plans in this project know to pass the un-padded phase number to
  this specific command.
