using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using CloudFlow.Core.Interfaces.Repositories;

using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using CloudFlow.Infrastructure.Aws.Repositories;

namespace CloudFlow.Workers.Aws.WebSocketApi;

public class WebSocketDisconnectHandler : IDisposable
{
    private readonly IWebSocketConnectionRepository connectionRepository;
    private readonly AmazonDynamoDBClient? client;
    private readonly DynamoDBContext? context;

    public WebSocketDisconnectHandler()
    {
        client = new AmazonDynamoDBClient();
        context = new DynamoDBContext(client);
        connectionRepository = new DynamoDbWebSocketConnectionRepository(context);
    }

    public WebSocketDisconnectHandler(IWebSocketConnectionRepository connectionRepository)
    {
        this.connectionRepository = connectionRepository;
    }

    public void Dispose()
    {
        context?.Dispose();
        client?.Dispose();
        GC.SuppressFinalize(this);
    }
    public async Task<APIGatewayProxyResponse> Handle(APIGatewayProxyRequest request, ILambdaContext context)
    {
        var connectionId = request.RequestContext?.ConnectionId;

        if (string.IsNullOrWhiteSpace(connectionId))
            return new APIGatewayProxyResponse
            {
                StatusCode = 400,
                Body = "ConnectionId não encontrado na requisição."
            };

        await connectionRepository.Remove(connectionId, CancellationToken.None);

        return new APIGatewayProxyResponse
        {
            StatusCode = 200,
            Body = "Disconnected"
        };
    }
}
