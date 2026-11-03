import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/loading_provider.dart';

class LoadingOverlay extends ConsumerWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(loadingProvider) > 0;
    if (!isLoading) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          ModalBarrier(color: AppColors.black.withValues(alpha: 0.35)),
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.themeCard,
                borderRadius: AppRadius.all16,
                border: Border.all(color: context.themeBorder, width: 1),
                boxShadow: context.themeShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: context.themeSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppText.body(
                    AppLocalizations.of(context)!.loading,
                    color: context.themeTextPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
