import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/logger.dart';

/// How hard to squeeze an image before it is uploaded.
class ImageCompressProfile {
  const ImageCompressProfile({
    required this.maxSide,
    required this.quality,
    required this.targetBytes,
    this.minQuality = 45,
  });

  /// Longest edge in pixels after resizing. Smaller images are not enlarged.
  final int maxSide;

  /// First JPEG quality tried (0-100).
  final int quality;

  /// Quality steps down until the file is at or under this size, but never
  /// below [minQuality], so the text on a bill stays readable.
  final int targetBytes;
  final int minQuality;

  /// Bill photos: shop names, amounts and dates must stay readable.
  static const bill = ImageCompressProfile(
    maxSide: 1600,
    quality: 72,
    targetBytes: 350 * 1024,
  );

  /// Profile photos are shown as small circles.
  static const profile = ImageCompressProfile(
    maxSide: 512,
    quality: 75,
    targetBytes: 80 * 1024,
  );

  /// Catalog cover thumbnails in lists.
  static const cover = ImageCompressProfile(
    maxSide: 480,
    quality: 72,
    targetBytes: 60 * 1024,
  );

  /// Greeting banners shown full width.
  static const banner = ImageCompressProfile(
    maxSide: 1280,
    quality: 75,
    targetBytes: 300 * 1024,
  );
}

/// Makes photos light before they go to Firebase Storage: resizes so the
/// longest edge is at most [ImageCompressProfile.maxSide], fixes camera
/// rotation, removes EXIF data (including GPS location) and saves as JPEG.
///
/// Never blocks an upload: if compression fails, or does not make the file
/// smaller, the original bytes are returned.
///
/// On web the native compressor is not available, so web uploads rely on
/// the image picker's own `maxWidth` / `imageQuality` resizing.
class ImageCompressService {
  const ImageCompressService._();

  static Future<Uint8List> compress(
    Uint8List input, {
    ImageCompressProfile profile = ImageCompressProfile.bill,
  }) async {
    if (kIsWeb || input.isEmpty) return input;
    try {
      final size = await _dimensions(input);
      final minSide = size == null
          ? profile.maxSide
          : targetShortSide(size.$1, size.$2, profile.maxSide);

      var quality = profile.quality;
      Uint8List best = input;
      while (true) {
        final out = await FlutterImageCompress.compressWithList(
          input,
          // Both set to the short-side target: the plugin scales so the
          // shorter edge reaches it, which works whichever way the photo
          // is rotated.
          minWidth: minSide,
          minHeight: minSide,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false,
        );
        if (out.isNotEmpty && out.length < best.length) best = out;
        if (out.length <= profile.targetBytes ||
            quality - 12 < profile.minQuality) {
          break;
        }
        quality -= 12;
      }
      AppLogger.info(
        'Image compressed ${_kb(input.length)} → ${_kb(best.length)} '
        '(q$quality, short side $minSide)',
      );
      return best;
    } catch (e) {
      AppLogger.warning('Image compression failed, uploading original: $e');
      return input;
    }
  }

  /// Short-edge size that makes the long edge [maxSide]; images already
  /// small enough keep their size.
  @visibleForTesting
  static int targetShortSide(int width, int height, int maxSide) {
    final long = width > height ? width : height;
    final short = width > height ? height : width;
    if (long <= maxSide || long == 0) return short;
    return (short * maxSide / long).round().clamp(1, maxSide);
  }

  /// Reads width and height from the file header without decoding pixels.
  static Future<(int, int)?> _dimensions(Uint8List bytes) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final size = (desc.width, desc.height);
      desc.dispose();
      buffer.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  static String _kb(int bytes) => '${(bytes / 1024).round()} KB';
}
