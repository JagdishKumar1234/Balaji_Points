import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:flutter/material.dart';

/// The title above a Home section (e.g. Latest Offers, Announcements), so
/// each section is clearly separate. Same 16 px sides as the cards.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.themeGoldSoft,
              borderRadius: AppRadius.sm8,
            ),
            child: Icon(icon, size: 16, color: context.themeTextPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h5(color: context.themeTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
