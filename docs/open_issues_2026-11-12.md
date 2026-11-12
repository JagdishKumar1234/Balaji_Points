# Open issues — 2026-11-12

Known problems and pending decisions that are **not fixed** in this commit.
Most urgent first.

## Blocking

1. **PIN admins cannot read enquiries yet (Google Cloud permission missing).**
   `adminPinSignIn` is deployed and checks the PIN correctly, but creating the
   sign-in token fails: `iam.serviceAccounts.signBlob denied`. Grant once:
   ```
   gcloud auth login
   gcloud services enable iamcredentials.googleapis.com --project balajipoints
   gcloud iam service-accounts add-iam-policy-binding \
     53571317085-compute@developer.gserviceaccount.com \
     --member="serviceAccount:53571317085-compute@developer.gserviceaccount.com" \
     --role="roles/iam.serviceAccountTokenCreator" --project balajipoints
   ```
   Until then, branch admins who log in with a PIN see "Sign in with your
   admin email to see enquiries". Email admins are not affected.

2. **Wrong migration link on the Erode admin record.** `users/B8Q69u09NUyXq5nsBDjw`
   (Erode admin, phone 9600609121) has `migratedToUid` pointing at the
   **super admin's** account (`Ip8waoPaiBfRdXTDbOTRWsuCWw83`). New code never
   follows it, but older code that follows `migratedToUid` could mix the two
   accounts. Clear the field after review.

## Security (live today)

3. **User records are readable by anyone, including `pinHash` and `pinSalt`.**
   A 4-digit PIN can be recovered from its hash in seconds. The stricter
   rules and server PIN login (planned rollout) are not live.
4. **Bills can be read and deleted by anyone; offers can be changed by anyone**
   (app-level checks only).
5. **Enquiries can be created by anyone** (needed: PIN members and guests have
   no Firebase sign-in). Fields are strictly checked, but spam is limited only
   by a 2-minute cooldown on the phone. No App Check or server rate limit.
6. **Anonymous sign-in is off in live Firebase**, so PIN members have no
   Firebase identity. The app now skips the attempt for a day instead of
   failing on every launch.
7. **Hidden admin tools are still reachable by URL** on web:
   `/admin/check-duplicates` and `/admin/smart-cleanup` (dashboard cards are
   commented out).

## Not deployed on purpose

8. **Cloud Functions written but not deployed:** `onBillCreated` (needs a
   Firestore composite index on `bills` first, otherwise every bill gets a
   validation error), `onBranchRenamed`, `onRoleRenamed`. `onPointsChanged` and
   `onUserDeleted` are still on Node 20 (retired), so they cannot be updated
   until moved to Node 22.

## Decisions pending

9. **Guest mode** is planned, not built (guests: offers + enquiries only, no
   bills). Open questions: which offers a guest sees (all branches, or a
   chosen branch), and whether guests can browse catalogs.
10. **Catalog preload uses mobile data** (about 53 MB once per member, again
    only when a PDF is replaced). Wi-Fi-only needs a network-check package.
11. **App size:** the PDF engine adds about 2.5 MB to the download. Option:
    store catalogs as page images and drop the PDF engine; admins would then
    upload images, and PDFs would be converted by the upload script.

## Build and tooling

12. **pdfium download during Android builds** comes from GitHub and fails on a
    slow connection. Debug binaries were fetched by hand; the first release
    build will download them again.
13. **Analyzer warnings left from before:** unused `amount` in
    `export_users_before_cleanup.dart`, unused `isDark` in
    `home_top_carpenters.dart`, several `use_build_context_synchronously`
    infos in `admin_home_page.dart` and `app_update_service.dart`.

## Still to check on a device

14. Catalogs: preload, instant open, zoom buttons and double-tap, Share and
    Download in the reader.
15. Home startup speed after the anonymous sign-in and caching changes.
16. Contact Us as a member and as a guest, and the Enquiries inbox for an
    email admin (and a PIN admin after item 1).
