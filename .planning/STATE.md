---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: verifying
stopped_at: Phase 7 context gathered
last_updated: "2026-10-04T19:13:17.564Z"
last_activity: 2026-10-04
progress:
  total_phases: 15
  completed_phases: 5
  total_plans: 27
  completed_plans: 26
  percent: 96
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-08-27)

**Core value:** Endless, fresh word puzzles that generate algorithmically from a local dictionary — no internet, no content team, no ongoing maintenance.
**Current focus:** Phase 06 — differentiated-invalid-word-messaging

## Current Position

Phase: 07
Plan: Not started
Status: Phase complete — ready for verification
Last activity: 2026-10-04

Progress: [██████████] 96% (24/25 plans across milestone; only 05-08 remains)

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: —
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 01-word-engine-puzzle-generation P02 | 887 | 3 tasks | 7 files |
| Phase 02-persistence-entitlements P02 | 12min | 2 tasks | 3 files |
| Phase 02-persistence-entitlements P03 | 12min | 2 tasks | 4 files |
| Phase 02 P04 | 35min | 2 tasks | 2 files |
| Phase 02 P05 | ~50min | 3 tasks | 4 files |
| Phase 03-core-game-ui P01 | 15min | 3 tasks | 6 files |
| Phase 03-core-game-ui P03 | 25min | 3 tasks | 3 files |
| Phase 03 P02 | 25min | 2 tasks | 5 files |
| Phase 03 P04 | 12min | 2 tasks | 4 files |
| Phase 04 P01 | 8min | 2 tasks | 4 files |
| Phase 04-paywall-free-tier-gate P02 | 15min | 2 tasks | 5 files |
| Phase 04 P03 | 12min | 2 tasks | 4 files |
| Phase 04 P04 | 75min | 2 tasks | 0 files |
| Phase 05 P01 | 20min | 2 tasks | 7 files |
| Phase 05 P02 | 17min | 2 tasks | 3 files |
| Phase 05 P03 | 10min | 3 tasks | 5 files |
| Phase 05 P04 | 7min | 3 tasks | 2 files |
| Phase 05-polish-compliance-app-store P05 | 9min | 2 tasks | 3 files |
| Phase 05-polish-compliance-app-store P06 | ~90min | 3 tasks | 5 files (+ live fixes: sound retune, haptic, AX5 truncation) |
| Phase 05-polish-compliance-app-store P07 | ~60min | 3 tasks | 13 files (automated capture; iPhone + iPad sets) |
| Phase 06 P01 | 15min | 2 tasks | 4 files |
| Phase 06 P02 | 20min | 3 tasks | 2 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: 5-phase structure derived from requirements; word engine first because generator architecture is expensive to change after game logic is built on top of it
- [Phase 01-word-engine-puzzle-generation]: Set<String>.filter returns Set — convert to Array before assigning to Puzzle.validWords ([String])
- [Phase 01-word-engine-puzzle-generation]: @Suite(.serialized) on test suites that load word lists prevents parallel load memory pressure in Simulator
- [Phase 01-word-engine-puzzle-generation]: Simulator target: iPhone 17 (Xcode 26/iOS 26.5 has no iPhone 16 simulator)
- [Phase 02-persistence-entitlements]: PersistenceStore API frozen: makeContainer(inMemory:url:), record(score:wordsFoundCount:date:), puzzlesPlayedToday(now:), totalGamesPlayed(), bestScore(), totalWordsFound() — plans 02-03/02-05 depend on these exact signatures
- [Phase 02-persistence-entitlements]: Daily streak (RET-01) is derived at read time from GameRecord.date over a bounded 400-day window, not stored as a counter, with grace-day semantics (survives one missed day before playing)
- [Phase 02]: EntitlementStore derives isPremium exclusively from Transaction.currentEntitlements (no UserDefaults/@AppStorage flag), with purchaseUnlimited() and restore() via AppStore.sync() forming the frozen API for Phase 4's paywall
- [Phase 02-05]: Transaction.currentEntitlements is scoped to the signed-in sandbox/production Apple ID account, not local device state — a fresh reinstall on an account with a prior purchase shows isPremium=true immediately, before Restore is tapped. This is correct MON-04 behavior, not a bug; relevant for Phase 4 paywall design/QA.
- [Phase 02-05]: Reset the WordPuzzle.xcscheme Run StoreKit Configuration back to WordPuzzle.storekit after the manual sandbox test (it was set to None for that test per the plan's Step B) so Phase 3/4 local dev is not left pointed at the real sandbox.
- [Phase 03-01]: GameViewModel submission validation mirrors PuzzleGenerator's private isValidPuzzleWord rule exactly (length >= 4, contains center, subset of letters) plus dictionary and duplicate checks, so the UI never rejects a word the generator counted as valid.
- [Phase 03-01]: finishRound() records the session via PersistenceStore BEFORE flipping roundPhase to .roundOver, so the missed-words screen always renders against already-persisted data.
- [Phase 03-01]: GameTheme.swift is the single source of spacing/typography/color/geometry/motion tokens for all Phase 3 views — no inline magic numbers. GameViewModel, RankTier, and GameTheme's API is now frozen for plans 03-02/03-03/03-04.
- [Phase 03-03]: Presentation views (WordDisplayView, ScoreBarView, MissedWordsView) built with zero GameViewModel coupling — value/closure contracts only, verified via grep gates; counter-based .sensoryFeedback triggers (not Bool) so consecutive identical outcomes still fire haptics
- [Phase 03-02]: LetterGridView uses a single unified DragGesture(minimumDistance: 0) for both tap and drag-to-connect input, with HexFlowerLayout's trigonometry extracted into a stateless enum for unit testability
- [Phase 03-04]: wordList @State declared without a default value (assigned only in init, same pattern as gameViewModel) to avoid constructing two WordList instances -- the plan's own example code textually built WordList() twice
- [Phase 03-04]: AppWiringTests suite marked @Suite(.serialized) since the new launch-path test loads the full ENABLE word list, matching the project convention for word-list-loading test suites
- [Phase 04]: puzzlesPlayedToday() now counts started rounds (RoundStartRecord) not finished rounds (GameRecord) -- the daily free-tier limit and lifetime stats are two structurally different counters (D-02)
- [Phase 04]: todayTotalScore/todayTotalWordsFound/nextResetDate share a single todayBounds() day-boundary helper so the paywall countdown can never diverge from the daily-limit reset (D-06/D-07)
- [Phase 04-paywall-free-tier-gate]: requestNextRound(isPremium:) is the ONLY place that decides whether a new round may begin -- both the post-finish Next Puzzle trigger and the launch-time gate check funnel through it
- [Phase 04-paywall-free-tier-gate]: recordRoundStarted() called as the FIRST statement inside startNewRound(with:), so an abandoned round still consumes a free puzzle without over-recording on wordList.isLoaded bail-outs
- [Phase 04-paywall-free-tier-gate]: WordPuzzleApp's two separate launch .task modifiers merged into one sequenced task to eliminate a race that could paywall a premium user before entitlement refresh completed
- [Phase 04-paywall-free-tier-gate]: [04-02 Rule 3] GameView.swift's RoundPhase switch needed a minimal .paywalled placeholder (EmptyView) to keep the build compiling after the new enum case was added -- the real paywall screen remains plan 04-03 scope
- [Phase 04-paywall-free-tier-gate]: PaywallView is presentation-only (value-in/closure-out, zero @Environment) rendering the frozen D-05..D-09 contract; GameView's fullScreenCover branches content on roundPhase (.paywalled vs .roundOver) rather than using two separate covers
- [Phase 04-paywall-free-tier-gate]: MissedWordsView onContinue now routes through requestNextRound(isPremium:) instead of the ungated startNewRound() -- closes the bypass RESEARCH Pitfall 5 warned about
- [Phase 04-paywall-free-tier-gate]: Local Simulator .storekit purchase testing (steps 15-17) is unreliable on this dev machine -- same class of Xcode 26.6/iOS 26.5 StoreKit-testing bug as the Phase 2 02-04 blocker, not a code defect. — Deferred to Task 2's real sandbox purchase as authoritative proof, per the established 02-05 precedent.
- [Phase 04-paywall-free-tier-gate]: Restore Purchases negative-case error string verified only via a freshly created never-purchased sandbox tester -- App Store Connect 'Clear Purchase History' plus device sign-out/sign-in on an already-owning tester did not reliably reproduce it. — Apple's sandbox purchase-history-clear propagation is unreliable/delayed; a fresh tester sidesteps it entirely.
- [Phase 04-paywall-free-tier-gate]: WordPuzzle.xcscheme's Run-action StoreKitConfigurationFileReference was manually corrected from a broken '../../WordPuzzle/WordPuzzle.storekit' path (written by Xcode's own Edit Scheme UI when restoring the config after Task 2's real-sandbox test) back to the working '../../../WordPuzzle/WordPuzzle.storekit' path. — Xcode's Edit Scheme dialog wrote a path one directory level short of the actual file location; flagging in case Xcode does this again on a future manual StoreKit Configuration change via its UI.
- [Phase 05]: [Phase 05-01] Used Kenney Interface Sounds pack (not UI Audio) -- confirmation_*/error_*/maximize_* clip families map directly onto the four D-01 sound events; both packs are CC0 so this satisfies D-02
- [Phase 05]: [Phase 05-01] SoundManager.sessionCategory is fixed at .ambient (never .playback) per RESEARCH Pitfall 3, so SFX respect the hardware silent switch
- [Phase 05]: [Phase 05-02]: GameTheme's four font tokens keep their original names but now resolve to Dynamic Type text styles (largeTitle/title3/body/footnote); HexTileView's letter is the sole sanctioned fixed-point Font.system(size:) usage, clamped to 40pt via HexTileView.clampedLetterSize(scaled:) so the 70pt hexagon never overflows at AX1-AX5 sizes
- [Phase 05]: D-08: Patrick chose app icon Concept A (single gold hexagon, bold black 'W') over Concept B (honeycomb cluster), no refinements -- A stays legible at 40x40 and in the tinted monochrome slot where B collapses into an indistinct dot cluster
- [Phase 05]: App icon is generated via scripts/GenerateAppIcon.swift (SwiftUI ImageRenderer + alpha-flattening), never hand-painted -- PNGs are reproducible outputs, the script is the source of truth
- [Phase 05-04]: device-family-keep-ipad: Patrick chose to keep TARGETED_DEVICE_FAMILY = "1,2" (iPhone + iPad), accepting that plan 05-07 must add a 13" iPad screenshot set and plan 05-06 must add an iPad layout smoke test
- [Phase 05-04]: Encryption export compliance declared: INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO added to both app-target build configs; app makes zero network calls so uses no encryption
- [Phase 05-polish-compliance-app-store]: [Phase 05-05]: Sound preference lives in exactly one place -- GameView's @AppStorage(SoundManager.soundEffectsEnabledKey) -- bound into SettingsView and read by three onChange handlers; all four D-01 sound events route through SoundEffect.forSubmission/forRoundPhase, never a duplicated inline mapping
- [Phase 05-polish-compliance-app-store]: [Phase 05-05]: The launch-time round_end sound firing on the .loading -> .paywalled cold-launch path (free user already at daily limit) is intentional D-01 behavior, not a bug -- left for plan 05-06's manual device pass to evaluate
- [Phase 05-06]: word_rejected.wav retuned live during QA (Patrick's request, not a plan task): error_008 -> error_003 -> final error_004 @ -9dB gain, auditioned against the full Kenney error_* family. Rejected-word haptic upgraded from single .sensoryFeedback(.error) to a manual double-hit UIImpactFeedbackGenerator(.heavy) burst -- a single .impact(weight: .heavy, intensity: 1.0) shot was confirmed too weak on physical hardware.
- [Phase 05-06]: AX5 text truncation ("Novi...", "0 of 7...", "Tap or drag...", "F...") was a real bug caught only on a physical device (Simulator's wider logical screen masked it). Fixed via shrink-to-fit (lineLimit(1) + minimumScaleFactor) in ScoreBarView and WordDisplayView, plus GameView's controlRow splitting Finish Round onto its own row ONLY at dynamicTypeSize.isAccessibilitySize. A ScrollView-based fix was explicitly considered and rejected due to gesture-conflict risk with LetterGridView/WordDisplayView's DragGesture usage.

- [Phase 05-07]: App Store screenshots are captured by XCUITest (AppStoreScreenshotTests via scripts/capture-app-store-screenshots.sh), not by hand -- Patrick asked Claude to drive capture. Every round is pinned to HARMONY/center R through a DEBUG-only -ScreenshotPuzzle launch argument (verified absent from the Release binary) after a random puzzle surfaced SEXI/sexes/sexing on screen.
- [Phase 05-07]: Xcode 27.0 replaced Simulator.app with DeviceHub.app (Xcode.app/Contents/Applications/DeviceHub.app); `simctl status_bar --time` now only accepts a plain string like "9:41".

- [Phase 05-08]: Patrick decided (2026-10-04) to BUILD BACKLOG ITEMS 999.1-999.8 INTO v1.0 before submitting -- v1.0 submission is on hold. 05-08 metadata partly pushed via API (subtitle, categories, description, keywords, promo text, MANUAL release, age rating); build 1.0 (1) uploaded. Screenshots get re-captured/uploaded after the backlog lands. Device testing uses direct Wi-Fi installs: `bash scripts/install-on-device.sh`.

- [Backlog review 2026-10-04]: Promoted 999.3->Phase 6, 999.2->7, 999.8->8, 999.1->9, 999.6->10, 999.7->11, 999.4->12 (tutorial last so it teaches everything). 999.9/999.10/999.11 stay in backlog. gsd-tools `phase add` would have numbered new phases 1000+ (its regex treats "Phase 999.x" headers as the max phase), so promotion was done by hand -- use `phase insert` or manual edits for future promotions.

### Pending Todos

None yet.

### Blockers/Concerns

- 02-04: EntitlementStoreTests — 3/5 tests (purchase/restore/clear) fail on this dev machine with SKInternalErrorDomain Code=3 / "notEntitled". Developer Mode was enabled and the Mac was fully rebooted; failures persist identically (CLI and Xcode GUI, both against Simulator). Root cause unresolved — likely an Xcode 26.6/iOS 26.5 Simulator SKTestSession bug, not a code defect (physical-device run gets further with a different error). Deferred to plan 02-05's real sandbox purchase test as the authoritative MON-02/MON-03 proof. See 02-04-SUMMARY.md Issues Encountered for full diagnosis.
- gsd-tools 'phase complete' and 'roadmap update-plan-progress' checkbox/table regexes expect 'Phase 04' but ROADMAP.md headers use non-padded 'Phase 4' -- silently failed to update the top checklist line and Progress table row for Phase 4 (worked for Phases 2/3 previously, likely because those were invoked with non-padded phase numbers). Manually fixed for Phase 4; future phase completions should verify the checklist/table actually updated, not just trust the tool's roadmap_updated:true return value.
- 05-02: `state update-progress` and `state record-metric` both write `percent: 100` and `status: completed` into STATE.md frontmatter regardless of the actual completed/total ratio (their own JSON output correctly reported 72%/18 of 25, but the file write used a stale/hardcoded 100). Manually corrected frontmatter to `percent: 72` / `status: executing` after each call in this session; future plan executions in this phase should verify frontmatter percent/status after running these commands rather than trusting them.
- 05-02: This worktree's git branch (`worktree-agent-a14f6787ea2461fe8`) was found stale at session start — zero unique commits, sitting at the exact merge-base with `main`, missing all of Phase 4's implementation and all Phase 5 planning docs (including this plan's own PLAN.md). Fixed via `git merge --ff-only main` (verified safe via `git merge-base` showing no divergence) before any work began. Other parallel worktree agents executing sibling 05-XX plans may have hit the same staleness.
- 05-04: device-family-keep-ipad decision (Patrick chose to keep TARGETED_DEVICE_FAMILY = "1,2") adds scope not currently in any Phase 5 plan: plan 05-07 (Screenshots) was originally scoped iPhone-only and now needs an added 13" iPad (2064x2752) screenshot set; plan 05-06 (Manual QA) was originally scoped iPhone-only and now needs an iPad layout smoke test (the fixed 70pt hex geometry has never been validated at iPad width). Flagging before Wave 3 executes so this is visible scope drift, not a silent gap.
- 05-06: GameView's Settings gear button (`Image(systemName: "gearshape")`) does not render at all in the iPhone 17 Simulator — confirmed absent both before and after a full uninstall/reinstall, at default AND AX5 text sizes — but renders correctly on a physical iPhone 15 Pro. Root cause not investigated further once the physical-device render was confirmed; likely another Xcode 26.6/iOS 26.5 Simulator quirk in the same family as the 02-04 StoreKit bug, not a code defect. Relevant for any future Simulator-only QA pass on this screen — use a physical device to confirm gear visibility, not just the Simulator.
- 05-06: iPhone 17 Simulator's logical screen width (~402pt) is wider than a real iPhone 15 Pro (~393pt) — an AX5 Dynamic Type check that passes cleanly in Simulator can still truncate text on a real device. Caught GameView/ScoreBarView/WordDisplayView truncation this way (see 05-06-MANUAL-QA.md and commit 8ee88d6); any future AX5 layout check should be verified on a physical device, not just Simulator, before marking it a pass.

## Session Continuity

Last session: 2026-10-04T19:13:17.561Z
Stopped at: Phase 7 context gathered
Resume file: .planning/phases/07-found-words-view/07-CONTEXT.md
