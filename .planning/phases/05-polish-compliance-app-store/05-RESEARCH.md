# Phase 5: Polish, Compliance & App Store - Research

**Researched:** 2026-09-07
**Domain:** iOS Dynamic Type migration, AVFoundation sound effects, StoreKit 2 offline behavior, App Store Connect privacy/compliance, app icon & screenshot production
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Sound Effects (UX-02)**
- D-01: Sound effects fire on four events: word accepted, word rejected, pangram found (distinct/bigger than a normal accept), and round end / paywall shown.
- D-02: Audio files come from a free/royalty-free SFX library (e.g. Freesound, Kenney UI SFX pack) — no custom recording or commissioning. Pick short, clean sounds and bundle them as app assets.
- D-03: Settings screen scope is minimal: a single sound-effects on/off toggle only (the literal UX-02 requirement). Do not fold in a haptics toggle or the backlogged Phase 999.1 stats screen — those stay separate, deferred items.

**Dynamic Type (UX-03)**
- D-04: Migrate GameTheme.swift's fixed-point fonts (`Font.system(size: 34, weight: .semibold)` etc.) to relative/scalable text styles so all UI chrome (score bar, buttons, WordDisplayView, MissedWordsView, PaywallView, the new settings screen) genuinely scales with the system Dynamic Type setting. This touches every Phase 3/4 view that currently reads `GameTheme` fonts.
- D-05: Exception: the honeycomb letter tiles (`HexTileView`, fixed 70pt hex geometry via `HexFlowerLayout`) do NOT scale their hex size with Dynamic Type. Cap/clamp the letter text size inside each tile to a safe maximum so tiles never clip or overflow their fixed hexagon shape, even at the largest accessibility text sizes. The hex grid's fixed geometry (`HexFlowerLayout`'s trigonometry) is not reworked in this phase.

**Analytics Scope**
- D-06: TelemetryDeck (picked in CLAUDE.md's tech stack) is explicitly deferred to v2 — do NOT integrate it in this phase. v1 ships with zero analytics/telemetry of any kind.
- D-07: This simplifies UX-05: the privacy nutrition label should declare "Data Not Collected" across all categories, since the app collects nothing (no analytics SDK, no accounts, no network calls).

**App Icon & Screenshots (UX-04)**
- D-08: Claude drafts app icon concept(s) first — using the existing honeycomb + letter motif and the #F5B800 gold accent color already established in `GameTheme`/`Assets.xcassets/AccentColor` — for Patrick to react to and refine, before producing final 1024x1024 assets for the three required `AppIcon.appiconset` slots (universal/dark/tinted — all currently empty).
- D-09: App Store screenshots are captioned marketing screenshots: real Simulator gameplay captures overlaid with short marketing copy (e.g. value-prop taglines) and device frames — not plain uncaptioned screenshots. Covers gameplay, paywall, and any other screens worth showing.

### Claude's Discretion
- Settings screen UI entry point/navigation.
- Exact SFX library source and specific sound file selection (within "free/royalty-free" constraint).
- Specific relative text style mapping per GameTheme font token (e.g. which maps to `.title`, `.headline`, etc.) and the exact clamp value/mechanism for hex tile letter scaling.
- Icon concept directions to draft before presenting to Patrick.
- Screenshot marketing copy wording and which screens to feature.

### Deferred Ideas (OUT OF SCOPE)
- Haptics on/off toggle — deferred; settings screen scope stays minimal (sound toggle only, D-03).
- Folding Phase 999.1 (player stats screen) into this phase's settings screen — deferred, stays a separate backlog item.
- TelemetryDeck analytics integration — deferred to v2 (D-06).
- Hex tile geometry scaling with Dynamic Type (letting tiles themselves grow) — deferred as more invasive than needed; D-05's clamp approach is used instead.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-01 | All game features work fully offline | See "StoreKit 2 & Offline Behavior" — confirms no code in the app makes network calls; documents the one StoreKit caching caveat that affects *testing*, not shipped behavior |
| UX-02 | User can toggle sound effects on/off in a settings screen | See "SoundManager Pattern" and "Don't Hand-Roll" — AVAudioPlayer pool design, `@AppStorage` toggle, `.ambient` session category, settings screen pattern matching existing presentation-view convention |
| UX-03 | App supports Dynamic Type — all text scales correctly | See "Dynamic Type Migration" — GameTheme font-token-to-text-style mapping table, `@ScaledMetric` clamp technique for `HexTileView`, HIG point-size reference |
| UX-04 | Polished custom icon and App Store screenshots | See "App Icon Production" and "Screenshot Production" — 3-slot `AppIcon.appiconset` workflow (`ImageRenderer` / Icon Composer options), mandatory screenshot sizes, `xcrun simctl` capture + framing options |
| UX-05 | Privacy nutrition label is complete and accurate | See "Privacy Nutrition Label & Encryption Compliance" — "Data Not Collected" declaration mechanics, `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` build-setting-only approach for this project's plist-less setup |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **No third-party IAP/analytics SDKs this phase** — TelemetryDeck is in the tech stack but explicitly deferred (D-06); do not add any SDK dependency in Phase 5.
- **StoreKit 2 native only** — no RevenueCat/Adapty.
- **MVVM + `@Observable`** — any new service (e.g. a SoundManager) should follow the existing `@Observable final class` convention used by `WordList`/`EntitlementStore`/`PersistenceStore`, OR be a simple non-Observable struct/enum if it has no observable state (see Architecture Patterns below — sound-on/off state is better modeled as `@AppStorage` directly, not a duplicated Observable flag).
- **Presentation views are value-in/closure-out, zero `@Environment` coupling** — the new settings screen must follow this pattern, matching `WordDisplayView`/`ScoreBarView`/`MissedWordsView`/`PaywallView`.
- **`@AppStorage`/`GameTheme` conventions** — `GameTheme` remains the single source of spacing/typography/color/geometry tokens; simple persisted flags use `@AppStorage`, not SwiftData (SwiftData is reserved for queryable game history/stats per the Phase 2 decision).
- **No `List`** — use `ScrollView` + `LazyVStack` for any new scrollable list content (settings screen won't need one, but this applies if any list-like UI is added).
- **Explicit App Store Connect guidance already in CLAUDE.md**: declare TelemetryDeck's Device ID if it were active (it's not, this phase — declare "Not Collected" everywhere instead), require a visible "Restore Purchases" button (already shipped in Phase 4), set `App Uses Non-Exempt Encryption` = `NO`, uncheck Mac/Vision Pro availability unless tested there, submit for Manual Release.
- **No `URLSession`/network calls anywhere in the app** — already true; UX-01 work is about *verifying* this, not building new offline-handling code.

## Summary

Phase 5 is four largely independent workstreams gated by App Review, not by each other: (1) a Dynamic Type migration of `GameTheme.swift`'s four fixed-point font tokens to scalable text styles, with a `@ScaledMetric`-based clamp inside the fixed-geometry `HexTileView`; (2) a small `SoundManager` built on `AVAudioPlayer` with a `.ambient` audio session (so it respects the hardware silent switch, matching player expectation for a casual word game) gated by a single `@AppStorage` boolean, wired to a new minimal settings screen; (3) verification (not new code) that the app has zero network dependencies — `Transaction.currentEntitlements` and `AppStore.sync()` are the only StoreKit calls in the codebase and both work from StoreKit's local transaction cache once a device has synced once, so real Airplane Mode testing is the correct verification method, not code changes; (4) App Store Connect / build-setting work — a "Data Not Collected" privacy label (true zero-collection app), setting `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` as a build setting (no physical Info.plist exists), and producing three 1024×1024 app icon variants plus captioned, device-framed screenshots for the mandatory 6.9" iPhone size.

The codebase already funnels 100% of font usage through `GameTheme`'s four tokens (`displayFont`/`headingFont`/`bodyFont`/`labelFont`) across exactly 6 view files — confirmed by grep, no `Font.system(size:)` literals exist outside `GameTheme.swift`. This means the Dynamic Type migration is a single-file token change plus one `HexTileView` clamp change, not a scattered per-view rewrite.

**Primary recommendation:** Map each `GameTheme` font token to the nearest built-in Dynamic Type text style with a `.fontWeight()` override where the weight differs from the system default (table below), clamp `HexTileView`'s letter size with a bounded `@ScaledMetric`, build `SoundManager` as an `@Observable`-free enum/struct wrapping a small pool of preloaded `AVAudioPlayer`s reading an `@AppStorage("soundEffectsEnabled")` flag, verify offline behavior with a real device in Airplane Mode (not just Simulator), and set the encryption-compliance build setting directly in `project.pbxproj` since this project has no physical `Info.plist`.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI Dynamic Type (`Font` text styles, `@ScaledMetric`) | iOS 17+ (built-in) | Scalable typography | Apple's native mechanism; zero dependencies; already the only path CLAUDE.md sanctions |
| AVFoundation (`AVAudioPlayer`, `AVAudioSession`) | iOS 17+ (built-in) | Short SFX playback | Standard, lightweight choice for < 5 short one-shot sounds in a casual game; no need for AVAudioEngine's mixing graph complexity |
| `@AppStorage` | iOS 17+ (built-in) | Persist sound-toggle preference | Matches existing project convention (daily count / seed use `@AppStorage`); explicitly preferred over SwiftData for simple flags per CLAUDE.md |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kenney UI Audio pack (CC0) | current (kenney.nl/assets/ui-audio) | Source SFX for accept/reject/pangram/round-end | Free, no-attribution-required, game-ready UI clicks; satisfies D-02's royalty-free constraint cleanly |
| `xcrun simctl io booted screenshot` | Xcode 26.6 (installed) | Raw Simulator screenshot capture | Free, built-in; no external tool needed for capture step |
| SwiftUI `ImageRenderer` | iOS 16+ (built-in) | Render an icon-concept SwiftUI view to a 1024×1024 PNG | Lets Claude draft icon concepts in code (matching the existing honeycomb/gold motif) without a design tool, per D-08 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual per-view font mapping | Custom `Font` extension wrapping `UIFontMetrics` | More flexible for non-standard sizes, but adds indirection for zero benefit here — the 4 existing sizes (34/20/17/13) already sit almost exactly on Apple's `.largeTitle`/`.title3`/`.body`/`.footnote` point sizes at the default category (see mapping table) |
| `fastlane frameit` for screenshot framing | Manual compositing (Keynote/Figma/Preview) or a lightweight screenshot tool | `fastlane` is **not installed** on this machine (verified) and requires Ruby/gem setup; for 3-5 screenshots, manual framing in Keynote/Figma is faster to set up for a solo dev with no existing fastlane lane. Install fastlane only if iterating on screenshots repeatedly across locales. |
| Icon Composer (.icon file, Xcode 26 Liquid Glass icons) | Traditional 3-PNG `AppIcon.appiconset` (universal/dark/tinted) | The project's `Contents.json` is **already scaffolded** for the traditional 3-slot format (confirmed on disk), not the new single-.icon-file format — stick with the existing scaffold rather than migrating the asset catalog structure mid-phase |

**Installation:** No new package dependencies — everything above is either an Apple framework or a downloaded asset (SFX files, icon PNGs), not an SPM/CocoaPods package.

**Version verification:** N/A — no npm/SPM packages to pin. Confirmed locally: Xcode 26.6 (Build 17F113), macOS 26.6.2, deployment target iOS 17.6 (`IPHONEOS_DEPLOYMENT_TARGET = 17.6` in the app target's build settings).

## Architecture Patterns

### Recommended Project Structure
```
WordPuzzle/WordPuzzle/
├── Game/
│   ├── GameTheme.swift          # MODIFIED: font tokens become scalable text styles
│   └── Views/
│       ├── HexTileView.swift    # MODIFIED: clamped @ScaledMetric letter size
│       └── ...                  # unchanged structurally; fonts auto-scale via GameTheme
├── Settings/                    # NEW group, mirrors Game/ convention
│   ├── SoundManager.swift       # NEW: AVAudioPlayer pool + @AppStorage-gated play()
│   └── Views/
│       └── SettingsView.swift   # NEW: value-in/closure-out, single toggle
└── Assets.xcassets/
    ├── AppIcon.appiconset/      # 3 PNGs filled in (universal/dark/tinted)
    └── Sounds/ (or bundled resources) # NEW: 4 short SFX files
```

### Pattern 1: GameTheme Font Token → Text Style Migration
**What:** Replace `Font.system(size: N, weight: W)` literals with `Font.<textStyle>` (optionally `.fontWeight()`-overridden), so fonts scale via `UIFontMetrics` under the hood automatically.
**When to use:** All four `GameTheme` font tokens; no per-view changes needed since every view already reads through `GameTheme`.
**Mapping (HIG default/"Large" category point sizes vs. existing GameTheme sizes):**

| GameTheme token | Current (fixed) | Nearest text style (default size) | Recommended replacement |
|---|---|---|---|
| `displayFont` | 34pt, semibold | `.largeTitle` = 34pt (regular by default) | `Font.largeTitle.weight(.semibold)` |
| `headingFont` | 20pt, semibold | `.title3` = 20pt (regular by default) | `Font.title3.weight(.semibold)` |
| `bodyFont` | 17pt, regular | `.body` = 17pt (regular) | `Font.body` (exact match, no override needed) |
| `labelFont` | 13pt, regular | `.footnote` = 13pt (regular) | `Font.footnote` (exact match, no override needed) |

All four token point sizes coincide exactly with Apple's default-category text-style sizes — confirmed against HIG typography reference (34/28/22/20/17/17/16/15/13/12/11 for largeTitle/title/title2/title3/headline/body/callout/subhead/footnote/caption/caption2). This is not a coincidence to rely on for anything beyond the default category — the whole point of migrating is that these values now change together as the user's Dynamic Type setting changes; the "exact match at default size" fact just confirms the migration preserves the current visual hierarchy at the default setting.

**Example:**
```swift
// Source: Apple HIG typography (developer.apple.com/design/human-interface-guidelines/typography)
// GameTheme.swift, after migration:
static let displayFont = Font.largeTitle.weight(.semibold)
static let headingFont = Font.title3.weight(.semibold)
static let bodyFont = Font.body
static let labelFont = Font.footnote
```
No call sites in `WordDisplayView`, `ScoreBarView`, `MissedWordsView`, `PaywallView`, `GameView`, or the new `SettingsView` need to change — they already reference `GameTheme.displayFont` etc. by name.

### Pattern 2: Clamped `@ScaledMetric` for Fixed-Geometry Hex Tiles (D-05)
**What:** `HexTileView`'s letter must grow *slightly* with Dynamic Type for legibility, but never past a size that clips the fixed 70pt hexagon.
**When to use:** `HexTileView` only — `HexFlowerLayout`'s hex geometry itself stays fixed per D-05.
**Example:**
```swift
// Source: Apple's @ScaledMetric docs (developer.apple.com/documentation/swiftui/scaledmetric)
// + community pattern for clamping (useyourloaf.com/blog/the-@scaledmetric-property-wrapper)
struct HexTileView: View {
    let letter: Character
    let isCenter: Bool

    // Base matches the current displayFont size (34pt) so default-category
    // rendering is visually unchanged from today.
    @ScaledMetric(relativeTo: .largeTitle) private var scaledLetterSize: CGFloat = 34
    private let maxLetterSize: CGFloat = 40  // tune on-device; hexSize is 70pt

    private var letterFontSize: CGFloat { min(scaledLetterSize, maxLetterSize) }

    var body: some View {
        Text(String(letter).uppercased())
            .font(.system(size: letterFontSize, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.5)   // safety net if the clamp is ever miscalibrated
            .foregroundStyle(isCenter ? Color.black : Color.primary)
            .frame(width: GameTheme.hexSize, height: GameTheme.hexSize)
            .background(isCenter ? GameTheme.accent : GameTheme.secondarySurface)
            .clipShape(HexagonShape())
            .contentShape(HexagonShape())
            .accessibilityLabel(Text(isCenter ? "Center letter \(String(letter).uppercased())"
                                              : "Letter \(String(letter).uppercased())"))
    }
}
```
`@ScaledMetric` alone (uncapped) is **not sufficient** — at accessibility sizes (AX1–AX5) it can scale a 34pt base past 90pt, which would overflow a fixed 70pt hex. The `min(scaledLetterSize, maxLetterSize)` clamp is the load-bearing part of this pattern; `.minimumScaleFactor`/`.lineLimit(1)` are a defense-in-depth fallback, not the primary mechanism (planner note: `@ScaledMetric` was not found to have a built-in max-value parameter as of iOS 17/18 SwiftUI — clamping must be done manually with `min()`).

### Pattern 3: SoundManager (AVAudioPlayer pool)
**What:** A small, dependency-free sound player gated by a persisted toggle.
**When to use:** All four SFX events (D-01).
**Example:**
```swift
// Source: pattern synthesized from Apple AVAudioPlayer docs
// (developer.apple.com/documentation/avfaudio/avaudioplayer) + community SoundManager
// examples (hackingwithswift.com/example-code/media/how-to-play-sounds-using-avaudioplayer)
import AVFoundation

enum SoundEffect: String, CaseIterable {
    case wordAccepted = "word_accepted"
    case wordRejected = "word_rejected"
    case pangramFound = "pangram_found"
    case roundEnd = "round_end"
}

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    // One preloaded AVAudioPlayer per effect. `prepareToPlay()` at init avoids
    // first-play latency; a fresh player per `play()` call (rather than reusing
    // one player across rapid repeats) is NOT needed here because these 4 events
    // cannot fire concurrently with themselves in this game's flow — a shared
    // pool of one player per sound is sufficient.
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        // .ambient: mixes with other audio, respects the silent switch — the
        // expected behavior for a casual word game's SFX (not a music app).
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") else { continue }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            players[effect] = player
        }
    }

    func play(_ effect: SoundEffect, enabled: Bool) {
        guard enabled else { return }
        players[effect]?.stop()
        players[effect]?.currentTime = 0
        players[effect]?.play()
    }
}
```
Call sites pass the `@AppStorage("soundEffectsEnabled")` value in from the view/view model (kept consistent with the project's value-in pattern), e.g. `SoundManager.shared.play(.wordAccepted, enabled: soundEffectsEnabled)`.

### Pattern 4: Settings Screen (value-in/closure-out)
**What:** Minimal single-toggle screen matching `PaywallView`/`MissedWordsView` conventions.
**Example:**
```swift
struct SettingsView: View {
    @Binding var soundEffectsEnabled: Bool  // or plain Bool + onToggle closure, per existing convention
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: GameTheme.lg) {
            Toggle("Sound Effects", isOn: $soundEffectsEnabled)
                .font(GameTheme.bodyFont)
            // ... standard nav bar / done button
        }
        .padding(GameTheme.lg)
    }
}
```
The `@AppStorage` itself should live in the owning view (e.g., a wrapper in `GameView` or `ContentView`) and be passed down as a `Binding`, keeping `SettingsView` free of `@AppStorage`/`@Environment` per the established presentation-view rule — mirrors how `ScoreBarView` takes `freePuzzlesRemaining` as a plain value rather than reading a store directly.

### Anti-Patterns to Avoid
- **Wrapping the sound toggle in a new `@Observable` service:** Unnecessary — `@AppStorage` alone is sufficient for a single Bool flag and matches the existing `dailyCount`/`puzzleSeed` convention; don't create an `@Observable SettingsStore` just for one flag.
- **Uncapped `@ScaledMetric` on hex tile letters:** Will clip/overflow the fixed hexagon at accessibility text sizes (AX1–AX5) — always clamp with `min()`.
- **Global `.dynamicTypeSize(...)` range clamp on the whole app:** Would satisfy compile-time safety but violates UX-03's actual requirement ("text scales correctly... at the largest Dynamic Type size") — only `HexTileView` gets a local clamp; nothing app-wide.
- **`.playback` AVAudioSession category for SFX:** Bypasses the user's silent switch, which is unexpected behavior for a casual word game's incidental sound effects (differs from apps like video/music players where audio is primary content).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Text scaling with system font size | Custom `UIFontMetrics`-based scaling wrapper | Built-in SwiftUI text styles (`.largeTitle`, `.title3`, `.body`, `.footnote`) via `Font.<style>.weight()` | The 4 existing sizes already sit exactly on standard text-style default sizes; a custom wrapper adds indirection with no benefit |
| Clamping accessibility text scaling | A generic "MaxScaledFont" abstraction across the app | A single local `min(scaledMetric, cap)` inline in `HexTileView` | Only one view needs this; a reusable abstraction is premature generalization for a one-off constraint |
| Audio playback / mixing | AVAudioEngine graph, custom sound pooling library | `AVAudioPlayer` (one instance per short SFX, preloaded) | 4 short one-shot sounds is exactly AVAudioPlayer's designed use case; AVAudioEngine is for real-time mixing/effects, overkill here |
| Privacy label completion | Any third-party "privacy label generator" tool | App Store Connect's built-in App Privacy questionnaire | It's a guided form; for a genuinely zero-collection app every answer is "No" / "Data Not Collected" — no tooling needed |
| Screenshot device framing | Custom Core Graphics compositing script | `fastlane frameit` (if installed) or manual compositing in Keynote/Figma/Preview | Device bezel art and precise screenshot alignment is a solved, tedious problem; not worth hand-rolling for 3-5 screenshots |

**Key insight:** Every "custom solution" temptation in this phase (custom font scaling, custom audio engine, custom privacy tooling) has a simpler built-in or off-the-shelf answer given the phase's actual scope (4 fonts, 4 sounds, 1 toggle, 1 privacy questionnaire). Phase 5 is deliberately small in code surface area — resist expanding it.

## Common Pitfalls

### Pitfall 1: `@ScaledMetric` Without a Clamp Overflows Fixed Geometry
**What goes wrong:** At the largest accessibility text sizes (AX5), an uncapped `@ScaledMetric` can scale a 34pt base font past 90pt — more than the entire 70pt hex tile diameter — causing visible clipping or the tile shape to be entirely obscured by text.
**Why it happens:** SwiftUI's accessibility Dynamic Type range (AX1–AX5, opted into via iOS Settings > Accessibility > Display & Text Size > Larger Text) scales far more aggressively than the standard range (xSmall–xxxLarge) that most testing defaults to.
**How to avoid:** Always test at the *accessibility* extra-extra-extra-large size (not just the standard xxxLarge), and clamp with `min(scaledValue, cap)` as shown in Pattern 2.
**Warning signs:** Testing only at "Larger Text" off or mid-range Dynamic Type settings; never toggling the separate "Larger Accessibility Sizes" switch in Simulator/device Settings.

### Pitfall 2: StoreKit's Local Transaction Cache Can Be Empty on First-Ever Launch Offline
**What goes wrong:** `Transaction.currentEntitlements` and `AppStore.sync()` read from a local cache StoreKit builds by syncing with Apple's servers. If a device has *never* completed that sync for the signed-in account (e.g., a brand-new device, first launch, immediately in Airplane Mode before any network activity), the entitlements stream can come back empty even for an account that legitimately purchased on another device.
**Why it happens:** StoreKit 2's offline support is a *cache*, not a fully local ledger — it requires at least one successful sync.
**How to avoid:** This does not require new app code (the app is correctly built around `Transaction.currentEntitlements` per MON-04) — it's a **testing methodology** pitfall. UX-01 verification ("all game features work in Airplane Mode") should be tested by: (1) launching once with network available to let StoreKit sync, then (2) enabling Airplane Mode and re-testing, not by testing a pristine install with network off from the very first launch. Free-tier gameplay (the common case, no purchase) is unaffected either way since there's no entitlement to sync.
**Warning signs:** A premium tester's purchase appears to "disappear" only in a fresh-install + immediately-offline test scenario — this is expected StoreKit behavior, not a regression, but should be documented so it isn't mistaken for a bug during phase verification.

### Pitfall 3: `.playback` AVAudioSession Category Ignores the Silent Switch
**What goes wrong:** If `SoundManager` sets category `.playback` (or leaves the session at its default), SFX will play audibly even when the user has the phone in Silent mode — unexpected and often reported as a bug/annoyance for casual games.
**Why it happens:** `.playback` is designed for apps where audio is the primary content (music/video players) and deliberately overrides the silent switch.
**How to avoid:** Use `.ambient` (mixes with other audio, silenced by the switch) as shown in Pattern 3 — matches player expectations for incidental game SFX.
**Warning signs:** SFX audible during a device demo/test even with the physical mute switch engaged.

### Pitfall 4: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` Must Be Set as a Build Setting, Not a Plist Edit
**What goes wrong:** Following generic App Store submission guides that say "add `ITSAppUsesNonExemptEncryption` = `NO` to Info.plist" doesn't map directly onto this project, which has `GENERATE_INFOPLIST_FILE = YES` and **no physical Info.plist file on disk** (confirmed: `find` for `Info.plist` returns nothing; all Info.plist keys are `INFOPLIST_KEY_*` build settings in `project.pbxproj`).
**Why it happens:** Modern Xcode project templates (this project included) synthesize Info.plist at build time from build settings; editing a plist file that doesn't exist is a dead end.
**How to avoid:** Add `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` to the app target's build settings (Release configuration at minimum; Debug for consistency) — either via Xcode's Build Settings UI ("Uses Non-Exempt Encryption" search) or a direct `project.pbxproj` edit alongside the existing `INFOPLIST_KEY_*` entries at the app target's config blocks (confirmed present at lines ~415-421 and ~448-454 of `project.pbxproj`).
**Warning signs:** App Store Connect prompts for export compliance information on every build submission despite believing this was already declared — a strong signal the key was set in the wrong place (or not at all) and Xcode's generated Info.plist doesn't actually contain it.

### Pitfall 5: `TARGETED_DEVICE_FAMILY = "1,2"` Means This App Is Configured for iPad Too
**What goes wrong:** The project's build settings currently declare `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad) across all 6 configuration blocks in `project.pbxproj`. CLAUDE.md and the phase description describe this as "an iPhone game," but the actual Xcode configuration makes it iPad-available too. If left as-is, App Store Connect will likely require iPad screenshots (13" iPad, 2064×2752) in addition to the iPhone set, and the layout has never been verified on iPad (only iPhone Simulators were used through Phases 1-4 per `.planning/STATE.md`).
**Why it happens:** `"1,2"` is Xcode's default for new projects; nothing in Phases 1-4 revisited it since the UI was only ever built/tested for iPhone.
**How to avoid:** Decide explicitly during planning: either (a) restrict `TARGETED_DEVICE_FAMILY` to `"1"` (iPhone only) to match the stated product scope and avoid an iPad screenshot/testing burden, or (b) keep `"1,2"` and add iPad screenshot capture + a basic iPad layout smoke-test to this phase's scope. This is a **planning decision**, not something research can resolve — flagged as an Open Question below.
**Warning signs:** App Store Connect's screenshot upload step shows an iPad-size requirement/warning that wasn't anticipated.

### Pitfall 6: Text Style `.weight()` Override Interacts with Dynamic Type Legibility Adjustments
**What goes wrong:** At very large Dynamic Type sizes, Apple's text styles apply not just size but also "legibility weight" boosts for some styles. Forcing `.weight(.semibold)` on `.largeTitle`/`.title3` (as recommended in Pattern 1) is fine and expected — Apple explicitly supports overriding weight on a text style — but if a future engineer instead builds a fully custom font+size combination instead of starting from a text style base, they lose this system-managed legibility boost entirely.
**Why it happens:** `.system(size:weight:)` fonts never scale or adjust regardless of Dynamic Type settings; only text-style-based fonts (`.largeTitle`, `.body`, etc., even with a `.weight()` override) participate in Dynamic Type at all.
**How to avoid:** Always start from `Font.<textStyle>` and layer `.weight()`/`.italic()` on top — never fall back to `Font.system(size: N)` for anything user-facing after this migration (this is exactly what D-04 requires app-wide, with the sole HexTileView exception per D-05).
**Warning signs:** Any future PR reintroducing `Font.system(size:` outside `HexTileView`/`GameTheme`'s clamp code should be treated as a regression of this phase's work.

## Code Examples

### Verified: Font Text Style Point Sizes (Default/"Large" Category)
```
// Source: Apple HIG Typography (developer.apple.com/design/human-interface-guidelines/typography)
largeTitle: 34   title: 28   title2: 22   title3: 20
headline:   17   body:  17   callout: 16  subhead: 15
footnote:   13   caption: 12  caption2: 11
```

### Verified: StoreKit 2 Offline Behavior
```
// Source: Apple Developer Forums thread 706450 ("StoreKit 2 currentEntitlements
// without internet") + thread 732391 ("Handle no internet access edge case on
// StoreKit 2") — cross-verified against RevenueCat engineering blog explanation
// of the same underlying StoreKit local transaction cache.
//
// Transaction.currentEntitlements and Transaction.all read from a LOCAL cache
// StoreKit maintains by syncing with Apple's servers. Once synced at least once,
// both work correctly with no network (Airplane Mode, no Wi-Fi/cellular).
// If sync has never completed for the current device+account, the stream is
// empty even for a legitimately-entitled account.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Separate Info.plist file with `ITSAppUsesNonExemptEncryption` key | `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` build setting, `GENERATE_INFOPLIST_FILE = YES` | Xcode 13+ project template default (this project already uses it) | Any "edit Info.plist" instruction from older guides must be translated to a build-setting edit for this project |
| Manually creating 6+ app icon size variants (20pt-1024pt) | Single 1024×1024 image per appearance slot (universal/dark/tinted); Xcode generates device-size variants automatically | iOS 14+ single-size icon catalogs (this project's `Contents.json` already reflects this: 3 slots, all 1024×1024) | Only 3 PNGs needed, not dozens |
| `fastlane snapshot` UI-test-driven screenshot automation | Manual `xcrun simctl io booted screenshot` capture is equally valid for a small, one-time screenshot set | N/A — both remain valid; `snapshot` pays off at scale (many locales/devices), not for a 3-5 screenshot v1 launch | Recommend manual capture given `fastlane` isn't installed and the screenshot set is small |
| App Store screenshot requirement across ~6 iPhone sizes | Only 6.9" iPhone (and 13" iPad if iPad-enabled) mandatory as of the current App Store Connect; Apple auto-scales smaller sizes | Current App Store Connect behavior (2025-2026) | Reduces screenshot production burden to one iPhone size (1320×2868px) — plus iPad only if Pitfall 5's device-family question resolves to keeping iPad support |

**Deprecated/outdated:** Manually maintaining 15+ icon size slots in `Contents.json` — modern single-size-per-appearance icon catalogs replaced this; this project's catalog is already on the modern format.

## Open Questions

1. **Should `TARGETED_DEVICE_FAMILY` stay `"1,2"` (iPhone+iPad) or be restricted to `"1"` (iPhone only)?**
   - What we know: The build setting currently includes iPad; the product is described everywhere else (CLAUDE.md, phase description) as an iPhone game; no iPad testing has occurred in Phases 1-4.
   - What's unclear: Whether this was an intentional decision or an unreviewed Xcode default.
   - Recommendation: Planner should surface this to Patrick as an explicit choice before UX-04 screenshot work begins — it changes both the screenshot production scope (iPad set or not) and whether a basic iPad layout check belongs in this phase. Given CLAUDE.md's stated iPhone focus, restricting to `"1"` is the lower-effort path consistent with existing scope.

2. **Exact clamp value for `HexTileView`'s `@ScaledMetric` letter size.**
   - What we know: Base is 34pt (current `displayFont` size); hex tile is a fixed 70pt diameter; some headroom exists before clipping.
   - What's unclear: The precise maximum (e.g. 38pt vs. 44pt) that looks good without appearing static/broken relative to the rest of the now-scaling UI — this is a visual/on-device judgment call, not something research can determine analytically.
   - Recommendation: Left as Claude's discretion per CONTEXT.md; plan should include an on-device/Simulator visual check step at the largest accessibility size (AX5) as part of verification, not just a code review.

3. **Exact SFX file selection from Kenney UI Audio pack.**
   - What we know: The pack is CC0 (kenney.nl/assets/ui-audio), contains ~50 clips including clicks/switches, and matches the "clean, short" requirement in D-02.
   - What's unclear: Which specific 4 files map best to "word accepted" / "word rejected" / "pangram found (bigger/distinct)" / "round end" — this is a subjective audio-design choice.
   - Recommendation: Left as Claude's discretion per CONTEXT.md; plan should include a step to download/preview candidates and pick 4 (plus verify `.caf` or bundle-compatible format — Kenney ships `.ogg`/`.wav`, which need conversion to `.caf`/`.m4a`/`.wav`-compatible format for `AVAudioPlayer`; `.wav` works directly, no conversion needed if downloading the WAV variant).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | All build/test verification | Yes | 26.6 (Build 17F113) | — |
| iOS Simulator (iPhone 17) | Dynamic Type / screenshot testing | Yes | iOS 26.5 runtime, iPhone 17 device confirmed available | — |
| `xcrun simctl` | Screenshot capture (D-09) | Yes | bundled with Xcode 26.6 | — |
| fastlane / fastlane frameit | Optional device-frame + caption automation for screenshots | No | — | Manual compositing (Keynote, Figma, or Preview.app) for the small 3-5 screenshot set; install fastlane (`gem install fastlane` or `brew install fastlane`) only if screenshot iteration becomes frequent |
| ImageMagick (`convert`/`magick`) | Optional scripted image manipulation | No | — | Not needed — `ImageRenderer` (SwiftUI, built-in) covers icon-concept export; screenshot compositing can be done in Keynote/Figma/Preview without CLI tooling |
| Kenney UI Audio pack download | SFX sourcing (D-02) | External (web download, not yet fetched) | — | No fallback needed — this is a one-time manual download step in the plan, not a machine dependency |

**Missing dependencies with no fallback:** None — all missing tools have a viable manual fallback for this phase's small scope.

**Missing dependencies with fallback:** fastlane/frameit (manual compositing), ImageMagick (ImageRenderer + manual tools).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`@Test`/`@Suite`), matching all existing test files in `WordPuzzleTests/` |
| Config file | None — no `pytest.ini`/`jest.config`-equivalent; test target configured directly in `project.pbxproj`/scheme |
| Quick run command | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios && xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WordPuzzleTests/<SuiteName> 2>&1 \| tail -30` |
| Full suite command | `cd /Users/patrickhoughton/Documents/GitHub/word-puzzle-ios && xcodebuild test -project WordPuzzle/WordPuzzle.xcodeproj -scheme WordPuzzle -destination 'platform=iOS Simulator,name=iPhone 17' 2>&1 \| tail -30` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-01 | App has zero network calls; StoreKit works after one sync, offline | manual (Airplane Mode device/Simulator test) | N/A — code-search verification (`grep -rn "URLSession\|URLRequest"`) can be automated as a regression guard; actual offline behavior is a manual device test | ❌ Wave 0 (grep-based guard test optional) |
| UX-02 | Sound toggle persists across restarts; SFX plays/mutes correctly | unit (persistence logic) + manual (audible verification) | `xcodebuild test ... -only-testing:WordPuzzleTests/SoundManagerTests` (new suite testing the `enabled` gate logic, not actual audio output) | ❌ Wave 0 |
| UX-03 | All text scales at largest Dynamic Type size | manual (Simulator/device visual check at AX5) — SwiftUI's declarative view hierarchy is not reliably introspectable via Swift Testing for rendered font sizes | N/A — no automated command; verification step is "toggle Settings > Accessibility > Larger Text to max, inspect every screen" | ❌ Wave 0 (no automated coverage possible for actual rendering; a lightweight unit test CAN assert `GameTheme` no longer emits `Font.system(size:)`, but `Font`'s internal representation is not straightforwardly inspectable for equality — recommend a code-review/grep gate instead: `grep -c "Font.system(size:" GameTheme.swift` should be 0 after migration) |
| UX-04 | App icon + screenshots present, correctly sized | manual (App Store Connect upload validates format/size automatically) | N/A | — |
| UX-05 | Privacy label complete; encryption compliance set | manual (App Store Connect questionnaire) + one automated build-setting check | `grep -n "ITSAppUsesNonExemptEncryption" WordPuzzle/WordPuzzle.xcodeproj/project.pbxproj` should return the `NO` setting | ❌ Wave 0 (grep gate, not a test suite) |

### Sampling Rate
- **Per task commit:** Relevant quick-run test suite (e.g., `SoundManagerTests` after SoundManager work) + grep-based regression guards (no `Font.system(size:` outside `HexTileView`'s clamp code; no `URLSession`/`URLRequest` anywhere).
- **Per wave merge:** Full `xcodebuild test` suite green.
- **Phase gate:** Full suite green, PLUS the manual verification checklist (Airplane Mode device test, AX5 Dynamic Type visual pass on every screen, silent-switch SFX behavior, App Store Connect privacy questionnaire completed, icon/screenshots uploaded) before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `WordPuzzleTests/SoundManagerTests.swift` — new suite covering the `@AppStorage`-gated `enabled` logic (does NOT need to assert actual audio playback — assert that `play()` is a no-op when disabled, e.g. via an injectable "did attempt to play" seam)
- [ ] Grep-based regression guards for: (a) no `Font.system(size:` outside `HexTileView`, (b) no `URLSession`/`URLRequest` anywhere in `WordPuzzle/WordPuzzle`, (c) `ITSAppUsesNonExemptEncryption` present and `NO` in `project.pbxproj` — these can be lightweight shell-script checks run as part of task verification rather than Swift Testing suites, since they check source/config, not runtime behavior
- [ ] No SwiftUI snapshot-testing infrastructure exists (and none is recommended for this phase's scope) — Dynamic Type visual correctness (UX-03) and icon/screenshot correctness (UX-04) remain manual verification steps; this is expected and acceptable given the phase's small surface area, not a gap to fill with new tooling

## Sources

### Primary (HIGH confidence)
- Apple HIG Typography — developer.apple.com/design/human-interface-guidelines/foundations/typography/ — text style point size reference
- Apple `@ScaledMetric` documentation (referenced via community sources; official API surface confirmed no built-in max-clamp parameter) — developer.apple.com/documentation/swiftui/scaledmetric
- Apple `AVAudioPlayer`/`AVAudioSession` category documentation — developer.apple.com/documentation/avfaudio
- Apple Developer Forums thread 706450 "StoreKit 2 currentEntitlements without internet" — developer.apple.com/forums/thread/706450
- Apple Developer Forums thread 732391 "Handle no internet access edge case on StoreKit 2" — developer.apple.com/forums/thread/732391
- Kenney UI Audio pack license page — kenney.nl/assets/ui-audio (CC0, confirmed no-attribution commercial use)
- Local codebase inspection: `GameTheme.swift`, `HexTileView.swift`, `WordPuzzleApp.swift`, `project.pbxproj` (grep-verified: no `URLSession`, no `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` yet, `TARGETED_DEVICE_FAMILY = "1,2"`, `GENERATE_INFOPLIST_FILE = YES`, no physical `Info.plist`)
- Local environment probe: `xcodebuild -version` (26.6), `sw_vers` (macOS 26.6.2), `xcrun simctl list devices` (iPhone 17 available), fastlane/ImageMagick not installed

### Secondary (MEDIUM confidence)
- App Store Connect current screenshot size requirements (6.9" iPhone mandatory, others auto-scaled) — cross-verified across multiple 2026-dated ASO guide sites (splitmetrics.com, pushmyapp.ai, screenhance.com); not an official Apple page but consistent across independent sources
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` as the correct build-setting name for plist-less projects — cross-verified across aso.dev guide and Apple Developer Forums threads 802746/765911
- Privacy label "Data Not Collected" declaration mechanics — apple.com/privacy/labels and jamf.com summary, consistent with CLAUDE.md's existing guidance

### Tertiary (LOW confidence)
- Icon Composer / Xcode 26 Liquid Glass single-.icon-file workflow — noted for awareness only; NOT recommended for this phase since the project's `Contents.json` is already scaffolded for the traditional 3-PNG format; flagged as state-of-the-art context, not an actionable recommendation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all built-in Apple frameworks already implied by CLAUDE.md's tech stack; no new dependency decisions required
- Architecture: HIGH — patterns directly extend the codebase's own established conventions (GameTheme single-source-of-truth, value-in/closure-out views, `@AppStorage` for flags), verified by direct file inspection
- Pitfalls: MEDIUM-HIGH — StoreKit offline caching behavior and `@ScaledMetric` clamp necessity are well-documented (HIGH); exact clamp tuning values and TARGETED_DEVICE_FAMILY scope are judgment calls left open (flagged explicitly)

**Research date:** 2026-09-07
**Valid until:** ~30 days (stable Apple APIs; App Store Connect screenshot/privacy requirements can shift with Apple platform updates — re-verify screenshot size requirements if this phase is executed significantly later than planned)
