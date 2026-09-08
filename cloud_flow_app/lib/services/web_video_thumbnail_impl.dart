import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List?> generateWebVideoThumbnail({
  required Uint8List bytes,
  required String fileExtension,
  required int maxWidth,
  required int maxHeight,
}) async {
  final mimeType = fileExtension == 'webm' ? 'video/webm' : 'video/mp4';
  final blobParts = [bytes.toJS].toJS;
  final blobOptions = web.BlobPropertyBag(type: mimeType);
  final blob = web.Blob(blobParts, blobOptions);
  final objectUrl = web.URL.createObjectURL(blob);

  final video = web.document.createElement('video') as web.HTMLVideoElement;
  video.preload = 'metadata';
  video.src = objectUrl;
  video.muted = true;
  video.playsInline = true;

  final completer = Completer<Uint8List?>();

  void cleanup() {
    web.URL.revokeObjectURL(objectUrl);
    video.remove();
  }

  video.onloadeddata = (web.Event _) {
    video.currentTime = 0.001;
  }.toJS;

  video.onseeked = (web.Event _) {
    try {
      final originalWidth = video.videoWidth > 0 ? video.videoWidth : 355;
      final originalHeight = video.videoHeight > 0 ? video.videoHeight : 200;

      final widthRatio = maxWidth / originalWidth;
      final heightRatio = maxHeight / originalHeight;
      final scale = min(widthRatio, heightRatio);

      final targetWidth = (originalWidth * min(1.0, scale)).round();
      final targetHeight = (originalHeight * min(1.0, scale)).round();

      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = targetWidth;
      canvas.height = targetHeight;

      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      context.drawImage(video, 0, 0, targetWidth.toDouble(), targetHeight.toDouble());

      final dataUrl = canvas.toDataURL('image/webp', 0.85.toJS);
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64String = dataUrl.substring(commaIndex + 1);
        final imageBytes = base64Decode(base64String);
        cleanup();
        if (!completer.isCompleted) completer.complete(imageBytes);
        return;
      }

      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    } catch (_) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
    }
  }.toJS;

  video.onerror = (web.Event _) {
    cleanup();
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;

  Future.delayed(const Duration(seconds: 4), () {
    if (!completer.isCompleted) {
      cleanup();
      completer.complete(null);
    }
  });

  return completer.future;
}
