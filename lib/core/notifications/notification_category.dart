import 'package:flutter/material.dart';

import 'package:balaji_points/l10n/app_localizations.dart';

/// What a notification is about. Decides its icon, its filter chip on the
/// Notifications screen, and the screen a tap opens.
///
/// Admin announcements carry their category (`category` field, chosen by the
/// admin); every other notification gets one from its `type`.
enum NotificationCategory {
  /// Plain message for any other reason: no link, no highlight.
  normal('normal', Icons.notifications_rounded, null),
  general('general', Icons.campaign_rounded, null),
  offer('offer', Icons.local_offer_rounded, '/'),
  catalog('catalog', Icons.menu_book_rounded, '/catalogs'),
  // Members never spin (only the admin does); they see today's winner on
  // Home.
  dailySpin('dailySpin', Icons.emoji_events_rounded, '/'),
  addBill('addBill', Icons.receipt_long_rounded, '/add-bill'),
  wallet('wallet', Icons.account_balance_wallet_rounded, '/wallet'),
  festival('festival', Icons.celebration_rounded, '/'),
  branch('branch', Icons.storefront_rounded, '/my-branch'),

  // Personal notifications only; an admin cannot pick these.
  bill('bill', Icons.receipt_rounded, '/wallet'),
  points('points', Icons.emoji_events_rounded, '/wallet'),
  account('account', Icons.verified_user_rounded, '/profile');

  const NotificationCategory(this.id, this.icon, this.route);

  /// Stored in `notification_logs.category` and sent to the Cloud Function.
  final String id;
  final IconData icon;

  /// Screen a tap opens, or null to stay on the list.
  final String? route;

  /// The ones an admin can choose when sending (same list as the server's
  /// CATEGORIES in functions/role_broadcast.js).
  static const sendable = [
    normal,
    general,
    offer,
    festival,
    catalog,
    dailySpin,
    addBill,
    wallet,
    branch,
  ];

  /// Bottom-nav tabs: opened with `go`, the rest are pushed so Back returns
  /// to the list.
  bool get isTab => route == '/' || route == '/wallet' || route == '/profile';

  static NotificationCategory? fromId(String? id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The category of a `notification_logs` record.
  static NotificationCategory of(Map<String, dynamic>? data) {
    if (data == null) return general;
    final inner = data['data'];
    final explicit =
        fromId(data['category'] as String?) ??
        (inner is Map ? fromId(inner['category'] as String?) : null);
    if (explicit != null) return explicit;
    switch (data['type'] as String?) {
      case 'billApproved':
      case 'billRejected':
      case 'billSubmitted':
        return bill;
      case 'pointsWithdrawn':
      case 'tierUpgraded':
      case 'pointsMilestone':
        return points;
      case 'dailySpinWon':
        return dailySpin;
      case 'newOfferAvailable':
      case 'offerRedeemed':
        return offer;
      case 'greeting':
        return festival;
      case 'accountApproved':
        return account;
      default:
        return general;
    }
  }

  String label(AppLocalizations l10n) => switch (this) {
    normal => l10n.notifCatNormal,
    general => l10n.notifCatGeneral,
    offer => l10n.notifCatOffer,
    catalog => l10n.notifCatCatalog,
    dailySpin => l10n.notifCatDailySpin,
    addBill => l10n.notifCatAddBill,
    wallet => l10n.notifCatWallet,
    festival => l10n.notifCatFestival,
    branch => l10n.notifCatBranch,
    bill => l10n.notifCatBill,
    points => l10n.notifCatPoints,
    account => l10n.notifCatAccount,
  };

  /// Short call to action on the card, e.g. "Open catalogs".
  String? action(AppLocalizations l10n) => switch (this) {
    normal || general => null,
    offer => l10n.notifActOffer,
    catalog => l10n.notifActCatalog,
    dailySpin => l10n.notifActDailySpin,
    addBill => l10n.notifActAddBill,
    wallet || points || bill => l10n.notifActWallet,
    festival => null,
    branch => l10n.notifActBranch,
    account => l10n.notifActAccount,
  };
}
