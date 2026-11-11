import 'dart:async';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One offer as shown to members.
class OfferItem {
  const OfferItem({
    this.id = '',
    required this.title,
    required this.description,
    this.imageUrl,
    this.pointsTarget = 0,
    this.validUntil,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  /// Points a member needs for this offer; 0 when the offer has no target.
  final double pointsTarget;
  final DateTime? validUntil;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// A greeting-style offer stored with 1 point has no real target.
  bool get hasTarget => pointsTarget > 1;
}

/// Home offers: banners that slide by themselves in an endless loop, with the
/// next card peeking in from the side. Each card has an ⓘ button with the
/// full offer details and the member's progress towards its points target.
class OffersCarousel extends StatefulWidget {
  const OffersCarousel({
    super.key,
    required this.offers,
    this.myPoints = 0,
    this.autoPlayInterval = const Duration(seconds: 4),
  });

  final List<OfferItem> offers;
  final double myPoints;
  final Duration autoPlayInterval;

  /// Banners are designed at 1280 × 714.
  static const double bannerAspect = 1280 / 714;
  static const double _infoBarHeight = 64;

  /// The centre card lines up with every other Home card: 16 px from each
  /// side. Cards are [cardGap] apart, so the neighbours peek in slightly.
  static const double sideMargin = 16;
  static const double cardGap = 12;

  static double viewportFractionFor(double width) => width <= 0
      ? 1
      : ((width - 2 * sideMargin + cardGap) / width).clamp(0.5, 1);

  /// Total height of the carousel (cards only) for a given width, so the
  /// loading placeholder can take exactly the same space.
  static double cardHeightFor(double width) =>
      (width - 2 * sideMargin) / bannerAspect + _infoBarHeight;

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel>
    with WidgetsBindingObserver {
  // Starting far from page 0 lets the user swipe backwards forever too.
  static const int _loopBase = 10000;

  late PageController _controller;
  Timer? _timer;
  Timer? _resumeTimer;
  int _page = 0;
  bool _userTouching = false;

  int get _count => widget.offers.length;
  bool get _loops => _count > 1;
  int _realIndex(int page) => _count == 0 ? 0 : page % _count;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = _loops ? _loopBase * _count : 0;
    _controller = PageController(
      initialPage: _page,
      viewportFraction: _fraction,
    );
    _startAutoPlay();
  }

  double _fraction = 0.92;

  /// Rebuilds the page controller when the available width changes (e.g.
  /// rotation), keeping the current offer.
  void _fitTo(double width) {
    final f = OffersCarousel.viewportFractionFor(width);
    if ((f - _fraction).abs() < 0.0005) return;
    _fraction = f;
    final old = _controller;
    _controller = PageController(initialPage: _page, viewportFraction: f);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void didUpdateWidget(covariant OffersCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      // The list changed size: restart from the first offer.
      _timer?.cancel();
      _controller.dispose();
      _page = _loops ? _loopBase * _count : 0;
      _controller = PageController(
        initialPage: _page,
        viewportFraction: _fraction,
      );
      _startAutoPlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No sliding while the app is in the background.
    if (state == AppLifecycleState.resumed) {
      _startAutoPlay();
    } else {
      _timer?.cancel();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (!_loops) return;
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || _userTouching || !_controller.hasClients) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// A swipe pauses the loop; it starts again a few seconds after.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userTouching = true;
      _resumeTimer?.cancel();
    } else if (n is ScrollEndNotification && _userTouching) {
      _resumeTimer?.cancel();
      _resumeTimer = Timer(const Duration(seconds: 5), () {
        _userTouching = false;
      });
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        _fitTo(width);
        return _buildCarousel(context, width);
      },
    );
  }

  Widget _buildCarousel(BuildContext context, double width) {
    final height = OffersCarousel.cardHeightFor(width);
    final current = _realIndex(_page);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              // A single offer fills the width and doesn't slide.
              itemCount: _loops ? null : 1,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, page) {
                final offer = widget.offers[_realIndex(page)];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Cards beside the centre one shrink and fade slightly.
                    var distance = 0.0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      distance = ((_controller.page ?? _page.toDouble()) - page)
                          .abs()
                          .clamp(0.0, 1.0);
                    } else {
                      distance = page == _page ? 0 : 1;
                    }
                    return Transform.scale(
                      scale: 1 - distance * 0.07,
                      child: Opacity(
                        opacity: 1 - distance * 0.35,
                        child: child,
                      ),
                    );
                  },
                  child: _OfferCard(
                    offer: offer,
                    onInfo: () => showOfferDetails(
                      context,
                      offer,
                      myPoints: widget.myPoints,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_loops) ...[
          const SizedBox(height: AppSpacing.sm),
          _Indicator(count: _count, index: current),
        ],
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onInfo});

  final OfferItem offer;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OffersCarousel.cardGap / 2,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: AppRadius.forCard,
          border: Border.all(color: context.themeBorder),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.forCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: OffersCarousel.bannerAspect,
                child: offer.hasImage
                    ? _Banner(offer: offer)
                    : _PlainBanner(offer: offer),
              ),
              SizedBox(
                height: OffersCarousel._infoBarHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              offer.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelLarge(
                                color: context.themeTextPrimary,
                              ),
                            ),
                            if (offer.hasTarget) ...[
                              const SizedBox(height: 3),
                              _TargetChip(points: offer.pointsTarget),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onInfo,
                        tooltip: l10n.offerInfo,
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.offer});

  final OfferItem offer;

  @override
  Widget build(BuildContext context) {
    final px =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return Material(
      color: context.themeSoftSurface,
      child: InkWell(
        onTap: () => showFullScreenImage(context, offer.imageUrl!),
        child: Image.network(
          offer.imageUrl!,
          fit: BoxFit.cover,
          cacheWidth: px,
          // Fades in instead of popping, and keeps the old image while the
          // next one loads.
          frameBuilder: (context, child, frame, sync) => sync
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: child,
                ),
          errorBuilder: (context, error, stackTrace) =>
              _PlainBanner(offer: offer),
        ),
      ),
    );
  }
}

/// An offer with no banner image: navy card with the title.
class _PlainBanner extends StatelessWidget {
  const _PlainBanner({required this.offer});

  final OfferItem offer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.gold,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              offer.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.points});

  final double points;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_rounded, size: 14, color: AppColors.gold),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${AppLocalizations.of(context)!.offerPointsTarget}: '
            '${_formatTarget(points)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall(color: context.themeTextSecondary),
          ),
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == index ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == index ? AppColors.gold : context.themeBorderStrong,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

String _formatTarget(double points) =>
    NumberFormat.decimalPattern('en_IN').format(points.round());

/// The ⓘ sheet: banner, points target, the member's progress, full text.
Future<void> showOfferDetails(
  BuildContext context,
  OfferItem offer, {
  required double myPoints,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: context.themeCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _OfferDetailsSheet(offer: offer, myPoints: myPoints),
  );
}

class _OfferDetailsSheet extends StatelessWidget {
  const _OfferDetailsSheet({required this.offer, required this.myPoints});

  final OfferItem offer;
  final double myPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reached = offer.hasTarget && myPoints >= offer.pointsTarget;
    final progress = offer.hasTarget
        ? (myPoints / offer.pointsTarget).clamp(0.0, 1.0)
        : 0.0;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            l10n.offerDetails,
            style: AppTypography.labelMedium(color: context.themeTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            offer.title,
            style: AppTypography.title(color: context.themeTextPrimary),
          ),
          const SizedBox(height: 14),
          if (offer.hasImage)
            ClipRRect(
              borderRadius: AppRadius.all16,
              child: AspectRatio(
                aspectRatio: OffersCarousel.bannerAspect,
                child: Material(
                  color: context.themeSoftSurface,
                  child: InkWell(
                    onTap: () => showFullScreenImage(context, offer.imageUrl!),
                    child: Image.network(offer.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          if (offer.hasImage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showFullScreenImage(context, offer.imageUrl!),
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                label: Text(l10n.offerViewBanner),
              ),
            ),
          if (offer.hasTarget) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSoftSurface,
                borderRadius: AppRadius.all16,
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.offerPointsTarget,
                          style: AppTypography.labelLarge(
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTarget(offer.pointsTarget),
                        style: AppTypography.pointsSmall(
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        color: AppColors.gold,
                        backgroundColor: context.themeBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.offerProgress(
                      PointsUtils.formatPoints(myPoints),
                      _formatTarget(offer.pointsTarget),
                    ),
                    style: AppTypography.bodyMedium(
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reached
                        ? l10n.offerTargetReached
                        : l10n.offerPointsToGo(
                            PointsUtils.formatPoints(
                              offer.pointsTarget - myPoints,
                            ),
                          ),
                    style: AppTypography.labelMedium(
                      color: reached
                          ? AppColors.successText
                          : context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (offer.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SelectableText(
              offer.description.trim(),
              style: AppTypography.bodyLarge(
                color: context.themeTextPrimary,
              ).copyWith(height: 1.5),
            ),
          ],
          if (offer.validUntil != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 18,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.validUntil(
                    DateFormat('dd MMM yyyy').format(offer.validUntil!),
                  ),
                  style: AppTypography.bodyMedium(
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (offer.hasTarget) ...[
            const SizedBox(height: 16),
            Text(
              l10n.offerTermsApply,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
              ),
              child: Text(l10n.close),
            ),
          ),
        ],
      ),
    );
  }
}
