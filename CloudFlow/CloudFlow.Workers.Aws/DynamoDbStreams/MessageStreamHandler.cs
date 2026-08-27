using Amazon.ApiGatewayManagementApi;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Enums;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Repositories;
using CloudFlow.Infrastructure.Aws.Services;

namespace CloudFlow.Workers.Aws.DynamoDbStreams;

public class MessageStreamHandler : IDisposable
{
    private readonly IWebSocketNotificationService webSocketNotificationService;
    private readonly AmazonDynamoDBClient? dynamoClient;
    private readonly DynamoDBContext? dynamoContext;
    private readonly AmazonApiGatewayManagementApiClient? apiGatewayClient;

    public MessageStreamHandler()
    {
        var wsServiceUrl = Environment.GetEnvironmentVariable("AWS_WEBSOCKET_SERVICE_URL")
            ?? throw new InvalidOperationException("Variável de ambiente AWS_WEBSOCKET_SERVICE_URL não foi definida.");

        dynamoClient = new AmazonDynamoDBClient();
        dynamoContext = new DynamoDBContext(dynamoClient);
        var connectionRepository = new DynamoDbWebSocketConnectionRepository(dynamoContext);

        var wsConfig = new AmazonApiGatewayManagementApiConfig
        {
            ServiceURL = wsServiceUrl
        };
        apiGatewayClient = new AmazonApiGatewayManagementApiClient(wsConfig);
        webSocketNotificationService = new ApiGatewayWebSocketNotificationService(apiGatewayClient, connectionRepository);
    }

    public MessageStreamHandler(IWebSocketNotificationService webSocketNotificationService)
    {
        this.webSocketNotificationService = webSocketNotificationService;
    }

    public void Dispose()
    {
        apiGatewayClient?.Dispose();
        dynamoContext?.Dispose();
        dynamoClient?.Dispose();
        GC.SuppressFinalize(this);
    }

    public async Task Handle(DynamoDBEvent dynamoEvent, ILambdaContext context)
    {
        foreach (var record in dynamoEvent.Records)
        {
            var task = record.EventName switch
            {
                "INSERT" => HandleCreated(record.Dynamodb.NewImage, CancellationToken.None),
                "MODIFY" => HandleUpdated(record.Dynamodb.NewImage, record.Dynamodb.OldImage, CancellationToken.None),
                "REMOVE" => HandleDeleted(record.Dynamodb.OldImage, CancellationToken.None),
                _ => Task.CompletedTask
            };

            await task;
        }
    }

    private async Task HandleCreated(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> newImage,
        CancellationToken cancellationToken)
    {
        var messageDto = TryGetMessageDto(newImage);
        if (messageDto == null)
            return;

        var webSocketMessage = new WebSocketMessageDto<MessageResponseDto>(WebSocketEvents.MessageCreated, messageDto);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);
    }

    private async Task HandleUpdated(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> newImage,
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> oldImage,
        CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
    }

    private async Task HandleDeleted(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> oldImage,
        CancellationToken cancellationToken)
    {
        if (!oldImage.TryGetValue("Id", out var idAttribute))
            return;

        var webSocketMessage = new WebSocketMessageDto<string>(WebSocketEvents.MessageDeleted, idAttribute.S);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);
    }

    private static MessageResponseDto? TryGetMessageDto(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> image)
    {
        if (!image.TryGetValue("Id", out var idAttribute) ||
            !image.TryGetValue("Text", out var textAttribute) ||
            !image.TryGetValue("Type", out var typeAttribute) ||
            !image.TryGetValue("CreatedAt", out var createdAtAttribute))
            return null;

        return new MessageResponseDto(
            Id: idAttribute.S,
            Text: textAttribute.S,
            Type: (MessageType)int.Parse(typeAttribute.N),
            CreatedAt: DateTime.Parse(createdAtAttribute.S)
        );
    }
}
