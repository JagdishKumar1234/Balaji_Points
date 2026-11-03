import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

FirebaseFirestore? _override;

/// The Firestore instance used by services and screens.
/// Always [FirebaseFirestore.instance] in the app; tests can swap in a fake.
FirebaseFirestore get appFirestore => _override ?? FirebaseFirestore.instance;

@visibleForTesting
void overrideAppFirestoreForTesting(FirebaseFirestore? firestore) =>
    _override = firestore;
