import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';

import 'package:balaji_points/core/design/app_spacing.dart';

/// Consistent loading feedback for data-backed Super Admin panels.
class SuperAdminLoadingView extends StatelessWidget {
  const SuperAdminLoadingView({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 20,
            child: AppLoader(strokeWidth: 2.4),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(strokeWidth: 3),
            const SizedBox(height: AppSpacing.md),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
