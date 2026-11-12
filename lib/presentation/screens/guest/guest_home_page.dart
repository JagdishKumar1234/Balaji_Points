import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalogs_page.dart';
import 'package:balaji_points/presentation/screens/common/contact/contact_us_page.dart';
import 'package:balaji_points/presentation/screens/guest/branches_page.dart';
import 'package:balaji_points/services/branch/public_branches.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';

/// Guest mode (no login), with its own bottom tab bar:
/// Home · Catalogs · Branches · Contact. Careers and service requests open
/// from Home. Guests cannot see or submit bills, points or offers.
class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key, this.initialTab = 0});

  /// 0 Home, 1 Catalogs, 2 Branches, 3 Contact.
  final int initialTab;

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  late int _tab = widget.initialTab.clamp(0, 3);

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: IndexedStack(
        index: _tab,
        children: [
          _GuestHomeTab(onOpenTab: _go),
          const CatalogsPage(inTab: true),
          const BranchesPage(inTab: true),
          const ContactUsPage(inTab: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.guestTabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l10n.guestTabCatalogs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined),
            selectedIcon: const Icon(Icons.location_on_rounded),
            label: l10n.guestTabBranches,
          ),
          NavigationDestination(
            icon: const Icon(Icons.support_agent_outlined),
            selectedIcon: const Icon(Icons.support_agent_rounded),
            label: l10n.guestTabContact,
          ),
        ],
      ),
    );
  }
}

class _GuestHomeTab extends StatelessWidget {
  const _GuestHomeTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(onExplore: () => onOpenTab(1)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats card overlaps the bottom of the navy header.
                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: const _Stats(),
                  ),
                  _SectionTitle(l10n.guestWeOffer),
                  _Offerings(onTap: () => onOpenTab(1)),
                  const SizedBox(height: 22),
                  _SectionTitle(l10n.guestQuickLinks),
                  _QuickLinks(onOpenTab: onOpenTab),
                  const SizedBox(height: 22),
                  const _JoinPanel(),
                  const SizedBox(height: 14),
                  const _GrowPanel(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Navy header: rounded logo, name and Log in, then the hero line and
/// Explore catalogs.
class _Header extends StatelessWidget {
  const _Header({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0B2A5B)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo on a white tile with rounded corners.
                  Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.md12,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.sm8,
                      child: Image.asset(
                        'assets/images/balaji_point_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h5(color: AppColors.white),
                        ),
                        Text(
                          l10n.guestTagline,
                          // Two lines: next to Log in, one was cut off.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: Text(l10n.guestLogin),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.guestHeroTitle,
                style: AppTypography.h3(color: AppColors.white),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guestHeroBody,
                style: AppTypography.bodyMedium(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  // The theme gives outlined buttons a white fill; on navy
                  // that hid the white label.
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.gold, width: 1.5),
                ),
                onPressed: onExplore,
                icon: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.gold,
                ),
                label: Text(l10n.guestExploreCatalogs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live numbers: branches, catalogs and categories.
class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final branches = ref.watch(publicBranchesProvider).asData?.value.length;
    final catalogs = ref.watch(allCatalogsProvider).asData?.value.length;
    final categories = ref
        .watch(catalogCategoriesProvider)
        .asData
        ?.value
        .length;
    Widget stat(int? n, String label, IconData icon) => Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(height: 4),
          Text(
            n?.toString() ?? '–',
            style: AppTypography.h4(color: context.themePrimary),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: context.themeTextSecondary),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          stat(branches, l10n.guestStatBranches, Icons.storefront_rounded),
          stat(catalogs, l10n.guestStatCatalogs, Icons.menu_book_rounded),
          stat(categories, l10n.guestStatCategories, Icons.category_rounded),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppTypography.h5(color: context.themeTextPrimary)),
  );
}

/// What the stores sell: plywood, laminates, doors, hardware, fittings,
/// service. Tapping opens the catalogs.
class _Offerings extends StatelessWidget {
  const _Offerings({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.layers_rounded, l10n.guestOfferPlywood),
      (Icons.texture_rounded, l10n.guestOfferLaminates),
      (Icons.door_front_door_rounded, l10n.guestOfferDoors),
      (Icons.hardware_rounded, l10n.guestOfferHardware),
      (Icons.handyman_rounded, l10n.guestOfferFittings),
      (Icons.support_agent_rounded, l10n.guestOfferService),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 600 ? 6 : 3;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          // Room for a two-line label at large font sizes too.
          childAspectRatio: 0.9,
          children: [
            for (final (icon, label) in items)
              Material(
                color: context.themeCard,
                borderRadius: AppRadius.md12,
                child: InkWell(
                  borderRadius: AppRadius.md12,
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md12,
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.themeGoldSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: context.themePrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall(
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final links = [
      (
        Icons.build_circle_rounded,
        l10n.guestService,
        l10n.guestServiceSub,
        () => context.push('/contact-us?type=${EnquiryType.service.id}'),
      ),
      (
        Icons.work_rounded,
        l10n.guestCareers,
        l10n.guestCareersSub,
        () => context.push('/careers'),
      ),
      (
        Icons.location_on_rounded,
        l10n.guestBranches,
        l10n.guestBranchesSub,
        () => onOpenTab(2),
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.themeBorder),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.themePrimary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.md12,
                ),
                child: Icon(links[i].$1, color: context.themePrimary),
              ),
              title: Text(
                links[i].$2,
                style: AppTypography.labelLarge(
                  color: context.themeTextPrimary,
                ),
              ),
              subtitle: Text(
                links[i].$3,
                style: AppTypography.caption(color: context.themeTextSecondary),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.themeTextMuted,
              ),
              onTap: links[i].$4,
            ),
          ],
        ],
      ),
    );
  }
}

/// For carpenters, architects, engineers and interior designers.
class _JoinPanel extends StatelessWidget {
  const _JoinPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Panel(
      color: AppColors.primary,
      icon: Icons.workspace_premium_rounded,
      title: l10n.guestJoinTitle,
      body: l10n.guestJoinBody,
      points: [
        l10n.guestJoinPoint1,
        l10n.guestJoinPoint2,
        l10n.guestJoinPoint3,
      ],
      actions: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primary,
            ),
            onPressed: () => context.go('/register'),
            child: Text(l10n.guestRegister),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.white,
              side: BorderSide(color: AppColors.white.withValues(alpha: 0.6)),
            ),
            onPressed: () => context.go('/login'),
            child: Text(l10n.guestLogin),
          ),
        ),
      ],
    );
  }
}

/// For store owners: run Balaji Points for your own store or branch.
class _GrowPanel extends StatelessWidget {
  const _GrowPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Panel(
      color: const Color(0xFF6B4E16),
      icon: Icons.trending_up_rounded,
      title: l10n.guestGrowTitle,
      body: l10n.guestGrowBody,
      points: [
        l10n.guestGrowPoint1,
        l10n.guestGrowPoint2,
        l10n.guestGrowPoint3,
      ],
      actions: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primary,
            ),
            onPressed: () =>
                context.push('/contact-us?type=${EnquiryType.partner.id}'),
            icon: const Icon(Icons.handshake_rounded),
            label: Text(l10n.guestGrowCta),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    required this.points,
    required this.actions,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final List<String> points;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, AppColors.black, 0.25)!],
      ),
      borderRadius: AppRadius.forCard,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.h5(color: AppColors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: AppTypography.bodySmall(
            color: AppColors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 10),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p,
                    style: AppTypography.labelMedium(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(children: actions),
      ],
    ),
  );
}
