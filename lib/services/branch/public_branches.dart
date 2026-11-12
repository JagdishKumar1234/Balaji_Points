import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/app_firestore.dart';

/// A branch as guests see it: where it is and how to reach it.
class PublicBranch {
  const PublicBranch({
    required this.id,
    required this.name,
    this.shortName = '',
    this.address = '',
    this.phone = '',
    this.mapsUrl = '',
  });

  final String id;
  final String name;
  final String shortName;
  final String address;
  final String phone;

  /// Google Maps link set by the super admin (exact pin), if any.
  final String mapsUrl;

  /// Short label for pickers ("Karur Branch"), else the full name.
  String get label => shortName.isNotEmpty ? shortName : name;

  /// The super admin's map link when set; otherwise a Maps search for the
  /// store name and address, which finds the shop or its street.
  Uri get directions => mapsUrl.startsWith('https://')
      ? Uri.parse(mapsUrl)
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': [name, address].where((s) => s.isNotEmpty).join(', '),
        });

  /// Phone ready for the dialer ("96006-09121" -> "+919600609121").
  String get dialable {
    final d = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) return d;
    return d.length == 10 ? '+91$d' : d;
  }

  factory PublicBranch.fromMap(String id, Map<String, dynamic> d) =>
      PublicBranch(
        id: id,
        name: (d['name'] as String? ?? id).trim(),
        shortName: (d['shortName'] as String? ?? '').trim(),
        address: (d['address'] as String? ?? '').trim(),
        phone: (d['phone'] as String? ?? '').trim(),
        mapsUrl: (d['mapsUrl'] as String? ?? '').trim(),
      );
}

/// Active branches, sorted by name. Kept for the session.
final publicBranchesProvider = StreamProvider<List<PublicBranch>>(
  (ref) => appFirestore
      .collection('branches')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => PublicBranch.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      ),
);
