using CloudFlow.Core.Dtos;

namespace CloudFlow.Core.Interfaces.Services;

public interface IMessageService
{
    Task Create(CreateMessageDto dto, CancellationToken cancellationToken);
    Task<IReadOnlyList<MessageResponseDto>> GetRecent(CancellationToken cancellationToken);
}
