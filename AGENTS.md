# Agent instructions

## Building an Android App Bundle (.aab)

When the user asks to build an AAB ("build .aab", "build ABB", "build app bundle", "Play Store build"), update the version everywhere **before** building:

1. Bump the version in `pubspec.yaml` (`version: <name>+<build>`):
   - Always increase the build number (`+N`) by 1. Google Play rejects any upload whose versionCode is not higher than the previous one.
   - Bump the patch part of the version name (`1.0.0` → `1.0.1`) unless the user asks for a minor/major bump or gives an exact version.
2. Set `_appVersion` in `lib/widgets/settings_dialog.dart` to the same version name, so the version shown in Settings matches the build.
3. Android `versionCode`/`versionName` come from `pubspec.yaml` through `android/app/build.gradle.kts` (`flutter.versionCode`/`flutter.versionName`). Do not hard-code them there.
4. Search for any other hard-coded copy of the old version string and update it too. Do not touch `js/database.js` `db.version(...)`; that is a storage schema version, not the app version.
5. Run `flutter analyze` and `flutter test`, then `flutter build appbundle --release`.
6. Report the old and new version (`name+build`), the AAB path (`build/app/outputs/bundle/release/app-release.aab`), and its size.

Release signing: if `android/key.properties` does not exist or the `release` build type still uses `signingConfigs.getByName("debug")`, warn the user that Google Play will reject the bundle because it is debug-signed. Ask before creating or changing keystores or signing config, and never commit keystores or `key.properties`.

## Testing

- Do not launch an emulator; the user tests on a physical phone.
- After changes, run `flutter analyze` and `flutter test` before building.

## Google Sign-In Visibility

- For the current release, Google Sign-In is **hidden from the screen** on the login page (`lib/screens/login_screen.dart`).
- **Do not delete or remove the underlying functionality**: all backend methods (`_handleGoogleSignIn`, `_buildGoogleSignInButton`, `AuthService.instance.signInWithGoogle`, Google auth providers, etc.) must remain completely intact.
- It is toggled by `_showGoogleSignIn` in `lib/screens/login_screen.dart`. Only unhide it from the screen when the user explicitly instructs to do so.
