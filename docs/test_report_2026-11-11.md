# Balaji Points: live test report, 11 Nov 2026

Build: `release/1.1.2` (version 1.1.1, build 33, debug), Android emulator, live Firebase project `balajipoints`.

## Summary

- **All four roles were tested.** Every role logged in, and every main screen showed only its own branch's data, cross-checked against the live database.
- **Three cross-branch leaks were found and fixed in code:** offers, the daily winner, and admin screens missing three of the four member roles.
- **The fixes reach users with the 1.1.2 app update.** Server-side fixes (notifications and points reset) are already live.
- **Flows that create data were not tested live**, to keep live data unchanged: offer upload, bill submit and approve, push notifications. They need a test on a private copy of the database (see the last section).
- **Four data decisions are waiting for the owner** (see Decisions needed).

## How the test was run

- **View only:** screens were opened and read; nothing was submitted, approved, sent, drawn, reset or deleted.
- **Logins:** switching accounts cleared only the emulator's own saved login; nobody was logged out on a real phone.
- **Push tokens:** PIN logins on the emulator did not replace any account's push token (the carpenter account's token time was unchanged).
- **The one server call made** was the super admin "Preview reset", which only reads.
- **Cross-check:** each count on screen was compared with the live database read directly.

## Results by role and screen

✅ correct · 🔧 fixed during this test · ⚠️ needs a decision · — not tested

### Carpenter (E Road, test account 9758888477, PIN)

| Screen | Seen | Database check | Result |
|---|---|---|---|
| Login with PIN | Phone, then PIN, then home | Account is E Road, role carpenter | ✅ |
| Home: points card | 0 points, Bronze | E Road reset to 0 | ✅ |
| Home: Top members | E Road names only, all 0 | Karur's top (murugesh 160.86) absent | ✅ |
| Home: Today's winner | Was **varatharaj (a Karur member)** | Karur admin's draw today | 🔧 now "No winner today" |
| Home: Offers | "Happy Deepwali" | Offer has no branch | ⚠️ shown to every branch |
| Wallet | 0 points, 0/0/0 bills, "No bills yet" | Bills cleared for E Road | ✅ |
| Add Bill | "Complete your profile" | Account has no name | ✅ expected (not completed) |
| Notifications | 3 offer announcements only | E Road personal ones cleared; Karur's hidden | ✅ |
| Profile | New design, no My Orders | – | ✅ |
| Side menu | Name, phone, role, points, menu | – | ✅ |
| Edit Profile, Help, About | – | – | — not reached (emulator stopped accepting taps) |

### E Road admin (9600609121, PIN)

| Screen | Seen | Database check | Result |
|---|---|---|---|
| Dashboard | 199 members, 15 pending, 0 points issued | 199 member accounts; 15 pending kept | ✅ |
| Users | 199, all 0 points, no Karur names | – | ✅ |
| Pending bills | 15 E Road bills | The 15 kept at reset | ✅ |
| Bill history | Empty | Cleared at reset | ✅ |
| Notifications | "No notifications" | E Road's cleared | ✅ |
| Offers | "No offers created" | Only offer has no branch | ⚠️ admin cannot manage it |
| Spin | "Ready to spin", no eligible members | Before the fix Karur's draw would have blocked this | 🔧 |
| Send Greeting | Form opens | – | ✅ not sent |

### Karur admin (Vijender Singh Rajpurohit, email)

| Screen | Seen | Database check | Result |
|---|---|---|---|
| Dashboard | Was "Carpenters: 5" | Karur has 6 members incl. an interior designer | 🔧 now 6 |
| Users | Was 5, missing Dayanand Pandey | Dayanand is an interior designer in Karur | 🔧 now 6 |
| Notifications | 7 "New bill pending", all Karur | 7 Karur notifications in database | ✅ |
| Pending bills | 1 (varatharaj ₹35,960) | – | ✅ |
| Bill history | Karur bills only; points match | e.g. murugesh 4.79 + 156.07 = 160.86 | ✅ |
| Offers | "No offers created" | E Road's offer correctly hidden | ✅ |
| Users list | Includes "Test Account" 8947038661 | That is the super admin's phone | ⚠️ |

### Super admin (Google sign-in)

| Screen | Seen | Database check | Result |
|---|---|---|---|
| Email + password login | Rejected | Account uses Google only | ✅ expected |
| Google sign-in | Opens super admin | – | ✅ |
| Branches | 2 branches, both active, Diwali off | – | ✅ |
| Admins | 2 E Road, 1 Karur, each with the right branch | – | ✅ |
| Points: preview reset (E Road) | 199 eligible users, 0 points | Deployed fix includes all roles | ✅ |
| Points: help text | Said "carpenters, architects and interior designers" | Engineers are now included | 🔧 text updated |
| Roles | 4 built-in roles, all active | – | ✅ |

### Karur member

Not tested: no Karur member login was provided. The offer, notification and winner rules that protect Karur members are covered by automated tests.

## Problems found and fixed in this test

| # | Problem | Fix | Live when |
|---|---|---|---|
| 1 | Offers had no branch: admins saw every branch's offers, members saw all, and the "new offer" push went to every branch | Offers save the admin's branch; admins see only their branch's; members see theirs plus super admin offers; push and alert only to that branch | App 1.1.2 |
| 2 | One "today's winner" for the whole app: E Road members saw Karur's winner, and one branch's draw blocked the other's | One winner per branch per day; every winner screen filters by branch | App 1.1.2 |
| 3 | Admin screens counted only `carpenter`, so architects, engineers and interior designers were missing from Users, the dashboard and the add-bill member picker | All six admin places use the four member roles | App 1.1.2 |
| 4 | Points reset help text left out engineers | Text updated in English, Hindi and Tamil | App 1.1.2 |

Earlier the same day (already live): notifications saved with their branch, the points reset including all roles, and E Road's new-year points, bills and notifications cleared.

## Decisions needed

1. **"Happy Deepwali" offer has no branch.** It shows to Karur members too, and no branch admin can edit or switch it off. Recommended: set it to E Road (one field on one record).
2. **Today's Karur winner record has no branch.** After the fix nobody sees it, and Karur's admin could draw a second winner today. Recommended: tag today's record with Karur.
3. **"Test Account" (8947038661) is a Karur member** using the super admin's phone. Remove or move it, so it does not appear in Karur's rankings.
4. **Dashboard label "Carpenters"** now counts all four roles. Rename it to "Members"?

## Not tested yet (needs a private test database)

Running these on live data would create real offers, bills, points and notifications. They need the Firebase Local Emulator Suite, or a separate test project:

- Admin uploads an offer → only that branch's members see it and get the push.
- Member submits a bill → admin of that branch only gets the alert → approve → points, tier and history update once → member gets the push.
- Reject and withdraw a bill → points stay correct.
- Daily spin draw → winner shown only to that branch.
- Greeting sent → only that branch sees the banner.
- Super admin "Reset" on a branch (the preview is verified; the reset itself is not).

## Other observations

- **PIN logins don't save a push token.** The log shows "could not obtain Firebase UID" after a PIN login, because anonymous sign-in is turned off in Firebase. PIN users who sign in on a new phone may not receive pushes until this is fixed (part of the security rollout).
- **The emulator sometimes stops accepting taps.** This is an emulator issue, not an app bug; it is why three profile sub-screens were not reached.
- **The super admin and test logins were shared in chat.** Change those passwords and PINs.
