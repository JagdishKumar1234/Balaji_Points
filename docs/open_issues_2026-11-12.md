# Open issues — 2026-11-12 (updated)

Known problems and pending decisions. Most urgent first.

## Fixed in code (no further action)

- **Hidden admin tools reachable by URL.** The six maintenance routes
  (`/admin/duplicate-accounts`, `/admin/export-users`,
  `/admin/cleanup-duplicates`, `/admin/backup`, `/admin/check-duplicates`,
  `/admin/smart-cleanup`) are commented out in `lib/config/routes.dart`,
  like their dashboard cards. Uncomment both to bring a tool back.
- **Analyzer warnings.** `flutter analyze` now reports no errors and no
  warnings.
- **PIN admins now get a Firebase sign-in** (deployed and tested live
  2026-11-12): `adminPinSignIn` runs as the Firebase Admin SDK service
  account, which can sign tokens. Tested with the Erode admin: token issued,
  sign-in accepted, Erode enquiries readable. No `gcloud` grant was needed.
- **Firestore rules for guest mode deployed** (2026-11-12, 39 rules tests
  pass): guests' enquiries, service requests, careers and store-partner
  requests are accepted; members of all roles reach their own branch admin.
- **Erode admin record fixed:** the wrong `migratedToUid` (pointing at the
  super admin) was removed from `users/B8Q69u09NUyXq5nsBDjw`.
- **Contact Us for every member role:** carpenter, architect, engineer,
  interior designer, custom roles and older accounts with no role all send
  to their own branch. Live check: all 208 members have an active branch.
- **Guest mode** is built: catalogs, branches with map links, service
  request, careers, contact with branch choice, and a store-partner panel.

## Security (major, needs a planned rollout)

4. **User records are readable by anyone, including `pinHash` and
   `pinSalt`.** A 4-digit PIN can be recovered from its hash in seconds.
   Fix: move PIN checking to the server and hide the hashes. This needs an
   app release first (old apps read the hash to log in), then the rules.
5. **Bills can be read and deleted by anyone; offers can be changed by
   anyone** (app-level checks only). Fix: rules that require an admin
   sign-in. Now possible, since PIN admins get a sign-in too (needs the
   updated app on admins' phones first).
6. **Enquiries can be created by anyone.** Fields are strictly checked and
   the phone has a 2-minute cooldown; no App Check or server rate limit.
7. **Anonymous sign-in is off in live Firebase**, so PIN members have no
   Firebase identity (the app no longer retries it on every launch).

## Not deployed on purpose

8. **Cloud Functions written but not deployed:** `onBillCreated` (needs a
   Firestore composite index on `bills` first, otherwise every bill gets a
   validation error), `onBranchRenamed`, `onRoleRenamed`. `onPointsChanged`
   and `onUserDeleted` are still on Node 20 (retired) and cannot be updated
   until redeployed on Node 22.

## Decisions pending

9. **Catalog preload uses mobile data** (about 53 MB once per member, again
   only when a PDF is replaced). Wi-Fi-only needs a network-check package.
10. **App size:** the PDF engine adds about 2.5 MB to the download. Option:
    store catalogs as page images and drop the PDF engine.

## Build and tooling

11. **pdfium download during Android builds** comes from GitHub and fails on
    a slow connection. The first release build downloads it again.

## Still to check on a device

12. Catalogs: preload, instant open, zoom, Share and Download.
13. Guest mode: tabs, branch Directions (map links), Contact / Careers.
14. Enquiries inbox for an email admin and a PIN admin (log out and back in
    with the PIN once, to get the new sign-in).
