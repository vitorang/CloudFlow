import 'dart:math';
import 'package:cloud_flow_app/constants/media_formats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:image/image.dart' as img;

class ThumbnailService {
  bool canGenerateThumbnail(String fileExtension) {
    return isImage(fileExtension) || isVideo(fileExtension);
  }

  bool isImage(String fileExtension) {
    return MediaFormats.isImageExtension(fileExtension);
  }

  bool isVideo(String fileExtension) {
    return MediaFormats.isVideoExtension(fileExtension);
  }

  Future<Uint8List?> generateThumbnail({
    required Uint8List fileBytes,
    required String fileExtension,
    String? filePath,
    int maxWidth = 355,
    int maxHeight = 200,
    int quality = 85,
  }) async {
    final cleanExt = _cleanExtension(fileExtension);

    if (isImage(cleanExt)) {
      return _generateImageThumbnail(bytes: fileBytes, maxWidth: maxWidth, maxHeight: maxHeight);
    }

    if (isVideo(cleanExt)) {
      return _generateVideoThumbnail(filePath: filePath, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
    }

    return null;
  }

  Future<Uint8List?> _generateImageThumbnail({
    required Uint8List bytes,
    required int maxWidth,
    required int maxHeight,
  }) async {
    return compute((_) {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final originalWidth = decoded.width;
      final originalHeight = decoded.height;

      final widthRatio = maxWidth / originalWidth;
      final heightRatio = maxHeight / originalHeight;
      final scale = min(widthRatio, heightRatio);

      final targetWidth = (originalWidth * min(1.0, scale)).round();
      final targetHeight = (originalHeight * min(1.0, scale)).round();

      final resized = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );

      return Uint8List.fromList(img.encodeWebP(resized));
    }, null);
  }

  Future<Uint8List?> _generateVideoThumbnail({
    String? filePath,
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    if (filePath == null || filePath.isEmpty) return null;

    try {
      final rawBytes = await FlutterVideoThumbnailPlus.thumbnailData(
        video: filePath,
        imageFormat: ImageFormat.png,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        timeMs: 0,
        quality: quality,
      );

      if (rawBytes == null || rawBytes.isEmpty) return null;

      return _generateImageThumbnail(bytes: rawBytes, maxWidth: maxWidth, maxHeight: maxHeight);
    } catch (_) {
      return null;
    }
  }

  String _cleanExtension(String extension) {
    var ext = extension.trim().toLowerCase();
    if (ext.startsWith('.')) ext = ext.substring(1);
    return ext;
  }
}
