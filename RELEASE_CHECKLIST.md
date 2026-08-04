# Release checklist — WGN Mobile

Audited 3 Aug 2026 against:
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios)
- [Flutter Android deployment](https://docs.flutter.dev/deployment/android)

Items marked [x] are done and verified. The remaining work splits into things
that need the church (artwork, nonprofit status, legal review) and things that
need credentials only you should hold (keystore password, hosted Supabase).

---

## A. Store-policy blockers

These apply to **both** stores unless marked. Apple guideline numbers in brackets;
Google Play has an equivalent policy for each.

### A1. Placeholder artwork throughout [2.1 App Completeness]

Every image is the striped `PhPlaceholder`, several with literal captions:
`SERMON ARTWORK`, `EVENT FLYER`, `LIVE VIDEO FEED`, `DEVOTIONAL IMAGE`.

- [ ] Artwork columns + Storage buckets for sermons, events, devotionals, journal, updates
- [ ] Swap `PhPlaceholder` for `CachedNetworkImage`; keep the striped fill as loading/error state only
- [ ] Delete the placeholder caption labels

### A2. Non-functional and stubbed features [2.1]

| Where | Current behaviour |
|---|---|
| Giving → Paystack / Flutterwave | Rails labelled "coming soon"; CTA fires a toast |
| Reader + Testimonies → share | "Sharing comes with the next build" |
| More → Serve on a team | "Volunteer form opens in browser" — opens nothing |
| Profile → Giving history | "arrives with online giving" |

- [x] More → About WordFeast now opens a real screen instead of a toast
- [x] Profile → Personal details / Home branch now open an edit sheet for signed-in members instead of re-presenting the auth sheet. Name and branch are editable; email is deliberately read-only, since changing it is an auth operation that mails both addresses (`double_confirm_changes`) and needs its own flow
- [x] Auth → Google / Apple are now real sign-ins (native ID-token flow, see section B). Each button is hidden unless its provider is configured for the build, so an unconfigured deployment shows fewer routes rather than ones that can only fail — no toast stub remains
- [ ] Ship each remaining row working, or remove it
- [ ] Replace dev audio (placeholder `say`-generated m4a) with real recordings

### A3. Account deletion — DONE (in-app), web URL outstanding

- [x] "Delete account" in Profile → confirmation sheet → `delete_account` RPC (migration `0002`)
- [x] Server-side cascade verified against local Postgres: profile, likes, saves, registrations, amens, playback, reads and prayers all cascade from `auth.users`; testimonies are deleted explicitly because they were `on delete set null` and would otherwise stay published as orphans
- [x] Verified end-to-end in the simulator — deleting a guest account issues a new member code
- [ ] **Google Play additionally requires a publicly reachable web URL** for deletion requests. Wire it into `app_config.about.delete_account_url` (the About screen already renders the row when set) and declare it in the Play Data safety form

### A4. User-generated content has no safety controls [1.2]

Testimonies are a public feed; prayer requests are private. `testimonies.approved`
already defaults to false, which covers pre-moderation. Missing:

- [ ] Report/flag control on every testimony
- [ ] Block-user mechanism
- [ ] EULA / terms acceptance at first post, with a no-tolerance clause
- [ ] In-app contact route for takedowns
- [ ] Documented moderation turnaround

### A5. Privacy policy — drafted, needs legal review + publishing [5.1.1(i)]

- [x] Draft at `docs/privacy-policy.md` covering collected data, Supabase and YouTube as processors, UGC handling, retention and deletion
- [x] About screen built (More → About WordFeast), replacing the old toast stub; renders Website / Contact / Privacy policy / Terms / Delete-account rows, each hidden until its URL is set so no dead links ship
- [ ] **Have someone qualified review the draft** against NDPA 2023, and GDPR if you have EU/UK members; fill in operator name, contact address and retention period
- [ ] Publish at a stable URL, then set `app_config.about.privacy_policy_url` and `terms_url`
- [ ] Add the same URL to both store consoles

### A6. Donations [3.2.1(vi)]

Exempt from IAP and Play Billing as charitable giving, but Apple gates it on approval.

- [ ] Confirm registered nonprofit status; submit to Apple for approval
- [ ] Add Apple Pay (Apple requires it for in-app fundraising)
- [ ] Disclose use of funds per purpose; issue tax receipts
- [ ] Confirm Nigerian charitable-solicitation compliance

---

## B. Backend — blocks both platforms

- [x] `lib/data/supabase_client.dart` now **throws in release** if `SUPABASE_URL` / `SUPABASE_ANON_KEY` are missing, instead of silently falling back to localhost. Debug/profile still use the local CLI stack
- [x] Android `usesCleartextTraffic` moved from the main manifest to the **debug** source set. Verified in the merged manifests: present in debug, absent in release
- [x] iOS `NSAllowsLocalNetworking` **kept, deliberately** — correcting my earlier advice. Unlike Android's blanket flag it only permits cleartext to `.local`, unqualified hostnames and private IP ranges, never the public internet. Apple documents it as the sanctioned way to reach a local dev server and it needs no ATS justification at review
- [x] Hosted project created and linked (`njngkpcdyohwqzmbepky`, eu-west-1). Migrations `0001`–`0003` are applied — verified over REST: `sermons` returns 200 and `app_config` holds all four keys
- [x] Build-time configuration split into **`.env.app`**, consumed with `--dart-define-from-file`. `.env` keeps `SUPABASE_DB_PASSWORD` for the CLI and psql; `.env.app` holds only what is safe to compile into a shipped binary, since dart-defines survive in the APK and are readable with `strings`. `.env.app.example` is the committed template; both real files are gitignored
  ```
  flutter run                --dart-define-from-file=.env.app
  flutter build appbundle    --dart-define-from-file=.env.app
  ```
  The VS Code launch config passes it too. A run *without* it still falls back to the local `supabase start` stack in debug, and still throws in release
- [x] `supabase db push` applied migration `0004_account_merge.sql` (guest → account carry-over, below). Verified on the hosted database: both functions exist, `account_merge_tokens` has RLS on, and neither `anon` nor `authenticated` holds any grant on it
- [ ] `supabase db push` migration `0005_profile_name_from_metadata.sql` — seeds `profiles.full_name` from the sign-up metadata inside the trigger. The app's own follow-up write needs a session, and two routes don't have one: email sign-up with confirmations required (gotrue returns no session at all) and Google/Apple, where the name arrives in the ID token. Without it those sign-ups land a profile with a null name
- [ ] Rotate `SUPABASE_DB_PASSWORD` — it has sat in plaintext in `.env`, so treat it as already disclosed
- [ ] Verify RLS on every table against an anonymous session

### B1. Anonymous sign-ins are OFF on the hosted project — blocks everything

`GET /auth/v1/settings` reports `"anonymous_users": false`. The app is
guest-first: `main.dart` calls `signInAnonymously()` at startup and every
per-user table keys off that session, so **before** signing in, likes, streaks,
saved devotionals, prayer requests and playback progress all silently do
nothing until this is on. `supabase/config.toml` already sets
`enable_anonymous_sign_ins = true`, but that governs the local stack only — the
hosted project is configured separately.

Signing in and creating an account do now work without it: the auth sheet falls
back to `signUp` when there is no guest session to upgrade. That fallback stops
the app dead-ending on "Auth session missing!", but it is a safety net, not a
substitute — with anonymous sign-ins off, everything a visitor does before
creating an account is still discarded, and migration `0004` has nothing to
carry over.

- [ ] Dashboard → Authentication → Sign In / Providers → enable **Anonymous sign-ins**
- [ ] Consider enabling CAPTCHA alongside it, as Supabase recommends, since anonymous sign-up is an unauthenticated write path. `[auth.captcha]` in `config.toml` is where the local equivalent lives

Do **not** reach for `supabase config push` to do this. It is all-or-nothing —
it would also push `site_url = "http://127.0.0.1:3000"` and the local rate
limits to production, breaking password-reset and confirmation links. Until
`config.toml` is made production-accurate, the dashboard is the only safe route
for auth settings.

### B2. Google sign-in — code shipped, credentials outstanding

Implemented natively in `lib/features/auth/social_auth.dart`: the Google SDK
returns an OIDC ID token and `signInWithIdToken` exchanges it. There is no
browser round trip, so **no redirect URL or deep-link scheme is involved**.

- [ ] Google Cloud → APIs & Services → Credentials, create three OAuth client IDs:
  - **Web** — this is the audience Supabase validates against. Its value goes in `.env.app` as `GOOGLE_SERVER_CLIENT_ID`, on *every* platform
  - **iOS** — bundle ID `com.wordfeastgn.wgnmobile`. Goes in `.env.app` as `GOOGLE_IOS_CLIENT_ID`
  - **Android** — package `com.wordfeastgn.wgnmobile` plus the signing-certificate SHA-1. Register **both** the upload key (section D) and the Play App Signing key, or sign-in works in internal testing and fails in production
- [ ] `ios/Runner/Info.plist` → replace `com.googleusercontent.apps.REPLACE-WITH-REVERSED-IOS-CLIENT-ID` with the iOS client ID's parts reversed
- [ ] Dashboard → Authentication → Providers → Google: enable, and put all three client IDs in **Authorized Client IDs**
- [ ] Fill `GOOGLE_SERVER_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` in `.env.app`. Until then the Google button does not render

### B3. Apple sign-in — code shipped, Apple-side setup outstanding

Same native path, via `sign_in_with_apple`, with a nonce: the SDK is handed the
SHA-256 hash and Supabase the raw value, so a captured token cannot be replayed.
Shown on iOS and macOS only — Android would need a Services ID and a web
redirect flow the app does not carry.

- [x] `ios/Runner/Runner.entitlements` created with `com.apple.developer.applesignin`, and `CODE_SIGN_ENTITLEMENTS` wired into the Runner target's Debug, Release and Profile configurations
- [ ] developer.apple.com → the App ID `com.wordfeastgn.wgnmobile` → enable the **Sign in with Apple** capability. Signing fails with a provisioning error until this matches the entitlement
- [ ] Dashboard → Authentication → Providers → Apple: enable, and set **Authorized Client IDs** to `com.wordfeastgn.wgnmobile`. The native flow needs no secret; a Services ID and key are only required if a web or Android redirect flow is added later
- [ ] Note for review: guideline 4.8 requires Sign in with Apple *because* Google sign-in is offered. Both must ship, or neither

### B4. Guest → account carry-over (migration `0004`)

The email path upgrades the anonymous session in place with `updateUser`, so
the user id never changes. An ID-token sign-in cannot do that — gotrue has no
"link this token to the session I already hold" call — so Google and Apple land
on a *new* user id, and a guest's streak, saves, registrations, prayers and
testimonies would be stranded on the abandoned account. That would break the
promise the sign-up sheet itself makes.

`0004_account_merge.sql` moves them, gated on a single-use one-hour token
issued while still authenticated as the guest and redeemed as the signed-in
user. Neither RPC takes a user id as an argument — otherwise
`merge(someone_elses_uid)` would be a data-theft and account-deletion
primitive.

- [x] Verified against local Postgres: all eight tables carry over, likes dedupe, playback keeps the furthest position, the testimony is reassigned rather than orphaned, profile gaps fill from the guest, and the guest auth row is deleted. Rejected as expected: a non-guest issuing a token, an unknown token, a replayed token, and `authenticated` reading the token table directly
- [ ] Walk it once on a device after B1 and B2/B3 are done: browse as a guest, like a sermon and read a devotional, then sign in with Google and confirm the streak and the like survived

---

### B5. Email confirmation — decided OFF

**Decision: turn email confirmation off on the hosted project**, matching the
local `enable_confirmations = false`. Sign-up then completes in one step on
both routes, and the app never has to represent a half-made account.

- [ ] Dashboard → Authentication → Sign In / Providers → Email → turn
      **Confirm email** off. Same screen as the anonymous sign-ins toggle in
      B1, so do both in one visit. It cannot be done from the CLI for the
      reason given in B1

Verified against gotrue 2.193 with the flag off — both routes end clean, with
`is_anonymous` false, the address on the user, and `email_confirmed_at` set:

| | guest → `updateUser` | no session → `signUp` |
|---|---|---|
| session afterwards | valid, same user id | returned immediately |
| `is_anonymous` | `false` | `false` |
| can sign in elsewhere? | yes | yes |

What this buys, beyond the simpler flow: local and hosted stop diverging, so
auth bugs reproduce on a laptop instead of only in production; the missing
"resend confirmation" control is no longer a gap; and SMTP stops being on the
sign-up critical path.

**What it costs.** `profiles.email` is no longer proof of anything — anyone can
sign up with an address they do not own. Nothing today emails members, so the
practical impact is small, but two items downstream assume otherwise: tax
receipts for giving (A6) and any future takedown-contact route (A4). Revisit
this before either ships.

- [ ] SMTP (`[auth.email.smtp]`) is still needed for **password reset**, just
      no longer for sign-up. Supabase's built-in sender is rate-limited to a
      handful of messages an hour and is not for production
- [ ] With the flag off, a mistyped address silently costs the member their
      only recovery route. Consider validating the address format in the sheet

The app keeps handling the confirmation-required case even so: the sheet still
detects a session-less `signUp` and `isGuestProvider` still reads `new_email`.
That path is inert while the flag is off, and it is deliberately kept — the
flag is one dashboard click, confirmation is Supabase's default for a new
project, and both regressions it prevents are silent: sign-up that claims
success while nobody is signed in, and a signed-in member shown "Browsing as a
guest".

## C. iOS build config

- [ ] **App icon is still the stock Flutter logo** — confirmed by hash. See the shared icon blocker below
- [ ] Launch screen is Flutter's default blank `LaunchImage` — replace with branded artwork
- [ ] `CFBundleDisplayName` is **"Wgnmobile"** → "WGN Mobile" (Android already reads correctly, so this is an asymmetry)
- [ ] Xcode → Signing & Capabilities: set **Team**, confirm **Automatically manage signing**
- [ ] Register the explicit App ID `com.wordfeastgn.wgnmobile` on developer.apple.com
- [ ] Add app-level `PrivacyInfo.xcprivacy` to the Runner target (plugins already ship 42 of their own — only the app's is missing)
- [ ] Add `ITSAppUsesNonExemptEncryption` to stop the prompt on every upload
- [ ] Restrict to portrait, or build landscape/iPad layouts — iPad orientations are all enabled with no iPad design, and Apple reviews on iPad unless the app is iPhone-only
- [x] Deleted the stray `ios/Runner/Assets.xcassets/AppIcon 1.appiconset` (contained only `Contents.json`, zero references in the pbxproj)
- [x] Deployment target 13.0 — fine, matches Flutter's supported floor

---

## D. Android build config

The debug-key signing is fixed; what remains is generating the keystore itself,
which needs a password only you should hold.

- [x] `build.gradle.kts` now loads `android/key.properties` and uses a real `signingConfigs.release`. When the file is absent it logs a warning and leaves the build **unsigned** rather than falling back to debug keys — verified: `flutter build appbundle` succeeds, emits the warning, and produces an aab with no signature blocks (`jarsigner` reports "no manifest")
- [x] `.gitignore` now covers `android/key.properties`, `*.jks`, `*.keystore` and `build/symbols/`
- [x] Removed the leftover `// TODO: Specify your own unique Application ID` comment
- [ ] Create the upload keystore:
  ```
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
          -storetype JKS -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Create `android/key.properties` (`storePassword`, `keyPassword`, `keyAlias`, `storeFile`) — I can't do this step, it needs a password only you should know
- [ ] Back up the keystore somewhere durable and offline — losing it means you can never update the app under the same listing
- [ ] `flutter clean` after the signing change
- [ ] **Launcher icon is still the stock Flutter logo** across all five `mipmap-*` densities, and there is no adaptive icon. See the blocker below
- [x] `applicationId` confirmed correct at `com.wordfeastgn.wgnmobile`. **It cannot change after the first Play upload**
- [ ] Verify `targetSdk` resolves to Play's current minimum (35+). Flutter 3.44 defaults are fine; pin explicitly if you want to control the bump
- [ ] `android:label` is already "WGN Mobile" ✓ ; INTERNET + audio-service permissions are correct ✓
- [ ] R8 shrinking is on by default in release — no action, but expect longer builds
- [ ] Multidex not needed at `minSdk 24`

---

## E. Store listings

### Shared
- [ ] Privacy policy URL (from A5)
- [ ] Support / contact URL
- [ ] Demo account credentials + reviewer notes — guest mode covers browsing, but both reviewers need to test account features and deletion
- [ ] Content rights: confirm the church owns/licenses the recordings; confirm YouTube embeds are WordFeast's own channel [5.2.3]. KJV is public domain — no issue

### App Store Connect
- [ ] Apple Developer Program enrolment ($99/yr; fee waiver for approved nonprofits)
- [ ] App record + bundle ID association
- [ ] Screenshots: 6.9" and 6.5" iPhone
- [ ] Description, keywords, subtitle
- [ ] Age rating questionnaire — UGC raises the rating
- [ ] Privacy nutrition labels
- [ ] Export compliance

### Google Play Console
- [ ] Developer account ($25 one-time)
- [ ] **Data safety form** — mirrors the nutrition labels; include the account-deletion URL from A3
- [ ] Content rating (IARC questionnaire)
- [ ] Screenshots, feature graphic (1024×500), 512×512 hi-res icon
- [ ] Short + full description
- [ ] Target audience declaration

---

## F. Build and ship commands

```bash
# iOS — note it is `build ipa`, not `build ios`
flutter build ipa --obfuscate --split-debug-info=build/symbols/ios
# → build/ios/ipa/*.ipa ; upload via Transporter, Xcode Organizer, or:
#   xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey KEY --apiIssuer ISSUER

# Android — app bundle is the required format for Play
flutter build appbundle --obfuscate --split-debug-info=build/symbols/android
# → build/app/outputs/bundle/release/app-release.aab
```

- [x] Bumped `version:` in `pubspec.yaml` to `1.0.0+1`. Also replaced the hardcoded `WGN MOBILE · 1.0.0 (24)` string (a leftover from the design mock, which did not match pubspec) with a `package_info_plus` read, so the displayed version can no longer drift
- [ ] Keep the `build/symbols/` output — you need it to symbolicate production crashes from obfuscated builds
- [ ] Ship to **TestFlight** (internal testing) and a Play **internal testing** track before submitting for review

---

## Blocked: app icon artwork

Both platforms still ship the Flutter logo, and I cannot fix it from what's in
the repo. The only mark available is `assets/images/wgn-main-logo.png` at
**176×171 px**, with "WORDFEAST GOSPEL NETWORK" set as fine lettering around
the ring. Upscaling that to the 1024×1024 Apple requires would be visibly soft,
and the ring text turns to mush at 60px and below. Shipping it would look worse
than the Flutter default.

Already done so this is a one-command job once artwork exists:

- [x] `flutter_launcher_icons` added and configured in `pubspec.yaml` — generates the iOS `AppIcon` set *and* the Android mipmaps *and* the adaptive icon that is currently missing entirely
- [ ] **Supply a square master ≥1024×1024** at `assets/branding/wgn-icon-1024.png`, ideally exported from vector. Drop the ring lettering — icons are read at ~60px, so the dove/globe alone will carry it
- [ ] Supply `assets/branding/wgn-icon-foreground-1024.png` (dove/globe only, transparent) for the Android adaptive foreground; background is set to `#17101F`
- [ ] Run `dart run flutter_launcher_icons`
- [ ] Also needed for the listings: a 512×512 Play icon and a 1024×500 feature graphic

## Suggested order

1. **D signing + B backend** — Android literally cannot build a release today, and nothing is testable end-to-end without a hosted backend
2. **A3 + A5** — account deletion and privacy policy; small, self-contained, block both stores
3. **C + D icons** — both platforms still ship the Flutter logo; cheap to fix, embarrassing to miss
4. **A1** — real artwork; the largest chunk
5. **A4** — UGC safety controls
6. **A6** — donations; start Apple's nonprofit approval early, it gates the calendar
7. **A2** — finish or remove remaining stubs
8. **E + F** — listings, then TestFlight / internal track
