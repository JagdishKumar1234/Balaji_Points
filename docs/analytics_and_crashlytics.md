# Firebase Analytics and Crashlytics

Added on branch `release/1.1.2`. This explains what is tracked, how personal data is protected, and the one-time console and Play Store steps.

## What is collected

### Screens
Every screen view is logged automatically from the route pattern, for example `home`, `wallet`, `add_bill` or `admin_carpenter_profile`. Real ids are never part of a screen name.

### Events

| Event | When | Details sent |
|---|---|---|
| `login` | Successful login | `method`: `pin`, `email` or `google` |
| `sign_up` | New account | `method`: `email` or `google` |
| `logout` | Logout | – |
| `bill_submitted` | Bill sent | `amount`, `submitted_by`: `member` or `admin` |
| `bill_approved`, `bill_rejected`, `bill_withdrawn` | Admin bill actions | – |
| `daily_spin` | Spin completed | `points` |
| `image_opened` | Offer or bill photo opened full screen | – |
| `celebration_popup_shown` | Diwali popup shown | – |
| `update_prompt_shown` | Update prompt shown | `forced`: 1 or 0, `to`: version |
| `setting_changed` | Theme or language changed | `setting`, `value` |

### User properties
`role`, `branch_id` and `app_language`. Use these to split any report by branch or role.

### Crashes and errors
- **App crashes:** all Flutter and async crashes are sent as fatal.
- **Handled errors:** every `AppLogger.error(...)` in the app (about 170 places) is sent as a non-fatal issue, with its message as the reason.
- **Breadcrumbs:** navigation, update-check and warning lines are attached to each crash, so you can see what the user did just before it.

## Personal data protection

- **Phone numbers and emails are removed** from every event, error and breadcrumb before sending.
- **Users are identified only by a one-way hash** of their account id. Some older account ids are phone numbers, so the real id is never sent.
- **No names, PINs or bill photos are sent.**
- **Debug builds send nothing**, so testing never mixes into live reports.

All of this is in `lib/services/telemetry/telemetry.dart` and covered by `test/telemetry_test.dart`.

## One-time setup

### 1. Firebase Console
1. **Crashlytics:** Firebase Console > **Crashlytics**. If it shows a setup screen, click **Enable Crashlytics**.
2. **Analytics:** Project settings > **Integrations** > **Google Analytics** should show it as linked. The web config already has a measurement id, so it is very likely on already.

### 2. Play Console: Data safety form (required before the next upload)
App content > **Data safety**: update the form to say the app now collects:

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Crash logs | Yes | No | App functionality, Analytics |
| Diagnostics | Yes | No | App functionality, Analytics |
| App interactions | Yes | No | Analytics |
| Device or other IDs | Yes | No | Analytics |

The data is not linked to name, phone or email. Google may reject or pause the update if this form is not updated.

### 3. iOS (only if you ship iOS)
Crash reports on iOS need a dSYM upload step in Xcode: Runner > Build Phases > add a Run Script with
```
"${PODS_ROOT}/FirebaseCrashlytics/run" -gsp "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
```
Running `flutterfire configure` also adds this automatically.

## How to check it works

### Analytics (live view while testing)
```
adb shell setprop debug.firebase.analytics.app com.balaji.points
flutter run --dart-define=TELEMETRY_IN_DEBUG=true
```
Then open Firebase Console > Analytics > **DebugView** and use the app: screens and events appear within seconds. Afterwards, turn it off:
```
adb shell setprop debug.firebase.analytics.app .none.
```

### Crashlytics
1. Run a release build, or a debug build with `--dart-define=TELEMETRY_IN_DEBUG=true`.
2. Cause an error, for example add a bill with no internet.
3. Close and reopen the app. Reports are sent on the next launch.
4. Firebase Console > Crashlytics: the first report can take a few minutes to appear.

Normal reports from the Play build appear after the update goes live. Standard Analytics reports take up to 24 hours; DebugView is instant.

## Adding a new event

Add a method to `Telemetry` in `lib/services/telemetry/telemetry.dart` and call it where the action succeeds:
```dart
static void rewardRedeemed({required int points}) =>
    event('reward_redeemed', {'points': points});
```
Event and parameter names must be letters, digits and underscores, up to 40 characters, and must not start with `firebase_`, `google_` or `ga_`. Invalid names are dropped.
