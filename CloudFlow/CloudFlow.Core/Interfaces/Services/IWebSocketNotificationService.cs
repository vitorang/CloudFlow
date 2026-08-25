namespace CloudFlow.Core.Interfaces.Services;

public interface IWebSocketNotificationService
{
    Task Broadcast<T>(T payload, CancellationToken cancellationToken);
    Task Send<T>(string connectionId, T payload, CancellationToken cancellationToken);
}
