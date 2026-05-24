import 'package:cloud_firestore/cloud_firestore.dart';

/// Sorts bill documents newest-first without requiring a Firestore composite index.
List<QueryDocumentSnapshot> sortBillsByCreatedAtDesc(
  Iterable<QueryDocumentSnapshot> docs,
) {
  final sorted = docs.toList();
  sorted.sort((a, b) {
    final aMs = _createdAtMillis((a.data() as Map<String, dynamic>)['createdAt']);
    final bMs = _createdAtMillis((b.data() as Map<String, dynamic>)['createdAt']);
    return bMs.compareTo(aMs);
  });
  return sorted;
}

int _createdAtMillis(Object? value) {
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is DateTime) return value.millisecondsSinceEpoch;
  return 0;
}
