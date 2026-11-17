# Admin UI: audit and improvement plan

18 Nov 2026 · branch `release/1.1.3` · covers the branch admin app (phone first, tablet second)

## 1. Summary

The admin app now has a modern dashboard, a bottom tab bar (Home, Bills, Add Bill, Members, More), category-wise notifications and a cleaner app bar. A deep UI test of 13 admin screens in 5 display variants (65 renders) found **3 high**, **7 medium** and **5 low** issues. Most are small layout fixes. The two biggest gaps are a floating button that covers a Delete button on Offers, and money and points shown without consistent formatting.

Recommended order:
1. **Phase A:** fix the issues below (1–2 days).
2. **Phase B:** make every admin screen follow one layout pattern (2–3 days).
3. **Phase C:** add the new features you pick from section 5.

## 2. How the admin UI was tested

| Item | Detail |
|---|---|
| Tool | `tool/screenshots/admin_deep_ui_test.dart` renders the real admin screens on sample data and records every layout overflow or error |
| Sample data | Members of all 4 roles, a very long name, a member with no name, a member with no role (old account), bills in every status, a large amount (₹1,82,340.50), active and expired offers, two catalog categories, admin alerts, one account request |
| Variants | 360 px phone light, 360 px dark, 390 px phone, 900 px tablet, 360 px with large system text (130 %) |
| Screens | Dashboard (grid and list), Bills: Pending, Bills: History, Members, More, Notifications, Send Notification, Send Greeting, Offers, Catalogs, Enquiries, Spin |
| Also run | Full test suite: 1,023 tests pass; analyze clean |
| Not covered yet | Add Bill, Account requests, member profile, bill details (they need a signed-in admin), Hindi and Tamil text lengths, and a live phone pass with real admin data |

Run it again with:

```
flutter test tool/screenshots/admin_deep_ui_test.dart \
  --dart-define=SHOT_DIR=build/admin_ui \
  --dart-define=SDK_FONTS=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts
```

PNGs and `report.txt` land in `build/admin_ui`.

## 3. Findings

### High: users see a broken or blocked screen

| # | Screen | Problem | Fix |
|---|---|---|---|
| H1 | Spin | The content is 1.8 px too wide on a normal 360 px phone and 33 px too wide with large text, so a red/black overflow stripe shows next to "Ready to spin!". The spin button sits partly under the tab bar. | Let the status row wrap. Add bottom padding equal to the tab bar height. |
| H2 | Offers | The "Create Offer" floating button covers the Delete button on the card under it. With large text, the Created / Valid until row overflows by 52 px. | Add list bottom padding (button height + 16). Let the date row wrap to two lines. |
| H3 | Pending bills, Bill history | Money shows as `₹24500` and `₹182341`; the second is rounded from ₹1,82,340.50. Points show as `24.50 pts`, `8.0` and `42.5` in different places. | One shared formatter: `₹1,82,340.50` in the Indian grouping style, and points like `24.5` everywhere. |

### Medium: works, but hard to use or inconsistent

| # | Screen | Problem | Fix |
|---|---|---|---|
| M1 | Members | The search hint is cut ("Search name or …") because the Add and PDF buttons share the row. | Move Add and PDF to the app bar (⋮ or icons). Search gets the full width. |
| M2 | Catalogs | The "Add category" button label is cut ("Add categ…") at 360 px. | Shorter label ("Category") or an icon button. |
| M3 | Spin | A second navy "Daily Spin" header sits under the app bar that already says Spin. | Remove the inner header; keep the history button in the app bar. |
| M4 | Pending bills (dark) | The Reject button is a pale pink block in dark mode; elsewhere danger buttons are outlined. | Use the same danger style as the rest of the app. |
| M5 | Pending bills | Cards are tall, with thick gold borders, so about 1.5 bills fit on a screen. The admin's most-used screen needs more per screen. | Compact card: name, amount, points, site on two lines; Approve/Reject as one row; open for photo and details. |
| M6 | Dashboard (large text) | Labels are cut: "Pending bi…", "Bills this …", "Points iss…". | Allow two-line labels in the summary card and the month cards. |
| M7 | Testability | Send Greeting (and Add Bill, Account requests, member profile) talk to Firebase directly, so they can't be checked on sample data. | Read through the same swappable data layer as the other screens. |

### Low: polish

| # | Screen | Problem | Fix |
|---|---|---|---|
| L1 | Pending bills | The search hint says "Search carpenter…" though bills come from all 4 roles. | "Search member…" |
| L2 | Bills | The pending-bills filter is a button inside the page, but Members has it in the app bar. | Put the filter in the app bar on every list screen. |
| L3 | All lists | Loading shows a spinner; content jumps in. | Light placeholder (skeleton) cards. |
| L4 | Notifications, Enquiries | The empty states have no next step. | Add an action, e.g. "Send a notification". |
| L5 | All | Hindi and Tamil labels are longer and not yet checked at 360 px. | Run the deep test in `hi` and `ta`. |

What looked right:
- the dashboard in grid and list, light and dark, and on tablet;
- the tab bar and its badges;
- the More screen;
- Notifications;
- Send Notification, which fits one screen even with large text;
- the new member card;
- Enquiries.

## 4. Phase B: one layout pattern for every admin screen

Every admin screen should follow the same rules:

1. **App bar:** title on the left; search or filter and screen actions on the right. No second header inside the page.
2. **Content:** a list or form that uses the full width, with bottom padding so nothing hides under the tab bar or a floating button.
3. **One main action:** the gold button, either sticky at the bottom (forms) or a floating button that never covers list items.
4. **The same pieces everywhere:** a card style (white, 16 px corners, thin border), a status chip, money and points formatting, an empty state with an action, and skeleton loading.
5. **Checked by the deep UI test** in all 5 variants, plus Hindi and Tamil, before each release.

## 5. Ideas for new admin features

Ranked by how much they help a branch admin day to day.

| # | Feature | What the admin gets | Size |
|---|---|---|---|
| F1 | **Faster bill review** | Compact list, a full-screen bill photo with zoom, swipe to approve or reject, "Approve all" for one member, and quick reject reasons (photo unclear, duplicate, wrong amount) | M |
| F2 | **Sent notifications history** | A list of what the branch sent, to whom, when, and how many phones were reached; send again; templates for common messages | S |
| F3 | **Member profile upgrade** | A timeline of bills, points and spins; Call and WhatsApp buttons; admin notes; manual points change with a reason (logged) | M |
| F4 | **Reports** | Monthly summary per role (bills, amount, points), top members, inactive members; export PDF and Excel | M |
| F5 | **Inactive member nudges** | A list of members with no bill in 30 or 60 days; one tap sends them a notification | S |
| F6 | **Admin activity log** | Who approved, rejected or changed what, and when (useful when a branch has more than one admin) | S |
| F7 | **Sign-up QR at the counter** | A branch QR poster; scanning opens sign-up with the branch already chosen | S |
| F8 | **Scheduled and automatic messages** | Schedule a notification for later; automatic birthday or festival greetings | M |
| F9 | **Branch targets** | A monthly target (bills or amount) with progress on the dashboard | S |
| F10 | **Offer redemption requests** | Members request an offer; the admin approves and marks it handed over | M |

S = about a day, M = 2–4 days. Every feature gets the same deep UI test and a live phone check before release.

## 6. Proposed order

1. **Phase A:** fix H1–H3, M1–M4 and M6, then run the deep UI test and a live phone check.
2. **Phase B:** the one-layout-pattern rules (section 4), M5 compact bill card, L1–L4, and Hindi/Tamil checks.
3. **Phase C:** the features you choose. Suggested first: **F1 faster bill review**, **F2 sent notifications history**, **F3 member profile upgrade**.
4. Build a test APK after each phase.

## 7. Decisions needed

1. Approve Phase A as listed?
2. Which Phase C features, and in what order?
3. M5: is a compact pending-bill card fine, or should bills keep the large photo-first cards?
