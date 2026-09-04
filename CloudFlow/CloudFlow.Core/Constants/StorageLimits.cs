namespace CloudFlow.Core.Constants;

public static class StorageLimits
{
    public const string TempFolderPrefix = "temp/";
    public const string MessagesFolderPrefix = "messages/";
    public const string FileSuffix = "file";
    public const string ThumbnailSuffix = "thumbnail";
    public const string ThumbnailExtension = "webp";
    public const int ThumbnailMaxWidthPx = 355;
    public const int ThumbnailMaxHeightPx = 200;
    public const long MaxAttachmentSizeBytes = 10 * 1024 * 1024;
    public const long MaxThumbnailSizeBytes = 200 * 1024;
    public static readonly TimeSpan UploadUrlExpiration = TimeSpan.FromMinutes(15);
    public static readonly TimeSpan DownloadUrlExpiration = TimeSpan.FromDays(7);
}
