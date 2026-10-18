# Testing the mobile and web applications

Use a separate development/staging Supabase project for test records. Production
owner accounts and schools are provisioned through the web administration flow,
not through test fixtures. See ../school-project-web/docs/vercel.md for deployment.

## Repeatable setup

The shared backend and the school/parent web portal are in
`../school-project-web`. Start there: its README describes hosted Supabase
configuration, migrations and demo accounts. Both clients must point at the same
Supabase project, with every migration applied before testing updated clients.

Create `env/dev.json` from `env/example.json` and use only the project's
publishable key. Google client IDs may be blank for password-only testing.
`WEB_BASE_URL` must be reachable from the test device: for the Android emulator
use `http://10.0.2.2:3000`; for a physical phone use your computer's LAN address or
an HTTPS web deployment. A phone's `localhost` means the phone itself.

```text
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

If Flutter reports missing Android SDK licences, run
`flutter doctor --android-licenses` and accept only if you agree to the terms.
Start an Android emulator in Android Studio or connect a phone with USB debugging
enabled. The Android toolchain must be healthy before building an installable APK.

The website can generate isolated demo accounts with:

```text
npm run test:seed -- --allow-hosted
```

Use a dedicated hosted test project and set ALLOW_TEST_FIXTURES=true only there. Passwords are random and stored only in the
web directory's ignored `.demo-credentials.json`. Sign in using the same admin or
parent account in the mobile app and web app.

1. Staff: search/create/edit a student, record attendance and add a shared note.
2. Web: link that student to a guardian, enrol them in a course, enter a draft
   grade, then publish it. Add a parent-visible event.
3. Parent: verify the child profile, published grade, attendance, shared note,
   course/teacher and event. Refresh after saving changes in the other client.
4. Confirm that unpublished grades, staff-only notes and another parent's child
   remain invisible. Try the invite-code flow with an unlinked parent account.
5. Test both English and Turkish, loading/error/retry states, sign-out, password
   recovery and account deletion. Deleting the last administrator is refused.

Validation:

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=env/dev.json
```

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`. Install it with
`flutter install` or Android's adb. An APK built without dart-defines opens the
configuration-missing screen; rebuild with `env/dev.json` before live testing.

iOS builds and signing require macOS/Xcode. Push delivery, crash-reporting
integration, store assets and production infrastructure still require their own
configuration. See `../school-project-web/docs/production.md` for release gates
and measured limits; passing local tests does not establish a production SLA.
