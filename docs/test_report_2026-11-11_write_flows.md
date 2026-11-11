# Balaji Points: write-flow and UI test report, 11 Nov 2026

Build: `release/1.1.2` (debug, test mode), Android emulator.
Data: a **private local copy of Firebase** (Firebase Local Emulator Suite) on the developer's computer. **No live data was read or changed by these tests.**

This report follows the view-only live test in [test_report_2026-11-11.md](test_report_2026-11-11.md), which could not test anything that creates data.

## Summary

- **Every flow that creates data was tested** on the private copy: bill submit, approve, reject, duplicate warning, offers per branch, daily spin per branch, greeting per branch and notifications. Branch isolation held everywhere: nothing from E Road reached Karur, and nothing from Karur reached E Road.
- **Points are correct.** Every approval credited points once, and rejections changed nothing. The points record and the user record always matched (12.5, then 14.5).
- **Testing found 8 bugs, and all 8 are fixed in code** (see Bugs found and fixed). The worst ones in live today:
  - Members with no working push token never see "Bill approved" or "Bill rejected" in the app.
  - The admin's daily spin list of eligible members is always empty.
  - Rejections are pushed twice.
- **Deployed 11 Nov 2026 (evening):** `processNotificationQueue` and `onBillStatusChanged` are live on Node 22 with fixes 1, 3 and 8. `onBillCreated` (fixes 4 and 5) is held back until its Firestore index exists. The app fixes reach users with the 1.1.2 update.
- **UI items fixed after the test:** the tab bar now hides while the keyboard is open, the bill timeline follows the bill's status, and the rank #1 confetti plays only for a real leader, once a day.
- **Not tested:** bill withdraw (no screen offers it), super admin "Reset" and Karur admin's own spin. See Not tested.

## How the test was run

| Item | Setting |
|---|---|
| Firebase | Local Auth, Firestore, Functions and Storage emulators (`firebase.json` `emulators` section) |
| App | Debug build with `--dart-define=USE_FIREBASE_EMULATORS=true`; a red **TEST MODE** strip shows on every screen; release builds refuse this mode |
| Rules | The real `firestore.rules`, loaded by the local Firestore |
| Functions | The real `functions/index.js`, run locally |
| Test data | `functions/scripts/emulator_seed.js` (refuses to run unless pointed at the emulators) |
| Push | Test accounts have fake push tokens, so every push "fails" by design; the test checks *who* each push is addressed to and that the in-app record is saved |

### Test accounts (local copy only)

| Role | Branch | Login |
|---|---|---|
| Carpenter | TEST E Road (`erode_main`) | 9000000001, PIN |
| Carpenter | TEST Karur (`karur_test`) | 9000000002, PIN |
| Branch admin | TEST E Road | 9000000003, PIN |
| Branch admin | TEST Karur | email |
| Super admin | – | email (local copy only) |

PINs and passwords are in the seed script and exist only on the local copy.

### Making the test match live

Live Firebase has anonymous sign-in turned off, but the local Auth emulator always allows it. With it on, PIN logins took a path live never takes: a copy of the user record that the rules then blocked for admins. Test mode now skips anonymous sign-in (`TestEmulators.blocksAnonymousSignIn`), so PIN logins behave exactly as in live. The only effect outside test mode: none (`enabled` is a build-time constant that is off in every normal build).

## Results by flow

✅ correct · 🔧 bug found and fixed · ⚠️ needs a decision · — not tested

### 1. Carpenter submits a bill

| Step | Expected | Seen | Result |
|---|---|---|---|
| E Road carpenter adds ₹12,500, site "Test Site" | Saved as pending, 12.5 points shown before submit | Pending, `branchId: erode_main`, "You will earn 12.50 points when approved" | ✅ |
| New-bill alert | Only E Road admin | Queued only for E Road admin; log tagged `erode_main` | ✅ |
| Karur admin | Sees nothing from E Road | 0 pending, no notifications | ✅ |
| Server check of a bill dated today | Accepted | Was marked "Bill date cannot be in the future" | 🔧 Bug 4 |
| Server duplicate check | New bill not matched against itself | Would have flagged every bill as a duplicate of itself | 🔧 Bug 5 |
| Same bill entered again | App warns before saving | "Duplicate bill detected" with site, amount, date; Cancel and "Add anyway" | ✅ |

### 2. Admin approves a bill

| Step | Expected | Seen | Result |
|---|---|---|---|
| E Road admin opens Pending Bills | 1 bill, 12.50 pts, ₹12,500 | As expected | ✅ |
| Confirm dialog | Amount and points | "Approve this bill of ₹12500? 12.50 points will be added" | ✅ |
| Bill record | approved, 12.5, approved by admin | As expected | ✅ |
| Points | +12.5 once | `user_points` 12.5, 1 history entry; user record 12.5 | ✅ |
| Second approval (₹2,000) | +2 once | 14.5 total, 2 history entries, both records match | ✅ |
| Push to member | Exactly one, to that member only | One `billApproved`, addressed to 9000000001 | ✅ |
| In-app "Bill approved" | In member's Notifications | Missing whenever the push failed | 🔧 Bug 1 |
| Dashboard | Counts update | Pending 0, bills this month 2 (1 approved), points issued 12.5 | ✅ |
| Member home | 12.5 points, 1987.5 to Silver, 1% | As expected | ✅ |

### 3. Admin rejects a bill

| Step | Expected | Seen | Result |
|---|---|---|---|
| Reject ₹8,000, then ₹3,000 | Status rejected, points unchanged | Rejected; points stayed 12.5 / 14.5 | ✅ |
| Push to member | One | Was **two** (app and server both sent one) | 🔧 Bug 3; after the fix: one |
| In-app "Bill rejected" | In member's Notifications | Shown once | ✅ (after Bug 1 fix) |

### 4. Offers per branch

Offer upload by an admin was tested earlier the same day (Karur offer saved with Karur's branch, push only to Karur's member). For the member check, three local offers were added: Karur only, E Road only, and one with no branch (super admin, all branches).

| Who | Should see | Saw | Result |
|---|---|---|---|
| Karur carpenter | Karur + all-branch | KARUR ONLY, ALL BRANCH | ✅ |
| E Road carpenter | E Road + all-branch | EROAD ONLY, ALL BRANCH | ✅ |

### 5. Daily spin per branch

| Step | Expected | Seen | Result |
|---|---|---|---|
| E Road admin opens Spin after an approval today | 1 eligible member | "No Eligible Carpenters Today" | 🔧 Bug 2; after the fix: "1 eligible, Erode Carpenter, +12.5" |
| Spin | Winner from E Road | "Winner: Erode Carpenter", next spin in 23h 59m | ✅ |
| Winner records | Tagged E Road, one per branch per day | `daily_prize_winners` with `erode_main`; `daily_winners/erode_main_2026-11-11` | ✅ |
| E Road member home | Today's winner shown | "Today's lucky winner: Erode Carpenter, selected via daily spin" | ✅ |
| Karur member home | No E Road winner | "No winner today · Spin not done yet" | ✅ |

### 6. Greeting per branch

| Step | Expected | Seen | Result |
|---|---|---|---|
| E Road admin sends "Test greeting for E Road" (home banner) | Saved with E Road | `greetings` record, `branchId: erode_main`, active | ✅ |
| Push | Only E Road members | Queued only for 9000000001 | ✅ |
| E Road member | Banner and inbox | "New announcement · Test greeting for E Road" on home and in Notifications | ✅ |
| Karur member | Nothing | No banner, empty inbox | ✅ |

### 7. Notifications inbox by role

| Who | Saw | Result |
|---|---|---|
| E Road carpenter | New announcement (greeting), Bill rejected. After the fix, the "Bill approved" record was confirmed in the database (addressed to this member); the screen was not re-checked because testing stopped | ✅ |
| Karur carpenter | "No notifications" | ✅ |
| E Road admin | 2 "New bill pending", E Road only | ✅ |
| Karur admin | Nothing from E Road | ✅ |

### 8. Leaderboard and points display

| Where | Expected | Seen | Result |
|---|---|---|---|
| Member home points card | 12.5 | 12.5 | ✅ |
| "Your position" and Top members | 12.5 | **12** (decimals dropped) | 🔧 Bug 6 |
| Admin bill details, member card | 12.5 | **13** (rounded) | 🔧 Bug 6 |
| Karur leaderboard | Karur members only | Karur Carpenter only | ✅ |

## UI test

Screens were opened and checked by screenshot on a 1080×2400 phone emulator, light theme.

| Screen | Check | Result |
|---|---|---|
| All screens (test build) | TEST MODE strip visible | ✅ |
| Onboarding, login, PIN | Layout, fields, Remember me, Forgot PIN | ✅ |
| Member home | Branch card, points card, tier progress, Add Bill card, offers carousel (swipes), today's winner, greeting banner, leaderboard, bottom tabs | ✅ |
| Add Bill | Image box, amount with live points preview, date, site name, vendor, Submit | ✅ |
| Add Bill with keyboard open | Bottom tab bar sat above the keyboard and took space from the form | 🔧 UI 1 |
| Duplicate bill dialog | Site, amount, points, date; Cancel and Add anyway | ✅ |
| Member Notifications | Cards with title, time ago, text; Delete all | ✅ |
| Admin dashboard | Tiles and counts update after each action | ✅ |
| Pending Bills | Card per bill; Approve and Reject dialogs | ✅ |
| Bill History, Bill Details | Tabs, filters, PDF, share, timeline | ✅ |
| Bill Details timeline for an approved bill | Still showed "Waiting for approval · Pending action from admin" as a step | 🔧 UI 2 |
| Spin | Wheel, Spin now, countdown, eligible list, today's and monthly winners | ✅ after fixes |
| Spin eligible row | Name and phone overflowed by 1 px (yellow-black stripe); bill-count icon green on green (invisible) | 🔧 Bug 7 |
| Send Greeting | Message, character count, image, channels, Send | ✅ |
| Confetti on home | Celebration animation played over the header text on every visit | 🔧 UI 3 |

UI items fixed after the test (not yet re-checked on the device):

1. **Tab bar over the keyboard.** The member tab bar hides while the keyboard is open, on every member screen (`dashboard_page.dart`).
2. **Bill timeline.** A pending bill shows "Waiting for approval" as the current step (orange clock, no longer a green tick). An approved bill ends with "Approved" and the approval time; a rejected bill ends with "Rejected" (red ✕) and the rejection time. The end of the line no longer depends on the English word "Approved", so it is also correct in Hindi and Tamil (`bill_details_page.dart`).
3. **Confetti.** It plays only when the member is #1 with more than 0 points, and at most once a day per account (`rank_celebration.dart`, tested in `test/rank_celebration_test.dart`). Before, after a points reset, whoever sorted first saw it on every visit.

## Bugs found and fixed

| # | Bug | Effect in live today | Fix | Where | Live when |
|---|---|---|---|---|---|
| 1 | The in-app record of a personal notification was saved only after a successful push | Members whose phone has no working push token (common for PIN logins) never see "Bill approved" or "Bill rejected" in the app | The server saves the in-app record whether the push succeeds, fails or has no token; the app saves it directly when the member has no token | `functions/in_app_record.js`, `index.js` `processNotificationQueue`; `notification_service.dart` | Functions deploy + app 1.1.2 |
| 2 | The spin's eligible-members list read the wrong field names (`userId`, `totalAmount`, `points`) and cast decimal points to whole numbers | List always says "No eligible carpenters today", although Spin now still works | Reads `carpenterId`, `amount`, `pointsEarned`; decimals kept | `todays_eligible_carpenters.dart` | App 1.1.2 |
| 3 | Reject sent two pushes: one from the app, one from the server | Member gets "Bill rejected" twice | Server skips when the app already handled it (`rejectedBy` set), the same rule approvals already use | `index.js` `onBillStatusChanged` | Functions deploy |
| 4 | The server's date check compared a bill's date and time with midnight | Every bill dated today was marked "Bill date cannot be in the future", and its duplicate check was skipped | Compares calendar days in India time | `functions/bill_date.js` | Functions deploy (this function is not deployed yet) |
| 5 | The server's duplicate check found the new bill itself, and used the server's time zone for "same day" | Every bill would be flagged as a duplicate of itself | Leaves the bill itself out; uses India-time day; withdrawn bills filtered in code | `index.js` `onBillCreated`, `bill_date.js` | Functions deploy |
| 6 | Leaderboard stored points as whole numbers; admin screens rounded them | 12.5 shown as 12 to members and 13 to admins; ties in the wrong order | Leaderboard keeps decimals; four admin labels use the shared `PointsUtils.formatPoints` | `home_provider.dart`, `top_carpenters_display.dart`, `bill_details_page.dart`, `carpenter_profile_detail_screen.dart`, `pending_bills_list.dart` | App 1.1.2 |
| 7 | Spin eligible row overflowed; bill-count icon invisible | Visual glitch | Phone text shrinks with "…"; icon white | `todays_eligible_carpenters.dart` | App 1.1.2 |
| 8 | `admin.firestore.FieldValue` and `Timestamp` are undefined in the local Functions emulator | Local only: every function write with a time crashed, hiding bugs 1, 4 and 5 | Modular import `require("firebase-admin/firestore")` | `index.js` | Functions deploy (no change in live behaviour) |

All automated tests pass after the fixes: **646 app tests** (`flutter test`) and **13 Cloud Functions tests** (`node --test test/*.test.js`). `flutter analyze` reports no errors.

New automated tests: `functions/test/in_app_record.test.js`, `functions/test/bill_date.test.js`, and a new case in `test/notification_visibility_test.dart` (a record saved without a push is visible to that member only).

## Not tested

| Item | Why |
|---|---|
| **Bill withdraw** (take back an approved bill's points) | The code and translations exist (`BillService.withdrawBill`), but **no screen calls it**, so admins cannot withdraw a bill. Decide: add a "Withdraw" button on approved bills, or remove the code. |
| Super admin "Reset" on a branch | Stopped before this step. The preview was verified on live earlier. |
| Karur admin's own spin on the same day | Stopped before this step. Covered by `daily_winner_scope_test.dart`. |
| Offer upload in this session | Tested earlier the same day (flow 3 of the first emulator run); not repeated after the data reset. |
| Tier upgrade (Silver at 2,000) | Needs a ₹2,000,000 bill; covered by unit tests. |
| Real push delivery to a phone | Test accounts have fake tokens; live push was verified earlier (4 queue items sent). |
| Dark theme, Hindi and Tamil | Covered by `responsive_layout_test.dart`; not checked on device in this run. |

## Decisions and next steps

1. **Cloud Functions:** fixes 1, 3 and 8 are live. Before `onBillCreated` (fixes 4 and 5) can go live, add a Firestore composite index on `bills` (`carpenterId`, `siteName`, `amount`, `billDate`). Without it, every new bill would get the index error written as its `validationError`.
2. **Ship app 1.1.2** with fixes 1, 2, 6 and 7.
3. **Withdraw:** add the button or remove the code.
4. The four decisions from the first report still stand: "Happy Deepwali" branch, today's Karur winner record, the "Test Account" in Karur, and the "Carpenters" label.
5. **Change the passwords and PINs** that were shared in chat.

## How to run these tests again

```bash
# 1. Start the private copy (Node 22, Java from Android Studio)
npx firebase-tools@15 emulators:start --only auth,firestore,functions,storage --project balajipoints

# 2. Fill it with test accounts
cd functions
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node scripts/emulator_seed.js

# 3. Point the phone emulator at it and install the test build
for p in 9099 8080 5001 9199; do adb reverse tcp:$p tcp:$p; done
flutter run --debug --dart-define=USE_FIREBASE_EMULATORS=true
```

Never build a release with `USE_FIREBASE_EMULATORS`: the app refuses to start in that case.
