using CloudFlow.Core.Dtos;
using CloudFlow.Core.Entities;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Core.Extensions;

public static class MessageExtensions
{
    public static Message ToEntity(this CreateMessageDto dto)
    {
        var message = new Message
        {
            Author = dto.Author.Trim(),
            Text = dto.Text,
            AttachmentKey = dto.AttachmentKey,
            ThumbnailKey = dto.ThumbnailKey
        };

        if (dto.ExpiresInHours.HasValue && dto.ExpiresInHours.Value > 0)
            message.ExpiresAt = DateTimeOffset.UtcNow.AddHours(dto.ExpiresInHours.Value).ToUnixTimeSeconds();

        return message;
    }

    public static MessageResponseDto ToResponseDto(this Message entity, IStorageService storageService)
    {
        return new MessageResponseDto(
            Id: entity.Id,
            Author: entity.Author,
            Text: entity.Text,
            AttachmentUrl: storageService.GetDownloadUrl(entity.AttachmentKey),
            ThumbnailUrl: storageService.GetDownloadUrl(entity.ThumbnailKey),
            CreatedAt: entity.CreatedAt,
            ExpiresAt: entity.ExpiresAt
        );
    }
}
