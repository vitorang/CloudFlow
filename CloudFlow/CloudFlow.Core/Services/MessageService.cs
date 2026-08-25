using CloudFlow.Core.Dtos;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService(
    IWebSocketNotificationService webSocketNotificationService) : IMessageService
{
    private const int RecentMessagesLimit = 5;

    public async Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        var message = dto.ToEntity();
        var responseDto = message.ToResponseDto();
        await webSocketNotificationService.Broadcast(responseDto, cancellationToken);
    }

    public async Task<IReadOnlyList<MessageResponseDto>> GetRecent(CancellationToken cancellationToken)
    {
        return await Task.FromResult<IReadOnlyList<MessageResponseDto>>([]);
    }
}

