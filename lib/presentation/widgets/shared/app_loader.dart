import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

/// Inline circular loader sized to fit within a row or button.
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppLoader({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? context.themePrimary,
        ),
      ),
    );
  }
}

/// Full-screen blocking loader with optional message.
class AppFullScreenLoader extends StatelessWidget {
  final String? message;

  const AppFullScreenLoader({super.key, this.message});

  static OverlayEntry show(BuildContext context, {String? message}) {
    final entry = OverlayEntry(
      builder: (_) => AppFullScreenLoader(message: message),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: AppColors.black.withValues(alpha: 0.4),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: AppRadius.all16,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLoader(
                  size: 40,
                  strokeWidth: 3,
                  color: context.themePrimary,
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  AppText.body(
                    message!,
                    color: context.themeTextSecondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
