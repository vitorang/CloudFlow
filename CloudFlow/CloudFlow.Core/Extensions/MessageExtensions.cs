using CloudFlow.Core.Dtos;
using CloudFlow.Core.Entities;

namespace CloudFlow.Core.Extensions;

public static class MessageExtensions
{
    public static Message ToEntity(this CreateMessageDto dto)
    {
        var message = new Message
        {
            Author = dto.Author.Trim(),
            Text = dto.Text,
            Type = dto.Type
        };

        if (dto.ExpiresInHours.HasValue && dto.ExpiresInHours.Value > 0)
            message.ExpiresAt = DateTimeOffset.UtcNow.AddHours(dto.ExpiresInHours.Value).ToUnixTimeSeconds();

        return message;
    }

    public static MessageResponseDto ToResponseDto(this Message entity)
    {
        return new MessageResponseDto(
            Id: entity.Id,
            Author: entity.Author,
            Text: entity.Text,
            Type: entity.Type,
            CreatedAt: entity.CreatedAt,
            ExpiresAt: entity.ExpiresAt
        );
    }
}
