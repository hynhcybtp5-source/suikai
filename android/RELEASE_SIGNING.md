# Android release signing

Suikai uses an **upload key** for Android release builds. Enrol the app in
Google Play App Signing when creating its Play Console release; Google then
holds the app-signing key and this local upload key signs each uploaded AAB.

## One-time setup

Run this command from a secure local machine. Choose and store the passwords
yourself; do not place them in source control, chat, or issue trackers.

```sh
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Copy `android/key.properties.example` to `android/key.properties`, then set:

```properties
storeFile=../upload-keystore.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

Keep the keystore and its passwords in controlled backup storage. Losing the
upload key requires an upload-key reset in Play Console. Neither
`android/key.properties` nor `*.jks`/`*.keystore` is tracked by Git.

## Build

Use the local ignored `dart_defines.json` for Supabase and legal release
configuration:

```sh
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

Set these legal values in that local file before production release:

```json
{
  "SUIKAI_PRIVACY_POLICY_URL": "https://suikai-897bb.web.app/privacy-policy",
  "SUIKAI_TERMS_URL": "https://suikai-897bb.web.app/terms-of-service",
  "SUIKAI_COMMUNITY_GUIDELINES_URL": "https://suikai-897bb.web.app/community-guidelines",
  "SUIKAI_DELETE_ACCOUNT_URL": "https://suikai-897bb.web.app/delete-account",
  "SUIKAI_SUPPORT_EMAIL": "suikai.app@gmail.com"
}
```

The release build intentionally fails with a clear error if the signing file,
keystore, or any required signing field is missing. Debug builds do not need
these files.
