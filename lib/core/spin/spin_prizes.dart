import 'package:flutter/material.dart';

/// One slice of the Daily Buy Daily Win wheel. The wheel shows only the
/// product picture, never the name.
class SpinPrize {
  const SpinPrize(this.id, this.name, this.fallbackIcon);

  /// File name (without .png) in assets/images/spin_prizes/.
  final String id;

  /// For screen readers and admin reports only; not drawn on the wheel.
  final String name;

  /// Shown until the product photo is added to the assets folder.
  final IconData fallbackIcon;

  String get asset => 'assets/images/spin_prizes/$id.png';
}

/// The 10 prizes, clockwise from the top of the wheel.
const spinPrizes = <SpinPrize>[
  SpinPrize('power_drill', 'Power Drill Machine', Icons.hardware_rounded),
  SpinPrize('circular_saw', 'Circular Saw Machine', Icons.carpenter_rounded),
  SpinPrize('tool_box', 'Tool Box', Icons.home_repair_service_rounded),
  SpinPrize('hammer', 'Hammer', Icons.gavel_rounded),
  SpinPrize(
    'screwdriver_kit',
    'Screwdriver / Tool Kit',
    Icons.handyman_rounded,
  ),
  SpinPrize('measuring_tape', 'Measuring Tape', Icons.straighten_rounded),
  SpinPrize('aluminium_ladder', 'Aluminium Ladder', Icons.stairs_rounded),
  SpinPrize('hand_planer', 'Hand Planer', Icons.construction_rounded),
  SpinPrize('drill_bit_set', 'Drill Bit Set', Icons.build_rounded),
  SpinPrize(
    'tool_accessory_kit',
    'Tool Accessory Kit',
    Icons.inventory_2_rounded,
  ),
];
