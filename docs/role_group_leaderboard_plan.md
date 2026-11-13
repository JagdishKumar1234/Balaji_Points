# Role groups + account approval — plan

Date: 2026-11-13 · Branch: `release/1.1.3` · Status: **built 2026-11-13 (not deployed)** — v4: only the branch admin approves accounts

Four parts:

- **A.** Leaderboards split by role group (Top 3 / Top 10 / my rank / celebration popup)
- **B.** Daily spin split by role group (separate winner per group, eligible = today's sales)
- **C.** Admin users list: filter by group / role
- **D.** New account approval by branch admin (+ mark all live users `profile_verified = true`)

Sign-up form and sign-in screens stay the same. Only what happens **after** sign-up and at sign-in changes (Part D).

---

## 0. The two groups (used by every part)

| Group | Roles | Default rate | Title |
|---|---|---|---|
| **Group 1: Trade** | `carpenter`, `interior_designer`, old accounts with no role | ₹1,000 = 1 pt | "Top Carpenters & Interior Designers" |
| **Group 2: Professional** | `architect`, `engineer` | ₹5,000 = 1 pt | "Top Architects & Engineers" |

**The rule everywhere:** members see only people in the **same branch AND same group**.

Groups are a **fixed role mapping in code**, not worked out from the rate. The super admin can edit rates, and grouping by rate would split boards silently if one role's rate changed.

New file `lib/core/points/leaderboard_group.dart`:

```dart
enum LeaderboardGroup { trade, professional }

class LeaderboardGroups {
  static const trade = {'carpenter', 'interior_designer'};
  static const professional = {'architect', 'engineer'};

  /// null for admin / super_admin / unknown -> not in any board or spin.
  /// Empty/missing role = old carpenter account -> trade. Case-insensitive.
  static LeaderboardGroup? of(String? role);
  static Set<String> rolesOf(LeaderboardGroup g);
}
```

All parts call this one helper. No screen compares role strings itself.

**Who counts as an active member** (shared helper `MemberFilter.isActiveMember(data)`):
- role is in a group (above)
- `profile_verified == true` (Part D)
- `status != 'deleted'`

---

## Part A — Role-group leaderboards

### A1. Where rankings are shown today

| Place | File | Problem today |
|---|---|---|
| Home Top 3 podium, Top 10 list, "your rank" | `lib/providers/home_provider.dart` (`_fetchRanked`, `_refreshRankings`, `_showCachedRankings`) → `home_top_carpenters.dart`, `top_carpenters_display.dart`, `top_carpenters_list.dart` | All 4 roles mixed. **If the branch can't be resolved it loads every user from every branch** (line ~376). Deleted users are not excluded. |
| Rank #1 confetti | `home_page.dart` (~line 200) | Uses #1 of the mixed list. |
| Diwali / celebration popup (Top 3 + your rank) | `lib/services/branch/branch_celebration_service.dart` `loadCelebrationSummary` → `diwali_celebration_dialog.dart` | All 4 roles mixed. Reads points from a different place than home. |

No Cloud Function computes rankings.

### A2. Shared ranking service (single source of truth)
New `lib/services/leaderboard/leaderboard_service.dart`:

```dart
Future<LeaderboardResult> load({
  required String branchId,        // never null
  required LeaderboardGroup group,
  required String? currentUserId,
  Source source = Source.serverAndCache,
});
```

1. Query `users` where `branchId == branchId` (same query as today, no new index).
2. Keep a doc only if the doc's `branchId` matches (a second check, for cached data), `LeaderboardGroups.of(role) == group`, and `isActiveMember`.
3. Points: `user_points` total first, falling back to `users.totalPoints` (Q3 default; the same rule for home and popup).
4. Sort by points high→low, then name A–Z. Ranks run 1..n inside the group.
5. Return the full list plus the current user's entry and rank.

### A3. Home (`home_provider.dart`)
- Read the user's own `role` and `branchId` from their user doc (already in `userData`). Fall back to the session only if they're missing.
- No group (admin) or no branch → show the empty state. **Never query all users.**
- `_fetchRanked` → `LeaderboardService.load(...)`.
- The cached list (`_showCachedRankings`) is also filtered by branch and group. Rankings are cleared on logout or account switch, so a previous account's list never flashes up.
- The title follows the group (l10n en/hi/ta). The subtitle shows the rate from `RoleService.rateForRole()` and is never hardcoded.

### A4. Celebration popup
`loadCelebrationSummary(branchId)` → `loadCelebrationSummary(branchId, group)` via `LeaderboardService`, with the same group title.

### A5. Confetti
No logic change. It follows the group's #1 automatically.

---

## Part B — Daily spin per role group

### B1. Today
- Admin screen: `lib/presentation/widgets/admin/daily_spin_management.dart` and `todays_eligible_carpenters.dart`.
- Eligible = anyone in the branch with a bill **approved today** (`status == approved`, `approvedDate == today`). All roles are mixed.
- There is one spin per branch per 24 h.
- Winner saved to `daily_prize_winners` (log) and `daily_winners/{branchId}_{date}` (home card).
- Member home: `HomeTodaysWinnerCard` in `home_top_carpenters.dart`.
- History: `daily_spin_history_screen.dart`.
- Branch filtering: `lib/services/branch/daily_winner_scope.dart`.

### B2. New behaviour
- The admin spin screen gets a **group switch: [Carpenters & Interior] [Architects & Engineers]**.
- Each group has:
  - **Eligible list:** active members **of that group in this branch** with ≥1 bill approved today. Each row shows the **member's sales today (₹ total of today's approved bills)** and bill count.
  - The **group's total sales today** at the top.
  - Its **own spin button** and **own once-a-day limit** (Group 1 spinning doesn't block Group 2).
  - Its own "today's winner" card.
- A group with no eligible members shows "No qualified members today" and the button is disabled.
- Spin pick: equal chance per qualified member (same as today; see Q5 for a minimum sales amount).

### B3. Data changes (no migration needed)
- `daily_prize_winners` gets new fields `group: 'trade' | 'professional'`, `role`, `todaySales`.
- `daily_winners` doc id changes to **`{branchId}_{group}_{date}`**.
- **No legacy `{branchId}_{date}` doc is written any more.** Writing one would show a carpenter winner to architects on the old app. Old-app members see "no winner yet" until they update.
- `DailyWinnerScope`:
  - `docId(branchId, group, date)`
  - `belongsTo(data, branchId, group)`
  - Old records with no `group` count as "before split". They show only in admin history (label "All roles"), never on member home.
- Member home `HomeTodaysWinnerCard` reads **only its own group's doc** for its own branch.
- Admin history screen: add a group filter (All / Group 1 / Group 2) and a group chip on each row.
- Firestore rules for these two collections already accept extra fields → no rules change.
- `daily_spin_provider.dart` (the member's own points spin game) is a separate feature and isn't touched.

---

## Part C — Admin users list filter

File: `lib/presentation/widgets/admin/users_list/search_header.dart` (already has Sort + Tier filters around line 365) and `users_list_view.dart`.

- New filter row:
  - **All · Carpenter & Interior · Architect & Engineer**
  - plus a role dropdown: **All roles · Carpenter · Interior Designer · Architect · Engineer**
  - Picking a role selects its group automatically. Picking a group resets the role to "All roles" inside that group.
- Combines with the existing search, sort and tier filters.
- The count label shows the filtered count ("12 of 140 members").
- Still branch-scoped (`forAdminBranch()`). Super admin keeps the branch picker.
- The main list shows **approved members only**. Pending and rejected members appear on the new Requests screen (Part D).
- Dashboard member counts (`admin_dashboard.dart`, `admin_home_page.dart`) count approved members only.

---

## Part D — New account approval

### D1. Rule
- A member who **signs up themselves** starts as **pending**. They **cannot sign in** until the branch admin of **their branch** approves.
- **Only the branch admin** approves or rejects, for all 4 roles. **The super admin cannot** (decided 2026-11-13): no button, the route sends them back, and the server function refuses them.
- The admin can **reject**. A rejected user also can't sign in, and the admin can approve them later from the Rejected tab.
- Accounts the **admin creates** (`add_carpenter_dialog.dart`) are approved straight away.
- Admins and the super admin never need approval.

### D2. Fields on `users/{id}`

| Field | Values |
|---|---|
| `profile_verified` | `true` = can sign in; `false` / missing = cannot |
| `approvalStatus` | `pending` · `approved` · `rejected` |
| `approvalRequestedAt` | timestamp (sign-up time) |
| `approvedBy` / `approvedAt` | admin uid + name, timestamp |
| `rejectedBy` / `rejectedAt` / `rejectReason` | admin uid + name, timestamp, optional text |

**Missing `profile_verified` = not verified.** This is the strict choice: it also catches people who sign up on the old app after the migration. That's why the migration must run **before** the new app goes live (D7).

### D3. Sign-up (form unchanged, only the end changes)
Three sign-up paths save a new member profile: PIN `PinAuthService.createAccount`, `AuthNotifier.registerWithEmailAndPassword`, and the Google first-time profile in `auth_provider.dart` (~line 647).

- Each writes `profile_verified: false`, `approvalStatus: 'pending'`, `approvalRequestedAt`.
- None of them signs the user in any more. They sign out and show a new **"Request sent"** screen:
  - "Your account request has been sent to <branch name>. You can sign in once the branch approves it."
  - Branch phone and a call button. A single "Back to sign in" button, sticky in the footer, so the screen fits without scrolling.
- An `admin_notifications` / `notification_logs` entry of type `newUserRegistered` (the type already exists) plus an FCM push to the branch admin: "New account request: <name> (<role>)".

### D4. Sign-in gate (every path)

| Path | File | Where the check goes |
|---|---|---|
| PIN | `auth_provider.dart` `loginWithPin` | right after `verifyPin` returns `userData`, **before** saving the session |
| Email / password | `auth_provider.dart` `loginWithEmailAndPassword` | after loading the profile |
| Google | `auth_provider.dart` `loginWithGoogle` | after loading the profile |
| App start with a saved session | `splash_page.dart` / session restore | re-read the user doc. If not verified, clear the session and go to the status screen |

- The check applies only to member roles: `isMemberRole(role) && profile_verified != true` → block.
- Blocked → no session saved, Firebase signs out, and a new **Account status** screen shows:
  - **pending:** "Waiting for approval from <branch>". Branch phone.
  - **rejected:** "Your account request was not approved. Please contact <branch>." Reason if given, plus branch phone.
- New `AuthState`: `AuthPendingApproval(status, branchName, branchPhone)`. It is not an error, so the AppLoader overlay clears like a normal logout (`ref.withLoader`).
- If an approved user is later rejected, they are signed out on the next app start (splash check).

### D5. Approve / reject: a server function (recommended)
New callable `reviewMemberAccount({ userId, action: 'approve' | 'reject', reason? })` in `functions/index.js`. It does the following:
- Checks the caller is the **admin of the same branch** as the user. Anyone else is refused, **including the super admin**.
- Checks the target is a member role (it never changes admins).
- Sets the D2 fields in one write and logs to `notification_logs`.
- On approve: if the user has an FCM token, sends a push: "Your Balaji Points account is approved. You can sign in now."

**Why a server function:** today's rules let a user edit their own doc. Approval fields must not be self-settable, and a branch admin must not approve another branch's users.

Rules change (`firestore.rules`):
- Add `profile_verified`, `approvalStatus`, `approvedBy`, `approvedAt`, `rejectedBy`, `rejectedAt` and `rejectReason` to `protectedUserFieldsUnchanged`.
- On **create**, a non-admin may only write `profile_verified == false` (or leave it out).

Admin "Add member" (`add_carpenter_dialog.dart`) creates the account, then calls `reviewMemberAccount(approve)`.

### D6. New admin screen: Account Requests
New `lib/presentation/screens/admin/account_requests_screen.dart`.

- Entry point: admin home / drawer tile **"Account requests"** with a **badge count** of pending requests (live stream).
- Tabs: **Pending (n) · Rejected (n)**. Optional **Approved (last 30 days)**.
- Uses the same group/role filter as Part C plus search by name or phone.
- Each card shows:
  - name, phone (tap to call), role chip, group, sign-up date
  - a duplicate-phone / same-name warning if another account with that phone or name exists in the branch (reuses the duplicate check helpers)
- Actions:
  - **Approve:** confirm, call the function, then show a toast. The card moves out of Pending.
  - **Reject:** a bottom sheet with an optional reason (presets "Not a customer", "Wrong branch", "Duplicate account", "Other"), then the function call.
  - Rejected tab: **Approve** is still possible.
- Data: `users` where `branchId == adminBranch`. Filter on the phone for member role + `profile_verified != true`, split by `approvalStatus`. Missing status = pending.
- Uses the existing AppTableCard / list styles and the navy + gold design system. On web/desktop it shows as a table (as with the other admin tables).

### D7. Mark all live users `profile_verified = true`
New script `functions/scripts/set_profile_verified.js`:
- It acts on **every** existing member account (all 4 roles + no-role) and every branch. Default is a **dry run**: it prints counts per branch/role and changes nothing.
- `--apply` sets `profile_verified: true`, `approvalStatus: 'approved'`, `approvedAt: now`, `approvedBy: 'migration-2026-11'`. Docs that already have the field are skipped, so it is safe to re-run.
- Admin and super admin docs are left alone.
- It needs the admin credential, and I will run it on production **only after your OK**.

### D8. Rollout order (important — avoids locking everyone out)
1. Deploy the `reviewMemberAccount` function (Node 22).
2. Dry-run, then `--apply`, `set_profile_verified.js`. **All live users can sign in on any app version.**
3. Deploy `firestore.rules` (approval fields protected). Old apps are unaffected because they never write those fields.
4. Release app 1.1.3 (Parts A–D).
5. Gap: people who sign up on the **old** app after step 2 have no `profile_verified`. The new app treats them as pending, and they show up on the Requests screen. But on the old app they can still sign in. To close this, **raise the minimum version once the Play rollout is 100%** (the same rule as before).
6. Re-run the script with `--report-only` to list any member without the field (should be only new pending sign-ups).

---

## Leaderboard / spin / list must also skip unapproved users
Parts A, B and C all use `isActiveMember`, so **pending and rejected users never appear** in Top 3/10, ranks, spin eligibility or the users list.

---

## 5. "No mix-up" checklist

| Risk | Guard |
|---|---|
| Another branch's data shows | Query by `branchId` and re-check each doc. No branch → empty list (never "all users"). Spin and requests use `forAdminBranch()`. The approve function checks the branch on the server. |
| Other group shows | `LeaderboardGroups.of(role) == myGroup` on each doc (boards, spin eligibility, winner card). |
| Group 1 winner shown to Group 2 | Winner doc id includes the group, and the legacy doc is no longer written. |
| One group's spin blocks the other | Once-a-day limit checked per branch + group. |
| Admin / super admin in a list | `of('admin')` = null. |
| Deleted / pending / rejected users in lists | `isActiveMember`. |
| Previous account's list flashes after switching accounts | Cache filtered by branch + group, and state cleared on logout. |
| Rate change moves people between boards | Groups fixed by role. |
| Home and popup ranks differ | One `LeaderboardService`, one points rule. |
| User approves themselves | Approval fields protected in rules; only the server function writes them. |
| Branch admin approves another branch's user | The function checks the caller's branch. |
| Live users locked out | Migration (D7) runs before the rules and the app (D8). |

---

## 6. Tests

**Unit** (`fake_cloud_firestore`). Seed data: 2 branches × 4 roles, plus a no-role, admin, deleted, pending and rejected user, and today's approved bills.

1. `LeaderboardGroups.of` for every role, case variations, empty, admin and unknown.
2. A carpenter or interior designer in Branch 1 sees only Branch 1 Group 1. An architect or engineer in Branch 2 sees only Branch 2 Group 2.
3. Pending, rejected, deleted and admin users are never in a board.
4. Missing branch → empty list, and no query of all users.
5. Ties sorted by name; ranks run 1..n with no gaps; the popup top 3 equals the home top 3.
6. Spin eligibility: only the group's members with a bill approved today in this branch; the sales sum is correct; Group 1's spin doesn't block Group 2.
7. Winner doc id and `belongsTo` with branch + group; old no-group records hidden on member home.
8. Users filter: group, role, combined with tier and search.
9. Login gate: pending, rejected and missing field → blocked, no session saved; approved → in. Admins are not blocked.

**Function emulator** (`firestore-tests/functions.emulator.test.mjs`):
- Same-branch admin can approve/reject.
- An admin from another branch is refused, and a member is refused.
- The super admin can do any branch.
- An admin account can't be the target.

**Rules tests:**
- A user can't set their own `profile_verified`.
- On create, `profile_verified: true` is refused for a non-admin.

**Manual** (debug build, 2 branches):
- One user of each role: check the boards, the winner card, and the users filter.
- Sign up a new user, check they're blocked, approve them on the Requests screen, then check they can sign in.
- Reject a user and check they see the status screen.

---

## 7. Build order
1. Group helper + `isActiveMember` + tests
2. `LeaderboardService` + home + popup (A)
3. Spin per group (B)
4. Users filter (C)
5. Approval: fields, sign-up end screen, sign-in gate, status screen, function, rules, Requests screen, script (D)
6. `flutter analyze`, all tests, emulator tests, manual run
7. Rollout per D8. Each production step (function deploy, script `--apply`, rules deploy) waits for your OK.

---

## 8. Known limits / out of scope
- `users` is still readable by anyone (`allow read: if true`). Branch/group isolation of **what is shown** is enforced in the app. Full server-side read isolation belongs to the pending strict-security rollout.
- Offer targets in points aren't changed.
- Pending users get no push on approval unless they already have an FCM token (a brand-new user usually doesn't). They find out when they next sign in, so the Request-sent screen says "we'll approve soon — try signing in later".

## 9. Decisions (all answered 2026-11-13)
- **Q1 Spin:** a **separate spin per group** → **2 spins daily per branch** (one for Group 1, one for Group 2). ✅
- **Q2 Admin users list:** filter **All / Group 1 / Group 2 / specific role**. ✅
- **Q3 Ranking pool:** the rank is computed **only among the members of the user's own group in the user's own branch**.
  - Example: 20 carpenters + interior designers in a branch. A carpenter sees Top 3 / Top 10 and "your rank #x of 20" from those 20 only.
  - Architects and engineers get the same treatment within their own group.
  - The board header shows the group size: "Rank 4 of 20".
  - Points value: `user_points` total first, `users.totalPoints` as fallback. The same rule is used on every screen.
  - ✅
- **Q4 Titles:** OK. ✅
- **Q5 Spin qualification:** **at least one bill approved today** for that member (in this branch). No minimum amount. ✅
  - Each logged-in member's **Today's winner** card shows **only the winner of their own group's spin** in their own branch.
  - If their group hasn't spun yet: "Today's draw hasn't happened yet".
- **Q6 Push to branch admin on every new account request:** **yes** (plus the badge on the Requests tile). ✅
  - The push goes to all admins of that branch with an FCM token.
  - Title: "New account request". Body: "<name> · <role>".
  - Tapping it opens the Account Requests screen.
  - It is sent from a server trigger on the new user doc, so it works for sign-ups from both old and new app versions.
- **Q7 Same phone number again:** **no new account.** Registration is blocked when the phone already exists. ✅
  - **Same branch, pending:** "An account request for this number is already waiting for approval at <branch>." Shows the branch phone.
  - **Same branch, rejected:** "This number already has an account at <branch>. Please contact the branch." Shows the branch phone. The admin can approve it from the Rejected tab.
  - **Same branch, approved:** the existing "Account already exists — please sign in" message.
  - **Different branch:** "This number is already registered with another Balaji Points branch. Please contact support." The other branch's name or data is never shown.
  - The phone check runs **before** any profile is written, in all three sign-up paths. The same normalised phone check as `PinAuthService.normalizePhone` is used.
  - On the Requests screen, a card shows a **"Possible duplicate"** hint when another account in the branch has the same name, or a phone differing only in formatting.
