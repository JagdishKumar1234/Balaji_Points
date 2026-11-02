import 'package:cloud_functions/cloud_functions.dart';

class SuperAdminService {
  SuperAdminService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<BranchAdminResult> createBranchAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String branchId,
  }) async {
    final callable = _functions.httpsCallable('createBranchAdmin');
    final response = await callable.call({
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'branchId': branchId,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return BranchAdminResult(
      email: data['email'] as String? ?? email,
      branchName: data['branchName'] as String? ?? branchId,
    );
  }

  Future<void> updateBranchAdminPassword({
    required String uid,
    required String password,
  }) async {
    await _functions.httpsCallable('updateBranchAdminPassword').call({
      'uid': uid,
      'password': password,
    });
  }

  Future<void> deleteBranchAdmin(String uid) async {
    await _functions.httpsCallable('deleteBranchAdmin').call({'uid': uid});
  }

  Future<BranchPointsResetPreview> previewBranchPointsReset(
    String branchId,
  ) async {
    final callable = _functions.httpsCallable(
      'previewBranchPointsReset',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
    );
    final response = await callable.call({'branchId': branchId});
    final data = Map<String, dynamic>.from(response.data as Map);
    return BranchPointsResetPreview.fromMap(data);
  }

  Future<BranchPointsResetResult> clearBranchPoints({
    required String branchId,
    required String confirmBranchId,
    required int expectedUsers,
  }) async {
    final callable = _functions.httpsCallable(
      'clearBranchPoints',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 8)),
    );
    final response = await callable.call({
      'branchId': branchId,
      'confirmBranchId': confirmBranchId,
      'expectedUsers': expectedUsers,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return BranchPointsResetResult.fromMap(data);
  }
}

class BranchAdminResult {
  const BranchAdminResult({required this.email, required this.branchName});

  final String email;
  final String branchName;
}

class BranchPointsResetPreview {
  const BranchPointsResetPreview({
    required this.branchId,
    required this.branchName,
    required this.eligibleUsers,
    required this.pointsDocuments,
    required this.historyDocuments,
    required this.embeddedHistoryEntries,
    required this.currentPoints,
  });

  final String branchId;
  final String branchName;
  final int eligibleUsers;
  final int pointsDocuments;
  final int historyDocuments;
  final int embeddedHistoryEntries;
  final num currentPoints;

  factory BranchPointsResetPreview.fromMap(Map<String, dynamic> data) =>
      BranchPointsResetPreview(
        branchId: data['branchId'] as String? ?? '',
        branchName: data['branchName'] as String? ?? '',
        eligibleUsers: (data['eligibleUsers'] as num?)?.toInt() ?? 0,
        pointsDocuments: (data['pointsDocuments'] as num?)?.toInt() ?? 0,
        historyDocuments: (data['historyDocuments'] as num?)?.toInt() ?? 0,
        embeddedHistoryEntries:
            (data['embeddedHistoryEntries'] as num?)?.toInt() ?? 0,
        currentPoints: data['currentPoints'] as num? ?? 0,
      );
}

class BranchPointsResetResult {
  const BranchPointsResetResult({
    required this.branchName,
    required this.usersReset,
    required this.pointsDocumentsReset,
    required this.historyDocumentsDeleted,
  });

  final String branchName;
  final int usersReset;
  final int pointsDocumentsReset;
  final int historyDocumentsDeleted;

  factory BranchPointsResetResult.fromMap(Map<String, dynamic> data) =>
      BranchPointsResetResult(
        branchName: data['branchName'] as String? ?? '',
        usersReset: (data['usersReset'] as num?)?.toInt() ?? 0,
        pointsDocumentsReset:
            (data['pointsDocumentsReset'] as num?)?.toInt() ?? 0,
        historyDocumentsDeleted:
            (data['historyDocumentsDeleted'] as num?)?.toInt() ?? 0,
      );
}
