import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/points/points_rate.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Admin view of one bill: amount, points and status; the member who sent
/// it; the bill photo; every detail and time; and, while pending, Approve /
/// Reject in a footer that stays on screen.
///
/// Points and tier come from `user_points` (the source of truth), and the
/// points preview uses the member's role rate, the same rate approval
/// credits.
class BillDetailsPage extends StatefulWidget {
  final String billId;
  final Map<String, dynamic>? initialBillData;

  const BillDetailsPage({
    super.key,
    required this.billId,
    this.initialBillData,
  });

  @override
  State<BillDetailsPage> createState() => _BillDetailsPageState();
}

class _BillDetailsPageState extends State<BillDetailsPage> {
  late final BillService _billService = BillService();
  final FirebaseFirestore _db = appFirestore;

  Map<String, dynamic>? _bill;
  Map<String, dynamic>? _member;
  Map<String, dynamic>? _memberPoints;
  String? _memberId;
  int _rupeesPerPoint = PointsRate.defaultRupeesPerPoint;
  bool _loading = true;
  bool _processing = false;

  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _money = NumberFormat.decimalPattern('en_IN');

  @override
  void initState() {
    super.initState();
    // Show what the list already had straight away, then refresh.
    final initial = widget.initialBillData;
    if (initial != null) {
      _bill = {...initial, 'billId': widget.billId};
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await _db.collection('bills').doc(widget.billId).get();
      if (doc.exists) {
        _bill = {...?doc.data(), 'billId': doc.id};
        final memberId = _bill!['carpenterId'] as String?;
        if (memberId != null && memberId.isNotEmpty) {
          await _loadMember(memberId);
        }
      } else {
        _bill = null;
      }
    } catch (e) {
      AppLogger.warning('Bill details load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMember(String memberId) async {
    try {
      var doc = await _db.collection('users').doc(memberId).get();
      var id = memberId;
      if (!doc.exists) {
        final q = await _db
            .collection('users')
            .where('phone', isEqualTo: memberId)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          doc = q.docs.first;
          id = doc.id;
        }
      }
      if (!doc.exists) return;
      _member = doc.data();
      _memberId = id;
      _rupeesPerPoint = await RoleService().rateForRole(
        _member?['role'] as String?,
      );
      final points = await _db.collection('user_points').doc(id).get();
      _memberPoints = points.data();
    } catch (e) {
      AppLogger.warning('Bill member load failed: $e');
    }
  }

  double get _amount => ((_bill?['amount'] as num?) ?? 0).toDouble();

  double get _points =>
      PointsRate.forBill(_bill ?? const {}, rupeesPerPoint: _rupeesPerPoint);

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(
      title: l10n.approveBillAction,
      message: l10n.approveThisBillOfPointsWill2(
        _money.format(_amount.round()),
        _points.toStringAsFixed(2),
      ),
      action: l10n.approve,
      color: AppColors.success,
    );
    if (!ok) return;
    await _run(
      () => _billService.approveBill(
        widget.billId,
        (_bill!['carpenterId'] as String?) ?? '',
        _amount,
      ),
      success: l10n.billApproved,
      failure: l10n.failedToApproveBill2,
      successColor: AppColors.success,
    );
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(
      title: l10n.rejectBill,
      message: l10n.rejectBillConfirmation,
      action: l10n.reject,
      color: context.themeError,
    );
    if (!ok) return;
    await _run(
      () => _billService.rejectBill(widget.billId),
      success: l10n.billRejected2,
      failure: l10n.failedToRejectBill2,
      successColor: AppColors.warning,
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    required Color color,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Runs approve / reject and reports the real result (a `false` from the
  /// service is a failure, not a success).
  Future<void> _run(
    Future<bool> Function() job, {
    required String success,
    required String failure,
    required Color successColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    setState(() => _processing = true);
    try {
      final done = await job();
      messenger.showSnackBar(
        SnackBar(
          content: Text(done ? success : failure),
          backgroundColor: done ? successColor : errorColor,
        ),
      );
      if (done && mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.error2('$e')), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bill = _bill;
    final pending = (bill?['status'] ?? 'pending') == 'pending';

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(title: Text(l10n.billDetails), centerTitle: false),
      body: _loading
          ? Center(child: AppLoader(color: context.themePrimary))
          : bill == null
          ? Center(
              child: Text(
                l10n.billNotFound,
                style: AppTypography.bodyMedium(
                  color: context.themeTextSecondary,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: context.themePrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _summary(context, bill),
                        const SizedBox(height: 12),
                        if (_member != null) ...[
                          _memberCard(context),
                          const SizedBox(height: 12),
                        ],
                        if ((bill['imageUrl'] as String? ?? '').isNotEmpty) ...[
                          _photo(context, bill['imageUrl'] as String),
                          const SizedBox(height: 12),
                        ],
                        _details(context, bill),
                        const SizedBox(height: 12),
                        _timeline(context, bill),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      // Approve / Reject stay on screen while the bill is pending.
      bottomNavigationBar: bill != null && pending && !_loading
          ? _actions(context)
          : null,
    );
  }

  Widget _card(BuildContext context, {required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.themeCard,
      borderRadius: AppRadius.all16,
      border: Border.all(color: context.themeBorder),
    ),
    child: child,
  );

  Widget _sectionTitle(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.themePrimary),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTypography.labelLarge(color: context.themeTextPrimary),
            ),
          ],
        ),
      );

  /// Status, amount and points: the three things an admin checks first.
  Widget _summary(BuildContext context, Map<String, dynamic> bill) {
    final l10n = AppLocalizations.of(context)!;
    final status = (bill['status'] as String? ?? 'pending').toLowerCase();
    final approved = status == 'approved';
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusChip(status: status, showIcon: true),
              const Spacer(),
              if ((bill['billNumber'] ?? '').toString().isNotEmpty &&
                  bill['billNumber'] != 'N/A')
                Flexible(
                  child: Text(
                    l10n.billNo2('${bill['billNumber']}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _figure(
                  context,
                  l10n.billAmount3,
                  '₹${_money.format(_amount.round())}',
                  context.themeTextPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: context.themeBorder),
              const SizedBox(width: 14),
              Expanded(
                child: _figure(
                  context,
                  approved ? l10n.billPointsCredited : l10n.pointsToCredit,
                  _points.toStringAsFixed(2),
                  context.themePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.caption(color: context.themeTextSecondary),
      ),
      const SizedBox(height: 2),
      Text(value, style: AppTypography.h3(color: color)),
    ],
  );

  Widget _memberCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = _member!;
    final name =
        '${(m['firstName'] ?? '').toString().trim()} '
                '${(m['lastName'] ?? '').toString().trim()}'
            .trim();
    final phone = (m['phone'] ?? '') as String;
    final image = (m['profileImage'] ?? '') as String;
    final total =
        (_memberPoints?['totalPoints'] as num?) ??
        (m['totalPoints'] as num?) ??
        0;
    final tier =
        (_memberPoints?['tier'] as String?) ?? (m['tier'] as String?) ?? '';
    final fallback = Icon(
      Icons.person_rounded,
      size: 26,
      color: context.themeTextSecondary,
    );

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, Icons.person_rounded, l10n.billMember),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.themePrimary.withValues(alpha: 0.08),
                child: ClipOval(
                  child: image.isEmpty
                      ? fallback
                      : Image.network(
                          image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallback,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '—' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge(
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RoleTag(
                          roleId: m['role'] as String?,
                          storedName: m['roleName'] as String?,
                        ),
                        Text(
                          [
                            if (tier.isNotEmpty) tier,
                            l10n.pts3(PointsUtils.formatPoints(total)),
                          ].join(' · '),
                          style: AppTypography.caption(
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (phone.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(phone, overflow: TextOverflow.ellipsis),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                  ),
                ),
              if (phone.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.badge_rounded, size: 18),
                  label: Text(l10n.viewProfile),
                  onPressed: _memberId == null
                      ? null
                      : () =>
                            context.push('/admin/carpenter-profile/$_memberId'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photo(BuildContext context, String url) {
    final l10n = AppLocalizations.of(context)!;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, Icons.image_rounded, l10n.billAttachment2),
          GestureDetector(
            onTap: () => showFullScreenImage(context, url),
            child: ClipRRect(
              borderRadius: AppRadius.md12,
              child: Stack(
                children: [
                  Image.network(
                    url,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: context.themeSoftSurface,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.6),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.zoom_in_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.viewFullSize,
                            style: AppTypography.labelSmall(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _details(BuildContext context, Map<String, dynamic> bill) {
    final l10n = AppLocalizations.of(context)!;
    final billDate = (bill['billDate'] as Timestamp?)?.toDate();
    final site = (bill['siteName'] as String? ?? '').trim();
    final rows = <(IconData, String, String)>[
      if (billDate != null)
        (
          Icons.receipt_long_rounded,
          l10n.billDateLabel,
          billDate.hour == 0 && billDate.minute == 0
              ? DateFormat('dd MMM yyyy').format(billDate)
              : _dateTime.format(billDate),
        ),
      if (site.isNotEmpty) (Icons.location_on_rounded, l10n.site, site),
      (
        Icons.percent_rounded,
        l10n.pointsRate,
        PointsRate.label(
          PointsRate.sanitize(
            bill['rupeesPerPoint'],
            fallback: _rupeesPerPoint,
          ),
        ),
      ),
    ];
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            context,
            Icons.info_outline_rounded,
            l10n.billDetailsSection,
          ),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(r.$1, size: 16, color: context.themeTextSecondary),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: Text(
                      r.$2,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$3,
                      style: AppTypography.labelMedium(
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Submitted, then approved / rejected (or waiting), each with its time.
  Widget _timeline(BuildContext context, Map<String, dynamic> bill) {
    final l10n = AppLocalizations.of(context)!;
    final status = (bill['status'] as String? ?? 'pending').toLowerCase();
    DateTime? ts(Object? v) => v is Timestamp ? v.toDate() : null;
    final submitted = ts(bill['createdAt']);
    final decided = status == 'rejected'
        ? ts(bill['rejectedAt']) ?? ts(bill['approvedAt'])
        : ts(bill['approvedAt']);

    final steps = <_Step>[
      _Step(
        title: l10n.submittedLabel,
        time: submitted == null ? '—' : _dateTime.format(submitted),
        color: AppColors.success,
        icon: Icons.upload_rounded,
      ),
      switch (status) {
        'approved' => _Step(
          title: l10n.approvedLabel,
          time: decided == null ? '—' : _dateTime.format(decided),
          color: AppColors.success,
          icon: Icons.check_rounded,
        ),
        'rejected' => _Step(
          title: l10n.rejectedLabel,
          time: decided == null ? '—' : _dateTime.format(decided),
          color: context.themeError,
          icon: Icons.close_rounded,
        ),
        _ => _Step(
          title: l10n.waitingForApproval,
          time: l10n.pendingActionFromAdmin,
          color: AppColors.warning,
          icon: Icons.schedule_rounded,
        ),
      },
    ];

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, Icons.history_rounded, l10n.timeline),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: steps[i].color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          steps[i].icon,
                          size: 15,
                          color: AppColors.white,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: context.themeBorder,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 3,
                        bottom: i < steps.length - 1 ? 18 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].title,
                            style: AppTypography.labelMedium(
                              color: context.themeTextPrimary,
                            ),
                          ),
                          Text(
                            steps[i].time,
                            style: AppTypography.caption(
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.themeBackground,
        border: Border(top: BorderSide(color: context.themeBorder)),
      ),
      // heightFactor 1: a bottom bar gets the whole screen height to
      // grow into; a plain Center would take it all and hide the page.
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.themeError,
                    side: BorderSide(
                      color: context.themeError.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.reject),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _processing ? null : _approve,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoader(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(l10n.approve),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.title,
    required this.time,
    required this.color,
    required this.icon,
  });

  final String title;
  final String time;
  final Color color;
  final IconData icon;
}
