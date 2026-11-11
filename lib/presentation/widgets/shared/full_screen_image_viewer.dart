import 'package:balaji_points/services/telemetry/telemetry.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens [imageUrl] over the whole screen, including the bottom navigation.
Future<void> showFullScreenImage(BuildContext context, String imageUrl) {
  Telemetry.imageOpened();
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
    ),
  );
}

/// Pinch or double-tap to zoom, drag to move, close button or Back to leave.
class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final _transform = TransformationController();
  Offset _lastDoubleTap = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    const scale = _doubleTapScale;
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        -_lastDoubleTap.dx * (scale - 1),
        -_lastDoubleTap.dy * (scale - 1),
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTapDown: (details) =>
                  _lastDoubleTap = details.localPosition,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _transform,
                maxScale: _maxScale,
                child: SizedBox.expand(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final total = progress.expectedTotalBytes;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          value: total == null
                              ? null
                              : progress.cumulativeBytesLoaded / total,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_rounded,
                            size: 56,
                            color: AppColors.onPrimaryMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.failedToLoadImage,
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    key: const ValueKey('image-viewer-close'),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 28),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.black.withValues(alpha: 0.55),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
