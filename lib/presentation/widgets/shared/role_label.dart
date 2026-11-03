import 'package:flutter/widgets.dart';
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
