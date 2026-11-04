import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:flutter/material.dart';

/// The role to show for a member account. Older accounts have no role saved
/// and count as carpenters; a renamed or custom role shows its saved name.
String memberRoleName(BuildContext context, Map<String, dynamic>? userData) {
  final saved = userData?['role'] as String?;
  final id = (saved == null || saved.trim().isEmpty)
      ? AppConstants.roleCarpenter
      : saved.trim().toLowerCase();
  final savedName = (userData?['roleName'] as String? ?? '').trim();
  final builtIn = AppRole.builtInDefault(id);
  if (builtIn == null) return savedName.isEmpty ? id : savedName;
  return savedName.isEmpty || savedName == builtIn.name
      ? roleDisplayName(context, builtIn)
      : savedName;
}

/// Round photo with a gold ring, or the person's initials when there is none.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
  });

  final String name;
  final double size;
  final String? imageUrl;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.h4(
            color: AppColors.gold,
          ).copyWith(fontSize: size * 0.34),
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
      ),
      child: ClipOval(
        child: url.startsWith('http')
            ? Image.network(
                url,
                key: ValueKey<String>(url),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

/// Gold tag showing the member's role, for use on navy.
class RoleTag extends StatelessWidget {
  const RoleTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: AppColors.goldSoft),
      ),
    );
  }
}
