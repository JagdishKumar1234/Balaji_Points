import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool compact;
  final bool showIcon;

  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = false,
  });

  String get _normalized => status.toLowerCase().trim();

  bool get _isPending => _normalized.isEmpty || _normalized == 'pending';

  Color _statusColor() {
    switch (_normalized) {
      case 'approved':
      case 'completed':
        return AppColors.success;
      case 'processing':
        return AppColors.warning;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _foreground(BuildContext context) {
    return _isPending ? context.themeTextSecondary : _statusColor();
  }

  IconData _iconData() {
    switch (_normalized) {
      case 'approved':
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.autorenew;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _label() {
    switch (_normalized) {
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'cancelled':
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = _statusColor().withValues(alpha: 0.15);
    final foreground = _foreground(context);
    final iconSize = compact ? 14.0 : 16.0;
    final horizontal = compact ? 10.0 : 12.0;
    final vertical = compact ? 4.0 : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_iconData(), size: iconSize, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            _label(),
            style: AppTypography.labelSmall(
              color: foreground,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
