import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class BillDetailsPage extends StatefulWidget {
  final String billId;
  final Map<String, dynamic>? initialBillData;

  const BillDetailsPage({
    super.key,
    required this.billId,
    this.initialBillData,
  });

  @override
  State<BillDetailsPage> createState() => _BillDetailsPageState();
}

class _BillDetailsPageState extends State<BillDetailsPage> {
  final BillService _billService = BillService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _billData;
  Map<String, dynamic>? _carpenterData;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  Future<void> _loadBillData() async {
    setState(() => _isLoading = true);

    try {
      final billDoc = await _firestore
          .collection('bills')
          .doc(widget.billId)
          .get();
      if (billDoc.exists) {
        _billData = billDoc.data();
        _billData!['billId'] = billDoc.id;

        final carpenterId = _billData!['carpenterId'] as String?;
        if (carpenterId != null) {
          await _loadCarpenterData(carpenterId);
        }
      }
    } catch (e) {
      AppLogger.debug('Error loading bill data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCarpenterData(String carpenterId) async {
    try {
      final doc = await _firestore.collection('users').doc(carpenterId).get();
      if (doc.exists) {
        _carpenterData = doc.data();
        return;
      }

      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: carpenterId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        _carpenterData = query.docs.first.data();
      }
    } catch (e) {
      AppLogger.debug('Error loading carpenter data: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return AppLocalizations.of(context)!.pendingApproval2;
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'rejected':
        return Icons.check_circle_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Future<void> _approveBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(AppLocalizations.of(context)!.approveBillAction),
        content: Text(
          AppLocalizations.of(
            context,
          )!.areYouSureYouWantTo(_billData!['amount']?.toString() ?? '0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.success,
            ),
            child: Text(AppLocalizations.of(context)!.approve),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _billService.approveBill(
        widget.billId,
        _billData!['carpenterId'],
        _billData!['amount'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billApproved),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error2('${e.toString()}'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(AppLocalizations.of(context)!.rejectBill),
        content: Text(AppLocalizations.of(context)!.rejectBillConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: AppColors.white,
              backgroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _billService.rejectBill(widget.billId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.billRejected2),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error2('${e.toString()}'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _viewFullImage() {
    final imageUrl = _billData!['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) return;
    showFullScreenImage(context, imageUrl);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          AppLocalizations.of(context)!.billDetails,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.textPrimary),
            onPressed: () {},
            tooltip: AppLocalizations.of(context)!.share,
          ),
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
            tooltip: 'PDF',
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.themePrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _billData == null
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.billNotFound,
                        style: AppTypography.bodyMedium().copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        _buildStatusCard(context),
                        const SizedBox(height: 12),

                        // Carpenter Information
                        _buildCarpenterCard(context),
                        const SizedBox(height: 12),

                        // Bill Summary
                        _buildBillSummaryCard(context),
                        const SizedBox(height: 12),

                        // Bill Attachment
                        if (_billData!['imageUrl'] != null &&
                            (_billData!['imageUrl'] as String).isNotEmpty)
                          _buildAttachmentCard(context),
                        const SizedBox(height: 12),

                        // Timeline
                        _buildTimelineCard(context),
                        const SizedBox(height: 16),

                        // Action Buttons (if pending)
                        if (_billData!['status'] == 'pending')
                          _buildActionButtons(context),

                        const SizedBox(height: 20),
                      ],
                    ),
            ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final status = _billData!['status'] as String? ?? 'pending';
    final billNumber = _billData!['billNumber'] as String? ?? 'N/A';
    final createdAt = _billData!['createdAt'] as Timestamp?;
    final storeName = (_billData!['siteName'] as String? ?? '').isNotEmpty
        ? (_billData!['siteName'] as String)
        : '-';

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: AppRadius.all16,
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: AppColors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.billId,
            style: AppTypography.bodySmall().copyWith(
              fontSize: 12,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            billNumber,
            style: AppTypography.labelLarge().copyWith(
              fontSize: 12,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              AppLocalizations.of(
                context,
              )!.submitted('${_getTimeAgo(createdAt)}'),
              style: AppTypography.bodySmall().copyWith(
                fontSize: 12,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: context.themeTextSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.submittedOn,
                      style: AppTypography.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    Text(
                      createdAt != null
                          ? DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(createdAt.toDate())
                          : '-',
                      style: AppTypography.bodySmall().copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.store_rounded,
                size: 14,
                color: context.themeTextSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.store,
                      style: AppTypography.bodySmall().copyWith(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    Text(
                      storeName,
                      style: AppTypography.bodySmall().copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarpenterCard(BuildContext context) {
    if (_carpenterData == null) {
      return Container();
    }

    final firstName = _carpenterData!['firstName'] as String? ?? '';
    final lastName = _carpenterData!['lastName'] as String? ?? '';
    final phone = _carpenterData!['phone'] as String? ?? '';
    final tier = _carpenterData!['tier'] as String? ?? 'Bronze';
    final totalPoints = (_carpenterData!['totalPoints'] ?? 0) as num;
    final profileImage = _carpenterData!['profileImage'] as String? ?? '';

    Color getTierColor(String tierName) {
      switch (tierName.toLowerCase()) {
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

    return Container(
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: context.themeContentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.carpenterInfo,
                    style: AppTypography.labelLarge().copyWith(fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/carpenter-profile/${_billData!['carpenterId']}',
                  );
                },
                icon: const Icon(Icons.person_rounded, size: 14),
                label: Text(AppLocalizations.of(context)!.viewProfile),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  foregroundColor: context.themeOnPrimary,
                  backgroundColor: context.themePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: profileImage.isNotEmpty
                    ? Image.network(
                        profileImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: context.themeBackground,
                          child: Icon(
                            Icons.person_rounded,
                            size: 26,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: context.themeBackground,
                        child: Icon(
                          Icons.person_rounded,
                          size: 26,
                          color: context.themeTextSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: AppTypography.labelLarge().copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 10,
                          color: context.themeTextSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          phone,
                          style: AppTypography.bodySmall().copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getTierColor(tier),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            tier,
                            style: AppTypography.labelSmall().copyWith(
                              fontSize: 12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 10,
                          color: context.themeContentColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.pts3('${totalPoints.toStringAsFixed(0)}'),
                          style: AppTypography.bodySmall().copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(BuildContext context) {
    final amount = (_billData!['amount'] ?? 0) as num;
    final points = (amount / 1000).toStringAsFixed(2);
    final billDate = _billData!['billDate'] as Timestamp?;
    final billNumber = _billData!['billNumber'] as String? ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_rounded,
                size: 20,
                color: context.themeContentColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.billSummary,
                style: AppTypography.labelLarge().copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.currency_rupee_rounded,
                        size: 24,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.billAmount3,
                        style: AppTypography.bodySmall().copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.themeContentColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 24,
                        color: context.themeContentColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        points,
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 16,
                          color: context.themeContentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.pointsToCredit,
                        style: AppTypography.bodySmall().copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: context.themeContentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.billDateLabel,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          Text(
                            billDate != null
                                ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(billDate.toDate())
                                : '-',
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color: context.themeContentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.billNo,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          Text(
                            billNumber,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.percent_rounded,
                      size: 14,
                      color: context.themeContentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.pointsRate,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.t1Pt1000,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 14,
                      color: context.themeContentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.billType,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.purchase,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context) {
    final imageUrl = _billData!['imageUrl'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file_rounded,
                size: 20,
                color: context.themeContentColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.billAttachment2,
                style: AppTypography.labelLarge().copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _viewFullImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: context.themeBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.search_rounded,
              color: context.themeContentColor,
            ),
            title: Text(
              AppLocalizations.of(context)!.viewFullSize,
              style: AppTypography.bodySmall(),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.themeTextSecondary,
              size: 18,
            ),
            onTap: _viewFullImage,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.download_rounded,
              color: context.themeContentColor,
            ),
            title: Text(
              AppLocalizations.of(context)!.downloadImage,
              style: AppTypography.bodySmall(),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.themeTextSecondary,
              size: 18,
            ),
            onTap: () {},
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.picture_as_pdf_rounded,
              color: context.themeContentColor,
            ),
            title: Text(
              AppLocalizations.of(context)!.generatePdf,
              style: AppTypography.bodySmall(),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: context.themeTextSecondary,
              size: 18,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    final status = _billData!['status'] as String? ?? 'pending';
    final createdAt = _billData!['createdAt'] as Timestamp?;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20,
                color: context.themeContentColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.timeline,
                style: AppTypography.labelLarge().copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            context,
            AppLocalizations.of(context)!.billCreated,
            createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
                : '-',
            true,
            true,
          ),
          _buildTimelineItem(
            context,
            AppLocalizations.of(context)!.submittedLabel,
            createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
                : '-',
            true,
            true,
          ),
          _buildTimelineItem(
            context,
            AppLocalizations.of(context)!.waitingForApproval,
            AppLocalizations.of(context)!.pendingActionFromAdmin,
            status == 'pending',
            status == 'pending',
          ),
          _buildTimelineItem(
            context,
            AppLocalizations.of(context)!.approvedLabel,
            '--',
            status == 'approved',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String subtitle,
    bool isActive,
    bool isCompleted,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : (isActive ? AppColors.warning : context.themeBackground),
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : (isActive ? AppColors.warning : context.themeBorder),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AppColors.white,
                    )
                  : (isActive
                        ? const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppColors.white,
                          )
                        : null),
            ),
            if (title != 'Approved')
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.success
                    : (isActive ? AppColors.warning : context.themeBorder),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium().copyWith(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall().copyWith(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _rejectBill,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.rejectBill),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _approveBill,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(AppLocalizations.of(context)!.approveBillAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow2;
    } else if (diff.inMinutes < 60) {
      return AppLocalizations.of(context)!.minAgo('${diff.inMinutes}');
    } else if (diff.inHours < 24) {
      return AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    } else {
      return AppLocalizations.of(context)!.daysAgo(diff.inDays);
    }
  }
}
