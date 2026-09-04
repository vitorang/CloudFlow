using Amazon.S3;
using Amazon.S3.Model;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Configuration;

namespace CloudFlow.Infrastructure.Aws.Services;

public class S3StorageService(IAmazonS3 s3Client, AwsOptions awsOptions) : IStorageService
{
    public Task<UploadUrlsResponseDto> GenerateUploadUrls(GenerateUploadUrlsDto dto, CancellationToken cancellationToken)
    {
        var rawExtension = dto.FileExtension.Trim();
        var normalizedExtension = (rawExtension.StartsWith('.') ? rawExtension[1..] : rawExtension).ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(normalizedExtension))
            throw new ArgumentException("A extensão do arquivo é obrigatória.");

        var fileId = Ulid.NewUlid().ToString();
        var fileKey = BuildFileKey(StorageLimits.TempFolderPrefix, fileId, normalizedExtension);
        var fileUploadUrl = CreatePresignedPutUrl(fileKey);

        var fileTarget = new UploadTargetDto(
            Key: fileKey,
            UploadUrl: fileUploadUrl,
            MaxSizeBytes: StorageLimits.MaxAttachmentSizeBytes
        );

        UploadTargetDto? thumbnailTarget = null;
        if (dto.HasThumbnail)
        {
            var thumbnailKey = BuildFileKey(StorageLimits.TempFolderPrefix, fileId, StorageLimits.ThumbnailExtension, isThumbnail: true);
            var thumbnailUploadUrl = CreatePresignedPutUrl(thumbnailKey);

            thumbnailTarget = new UploadTargetDto(
                Key: thumbnailKey,
                UploadUrl: thumbnailUploadUrl,
                MaxSizeBytes: StorageLimits.MaxThumbnailSizeBytes
            );
        }

        var responseDto = new UploadUrlsResponseDto(
            File: fileTarget,
            Thumbnail: thumbnailTarget
        );

        return Task.FromResult(responseDto);
    }

    private static string BuildFileKey(string folderPrefix, string fileId, string extension, bool isThumbnail = false)
    {
        var suffix = isThumbnail ? StorageLimits.ThumbnailSuffix : StorageLimits.FileSuffix;
        return $"{folderPrefix}{fileId}_{suffix}.{extension}";
    }

    private string CreatePresignedPutUrl(string key)
    {
        var presignedUrlRequest = new GetPreSignedUrlRequest
        {
            BucketName = awsOptions.S3.BucketName,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = DateTime.UtcNow.Add(StorageLimits.UploadUrlExpiration)
        };

        return s3Client.GetPreSignedURL(presignedUrlRequest);
    }

    public async Task<string> MoveToMessages(string tempFileKey, CancellationToken cancellationToken)
    {
        if (!tempFileKey.StartsWith(StorageLimits.TempFolderPrefix))
            throw new ArgumentException($"A chave temporária deve iniciar com '{StorageLimits.TempFolderPrefix}'.");

        var fileName = tempFileKey[StorageLimits.TempFolderPrefix.Length..];

        var isThumbnail = fileName.Contains($"_{StorageLimits.ThumbnailSuffix}.");
        var maxAllowedSize = isThumbnail ? StorageLimits.MaxThumbnailSizeBytes : StorageLimits.MaxAttachmentSizeBytes;

        var metadata = await s3Client.GetObjectMetadataAsync(awsOptions.S3.BucketName, tempFileKey, cancellationToken);
        if (metadata.ContentLength > maxAllowedSize)
            throw new ArgumentException(
                $"O tamanho do arquivo ({metadata.ContentLength} bytes) excede o limite máximo permitido de {maxAllowedSize} bytes.");

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

        return $"https://{awsOptions.S3.BucketName}.s3.{awsOptions.Region}.amazonaws.com/{fileKey}";
    }
}
