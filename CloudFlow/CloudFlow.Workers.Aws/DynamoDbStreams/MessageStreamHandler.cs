using Amazon.ApiGatewayManagementApi;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.SimpleNotificationService;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Configuration;
using CloudFlow.Infrastructure.Aws.Constants;
using CloudFlow.Infrastructure.Aws.Repositories;
using CloudFlow.Infrastructure.Aws.Services;

namespace CloudFlow.Workers.Aws.DynamoDbStreams;

public class MessageStreamHandler : IDisposable
{
    private readonly IWebSocketNotificationService webSocketNotificationService;
    private readonly IAuditNotificationService auditNotificationService;
    private readonly IStorageService storageService;
    private readonly AmazonDynamoDBClient? dynamoClient;
    private readonly DynamoDBContext? dynamoContext;
    private readonly AmazonApiGatewayManagementApiClient? apiGatewayClient;
    private readonly AmazonSimpleNotificationServiceClient? snsClient;
    private readonly Amazon.S3.AmazonS3Client? s3Client;

    public MessageStreamHandler()
    {
        var wsServiceUrl = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.WebSocketServiceUrl)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.WebSocketServiceUrl} não foi definida.");

        var snsTopicArn = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.SnsMessagesTopicArn)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.SnsMessagesTopicArn} não foi definida.");

        var s3BucketName = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.S3BucketName)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.S3BucketName} não foi definida.");

        var region = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.Region)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.Region} não foi definida.");


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

        var s3Config = new Amazon.S3.AmazonS3Config
        {
            RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(region)
        };
        s3Client = new Amazon.S3.AmazonS3Client(s3Config);

        var awsOptions = new AwsOptions(
            Region: region,
            AccessKey: string.Empty,
            SecretKey: string.Empty,
            DynamoDB: new DynamoDbOptions(string.Empty),
            WebSocket: new WebSocketOptions(wsServiceUrl, string.Empty),
            S3: new S3Options(s3BucketName)
        );
        storageService = new S3StorageService(s3Client, awsOptions);
    }


    public MessageStreamHandler(
        IWebSocketNotificationService webSocketNotificationService,
        IAuditNotificationService auditNotificationService,
        IStorageService storageService)
    {
        this.webSocketNotificationService = webSocketNotificationService;
        this.auditNotificationService = auditNotificationService;
        this.storageService = storageService;
    }

    public void Dispose()
    {
        s3Client?.Dispose();
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
            TopicName: PubSubTopics.Aws.Messages,
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

        var keysToDelete = new List<string>();
        if (oldImage.TryGetValue("AttachmentKey", out var attachmentKeyAttribute) && !string.IsNullOrWhiteSpace(attachmentKeyAttribute.S))
            keysToDelete.Add(attachmentKeyAttribute.S);

        if (oldImage.TryGetValue("ThumbnailKey", out var thumbnailKeyAttribute) && !string.IsNullOrWhiteSpace(thumbnailKeyAttribute.S))
            keysToDelete.Add(thumbnailKeyAttribute.S);

        if (keysToDelete.Count > 0)
            await storageService.DeleteMany(keysToDelete, cancellationToken);

        var webSocketMessage = new WebSocketMessageDto<string>(WebSocketEvents.MessageDeleted, messageId);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);

        var auditDto = new AuditEventDto(
            TopicName: PubSubTopics.Aws.Messages,
            EventType: WebSocketEvents.MessageDeleted,
            OccurredAt: DateTime.UtcNow,
            Payload: new { Id = messageId }
        );
        await auditNotificationService.Publish(auditDto, cancellationToken);
    }

    private MessageResponseDto? TryGetMessageDto(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> image)
    {
        if (!image.TryGetValue("Id", out var messageIdAttribute) ||
            !image.TryGetValue("CreatedAt", out var createdAtAttribute))
            return null;

        var text = image.TryGetValue("Text", out var textAttribute) ? textAttribute.S ?? string.Empty : string.Empty;
        var author = image.TryGetValue("Author", out var authorAttribute) ? authorAttribute.S : string.Empty;
        var attachmentKey = image.TryGetValue("AttachmentKey", out var attachmentKeyAttribute) ? attachmentKeyAttribute.S : null;
        var thumbnailKey = image.TryGetValue("ThumbnailKey", out var thumbnailKeyAttribute) ? thumbnailKeyAttribute.S : null;
        long? expiresAt = image.TryGetValue("ExpiresAt", out var expiresAtAttribute) && long.TryParse(expiresAtAttribute.N, out var parsedExpiresAt)
            ? parsedExpiresAt
            : null;

        return new MessageResponseDto(
            Id: messageIdAttribute.S,
            Author: author,
            Text: text,
            AttachmentUrl: storageService.GetDownloadUrl(attachmentKey),
            ThumbnailUrl: storageService.GetDownloadUrl(thumbnailKey),
            CreatedAt: DateTime.Parse(createdAtAttribute.S),
            ExpiresAt: expiresAt
        );
    }
}
