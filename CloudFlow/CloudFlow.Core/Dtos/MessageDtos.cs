using CloudFlow.Core.Enums;

namespace CloudFlow.Core.Dtos;

public record CreateMessageDto(
    string Author,
    string Text,
    MessageType Type,
    int? ExpiresInHours = null
);

public record MessageResponseDto(
    string Id,
    string Author,
    string Text,
    MessageType Type,
    DateTime CreatedAt,
    long? ExpiresAt = null
);
