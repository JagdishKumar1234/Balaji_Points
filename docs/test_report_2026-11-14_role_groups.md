# Test report — role groups, spins, account approval (2026-11-14)

Build under test: `release/1.1.3` working tree (uncommitted).
Everything below ran on **test data only** (local Firebase emulators + test
accounts from `functions/scripts/emulator_seed.js`); nothing touched live data.

## Result

**Pass.** One layout bug was found and fixed (spin status text overflowed).
No feature leaked data between E Road and Karur, or between the two role groups.

| Suite | Result |
|---|---|
| App tests (`flutter test`) | **1010 passed**, 0 failed |
| Both-branch app scenarios (`test/two_branch_features_test.dart`) | 12 / 12 |
| Server end-to-end, both branches (`firestore-tests/role_groups.emulator.test.mjs`) | 16 / 16 (8 E Road + 8 Karur) |
| Older server tests (`functions.emulator.test.mjs`) | 9 / 9 |
| Firestore rules tests | 42 / 42 |
| Function unit tests | 28 / 28 |
| Real app on Android emulator (test mode) | see below |

## Real app on screen (Android emulator, TEST MODE)

| # | Who | What was checked | Result |
|---|---|---|---|
| 1 | Karur waiting sign-up (9000000014) | PIN sign-in blocked → "Waiting for approval", Karur name + phone | ✅ |
| 2 | Karur rejected (9000000015) | Blocked → "Account not approved", reason shown | ✅ |
| 3 | Karur architect (9000000010) | Board "Top Architects & Engineers", **Karur architects + engineers only**, "Rank 1 of 2"; waiting 999-pt account not shown; winner card "Architect & Engineer" | ✅ |
| 4 | Karur architect | Add Bill with no photo → "Please upload bill photo", nothing saved; preview 15,000 ÷ 5,000 = 3 pts | ✅ |
| 5 | E Road carpenter (9000000001) | Board "Top Carpenters & Interior Designers", **E Road only**, "Rank 1 of 2" | ✅ |
| 6 | Karur admin (PIN) | Dashboard: Account requests badge **1**, members 4 (approved only) | ✅ |
| 7 | Karur admin | Requests list shows **only Karur** request, role tag + group | ✅ |
| 8 | Karur admin | Approve → server approves → WhatsApp sheet with Karur message → opens `wa.me/919000000014?text=…` | ✅ |
| 9 | Karur admin | Spin Carpenter & Interior → winner **Karur Carpenter**; Architect & Engineer still "Ready", 2 qualified, ₹55,000 today → winner **Karur Architect** | ✅ |
| 10 | Karur admin | Users list: role tag on every card, Karur only, "5 of 5"; filter Architect & Engineer → "3 of 5" | ✅ |
| 11 | E Road admin (9000000003) | Requests: only E Road's; Reject with reason → polite WhatsApp message with reason | ✅ |
| 12 | E Road admin | Spin still "Ready" (Karur's draws don't block E Road) | ✅ |
| 13 | Newly approved Karur member | Can sign in; sees own group winner "Karur Architect", "Rank 3 of 3" | ✅ |
| 14 | Karur carpenter (9000000002) | Winner card shows **Karur Carpenter** (own group), "Rank 2 of 2" | ✅ |
| 15 | Newly rejected E Road member | Blocked, "Reason: Not a customer" | ✅ |
| — | Database after the run | Approved push queued to the member; approve/reject record who did it; winner docs `karur_test_trade_…` and `karur_test_professional_…` | ✅ |

Screenshots: `docs/test_shots_2026-11-14/`.

## Bug found and fixed

- **Spin status text overflowed** its badge on a phone ("Today's draw for this
  group is done"). Fixed in `daily_spin_management.dart` (text now wraps).
  Covered by the full test run; the Android emulator crashed three times so the
  fix was not re-checked on screen.

## Not covered on screen (covered by automated tests instead)

- New registration (email / Google) end to end and the duplicate-phone dialog —
  typing long text into this emulator was unreliable.
- Single-role filter in the users list.
- Real push delivery (the local emulators cannot send pushes; the queue entry
  was checked).

## How to run again

See `docs/test_report_2026-11-11_write_flows.md` → "How to run these tests
again". Extra test accounts now in the seed: Karur architect 9000000010/1010,
engineer 9000000011/1111, interior designer 9000000012/1212; waiting sign-ups
9000000013/1313 (E Road), 9000000014/1414 (Karur); rejected 9000000015/1515.

## Release 1.1.3 (35)

AAB: `build/app/outputs/bundle/release/app-release.aab` (69.4 MB, signed), commit `538997c`.

### What's new (Play Store, max 500 characters)

**English**
```
What's new in 1.1.3
• Fairer leaderboards: carpenters and interior designers now compete together, and architects and engineers together, within your own branch.
• Two daily lucky draws: one for each group, open to members with a bill approved that day.
• New accounts are approved by your branch. You'll get a notification once approved.
• A bill photo is now required when adding a bill.
• Bug fixes and security improvements.
```

**Hindi**
```
1.1.3 में नया
• निष्पक्ष लीडरबोर्ड: कारपेंटर और इंटीरियर डिज़ाइनर आपस में, और आर्किटेक्ट और इंजीनियर आपस में, अपनी ही शाखा में मुकाबला करते हैं।
• रोज़ दो लकी ड्रॉ: हर ग्रुप के लिए एक, उस दिन बिल अप्रूव होने वाले सदस्यों के लिए।
• नए खाते आपकी शाखा मंज़ूर करती है। मंज़ूरी पर आपको सूचना मिलेगी।
• बिल जोड़ते समय बिल की फ़ोटो अब ज़रूरी है।
• बग सुधार और सुरक्षा सुधार।
```

**Tamil**
```
1.1.3 இல் புதியவை
• நியாயமான தரவரிசை: தச்சர்கள், உள் அலங்கார வடிவமைப்பாளர்கள் ஒரு குழு; கட்டிடக் கலைஞர்கள், பொறியாளர்கள் ஒரு குழு; உங்கள் கிளைக்குள் மட்டும்.
• தினமும் இரண்டு குலுக்கல்கள்: ஒவ்வொரு குழுவிற்கும் ஒன்று, அன்று பில் அங்கீகரிக்கப்பட்டவர்களுக்கு.
• புதிய கணக்குகளை உங்கள் கிளை அங்கீகரிக்கும். அங்கீகரித்ததும் அறிவிப்பு வரும்.
• பில் சேர்க்கும்போது பில் புகைப்படம் இப்போது அவசியம்.
• பிழைத் திருத்தங்கள், பாதுகாப்பு மேம்பாடுகள்.
```
