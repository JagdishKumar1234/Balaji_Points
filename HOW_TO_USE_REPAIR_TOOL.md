# How to Use the Points Repair Tool

## Access Points Repair Tool

### Method 1: Via Admin Dashboard (Recommended)

1. **Login to Admin Panel**
   - URL: Your app's admin section
   - Enter admin credentials

2. **Navigate to Points Repair Tool**
   - Look for "Points Repair" or "Admin Tools" menu
   - Click "Points Repair Tool"

3. **You should see:**
   - Info banner explaining what the tool does
   - "Scan for Issues" button
   - Action buttons below

### Method 2: Direct Navigation (If Menu Not Available)

Add this route to your app's router:

```dart
// In your router configuration
path: '/admin/points-repair',
builder: (context, state) => const PointsRepairPage(),
```

Then navigate to: `yourapp.com/admin/points-repair`

---

## Using the Tool

### Screen 1: Initial State

```
┌─────────────────────────────────────────┐
│  Points Repair Tool                     │
├─────────────────────────────────────────┤
│                                         │
│  ℹ️ Points Data Repair                  │
│  This tool scans user points data and   │
│  fixes duplicate entries, inconsistent  │
│  totals, and mismatched tiers           │
│                                         │
│  [Scan for Issues Button]               │
│                                         │
└─────────────────────────────────────────┘
```

### Step 1: Click "Scan for Issues"

**What happens:**
- Tool scans all users in database
- Takes 2-3 seconds
- Shows "Scan Report"

### Screen 2: Scan Report

```
┌─────────────────────────────────────────┐
│  Scan Report                            │
├─────────────────────────────────────────┤
│  Total users scanned:        547        │
│  Users with issues:          23         │
│  Users with duplicates:      18         │
│  Total duplicate entries:    42         │
│  Points mismatches:          5          │
│                                         │
│  [Scan Again] [Repair All Users]       │
└─────────────────────────────────────────┘
```

**What to look for:**
- **Users with issues:** Number of users that need fixing
- **Total duplicate entries:** Duplicate history entries found
- **Points mismatches:** Users where history sum ≠ totalPoints

### Step 2: Click "Repair All Users"

**Confirmation Dialog Appears:**
```
┌─────────────────────────────────────────┐
│  Repair All Users?                      │
├─────────────────────────────────────────┤
│  This will repair 23 users by:          │
│  • Removing duplicate history entries   │
│  • Recalculating correct totals         │
│  • Updating tier assignments            │
│                                         │
│  This action cannot be undone easily.   │
│                                         │
│  [Cancel]              [Repair]         │
└─────────────────────────────────────────┘
```

### Step 3: Click "Repair" to Confirm

**Wait for Progress:**
- Screen shows loading indicator
- Takes 10-30 seconds
- Don't close app or navigate away

### Screen 3: Repair Results

```
┌─────────────────────────────────────────┐
│  ✅ Repair Complete                     │
├─────────────────────────────────────────┤
│  user1_id         306 pts               │
│  user2_id         150 pts               │
│  user3_id         520 pts               │
│  user4_id         214 pts               │
│  ...                                    │
│                                         │
│  [Scan for Issues] [Repair All Users]  │
└─────────────────────────────────────────┘
```

**Check Results:**
- ✅ Green text = Successfully repaired
- ❌ Red text = Failed (rare)
- Numbers = New total points for each user

---

## After Repair

### Verify Points Are Fixed

1. **Open User Profile Screen**
   - Check displayed total points
   - Note the number

2. **Open Home Screen**
   - Force refresh (pull down)
   - Check total points match profile
   - Check points displayed in hero card

3. **Open Wallet Screen**
   - Check "Total Points" card at top
   - Should match profile/home
   - Verify "Points History" total
   - Grand total should equal displayed total

### Expected Results

After successful repair:
```
✅ Profile Screen → Shows correct total
✅ Home Screen    → Matches profile (after refresh)
✅ Wallet Screen  → Total matches, history sum = total
✅ Points History → No duplicate entries
✅ User Tier      → Correct based on total
```

---

## Understanding the Results

### Green Check ✅
```
user123_id        306 pts
```
User's data has been repaired successfully. New total is 306 points.

### Red X ❌
```
user456_id        Failed
```
Repair failed for this user. Rare. Check app logs.

### Zero Points
```
user789_id        0 pts
```
User had no valid history or all entries were invalid. Check manually.

---

## If Something Goes Wrong

### Repair Button Doesn't Appear

**Reason:** No issues found!  
**Action:** This is good. Scan report would show "0 users with issues"

### Repair Shows Failures

**Reason:** Firestore permissions issue  
**Action:** 
1. Check Firebase rules allow admin access
2. Check network connection
3. Try again after 1 minute

### Points Still Don't Match After Repair

**Reason:** Cache or stale data  
**Action:**
1. Force close and reopen app
2. Clear app cache if available
3. Run repair again

### Lost Points After Repair

**This should NOT happen.** If it does:
1. Check app logs for errors
2. Don't panic - run verify
3. Restore from Firestore backup if needed
4. Report issue

---

## Monitoring

### Daily Check

```bash
1. Open Points Repair Tool
2. Click "Scan for Issues"
3. If users with issues > 0 → Run repair
4. If users with issues = 0 → All good ✅
```

### Weekly Review

- Check app logs for repair errors
- Ask users if points seem correct
- Run scan again to verify stability

### Monthly Maintenance

- Full scan and repair
- Verify all users
- Document any issues

---

## Tips & Tricks

### Tip 1: Run Scan First
Always run "Scan for Issues" before repair. It's safe and shows what will be fixed.

### Tip 2: Off-Peak Hours
Run repair when users aren't actively adding bills. Less chance of conflicts.

### Tip 3: One Repair at a Time
Don't run multiple repairs simultaneously. Wait for one to complete.

### Tip 4: Check Logs
After repair, check app logs for detailed activity:
```
[Points Sync Repair] Repairing user123...
[Points Sync Repair] Removed 3 duplicates
[Points Sync Repair] New total: 306 pts
[Points Sync Repair] ✅ Success
```

### Tip 5: Keep Backups
Firebase automatic backups are your safety net. Good to know they exist.

---

## Common Scenarios

### Scenario 1: First Time Using Tool

```
1. Click "Scan for Issues"
2. See "Users with issues: 23"
3. Click "Repair All Users"
4. Confirm in dialog
5. Wait for completion
6. See results
7. Verify points in app
8. Done! ✅
```

### Scenario 2: Regular Monitoring

```
1. Every week: Click "Scan for Issues"
2. If issues found: Click "Repair All Users"
3. If no issues: All good, come back next week
```

### Scenario 3: Manual User Repair

If you need to repair a specific user (rare):

```dart
// In a debug method or console:
final service = PointsSyncRepairService();
final newTotal = await service.repairUserPoints('specific_user_id');
print('Fixed user: $newTotal points');
```

---

## File Locations

If you need to access the code:

```
Core Service:
  lib/services/maintenance/points_sync_repair_service.dart
  
Admin UI:
  lib/presentation/screens/admin/points_repair_page.dart
  
Documentation:
  POINTS_SYNC_REPAIR_GUIDE.md      (Full technical guide)
  POINTS_ISSUE_SUMMARY.md          (Problem & solution)
  QUICK_REPAIR_STEPS.md            (Quick overview)
  HOW_TO_USE_REPAIR_TOOL.md        (This file)
```

---

## Next Steps

✅ **Now:** Open admin panel and run "Scan for Issues"  
✅ **Then:** Review the report  
✅ **Finally:** Click "Repair All Users" if issues found  
✅ **Last:** Verify all screens show correct points  

---

## Success Criteria

After using the repair tool, you should see:

- [ ] All screens show same point total
- [ ] No duplicate entries in point history
- [ ] User tiers are correct
- [ ] No errors in app logs
- [ ] Users report correct points

---

**Questions?** Check the app logs or the detailed guides listed above.
