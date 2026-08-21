using Amazon.DynamoDBv2.DataModel;
using CloudFlow.Core.Enums;

namespace CloudFlow.Infrastructure.Aws.Models;

[DynamoDBTable("Messages")]
public class MessageItem
{
    [DynamoDBHashKey]
    public string Id { get; set; } = string.Empty;

    [DynamoDBProperty]
    public string Text { get; set; } = string.Empty;

    [DynamoDBProperty]
    public int Type { get; set; }

    [DynamoDBProperty]
    public string CreatedAt { get; set; } = string.Empty;
}
