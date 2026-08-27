using CloudFlow.Core.Dtos;
using CloudFlow.Core.Entities;

namespace CloudFlow.Core.Extensions;

public static class MessageExtensions
{
    public static Message ToEntity(this CreateMessageDto dto)
    {
        return new Message
        {
            Author = dto.Author.Trim(),
            Text = dto.Text,
            Type = dto.Type
        };
    }

    public static MessageResponseDto ToResponseDto(this Message entity)
    {
        return new MessageResponseDto(
            Id: entity.Id,
            Author: entity.Author,
            Text: entity.Text,
            Type: entity.Type,
            CreatedAt: entity.CreatedAt
        );
    }
}
