using Amazon.DynamoDBv2.DataModel;

namespace CloudFlow.Infrastructure.Aws.Models;

[DynamoDBTable("WebSocketConnections")]
public class WebSocketConnectionItem
{
    [DynamoDBHashKey]
    public string ConnectionId { get; set; } = string.Empty;

    [DynamoDBProperty]
    public string ConnectedAt { get; set; } = string.Empty;
}
