# Admin Guide: Fixing Duplicate Points

## Quick Start

### Step 1: Identify Users with Duplicates

```dart
import 'package:balaji_points/services/maintenance/duplicate_points_cleaner.dart';

final cleaner = DuplicatePointsCleaner();

// Generate detailed report
final report = await cleaner.generateDuplicateReport();

print('Users with duplicates: ${report['usersWithDuplicates']}');
print('Total duplicate entries: ${report['totalDuplicates']}');

// Print details for each affected user
for (final entry in (report['details'] as Map).entries) {
  final userId = entry.key;
  final details = entry.value as Map<String, dynamic>;
  
  print('User: $userId');
  print('  Stored Total: ${details['storedTotal']}');
  print('  Correct Total: ${details['correctTotal']}');
  print('  Lost Points: ${details['pointsDifference']}');
  print('  Duplicate Bills: ${details['duplicateCount']}');
}
```

### Step 2: Fix Specific Users

#### Option A: Fix One User
```dart
final cleaner = DuplicatePointsCleaner();

final userId = 'user123';
final success = await cleaner.fixUserDuplicates(userId);

if (success) {
  print('✅ Fixed duplicates for $userId');
} else {
  print('❌ Failed to fix $userId');
}
```

#### Option B: Fix Multiple Users
```dart
final cleaner = DuplicatePointsCleaner();

final userIds = ['user1', 'user2', 'user3', 'user4'];
final results = await cleaner.fixMultipleUsers(userIds);

// Check results
for (final entry in results.entries) {
  final status = entry.value ? '✅' : '❌';
  print('$status ${entry.key}');
}
```

#### Option C: Fix All Users
```dart
final cleaner = DuplicatePointsCleaner();
final fixedCount = await cleaner.fixDuplicates();

print('Fixed $fixedCount duplicate entries globally');
```

## Detailed Methods

### 1. generateDuplicateReport() - Scan & Report
**Returns:** Map with complete report of all duplicates

```dart
final report = await cleaner.generateDuplicateReport();

// Report structure:
{
  'timestamp': '2026-06-10T15:30:00.000Z',
  'totalUsersScanned': 150,
  'usersWithDuplicates': 5,
  'totalDuplicates': 8,
  'details': {
    'user1': {
      'userId': 'user1',
      'storedTotal': 250.0,      // Current (with duplicates)
      'correctTotal': 200.0,     // Should be
      'pointsDifference': 50.0,  // Extra points given
      'duplicateCount': 2,       // Number of duplicate bills
      'duplicates': [
        {
          'billId': 'bill123',
          'occurrences': 2,      // Appeared 2 times
          'entries': [...]
        }
      ]
    }
  }
}
```

### 2. fixUserDuplicates(userId) - Fix One User
**Returns:** `bool` (success/failure)

What it does:
- Removes duplicate pointsHistory entries
- Keeps first occurrence of each billId
- Recalculates totalPoints
- Updates tier based on new total
- Records timestamp

```dart
final success = await cleaner.fixUserDuplicates('user123');
```

### 3. fixMultipleUsers(userIds) - Fix List
**Returns:** `Map<String, bool>` (userId → success)

```dart
final results = await cleaner.fixMultipleUsers([
  'user1',
  'user2',
  'user3'
]);

results.forEach((userId, success) {
  print('$userId: ${success ? 'Fixed' : 'Failed'}');
});
```

### 4. fixDuplicates() - Fix All
**Returns:** `int` (number of entries fixed)

```dart
final fixedCount = await cleaner.fixDuplicates();
// Fixes all users with duplicates
```

### 5. verifyUserPoints(userId) - Verify One
**Returns:** `void` (logs results)

Checks if `totalPoints` = sum of all `pointsHistory[*].points`

```dart
await cleaner.verifyUserPoints('user123');
// Logs: "Points verified: 200.0" or "Fixed points for user123: 250.0 → 200.0"
```

### 6. verifyAllPoints() - Verify All
**Returns:** `int` (number of mismatches fixed)

```dart
final fixedCount = await cleaner.verifyAllPoints();
print('Fixed $fixedCount point mismatches');
```

## Real-World Examples

### Scenario 1: One User Has Too Many Points
```dart
// User 'carp_john' should have 500 points but has 750
final report = await cleaner.generateDuplicateReport();
final userDetails = report['details']['carp_john'];

print('Lost points: ${userDetails['pointsDifference']}'); // 250

// Fix it
await cleaner.fixUserDuplicates('carp_john');

// Verify
await cleaner.verifyUserPoints('carp_john');
```

### Scenario 2: Multiple Users Affected
```dart
// Find all affected users
final report = await cleaner.generateDuplicateReport();
final affectedUsers = (report['details'] as Map).keys.toList();

print('Users with duplicates: $affectedUsers');

// Fix all of them
final results = await cleaner.fixMultipleUsers(affectedUsers);

// Show summary
int successful = results.values.where((v) => v).length;
print('Fixed $successful/${affectedUsers.length} users');
```

### Scenario 3: Audit Trail
```dart
// Get all details about duplicates before fixing
final report = await cleaner.generateDuplicateReport();

// Log each duplicate
for (final entry in (report['details'] as Map).entries) {
  final userId = entry.key;
  final details = entry.value as Map<String, dynamic>;
  
  print('=== User: $userId ===');
  print('Points Error: ${details['pointsDifference']} points excess');
  
  for (final dup in details['duplicates'] as List) {
    print('  - Bill ${dup['billId']}: appeared ${dup['occurrences']} times');
  }
}

// Now fix
await cleaner.fixDuplicates();
```

## Safety Checks

### Before Fixing:
1. ✅ Generate report and save it
2. ✅ Review which users are affected
3. ✅ Check how many points will be adjusted
4. ✅ Communicate with users if needed

### During Fixing:
1. ✅ Points only decrease (extras removed)
2. ✅ Tier may downgrade if points drop
3. ✅ All changes timestamped
4. ✅ Each action logged

### After Fixing:
1. ✅ Run verifyAllPoints() to confirm
2. ✅ Check affected users' wallets
3. ✅ Confirm no errors in logs

## Database Changes Made

When fixing a user, the following fields are updated:
- `pointsHistory` - Duplicates removed
- `totalPoints` - Recalculated
- `tier` - Updated based on new points
- `lastUpdated` - Current timestamp
- `cleanedAt` - When cleaning happened

**Example Before:**
```json
{
  "userId": "user123",
  "totalPoints": 250,
  "tier": "Silver",
  "pointsHistory": [
    {"billId": "B1", "points": 50, "reason": "Bill approval"},
    {"billId": "B1", "points": 50, "reason": "Bill approval"},  // DUPLICATE!
    {"billId": "B2", "points": 100, "reason": "Bill approval"},
    {"billId": "B2", "points": 50, "reason": "Bill approval"}   // DUPLICATE!
  ]
}
```

**Example After:**
```json
{
  "userId": "user123",
  "totalPoints": 200,
  "tier": "Silver",
  "pointsHistory": [
    {"billId": "B1", "points": 50, "reason": "Bill approval"},
    {"billId": "B2", "points": 100, "reason": "Bill approval"}
  ],
  "cleanedAt": "2026-06-10T15:30:00Z"
}
```

## Integration into Admin Panel (Optional)

You can add this to an admin dashboard page:

```dart
class AdminDuplicateFixPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Fix Duplicate Points')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final cleaner = DuplicatePointsCleaner();
              final report = await cleaner.generateDuplicateReport();
              // Show report to admin
            },
            child: Text('Scan for Duplicates'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cleaner = DuplicatePointsCleaner();
              final count = await cleaner.fixDuplicates();
              // Show success message
            },
            child: Text('Fix All Duplicates'),
          ),
        ],
      ),
    );
  }
}
```

## Troubleshooting

### Issue: "User points doc not found"
- User might not have earned any points yet
- Check if user exists in `users` collection
- Points tracking starts after first bill approval

### Issue: "No duplicates found"
- No duplicate entries for that user
- Previous fix already applied
- Run verifyAllPoints() instead

### Issue: "Error fixing user"
- Check Firestore permissions
- Ensure user_points collection exists
- Check logs for specific error

## Questions?

Common questions answered:
- **Q: Will users lose legitimate points?**
  A: No. Only duplicate entries for the same billId are removed.

- **Q: Can I undo the fix?**
  A: Points are recalculated from original pointsHistory. To restore, you'd need to restore from backup or manually add back.

- **Q: Do users get notified?**
  A: The fix is silent. Admins might want to notify affected users.

- **Q: Is it safe to run multiple times?**
  A: Yes! Running again will detect no duplicates and do nothing.

- **Q: What if I run while points are being approved?**
  A: Safe. New approvals won't be affected by historical cleanup.
