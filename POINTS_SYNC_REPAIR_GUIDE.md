# Points Sync and Repair Guide

## Problem Overview

You're seeing different point totals across the app:
- **Profile Screen: 306 points** ✅ (Source of Truth - from `user_points` doc)
- **Home Screen: 214 points** ❌ (Stale - not refreshed)
- **Wallet Screen: 520 points** ❌ (Sum of history with duplicates)

### Root Causes

1. **Duplicate History Entries**: Some bills were added to `pointsHistory` array multiple times
2. **Inconsistent totalPoints**: The `totalPoints` field in `user_points` and `users` collections might not match
3. **Stale Home Cache**: Home screen doesn't refresh frequently enough

## Solution

### Step 1: Access the Repair Tool

The repair tool is available in the admin panel. Add this route to your admin navigation:

```dart
// In admin_home_page.dart or your router
PointsRepairPage() // Access via admin panel
```

### Step 2: Scan for Issues

1. Open **Points Repair Tool** in admin panel
2. Click **"Scan for Issues"**
3. Review the report showing:
   - Total users scanned
   - Users with issues
   - Duplicate entries found
   - Points mismatches

### Step 3: Repair All Users

Once you've confirmed there are issues:

1. Click **"Repair All Users"** button
2. Confirm the repair action
3. The system will:
   ✅ Remove duplicate history entries (keeps first occurrence of each bill)
   ✅ Recalculate correct totalPoints from cleaned history
   ✅ Update tier based on correct points
   ✅ Sync both `user_points` and `users` collections atomically

### Step 4: Verify

After repair completes:
- Check that point totals match across all screens
- Verify profile, home, and wallet all show **306 points**
- Points history total should equal the displayed total

## What Gets Fixed

### ✅ Fixed Automatically
- Duplicate entries in `pointsHistory` array
- Incorrect `totalPoints` values
- Mismatched tier assignments
- Inconsistency between collections

### ✅ Preserved
- Legitimate points (no loss)
- Original bill IDs and dates
- User identity and profile data
- First occurrence of each bill (no data loss)

## Data Structure

### Before Repair
```
user_points: {
  userId: "user123"
  totalPoints: 250  // ❌ Incorrect - doesn't match history sum
  pointsHistory: [
    { billId: "bill1", points: 100, ... },  // Original
    { billId: "bill1", points: 100, ... },  // Duplicate!
    { billId: "bill2", points: 50, ... },   // Original
    { billId: "bill2", points: 50, ... },   // Duplicate!
    ...
  ]
  // History sum = 300 (includes duplicates)
}
```

### After Repair
```
user_points: {
  userId: "user123"
  totalPoints: 306  // ✅ Correct - calculated from history
  pointsHistory: [
    { billId: "bill1", points: 100, ... },  // Kept
    { billId: "bill2", points: 50, ... },   // Kept
    ...
  ]
  // History sum = 306 (no duplicates, matches totalPoints)
}
```

## Behind the Scenes

The repair service (`PointsSyncRepairService`):

1. **Scans** all users in `user_points` collection
2. **Detects** duplicates by checking bill IDs in history
3. **Deduplicates** by keeping only first occurrence of each bill
4. **Recalculates** total points from cleaned history
5. **Updates** both collections atomically with Firestore batch operations
6. **Verifies** consistency across collections

## Preventing Future Issues

### Best Practices

✅ **Always use PointsManagerService** for adding/withdrawing points
- Ensures atomic operations
- Prevents double-counting
- Maintains consistency

✅ **Use batch operations** when updating multiple users
- Atomic - all-or-nothing
- Consistent state
- Better performance

✅ **Regularly verify** points data
- Run scan weekly
- Check for new issues
- Act quickly if found

### Code Example: Correct Points Addition

```dart
final pointsManager = PointsManagerService();

// ✅ Correct - Atomic operation
final newTotal = await pointsManager.addPoints(
  userId: userId,
  pointsToAdd: 100,
  reason: 'Bill #123 approved',
  billId: billId,
);

// This updates:
// 1. user_points collection
// 2. users collection (mirror)
// 3. pointsHistory array
// All atomically in one batch!
```

## Troubleshooting

### Issue: Repair completes but points still don't match

**Solution:**
1. Force refresh all screens
2. Re-run the scan to verify
3. Check Firebase logs for errors

### Issue: Some users failed to repair

**Solution:**
1. Note the failed user IDs
2. Run scan again to see details
3. Check Firestore rules and permissions
4. Manually repair individual users if needed

### Issue: User lost points after repair

**This should NOT happen** because:
- We only remove duplicates
- We recalculate from actual history
- No legitimate transactions are deleted

If this occurs:
1. Check app logs for errors
2. Restore from Firestore backup
3. Contact support

## API Reference

### PointsSyncRepairService

```dart
final service = PointsSyncRepairService();

// Generate scan report
final report = await service.generateRepairReport();

// Repair one user
final newTotal = await service.repairUserPoints('userId');

// Repair multiple users
final results = await service.repairMultipleUsers(['user1', 'user2']);

// Repair all users with issues
final result = await service.repairAllUsers();

// Verify a user's data
final isValid = await service.verifyUserPoints('userId');
```

## Timeline

- **Scan**: 2-3 seconds for all users
- **Repair one user**: < 1 second
- **Repair all**: Depends on count (typically 10-30 seconds)

## Safety Checklist

Before running repair:
- [ ] Generated report first
- [ ] Reviewed affected users
- [ ] Confirmed points differences
- [ ] Backed up data (optional but recommended)
- [ ] Informed affected users (if needed)

After running repair:
- [ ] Checked app - points match across screens
- [ ] Ran verify to confirm
- [ ] Monitored app logs for errors
- [ ] Checked user feedback

## Files Involved

- `lib/services/maintenance/points_sync_repair_service.dart` - Core repair logic
- `lib/presentation/screens/admin/points_repair_page.dart` - Admin UI for repairs
- `lib/services/user/points_manager_service.dart` - Central points operations
- `lib/providers/wallet_provider.dart` - Wallet screen (sums history)
- `lib/providers/home_provider.dart` - Home screen (displays totalPoints)

## Next Steps

1. ✅ Run the scan to identify issues
2. ✅ Review the repair report
3. ✅ Execute repair if issues found
4. ✅ Verify all screens show correct totals
5. ✅ Monitor for future issues

## Questions?

Check the app logs for detailed repair activity. The repair service logs every step of the process.
