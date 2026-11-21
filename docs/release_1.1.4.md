# Release 1.1.4 (37)

Build 37 built 2026-11-21 from `release/1.1.3` (build 36 was built 2026-11-18
after commit `1fb0a9c`; 37 replaces it, Play needs a higher version code).
AAB: `build/app/outputs/bundle/release/app-release.aab`.

## Added in build 37

- Admin → member detail → **Change branch / role** (all 4 member roles), for
  members who chose the wrong branch or role at sign-up. Only the member's own
  branch admin; the super admin cannot. Role change recalculates every bill at
  the new role's points rate. Branch change starts the member at 0 points in
  the new branch (old approved bills and history stay with the old branch;
  pending bills move). Server function `changeMemberBranchRole` (live 2026-11-21).
- Admin → member detail → **Delete account**, plain Yes / No confirm. Server
  function `deleteMemberAccount` (live 2026-11-21).
- Edit member: the free-text Branch ID field is removed (use Change branch / role).
- Catalog PDFs over 100 MB upload from phones (streamed from disk).
- "Powered by Sri Balaji Plywood & Hardware" on splash and sign-in screens.

## In this release (since 1.1.3, commit `538997c`)

- Daily Buy Daily Win prize wheel (10 tool prizes, casino colours); the draw saves a random qualified member and a random prize; winner and prize on every member's Home.
- Push notifications for the spin: winner, the rest of the winner's group, and a 6 PM spin reminder for branch admins (server functions `onDailyWinnerCreated`, `spinReminder`, already live).
- Admin: role-targeted notifications with categories; category-wise admin notifications; new dashboard (grid/list, reorder); bottom tab bar; Bills title, alerts bell, new member card, member filters in the app bar.
- Notifications: categories that open the right screen, Normal type, swipe-delete crash fixed, shared notifications cannot be deleted for everyone.
- Catalog PDF upload size limit removed (admin).

Server side already deployed before this build: `sendRoleBroadcast`, `onDailyWinnerCreated`, `spinReminder`, Firestore and Storage rules.

## What's new (Play Store, max 500 characters)

**English** (417 characters)
```
What's new in 1.1.4
• Daily Buy Daily Win: a new prize wheel. Today's winner and their prize show on your Home screen.
• Instant alerts: the winner gets "You won!", and everyone sees who won.
• Better notifications: sorted by type, and a tap opens the right screen.
• For branch admins: new dashboard, bottom tab bar, send notifications to chosen member types, and a daily spin reminder.
• Bug fixes and improvements.
```

**Hindi** (376 characters)
```
1.1.4 में नया
• डेली बाय डेली विन: नया इनाम चक्र। आज का विजेता और उसका इनाम आपकी होम स्क्रीन पर दिखता है।
• तुरंत सूचना: विजेता को "आप जीते!" और सभी को पता चलता है कि कौन जीता।
• बेहतर सूचनाएँ: प्रकार के अनुसार, और टैप करने पर सही स्क्रीन खुलती है।
• शाखा एडमिन के लिए: नया डैशबोर्ड, नीचे टैब बार, चुने हुए सदस्यों को सूचना भेजें, और रोज़ स्पिन रिमाइंडर।
• बग सुधार और बेहतरी।
```

**Tamil** (461 characters)
```
1.1.4 இல் புதியவை
• டெய்லி பை டெய்லி வின்: புதிய பரிசுச் சக்கரம். இன்றைய வெற்றியாளரும் பரிசும் உங்கள் முகப்புத் திரையில் தெரியும்.
• உடனடி அறிவிப்பு: வெற்றியாளருக்கு "நீங்கள் வென்றீர்கள்!", மற்றவர்களுக்கு யார் வென்றார் என்று தெரியும்.
• சிறந்த அறிவிப்புகள்: வகை வாரியாக; தட்டினால் சரியான திரை திறக்கும்.
• கிளை நிர்வாகிகளுக்கு: புதிய டாஷ்போர்டு, கீழ் டேப் பார், தேர்ந்த உறுப்பினர்களுக்கு அறிவிப்பு, தினசரி ஸ்பின் நினைவூட்டல்.
• பிழைத் திருத்தங்கள், மேம்பாடுகள்.
```
