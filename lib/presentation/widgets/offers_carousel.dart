import 'package:flutter/material.dart';
import 'package:balaji_points/core/theme/design_token.dart';

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
        const SizedBox(height: DesignToken.layoutCardGapTight),
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
        horizontal: DesignToken.layoutScreenPaddingX,
      ),
      decoration: BoxDecoration(
        borderRadius: DesignToken.borderRadiusLG,
        boxShadow: [
          BoxShadow(
            color: DesignToken.purpleShade500.withValues(alpha: 0.3),
            blurRadius: DesignToken.offerCarouselShadowBlur,
            offset: Offset(0, DesignToken.offerCarouselShadowDy),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: DesignToken.borderRadiusLG,
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
                    return ColoredBox(color: DesignToken.purpleShade300);
                  },
                ),
              )
            else
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignToken.purpleShade600,
                        DesignToken.purpleShade300,
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
                      DesignToken.black.withValues(alpha: 0.35),
                      DesignToken.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignToken.paddingXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.title.isNotEmpty)
                    Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignToken.textBold.copyWith(
                        color: DesignToken.white,
                        fontSize: DesignToken.fontSize3XL,
                      ),
                    ),
                  if (offer.title.isNotEmpty && offer.description.isNotEmpty)
                    const SizedBox(height: DesignToken.spacingSM),
                  if (offer.description.isNotEmpty)
                    Text(
                      offer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignToken.textRegular.copyWith(
                        color: DesignToken.white.withValues(alpha: 0.9),
                        fontSize: DesignToken.fontSizeLG,
                      ),
                    ),
                  if (offer.actionText.isNotEmpty &&
                      (offer.title.isNotEmpty || offer.description.isNotEmpty))
                    const SizedBox(height: DesignToken.spacingMD),
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
                                  borderRadius: DesignToken.borderRadiusLG,
                                ),
                                child: ClipRRect(
                                  borderRadius: DesignToken.borderRadiusLG,
                                  child: Image.network(
                                    offer.imageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: DesignToken.grey200,
                                        height: DesignToken
                                            .offerImageDialogFallbackMinHeight,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: DesignToken.iconSize2XL,
                                            color: DesignToken.grey500,
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
                      borderRadius: BorderRadius.circular(DesignToken.radiusXL),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignToken.paddingXL,
                          vertical: DesignToken.paddingSM + 2,
                        ),
                        decoration: BoxDecoration(
                          color: DesignToken.white,
                          borderRadius: BorderRadius.circular(
                            DesignToken.radiusXL,
                          ),
                        ),
                        child: Text(
                          offer.actionText,
                          style: DesignToken.textBold.copyWith(
                            color: DesignToken.purpleShade700,
                            fontSize: DesignToken.fontSizeMD,
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
      margin: const EdgeInsets.symmetric(horizontal: DesignToken.spacingXS),
      width: isActive ? DesignToken.width2XL : DesignToken.spacingSM,
      height: DesignToken.spacingSM,
      decoration: BoxDecoration(
        color: isActive ? DesignToken.secondary : DesignToken.grey300,
        borderRadius: DesignToken.borderRadiusXS,
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
      ..color = DesignToken.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(size.width * 0.2 * (i + 1), size.height * 0.3 * (j + 1)),
          DesignToken.iconSizeMD,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
