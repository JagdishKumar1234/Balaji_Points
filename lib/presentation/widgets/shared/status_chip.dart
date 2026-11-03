import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
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

  /// Tinted background + dark text pair (spec chips). Theme-aware.
  (Color bg, Color fg) _colors(BuildContext context) {
    switch (_normalized) {
      case 'approved':
      case 'completed':
        return (context.themeSuccessSoft, context.themeSuccessText);
      case 'cancelled':
      case 'rejected':
        return (context.themeErrorSoft, context.themeErrorText);
      case 'processing':
        return (context.themeSoftSurface, context.themeTextPrimary);
      default:
        return (context.themePendingSoft, context.themePendingText);
    }
  }

  IconData _iconData() {
    switch (_normalized) {
      case 'approved':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'processing':
        return Icons.autorenew_rounded;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  String _label(BuildContext context) {
    switch (_normalized) {
      case 'approved':
        return AppLocalizations.of(context)!.approvedLabel;
      case 'completed':
        return AppLocalizations.of(context)!.completed;
      case 'processing':
        return AppLocalizations.of(context)!.processing;
      case 'cancelled':
      case 'rejected':
        return AppLocalizations.of(context)!.rejectedLabel;
      default:
        return AppLocalizations.of(context)!.pendingStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(context);
    final iconSize = compact ? 13.0 : 15.0;
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.sm8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(_iconData(), size: iconSize, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            _label(context),
            style: (compact
                ? AppTypography.labelSmall(color: foreground)
                : AppTypography.label(color: foreground)),
          ),
        ],
      ),
    );
  }
}
