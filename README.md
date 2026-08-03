# WGN Mobile

WordFeast Gospel Network mobile app — Flutter + Supabase. Implements the
"WGN App" Claude Design spec: audio sermons with offline downloads and
background playback, Daily Feast devotionals with reading streaks, live
services (YouTube), events, testimonies, prayer requests, giving, the
Journal, updates, and a member profile with QR check-in. Dark and light
themes.

## Run it (local dev)

Prereqs: Flutter 3.44+, Docker, Supabase CLI.

```sh
supabase start          # local backend (applies migrations + seed data)
flutter run             # iOS simulator or Android emulator
```

The app points at the local Supabase stack by default
(`http://127.0.0.1:54321`, or `10.0.2.2` on Android emulators). For a hosted
Supabase project:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable key>
```

Push the schema to a hosted project with `supabase link` + `supabase db push`.

Dev sermon audio: seeded rows reference files `1.m4a` … `10.m4a` in the
`sermon-audio` storage bucket. Upload real recordings there (or any sample
audio) — filenames must match `sermons.audio_path`.

## Architecture

- `lib/core` — design tokens (`WgnColors`), typography (Manrope / Instrument
  Serif / JetBrains Mono), shared widgets (placeholder art, chips, toggles,
  toast).
- `lib/data` — models, Supabase repositories (Riverpod providers), per-user
  state (likes, saves, reads, playback) with optimistic sync.
- `lib/services` — audio player (`just_audio` + `audio_service`), download
  manager (`dio` + `sqflite`), local prefs.
- `lib/features` — one folder per screen; `shell/` owns the bottom nav,
  drawer and mini-player.
- `supabase/` — migrations, seed data, config. Staff manage content through
  Supabase Studio (`http://127.0.0.1:54323` locally).

Auth is guest-first: every install gets an anonymous Supabase session;
creating an account upgrades that session in place (email link), keeping
streaks, likes and registrations.

## Tests

```sh
flutter test            # streak + sermon filter/sort logic
flutter analyze
```

## What's deferred (by design)

Paystack/Flutterwave rails show "coming soon" (bank transfer sheet is live), Google/Apple buttons activate once you have a hosted Supabase project with OAuth keys, and share sheets are stubbed with toasts. When you're ready to go hosted: create the project, supabase link + supabase db push, upload real sermon MP3s to the sermon-audio bucket, and pass the URL/key via --dart-define (details in the README).
