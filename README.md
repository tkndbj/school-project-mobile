# School Platform — mobile app

Flutter app (Android & iOS) for **school staff** and **parents**. The backend
is the Supabase project defined in the web repository
(`../school-project-web/supabase`); its API contract — tables, RPC functions,
storage layout, error codes — is documented in
`../school-project-web/docs/database.md`.

| Side | Who | What |
| --- | --- | --- |
| Parent | guardians linked to students | children, profile, grades (published only), attendance, notes shared with parents, events, courses & teachers |
| School | school admins & staff | dashboard, students (search, create, edit), daily attendance, quick notes, events |

Platform administration, grade books, imports, custom fields and school
settings are web-only; the app points users there.

## Requirements

- Flutter 3.41+ (Dart 3.11+)
- A Supabase project (local: `npx supabase start` in the web repo, needs Docker)
- Google Cloud OAuth clients when enabling Google sign-in (optional for email/password accounts)

## Configuration

All configuration is compile-time (`--dart-define-from-file`). Copy the
example and fill it in — real env files are git-ignored:

```bash
cp env/example.json env/dev.json
```

| Key | Value |
| --- | --- |
| `SUPABASE_URL` | Project URL. Android emulator → local stack: `http://10.0.2.2:54321` |
| `SUPABASE_PUBLISHABLE_KEY` | Publishable (`sb_publishable_…`) key. Never the secret key. |
| `GOOGLE_WEB_CLIENT_ID` | Optional OAuth client of type **Web application** (also configured in Supabase); omit to hide Google sign-in |
| `GOOGLE_IOS_CLIENT_ID` | OAuth client of type **iOS**, required only for native Google sign-in on iOS |
| `WEB_BASE_URL` | Web app base URL (password reset, `DELETE /api/account`) |

A build without valid configuration shows a "configuration missing" screen
listing every problem instead of crashing.

### Google sign-in

Sign-in is native (`google_sign_in` 7) and exchanges the Google ID token for a
Supabase session with `signInWithIdToken`.

1. Google Cloud Console → APIs & Services → Credentials, create:
   - **Web application** client → `GOOGLE_WEB_CLIENT_ID`. Add it (and its
     secret) to Supabase: Authentication → Providers → Google. Locally this is
     `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID/SECRET` (see web repo).
   - **Android** client: package `com.schoolproject.app` and the SHA-1 of every
     signing key (debug: `cd android && ./gradlew signingReport`; release: the
     upload key **and** the Play App Signing key).
   - **iOS** client: bundle id `com.schoolproject.app` → `GOOGLE_IOS_CLIENT_ID`.
2. iOS: add the iOS client's **reversed client id**
   (`com.googleusercontent.apps.…`) as an additional entry under
   `CFBundleURLSchemes` in `ios/Runner/Info.plist`.
3. In Supabase → Google provider, add the Android and iOS client ids to
   "Authorized Client IDs" so their ID tokens are accepted.

### Password reset

Staff use email + password (accounts are created by invitation from the web
panel; there is no public sign-up). "Forgot password" sends Supabase's
recovery email; the link opens the web app (`WEB_BASE_URL`), where the new
password is chosen. `WEB_BASE_URL` must be in Supabase's redirect allow-list.

## Running

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

## Quality gates

```bash
dart format --set-exit-if-changed lib test
flutter analyze            # very_good_analysis, strict casts/inference/raw types
flutter test               # unit, provider and widget tests
```

Localization files are generated from `lib/l10n/*.arb` on `pub get` /
build (`flutter gen-l10n` to regenerate manually). A test enforces that
Turkish translates every English key with the same placeholders.

## Architecture

```
lib/
  main.dart                 bootstrap: config → Supabase + preferences → ProviderScope
  l10n/                     ARB files (en, tr) + generated AppLocalizations
  src/
    app.dart                MaterialApp.router (themes, locale, router)
    core/
      config/               AppConfig (dart-defines, validated) + error screen
      domain/enums.dart     Dart mirrors of the Postgres enums
      errors/               AppFailure (sealed) + localized messages
      l10n/                 enum → label helpers
      locale/               persisted language choice
      media/                signed URLs for the private `school-media` bucket
      routing/              routes, pure redirect logic (RouteGate), GoRouter
      theme/                Material 3 light/dark + school brand colors
      utils/ widgets/       JSON helpers, formatting, shared UI states
    features/
      auth/        data (AuthRepository, Google gateway) · presentation (sign-in)
      account/     domain (AccountContext) · data · application (routing state) · presentation
      parent/      domain · data (guardian_* RPCs) · application · presentation
      school/      domain · data (RLS-protected tables) · application · presentation
      settings/    presentation
```

Principles:

- **The database is the security boundary.** Row-level security and the
  guardian functions decide what each user sees; the app never filters data
  for security reasons. Parents use only the `guardian_*` RPCs.
- **Layering:** widgets → providers (Riverpod 3) → repositories → Supabase.
  Widgets never call Supabase. Repositories throw only `AppFailure`s, which
  map the documented database error codes (`42501`, `SC001`–`SC030`,
  `23505`, …) to typed failures and localized messages.
- **Routing** is derived from a single `RouteGate` (signed out / loading /
  ready + account context + chosen side). `resolveRedirect` is a pure,
  unit-tested function. After sign-in the app calls
  `link_my_guardian_records` and `my_account_context`.
- **Models** are immutable with hand-written `fromJson` using strict
  accessors that fail loudly on contract drift; unknown enum values from newer
  backends are tolerated where safe.
- Riverpod's automatic retry is disabled; errors show an explicit retry.

### Tests

`test/helpers/fake_backend.dart` runs a real `SupabaseClient` against a
scripted HTTP client, so repository tests verify the actual PostgREST
requests (filters, pagination, RPC parameters such as `save_attendance` entries) and
error parsing.

## Release checklist

1. **Decide the final application id / bundle id before the first store
   upload** — it can never change afterwards. Currently `com.schoolproject.app`
   (Android `applicationId`/`namespace` in `android/app/build.gradle.kts`,
   Kotlin package of `MainActivity`, iOS `PRODUCT_BUNDLE_IDENTIFIER`, the deep
   link scheme in `AndroidManifest.xml`/`Info.plist`, and the Supabase
   redirect allow-list in the web repo's `supabase/config.toml`).
2. Android: create an upload keystore, copy `android/key.properties.example` to
   ignored `android/key.properties` and fill in its private values. Release
   builds require this configuration and do not use the debug signing key.
   Configure `signingConfigs.release`
   (keep the keystore and passwords out of git), enable Play App Signing, add
   both SHA-1s to the Google Android OAuth client.
3. iOS: set the team, enable Sign in with Apple only if you add it (Apple
   requires it when offering other third-party logins on iOS — **review this
   before App Store submission**), add the reversed client id URL scheme.
4. Production `env/prod.json` with the production Supabase project and web URL.
5. App icons, splash screen, store listings, privacy policy URL and data-safety
   / privacy nutrition labels (the app processes children's data: name, school
   records; no tracking, no ads).
6. Account deletion is available in Settings (required by both stores); it
   calls `DELETE {WEB_BASE_URL}/api/account`.
7. Build with obfuscation: `flutter build appbundle --obfuscate
   --split-debug-info=build/symbols --dart-define-from-file=env/prod.json`
   (keep the symbols for crash symbolication).

## Reproducible Android releases

Use Flutter 3.41.6, matching CI. Release configuration contains public values only:
copy env/example.json to ignored env/prod.json, use the hosted Supabase project
and final HTTPS Vercel domain, and omit unconfigured Google client IDs.

```text
dart run tool/validate_release_config.dart env/prod.json
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env/prod.json
```

The signed Android workflow runs manually in the protected production environment.
Configure MOBILE_PRODUCTION_CONFIG, ANDROID_UPLOAD_KEY_BASE64 and
ANDROID_UPLOAD_PASSWORD as GitHub environment secrets. It builds an AAB and keeps
symbol files for crash symbolication. The upload alias is upload. Keep the upload
keystore and android/key.properties backed up outside Git; losing the upload key
requires a Play Console reset. No signing passwords or keystores are committed.

iOS signing and archive validation require macOS/Xcode and your Apple Developer
team. Production SMTP, OAuth (if enabled), monitoring, privacy/store metadata and
backups are deployment settings described in the web repository's production
guide. The current product uses refresh-based records; push delivery and offline
editing are not advertised features.
