import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/user/user_service.dart';
import '../../../core/logger.dart';

class PendingCarpentersList extends StatefulWidget {
  const PendingCarpentersList({super.key});

  @override
  State<PendingCarpentersList> createState() => _PendingCarpentersListState();
}

class _PendingCarpentersListState extends State<PendingCarpentersList> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pending_users')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: AppText.body('Error: ${snapshot.error}', color: context.themeError),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 64,
                    color: context.themePrimary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  AppText.label('No Pending Requests'),
                  const SizedBox(height: 8),
                  AppText.body('All carpenters have been verified', color: context.themeTextSecondary),
                ],
              ),
            );
          }

          final pendingUsers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final doc = pendingUsers[index];
              final data = doc.data() as Map<String, dynamic>;
              final phone = doc.id;
              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final city = data['city'] ?? 'N/A';
              final skill = data['skill'] ?? 'N/A';
              final referral = data['referral'] ?? 'N/A';
              final createdAt = data['createdAt'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: AppRadius.all16,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  title: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: context.themePrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: AppText.label(
                            '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.label('$firstName $lastName'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: context.themePrimary.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AppText.body(phone, color: context.themeTextSecondary),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: AppRadius.md12,
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: AppText.label('Pending'),
                      ),
                    ],
                  ),
                  children: [
                    // Details
                    _buildDetailRow(Icons.location_city, 'City', city),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.build, 'Skill', skill),
                    if (referral != 'N/A') ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.card_giftcard,
                        'Referral',
                        referral,
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Requested',
                        _formatDate(createdAt.toDate()),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _rejectUser(
                                    phone,
                                    '$firstName $lastName',
                                  ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.themeError),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md12,
                              ),
                            ),
                            child: AppText.label('Reject', color: context.themeError),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _approveUser(
                                    doc.id,
                                    data,
                                    '$firstName $lastName',
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.themeSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.md12,
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  )
                                : AppText.label('Approve', color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.themePrimary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        AppText.bodySmall('$label: ', color: context.themeTextSecondary),
        Expanded(child: AppText.label(value)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _approveUser(
    String phone,
    Map<String, dynamic> data,
    String userName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.label('Approve Carpenter'),
        content: AppText.body(
          'Are you sure you want to approve $userName?\n\nThis will create a verified user account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.md12,
              ),
            ),
            child: AppText.label('Approve', color: AppColors.white),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Note: In production, you'd create Firebase Auth user first
      // For now, we'll mark as approved and admin will need to ensure Firebase Auth account exists
      await FirebaseFirestore.instance
          .collection('pending_users')
          .doc(phone)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'admin', // TODO: Get actual admin UID
          });

      // Create verified user in users collection
      // Generate a temporary UID (in production, use Firebase Auth UID)
      final tempUid = 'user_$phone';

      await _userService.createVerifiedUser(
        uid: tempUid,
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        phone: phone,
        city: data['city'],
        skill: data['skill'],
        referral: data['referral'],
        verifiedBy: 'admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      AppLogger.info('Carpenter approved: $phone');
    } catch (e) {
      AppLogger.error('Error approving user', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rejectUser(String phone, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.label('Reject Carpenter', color: context.themeError),
        content: AppText.body(
          'Are you sure you want to reject $userName?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: AppText.label('Cancel'),
          ),
          AppButton(
              label: "action",
              onPressed: () => Navigator.pop(context, true),
              variant: AppButtonVariant.danger,
              fullWidth: false,
            ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('pending_users')
          .doc(phone)
          .update({
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName rejected'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error rejecting user', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting user: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }
}
