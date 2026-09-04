class MediaFormats {
  static const Set<String> videoExtensions = {'mp4', 'webm'};

  static const Set<String> imageExtensions = {'jpg', 'jpeg', 'gif', 'png', 'webp'};

  static bool isVideoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final clean = url.split('?').first.toLowerCase();
    final dotIndex = clean.lastIndexOf('.');
    if (dotIndex == -1) return false;
    final extension = clean.substring(dotIndex + 1);
    return videoExtensions.contains(extension);
  }

  static bool isVideoExtension(String extension) {
    final clean = _clean(extension);
    return videoExtensions.contains(clean);
  }

  static bool isImageExtension(String extension) {
    final clean = _clean(extension);
    return imageExtensions.contains(clean);
  }

  static String _clean(String extension) {
    var ext = extension.trim().toLowerCase();
    if (ext.startsWith('.')) ext = ext.substring(1);
    return ext;
  }
}
