# Release 1.1.2 (34) — test report

Date: 2026-11-12. Build: `flutter clean` → release App Bundle (`.aab`),
web-only PDF engine left out. Firebase project: `balajipoints` (live).

## Summary

| Area | Result |
|---|---|
| Automated tests | **940 passed, 0 failed** |
| Static analysis | **0 errors, 0 warnings** |
| Firestore rules tests (emulator) | **39 passed** |
| Server function tests | **7 passed** (`adminPinSignIn`) |
| Device pass (Android emulator, profile build) | Guest mode and catalogs checked; member and admin screens covered by automated tests (see "Not tested on device") |

## Fixed during testing

1. **Admin screens open to non-carpenter members.** The router blocked
   only carpenters from `/admin` and `/super-admin`; architects, engineers,
   interior designers and custom roles could open them by address on web.
   Now only admins (and the super admin for its panel) can.
2. **Contact Us for every role.** Older accounts with no saved role were
   refused (empty role); custom roles were treated as guests. All
   non-admin accounts now send to their own branch.
3. **Catalog reopen flash.** Reopening a saved catalog briefly showed an
   empty download bar ("/ 5.5 MB"); it now shows a small spinner. The open
   itself took about 0.37 s from tap (including the page slide).
4. **Login: "Continue as guest" below the fold.** Added a gold "Guest"
   button at the top right; the full-width button stays at the bottom.
5. **Guest header tagline cut off** next to Log in: now two lines.
6. **Contact Us support box cut off** the numbers and email: each is now
   its own button, both numbers in full.

## Device pass (emulator, profile build)

| Screen | Check | Result |
|---|---|---|
| Login | Loads, buttons visible | Pass (guest button fix above) |
| Guest home | Header, live stats (2 branches, 11 catalogs, 4 categories), offers, quick links, Join and Grow panels | Pass, loaded in ~2 s |
| Guest → Catalogs | Grid with covers | Pass, instant |
| Catalog reader | First open (5.5 MB download) | ~7 s on emulator network, progress shown |
| Catalog reader | Reopen saved file | Pass, ~0.37 s; PDF parse 13–146 ms, pages drawn 16–106 ms |
| Catalog reader | Share, Download, zoom buttons | Present |
| Guest → Branches | Both branches, address, phone, Call, Directions | Pass |
| Directions (E Road) | Opens Google Maps at "Sri Balaji Plywood & Hardware", Erode | Pass |
| Guest → Contact Us | Both support numbers in full, optional branch, topics | Pass |

## Bill photos and points

- **Compression** (every bill photo, member or admin): picker limits to
  1,920 px at quality 85, then the app resizes to 1,600 px longest side,
  JPEG, stepping quality down until ≤ 350 KB (never below 45 so text stays
  readable); rotation fixed; GPS/EXIF removed.
- **Live check (read-only):** 375 bill photos in Storage. Before 12 Nov:
  median 241 KB, largest **901 KB**. Since 12 Nov: all ≤ 350 KB (largest
  313 KB).
- **Points (new tests on a fake database):** approval credits points at the
  bill's locked rate (₹1,000/point carpenter, ₹5,000/point architect);
  tier upgrades when crossing 2,000 (Silver); the points log records the
  bill; **a bill can never be credited twice**; a rejected bill credits
  nothing and cannot be approved later.

## Access by role (automated)

Guests, carpenter, architect, engineer, interior designer, a custom role,
admin and super admin checked against every kind of screen:
- Guest screens (home, branches, careers, contact): open to everyone.
- Catalogs and the reader: open to every role and guests.
- Admin screens: only admins; super admin panel: only the super admin.
- Member screens (home, wallet, profile, add bill): open to all members.

## Live changes made today (with approval)

- Firestore rules: guest mode (enquiries with optional branch, service,
  careers, store partner), catalogs.
- `adminPinSignIn` function: PIN admins get a Firebase sign-in (tested
  end-to-end with the Erode admin).
- Erode admin record: wrong `migratedToUid` removed.
- Branch map links saved (E Road, Karur); Erode offers copied to Karur;
  11 catalogs uploaded.

## Not tested on device (do before rollout to 100%)

The device pass was stopped before these; they are covered by automated
tests but should be tapped through once on a real phone:
1. Member login (PIN) → Home, Wallet, Add bill (photo pick, up to Submit),
   Profile, Contact Us (own branch shown), Catalogs with background preload.
2. Admin login (PIN) → dashboard, Enquiries (after logging in again with
   the PIN), Pending bills, Bill history, member details, bill details.
3. Super admin → Branches (map link field), Guest enquiries.
4. Careers form and Contact Us send (sends real data; use a test branch or
   delete afterwards).

## Notes for release

- Release build leaves out pdfrx's 4 MB web engine; it is restored after
  the build so web and debug builds keep working.
- After uploading, roll out in stages and raise the force-update minimum
  (`app_config/version`) only when the rollout is at 100%.

## What's new (Play Store, max 500 characters)

**English**
```
What's new in 1.1.2
• Product catalogs: browse Laminates, Plywood, Doors and Hardware. Opens instantly, with zoom, share and download.
• Contact Us: send enquiries to your branch, or call and email support.
• Guest mode: explore catalogs, branches with map directions, service requests and careers without logging in.
• Faster app start and smoother screens.
• Clearer bills with date and time.
• Bug fixes and security improvements.
```

**Hindi**
```
1.1.2 में नया
• प्रोडक्ट कैटलॉग: लैमिनेट, प्लाईवुड, दरवाज़े और हार्डवेयर देखें। तुरंत खुलते हैं, ज़ूम, शेयर और डाउनलोड के साथ।
• संपर्क करें: अपनी शाखा को पूछताछ भेजें, या सहायता को कॉल और ईमेल करें।
• अतिथि मोड: बिना लॉग इन कैटलॉग, नक्शे के साथ शाखाएँ, सर्विस अनुरोध और करियर देखें।
• तेज़ शुरुआत और स्मूद स्क्रीन।
• तारीख और समय के साथ साफ़ बिल।
• बग सुधार और सुरक्षा सुधार।
```

**Tamil**
```
1.1.2 இல் புதியவை
• தயாரிப்பு பட்டியல்கள்: லேமினேட், ப்ளைவுட், கதவுகள், ஹார்டுவேர். உடனே திறக்கும், பெரிதாக்கல், பகிர்தல், பதிவிறக்கத்துடன்.
• தொடர்பு: உங்கள் கிளைக்கு விசாரணை அனுப்புங்கள் அல்லது ஆதரவை அழைக்கவும்.
• விருந்தினர் முறை: உள்நுழையாமல் பட்டியல்கள், வரைபட வழியுடன் கிளைகள், சேவை, வேலைவாய்ப்பு.
• வேகமான தொடக்கம், மென்மையான திரைகள்.
• தேதி, நேரத்துடன் தெளிவான பில்கள்.
• பிழைத் திருத்தங்கள், பாதுகாப்பு மேம்பாடுகள்.
```
