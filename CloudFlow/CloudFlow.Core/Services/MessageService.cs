using System.Collections.Concurrent;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Entities;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService : IMessageService
{
    private const int RecentMessagesLimit = 5;
    private static readonly ConcurrentBag<Message> Messages = new();

    public Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var message = dto.ToEntity();
        Messages.Add(message);

        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<MessageResponseDto>> GetRecent(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        IReadOnlyList<MessageResponseDto> recentMessages = Messages
            .OrderByDescending(m => m.CreatedAt)
            .Take(RecentMessagesLimit)
            .Select(m => m.ToResponseDto())
            .ToList();

        return Task.FromResult(recentMessages);
    }
}
