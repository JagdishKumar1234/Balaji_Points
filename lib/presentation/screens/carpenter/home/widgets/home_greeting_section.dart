import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

/// Minimal-height greeting strip (~half the height of a typical card row).
class HomeGreetingSection extends StatefulWidget {
  final String userName;

  const HomeGreetingSection({super.key, required this.userName});

  @override
  State<HomeGreetingSection> createState() => _HomeGreetingSectionState();
}

class _HomeGreetingSectionState extends State<HomeGreetingSection> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final hour = now.hour;
    final isDayTime = hour >= 6 && hour < 18;

    final greeting = hour < 12
        ? l10n.goodMorningGreeting
        : (hour < 17 ? l10n.goodAfternoonGreeting : l10n.goodEveningGreeting);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.sm8,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightPrimary.withValues(alpha: 0.07),
              AppColors.lightSecondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppTypography.bodyMedium().copyWith(
                    fontSize: 12.0,
                    color: AppColors.lightTextPrimary.withValues(alpha: 0.72),
                    height: 1.0,
                  ),
                  children: [
                    TextSpan(text: '$greeting, '),
                    TextSpan(
                      text: widget.userName,
                      style: AppTypography.buttonMedium().copyWith(
                        fontSize: 12.0,
                        color: AppColors.lightTextPrimary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 4.0),
            _SunMoonBadge(
              isDayTime: isDayTime,
              pressed: _pressed,
              onPressedChanged: (pressed) {
                setState(() {
                  _pressed = pressed;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SunMoonBadge extends StatelessWidget {
  final bool isDayTime;
  final bool pressed;
  final ValueChanged<bool> onPressedChanged;

  const _SunMoonBadge({
    required this.isDayTime,
    required this.pressed,
    required this.onPressedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isDayTime ? Icons.wb_sunny_outlined : Icons.nightlight_round;

    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: pressed ? 0.92 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDayTime
                  ? [const Color(0xFFFFD54F), AppColors.amber]
                  : [AppColors.info, const Color(0xFF8E24AA)],
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 16.0,
          ),
        ),
      ),
    );
  }
}
