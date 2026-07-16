import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Reusable widget to display bill numbers in admin screens
class BillNumberChip extends StatelessWidget {
  final String billNumber;
  final bool isSelectable;
  final VoidCallback? onTap;
  final bool compact;

  const BillNumberChip({
    required this.billNumber,
    this.isSelectable = true,
    this.onTap,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt,
            size: compact ? 12 : 14,
            color: context.themePrimary,
          ),
          const SizedBox(width: 6),
          Text(
            billNumber,
            style: compact
                ? AppTypography.labelSmall(color: context.themePrimary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10)
                : AppTypography.bodySmall(color: context.themePrimary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.themePrimary.withValues(alpha: 0.1),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: context.themePrimary.withValues(alpha: 0.2),
        ),
      ),
      child: isSelectable && onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.sm8,
                child: content,
              ),
            )
          : content,
    );
  }
}
