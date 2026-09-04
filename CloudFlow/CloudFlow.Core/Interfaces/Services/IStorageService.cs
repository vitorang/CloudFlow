using CloudFlow.Core.Dtos;

namespace CloudFlow.Core.Interfaces.Services;

public interface IStorageService
{
    Task<UploadUrlsResponseDto> GenerateUploadUrls(GenerateUploadUrlsDto dto, CancellationToken cancellationToken);
    Task<string> MoveToMessages(string tempFileKey, CancellationToken cancellationToken);
    Task DeleteMany(IReadOnlyList<string> fileKeys, CancellationToken cancellationToken);
    string? GetDownloadUrl(string? fileKey);
}
