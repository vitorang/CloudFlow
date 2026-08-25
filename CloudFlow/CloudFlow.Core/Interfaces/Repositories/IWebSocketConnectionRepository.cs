namespace CloudFlow.Core.Interfaces.Repositories;

public interface IWebSocketConnectionRepository
{
    Task Add(string connectionId, CancellationToken cancellationToken);
    Task Remove(string connectionId, CancellationToken cancellationToken);
    Task<IReadOnlyList<string>> GetAll(CancellationToken cancellationToken);
}
