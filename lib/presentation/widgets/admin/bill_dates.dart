import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

/// The dates on an admin bill card, each with its time:
/// * Bill date (the date on the paper bill; time shown only if one was set)
/// * Submitted (when the member sent it) — always date + time
/// * Approved / Rejected (when the admin decided) — date + time
/// Items wrap onto the next line instead of being cut off.
class BillDates extends StatelessWidget {
  const BillDates({super.key, required this.bill});

  final Map<String, dynamic> bill;

  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final _date = DateFormat('dd MMM yyyy');

  static DateTime? _ts(Object? v) => v is Timestamp ? v.toDate() : null;

  /// Paper bills are dated by day: skip a midnight time.
  static String _billDate(DateTime d) =>
      d.hour == 0 && d.minute == 0 ? _date.format(d) : _dateTime.format(d);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = bill['status'] as String? ?? '';
    final billDate = _ts(bill['billDate']);
    final submitted = _ts(bill['createdAt']);
    final approved = _ts(bill['approvedAt']);
    final rejected = _ts(bill['rejectedAt']);

    final items = <Widget>[
      if (billDate != null)
        _item(
          context,
          Icons.receipt_long_rounded,
          l10n.billDate3,
          _billDate(billDate),
          context.themeContentColor,
        ),
      if (submitted != null)
        _item(
          context,
          Icons.schedule_rounded,
          l10n.submitted2,
          _dateTime.format(submitted),
          context.themeTextSecondary,
        ),
      if (status == 'approved' && approved != null)
        _item(
          context,
          Icons.check_circle_rounded,
          l10n.approved2,
          _dateTime.format(approved),
          AppColors.success,
        ),
      if (status == 'rejected' && (rejected ?? approved) != null)
        _item(
          context,
          Icons.cancel_rounded,
          l10n.billRejectedAt,
          _dateTime.format((rejected ?? approved)!),
          context.themeError,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 4, children: items);
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: AppTypography.caption(color: context.themeTextSecondary),
              ),
              TextSpan(
                text: value,
                style: AppTypography.labelSmall(color: color),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
