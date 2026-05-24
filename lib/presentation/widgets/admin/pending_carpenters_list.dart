import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
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
      backgroundColor: AppColors.woodenBackground,
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
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTypography.bodyMedium().copyWith(color: AppColors.red),
              ),
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
                    color: AppColors.lightPrimary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Requests',
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 18,
                      color: AppColors.lightPrimary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All carpenters have been verified',
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: AppColors.lightPrimary.withOpacity(0.5),
                    ),
                  ),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
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
                          color: AppColors.lightPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 18,
                              color: AppColors.lightPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName',
                              style: AppTypography.labelLarge().copyWith(
                                fontSize: 16,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: AppColors.lightPrimary.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: AppTypography.bodyMedium().copyWith(
                                    fontSize: 13,
                                    color: AppColors.lightPrimary.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
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
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Pending',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
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
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Reject',
                              style: AppTypography.labelLarge().copyWith(
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
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
                              backgroundColor: AppColors.lightSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                : Text(
                                    'Approve',
                                    style: AppTypography.labelLarge().copyWith(
                                      fontSize: 14,
                                      color: AppColors.white,
                                    ),
                                  ),
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
        Icon(icon, size: 16, color: AppColors.lightPrimary.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall().copyWith(
            fontSize: 13,
            color: AppColors.lightPrimary.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelLarge().copyWith(
              fontSize: 13,
              color: AppColors.lightPrimary,
            ),
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Approve Carpenter',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: AppColors.lightPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to approve $userName?\n\nThis will create a verified user account.',
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 16,
            color: AppColors.lightPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.lightPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Approve',
              style: AppTypography.labelLarge().copyWith(color: AppColors.white),
            ),
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
            backgroundColor: AppColors.red,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reject Carpenter',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: Colors.red.shade700,
          ),
        ),
        content: Text(
          'Are you sure you want to reject $userName?\n\nThis action cannot be undone.',
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 16,
            color: AppColors.lightPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge().copyWith(
                color: AppColors.lightPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Reject',
              style: AppTypography.labelLarge().copyWith(color: AppColors.white),
            ),
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
            backgroundColor: AppColors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error rejecting user', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting user: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}
