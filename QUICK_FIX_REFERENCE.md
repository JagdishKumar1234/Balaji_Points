# Quick Fix Reference - Duplicate Points

## 🔍 Find Duplicates (Read-Only - Safe)
```dart
final cleaner = DuplicatePointsCleaner();
final report = await cleaner.generateDuplicateReport();

// Check results
print('Affected users: ${report['usersWithDuplicates']}');
print('Total duplicates: ${report['totalDuplicates']}');
```

## ✅ Fix for Specific Users (Recommended)
```dart
// Fix one user
await cleaner.fixUserDuplicates('user_id_here');

// Fix multiple users
await cleaner.fixMultipleUsers(['user1', 'user2', 'user3']);
```

## 🔧 Fix All Users (Use with Caution)
```dart
final count = await cleaner.fixDuplicates();
print('Fixed $count duplicate entries');
```

## 📊 Verify Points Are Correct
```dart
// Verify one user
await cleaner.verifyUserPoints('user_id_here');

// Verify all users
await cleaner.verifyAllPoints();
```

---

## What Gets Fixed?
- ✅ Removes duplicate entries from pointsHistory
- ✅ Keeps only first occurrence of each bill
- ✅ Recalculates totalPoints correctly
- ✅ Updates tier (may downgrade)
- ✅ Records timestamp

## What Gets Preserved?
- ✅ Legitimate points (no data loss)
- ✅ Original bill IDs and dates
- ✅ User identity and other data
- ✅ Firestore documents (just updated)

## Example: User Lost 50 Points
```dart
// Before fix: 250 points
// After fix: 200 points (50 points removed - duplicates gone)

await cleaner.fixUserDuplicates('user123');
```

---

## Safety Checklist
- [ ] Generated report first
- [ ] Reviewed affected users
- [ ] Confirmed points differences
- [ ] Backed up important data (optional)
- [ ] Applied fix
- [ ] Ran verify to confirm
- [ ] Checked app logs for errors

---

## Time to Complete
- Scan (report): **1-2 seconds**
- Fix one user: **< 1 second**
- Fix 10 users: **5-10 seconds**
- Fix all users: **Depends on count**

---

## Rollback Plan
If issues occur:
1. Check logs for details
2. Run `verifyAllPoints()` to confirm
3. If needed, restore from Firestore backup

---

## Copy-Paste Commands

### Scan All Duplicates
```dart
final cleaner = DuplicatePointsCleaner();
final report = await cleaner.generateDuplicateReport();
for (final entry in (report['details'] as Map).entries) {
  print('${entry.key}: ${(entry.value as Map)['pointsDifference']} points excess');
}
```

### Fix Specific User
```dart
final cleaner = DuplicatePointsCleaner();
await cleaner.fixUserDuplicates('USER_ID');
print('Fixed!');
```

### Fix Multiple Users (CSV)
```dart
final cleaner = DuplicatePointsCleaner();
final users = 'user1,user2,user3'.split(',');
await cleaner.fixMultipleUsers(users);
```

### Get Summary Report
```dart
final cleaner = DuplicatePointsCleaner();
final report = await cleaner.generateDuplicateReport();
print('Scanned: ${report['totalUsersScanned']}');
print('Affected: ${report['usersWithDuplicates']}');
print('Duplicates: ${report['totalDuplicates']}');
```

---

## Where to Run This?
- Admin panel page
- Scheduled maintenance task
- Console/debugging command
- Database migration script

---

## Need Help?
1. Check `ADMIN_DUPLICATE_FIX_GUIDE.md` for detailed examples
2. Check `POINTS_DUPLICATE_FIX.md` for technical details
3. Review app logs for error messages
4. Check Firestore console for data verification
