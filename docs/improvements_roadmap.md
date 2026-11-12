# Balaji Points — improvements roadmap

Ideas to make the app more robust, safer and easier to use, grouped by
area and ordered by value within each group. Each item says why it matters
and roughly how big it is (S = a day or less, M = a few days, L = a week or
more). Written 2026-11-12, after the catalogs, Contact Us and guest-mode
work. Known open problems are tracked separately in
`open_issues_2026-11-12.md`.

## 1. Security and data safety (do first)

1. **Hide PIN hashes and check PINs on the server (L).**
   Today every user record, including `pinHash` and `pinSalt`, can be read
   by anyone, and a 4-digit PIN can be recovered from its hash in seconds.
   Move PIN checking into a Cloud Function (like `adminPinSignIn`, but for
   every member), give PIN members a real Firebase sign-in, then lock the
   `users` collection so people only read their own record.
   Order: ship the app update → wait until most members have it → change
   the rules → raise the minimum app version.
2. **Admin-only rules for bills and offers (M).** Bills can be deleted and
   offers changed by anyone who knows how to call Firestore. Now that PIN
   admins get a sign-in, the rules can require "admin of this branch".
3. **Move point crediting fully to the server (M).** Approval credits
   points from the admin's phone (with a duplicate guard). A Cloud Function
   that credits on approval would make points impossible to tamper with and
   would keep working if an admin's phone loses connection mid-approval.
4. **Firebase App Check (S).** Blocks scripts and fake apps from calling
   Firestore and functions directly. Also stops enquiry spam.
5. **Daily backups (S).** Scheduled Firestore export to Cloud Storage, kept
   30 days. One bad script or rules mistake should never lose points.
6. **Audit log for admin actions (M).** Who approved, rejected, edited a
   member, reset a PIN or changed points, and when. Helps settle disputes.

## 2. Speed and smoothness

1. **Keep the first screen instant (S).** Home already shows the saved
   copy first; do the same for Wallet, Bill history and Notifications
   (show cached, refresh quietly), so no screen opens on a spinner.
2. **Paginate long lists (M).** Admin bill history, users and notifications
   load whole collections. Load 30 at a time and fetch more on scroll; this
   keeps big branches fast as data grows.
3. **Composite indexes for common queries (S).** Branch + status + date
   queries are currently sorted on the phone. Indexes let Firestore sort and
   page, which is faster and cheaper.
4. **Image thumbnails (S).** Bill and offer photos are shown small in lists
   but downloaded full size (up to 350 KB). A 200 px thumbnail made at
   upload (or a resize extension) cuts list data by ~90%.
5. **Release-only checks (S).** Build with `--obfuscate --split-debug-info`
   and keep the build script that strips the web PDF engine (4 MB).
6. **Catalog preload on Wi-Fi only (S)**, with a setting to allow mobile data.

## 3. Members (carpenters, architects, engineers, interior designers)

1. **Bill status timeline for members (S).** The admin bill screen shows
   Submitted → Approved/Rejected with times; show the same to the member,
   plus the rejection reason.
2. **Rejection reason (S).** Let admins pick a reason (unclear photo, wrong
   amount, duplicate…) so members know what to fix.
3. **Re-submit a rejected bill (S)** with the details pre-filled.
4. **Points statement (M).** Monthly statement (PDF or in-app): opening
   points, bills, spins, redemptions, closing points.
5. **Reward redemption flow (M).** Members request an offer when they reach
   its points; the branch admin approves; points are deducted with a record.
6. **Reminders (S).** "You are 120 points from Silver", "Your bill is still
   pending", sent by push.
7. **Referral (M).** Members invite other carpenters / architects; bonus
   points when the invitee's first bill is approved.
8. **WhatsApp share of achievements (S)** (tier reached, reward won), which
   also advertises the store.

## 4. Branch admins

1. **Bulk approve (S)** for many small, clear bills at once.
2. **Duplicate-bill check before approval (S)** using bill number + amount +
   date (the old `onBillCreated` function; needs its Firestore index).
3. **Branch dashboard trends (M):** bills and points per week, top members,
   pending age, approval time.
4. **Enquiry follow-up (S):** notes, "called" / "quoted" / "closed" status,
   and a reminder for enquiries open more than two days.
5. **Export (S):** members, bills and enquiries to Excel for accounts.

## 5. Super admin and multi-store growth

1. **Store onboarding flow (M).** "Partner with us" requests become a
   checklist: create branch → create admin → set roles and rates → share
   the app link. Turns store enquiries into new branches quickly.
2. **Per-branch settings (M):** each branch's own offers, spin prizes,
   points rate overrides and catalog selection.
3. **Usage analytics per branch (S)** from Firebase Analytics: active
   members, bills per member, time to approval.
4. **Plans for partner stores (L)** if the platform is offered to other
   shops: limits, branding (logo / colours per store) and billing.

## 6. Guest mode and growth

1. **Offers preview for guests (S)** (no points shown), to show what members
   win.
2. **"Request a callback" button (S)** on catalogs and branches.
3. **Share links that open the app (M)** for catalogs and branches
   (deep links), so a shared catalog brings people into guest mode.
4. **Store photos and opening hours (S)** on the branches screen.

## 7. Quality and release process

1. **Automated checks on every change (S).** A GitHub Action that runs
   `flutter analyze`, `flutter test` and the Firestore rules tests.
2. **Integration test on a device (M)** for login, add bill, approve and
   catalogs, run before each Play Store upload.
3. **Staged rollout (S):** Play Console 10% → 50% → 100%, and raise the
   force-update minimum only after 100%.
4. **Crash and ANR watch (S):** review Crashlytics daily for a week after
   each release; alert on new issues.
5. **Clean up old code (M):** large screens (1,500–2,400 lines) such as the
   admin bill lists are hard to change safely; split them into smaller
   widgets with tests.
6. **One source for rules and functions deploys (S):** a script that runs
   the tests and deploys, so the live rules never drift from the repo.

## 8. Accessibility and language

1. **Bigger tap targets and font scaling checks (S)** on all forms (already
   tested on Contact Us and catalogs).
2. **Screen-reader labels (S)** for icon-only buttons.
3. **Review Hindi and Tamil wording with a native speaker (S)**, especially
   new screens (guest mode, enquiries, catalogs).
