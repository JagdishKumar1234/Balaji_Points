import 'dart:async';

import 'package:balaji_points/core/points/points_rate.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/presentation/screens/admin/bill_details_page.dart';
import 'package:balaji_points/presentation/widgets/admin/bill_dates.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Admin view of one member (any of the 4 roles): profile, live points and
/// bill counts, pending bills to approve or reject, and the full history.
///
/// Every number comes from Firestore (nothing typed in): the member's
/// `users` record, `user_points` (the source of truth for points and tier,
/// updated with each approval) and their `bills`. The three streams are
/// opened once, so changing a filter never reloads the data.
class CarpenterProfileDetailScreen extends StatefulWidget {
  final String carpenterId;

  const CarpenterProfileDetailScreen({required this.carpenterId, super.key});

  @override
  State<CarpenterProfileDetailScreen> createState() =>
      _CarpenterProfileDetailScreenState();
}

class _CarpenterProfileDetailScreenState
    extends State<CarpenterProfileDetailScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _pointsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _billsStream;

  /// 'all', 'approved', 'pending' or 'rejected'.
  String _statusFilter = 'all';
  String? _siteFilter;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    final db = appFirestore;
    _userStream = db.collection('users').doc(widget.carpenterId).snapshots();
    _pointsStream = db
        .collection('user_points')
        .doc(widget.carpenterId)
        .snapshots();
    _billsStream = db
        .collection('bills')
        .where('carpenterId', isEqualTo: widget.carpenterId)
        .snapshots();
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return AppColors.tierPlatinum;
      case 'gold':
        return AppColors.tierGold;
      case 'silver':
        return AppColors.tierSilver;
      case 'bronze':
        return AppColors.tierBronze;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _handleResetPin(
    BuildContext dialogContext,
    String pin,
    String confirmPin,
    String carpenterPhone,
  ) async {
    if (pin.isEmpty || confirmPin.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pleaseEnterPinInBothFields,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (pin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinMismatch),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (pin.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enter4Digits),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pinMustContainOnlyNumbers,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final pinAuthService = PinAuthService();
      final success = await pinAuthService.resetPin(
        phone: carpenterPhone,
        newPin: pin,
        isAdmin: true,
      );

      if (!mounted) return;

      if (success) {
        if (Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinResetSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminResetPinFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorResettingPin('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resetPinDialog(
    BuildContext context,
    String carpenterId,
    String carpenterPhone,
    String carpenterName,
  ) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.resetPin),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.resetPinFor('$carpenterName'),
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.phone2('$carpenterPhone'),
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.md12,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.carpenterWillNeedToUseThis,
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newPinLabel,
                  hintText: AppLocalizations.of(context)!.hintPin,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPin,
                  hintText: AppLocalizations.of(context)!.hintConfirmPin,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => _handleResetPin(
              dialogContext,
              pinController.text.trim(),
              confirmPinController.text.trim(),
              carpenterPhone,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.navigation,
            ),
            child: Text(
              AppLocalizations.of(context)!.resetPin,
              style: TextStyle(color: AppColors.navigation),
            ),
          ),
        ],
      ),
    ).then((_) {
      pinController.dispose();
      confirmPinController.dispose();
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _clearFilters() => setState(() {
    _statusFilter = 'all';
    _siteFilter = null;
    _range = null;
  });

  bool get _hasFilters =>
      _statusFilter != 'all' || _siteFilter != null || _range != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userStream,
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        if (userData == null) {
          final loading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasError;
          return Scaffold(
            backgroundColor: context.themeBackground,
            appBar: AppBar(title: Text(l10n.memberDetailsTitle)),
            body: Center(
              child: loading
                  ? CircularProgressIndicator(color: context.themePrimary)
                  : AppText.body(l10n.carpenterNotFound),
            ),
          );
        }

        final phone = (userData['phone'] ?? '') as String;
        final name =
            '${(userData['firstName'] ?? '').toString().trim()} '
                    '${(userData['lastName'] ?? '').toString().trim()}'
                .trim();

        return Scaffold(
          backgroundColor: context.themeBackground,
          appBar: AppBar(
            title: Text(l10n.memberDetailsTitle),
            centerTitle: false,
            actions: [
              if (context.isDesktop) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: Text(l10n.resetPin),
                  onPressed: () =>
                      _resetPinDialog(context, widget.carpenterId, phone, name),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.edit),
                  onPressed: () =>
                      _showEditDialog(context, widget.carpenterId, userData),
                ),
                const SizedBox(width: 12),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.lock_reset_rounded),
                  tooltip: l10n.resetPin,
                  onPressed: () =>
                      _resetPinDialog(context, widget.carpenterId, phone, name),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: l10n.edit,
                  onPressed: () =>
                      _showEditDialog(context, widget.carpenterId, userData),
                ),
              ],
            ],
          ),
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _pointsStream,
            builder: (context, pointsSnap) {
              final points = pointsSnap.data?.data();
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _billsStream,
                builder: (context, billsSnap) {
                  final bills =
                      billsSnap.data?.docs
                          .map((d) => {...d.data(), 'billId': d.id})
                          .toList() ??
                      const <Map<String, dynamic>>[];
                  return _body(
                    context,
                    userData: userData,
                    name: name,
                    phone: phone,
                    points: points,
                    bills: bills,
                    billsLoaded: billsSnap.hasData,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context, {
    required Map<String, dynamic> userData,
    required String name,
    required String phone,
    required Map<String, dynamic>? points,
    required List<Map<String, dynamic>> bills,
    required bool billsLoaded,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final total =
        (points?['totalPoints'] as num?) ??
        (userData['totalPoints'] as num?) ??
        0;
    final tier =
        (points?['tier'] as String?) ??
        (userData['tier'] as String?) ??
        'Bronze';

    final counts = <String, int>{'approved': 0, 'pending': 0, 'rejected': 0};
    var approvedAmount = 0.0;
    for (final b in bills) {
      final s = (b['status'] as String? ?? 'pending').toLowerCase();
      counts[s] = (counts[s] ?? 0) + 1;
      if (s == 'approved') {
        approvedAmount += (b['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final pending =
        bills.where((b) => (b['status'] ?? 'pending') == 'pending').toList()
          ..sort(_newestFirst);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: ResponsiveContainer(
        maxWidth: 820,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileCard(userData: userData, name: name, phone: phone),
            const SizedBox(height: 12),
            _PointsCard(
              totalPoints: total,
              tier: tier,
              tierColor: _getTierColor(tier),
              approvedAmount: approvedAmount,
              counts: counts,
              loaded: billsLoaded,
              selected: _statusFilter,
              onSelect: (s) => setState(
                () => _statusFilter = _statusFilter == s ? 'all' : s,
              ),
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(
                icon: Icons.schedule_rounded,
                color: AppColors.warning,
                title: l10n.pendingBillRequests,
                count: pending.length,
              ),
              const SizedBox(height: 10),
              for (final b in pending)
                _BillCard(
                  bill: b,
                  onApprove: () => _approvePendingBill(b),
                  onReject: () => _rejectPendingBill(b['billId'] as String),
                ),
            ],
            const SizedBox(height: 20),
            _SectionTitle(
              icon: Icons.history_rounded,
              color: context.themePrimary,
              title: l10n.memberHistory,
            ),
            const SizedBox(height: 10),
            _filters(context, bills, counts),
            const SizedBox(height: 12),
            ..._history(context, bills, points, billsLoaded),
          ],
        ),
      ),
    );
  }

  static int _newestFirst(Map<String, dynamic> a, Map<String, dynamic> b) {
    DateTime d(Map<String, dynamic> m) =>
        ((m['createdAt'] ?? m['billDate'] ?? m['date']) as Timestamp?)
            ?.toDate() ??
        DateTime(1970);
    return d(b).compareTo(d(a));
  }

  Widget _filters(
    BuildContext context,
    List<Map<String, dynamic>> bills,
    Map<String, int> counts,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final sites =
        bills
            .map((b) => (b['siteName'] as String? ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final fmt = DateFormat('dd MMM yy');
    Widget chip(String id, String label, int? n, Color color) {
      final on = _statusFilter == id;
      return ChoiceChip(
        label: Text(n == null ? label : '$label  $n'),
        selected: on,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: color,
        backgroundColor: context.themeCard,
        side: BorderSide(color: on ? color : context.themeBorder),
        labelStyle: AppTypography.labelMedium(
          color: on ? AppColors.white : context.themeTextPrimary,
        ),
        onSelected: (_) => setState(() => _statusFilter = id),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('all', l10n.all, bills.length, context.themePrimary),
            chip(
              'approved',
              l10n.approvedLabel,
              counts['approved'],
              AppColors.success,
            ),
            chip(
              'pending',
              l10n.pendingStatus,
              counts['pending'],
              AppColors.warning,
            ),
            chip(
              'rejected',
              l10n.rejectedLabel,
              counts['rejected'],
              context.themeError,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (sites.isNotEmpty) ...[
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: sites.contains(_siteFilter)
                      ? _siteFilter
                      : null,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(borderRadius: AppRadius.md12),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.allSites)),
                    for (final s in sites)
                      DropdownMenuItem(
                        value: s,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _siteFilter = v),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
                ),
                label: Text(
                  _range == null
                      ? l10n.memberDateRange
                      : '${fmt.format(_range!.start)} – '
                            '${fmt.format(_range!.end)}',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _pickRange,
              ),
            ),
            if (_hasFilters)
              IconButton(
                tooltip: l10n.clearAll,
                icon: const Icon(Icons.filter_alt_off_rounded),
                onPressed: _clearFilters,
              ),
          ],
        ),
      ],
    );
  }

  /// Bills (after the filters) plus other point entries such as daily spin
  /// rewards. Bill approvals are not repeated: they are the bills.
  List<Widget> _history(
    BuildContext context,
    List<Map<String, dynamic>> bills,
    Map<String, dynamic>? points,
    bool loaded,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (!loaded) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: context.themePrimary),
          ),
        ),
      ];
    }

    bool inRange(Timestamp? t) {
      if (_range == null) return true;
      if (t == null) return false;
      final d = t.toDate();
      return !d.isBefore(_range!.start) &&
          d.isBefore(_range!.end.add(const Duration(days: 1)));
    }

    final entries = <Map<String, dynamic>>[
      for (final b in bills)
        if ((_statusFilter == 'all' ||
                (b['status'] ?? 'pending') == _statusFilter) &&
            (_siteFilter == null || b['siteName'] == _siteFilter) &&
            inRange((b['createdAt'] ?? b['billDate']) as Timestamp?))
          {...b, '_kind': 'bill'},
      // Other point entries only when not filtering by bill status or site.
      if (_statusFilter == 'all' && _siteFilter == null)
        for (final raw in (points?['pointsHistory'] as List?) ?? const [])
          if (raw is Map &&
              raw['billId'] == null &&
              inRange(raw['date'] as Timestamp?))
            {...Map<String, dynamic>.from(raw), '_kind': 'points'},
    ]..sort(_newestFirst);

    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              l10n.noHistoryFound,
              style: AppTypography.bodyMedium(
                color: context.themeTextSecondary,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      for (final e in entries)
        e['_kind'] == 'bill' ? _BillCard(bill: e) : _PointsEntryCard(entry: e),
    ];
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String carpenterId,
    Map<String, dynamic> userData,
  ) async {
    final firstNameController = TextEditingController(
      text: userData['firstName'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: userData['lastName'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );
    final branchIdController = TextEditingController(
      text: userData['branchId'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.title(AppLocalizations.of(context)!.editCarpenter),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.firstName,
                  hintText: AppLocalizations.of(context)!.enterFirstName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.lastName,
                  hintText: AppLocalizations.of(context)!.enterLastName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumber,
                  hintText: AppLocalizations.of(context)!.hintPhone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: AppLocalizations.of(
                    context,
                  )!.changingPhoneNumberWillUpdateLogin,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: branchIdController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.branchId,
                  hintText: AppLocalizations.of(context)!.hintBranchId,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText.body(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = phoneController.text.trim();
              if (newPhone.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.phoneNumberCannotBeEmpty,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(carpenterId)
                    .update({
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'phone': newPhone,
                      'branchId': branchIdController.text,
                    });

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText.body(
                        AppLocalizations.of(
                          context,
                        )!.carpenterUpdatedSuccessfully,
                        color: AppColors.white,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText.body(
                        AppLocalizations.of(
                          context,
                        )!.errorUpdatingCarpenter('$e'),
                        color: AppColors.white,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: context.themeOnPrimary,
              backgroundColor: context.themePrimary,
            ),
            child: AppText.body(
              AppLocalizations.of(context)!.update,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    ).then((_) {
      firstNameController.dispose();
      lastNameController.dispose();
      phoneController.dispose();
      branchIdController.dispose();
    });
  }

  Future<void> _approvePendingBill(Map<String, dynamic> bill) async {
    final billId = bill['billId'] as String?;
    final amount = (bill['amount'] ?? 0).toDouble();
    // Preview at the member's role rate, the same rate approval credits.
    String? role;
    try {
      final member = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.carpenterId)
          .get();
      role = member.data()?['role'] as String?;
    } catch (_) {}
    final rate = await RoleService().rateForRole(role);
    final previewPoints = PointsRate.forBill(bill, rupeesPerPoint: rate);
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText.label(AppLocalizations.of(context)!.approveBillAction),
        content: AppText.body(
          AppLocalizations.of(context)!.approveThisBillOfPointsWill2(
            '${amount.toStringAsFixed(0)}',
            previewPoints.toStringAsFixed(2),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.approve,
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || billId == null) return;

    _showLoadingDialog();

    try {
      final billService = BillService();
      final success = await billService.approveBill(
        billId,
        widget.carpenterId,
        amount,
      );

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billApproved),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToApproveBill2),
            backgroundColor: context.themeError,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error2('$e')),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _rejectPendingBill(String billId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.rejectBill,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: context.themeError,
          ),
        ),
        content: AppText.body(
          AppLocalizations.of(context)!.rejectBillConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: context.themeOnError,
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.reject,
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog();

    try {
      final billService = BillService();
      final success = await billService.rejectBill(billId);

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billRejected),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToRejectBill2),
            backgroundColor: context.themeError,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error2('$e')),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: context.themePrimary)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    this.count,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          title,
          style: AppTypography.h5(color: context.themeTextPrimary),
        ),
      ),
      if (count != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: AppRadius.pill,
          ),
          child: Text('$count', style: AppTypography.labelSmall(color: color)),
        ),
      ],
    ],
  );
}

/// Photo, full name, role, tier and status, then phone (tap to call),
/// branch and member-since date.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.userData,
    required this.name,
    required this.phone,
  });

  final Map<String, dynamic> userData;
  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = (userData['profileImage'] ?? '') as String;
    final branchId = (userData['branchId'] ?? '') as String;
    final createdAt = userData['createdAt'] as Timestamp?;
    final active = userData['active'] != false;
    final avatarFallback = Icon(
      Icons.person_rounded,
      size: 32,
      color: context.themeTextSecondary,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: context.themePrimary.withValues(alpha: 0.08),
                child: ClipOval(
                  child: image.isEmpty
                      ? avatarFallback
                      : Image.network(
                          image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => avatarFallback,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5(color: context.themeTextPrimary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        RoleTag(
                          roleId: userData['role'] as String?,
                          storedName: userData['roleName'] as String?,
                        ),
                        StatusChip(
                          status: active ? 'active' : 'inactive',
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.themeBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.phone_rounded,
                  label: l10n.phone,
                  value: phone.isEmpty ? '—' : phone,
                  onTap: phone.isEmpty
                      ? null
                      : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: branchId.isEmpty
                      ? Future.value(null)
                      : BranchService().getBranch(branchId),
                  builder: (context, snap) => _InfoTile(
                    icon: Icons.storefront_rounded,
                    label: l10n.branch,
                    value:
                        (snap.data?['shortName'] ??
                                snap.data?['name'] ??
                                (branchId.isEmpty ? '—' : branchId))
                            .toString(),
                  ),
                ),
              ),
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: l10n.memberSince,
                  value: createdAt == null
                      ? '—'
                      : DateFormat('dd MMM yyyy').format(createdAt.toDate()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.md12,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: context.themeTextSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium(
              color: onTap == null
                  ? context.themeTextPrimary
                  : context.themePrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Points and tier, approved purchase total, and live bill counts. Tapping
/// a count filters the history to that status (tap again to clear).
class _PointsCard extends StatelessWidget {
  const _PointsCard({
    required this.totalPoints,
    required this.tier,
    required this.tierColor,
    required this.approvedAmount,
    required this.counts,
    required this.loaded,
    required this.selected,
    required this.onSelect,
  });

  final num totalPoints;
  final String tier;
  final Color tierColor;
  final double approvedAmount;
  final Map<String, int> counts;
  final bool loaded;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = NumberFormat.decimalPattern('en_IN');
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalPointsLabel,
                      style: AppTypography.caption(
                        color: context.themeTextSecondary,
                      ),
                    ),
                    Text(
                      PointsUtils.formatPoints(totalPoints),
                      style: AppTypography.h3(color: context.themePrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: tierColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tier,
                      style: AppTypography.labelMedium(
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.memberApprovedAmount}: ₹${money.format(approvedAmount.round())}',
            style: AppTypography.caption(color: context.themeTextSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final s in [
                (
                  'approved',
                  l10n.approvedLabel,
                  Icons.check_circle_rounded,
                  AppColors.success,
                ),
                (
                  'pending',
                  l10n.pendingStatus,
                  Icons.schedule_rounded,
                  AppColors.warning,
                ),
                (
                  'rejected',
                  l10n.rejectedLabel,
                  Icons.cancel_rounded,
                  context.themeError,
                ),
              ]) ...[
                if (s.$1 != 'approved') const SizedBox(width: 8),
                Expanded(
                  child: _CountTile(
                    label: s.$2,
                    icon: s.$3,
                    color: s.$4,
                    count: loaded ? counts[s.$1] ?? 0 : null,
                    selected: selected == s.$1,
                    onTap: () => onSelect(s.$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: color.withValues(alpha: selected ? 0.18 : 0.08),
    borderRadius: AppRadius.md12,
    child: InkWell(
      borderRadius: AppRadius.md12,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md12,
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              count?.toString() ?? '–',
              style: AppTypography.h5(color: color),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One bill: photo (tap to zoom), amount, site and bill number, status and
/// points, then all dates with times. Tap opens the bill details. Pending
/// bills get Approve / Reject buttons.
class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill, this.onApprove, this.onReject});

  final Map<String, dynamic> bill;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = bill['imageUrl'] as String? ?? '';
    final site = (bill['siteName'] as String? ?? '').trim();
    final number = (bill['billNumber'] ?? '').toString().trim();
    final amount = (bill['amount'] as num?) ?? 0;
    final status = (bill['status'] as String? ?? 'pending').toLowerCase();
    final pointsValue = PointsRate.forBill(bill);
    final money = NumberFormat.decimalPattern('en_IN');
    final thumbFallback = Icon(
      Icons.receipt_long_rounded,
      color: context.themeTextSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.themeCard,
        borderRadius: AppRadius.md12,
        child: InkWell(
          borderRadius: AppRadius.md12,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BillDetailsPage(
                billId: bill['billId'] as String,
                initialBillData: bill,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: AppRadius.md12,
              border: Border.all(
                color: status == 'pending'
                    ? AppColors.warning.withValues(alpha: 0.4)
                    : context.themeBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: image.isEmpty
                          ? null
                          : () => showFullScreenImage(context, image),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: context.themeSoftSurface,
                          borderRadius: AppRadius.sm8,
                          border: Border.all(color: context.themeBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: image.isEmpty
                            ? thumbFallback
                            : Image.network(
                                image,
                                fit: BoxFit.cover,
                                cacheWidth: 168,
                                errorBuilder: (_, __, ___) => thumbFallback,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${money.format(amount.round())}',
                            style: AppTypography.h5(
                              color: context.themeTextPrimary,
                            ),
                          ),
                          if (site.isNotEmpty)
                            Text(
                              l10n.site3(site),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(
                                color: context.themeTextSecondary,
                              ),
                            ),
                          if (number.isNotEmpty && number != 'N/A')
                            Text(
                              l10n.billNo2(number),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(
                                color: context.themeTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip(
                          status: status,
                          compact: true,
                          showIcon: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.pts7(pointsValue.toStringAsFixed(2)),
                          style: AppTypography.labelMedium(
                            color: context.themePrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                BillDates(bill: bill),
                if (onApprove != null && onReject != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.themeError,
                            side: BorderSide(
                              color: context.themeError.withValues(alpha: 0.5),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(l10n.reject),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onApprove,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(l10n.approve),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A points entry that is not a bill (e.g. daily spin reward).
class _PointsEntryCard extends StatelessWidget {
  const _PointsEntryCard({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = (entry['points'] as num?) ?? 0;
    final raw = (entry['reason'] as String? ?? '').trim();
    final reason = raw.toLowerCase() == 'daily spin'
        ? l10n.dailySpin
        : (raw.isEmpty ? l10n.pointsAwarded : raw);
    final date = (entry['date'] as Timestamp?)?.toDate();
    final positive = value >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: AppRadius.md12,
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.themeGoldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stars_rounded, color: context.themePrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge(
                      color: context.themeTextPrimary,
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(date),
                      style: AppTypography.caption(
                        color: context.themeTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${positive ? '+' : ''}${value.toStringAsFixed(2)}',
              style: AppTypography.h5(
                color: positive ? AppColors.success : context.themeError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
