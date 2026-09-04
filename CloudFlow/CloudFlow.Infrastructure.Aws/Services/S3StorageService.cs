using Amazon.S3;
using Amazon.S3.Model;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Configuration;

namespace CloudFlow.Infrastructure.Aws.Services;

public class S3StorageService(IAmazonS3 s3Client, AwsOptions awsOptions) : IStorageService
{
    public async Task<UploadUrlsResponseDto> GenerateUploadUrls(GenerateUploadUrlsDto dto, CancellationToken cancellationToken)
    {
        var rawExtension = dto.FileExtension.Trim();
        var normalizedExtension = (rawExtension.StartsWith('.') ? rawExtension[1..] : rawExtension).ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(normalizedExtension))
            throw new ArgumentException("A extensão do arquivo é obrigatória.");

        var fileId = Ulid.NewUlid().ToString();
        var fileKey = BuildFileKey(StorageLimits.TempFolderPrefix, fileId, normalizedExtension);
        var attachmentPost = await CreatePresignedPost(fileKey, StorageLimits.MaxAttachmentSizeBytes);
        var attachmentUpload = new AttachmentUploadDto(
            Key: fileKey,
            UploadUrl: attachmentPost.Url,
            FormFields: attachmentPost.Fields,
            MaxSizeBytes: StorageLimits.MaxAttachmentSizeBytes
        );

        ThumbnailUploadDto? thumbnailUpload = null;
        if (dto.HasThumbnail)
        {
            var thumbnailKey = BuildFileKey(StorageLimits.TempFolderPrefix, fileId, StorageLimits.ThumbnailExtension, isThumbnail: true);
            var thumbnailPost = await CreatePresignedPost(thumbnailKey, StorageLimits.MaxThumbnailSizeBytes);

            thumbnailUpload = new ThumbnailUploadDto(
                Key: thumbnailKey,
                UploadUrl: thumbnailPost.Url,
                FormFields: thumbnailPost.Fields,
                MaxSizeBytes: StorageLimits.MaxThumbnailSizeBytes,
                MaxWidthPx: StorageLimits.ThumbnailMaxWidthPx,
                MaxHeightPx: StorageLimits.ThumbnailMaxHeightPx
            );
        }

        var responseDto = new UploadUrlsResponseDto(
            Attachment: attachmentUpload,
            Thumbnail: thumbnailUpload
        );

        return responseDto;
    }

    private static string BuildFileKey(string folderPrefix, string fileId, string extension, bool isThumbnail = false)
    {
        var suffix = isThumbnail ? StorageLimits.ThumbnailSuffix : StorageLimits.FileSuffix;
        return $"{folderPrefix}{fileId}_{suffix}.{extension}";
    }

    private async Task<CreatePresignedPostResponse> CreatePresignedPost(string key, long maxSizeBytes)
    {
        var request = new CreatePresignedPostRequest
        {
            BucketName = awsOptions.S3.BucketName,
            Key = key,
            Expires = DateTime.UtcNow.Add(StorageLimits.UploadUrlExpiration)
        };

        request.Conditions.Add(S3PostCondition.ContentLengthRange(0, maxSizeBytes));

        return await s3Client.CreatePresignedPostAsync(request);
    }

    public async Task<string> MoveToMessages(string tempFileKey, CancellationToken cancellationToken)
    {
        if (!tempFileKey.StartsWith(StorageLimits.TempFolderPrefix))
            throw new ArgumentException($"A chave temporária deve iniciar com '{StorageLimits.TempFolderPrefix}'.");

        var fileName = tempFileKey[StorageLimits.TempFolderPrefix.Length..];
        var destinationKey = $"{StorageLimits.MessagesFolderPrefix}{fileName}";

        var copyRequest = new CopyObjectRequest
        {
            SourceBucket = awsOptions.S3.BucketName,
            SourceKey = tempFileKey,
            DestinationBucket = awsOptions.S3.BucketName,
            DestinationKey = destinationKey
        };
        await s3Client.CopyObjectAsync(copyRequest, cancellationToken);

        var deleteRequest = new DeleteObjectRequest
        {
            BucketName = awsOptions.S3.BucketName,
            Key = tempFileKey
        };
        await s3Client.DeleteObjectAsync(deleteRequest, cancellationToken);

        return destinationKey;
    }

    public async Task DeleteMany(IReadOnlyList<string> fileKeys, CancellationToken cancellationToken)
    {
        var validKeys = fileKeys.Where(key => !string.IsNullOrWhiteSpace(key)).Distinct().ToList();
        if (validKeys.Count == 0)
            return;

        var deleteObjectsRequest = new DeleteObjectsRequest
        {
            BucketName = awsOptions.S3.BucketName,
            Objects = [.. validKeys.Select(key => new KeyVersion { Key = key })]
        };

        await s3Client.DeleteObjectsAsync(deleteObjectsRequest, cancellationToken);
    }

    public string? GetDownloadUrl(string? fileKey)
    {
        if (string.IsNullOrWhiteSpace(fileKey))
            return null;

        var presignedUrlRequest = new GetPreSignedUrlRequest
        {
            BucketName = awsOptions.S3.BucketName,
            Key = fileKey,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.Add(StorageLimits.DownloadUrlExpiration)
        };

        return s3Client.GetPreSignedURL(presignedUrlRequest);
    }
}
