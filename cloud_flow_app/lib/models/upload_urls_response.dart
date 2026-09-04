class AttachmentUpload {
  final String key;
  final String uploadUrl;
  final Map<String, String> formFields;
  final int maxSizeBytes;

  const AttachmentUpload({
    required this.key,
    required this.uploadUrl,
    required this.formFields,
    required this.maxSizeBytes,
  });

  factory AttachmentUpload.fromJson(Map<String, dynamic> json) {
    final rawFields = json['formFields'] as Map<String, dynamic>? ?? {};
    return AttachmentUpload(
      key: json['key'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      formFields: rawFields.map((k, v) => MapEntry(k, v.toString())),
      maxSizeBytes: (json['maxSizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class ThumbnailUpload {
  final String key;
  final String uploadUrl;
  final Map<String, String> formFields;
  final int maxSizeBytes;
  final int maxWidthPx;
  final int maxHeightPx;

  const ThumbnailUpload({
    required this.key,
    required this.uploadUrl,
    required this.formFields,
    required this.maxSizeBytes,
    required this.maxWidthPx,
    required this.maxHeightPx,
  });

  factory ThumbnailUpload.fromJson(Map<String, dynamic> json) {
    final rawFields = json['formFields'] as Map<String, dynamic>? ?? {};
    return ThumbnailUpload(
      key: json['key'] as String? ?? '',
      uploadUrl: json['uploadUrl'] as String? ?? '',
      formFields: rawFields.map((k, v) => MapEntry(k, v.toString())),
      maxSizeBytes: (json['maxSizeBytes'] as num?)?.toInt() ?? 0,
      maxWidthPx: (json['maxWidthPx'] as num?)?.toInt() ?? 355,
      maxHeightPx: (json['maxHeightPx'] as num?)?.toInt() ?? 200,
    );
  }
}

class UploadUrlsResponse {
  final AttachmentUpload attachment;
  final ThumbnailUpload? thumbnail;

  const UploadUrlsResponse({
    required this.attachment,
    this.thumbnail,
  });

  factory UploadUrlsResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlsResponse(
      attachment: AttachmentUpload.fromJson(json['attachment'] as Map<String, dynamic>? ?? {}),
      thumbnail: json['thumbnail'] != null
          ? ThumbnailUpload.fromJson(json['thumbnail'] as Map<String, dynamic>)
          : null,
    );
  }
}
