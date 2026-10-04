---
phase: 5
plan: 08
status: draft
---

# App Store Listing — Word Puzzle Unlimited v1.0

Every value Patrick will set in App Store Connect, drafted within Apple's limits.
Status `draft` until the values are confirmed live in App Store Connect.

## Current App Store Connect state (API read-back, 2026-10-03)

`python3 scripts/appstoreconnect.py get "/v1/apps?filter[bundleId]=com.patrickhoughton.WordPuzzle"`

| Field | Value |
|---|---|
| App id | `6806385553` |
| Name | `Word Puzzle Unlimited` |
| SKU | `wordpuzzle-001` |
| Primary locale | `en-US` |
| Version | `1.0` (id `03ce47c4-7f3d-41dc-9df4-456ae869dd76`), `PREPARE_FOR_SUBMISSION` |
| Release type | `AFTER_APPROVAL` — **must change to Manual Release** |
| AppInfo | `ee6e2274-5da6-46e9-b0df-6ecc38cd3ae5`, `PREPARE_FOR_SUBMISSION` |
| Subtitle, privacy policy URL, categories | all unset |
| Description, keywords, promo text, support URL | all unset (version localization `0dbffaa6-f9f7-42eb-ace0-2b70e0bbc5bd`) |
| App Review details | none |
| Age rating declaration | every answer unset |
| Builds uploaded | **0** — a build must be archived and uploaded before submission |
| IAP `com.patrickhoughton.wordpuzzle.unlimited` (id `6806386464`) | `NON_CONSUMABLE`, state **`MISSING_METADATA`** — localization exists ("Unlimited Puzzles" / "One-time purchase, no subscription, unlimited play."); **App Review screenshot missing** |

## Progress log

**2026-10-04 — pushed via the App Store Connect API (all HTTP 200):**
- Subtitle → `Endless offline word puzzles`
- Categories → Games, subcategories Word + Puzzle
- Description, Keywords (97 chars), Promotional Text → as drafted below
- Release type → `MANUAL` (was `AFTER_APPROVAL`)
- Age rating declaration → every answer None/No (4+)

**2026-10-04 — build 1.0 (1) archived and uploaded** (`xcodebuild -exportArchive`, cloud-managed
distribution signing via the API key; `EXPORT SUCCEEDED`). Processing at Apple.

**On hold (Patrick, 2026-10-04): v1.0 submission waits for backlog items 999.1–999.8 to be built
into v1.0 and tested on device.** Consequences:
- Screenshots: NOT uploaded yet — re-capture after the backlog lands (the UI will change), then upload.
- Description/promo text may need a refresh once the new features exist.
- Still outstanding: IAP review screenshot, App Privacy questionnaire and Mac/Vision Pro
  availability (UI-only), screenshot upload, final build upload + submission.

**2026-10-04 — copyright, review contact, URLs (all HTTP 200/201):**
- Copyright → `2026 Three Mile Bridge LLC`
- App Review details created: Patrick Houghton, +1 850 723 9249, mrpatrickhoughton@gmail.com,
  no demo account, notes as drafted below
- Privacy Policy URL → `https://apps.threemilebridge.com/wordpuzzle/privacy/`
- Support URL → `https://apps.threemilebridge.com/wordpuzzle/support/`
- Pages served by GitHub Pages from `docs/` (custom domain `apps.threemilebridge.com`, HTTPS
  certificate approved, HTTPS enforced; all three pages return 200).
- DNS: threemilebridge.com moved from Dynadot "Site Builder" preset to "Dynadot DNS" (registry
  delegation geo.dyna-ns.net -> ns1/ns2.dyna-ns.net at 18:21:56Z). Required setting Dynadot
  Email Settings to "Not Set" first; mail now flows via explicit records. Zone: A 54.177.117.207 +
  16.162.17.243, MX 0 webhost.dynadot.com, SPF TXT, www A x2, default._domainkey CNAME
  clients._domainkey.webhost.dynadot.com, _dmarc TXT, apps CNAME patrickhoughton.github.io.

## Listing values

### App Name — 21/30 chars
```
Word Puzzle Unlimited
```
Already registered; kept. "Spelling Bee" is deliberately **not** used in the name,
subtitle or description: it is a New York Times trademark for this puzzle format,
and trademarked terms in visible metadata are a Guideline 5.2.1 / 2.3.7 rejection risk.

### Subtitle — 28/30 chars
```
Endless offline word puzzles
```

### Keywords — 97/100 chars
```
spelling,bee,pangram,anagram,honeycomb,letters,vocabulary,brain,teaser,scramble,game,subscription
```
No spaces after commas. Omits words already indexed from the name/subtitle
(word, puzzle(s), unlimited, endless, offline). UX-04 targets reconstructed from
name + subtitle + keywords:
- "spelling bee unlimited" → `spelling`,`bee` (keywords) + `Unlimited` (name)
- "word puzzle offline" → `Word Puzzle` (name) + `offline` (subtitle)
- "word game no subscription" → `Word` (name) + `game`,`subscription` (keywords)

`spelling,bee` are kept as separate generic keyword tokens (hidden field, not
displayed) — lower risk than visible use, but drop them if Review objects.

### Promotional Text — 156/170 chars (editable any time without review)
```
A fresh honeycomb puzzle every round, generated on your device. Play 3 free puzzles a day, or unlock unlimited play once for $2.99. No subscription, no ads.
```

### Description
```
Seven letters. One center letter. How many words can you find?

Word Puzzle Unlimited is a honeycomb word game with a puzzle that never runs out. Every round is generated fresh on your device from a dictionary of more than 170,000 words, so there is always a new set of letters to play — no daily wait for tomorrow's puzzle.

HOW TO PLAY
• Tap or drag across the letters to build a word, then swipe down to submit it.
• Every word must be at least four letters long and use the gold center letter.
• Letters can be reused as often as you like.
• Find a pangram — a word that uses all seven letters — for a big bonus.
• Climb the ranks as your score grows, then finish the round to see every word you missed.

BUILT TO PLAY ANYWHERE
• Works fully offline. No account, no sign-in, no internet connection needed.
• No ads and no tracking. The app collects no data at all.
• Supports Dynamic Type for comfortable reading at any text size.
• Optional sound effects and haptic feedback.

FREE TO TRY, ONE PRICE TO OWN
Play 3 free puzzles every day. When you want more, unlock unlimited puzzles with a single one-time purchase of $2.99 — no subscription, ever. Already unlocked on another device? Tap Restore Purchases on the unlock screen.
```
1233/4000 chars.

### URLs
| Field | Value | Status |
|---|---|---|
| Privacy Policy URL (required — app has an IAP) | `https://patrickhoughton.github.io/word-puzzle-ios/privacy/` (proposed) | **BLOCKER — not published yet.** Repo is public; GitHub Pages is not enabled. Policy text drafted below. |
| Support URL (required) | `https://patrickhoughton.github.io/word-puzzle-ios/support/` (proposed) | **BLOCKER — not published yet.** Needs a contact method. |
| Marketing URL | — | optional, leave blank |

### Category
- Primary: **Games**, subcategories **Word** and **Puzzle**
- Secondary: none

### Age Rating — all "None" / "No" → 4+
Every frequency question (cartoon/realistic violence, sexual content, profanity
or crude humor, horror, mature themes, alcohol/drugs, medical, gambling
simulation, contests, guns) = **None**. Unrestricted web access = **No**.
User-generated content = **No**. Messaging/chat = **No**. Advertising = **No**.
Loot boxes = **No**. Gambling = **No**. Made for Kids = **No**. (The bundled
word list is profanity-filtered — `enable-clean.txt`.)

### Copyright
```
2026 Patrick Houghton
```

### App Review Information
- Sign-in required: **No** (no demo account needed)
- Contact: Patrick Houghton — phone/email entered privately in App Store Connect
- **Notes:**
```
The app works fully offline and requires no login, demo account or network connection.

How to reach the in-app purchase (paywall):
The paywall appears after a free user has started their third puzzle of the day. To reach it quickly: play and finish three rounds — tap letters to build a word, swipe down on the assembled word to submit it, then tap Finish Round, then tap Next Puzzle on the results screen. After the third round, tapping Next Puzzle shows the unlock screen with the price ($2.99), an "Unlock Unlimited Puzzles" button and a "Restore Purchases" button.

The in-app purchase is a single non-consumable ("Unlimited Puzzles", com.patrickhoughton.wordpuzzle.unlimited) that removes the 3-puzzles-per-day limit. There are no subscriptions.
```

### App Privacy questionnaire — **Data Not Collected**
"Do you or your third-party partners collect data from this app?" → **No, we do
not collect data from this app.** Every category (Contact Info, Health & Fitness,
Financial Info, Location, Sensitive Info, Contacts, User Content, Browsing
History, Search History, Identifiers, Purchases, Usage Data, Diagnostics, Other
Data) is therefore **Not Collected**. Justification: no analytics SDK
(TelemetryDeck deferred to v2 per D-06), no accounts, and no network calls at
all (enforced by `scripts/compliance-guards.sh` Guard 1). StoreKit purchases are
processed by Apple, not collected by the developer.

### Availability
- iPhone: yes. iPad: **yes** (05-04 `device-family-keep-ipad`).
- "Make this app available on Mac (Apple silicon)": **unchecked** — not tested.
- "Make this app available on Apple Vision Pro": **unchecked** — not tested.
- Territories: all; price: Free (IAP carries the $2.99).

### Screenshots
- 6.9" iPhone: `Marketing/screenshots/final/01-gameplay.png`, `02-round-end.png`, `03-paywall.png` (1320x2868)
- 13" iPad: `Marketing/screenshots/final/ipad/01..03` (2064x2752)
- IAP App Review screenshot: `Marketing/screenshots/raw/03-paywall.png` (uncaptioned paywall, 1320x2868)

### Release Option
**Manual Release** — currently `AFTER_APPROVAL`, must be changed.

## Privacy Policy (draft text to publish)

```
Privacy Policy — Word Puzzle Unlimited
Last updated: October 3, 2026

Word Puzzle Unlimited does not collect, store, or share any personal information.

• No data collection. The app has no analytics, advertising, or tracking code, and it does not ask for an account.
• No network access. Puzzles are generated on your device, and the app never connects to the internet.
• On-device data. Your game history, scores, streak and settings are stored only on your device and are deleted when you delete the app.
• Purchases. The optional "Unlimited Puzzles" purchase is processed entirely by Apple through the App Store. The developer never receives your payment details.
• Children. The app does not knowingly collect information from anyone, including children.

If this policy changes, the updated version will be posted at this address.

Contact: phoughton@threemilebridge.com
```

## Pre-submission checklist

- [x] Restore Purchases button present (MON-03, Phase 4)
- [x] Paywall discoverable — step-by-step path in App Review Notes (drafted above)
- [x] Encryption export compliance: `ITSAppUsesNonExemptEncryption = NO` (05-04)
- [ ] Privacy label "Data Not Collected" published (Task 2 — UI only, no API exists)
- [ ] Mac and Vision Pro availability unchecked (Task 2)
- [x] Screenshots for all required sizes generated (05-07: iPhone 6.9" + iPad 13")
- [ ] Screenshots uploaded (Task 2)
- [x] Privacy Policy URL published and set (apps.threemilebridge.com, 2026-10-04)
- [x] Support URL published and set (apps.threemilebridge.com, 2026-10-04)
- [ ] IAP metadata complete (App Review screenshot) — currently `MISSING_METADATA`
- [x] Release option set to Manual Release (API, 2026-10-04)
- [ ] Final build archived and uploaded — 1.0 (1) uploaded 2026-10-04 as a test; final build after Phases 6-12
