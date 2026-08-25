using System.Collections.Concurrent;
using CloudFlow.Core.Interfaces.Repositories;

namespace CloudFlow.Infrastructure.Aws.Repositories;

public class MemoryWebSocketConnectionRepository : IWebSocketConnectionRepository
{
    private readonly ConcurrentDictionary<string, byte> connections = new();

    public Task Add(string connectionId, CancellationToken cancellationToken)
    {
        connections.TryAdd(connectionId, 0);
        return Task.CompletedTask;
    }

    public Task Remove(string connectionId, CancellationToken cancellationToken)
    {
        connections.TryRemove(connectionId, out _);
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<string>> GetAll(CancellationToken cancellationToken)
    {
        IReadOnlyList<string> result = connections.Keys.ToList();
        return Task.FromResult(result);
    }
}
