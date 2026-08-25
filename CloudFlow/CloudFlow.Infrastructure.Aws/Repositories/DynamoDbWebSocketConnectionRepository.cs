using Amazon.DynamoDBv2.DataModel;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Infrastructure.Aws.Models;

namespace CloudFlow.Infrastructure.Aws.Repositories;

public class DynamoDbWebSocketConnectionRepository(IDynamoDBContext context) : IWebSocketConnectionRepository
{
    public async Task Add(string connectionId, CancellationToken cancellationToken)
    {
        var item = new WebSocketConnectionItem
        {
            ConnectionId = connectionId,
            ConnectedAt = DateTime.UtcNow.ToString("O")
        };

        await context.SaveAsync(item, cancellationToken);
    }

    public async Task Remove(string connectionId, CancellationToken cancellationToken)
    {
        await context.DeleteAsync<WebSocketConnectionItem>(connectionId, cancellationToken);
    }

    public async Task<IReadOnlyList<string>> GetAll(CancellationToken cancellationToken)
    {
        var conditions = new List<ScanCondition>();
        var search = context.ScanAsync<WebSocketConnectionItem>(conditions);
        var items = await search.GetNextSetAsync(cancellationToken);

        return items.Select(item => item.ConnectionId).ToList();
    }
}
