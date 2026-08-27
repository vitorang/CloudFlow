namespace CloudFlow.Core.Dtos;

public record RecentMessagesResponseDto(
    IReadOnlyList<MessageResponseDto> Messages,
    bool HasPreviousMessages
);
