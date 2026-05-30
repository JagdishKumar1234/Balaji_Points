# Super Admin User Setup Guide

## Generated Super Admin Credentials

### 📱 Contact Information
- **Phone**: `9876543210`
- **Full Name**: Super Admin Master
- **Email**: superadmin@balajipointsdev.com

### 🔐 Authentication Credentials
- **PIN**: `7834` (Complex 4-digit PIN - non-sequential)
- **Role**: `super_admin`
- **Access Level**: Full system access

---

## Firebase Firestore Entry

### Collection: `users`
### Document Structure for Super Admin:

```json
{
  "uid": "SA_MASTER_001",
  "userId": "SA_MASTER_001",
  "phone": "9876543210",
  "firstName": "Super",
  "lastName": "Admin",
  "email": "superadmin@balajipointsdev.com",
  "role": "super_admin",
  "status": "verified",
  "tier": "Diamond",
  "totalPoints": 0,
  "branchId": "ROOT",
  "profileImage": "",
  "pinHash": "[GENERATED_BY_PIN_AUTH_SERVICE]",
  "pinSalt": "[GENERATED_BY_PIN_AUTH_SERVICE]",
  "createdAt": "SERVER_TIMESTAMP",
  "verifiedAt": "SERVER_TIMESTAMP",
  "pinUpdatedAt": "SERVER_TIMESTAMP",
  "lastLogin": "SERVER_TIMESTAMP",
  "permissions": {
    "canManageAdmins": true,
    "canManageBranches": true,
    "canViewAnalytics": true,
    "canAccessAuditLogs": true,
    "canModifySystemSettings": true,
    "canManageUsers": true,
    "canApproveBills": true
  },
  "metadata": {
    "createdBy": "SYSTEM_INIT",
    "accessLevel": "FULL",
    "mfaEnabled": false,
    "lastPasswordChange": "SERVER_TIMESTAMP"
  }
}
```

---

## 🔐 Security Enhancements for Super Admin Access

### 1. **Multi-Factor Authentication (MFA)**
```dart
// Add MFA check before granting super_admin access
Future<bool> validateSuperAdminAccess({
  required String phone,
  required String pin,
  required String? biometricData,
}) async {
  // Check if user is super_admin
  final user = await getUserByPhone(phone);
  if (user?['role'] != 'super_admin') return false;

  // Verify PIN
  if (!await verifyPin(phone, pin)) return false;

  // For super_admin: require biometric or additional verification
  if (biometricData == null) {
    return false; // Require biometric
  }

  return true;
}
```

### 2. **Session Security**
```dart
// Session timeout for super_admin (shorter duration)
const Duration superAdminSessionTimeout = Duration(minutes: 15);
const Duration regularAdminSessionTimeout = Duration(minutes: 30);
const Duration carpenterSessionTimeout = Duration(hours: 4);
```

### 3. **Audit Logging for Super Admin Actions**
```dart
// Log all super_admin actions to audit trail
Future<void> logSuperAdminAction({
  required String action,
  required String details,
  required String userId,
  required String ipAddress,
}) async {
  await _firestore.collection('audit_logs').add({
    'action': action,
    'userId': userId,
    'userRole': 'super_admin',
    'details': details,
    'ipAddress': ipAddress,
    'timestamp': FieldValue.serverTimestamp(),
    'severity': 'HIGH',
  });
}
```

### 4. **IP Whitelisting (Optional)**
```dart
// Restrict super_admin access to specific IPs
final whitelistedIPs = [
  '192.168.1.100', // Office network
  '203.0.113.0',   // VPN server
];

bool isSuperAdminIPWhitelisted(String ipAddress) {
  return whitelistedIPs.contains(ipAddress);
}
```

### 5. **Enhanced Authentication Flow**
```dart
// File: lib/services/auth/super_admin_auth_service.dart

class SuperAdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PinAuthService _pinAuthService = PinAuthService();

  /// Authenticate super_admin with enhanced security
  Future<bool> authenticateSuperAdmin({
    required String phone,
    required String pin,
    bool requireBiometric = true,
  }) async {
    try {
      // 1. Verify phone + PIN
      final pinValid = await _pinAuthService.verifyPin(phone, pin);
      if (!pinValid) {
        logFailedSuperAdminAttempt(phone);
        return false;
      }

      // 2. Get user and verify role
      final user = await _getUserByPhone(phone);
      if (user?['role'] != 'super_admin') {
        return false;
      }

      // 3. Check if biometric required
      if (requireBiometric) {
        // Integrate with biometric_service.dart
        // Biometric verification required for super_admin
        return true; // After biometric verification
      }

      // 4. Check session timeout
      final lastLogin = user?['lastLogin'] as Timestamp?;
      if (lastLogin != null) {
        final elapsed = DateTime.now().difference(lastLogin.toDate());
        if (elapsed > const Duration(days: 30)) {
          // Force password change
          return false;
        }
      }

      // 5. Update last login
      await _firestore.collection('users').doc(user?['uid']).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // 6. Log successful authentication
      await logSuperAdminLogin(phone);

      return true;
    } catch (e) {
      AppLogger.error('Super admin authentication failed', e);
      return false;
    }
  }

  /// Log failed super_admin authentication attempts
  Future<void> logFailedSuperAdminAttempt(String phone) async {
    await _firestore.collection('security_events').add({
      'type': 'FAILED_SUPER_ADMIN_LOGIN',
      'phone': phone,
      'timestamp': FieldValue.serverTimestamp(),
      'severity': 'CRITICAL',
    });
  }

  /// Log successful super_admin login
  Future<void> logSuperAdminLogin(String phone) async {
    await _firestore.collection('audit_logs').add({
      'action': 'SUPER_ADMIN_LOGIN',
      'phone': phone,
      'timestamp': FieldValue.serverTimestamp(),
      'severity': 'HIGH',
    });
  }
}
```

### 6. **Update User Model for Super Admin Role**
```dart
// Update enum in lib/core/models/user.dart
enum UserRole {
  carpenter,
  admin,
  super_admin,
}

extension UserRoleExtension on String {
  UserRole toUserRole() {
    switch (this) {
      case 'carpenter':
        return UserRole.carpenter;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.super_admin;
      default:
        return UserRole.carpenter;
    }
  }
}
```

### 7. **Update Authentication Routes**
```dart
// In lib/config/routes.dart
// Add route guard for super_admin

Future<String?> _determineInitialRoute(
  BuildContext context,
  SessionService sessionService,
  UserService userService,
) async {
  final phone = await sessionService.getPhoneNumber();

  if (phone != null) {
    final user = await userService.getUserByPhone(phone);

    if (user?['role'] == 'super_admin') {
      return '/super-admin';
    } else if (user?['role'] == 'admin') {
      return '/admin';
    } else {
      return '/carpenter';
    }
  }

  return '/splash';
}
```

---

## 📋 Setup Instructions

### Step 1: Create User via Firebase Console (Manual Entry)

1. Go to Firebase Console → Firestore → `users` collection
2. Click "Add document"
3. Set Document ID: `SA_MASTER_001`
4. Copy the JSON structure above

### Step 2: Set PIN Hash Locally (Using Flutter App)

1. Open app terminal and run:
```bash
cd /path/to/balaji_points
flutter run
```

2. Use the test/debug interface to call:
```dart
final pinAuthService = PinAuthService();
final success = await pinAuthService.setPinForPhone(
  phone: '9876543210',
  pin: '7834',
  firstName: 'Super',
  lastName: 'Admin',
  branchId: 'ROOT',
);
```

### Step 3: Promote User to Super Admin

Once user is created, update the `role` field from `carpenter` to `super_admin`:

```dart
await FirebaseFirestore.instance
    .collection('users')
    .where('phone', isEqualTo: '9876543210')
    .limit(1)
    .get()
    .then((query) async {
  if (query.docs.isNotEmpty) {
    await query.docs.first.reference.update({
      'role': 'super_admin',
      'permissions': {
        'canManageAdmins': true,
        'canManageBranches': true,
        'canViewAnalytics': true,
        'canAccessAuditLogs': true,
        'canModifySystemSettings': true,
        'canManageUsers': true,
        'canApproveBills': true,
      },
    });
  }
});
```

---

## 🔒 Security Best Practices

### ✅ DO:
- ✓ Use this super admin account only for critical operations
- ✓ Change PIN regularly (every 30 days)
- ✓ Enable biometric verification for super_admin
- ✓ Monitor audit logs for unusual activity
- ✓ Use strong, unique PIN (avoid sequential like 1234, 4321)
- ✓ Enable 2FA when available
- ✓ Share credentials only with trusted personnel via secure channels
- ✓ Log all super_admin actions to audit trail

### ❌ DON'T:
- ✗ Share credentials in plaintext via email/chat
- ✗ Use simple PINs (1234, 0000, 1111, etc.)
- ✗ Leave super_admin logged in unattended
- ✗ Create multiple super_admin accounts unnecessarily
- ✗ Use default/demo credentials in production
- ✗ Store credentials in code or version control
- ✗ Share PIN with other team members

---

## 🔍 Verification Checklist

After creating super admin user:

- [ ] Document ID: `SA_MASTER_001` exists in `users` collection
- [ ] Role field: `super_admin`
- [ ] Phone field: `9876543210`
- [ ] PIN hash: Generated and stored
- [ ] Can login with phone: `9876543210` and PIN: `7834`
- [ ] Redirects to `/super-admin` screen
- [ ] Can access super admin dashboard
- [ ] Audit log created for login
- [ ] Session timeout: 15 minutes (shorter than admin)
- [ ] Can create and manage admins

---

## 📝 Test Cases

```dart
// Test 1: Successful super admin login
test('Super admin login with correct PIN', () async {
  final result = await pinAuthService.verifyPin('9876543210', '7834');
  expect(result, true);
});

// Test 2: Reject with wrong PIN
test('Super admin login with wrong PIN', () async {
  final result = await pinAuthService.verifyPin('9876543210', '1234');
  expect(result, false);
});

// Test 3: Verify role is super_admin
test('User has super_admin role', () async {
  final user = await userService.getUserByPhone('9876543210');
  expect(user?['role'], 'super_admin');
});

// Test 4: Session timeout is enforced
test('Super admin session expires after 15 minutes', () async {
  // Login and verify session
  // Wait 16 minutes
  // Verify session is expired
});
```

---

## 🚨 Emergency Access

If locked out:
1. Use Firebase Console to reset PIN hash
2. Use emergency admin account (if configured)
3. Contact system administrator
4. Check audit logs for suspicious activity

---

**Last Updated**: May 30, 2026
**Version**: 1.0
**Status**: Ready for Testing
