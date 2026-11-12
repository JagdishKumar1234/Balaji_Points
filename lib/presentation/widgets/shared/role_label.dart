import 'package:flutter/widgets.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/auth/role_service.dart';

/// Display name for a role in the current language.
///
/// Built-in roles that still use their default English name are translated;
/// custom names (and renamed built-ins) are shown exactly as the super admin
/// typed them. The stored `roleName` on user documents stays unchanged.
String roleDisplayName(BuildContext context, AppRole role) {
  final l10n = AppLocalizations.of(context)!;
  final builtIn = AppRole.builtInDefault(role.id);
  if (builtIn == null || builtIn.name != role.name) return role.name;
  return switch (role.id) {
    AppConstants.roleCarpenter => l10n.carpenter,
    AppConstants.roleArchitect => l10n.roleArchitect,
    AppConstants.roleEngineer => l10n.roleEngineer,
    AppConstants.roleInteriorDesigner => l10n.roleInteriorDesigner,
    _ => role.name,
  };
}

/// Name plus short form, e.g. "Architect · Ar.".
String roleSelectionLabel(BuildContext context, AppRole role) {
  final name = roleDisplayName(context, role);
  return role.abbreviation.isEmpty ? name : '$name · ${role.abbreviation}';
}

/// Role name for a stored role id, in the current language. Custom roles
/// use [storedName] (the user's saved `roleName`) or the id itself.
String roleLabelForId(BuildContext context, String? id, {String? storedName}) {
  final roleId = (id ?? '').trim().toLowerCase();
  if (roleId.isEmpty) return '';
  final builtIn = AppRole.builtInDefault(roleId);
  if (builtIn != null) return roleDisplayName(context, builtIn);
  final name = (storedName ?? '').trim();
  return name.isNotEmpty ? name : roleId;
}

/// Small navy pill with the member's role, for admin bill cards.
class RoleTag extends StatelessWidget {
  const RoleTag({super.key, required this.roleId, this.storedName});

  final String? roleId;
  final String? storedName;

  @override
  Widget build(BuildContext context) {
    final label = roleLabelForId(context, roleId, storedName: storedName);
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.themePrimary.withValues(alpha: 0.08),
        borderRadius: AppRadius.pill,
        border: Border.all(color: context.themePrimary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSmall(color: context.themePrimary),
      ),
    );
  }
}
