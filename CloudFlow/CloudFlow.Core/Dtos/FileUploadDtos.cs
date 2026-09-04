namespace CloudFlow.Core.Dtos;

public record GenerateUploadUrlsDto(
    string FileExtension,
    bool HasThumbnail = false
);

public record AttachmentUploadDto(
    string Key,
    string UploadUrl,
    IReadOnlyDictionary<string, string> FormFields,
    long MaxSizeBytes
);

public record ThumbnailUploadDto(
    string Key,
    string UploadUrl,
    IReadOnlyDictionary<string, string> FormFields,
    long MaxSizeBytes,
    int MaxWidthPx,
    int MaxHeightPx
);

public record UploadUrlsResponseDto(
    AttachmentUploadDto Attachment,
    ThumbnailUploadDto? Thumbnail = null
);
