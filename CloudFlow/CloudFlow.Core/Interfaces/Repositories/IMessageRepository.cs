using CloudFlow.Core.Entities;

namespace CloudFlow.Core.Interfaces.Repositories;

public interface IMessageRepository
{
    Task Create(Message message, CancellationToken cancellationToken);
    Task<IReadOnlyList<Message>> GetRecent(int limit, CancellationToken cancellationToken);
}
