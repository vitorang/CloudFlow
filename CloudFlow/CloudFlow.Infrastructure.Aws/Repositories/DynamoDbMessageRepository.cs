using Amazon.DynamoDBv2.DataModel;
using Amazon.DynamoDBv2.DocumentModel;
using CloudFlow.Core.Entities;
using CloudFlow.Core.Enums;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Infrastructure.Aws.Models;

namespace CloudFlow.Infrastructure.Aws.Repositories;

public class DynamoDbMessageRepository(IDynamoDBContext context) : IMessageRepository
{
    public async Task Create(Message message, CancellationToken cancellationToken)
    {
        var item = new MessageItem
        {
            Id = message.Id,
            Text = message.Text,
            Type = (int)message.Type,
            CreatedAt = message.CreatedAt.ToString("O")
        };

        await context.SaveAsync(item, cancellationToken);
    }

    public async Task<IReadOnlyList<Message>> GetRecent(DateTime before, int limit, CancellationToken cancellationToken)
    {
        var scanConditions = new List<ScanCondition>
        {
            new("CreatedAt", ScanOperator.LessThan, before.ToUniversalTime().ToString("O"))
        };
        var search = context.ScanAsync<MessageItem>(scanConditions);

        var items = await search.GetNextSetAsync(cancellationToken);

        return [.. items
            .OrderByDescending(item => item.CreatedAt)
            .Take(limit)
            .Select(item => new Message
            {
                Id = item.Id,
                Text = item.Text,
                Type = (MessageType)item.Type,
                CreatedAt = DateTime.Parse(item.CreatedAt)
            })];
    }

    public async Task DeleteMany(IReadOnlyList<string> ids, CancellationToken cancellationToken)
    {
        var batchWrite = context.CreateBatchWrite<MessageItem>();
        foreach (var id in ids)
            batchWrite.AddDeleteKey(id);

        await batchWrite.ExecuteAsync(cancellationToken);
    }
}
