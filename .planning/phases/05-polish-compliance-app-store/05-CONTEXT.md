# Phase 5: Polish, Compliance & App Store - Context

**Gathered:** 2026-09-07
**Status:** Ready for planning

<domain>
## Phase Boundary

The app passes App Review on first submission: fully offline, supports Dynamic Type, has a completed privacy label, and has App Store metadata (icon, screenshots, keywords) that accurately represents the product. Covers UX-01 (offline), UX-02 (sound toggle), UX-03 (Dynamic Type), UX-04 (icon/screenshots), UX-05 (privacy label). No new gameplay capabilities — this phase is polish and store-readiness, not features.

</domain>

<decisions>
## Implementation Decisions

### Sound Effects (UX-02)
- **D-01:** Sound effects fire on four events: word accepted, word rejected, pangram found (distinct/bigger than a normal accept), and round end / paywall shown.
- **D-02:** Audio files come from a free/royalty-free SFX library (e.g. Freesound, Kenney UI SFX pack) — no custom recording or commissioning. Pick short, clean sounds and bundle them as app assets.
- **D-03:** Settings screen scope is minimal: a single sound-effects on/off toggle only (the literal UX-02 requirement). Do not fold in a haptics toggle or the backlogged Phase 999.1 stats screen — those stay separate, deferred items.
- **Claude's Discretion:** Where the settings screen is entered from (e.g. a gear icon in GameView's top bar) — no specific UI entry point was locked by the user.

### Dynamic Type (UX-03)
- **D-04:** Migrate GameTheme.swift's fixed-point fonts (`Font.system(size: 34, weight: .semibold)` etc.) to relative/scalable text styles so all UI chrome (score bar, buttons, WordDisplayView, MissedWordsView, PaywallView, the new settings screen) genuinely scales with the system Dynamic Type setting. This touches every Phase 3/4 view that currently reads `GameTheme` fonts.
- **D-05:** Exception: the honeycomb letter tiles (`HexTileView`, fixed 70pt hex geometry via `HexFlowerLayout`) do NOT scale their hex size with Dynamic Type. Cap/clamp the letter text size inside each tile to a safe maximum so tiles never clip or overflow their fixed hexagon shape, even at the largest accessibility text sizes. The hex grid's fixed geometry (`HexFlowerLayout`'s trigonometry) is not reworked in this phase.

### Analytics Scope
- **D-06:** TelemetryDeck (picked in CLAUDE.md's tech stack) is explicitly deferred to v2 — do NOT integrate it in this phase. v1 ships with zero analytics/telemetry of any kind.
- **D-07:** This simplifies UX-05: the privacy nutrition label should declare "Data Not Collected" across all categories, since the app collects nothing (no analytics SDK, no accounts, no network calls).

### App Icon & Screenshots (UX-04)
- **D-08:** Claude drafts app icon concept(s) first — using the existing honeycomb + letter motif and the #F5B800 gold accent color already established in `GameTheme`/`Assets.xcassets/AccentColor` — for Patrick to react to and refine, before producing final 1024x1024 assets for the three required `AppIcon.appiconset` slots (universal/dark/tinted — all currently empty).
- **D-09:** App Store screenshots are captioned marketing screenshots: real Simulator gameplay captures overlaid with short marketing copy (e.g. value-prop taglines) and device frames — not plain uncaptioned screenshots. Covers gameplay, paywall, and any other screens worth showing.

### Claude's Discretion
- Settings screen UI entry point/navigation.
- Exact SFX library source and specific sound file selection (within "free/royalty-free" constraint).
- Specific relative text style mapping per GameTheme font token (e.g. which maps to `.title`, `.headline`, etc.) and the exact clamp value/mechanism for hex tile letter scaling.
- Icon concept directions to draft before presenting to Patrick.
- Screenshot marketing copy wording and which screens to feature.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design tokens & existing UI
- `WordPuzzle/WordPuzzle/Game/GameTheme.swift` — current fixed-point font/spacing/color tokens; D-04/D-05 require modifying this file's font definitions
- `.planning/phases/03-core-game-ui/03-UI-SPEC.md` — original design contract GameTheme was built from; check before changing font tokens so spacing/hierarchy intent isn't lost

### App Store / compliance
- CLAUDE.md "App Store Connect — What to Know for First Submission" section — privacy label guidance, common rejection triggers, `App Uses Non-Exempt Encryption` = NO
- `.planning/REQUIREMENTS.md` — UX-01 through UX-05 acceptance criteria

No other external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Color.accentColor` / `Assets.xcassets/AccentColor` — #F5B800 gold, already the app's brand color; reuse in icon design
- `GameTheme` enum — single source of truth for spacing/typography/color; Dynamic Type migration happens here, not scattered across views

### Established Patterns
- Presentation views (`WordDisplayView`, `ScoreBarView`, `MissedWordsView`, `PaywallView`) are value-in/closure-out with zero `@Environment`/ViewModel coupling — a new settings screen and any Dynamic-Type-driven view changes should follow this same pattern
- `@AppStorage` is the established pattern for simple persisted flags (daily count, puzzle seed) — the sound-toggle preference should follow this same convention rather than SwiftData

### Integration Points
- `AppIcon.appiconset/Contents.json` already defines the 3 required appearance slots (universal/dark/tinted) at 1024x1024 but contains zero actual image files — icon work fills these in, no new slots needed
- No `Info.plist` file exists on disk — this project uses Xcode's `GENERATE_INFOPLIST_FILE = YES` build setting; any Info.plist-level changes (e.g. encryption export compliance) go through `INFOPLIST_KEY_*` build settings in `project.pbxproj`, not a physical plist file
- No settings screen, SoundManager, or audio assets exist yet — all greenfield for this phase

</code_context>

<specifics>
## Specific Ideas

No specific icon concept or exact sound selections were specified — Claude has discretion to draft options per D-08 and D-02, for Patrick to react to during planning/execution.

</specifics>

<deferred>
## Deferred Ideas

- Haptics on/off toggle — considered as an addition to the new settings screen, deferred: settings screen scope stays minimal (sound toggle only, D-03)
- Folding Phase 999.1 (player stats screen) into this phase's settings screen — considered, deferred: kept as a separate backlog item, not part of Phase 5
- TelemetryDeck analytics integration — deferred to v2 (D-06)
- Hex tile geometry scaling with Dynamic Type (letting tiles themselves grow, not just clamping letter text) — considered, deferred as more invasive than needed; D-05 covers the simpler clamp approach instead

### Reviewed Todos (not folded)
None — `todo match-phase 5` returned zero matches.

</deferred>

---

*Phase: 05-polish-compliance-app-store*
*Context gathered: 2026-09-07*
