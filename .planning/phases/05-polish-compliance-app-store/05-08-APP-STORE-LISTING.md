---
phase: 5
plan: 08
status: submitted
---

# App Store Listing — Word Puzzle Unlimited v1.0

Every value Patrick will set in App Store Connect, drafted within Apple's limits.
Status `submitted` — v1.0 (build 2) + IAP submitted for review 2026-10-05; values below are what is live in App Store Connect.

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
- Description, Keywords (97 chars), Promotional Text → the 2026-10-04 drafts (keywords unchanged below; description/promo since refreshed 2026-10-05, not yet pushed)
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

**2026-10-05 — resumed after Phases 6-12 (local work only, no App Store Connect writes):**
- Screenshots re-captured against the current UI: now **4 per device** (added `02-found-words`
  for the Phase 7 sheet). Tutorial bypassed in the capture test via `-hasSeenTutorial YES`
  (pre-existing from 11-01). Commit `dd670b5`.
- Description and Promotional Text refreshed for the new features (below) — **not yet pushed**;
  the live App Store Connect values are still the 2026-10-04 text.
- Build number bumped to **1.0 (2)** (commit `7bee163`) — build 1 is already uploaded and VALID,
  so the final upload must be build 2 or higher.
- `bash scripts/compliance-guards.sh` → exit 0 (all 4 guards pass, after the bump).

**2026-10-05 — API read-back (GET only):**

| Check | Result |
|---|---|
| `GET /v1/builds?filter[app]=6806385553` | 1 build: version `1` (id `82e832c9-4e15-43f8-ae8c-281cdcf303c9`), uploaded 2026-10-04T07:13:21-07:00, `processingState VALID`, `expired false`, `minOsVersion 17.6`, **`usesNonExemptEncryption false`** (export compliance answered by the Info.plist key — no prompt) |
| `GET /v1/appStoreVersions/03ce47c4-…?include=build` | `1.0`, `PREPARE_FOR_SUBMISSION`, `releaseType MANUAL`, copyright `2026 Three Mile Bridge LLC`, **no build attached** |
| `GET /v1/appStoreVersionLocalizations/0dbffaa6-…` | description/keywords/promo = 2026-10-04 text; keywords 97 chars as below; support URL set |
| `GET /v1/appStoreVersionLocalizations/0dbffaa6-…/appScreenshotSets` | **0 sets** — no screenshots uploaded |
| `GET /v1/apps/6806385553/inAppPurchasesV2` | `6806386464` Unlimited Puzzles, `NON_CONSUMABLE`, state **`MISSING_METADATA`**, familySharable false |
| `GET /v2/inAppPurchases/6806386464/appStoreReviewScreenshot` | **`data: null`** — the one missing piece of IAP metadata |
| IAP price schedule / availability / localization | 1 manual price (USA base territory, price point 10036) set; availability set (`availableInNewTerritories true`); en-US localization "Unlimited Puzzles" / "One-time purchase, no subscription, unlimited play." (`PREPARE_FOR_SUBMISSION`) |

**2026-10-05 — App Store Connect writes, approved by Patrick (helper `scripts/asc_upload_assets.py`, payloads checked against Apple OpenAPI spec v4.5):**
- iPhone 6.9" set `b8aa6d18-afda-4338-bd75-688329b65f88` (`APP_IPHONE_67`) created; 4 screenshots
  uploaded in order 01-gameplay, 02-found-words, 03-round-end, 04-paywall, all `COMPLETE`, no errors.
  Accepted 1320x2868 in the `APP_IPHONE_67` slot.
- iPad 13" set `497360dc-2311-4f3d-b008-139784c158c9` (`APP_IPAD_PRO_3GEN_129`) created; same 4
  screenshots, same order, all `COMPLETE`. Accepted 2064x2752 in the `APP_IPAD_PRO_3GEN_129` slot.
- Read-back (`GET .../appScreenshotSets?include=appScreenshots`): 2 sets, 4 screenshots each, order 01→04.
- IAP App Review screenshot (`raw/04-paywall.png`) uploaded: id `331458d7-6c20-4158-82bd-02ae38a1ca42`,
  `COMPLETE`. IAP state read back: **`MISSING_METADATA` → `READY_TO_SUBMIT`**.
- **NOT done — permission denied by the Claude Code permission classifier** on the description/promo
  `PATCH /v1/appStoreVersionLocalizations/0dbffaa6-…` (stopped there per instructions; no retry).
  Therefore also not done: review-notes PATCH, build 1.0 (2) archive/upload, build attach.
  Live description/promo/review notes are still the 2026-10-04 values.

**2026-10-05 — re-run after Patrick added allow rules (commands matched exactly, no pipes):**
- `PATCH /v1/appStoreVersionLocalizations/0dbffaa6-…` description (1824) + promotionalText (168):
  HTTP 200; GET read-back matches the listing doc word for word; keywords unchanged (97).
  (Note: the Bash harness turned a JSON `'` escape into a bare `'` and broke shell quoting —
  apostrophes were passed with the standard `'\''` shell idiom instead.)
- App Review detail id `0497122e-c6fe-4a12-a13f-5c096ab38c54`: `PATCH notes` (adds the
  first-launch tutorial paragraph) HTTP 200; GET read-back matches the Notes block below.
  Contact fields untouched.
- Build 1.0 (2): `xcodebuild archive` (Release, generic iOS, `-allowProvisioningUpdates` + API key)
  then `xcodebuild -exportArchive` (ExportOptions: method `app-store-connect`, destination `upload`,
  team H5U5FQ78L4, automatic signing) → `Upload succeeded` / `EXPORT SUCCEEDED` at 18:30 local.
  Archive Info.plist: CFBundleVersion 2, CFBundleShortVersionString 1.0, ITSAppUsesNonExemptEncryption false.
- Build processing: id `6abe3263-790d-486f-96b4-d14596ef6324`, uploaded 2026-10-05T16:31:27-07:00,
  `VALID` within ~5 min, **`usesNonExemptEncryption false`**.
- `PATCH /v1/appStoreVersions/03ce47c4-…/relationships/build` → HTTP 204. Read-back: version 1.0
  (`PREPARE_FOR_SUBMISSION`, `MANUAL`) now has build `6abe3263-…` (version 2, VALID) attached.
- NOT done (by design): Submit for Review. Still open for Patrick (UI only): App Privacy "Data Not
  Collected", uncheck Mac + Vision Pro, confirm no export-compliance prompt in the UI, and make sure
  the IAP (READY_TO_SUBMIT) is included with the first version submission.

**2026-10-05 — SUBMITTED FOR REVIEW (Patrick, App Store Connect UI; facts from orchestrator API read-backs + Patrick's screenshots):**
- Review submission `3699c1dc-49a9-472c-80b1-cb3eaeab2db1`, submitted 7:13 PM, **2 items**: version 1.0
  (build 2) and IAP `6806386464`. Version `appStoreState WAITING_FOR_REVIEW`, `releaseType MANUAL`;
  IAP `WAITING_FOR_REVIEW`.
- `GET /v1/apps/6806385553/appInfos` (read-back by executor): appInfo `ee6e2274-5da6-46e9-b0df-6ecc38cd3ae5`
  `state WAITING_FOR_REVIEW`, `appStoreState WAITING_FOR_REVIEW`, `appStoreAgeRating FOUR_PLUS`.
- **No export compliance prompt appeared** (build 2 `usesNonExemptEncryption false`).
- App Privacy questionnaire completed as **Data Not Collected** (submission requires it; it went through).

**Lessons — App Store Connect surprises on this first submission (reuse next time):**
1. **A first IAP is NOT added automatically.** The first submission (7:04 PM) held only the version even
   though the IAP was `READY_TO_SUBMIT`. Patrick cancelled it (version went to `DEVELOPER_REJECTED`,
   which is resubmittable). Fix in the new ASC UI: add the IAP to a draft submission from the IAP's own
   page, then put the version into that same draft via **Add for Review** dropdown → "Draft Submission (1)".
   A first IAP must be explicitly included with the version submission.
2. **"Add for Review" was blocked by two unset items the API work never touched:**
   - *Content Rights* — answered **Yes, contains third-party content, and the rights are held** (the ENABLE
     word list is public domain).
   - *App price tier* — none was set; now **Free, USD base** (the IAP carries the $2.99).
3. **Screenshot UI hides the 6.9" set:** the new ASC media UI shows "iPhone with Dynamic Island (medium
   display)" by default; the `APP_IPHONE_67` (6.9") set uploaded via API only appears under **View All
   Sizes in Media Manager**. An "iPhone Duo" tab exists but submission did not require it.
4. Mac / Vision Pro availability: uncheck steps were given to Patrick but he has **not explicitly
   confirmed** doing them — pending confirmation (see checklist).

## Per-step confirmation (plan Task 2, what was actually set)
1. App Privacy — **Data Not Collected**, completed by Patrick in the UI 2026-10-05 (submission accepted).
2. Listing metadata — name `Word Puzzle Unlimited`, subtitle `Endless offline word puzzles`, keywords
   (97 chars, below) set via API; description (1824) + promo (168) PATCHed and read back 2026-10-05;
   category Games > Word + Puzzle; age rating 4+ (read back `FOUR_PLUS`).
3. Screenshots — 4 x iPhone 6.9" (`APP_IPHONE_67`) + 4 x iPad 13" (`APP_IPAD_PRO_3GEN_129`) uploaded via
   API, all `COMPLETE`, order 01→04.
4. Availability — iPad yes; Mac and Vision Pro **pending Patrick's confirmation** that they were unchecked.
5. URLs — Privacy Policy `https://apps.threemilebridge.com/wordpuzzle/privacy/`, Support
   `https://apps.threemilebridge.com/wordpuzzle/support/` (API, 2026-10-04).
6. Review Notes — PATCHed 2026-10-05 with tutorial-skip + paywall steps, read back.
7. Export compliance — **no prompt**; builds 1 and 2 report `usesNonExemptEncryption false`.
8. Release option — **Manual Release** (`releaseType MANUAL`, read back while `WAITING_FOR_REVIEW`).

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

### Promotional Text — 168/170 chars (editable any time without review)
```
A fresh honeycomb puzzle every round, generated on your device. Spin the letters, track your words, build a streak. 3 free puzzles a day, or unlock unlimited for $2.99.
```
Refreshed 2026-10-05 (was 156 chars, pushed 2026-10-04; refreshed text NOT yet pushed).

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
• New to the game? A short hands-on tutorial on a practice board walks you through it on first launch.

MORE WAYS TO PLAY
• Stuck? Flick the outer ring of letters and watch it spin, or double-tap any empty space to shuffle.
• Tap the score bar to see every word you've found, grouped by length.
• Find every pangram in a puzzle, or every word of one length, for extra bonus points.
• Clear feedback tells you why a word didn't count: too short, missing the center letter, already found, or not a word.
• Your stats screen tracks your daily streak, best score, best rank and lifetime totals.

BUILT TO PLAY ANYWHERE
• Works fully offline. No account, no sign-in, no internet connection needed.
• No ads and no tracking. The app collects no data at all.
• Supports Dynamic Type for comfortable reading at any text size.
• Optional sound effects and haptic feedback.

FREE TO TRY, ONE PRICE TO OWN
Play 3 free puzzles every day. When you want more, unlock unlimited puzzles with a single one-time purchase of $2.99 — no subscription, ever. Already unlocked on another device? Tap Restore Purchases on the unlock screen.
```
1824/4000 chars. Refreshed 2026-10-05 for Phases 6-12 (tutorial, flick-to-spin,
double-tap shuffle, found-words view, completion bonuses, differentiated rejection
feedback, stats/streak screen) — NOT yet pushed (live value is the 2026-10-04 1233-char text).
No "Spelling Bee"; hidden Mythic tier deliberately not mentioned.

### URLs
| Field | Value | Status |
|---|---|---|
| Privacy Policy URL (required — app has an IAP) | `https://apps.threemilebridge.com/wordpuzzle/privacy/` | Published (GitHub Pages from `docs/`) and set via API 2026-10-04 |
| Support URL (required) | `https://apps.threemilebridge.com/wordpuzzle/support/` | Published and set via API 2026-10-04 (read back 2026-10-05) |
| Marketing URL | — | optional, left blank |

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
2026 Three Mile Bridge LLC
```
Set via API 2026-10-04; read back 2026-10-05.

### App Review Information
- Sign-in required: **No** (no demo account needed)
- Contact: Patrick Houghton — phone/email entered privately in App Store Connect
- **Notes:** (updated 2026-10-05 for the Phase 11 first-launch tutorial — the live App Review
  details still carry the 2026-10-04 notes without the tutorial paragraph; push needed)
```
The app works fully offline and requires no login, demo account or network connection.

First launch: a short interactive tutorial runs on a practice board. Tap "Skip tutorial" in the instruction banner to go straight to the first real puzzle (or complete the steps and tap Finish Round). The practice board does not count toward the daily limit.

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

### Screenshots (re-captured 2026-10-05, commit `dd670b5`)
Upload in this order — 01 gameplay, 02 found words, 03 round end, 04 paywall:
- 6.9" iPhone (1320x2868): `Marketing/screenshots/final/01-gameplay.png`, `02-found-words.png`, `03-round-end.png`, `04-paywall.png`
- 13" iPad (2064x2752): `Marketing/screenshots/final/ipad/01-gameplay.png` … `04-paywall.png`
- Captions: "Endless word puzzles, fresh every round" / "Track every word you find, sorted by length" /
  "See every word you missed, pangrams too" / "Unlock unlimited puzzles — no subscription, just $2.99"
- IAP App Review screenshot: `Marketing/screenshots/raw/04-paywall.png` (uncaptioned paywall, 1320x2868)

### Release Option
**Manual Release** — set via API 2026-10-04 (`releaseType MANUAL`, read back 2026-10-05).

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
- [x] Privacy label "Data Not Collected" published (Patrick, UI, 2026-10-05 — required by and accepted for submission)
- [ ] Mac and Vision Pro availability unchecked — **pending Patrick's explicit confirmation** (steps given; not confirmed)
- [x] Screenshots for all required sizes generated (re-captured 2026-10-05 after Phases 6-12: 4 x iPhone 6.9" + 4 x iPad 13")
- [x] Screenshots uploaded 2026-10-05 (4 x iPhone 6.9" + 4 x iPad 13", all COMPLETE, read back)
- [x] Privacy Policy URL published and set (apps.threemilebridge.com, 2026-10-04)
- [x] Support URL published and set (apps.threemilebridge.com, 2026-10-04)
- [x] IAP metadata complete — review screenshot uploaded 2026-10-05; state `READY_TO_SUBMIT`
- [x] Release option set to Manual Release (API, 2026-10-04)
- [x] Final build archived and uploaded — 1.0 (2) uploaded 2026-10-05, VALID
- [x] Export compliance — builds 1 and 2 report `usesNonExemptEncryption false`; no prompt appeared at submission
- [x] Refreshed Description / Promotional Text / Review Notes pushed and read back (2026-10-05)
- [x] Build 1.0 (2) attached to version 1.0 (read back)
- [x] IAP included with the version submission (submission `3699c1dc-…`, 2 items, after the 7:04 PM version-only attempt was cancelled)
- [x] Content Rights answered (Yes — third-party content, rights held; ENABLE is public domain)
- [x] App price set (Free, USD base)
- [x] Submitted for review 2026-10-05 7:13 PM — version + IAP `WAITING_FOR_REVIEW`
- [ ] After approval: press Release (Manual Release)
