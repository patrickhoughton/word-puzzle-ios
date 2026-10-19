# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-10-19 (approved and READY_FOR_SALE; v1.0.1 hotfix submitted the same day)
**Phases:** 12 | **Plans:** 60 | **Sessions:** not tracked

### What Was Built
- Pangram-first puzzle generator over a profanity-filtered ENABLE list: unlimited puzzles with no content pipeline
- SwiftData history, streaks and stats, plus a StoreKit 2 entitlement that's always re-derived from `Transaction.currentEntitlements`
- Hex-flower SwiftUI game with tap/drag input, swipe-down submit, ranks, missed-word reveal, sounds, haptics and Dynamic Type through AX5
- Free tier (3 puzzle starts a day) with a paywall, one-time $2.99 unlock and Restore Purchases
- Pre-launch extras: per-reason rejection feedback, found-words view, sweep bonuses, stats screen, double-tap shuffle, tutorial, inertial flick-to-spin
- An automated store pipeline: XCUITest screenshots, App Store Connect API metadata and submissions, Wi-Fi device installs

### What Worked
- Building the word engine first. Generator changes never rippled into UI work
- Presentation-only views (value in, closures out) with frozen APIs between plans, so parallel plans rarely collided
- Physical-device checkpoints. They caught AX5 truncation, the weak haptic and stats-sheet bugs that Simulator hid
- App Store Connect API automation. v1.0.1 went from version bump to submitted in one sitting

### What Was Inefficient
- The Xcode 26.6 / iOS 26.5 Simulator StoreKit testing bug cost hours. Real sandbox purchases became the authoritative proof
- Parallel worktree executors started from stale branches several times (08-01, 08-02, 09-02)
- gsd-tools `phase complete` / `state` / `milestone complete` wrote wrong counts, dates and accomplishments. Every call needed a manual diff
- The first App Review needed a Guideline 2.1 Information Needed round (normal for new accounts) and a pending-agreements stall, adding about 2 weeks

### Patterns Established
- Single gate funnel (`requestNextRound`) for every "may a new round start?" decision
- Generated, reproducible assets: icon from a Swift script, screenshots from a UI test on a staged DEBUG-only puzzle
- App Store Connect writes go through `scripts/appstoreconnect.py` with exact-match allow rules, and each payload is shown to Patrick before it's sent
- Compliance guards script (no networking API, encryption flag, device family) as a regression check

### Key Lessons
1. Rules that count "starts" need state that survives the app being killed. The abandoned-rounds-count rule was right, but without a saved round every relaunch looked abandoned, and the first real user hit it within a day. Test the kill-and-relaunch path on device before shipping any limit.
2. Treat Simulator as a smoke test only. AX5 layout, haptics, StoreKit and Settings gear visibility all differed on real hardware.
3. Verify every tool's write (gsd-tools, Xcode's scheme editor) against the file on disk, not its return value.
4. New Apple developer accounts should expect an Information Needed round: have a device screen recording and written answers ready before the first submission.

### Cost Observations
- Model mix: not tracked (planning on opus, execution mostly on sonnet per the balanced profile)
- Sessions: not tracked
- Notable: the v1.0.1 hotfix (diagnose → plan → execute → test → device check → submit) took one session

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | — | 12 | Backlog features promoted into the launch milestone; store pipeline automated |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | ~355 Swift Testing + XCTest perf/UI suites | not measured | 12 phases, 0 third-party dependencies |

### Top Lessons (Verified Across Milestones)

1. (Needs a second milestone to cross-validate)
