using CloudFlow.Core.Enums;

namespace CloudFlow.Core.Dtos;

public record CreateMessageDto(
    string Author,
    string Text,
    MessageType Type
);

public record MessageResponseDto(
    string Id,
    string Author,
    string Text,
    MessageType Type,
    DateTime CreatedAt
);
