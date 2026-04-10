import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/services/session_service.dart';

class UserPointsService {
  UserPointsService({
    FirebaseFirestore? firestore,
    SessionService? sessionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _sessionService = sessionService ?? SessionService();

  final FirebaseFirestore _firestore;
  final SessionService _sessionService;

  Future<DocumentReference<Map<String, dynamic>>?>
  resolveCurrentUserPointsDocRef() async {
    final userId = await _sessionService.getUserId();
    final phoneNumber = await _sessionService.getPhoneNumber();
    final candidateIds = <String>{
      if (userId != null && userId.isNotEmpty) userId,
      if (phoneNumber != null && phoneNumber.isNotEmpty) phoneNumber,
    };

    for (final candidateId in candidateIds) {
      final docRef = _firestore.collection('user_points').doc(candidateId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return docRef;
      }
    }

    for (final candidateId in candidateIds) {
      final query = await _firestore
          .collection('user_points')
          .where('userId', isEqualTo: candidateId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.reference;
      }
    }

    return null;
  }
}
