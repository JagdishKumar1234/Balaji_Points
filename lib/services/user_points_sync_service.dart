import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:balaji_points/services/user_points_service.dart';

/// Global singleton that keeps one live points subscription for the app.
/// All screens (home/wallet/profile) can listen to [pointsData] so they stay synced.
class UserPointsSyncService {
  UserPointsSyncService._internal();
  static final UserPointsSyncService _instance = UserPointsSyncService._internal();
  factory UserPointsSyncService() => _instance;

  final UserPointsService _userPointsService = UserPointsService();

  final ValueNotifier<Map<String, dynamic>?> pointsData =
      ValueNotifier<Map<String, dynamic>?>(null);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? _subscribedDocPath;
  bool _isStarting = false;

  Future<void> start() async {
    if (_isStarting) return;
    _isStarting = true;
    try {
      final pointsDocRef = await _userPointsService.resolveCurrentUserPointsDocRef();
      if (pointsDocRef == null) return;

      if (_subscribedDocPath == pointsDocRef.path && _subscription != null) {
        return;
      }

      await _subscription?.cancel();
      _subscribedDocPath = pointsDocRef.path;
      _subscription = pointsDocRef.snapshots().listen((snapshot) {
        pointsData.value = snapshot.data();
      });
    } finally {
      _isStarting = false;
    }
  }

  Future<void> refresh() async {
    _subscribedDocPath = null;
    await start();
  }
}

