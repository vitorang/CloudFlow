using CloudFlow.Core.Dtos;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService(IMessageRepository messageRepository) : IMessageService
{
    private const int RecentMessagesLimit = 20;

    public async Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        var message = dto.ToEntity();
        await messageRepository.Create(message, cancellationToken);
    }

    public async Task<RecentMessagesResponseDto> GetRecent(DateTime before, CancellationToken cancellationToken)
    {
        var messages = await messageRepository.GetRecent(before, RecentMessagesLimit + 1, cancellationToken);
        var hasPreviousMessages = messages.Count > RecentMessagesLimit;
        var slicedMessages = messages.Take(RecentMessagesLimit).ToList();

        var responseDtos = slicedMessages.Select(m => m.ToResponseDto()).ToList();
        return new RecentMessagesResponseDto(responseDtos, hasPreviousMessages);
    }

    public async Task DeleteMany(DeleteMessagesDto dto, CancellationToken cancellationToken)
    {
        if (dto.Ids.Count == 0)
            return;

        await messageRepository.DeleteMany(dto.Ids, cancellationToken);
    }
}

