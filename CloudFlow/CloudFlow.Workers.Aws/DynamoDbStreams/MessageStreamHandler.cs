using Amazon.ApiGatewayManagementApi;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.SimpleNotificationService;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Enums;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Constants;
using CloudFlow.Infrastructure.Aws.Repositories;
using CloudFlow.Infrastructure.Aws.Services;

namespace CloudFlow.Workers.Aws.DynamoDbStreams;

public class MessageStreamHandler : IDisposable
{
    private readonly IWebSocketNotificationService webSocketNotificationService;
    private readonly IAuditNotificationService auditNotificationService;
    private readonly AmazonDynamoDBClient? dynamoClient;
    private readonly DynamoDBContext? dynamoContext;
    private readonly AmazonApiGatewayManagementApiClient? apiGatewayClient;
    private readonly AmazonSimpleNotificationServiceClient? snsClient;

    public MessageStreamHandler()
    {
        var wsServiceUrl = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.WebSocketServiceUrl)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.WebSocketServiceUrl} não foi definida.");

        var snsTopicArn = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.SnsMessagesTopicArn)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.SnsMessagesTopicArn} não foi definida.");

        dynamoClient = new AmazonDynamoDBClient();
        dynamoContext = new DynamoDBContextBuilder()
            .WithDynamoDBClient(() => dynamoClient)
            .Build();
        var connectionRepository = new DynamoDbWebSocketConnectionRepository(dynamoContext);

        var wsConfig = new AmazonApiGatewayManagementApiConfig
        {
            ServiceURL = wsServiceUrl
        };
        apiGatewayClient = new AmazonApiGatewayManagementApiClient(wsConfig);
        webSocketNotificationService = new ApiGatewayWebSocketNotificationService(apiGatewayClient, connectionRepository);

        snsClient = new AmazonSimpleNotificationServiceClient();
        auditNotificationService = new SnsAuditNotificationService(snsClient, snsTopicArn);
    }

    public MessageStreamHandler(
        IWebSocketNotificationService webSocketNotificationService,
        IAuditNotificationService auditNotificationService)
    {
        this.webSocketNotificationService = webSocketNotificationService;
        this.auditNotificationService = auditNotificationService;
    }

    public void Dispose()
    {
        snsClient?.Dispose();
        apiGatewayClient?.Dispose();
        dynamoContext?.Dispose();
        dynamoClient?.Dispose();
        GC.SuppressFinalize(this);
    }

    public async Task Handle(DynamoDBEvent dynamoEvent, ILambdaContext _)
    {
        foreach (var record in dynamoEvent.Records)
        {
            var task = record.EventName switch
            {
                "INSERT" => HandleCreated(record.Dynamodb.NewImage, CancellationToken.None),
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

        var auditDto = new AuditEventDto(
            TopicName: SnsTopics.Messages,
            EventType: WebSocketEvents.MessageCreated,
            OccurredAt: DateTime.UtcNow,
            Payload: messageDto
        );
        await auditNotificationService.Publish(auditDto, cancellationToken);
    }

    private async Task HandleDeleted(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> oldImage,
        CancellationToken cancellationToken)
    {
        if (!oldImage.TryGetValue("Id", out var messageIdAttribute))
            return;

        var messageId = messageIdAttribute.S;

        var webSocketMessage = new WebSocketMessageDto<string>(WebSocketEvents.MessageDeleted, messageId);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);

        var auditDto = new AuditEventDto(
            TopicName: SnsTopics.Messages,
            EventType: WebSocketEvents.MessageDeleted,
            OccurredAt: DateTime.UtcNow,
            Payload: new { Id = messageId }
        );
        await auditNotificationService.Publish(auditDto, cancellationToken);
    }

    private static MessageResponseDto? TryGetMessageDto(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> image)
    {
        if (!image.TryGetValue("Id", out var messageIdAttribute) ||
            !image.TryGetValue("Text", out var textAttribute) ||
            !image.TryGetValue("Type", out var typeAttribute) ||
            !image.TryGetValue("CreatedAt", out var createdAtAttribute))
            return null;

        var author = image.TryGetValue("Author", out var authorAttribute) ? authorAttribute.S : string.Empty;
        long? expiresAt = image.TryGetValue("ExpiresAt", out var expiresAtAttribute) && long.TryParse(expiresAtAttribute.N, out var parsedExpiresAt)
            ? parsedExpiresAt
            : null;

        return new MessageResponseDto(
            Id: messageIdAttribute.S,
            Author: author,
            Text: textAttribute.S,
            Type: (MessageType)int.Parse(typeAttribute.N),
            CreatedAt: DateTime.Parse(createdAtAttribute.S),
            ExpiresAt: expiresAt
        );
    }
}
