import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

class CarpenterSelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedCarpenter;
  final Function(Map<String, dynamic>) onCarpenterSelected;

  const CarpenterSelectionWidget({
    super.key,
    this.selectedCarpenter,
    required this.onCarpenterSelected,
  });

  @override
  State<CarpenterSelectionWidget> createState() =>
      _CarpenterSelectionWidgetState();
}

class _CarpenterSelectionWidgetState extends State<CarpenterSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCarpenterSelectionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeContentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_search,
                        color: AppColors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.selectCarpenter,
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 20,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setDialogState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: AppTypography.bodyMedium().copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.searchByNameOrPhone,
                      hintStyle: AppTypography.bodyMedium().copyWith(
                        color: context.themeTextMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.themeContentColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setDialogState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: context.themeSoftSurface,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.md12,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Carpenters List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            l10n.errorLoadingCarpenters,
                            style: AppTypography.bodyMedium().copyWith(
                              color: context.themeError,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: context.themeContentColor,
                          ),
                        );
                      }

                      var carpenters = snapshot.data?.docs ?? [];

                      // Filter to show only carpenters (exclude admins)
                      carpenters = carpenters.where((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        final role = user['role'] as String?;
                        return role != 'admin' &&
                            (role == null ||
                                role.isEmpty ||
                                role == 'carpenter');
                      }).toList();

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        carpenters = carpenters.where((doc) {
                          final user = doc.data() as Map<String, dynamic>;
                          final firstName = (user['firstName'] ?? '')
                              .toString()
                              .toLowerCase();
                          final lastName = (user['lastName'] ?? '')
                              .toString()
                              .toLowerCase();
                          final phone = (user['phone'] ?? '')
                              .toString()
                              .toLowerCase();
                          final fullName = '$firstName $lastName'.trim();

                          return fullName.contains(_searchQuery) ||
                              phone.contains(_searchQuery);
                        }).toList();
                      }

                      if (carpenters.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: 64,
                                color: context.themeTextMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? l10n.noCarpentersFound
                                    : l10n.noCarpentersAvailable,
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 16,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: carpenters.length,
                        itemBuilder: (context, index) {
                          final doc = carpenters[index];
                          final user = doc.data() as Map<String, dynamic>;
                          final userId = doc.id;
                          final firstName = user['firstName'] ?? '';
                          final lastName = user['lastName'] ?? '';
                          final name = ('$firstName $lastName').trim().isEmpty
                              ? 'Carpenter'
                              : ('$firstName $lastName').trim();
                          final phone = user['phone'] ?? '';
                          final profileImage = user['profileImage'] as String?;
                          final tier = user['tier'] ?? 'Bronze';
                          final rawPoints = user['totalPoints'];
                          final points = rawPoints is num ? rawPoints.toInt() : 0;

                          final isSelected =
                              widget.selectedCarpenter != null &&
                              widget.selectedCarpenter!['userId'] == userId;

                          return InkWell(
                            onTap: () {
                              widget.onCarpenterSelected({
                                'userId': userId,
                                'firstName': firstName,
                                'lastName': lastName,
                                'name': name,
                                'phone': phone,
                                'profileImage': profileImage,
                                'tier': tier,
                                'totalPoints': points,
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.themePrimary.withValues(
                                        alpha: 0.1,
                                      )
                                    : context.themeSurface,
                                borderRadius: AppRadius.md12,
                                border: Border.all(
                                  color: isSelected
                                      ? context.themePrimary
                                      : context.themeBorder,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Profile Image
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.themePrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: context.themePrimary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        profileImage != null &&
                                            profileImage.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              profileImage,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    Icons.person,
                                                    color: context
                                                        .themeContentColor,
                                                    size: 28,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: context.themeContentColor,
                                            size: 28,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name and Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText.label(name),
                                        const SizedBox(height: 4),
                                        Text(
                                          phone,
                                          style: AppTypography.bodyMedium()
                                              .copyWith(
                                                fontSize: 12,
                                                color:
                                                    context.themeTextSecondary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: context.themeContentColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius: AppRadius.sm8,
                                              ),
                                              child: Text(
                                                tier,
                                                style: AppTypography.labelLarge()
                                                    .copyWith(
                                                      fontSize: 10,
                                                      color: context
                                                          .themeContentColor,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$points pts',
                                              style: AppTypography.bodyMedium()
                                                  .copyWith(
                                                    fontSize: 11,
                                                    color: context
                                                        .themeTextSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: context.themeContentColor,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCarpenter = widget.selectedCarpenter;

    return InkWell(
      onTap: _showCarpenterSelectionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.themeSoftSurface,
          borderRadius: AppRadius.md12,
          border: Border.all(
            color: selectedCarpenter != null
                ? context.themePrimary
                : context.themePrimary.withValues(alpha: 0.3),
            width: selectedCarpenter != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: context.themeContentColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: selectedCarpenter != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.label(selectedCarpenter['name'] ?? 'Carpenter'),
                        const SizedBox(height: 2),
                        Text(
                          selectedCarpenter['phone'] ?? '',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      l10n.selectCarpenter,
                      style: AppTypography.bodyMedium().copyWith(
                        fontSize: 14,
                        color: context.themeTextSecondary,
                      ),
                    ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: context.themeContentColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
