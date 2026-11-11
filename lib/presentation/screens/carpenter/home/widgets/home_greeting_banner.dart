import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/models/greeting_model.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class HomeGreetingBanner extends StatefulWidget {
  final GreetingItem greeting;
  final VoidCallback onDismiss;

  const HomeGreetingBanner({
    super.key,
    required this.greeting,
    required this.onDismiss,
  });

  @override
  State<HomeGreetingBanner> createState() => _HomeGreetingBannerState();
}

class _HomeGreetingBannerState extends State<HomeGreetingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _expanded = false;

  /// Lines shown before a long greeting needs "Read more".
  static const int _collapsedLines = 4;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.greeting.imageUrl != null &&
        widget.greeting.imageUrl!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position:
          Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: const Offset(0, 0),
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOut,
            ),
          ),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Padding(
          // Same 16 px sides as every other Home card.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.forCard,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: context.themePrimary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.forCard,
              child: hasImage
                  ? _buildWithImage(context, isDark)
                  : _buildTextOnly(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = widget.greeting.message;
    final isLong =
        message.length > 140 ||
        '\n'.allMatches(message).length >= _collapsedLines;
    final collapse = isLong && !_expanded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.body(
          message,
          color: context.themeTextPrimary,
          maxLines: collapse ? _collapsedLines : null,
          overflow: collapse ? TextOverflow.ellipsis : null,
        ),
        if (isLong)
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? l10n.showLess : l10n.readMore),
          ),
      ],
    );
  }

  Widget _buildWithImage(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero image with overlay
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              color: AppColors.textMuted.withValues(alpha: 0.1),
              child: Image.network(
                widget.greeting.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                      color: context.themePrimary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.themePrimary.withValues(alpha: 0.08),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: context.themeTextSecondary,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          AppText.labelSmall(
                            AppLocalizations.of(context)!.failedToLoadImage,
                            color: context.themeTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Close button overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _handleDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Message section
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.themePrimary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.md12,
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: context.themePrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelSmall(
                          AppLocalizations.of(context)!.newAnnouncement,
                          color: context.themePrimary,
                        ),
                        const SizedBox(height: 4),
                        _buildMessage(context),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextOnly(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.themePrimary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.md12,
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: context.themePrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.labelSmall(
                      AppLocalizations.of(context)!.newAnnouncement,
                      color: context.themePrimary,
                    ),
                    const SizedBox(height: 8),
                    _buildMessage(context),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: context.themeTextSecondary,
                  size: 22,
                ),
                onPressed: _handleDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
