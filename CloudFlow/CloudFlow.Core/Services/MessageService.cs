using CloudFlow.Core.Dtos;
using CloudFlow.Core.Extensions;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Services;

public class MessageService(
    IMessageRepository messageRepository,
    IStorageService storageService) : IMessageService
{
    private const int RecentMessagesLimit = 20;

    public async Task Create(CreateMessageDto dto, CancellationToken cancellationToken)
    {
        var message = dto.ToEntity();

        if (!string.IsNullOrWhiteSpace(message.AttachmentKey))
            message.AttachmentKey = await storageService.MoveToMessages(message.AttachmentKey, cancellationToken);

        if (!string.IsNullOrWhiteSpace(message.ThumbnailKey))
            message.ThumbnailKey = await storageService.MoveToMessages(message.ThumbnailKey, cancellationToken);

        await messageRepository.Create(message, cancellationToken);
    }

    public async Task<RecentMessagesResponseDto> GetRecent(DateTime before, CancellationToken cancellationToken)
    {
        var messages = await messageRepository.GetRecent(before, RecentMessagesLimit + 1, cancellationToken);
        var currentUnixTimestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var activeMessages = messages.Where(m => !m.ExpiresAt.HasValue || m.ExpiresAt.Value > currentUnixTimestamp).ToList();

        var hasPreviousMessages = activeMessages.Count > RecentMessagesLimit;
        var slicedMessages = activeMessages.Take(RecentMessagesLimit).ToList();

        var responseDtos = slicedMessages.Select(m => m.ToResponseDto(storageService)).ToList();
        return new RecentMessagesResponseDto(responseDtos, hasPreviousMessages);
    }


    public async Task DeleteMany(DeleteMessagesDto dto, CancellationToken cancellationToken)
    {
        if (dto.Ids.Count == 0)
            return;

        await messageRepository.DeleteMany(dto.Ids, cancellationToken);
    }
}

