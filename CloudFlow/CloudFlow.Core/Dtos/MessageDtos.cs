namespace CloudFlow.Core.Dtos;

public record CreateMessageDto(
    string Author,
    string Text,
    string? AttachmentKey = null,
    string? ThumbnailKey = null,
    int? ExpiresInHours = null
);

public record MessageResponseDto(
    string Id,
    string Author,
    string Text,
    string? AttachmentUrl,
    string? ThumbnailUrl,
    DateTime CreatedAt,
    long? ExpiresAt = null
);
