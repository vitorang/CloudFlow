using System.Text;
using Amazon.ApiGatewayManagementApi;
using Amazon.ApiGatewayManagementApi.Model;
using CloudFlow.Core.Common;
using CloudFlow.Core.Interfaces.Repositories;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Infrastructure.Aws.Services;

public class ApiGatewayWebSocketNotificationService(
    IAmazonApiGatewayManagementApi apiGatewayClient,
    IWebSocketConnectionRepository connectionRepository) : IWebSocketNotificationService
{
    public async Task Broadcast<T>(T payload, CancellationToken cancellationToken)
    {
        var connections = await connectionRepository.GetAll(cancellationToken);
        var bytes = JsonHelper.SerializeToUtf8Bytes(payload);

        var tasks = connections.Select(connectionId => SendRaw(connectionId, bytes, cancellationToken));
        await Task.WhenAll(tasks);
    }

    public async Task Send<T>(string connectionId, T payload, CancellationToken cancellationToken)
    {
        var bytes = JsonHelper.SerializeToUtf8Bytes(payload);

        await SendRaw(connectionId, bytes, cancellationToken);
    }

    private async Task SendRaw(string connectionId, byte[] payload, CancellationToken cancellationToken)
    {
        using var stream = new MemoryStream(payload);
        var request = new PostToConnectionRequest
        {
            ConnectionId = connectionId,
            Data = stream
        };

        try
        {
            await apiGatewayClient.PostToConnectionAsync(request, cancellationToken);
        }
        catch (GoneException)
        {
            await connectionRepository.Remove(connectionId, cancellationToken);
        }
    }
}
