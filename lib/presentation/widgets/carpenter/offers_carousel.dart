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
          height: 220,
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
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.forCard,
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.3),
            blurRadius: 10.0,
            offset: Offset(0, 4.0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.forCard,
        child: Stack(
          children: [
            if (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  offer.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(color: const Color(0xFFBA68C8));
                  },
                ),
              )
            else
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8E24AA),
                        const Color(0xFFBA68C8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
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
                  if (offer.title.isNotEmpty && offer.description.isNotEmpty)
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
                      (offer.title.isNotEmpty || offer.description.isNotEmpty))
                    const SizedBox(height: AppSpacing.md),
                  if (offer.actionText.isNotEmpty)
                    InkWell(
                      onTap: () {
                        if (offer.imageUrl != null &&
                            offer.imageUrl!.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.forCard,
                                ),
                                child: ClipRRect(
                                  borderRadius: AppRadius.forCard,
                                  child: Image.network(
                                    offer.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.grey200,
                                        height: 220.0,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 40.0,
                                            color: AppColors.grey500,
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
                      },
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            20.0,
                          ),
                        ),
                        child: Text(
                          offer.actionText,
                          style: AppTypography.buttonMedium().copyWith(
                            color: const Color(0xFF7B1FA2),
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24.0 : AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: BoxDecoration(
        color: isActive ? AppColors.lightSecondary : AppColors.grey300,
        borderRadius: BorderRadius.circular(4),
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
