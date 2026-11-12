import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/firebase/app_firestore.dart';
import '../../core/models/enquiry.dart';
import '../auth/session_service.dart';
import '../branch/current_branch_service.dart';

/// Who is sending: a logged-in member (name, phone, branch and role filled
/// from the session) or a guest (nothing known).
class EnquirySender {
  const EnquirySender.guest()
    : isMember = false,
      name = '',
      phone = '',
      userId = null,
      branchId = null,
      branchName = '',
      role = null;

  const EnquirySender.member({
    required this.name,
    required this.phone,
    required this.userId,
    required this.branchId,
    required this.role,
    this.branchName = '',
  }) : isMember = true;

  final bool isMember;
  final String name;
  final String phone;
  final String? userId;
  final String? branchId;
  final String branchName;
  final String? role;
}

class EnquiryTooSoon implements Exception {
  const EnquiryTooSoon(this.wait);
  final Duration wait;
}

/// Contact Us enquiries. Members' enquiries go to their own branch admin;
/// guests' go to the super admin. Firestore rules check every field, since
/// members log in with a PIN and have no Firebase sign-in.
class EnquiryService {
  EnquiryService({FirebaseFirestore? db, SessionService? session})
    : _db = db ?? appFirestore,
      _session = session ?? SessionService();

  final FirebaseFirestore _db;
  final SessionService _session;

  /// One enquiry per phone every few minutes, so a double tap or an
  /// impatient resend does not flood the admin.
  static const cooldown = Duration(minutes: 2);
  static const _lastSentKey = 'enquiryLastSentAt';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('enquiries');

  /// Members get their details pre-filled; anyone else is a guest.
  Future<EnquirySender> currentSender() async {
    final saved = (await _session.getUserRole())?.trim().toLowerCase() ?? '';
    // Every logged-in account except admins is a member of its own branch:
    // the 4 built-in roles, custom roles from the super admin, and older
    // accounts with no role saved (they count as carpenters).
    final role = saved.isEmpty ? AppConstants.roleCarpenter : saved;
    final branchId = (await _session.getBranchId())?.trim();
    final userId = (await _session.getUserId())?.trim();
    final isAdmin =
        role == AppConstants.roleAdmin || role == AppConstants.roleSuperAdmin;
    if (isAdmin ||
        branchId == null ||
        branchId.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return const EnquirySender.guest();
    }
    final first = (await _session.getFirstName())?.trim() ?? '';
    final last = (await _session.getLastName())?.trim() ?? '';
    var branchName = '';
    try {
      final b = await _db.collection('branches').doc(branchId).get();
      branchName = (b.data()?['name'] as String? ?? '').trim();
    } catch (_) {}
    return EnquirySender.member(
      name: '$first $last'.trim(),
      phone: (await _session.getPhoneNumber())?.trim() ?? '',
      userId: userId,
      branchId: branchId,
      branchName: branchName,
      role: role,
    );
  }

  Future<void> submit({
    required EnquirySender sender,
    required EnquiryType type,
    required String name,
    required String phone,
    required String message,
    String city = '',
    String appVersion = '',
    String? guestBranchId,
    String guestBranchName = '',
    String position = '',
    String experience = '',
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final clock = now ?? DateTime.now();
    final last = prefs.getInt(_lastSentKey) ?? 0;
    final since = clock.difference(DateTime.fromMillisecondsSinceEpoch(last));
    if (!since.isNegative && since < cooldown) {
      throw EnquiryTooSoon(cooldown - since);
    }

    final data = <String, dynamic>{
      'type': type.id,
      'name': name.trim(),
      'phone': phone.trim(),
      'message': message.trim(),
      'source': sender.isMember ? 'member' : 'guest',
      'status': EnquiryStatus.open.id,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      if (appVersion.isNotEmpty) 'appVersion': appVersion,
    };
    if (sender.isMember) {
      data['userId'] = sender.userId;
      data['branchId'] = sender.branchId;
      data['role'] = sender.role;
      if (sender.branchName.isNotEmpty) data['branchName'] = sender.branchName;
    } else {
      // A guest picks the branch; its admin gets the enquiry.
      if (guestBranchId != null && guestBranchId.isNotEmpty) {
        data['branchId'] = guestBranchId;
        if (guestBranchName.trim().isNotEmpty) {
          data['branchName'] = guestBranchName.trim();
        }
      }
      if (city.trim().isNotEmpty) data['city'] = city.trim();
    }
    if (type == EnquiryType.career) {
      if (position.trim().isNotEmpty) data['position'] = position.trim();
      if (experience.trim().isNotEmpty) data['experience'] = experience.trim();
    }
    await _col.add(data);
    await prefs.setInt(_lastSentKey, clock.millisecondsSinceEpoch);
  }

  // ── Admin side ───────────────────────────────────────────────────────────

  /// A branch admin's enquiries ([branchId] set: that branch's members and
  /// the guests who picked it), or the super admin's view of every guest
  /// enquiry ([branchId] null). Newest first, sorted on the phone so no index is needed.
  Stream<List<Enquiry>> watch({String? branchId}) {
    final q = branchId == null
        ? _col.where('source', isEqualTo: 'guest')
        : _col.where('branchId', isEqualTo: branchId);
    return q.snapshots().map(
      (s) => s.docs.map(Enquiry.fromDoc).toList()
        ..sort(
          (a, b) => (b.createdAt ?? DateTime(9999)).compareTo(
            a.createdAt ?? DateTime(9999),
          ),
        ),
    );
  }

  Future<void> setResolved(Enquiry e, bool resolved) => _col.doc(e.id).update({
    'status': resolved ? EnquiryStatus.resolved.id : EnquiryStatus.open.id,
    'resolvedAt': resolved ? FieldValue.serverTimestamp() : FieldValue.delete(),
    'resolvedBy': resolved
        ? FirebaseAuth.instance.currentUser?.uid ?? ''
        : FieldValue.delete(),
  });
}

final enquiryServiceProvider = Provider<EnquiryService>(
  (ref) => EnquiryService(),
);

final enquirySenderProvider = FutureProvider.autoDispose<EnquirySender>(
  (ref) => ref.watch(enquiryServiceProvider).currentSender(),
);

/// Admin inbox: a branch id = that branch's member enquiries (branch
/// admin); `null` = guest enquiries only, with no branch (super admin).
///
/// Kept for the whole session (not auto-disposed): the dashboard starts it
/// and shows the open count, so the Enquiries screen opens with the list
/// already there and only live changes arrive after that.
final enquiriesProvider = StreamProvider.family<List<Enquiry>, String?>(
  (ref, branchId) {
    // The rules let only a Firebase-signed-in admin read enquiries. A PIN
    // login has no Firebase sign-in, so do not even ask: asking shows the
    // cached count, then the server refuses and it vanishes, over and over.
    if (!ref.watch(firebaseSignedInProvider)) {
      return Stream.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
    }
    return ref.watch(enquiryServiceProvider).watch(branchId: branchId);
  },
  // A refusal will not change by asking again; retrying made the dashboard
  // count flicker every few seconds.
  retry: (_, __) => null,
);

/// Whether this session has a Firebase sign-in (email / Google admins do;
/// PIN logins do not). Follows sign-in and sign-out while the app runs.
final firebaseSignedInProvider = NotifierProvider<_FirebaseSignedIn, bool>(
  _FirebaseSignedIn.new,
);

class _FirebaseSignedIn extends Notifier<bool> {
  @override
  bool build() {
    final auth = FirebaseAuth.instance;
    final sub = auth.authStateChanges().listen((u) => state = u != null);
    ref.onDispose(sub.cancel);
    return auth.currentUser != null;
  }
}

/// The key a branch admin's dashboard and inbox both use, so they share one
/// cached list. Matches [BranchScopedQuery.forAdminBranch].
String adminEnquiriesKey() =>
    CurrentBranchService.adminBranchId ?? '__no_branch__';
