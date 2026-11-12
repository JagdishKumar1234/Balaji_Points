# Balaji Points: per-role points rate test, 12 Nov 2026

Build: `release/1.1.2` (debug, TEST MODE), Android emulator, **private local copy of Firebase** (Firebase Local Emulator Suite). No live users, bills or points were touched.

## Summary

- **Every role earns at its own rate, end to end.** For a ₹10,000 bill: carpenter and interior designer 10 points, architect and engineer 2 points. The member's preview, the admin's pending card, the approve dialog, the saved bill and the credited points all agree.
- **Bug found and fixed:** if a role's rate changed between submit and approval, the member and the admin card showed one number but approval credited another (shown 3.00, credited 2.4). The rate is now locked when the bill is submitted.
- **Two smaller fixes:** the approve dialog said "added to the carpenter" for every role (now "the member"), and the duplicate warning showed the old bill's points at today's rate (now its own saved points).
- **Server fallback works** (approval outside the app): uses the bill's saved rate, else the member's role rate.

## Rates tested

| Role | Rate (₹ per point) |
|---|---|
| Carpenter | 1,000 |
| Interior designer | 1,000 |
| Architect | 5,000 |
| Engineer | 5,000 (changed to 4,000 and back during the test) |

## Results

### 1. Each role submits ₹10,000

| Member | Preview on Add Bill | Saved on bill | Result |
|---|---|---|---|
| Carpenter | You will earn 10.00 points | rate 1,000, expected 10 | ✅ |
| Architect | You will earn 2.00 points | rate 5,000, expected 2 | ✅ |
| Engineer | You will earn 2.00 points | rate 5,000, expected 2 | ✅ |
| Interior designer | You will earn 10.00 points | rate 1,000, expected 10 | ✅ |

### 2. E Road admin approves all four

| Member | Pending card | Approve dialog | Credited | Points record = user record | Result |
|---|---|---|---|---|---|
| Interior designer | 10.00 pts | 10.00 points | 10 | 10 = 10 | ✅ |
| Architect | 2.00 pts | 2.00 points | 2 | 2 = 2 | ✅ |
| Carpenter | 10.00 pts | 10.00 points | 10 | 10 = 10 | ✅ |
| Engineer | 2.00 pts | 2.00 points | 2 | 2 = 2 | ✅ |

Each bill was credited exactly once (one history entry per bill).

### 3. Rate changes

| Step | Expected | Seen | Result |
|---|---|---|---|
| Engineer rate set to ₹4,000; engineer submits ₹12,000 | Preview 3.00, bill saved at 4,000 | 3.00, saved at 4,000 | ✅ |
| Old approved engineer bill after the change | Stays 2 | 2 | ✅ |
| Same amount/site/date submitted again | Duplicate warning | Shown; but it listed the old bill as 2.50 pts (today's rate) | 🔧 fixed: shows the bill's own points |
| Rate changed back to ₹5,000 **before** approving the ₹12,000 bill | Credit 3 (what the member was shown) | Card 3.00, dialog 2.40, **credited 2.4** | 🔧 fixed |
| After the fix: submit ₹8,000 at 5,000, change rate to 4,000, approve | 1.60 everywhere | Preview 1.60, card 1.60, dialog 1.60, credited 1.6 | ✅ |

### 4. Server fallback (approval without the app)

| Bill | Expected | Credited | Result |
|---|---|---|---|
| ₹20,000, saved rate ₹4,000 | 5 | 5 | ✅ |
| ₹20,000, no saved rate (older bill), architect | 4 (role rate 5,000) | 4 | ✅ |

## Fixes made during the test

| # | Problem | Fix | Where |
|---|---|---|---|
| 1 | Approval used the rate at approval time, not the rate the member was shown | Approval uses the bill's saved `rupeesPerPoint`; older bills use the member's role rate | `bill_service.dart` (`_rateForBill`), `functions/index.js` (`onBillStatusChanged`) |
| 2 | Approve dialog in Pending Bills recalculated at the current rate | Uses the bill's saved rate | `pending_bills_list.dart` |
| 3 | Bill details "Points rate" showed the member's current rate | Shows the bill's own rate | `bill_details_page.dart` |
| 4 | Duplicate warning showed the old bill at today's rate | Shows the old bill's own points | `add_bill_page.dart`, `admin_add_bill_page.dart` |
| 5 | "points will be added to the carpenter" for every role | "to the member" (English, Hindi, Tamil) | translations |

Automated tests: 868 app tests pass, including the new "rate locked at submission" tests.

## Other observations

- During the test, a `flutter run` from the IDE replaced the test build with a live build that kept the local test session. Nothing was submitted in that state, and a read-only check confirmed none of the test accounts, bills, points or notifications exist in live. The test build was then reinstalled.
- The new launch logo and onboarding were seen working in the test build.

## To go live

1. **`onBillStatusChanged` deployed** 12 Nov 2026 (fix 1, server side).
2. **Ship app 1.1.2** (fixes 1–5 and the per-role rates on screens). Until admins update, an admin on the current app (1.1.1) approves every bill at ₹1,000 per point, so **update the branch admins' phones first**.
