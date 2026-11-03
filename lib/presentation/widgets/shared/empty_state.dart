import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Spec empty state: 1 px dashed border card, centred icon, title and a
/// short line that says what will appear here (or what to do next).
///
/// ```dart
/// EmptyState(
///   icon: Icons.receipt_long_outlined,
///   title: l10n.noBillsYet,
///   message: l10n.submitFirstBill,
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.framed = true,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Draw the dashed card. Set false when the state fills a whole page.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.themeSoftSurface,
              borderRadius: AppRadius.all16,
            ),
            child: Icon(icon, size: 28, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.section(color: context.themeTextPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: context.themeTextSecondary),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );

    final body = framed
        ? CustomPaint(
            painter: _DashedBorderPainter(color: context.themeBorderStrong),
            child: SizedBox(width: double.infinity, child: content),
          )
        : content;

    return Semantics(
      container: true,
      label: message == null ? title : '$title. $message',
      excludeSemantics: actionLabel == null,
      child: Center(child: body),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0, gap = 4.0, radius = 16.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
