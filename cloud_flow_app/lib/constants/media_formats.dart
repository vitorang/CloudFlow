class MediaFormats {
  static const Set<String> videoExtensions = {'mp4', 'webm'};

  static const Set<String> imageExtensions = {'jpg', 'jpeg', 'gif', 'png', 'webp'};

  static String _extractExtension(String pathOrUrl) {
    return pathOrUrl.split('?').first.trim().split('.').last.toLowerCase();
  }

  static bool isVideoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return videoExtensions.contains(_extractExtension(url));
  }

  static bool isImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return imageExtensions.contains(_extractExtension(url));
  }

  static bool isVideoExtension(String extension) {
    return videoExtensions.contains(_extractExtension(extension));
  }

  static bool isImageExtension(String extension) {
    return imageExtensions.contains(_extractExtension(extension));
  }
}
