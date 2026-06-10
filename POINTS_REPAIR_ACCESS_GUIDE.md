# How to Access Points Repair Tool in Admin Panel

## Location

The Points Repair Tool is now integrated into the **Admin Dashboard**.

### Access Steps

1. **Open Admin Panel**
   - Login to your admin account
   - Navigate to the admin home page

2. **Find Points Repair Card**
   - Look at the main dashboard grid
   - Find the **"Points Repair"** card with a build/wrench icon 🔧
   - It's in the second row of the dashboard

3. **Click the Card**
   - Click "Points Repair"
   - The tool opens in the admin panel

## Dashboard Layout

```
Dashboard Cards (Grid Layout):
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Pending     │ Bill        │ Offers      │ Users       │
│ Bills   📄  │ History  📊  │ 🏷️          │ 👥         │
├─────────────┼─────────────┼─────────────┼─────────────┤
│ Notif       │ Products    │ Orders      │ Spin        │
│ 🔔          │ 📦          │ 🛒          │ 🎰          │
├─────────────┼─────────────┼─────────────┼─────────────┤
│ Points      │ (future)    │ (future)    │ (future)    │
│ Repair  🔧  │             │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

The **Points Repair 🔧** card is in the third row, first column.

## Points Repair Tool Interface

Once opened, you'll see:

```
┌────────────────────────────────────────┐
│  Points Repair Tool                    │
├────────────────────────────────────────┤
│                                        │
│  ℹ️ Points Data Repair                 │
│  This tool scans user points data and  │
│  fixes:                                │
│  • Duplicate history entries           │
│  • Inconsistent totalPoints            │
│  • Mismatched tiers                    │
│                                        │
│  [Scan for Issues Button]              │
│                                        │
└────────────────────────────────────────┘
```

## Quick Usage

### Step 1: Scan
```
Click "Scan for Issues"
         ↓
Wait 2-3 seconds
         ↓
View Report:
  • Users scanned: X
  • Users with issues: Y
  • Duplicates found: Z
```

### Step 2: Repair (if issues found)
```
Click "Repair All Users"
         ↓
Confirm in dialog
         ↓
Wait 10-30 seconds
         ↓
View Results
```

### Step 3: Verify
```
Go to Profile → Check points
Go to Home → Check points
Go to Wallet → Check points
All should match ✅
```

## What Points Repair Does

### Scans For:
- Duplicate entries in pointsHistory
- Inconsistent totalPoints values
- Mismatched tier assignments
- Collection inconsistencies

### Fixes:
- Removes duplicate history entries
- Recalculates correct totalPoints
- Updates tier based on correct points
- Syncs both collections atomically

### Preserves:
- All legitimate points (no loss)
- Original transaction dates
- User identity and profile
- First occurrence of each bill

## Integration Details

### File Changes
- `lib/presentation/screens/admin/admin_home_page.dart` - Added navigation
- `lib/presentation/widgets/admin/admin_dashboard.dart` - Added dashboard card
- `lib/presentation/screens/admin/points_repair_page.dart` - Tool UI

### How It Works
1. Dashboard displays "Points Repair" card
2. Clicking opens PointsRepairPage
3. PointsRepairPage uses PointsSyncRepairService
4. Service scans and repairs Firestore data
5. Results display in the UI

## Section Routing

In admin_home_page.dart:
```
Route: 'points-repair'
Component: PointsRepairPage()
Title: 'Points Repair'
```

## Features Available

✅ **Scan Only** (Safe, read-only)
- No data modification
- Detailed report
- Identify issues

✅ **Full Repair** (Atomic operation)
- Remove duplicates
- Recalculate totals
- Sync collections
- Verify results

✅ **Progress Indication**
- Loading spinner during repair
- Results display
- Success/error messages

✅ **Error Handling**
- Network errors
- Permission errors
- Invalid data
- All logged and reported

## Navigation Flow

```
Admin Panel Home (Dashboard)
         ↓
   [Points Repair Card] 🔧
         ↓
 Points Repair Tool
         ↓
   [Scan for Issues]
         ↓
   Report Display
         ↓
  [Repair All Users]
         ↓
  Repair Results
```

## Back Navigation

To return to the dashboard:
- Click back button (←) in top-left
- Or use device back button
- Dashboard reloads normally

## Troubleshooting

### Card Not Visible?
1. Check you're logged in as admin
2. Refresh the page
3. Check Firebase permissions

### Can't Click the Card?
1. Check network connection
2. Wait for initial load to complete
3. Try refreshing

### Tool Doesn't Open?
1. Check app logs
2. Verify navigation setup
3. Check route configuration

## Future Enhancements

Possible additions:
- [ ] Repair individual user
- [ ] Repair specific users by ID
- [ ] Schedule automatic repairs
- [ ] Repair history/logs
- [ ] Bulk user repair options

## Documentation

For detailed information, see:
- `POINTS_SYNC_REPAIR_GUIDE.md` - Technical details
- `HOW_TO_USE_REPAIR_TOOL.md` - Step-by-step guide
- `QUICK_REPAIR_STEPS.md` - Quick reference

## Support

If you encounter issues:
1. Check app logs for error messages
2. Review the documentation
3. Verify Firestore permissions
4. Check network connection

---

## Summary

**Access:** Admin Panel → Dashboard → Points Repair Card 🔧

**Steps:** 
1. Click card
2. Click "Scan for Issues"
3. Review report
4. Click "Repair All Users" if needed
5. Verify in app

**Result:** All user points synchronized ✅
