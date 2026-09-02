namespace CloudFlow.Core.Interfaces.Services;

public interface IAuditNotificationService
{
    Task Publish<T>(T payload, CancellationToken cancellationToken);
}
