import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/spin/spin_prizes.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The prize name in the app language.
String spinPrizeLabel(BuildContext context, SpinPrize prize) {
  final l10n = AppLocalizations.of(context)!;
  return switch (prize.id) {
    'power_drill' => l10n.spinPrizePowerDrill,
    'circular_saw' => l10n.spinPrizeCircularSaw,
    'tool_box' => l10n.spinPrizeToolBox,
    'hammer' => l10n.spinPrizeHammer,
    'screwdriver_kit' => l10n.spinPrizeScrewdriverKit,
    'measuring_tape' => l10n.spinPrizeMeasuringTape,
    'aluminium_ladder' => l10n.spinPrizeLadder,
    'hand_planer' => l10n.spinPrizeHandPlaner,
    'drill_bit_set' => l10n.spinPrizeDrillBits,
    'tool_accessory_kit' => l10n.spinPrizeAccessoryKit,
    _ => prize.name,
  };
}

/// Ring colour of a prize: its slice colour on the wheel.
Color spinPrizeColor(SpinPrize prize) {
  final i = spinPrizes.indexOf(prize);
  const c = AppColors.spinWheelSlices;
  return c[(i < 0 ? 0 : i) % c.length];
}

/// Round prize picture: the product photo from assets/images/spin_prizes/,
/// or a matching tool icon until the photo is added. Used on the wheel, the
/// admin winner cards and the member home card.
class SpinPrizeImage extends StatelessWidget {
  const SpinPrizeImage({super.key, required this.prize, this.size});

  final SpinPrize prize;

  /// Fixed size; null fills the parent.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = spinPrizeColor(prize);
    return Semantics(
      label: spinPrizeLabel(context, prize),
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
        ),
        padding: const EdgeInsets.all(5),
        child: ClipOval(
          child: Image.asset(
            prize.asset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                FittedBox(child: Icon(prize.fallbackIcon, color: color)),
          ),
        ),
      ),
    );
  }
}
