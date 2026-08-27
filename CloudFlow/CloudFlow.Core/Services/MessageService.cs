using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService(
    IMessageRepository messageRepository,
    IWebSocketNotificationService webSocketNotificationService) : IMessageService
{
    private const int RecentMessagesLimit = 5;

    public async Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        var message = dto.ToEntity();
        await messageRepository.Create(message, cancellationToken);

        var responseDto = message.ToResponseDto();
        var webSocketMessage = new WebSocketMessageDto<MessageResponseDto>(WebSocketEvents.MessageCreated, responseDto);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);
    }

    public async Task<RecentMessagesResponseDto> GetRecent(DateTime before, CancellationToken cancellationToken)
    {
        var messages = await messageRepository.GetRecent(before, RecentMessagesLimit + 1, cancellationToken);
        var hasPreviousMessages = messages.Count > RecentMessagesLimit;
        var slicedMessages = messages.Take(RecentMessagesLimit).ToList();

        var responseDtos = slicedMessages.Select(m => m.ToResponseDto()).ToList();
        return new RecentMessagesResponseDto(responseDtos, hasPreviousMessages);
    }
}

