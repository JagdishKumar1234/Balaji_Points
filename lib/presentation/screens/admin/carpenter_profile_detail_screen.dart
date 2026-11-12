import 'package:balaji_points/services/auth/role_service.dart';
import 'package:balaji_points/core/points/points_rate.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:intl/intl.dart';

class CarpenterProfileDetailScreen extends StatefulWidget {
  final String carpenterId;

  const CarpenterProfileDetailScreen({required this.carpenterId, super.key});

  @override
  State<CarpenterProfileDetailScreen> createState() =>
      _CarpenterProfileDetailScreenState();
}

class _CarpenterProfileDetailScreenState
    extends State<CarpenterProfileDetailScreen> {
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;
  String _statusFilter = 'all';
  String? _siteFilter;

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return AppColors.tierPlatinum;
      case 'gold':
        return AppColors.tierGold;
      case 'silver':
        return AppColors.tierSilver;
      case 'bronze':
        return AppColors.tierBronze;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _handleResetPin(
    BuildContext dialogContext,
    String pin,
    String confirmPin,
    String carpenterPhone,
  ) async {
    if (pin.isEmpty || confirmPin.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pleaseEnterPinInBothFields,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (pin != confirmPin) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinMismatch),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (pin.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.enter4Digits),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      if (mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pinMustContainOnlyNumbers,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      final pinAuthService = PinAuthService();
      final success = await pinAuthService.resetPin(
        phone: carpenterPhone,
        newPin: pin,
        isAdmin: true,
      );

      if (!mounted) return;

      if (success) {
        if (Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pinResetSuccessfully),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminResetPinFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorResettingPin('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resetPinDialog(
    BuildContext context,
    String carpenterId,
    String carpenterPhone,
    String carpenterName,
  ) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.resetPin),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.resetPinFor('$carpenterName'),
                style: AppTypography.bodyMedium().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.phone2('$carpenterPhone'),
                style: AppTypography.bodySmall().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: AppRadius.md12,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.carpenterWillNeedToUseThis,
                  style: TextStyle(fontSize: 12, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.newPinLabel,
                  hintText: AppLocalizations.of(context)!.hintPin,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPinController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPin,
                  hintText: AppLocalizations.of(context)!.hintConfirmPin,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => _handleResetPin(
              dialogContext,
              pinController.text.trim(),
              confirmPinController.text.trim(),
              carpenterPhone,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.navigation,
            ),
            child: Text(
              AppLocalizations.of(context)!.resetPin,
              style: TextStyle(color: AppColors.navigation),
            ),
          ),
        ],
      ),
    ).then((_) {
      pinController.dispose();
      confirmPinController.dispose();
    });
  }

  Future<void> _selectHistoryDate(
    BuildContext context,
    bool isStartDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_historyStartDate ?? DateTime.now())
          : (_historyEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: context.themeSurface,
              onSurface: context.themeTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _historyStartDate = picked;
        } else {
          _historyEndDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.carpenterId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: context.themePrimary),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: AppText.title(
                AppLocalizations.of(context)!.carpenterDetails,
              ),
            ),
            body: Center(
              child: AppText.body(
                AppLocalizations.of(context)!.carpenterNotFound,
              ),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        final phone = userData['phone'] ?? '';
        final totalPoints = (userData['totalPoints'] ?? 0) as num;
        final tier = userData['tier'] ?? 'Bronze';
        final profileImage = userData['profileImage'] ?? '';
        final branchId = userData['branchId'] ?? '';
        final createdAt = userData['createdAt'] as Timestamp?;
        final carpenterName = '$firstName $lastName';

        return Scaffold(
          backgroundColor: context.themeBackground,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: AppText.title(
              AppLocalizations.of(context)!.carpenterDetails,
            ),
            centerTitle: false,
            actions: context.isDesktop
                ? [
                    // Desktop: Show as button group
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(
                              Icons.lock_reset_rounded,
                              color: context.themePrimary,
                            ),
                            label: Text(AppLocalizations.of(context)!.resetPin),
                            onPressed: () => _resetPinDialog(
                              context,
                              widget.carpenterId,
                              phone,
                              carpenterName,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: context.themePrimary,
                            ),
                            label: Text(AppLocalizations.of(context)!.edit),
                            onPressed: () => _showEditDialog(
                              context,
                              widget.carpenterId,
                              userData,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : [
                    // Mobile: Show as icons
                    IconButton(
                      icon: Icon(
                        Icons.lock_reset_rounded,
                        color: context.themePrimary,
                      ),
                      onPressed: () => _resetPinDialog(
                        context,
                        widget.carpenterId,
                        phone,
                        carpenterName,
                      ),
                      tooltip: AppLocalizations.of(context)!.resetPin,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: context.themePrimary,
                      ),
                      onPressed: () => _showEditDialog(
                        context,
                        widget.carpenterId,
                        userData,
                      ),
                      tooltip: AppLocalizations.of(context)!.edit,
                    ),
                  ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carpenter Profile Card
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipOval(
                        child: profileImage.isNotEmpty
                            ? Image.network(
                                profileImage,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    color: context.themeBackground,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 28,
                                      color: context.themeTextSecondary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: context.themeBackground,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.section(
                              '$firstName $lastName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: AppText.caption(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AppText.caption(
                                AppLocalizations.of(context)!.active,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Statistics Card - 3 Column Layout
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Total Points Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.themeContentColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: context.themeContentColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.section(
                                  PointsUtils.formatPoints(totalPoints),
                                ),
                                const SizedBox(height: 1),
                                AppText.caption(
                                  AppLocalizations.of(
                                    context,
                                  )!.totalPointsLabel,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(tier),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText.caption(
                              tier,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 3 Column Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatColumn(
                              context,
                              Icons.check_circle_rounded,
                              '32',
                              AppLocalizations.of(context)!.approvedLabel,
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatColumn(
                              context,
                              Icons.schedule_rounded,
                              '5',
                              AppLocalizations.of(context)!.pendingStatus,
                              AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatColumn(
                              context,
                              Icons.cancel_rounded,
                              '2',
                              AppLocalizations.of(context)!.rejectedLabel,
                              AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Carpenter Information
                FutureBuilder<Map<String, dynamic>?>(
                  future: BranchService().getBranch(branchId),
                  builder: (context, branchSnapshot) {
                    final branchName =
                        branchSnapshot.data?['shortName'] ??
                        branchSnapshot.data?['name'] ??
                        (branchId.isNotEmpty ? branchId : '-');

                    return AppCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: context.themeContentColor,
                              ),
                              const SizedBox(width: 5),
                              AppText.section(
                                AppLocalizations.of(
                                  context,
                                )!.carpenterInformation,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_rounded,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 3),
                                        AppText.caption(
                                          AppLocalizations.of(context)!.phone,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    AppText.caption(
                                      phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 3),
                                        AppText.caption(
                                          AppLocalizations.of(
                                            context,
                                          )!.memberSince,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    AppText.caption(
                                      createdAt != null
                                          ? DateFormat(
                                              'dd MMM',
                                            ).format(createdAt.toDate())
                                          : '-',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.business_rounded,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 3),
                                        AppText.caption(
                                          AppLocalizations.of(context)!.branch,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    AppText.caption(
                                      branchName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 3),
                                        AppText.caption(
                                          AppLocalizations.of(
                                            context,
                                          )!.totalPointsLabel,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    AppText.caption(
                                      PointsUtils.formatPoints(totalPoints),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Pending Bill Requests Section
                _buildPendingBillsSection(context, widget.carpenterId),

                const SizedBox(height: 16),

                // Complete History Header
                Text(
                  AppLocalizations.of(context)!.completeHistory,
                  style: AppTypography.labelLarge().copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),

                // Filters Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: context.themeContentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.filters,
                          style: AppTypography.labelMedium().copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _statusFilter = 'all';
                          _siteFilter = null;
                          _historyStartDate = null;
                          _historyEndDate = null;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: context.themePrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.clearAll,
                            style: AppTypography.labelSmall().copyWith(
                              fontSize: 12,
                              color: context.themePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Site Filter Dropdown
                _buildSiteFilterDropdown(context, widget.carpenterId),
                const SizedBox(height: 10),

                // Date Range Filters
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectHistoryDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _historyStartDate != null
                                  ? context.themePrimary
                                  : context.themeBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _historyStartDate != null
                                      ? DateFormat(
                                          'dd MMM',
                                        ).format(_historyStartDate!)
                                      : AppLocalizations.of(context)!.fromDate,
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectHistoryDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _historyEndDate != null
                                  ? context.themePrimary
                                  : context.themeBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _historyEndDate != null
                                      ? DateFormat(
                                          'dd MMM',
                                        ).format(_historyEndDate!)
                                      : AppLocalizations.of(context)!.toDate,
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Filter Pills
                Row(
                  children: [
                    _buildFilterPill(
                      context,
                      AppLocalizations.of(context)!.all,
                      'all',
                      AppColors.primaryOnDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      context,
                      AppLocalizations.of(context)!.approvedLabel,
                      'approved',
                      AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      context,
                      AppLocalizations.of(context)!.pendingStatus,
                      'pending',
                      AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      context,
                      AppLocalizations.of(context)!.rejectedLabel,
                      'rejected',
                      AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // History Items
                _buildHistoryList(context, widget.carpenterId),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String carpenterId,
    Map<String, dynamic> userData,
  ) async {
    final firstNameController = TextEditingController(
      text: userData['firstName'] ?? '',
    );
    final lastNameController = TextEditingController(
      text: userData['lastName'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData['phone'] ?? '',
    );
    final branchIdController = TextEditingController(
      text: userData['branchId'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.title(AppLocalizations.of(context)!.editCarpenter),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.firstName,
                  hintText: AppLocalizations.of(context)!.enterFirstName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.lastName,
                  hintText: AppLocalizations.of(context)!.enterLastName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumber,
                  hintText: AppLocalizations.of(context)!.hintPhone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: AppLocalizations.of(
                    context,
                  )!.changingPhoneNumberWillUpdateLogin,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: branchIdController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.branchId,
                  hintText: AppLocalizations.of(context)!.hintBranchId,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: AppText.body(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = phoneController.text.trim();
              if (newPhone.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.phoneNumberCannotBeEmpty,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(carpenterId)
                    .update({
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'phone': newPhone,
                      'branchId': branchIdController.text,
                    });

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText.body(
                        AppLocalizations.of(
                          context,
                        )!.carpenterUpdatedSuccessfully,
                        color: AppColors.white,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: AppText.body(
                        AppLocalizations.of(
                          context,
                        )!.errorUpdatingCarpenter('$e'),
                        color: AppColors.white,
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: context.themeOnPrimary,
              backgroundColor: context.themePrimary,
            ),
            child: AppText.body(
              AppLocalizations.of(context)!.update,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    ).then((_) {
      firstNameController.dispose();
      lastNameController.dispose();
      phoneController.dispose();
      branchIdController.dispose();
    });
  }

  Widget _buildStatColumn(
    BuildContext context,
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        AppText.section(count, color: color),
        const SizedBox(height: 2),
        AppText.caption(label),
      ],
    );
  }

  Widget _buildFilterPill(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final isSelected = value == 'all' || _statusFilter == value;
    final selectedForeground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? AppColors.white
        : AppColors.navigation;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _statusFilter = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : context.themeSoftSurface,
        foregroundColor: isSelected
            ? selectedForeground
            : context.themeTextPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: !isSelected
              ? BorderSide(color: context.themeBorder)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall().copyWith(fontSize: 12),
      ),
    );
  }

  Widget _buildSiteFilterDropdown(BuildContext context, String carpenterId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .snapshots(),
      builder: (context, snapshot) {
        final sites = <String>[];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>?;
              if (data != null) {
                final site = (data['siteName'] as String?) ?? '';
                if (site.isNotEmpty && !sites.contains(site)) {
                  sites.add(site);
                }
              }
            } catch (e) {
              // Silently ignore documents without siteName
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.themeSoftSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.themeBorder),
          ),
          child: DropdownButton<String?>(
            value: _siteFilter,
            underline: const SizedBox(),
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  AppLocalizations.of(context)!.allSites,
                  style: AppTypography.bodySmall().copyWith(fontSize: 12),
                ),
              ),
              ...sites.map(
                (site) => DropdownMenuItem(
                  value: site,
                  child: Text(
                    site,
                    style: AppTypography.bodySmall().copyWith(fontSize: 12),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _siteFilter = value;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingBillsSection(BuildContext context, String carpenterId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: context.themePrimary),
          );
        }

        final bills = snapshot.data?.docs ?? [];

        if (bills.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.pendingBillRequests,
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 16,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bills.length}',
                    style: AppTypography.labelSmall().copyWith(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final billData = bills[index].data() as Map<String, dynamic>;
                billData['billId'] = bills[index].id;
                return _buildPendingBillCard(context, billData);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingBillCard(
    BuildContext context,
    Map<String, dynamic> bill,
  ) {
    final imageUrl = bill['imageUrl'] as String? ?? '';
    final billNumber = bill['billNumber'] ?? 'N/A';
    final siteName = bill['siteName'] ?? '-';
    final amount = bill['amount'] ?? 0;
    final billDate = bill['billDate'] as Timestamp?;
    final billId = bill['billId'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.md12,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                if (imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => showFullScreenImage(context, imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: context.themeBackground,
                          child: Icon(
                            Icons.receipt_rounded,
                            size: 24,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: context.themeBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.receipt_rounded,
                      size: 24,
                      color: context.themeTextSecondary,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFA500,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'PENDING',
                          style: AppTypography.labelSmall().copyWith(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.siteMaterialPurchase,
                        style: AppTypography.labelMedium().copyWith(
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.billNo2('$billNumber'),
                        style: AppTypography.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.site3('$siteName'),
                        style: AppTypography.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        billDate != null
                            ? DateFormat(
                                'dd MMM yyyy • hh:mm a',
                              ).format(billDate.toDate())
                            : '-',
                        style: AppTypography.bodySmall().copyWith(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.pendingStatus,
                        style: AppTypography.labelSmall().copyWith(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${amount.toStringAsFixed(0)}',
                          style: AppTypography.labelMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.pts7(PointsRate.forBill(bill).toStringAsFixed(2)),
                          style: AppTypography.bodySmall().copyWith(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectPendingBill(billId ?? ''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      AppLocalizations.of(context)!.reject,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approvePendingBill(bill),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      AppLocalizations.of(context)!.approve,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approvePendingBill(Map<String, dynamic> bill) async {
    final billId = bill['billId'] as String?;
    final amount = (bill['amount'] ?? 0).toDouble();
    // Preview at the member's role rate, the same rate approval credits.
    String? role;
    try {
      final member = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.carpenterId)
          .get();
      role = member.data()?['role'] as String?;
    } catch (_) {}
    final rate = await RoleService().rateForRole(role);
    final previewPoints = PointsRate.forBill(bill, rupeesPerPoint: rate);
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText.label(AppLocalizations.of(context)!.approveBillAction),
        content: AppText.body(
          AppLocalizations.of(context)!.approveThisBillOfPointsWill2(
            '${amount.toStringAsFixed(0)}',
            previewPoints.toStringAsFixed(2),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.approve,
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || billId == null) return;

    _showLoadingDialog();

    try {
      final billService = BillService();
      final success = await billService.approveBill(
        billId,
        widget.carpenterId,
        amount,
      );

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billApproved),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToApproveBill2),
            backgroundColor: context.themeError,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error2('$e')),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _rejectPendingBill(String billId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.rejectBill,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: context.themeError,
          ),
        ),
        content: AppText.body(
          AppLocalizations.of(context)!.rejectBillConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: context.themeOnError,
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.reject,
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingDialog();

    try {
      final billService = BillService();
      final success = await billService.rejectBill(billId);

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billRejected),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToRejectBill2),
            backgroundColor: context.themeError,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.error2('$e')),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: context.themePrimary)),
    );
  }

  Widget _buildHistoryList(BuildContext context, String carpenterId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getCombinedHistoryStream(carpenterId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: context.themePrimary),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                AppLocalizations.of(context)!.noHistoryFound,
                style: AppTypography.bodyMedium().copyWith(
                  color: context.themeTextSecondary,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            if (event['type'] == 'bill') {
              return _buildBillItem(context, event);
            } else {
              return _buildPointsItem(context, event);
            }
          },
        );
      },
    );
  }

  Widget _buildBillItem(BuildContext context, Map<String, dynamic> bill) {
    final imageUrl = bill['imageUrl'] as String? ?? '';
    final billNumber = bill['billNumber'] ?? 'N/A';
    final siteName = bill['siteName'] ?? '-';
    final amount = bill['amount'] ?? 0;
    final status = bill['status'] ?? 'pending';
    final billDate = bill['billDate'] as Timestamp?;

    final statusColor = status == 'approved'
        ? AppColors.success
        : status == 'rejected'
        ? AppColors.error
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.md12,
        border: Border.all(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => showFullScreenImage(context, imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: context.themeBackground,
                      child: Icon(
                        Icons.receipt_rounded,
                        size: 24,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.themeBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  size: 24,
                  color: context.themeTextSecondary,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeContentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'BILL',
                      style: AppTypography.labelSmall().copyWith(
                        fontSize: 12,
                        color: context.themeContentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.siteMaterialPurchase,
                    style: AppTypography.labelMedium().copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.billNo2('$billNumber'),
                    style: AppTypography.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.site3('$siteName'),
                    style: AppTypography.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    billDate != null
                        ? DateFormat(
                            'dd MMM yyyy • hh:mm a',
                          ).format(billDate.toDate())
                        : '-',
                    style: AppTypography.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: AppTypography.labelSmall().copyWith(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: AppTypography.labelMedium().copyWith(
                        fontSize: 13,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.pts7(PointsRate.forBill(bill).toStringAsFixed(2)),
                      style: AppTypography.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.themeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsItem(BuildContext context, Map<String, dynamic> points) {
    final pointsValue = points['points'] ?? 0;
    final reason =
        points['reason'] ?? AppLocalizations.of(context)!.pointsAwarded;
    final timestamp = points['timestamp'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.md12,
        border: Border.all(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.themeContentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.star_outlined,
                size: 24,
                color: context.themeContentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeContentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'POINTS',
                      style: AppTypography.labelSmall().copyWith(
                        fontSize: 12,
                        color: context.themeContentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: AppTypography.labelMedium().copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timestamp != null
                        ? DateFormat(
                            'dd MMM yyyy • hh:mm a',
                          ).format(timestamp.toDate())
                        : '-',
                    style: AppTypography.bodySmall().copyWith(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.approvedLabel,
                    style: AppTypography.labelSmall().copyWith(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${pointsValue.toStringAsFixed(2)}',
                      style: AppTypography.labelMedium().copyWith(
                        fontSize: 13,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.pointsLabel,
                      style: AppTypography.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.themeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedHistoryStream(
    String carpenterId,
  ) {
    return FirebaseFirestore.instance
        .collection('bills')
        .where('carpenterId', isEqualTo: carpenterId)
        .snapshots()
        .asyncMap((billSnapshot) async {
          final bills = billSnapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'type': 'bill'};
          }).toList();

          final pointsSnapshot = await FirebaseFirestore.instance
              .collection('points_history')
              .where('userId', isEqualTo: carpenterId)
              .get();

          final points = pointsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {...data, 'type': 'points'};
          }).toList();

          final combined = [...bills, ...points];
          combined.sort((a, b) {
            final dateA = (a['timestamp'] ?? a['billDate']) as Timestamp?;
            final dateB = (b['timestamp'] ?? b['billDate']) as Timestamp?;

            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          });

          // Apply filters
          return combined.where((event) {
            // Site filter (only applies to bills)
            if (_siteFilter != null && event['type'] == 'bill') {
              final siteName = event['siteName'] as String? ?? '';
              if (siteName != _siteFilter) {
                return false;
              }
            }

            final status = event['status'] as String? ?? 'pending';

            // Status filter pills
            if (_statusFilter == 'all') {
              // All pills selected is same as "All" button
            } else if (_statusFilter == 'approved' && status != 'approved') {
              return false;
            } else if (_statusFilter == 'pending' && status != 'pending') {
              return false;
            } else if (_statusFilter == 'rejected' && status != 'rejected') {
              return false;
            }

            // Date range filter
            final timestamp = event['timestamp'] ?? event['billDate'];
            if (timestamp != null) {
              final date = timestamp is Timestamp
                  ? timestamp.toDate()
                  : (timestamp as DateTime);
              if (_historyStartDate != null &&
                  date.isBefore(_historyStartDate!)) {
                return false;
              }
              if (_historyEndDate != null &&
                  date.isAfter(_historyEndDate!.add(const Duration(days: 1)))) {
                return false;
              }
            }

            return true;
          }).toList();
        });
  }
}
