using CloudFlow.Core.Dtos;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService(IMessageRepository messageRepository) : IMessageService
{
    private const int RecentMessagesLimit = 5;

    public async Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        var message = dto.ToEntity();
        await messageRepository.Create(message, cancellationToken);
    }

    public async Task<IReadOnlyList<MessageResponseDto>> GetRecent(CancellationToken cancellationToken)
    {
        var messages = await messageRepository.GetRecent(RecentMessagesLimit, cancellationToken);

        return messages
            .Select(m => m.ToResponseDto())
            .ToList();
    }
}

