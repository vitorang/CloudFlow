namespace CloudFlow.Core.Dtos;

public record GenerateUploadUrlsDto(
    string FileExtension,
    bool HasThumbnail = false
);

public record UploadTargetDto(
    string Key,
    string UploadUrl,
    long MaxSizeBytes
);

public record UploadUrlsResponseDto(
    UploadTargetDto File,
    UploadTargetDto? Thumbnail = null
);
