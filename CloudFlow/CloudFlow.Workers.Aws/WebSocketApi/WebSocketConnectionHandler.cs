using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using Amazon.SimpleNotificationService;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;
using CloudFlow.Infrastructure.Aws.Constants;
using CloudFlow.Infrastructure.Aws.Repositories;
using CloudFlow.Infrastructure.Aws.Services;

namespace CloudFlow.Workers.Aws.WebSocketApi;

public class WebSocketConnectionHandler : IDisposable
{
    private readonly IWebSocketConnectionRepository connectionRepository;
    private readonly IAuditNotificationService auditNotificationService;
    private readonly AmazonDynamoDBClient? dynamoClient;
    private readonly DynamoDBContext? dynamoContext;
    private readonly AmazonSimpleNotificationServiceClient? snsClient;

    public WebSocketConnectionHandler()
    {
        var snsTopicArn = Environment.GetEnvironmentVariable(AwsEnvironmentVariables.SnsUsersTopicArn)
            ?? throw new InvalidOperationException($"Variável de ambiente {AwsEnvironmentVariables.SnsUsersTopicArn} não foi definida.");

        dynamoClient = new AmazonDynamoDBClient();
        dynamoContext = new DynamoDBContextBuilder()
            .WithDynamoDBClient(() => dynamoClient)
            .Build();
        connectionRepository = new DynamoDbWebSocketConnectionRepository(dynamoContext);

        snsClient = new AmazonSimpleNotificationServiceClient();
        auditNotificationService = new SnsAuditNotificationService(snsClient, snsTopicArn);
    }

    public WebSocketConnectionHandler(
        IWebSocketConnectionRepository connectionRepository,
        IAuditNotificationService auditNotificationService)
    {
        this.connectionRepository = connectionRepository;
        this.auditNotificationService = auditNotificationService;
    }

    public void Dispose()
    {
        snsClient?.Dispose();
        dynamoContext?.Dispose();
        dynamoClient?.Dispose();
        GC.SuppressFinalize(this);
    }

    public async Task<APIGatewayProxyResponse> Connect(APIGatewayProxyRequest request, ILambdaContext _)
    {
        var connectionId = request.RequestContext?.ConnectionId;

        if (string.IsNullOrWhiteSpace(connectionId))
            return new APIGatewayProxyResponse
            {
                StatusCode = 400,
                Body = "ConnectionId não encontrado na requisição."
            };

        await connectionRepository.Add(connectionId, CancellationToken.None);

        var auditDto = new AuditEventDto(
            TopicName: PubSubTopics.Aws.Users,
            EventType: WebSocketEvents.UserConnected,
            OccurredAt: DateTime.UtcNow,
            Payload: new
            {
                ConnectionId = connectionId
            }
        );

        await auditNotificationService.Publish(auditDto, CancellationToken.None);

        return new APIGatewayProxyResponse
        {
            StatusCode = 200,
            Body = "Connected"
        };
    }

    public async Task<APIGatewayProxyResponse> Disconnect(APIGatewayProxyRequest request, ILambdaContext _)
    {
        var connectionId = request.RequestContext?.ConnectionId;

        if (string.IsNullOrWhiteSpace(connectionId))
            return new APIGatewayProxyResponse
            {
                StatusCode = 400,
                Body = "ConnectionId não encontrado na requisição."
            };

        await connectionRepository.Remove(connectionId, CancellationToken.None);

        var auditDto = new AuditEventDto(
            TopicName: PubSubTopics.Aws.Users,
            EventType: WebSocketEvents.UserDisconnected,
            OccurredAt: DateTime.UtcNow,
            Payload: new
            {
                ConnectionId = connectionId
            }
        );

        await auditNotificationService.Publish(auditDto, CancellationToken.None);

        return new APIGatewayProxyResponse
        {
            StatusCode = 200,
            Body = "Disconnected"
        };
    }
}
