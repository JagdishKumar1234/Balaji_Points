import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';

class OffersCarousel extends StatefulWidget {
  final List<OfferItem> offers;

  const OffersCarousel({super.key, required this.offers});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(context, widget.offers[index]);
            },
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.offers.length,
            (index) => _buildDot(index == _currentPage),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferItem offer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: AppRadius.forCard,
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: 0.3),
            blurRadius: 10.0,
            offset: Offset(0, 4.0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.forCard,
        child: offer.imageUrl != null && offer.imageUrl!.isNotEmpty
            ? _buildImageOffer(context, offer)
            : Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.primary),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _OfferPatternPainter()),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.black.withValues(alpha: 0.35),
                            AppColors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (offer.title.isNotEmpty)
                          Text(
                            offer.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.buttonMedium().copyWith(
                              color: AppColors.white,
                              fontSize: 24.0,
                            ),
                          ),
                        if (offer.title.isNotEmpty &&
                            offer.description.isNotEmpty)
                          const SizedBox(height: AppSpacing.sm),
                        if (offer.description.isNotEmpty)
                          Text(
                            offer.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium().copyWith(
                              color: AppColors.white.withValues(alpha: 0.9),
                              fontSize: 16.0,
                            ),
                          ),
                        if (offer.actionText.isNotEmpty &&
                            (offer.title.isNotEmpty ||
                                offer.description.isNotEmpty))
                          const SizedBox(height: AppSpacing.md),
                        if (offer.actionText.isNotEmpty)
                          _buildAction(context, offer),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Banner images usually have their own text, so the title goes below the
  /// image rather than over it.
  Widget _buildImageOffer(BuildContext context, OfferItem offer) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _showFullImage(context, offer.imageUrl!),
            child: Image.network(
              offer.imageUrl!,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(color: AppColors.primaryLight);
              },
            ),
          ),
        ),
        ColoredBox(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (offer.title.isNotEmpty)
                        Text(
                          offer.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge(
                            color: colors.onSurface,
                          ),
                        ),
                      if (offer.description.isNotEmpty)
                        Text(
                          offer.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (offer.actionText.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _buildAction(
                    context,
                    offer,
                    background: context.themePrimary,
                    foreground: context.themeOnPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(
    BuildContext context,
    OfferItem offer, {
    Color background = AppColors.white,
    Color foreground = AppColors.primary,
  }) {
    return InkWell(
      onTap: () {
        if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty) {
          _showFullImage(context, offer.imageUrl!);
        }
      },
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          offer.actionText,
          style: AppTypography.buttonMedium().copyWith(
            color: foreground,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
          child: ClipRRect(
            borderRadius: AppRadius.forCard,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: context.themeBorder,
                  height: 220.0,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 40.0,
                      color: context.themeTextSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24.0 : AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: BoxDecoration(
        color: isActive ? context.themeSecondary : context.themeBorder,
        borderRadius: AppRadius.xs4,
      ),
    );
  }
}

class OfferItem {
  final String title;
  final String description;
  final String actionText;
  final String? imageUrl;

  OfferItem({
    required this.title,
    required this.description,
    required this.actionText,
    this.imageUrl,
  });
}

class _OfferPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(size.width * 0.2 * (i + 1), size.height * 0.3 * (j + 1)),
          20.0,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
