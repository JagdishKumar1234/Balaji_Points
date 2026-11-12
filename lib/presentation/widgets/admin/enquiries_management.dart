import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/contact/contact_us_page.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';

/// Contact Us inbox. A branch admin passes their [branchId] and sees that
/// branch's logged-in member enquiries; the super admin passes null and
/// sees only guest enquiries (no branch).
class EnquiriesManagement extends ConsumerStatefulWidget {
  const EnquiriesManagement({super.key, this.branchId});

  final String? branchId;

  @override
  ConsumerState<EnquiriesManagement> createState() =>
      _EnquiriesManagementState();
}

class _EnquiriesManagementState extends ConsumerState<EnquiriesManagement> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(enquiriesProvider(widget.branchId));
    // Keeps showing the last list while the stream re-attaches, so coming
    // back to this screen never flashes a loader.
    return async.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: AppLoader()),
      error: (e, _) {
        final denied = e is FirebaseException && e.code == 'permission-denied';
        if (!denied) AppLogger.error('Enquiries failed to load', e);
        return Center(
          child: EmptyState(
            icon: denied ? Icons.lock_outline_rounded : Icons.wifi_off_rounded,
            title: denied ? l10n.enquiriesNoAccess : l10n.enquiryFailed,
          ),
        );
      },
      data: (all) {
        final open = all.where((e) => e.isOpen).toList();
        final done = all.where((e) => !e.isOpen).toList();
        final list = _showResolved ? done : open;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text('${l10n.enquiriesOpen} (${open.length})'),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('${l10n.enquiriesResolved} (${done.length})'),
                  ),
                ],
                selected: {_showResolved},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    setState(() => _showResolved = s.first),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: EmptyState(
                        icon: Icons.mark_email_read_rounded,
                        title: l10n.enquiriesEmpty,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _EnquiryCard(enquiry: list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EnquiryCard extends ConsumerWidget {
  const _EnquiryCard({required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final e = enquiry;
    final who = e.isGuest
        ? [
            l10n.enquiryGuest,
            if (e.city.isNotEmpty) e.city,
            // The super admin sees every guest: show the branch picked.
            if (e.branchName.isNotEmpty) e.branchName,
          ].join(' · ')
        : [
            enquiryRoleLabel(context, e.role),
          ].where((s) => s.isNotEmpty).join(' · ');
    final when = e.createdAt == null
        ? ''
        : DateFormat('d MMM, h:mm a').format(e.createdAt!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.forCard,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.themeGoldSoft,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  enquiryTypeLabel(l10n, e.type),
                  style: AppTypography.labelSmall(
                    color: context.isDarkMode
                        ? AppColors.darkPendingText
                        : AppColors.pendingText,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                when,
                style: AppTypography.caption(color: context.themeTextMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            e.name,
            style: AppTypography.labelLarge(color: context.themeTextPrimary),
          ),
          if (who.isNotEmpty)
            Text(
              who,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
          // Career applications: position and experience.
          if (e.position.isNotEmpty || e.experience.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [e.position, e.experience].where((s) => s.isNotEmpty).join(' · '),
              style: AppTypography.labelMedium(color: context.themePrimary),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            e.message,
            style: AppTypography.bodyMedium(color: context.themeTextPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.call_rounded, size: 18),
                label: Text(e.phone),
                onPressed: () =>
                    launchUrl(Uri(scheme: 'tel', path: '+91${e.phone}')),
              ),
              FilledButton.tonalIcon(
                icon: Icon(
                  e.isOpen ? Icons.check_rounded : Icons.undo_rounded,
                  size: 18,
                ),
                label: Text(
                  e.isOpen ? l10n.enquiryMarkResolved : l10n.enquiryReopen,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final failed = l10n.enquiryFailed;
                  try {
                    await ref
                        .read(enquiryServiceProvider)
                        .setResolved(e, e.isOpen);
                  } catch (err) {
                    AppLogger.error('Enquiry update failed', err);
                    messenger.showSnackBar(SnackBar(content: Text(failed)));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
