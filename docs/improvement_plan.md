# Balaji Points: improvement plan and new screens

Reviewed 8 Nov 2026 on `release/1.1.1` at commit `4de3e94` (version 1.1.1, build 33). Based on reading the code only: nothing was changed, run against live data, or tested on a device for this review.

**Effort:** S = up to a day, M = 2–4 days, L = a week or more.

## Summary

1. **Security comes first.** Anyone can read every user's PIN hash, bills and points, and a 4-digit PIN can be cracked in seconds. A fix is already built on the `security-rollout` branch but is not live.
2. **Some data is wrong or inconsistent:** offers are not filtered by branch, the home rank differs from the Diwali rank, and Forgot PIN shows Erode's numbers to every branch.
3. **Missing screens hold back the main purpose of the app.** Members can earn points but cannot see a points statement, a full leaderboard, or redeem rewards, even though redemption code already exists.
4. **As branches grow, some screens will get slower and cost more,** because they load whole collections. Moving rankings to the server fixes speed, cost and the rank mismatch together.

---

## Phase 1: security and correctness (do before new features)

| # | Problem | Where | Fix | Effort |
|---|---|---|---|---|
| 1.1 | **PIN hashes are publicly readable.** `users` allows `read: if true` and stores `pinHash` with its salt. With only 10,000 possible PINs, anyone can work out any member's PIN offline. | `firestore.rules:109`, `pin_auth_service.dart:29` | Finish and release `security-rollout`: server PIN login, strict rules, data scoped by role, branch and user ID. | L (built, needs rollout) |
| 1.2 | Bills, points and offers are also publicly readable. PIN users have no Firebase sign-in (anonymous sign-in is disabled), so rules cannot tell users apart. | `firestore.rules:224, 262, 292` | Same rollout as 1.1, which gives PIN users a real sign-in. | Included in 1.1 |
| 1.3 | Rollout blockers already known: Erode PIN admins would be locked out (B1), and 20 accounts have no role saved. | `security-rollout` branch | Decide how Erode admins log in; run the role script with approval. | M |
| 1.4 | Six one-off maintenance screens are routed in the live app and can change or delete data: duplicates, cleanup, smart cleanup, backup, export. | `routes.dart:283-308` | Limit them to super admin, or remove them from release builds. | S |
| 1.5 | `debugPrint` writes user IDs to the phone log, including in release builds. | `notifications_page.dart:112, 300` | Switch to `AppLogger`, which is debug-only and masks IDs. | S |
| 1.6 | Offers are not filtered by branch, so Karur members see Erode's offers. | `home_provider.dart:247` | Add `branchId` to offers and filter by it (or allow "all branches"). | S |
| 1.7 | The home rank differs from the Diwali rank. Home counts deleted accounts, reads `users.totalPoints` instead of points records, and has no tie order. | `home_provider.dart` `_fetchRanked` | Short term: match the Diwali rules. Long term: 3.1. | S |
| 1.8 | Forgot PIN shows Erode's support numbers in every branch (U14). | `reset_pin_page.dart` | Read the phone numbers from the member's branch record. | S |
| 1.9 | A bill dated today can be flagged as a future date (B3). | `functions/index.js:710` | Compare dates in India time, not UTC. | S |
| 1.10 | Diwali bonus amounts and gift names are written into the app, so changing them needs a new release. | `branch_celebration_service.dart:24-31` | Move them to the branch's celebration settings in Firestore (see 4.6). | S |
| 1.11 | Copies of the Firebase config files are committed in `docs/`. | `docs/google-services (13).json`, `docs/GoogleService-Info (11).plist` | Delete them from `docs/`; the real ones live in `android/` and `ios/`. | S |

## Phase 2: reliability and code health

| # | Item | Detail | Effort |
|---|---|---|---|
| 2.1 | Crash and usage reporting | Neither Crashlytics nor Analytics is installed, so crashes after a release go unseen. Add Firebase Crashlytics first, then Analytics for which screens are used. | S |
| 2.2 | Async context warnings | 76 `use_build_context_synchronously` warnings. Each is a possible crash when a screen closes during a network call. Fix one file at a time, starting with auth and bills. | M |
| 2.3 | Very large files | Eleven files exceed 1,000 lines, for example `pending_bills_list.dart` (2,393) and `carpenter_profile_detail_screen.dart` (2,150). Split them into widgets with tests as each is touched. | M |
| 2.4 | Dead code | `PINSetupPage` and `DiagnosticPage` have no route, `wallet_page.dart` has two deprecated bill lists, and `phone_auth_service.dart` has OTP stubs. Remove them. | S |
| 2.5 | Force update while the app is open | The check runs only at app start. Also check when the app returns from the background. | S |
| 2.6 | End-to-end tests | 19 test files cover widgets and rules, but none covers login → home → add bill against the Firebase emulator. Add one smoke test per role. | M |
| 2.7 | App Check | Not installed (seen in logs). Add it after 1.1, so only the real app can call Firebase. | S |
| 2.8 | Lint cleanup | 53 unnecessary string interpolations and 12 missing braces. Run `dart fix --apply`. | S |

## Phase 3: speed and cost as branches grow

| # | Item | Detail | Effort |
|---|---|---|---|
| 3.1 | **Server-side leaderboard** | Home reads every user in the branch on each refresh to work out ranks. A Cloud Function can keep one leaderboard document per branch, updated when points change. This gives faster home loading, far fewer reads, the same rank on every screen and app version (fixes 1.7), and no deleted accounts. | M |
| 3.2 | Pagination | Only one list pages its results (`startAfter` is used once). The admin bill lists, user list and notifications load everything. Add "load more" to each. | M |
| 3.3 | Image sizes | Bill photos load at full size in lists. Store a thumbnail at upload, or decode at display size. | S |

## Phase 4: new screens

### For members (carpenter, architect, engineer, interior designer)

| # | Screen | What it does | Data | Effort | Value |
|---|---|---|---|---|---|
| 4.1 | **Rewards & Redeem** | Catalogue of rewards with their points cost; tap to request one; shows request status. | `offer_service.redeemOffer` and `offer_redemptions` exist, but **no screen uses them yet** | M | High: the main reason to collect points |
| 4.2 | **Points statement** | Every credit and deduction with date, bill and running balance; filter by month. | Points history inside `user_points` | M | High: fewer "where are my points" calls |
| 4.3 | **Full leaderboard** | Whole branch ranking, this month or all time, with your own row pinned. | After 3.1 | S | Medium. The "Leaderboard" link and feature tiles on home currently open **Notifications** by mistake. |
| 4.4 | **Bill details** | Status timeline (submitted → approved or rejected), rejection reason, points earned, full-screen photo. | `bills` | S | Medium: explains rejections |
| 4.5 | **Tier benefits** | What Bronze, Silver, Gold and Platinum each give, and how far you are from the next tier. | New `tiers` config | S | Medium |
| 4.6 | **Help & branch contact** | Your branch's phone numbers, address and map, plus an FAQ. | `branches` | S | Medium (fixes 1.8) |

### For branch admins

| # | Screen | What it does | Effort |
|---|---|---|---|
| 4.7 | **Redemption requests** | Approve or reject reward requests, which deducts points. Pairs with 4.1. | M |
| 4.8 | **Branch reports** | Bills per day and week, points issued, top members, pending backlog; export to PDF (the `pdf` package is already included). | M |
| 4.9 | **Member activity** | Members with no bills in 30 or 60 days, to follow up. | S |

### For super admin

| # | Screen | What it does | Effort |
|---|---|---|---|
| 4.10 | **All-branch dashboard** | Side-by-side totals for each branch: members, bills and points. | M |
| 4.11 | **App version & force update** | Set latest and minimum version with a confirmation step. It writes through a Cloud Function, because the rules block app writes to `app_config`. This replaces the manual Firebase Console step. | S |
| 4.12 | **Campaigns** | Turn the Diwali popup into any festival: dates, prize amounts, gifts and branches, all edited without a release (fixes 1.10). | M |
| 4.13 | **Audit log** | Who changed admins, branches, PINs and points, and when. Super admin actions are already written to `audit_logs`, but there is no screen to view them. | S |

## Phase 5: smaller polish

- The Notifications list needs extra space at the end so its last row clears the raised Add Bill button.
- The About Us and onboarding text still says "carpenters"; change it to "members" for all four roles.
- Have a native speaker review the Hindi and Tamil text added in 1.1.1.
- Show the member's tier colour on their profile and in the side menu.
- Add an empty state with a "Add your first bill" action on wallet for new members.

---

## Suggested order

| Release | Contents |
|---|---|
| 1.1.2 (small, soon) | 1.4–1.9, 1.11, 2.1, 2.4, 2.8, Phase 5 polish |
| 1.2 | 1.1–1.3 security rollout, 2.5, 2.7 |
| 1.3 | 3.1 leaderboard, 4.3, 4.4, 4.2, 4.6 |
| 1.4 | 4.1 and 4.7 rewards and redemption, 4.5 tiers |
| 1.5 | 4.8–4.13 admin and super admin tools, 3.2, 2.3 |

## Questions for you

1. **Erode admin login.** Should Erode admins keep PIN login after the security rollout, or move to email? This is the main blocker for 1.1.
2. **Rewards.** Are rewards physical gifts collected at the branch, or deducted from future bills? This decides how 4.1 and 4.7 work.
3. **iOS.** The config lists iOS version 1.0.12. Is an iOS app live? If so, it needs its own release and force update steps.
4. **Offers.** Should some offers apply to every branch? This decides the filter rule in 1.6.
