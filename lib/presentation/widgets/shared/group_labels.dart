import 'package:flutter/widgets.dart';

import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';

/// Display names for the two member groups.
extension LeaderboardGroupLabels on LeaderboardGroup {
  /// "Top Carpenters & Interior Designers" / "Top Architects & Engineers".
  String boardTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return this == LeaderboardGroup.trade
        ? l10n.groupTradeTitle
        : l10n.groupProfessionalTitle;
  }

  /// "Carpenter & Interior" / "Architect & Engineer".
  String shortLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return this == LeaderboardGroup.trade
        ? l10n.groupTradeShort
        : l10n.groupProfessionalShort;
  }
}

/// "All members", "Carpenter & Interior", "Architect", ...
String memberRoleFilterLabel(BuildContext context, MemberRoleFilter f) {
  final l10n = AppLocalizations.of(context)!;
  final g = f.groupValue;
  if (g != null) return g.shortLabel(context);
  final r = f.roleValue;
  if (r != null) return roleLabelForId(context, r);
  return l10n.allMembers;
}
