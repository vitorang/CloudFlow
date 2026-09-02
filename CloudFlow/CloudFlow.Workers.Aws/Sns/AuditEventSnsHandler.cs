using Amazon.ApiGatewayManagementApi;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.Core;
using Amazon.Lambda.SNSEvents;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Constants;
using CloudFlow.Infrastructure.Aws.Repositories;
using CloudFlow.Infrastructure.Aws.Services;
using System.Text.Json;

namespace CloudFlow.Workers.Aws.Sns;

public class AuditEventSnsHandler : IDisposable
{
    private readonly IWebSocketNotificationService webSocketNotificationService;
    private readonly AmazonDynamoDBClient? dynamoClient;
    private readonly DynamoDBContext? dynamoContext;
    private readonly AmazonApiGatewayManagementApiClient? apiGatewayClient;
    private readonly JsonSerializerOptions jsonSerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public AuditEventSnsHandler()
    {
        var wsServiceUrl = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.WebSocketServiceUrl)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.WebSocketServiceUrl} não foi definida.");

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
    }

    public AuditEventSnsHandler(IWebSocketNotificationService webSocketNotificationService)
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

    public async Task Handle(SNSEvent snsEvent, ILambdaContext _)
    {
        foreach (var record in snsEvent.Records)
        {
            var message = record.Sns.Message;

            if (string.IsNullOrWhiteSpace(message))
                continue;

            var auditDto = JsonSerializer.Deserialize<AuditEventDto>(message, jsonSerializerOptions);

            if (auditDto is null)
                continue;

            var notification = new WebSocketMessageDto<AuditEventDto>(
                WebSocketEvents.AuditEvent,
                auditDto
            );

            await webSocketNotificationService.Broadcast(notification, CancellationToken.None);
        }
    }
}
