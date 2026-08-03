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
| Auth → Google / Apple buttons | "arrives with the hosted backend" |

- [x] More → About WordFeast now opens a real screen instead of a toast
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
- [ ] Create the hosted Supabase project and `supabase db push` (migrations `0001`–`0003`)
- [ ] Rotate `SUPABASE_DB_PASSWORD` — it has sat in plaintext in `.env`
- [ ] Verify RLS on every table against an anonymous session

---

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
