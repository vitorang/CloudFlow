using CloudFlow.Core.Enums;

namespace CloudFlow.Core.Dtos;

public record CreateMessageDto(
    string Text,
    MessageType Type
);

public record MessageResponseDto(
    string Id,
    string Text,
    MessageType Type,
    DateTime CreatedAt
);
