using CloudFlow.Core.Dtos;
using CloudFlow.Core.Entities;

namespace CloudFlow.Core.Extensions;

public static class MessageExtensions
{
    public static Message ToEntity(this CreateMessageDto dto)
    {
        return new Message
        {
            Text = dto.Text,
            Type = dto.Type
        };
    }

    public static MessageResponseDto ToResponseDto(this Message entity)
    {
        return new MessageResponseDto(
            Id: entity.Id,
            Text: entity.Text,
            Type: entity.Type,
            CreatedAt: entity.CreatedAt
        );
    }
}
