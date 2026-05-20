# Hiraal Chronic Care

Flutter mobile app for chronic care patient monitoring, offline-first vital capture, reminders, notifications, and clinic workflows.

## Current Production Scope

- Offline-first capture for blood pressure and blood glucose readings.
- Local persistence with SQLite and deferred sync support.
- Profile, settings, notifications, booking, and patient detail flows.
- Android release hardening with minification, resource shrinking, and external signing configuration.

Not included in the current production-ready baseline:

- Real ERPNext service implementations.
- Real medical device integrations.

## Environment Configuration

The app uses `--dart-define` values instead of hardcoded environment switches.

Supported defines:

- `APP_ENV=development|staging|production`
- `USE_MOCK=true|false`
- `BASE_URL=https://emr.hiraalhealth.so`
- `ENABLE_CRASH_REPORTING=true|false`
- `SENTRY_DSN=...`
- `ENABLE_VERBOSE_LOGGING=true|false`

Example development run:

```powershell
flutter run \
	--dart-define=APP_ENV=development \
	--dart-define=USE_MOCK=true \
	--dart-define=ENABLE_VERBOSE_LOGGING=true
```

Example release build:

```powershell
flutter build apk --release \
	--dart-define=APP_ENV=production \
	--dart-define=USE_MOCK=true \
	--dart-define=BASE_URL=https://emr.hiraalhealth.so \
	--dart-define=ENABLE_CRASH_REPORTING=false
```

## Android Release Signing

Create `android/keystore.properties` from `android/keystore.properties.example` and fill in your real values.

Example file:

```properties
storeFile=../keys/hiraal-release.jks
storePassword=change-me
keyAlias=hiraal
keyPassword=change-me
```

When `android/keystore.properties` is present, the Android release build uses that keystore automatically. If it is missing, Gradle falls back to debug signing so local release smoke builds still work.

## Crash Reporting

Crash reporting is optional and disabled by default. To enable Sentry:

```powershell
flutter run \
	--dart-define=ENABLE_CRASH_REPORTING=true \
	--dart-define=SENTRY_DSN=your-dsn-here
```

## Session Handling

- Session inactivity timeout is 30 minutes.
- The app tracks last activity locally and shows the session-expired screen when needed.
- User-initiated logout clears all local data.
- Session expiry keeps unsynced readings on-device and clears the authenticated patient session.

## Verification Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=APP_ENV=production --dart-define=USE_MOCK=true
```

## Remaining Release Blockers

Before shipping to real users, complete these items:

1. Implement the ERPNext-backed service layer and set `USE_MOCK=false`.
2. Provide a real Android release keystore.
3. Configure a production Sentry DSN if crash reporting is required.
4. Add backend-integrated tests for auth, sync, and booking flows.
