using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;
using CloudFlow.Core.Common;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Infrastructure.Aws.Services;

public class SnsAuditNotificationService(
    IAmazonSimpleNotificationService snsClient,
    string topicArn) : IAuditNotificationService
{
    public async Task Publish<T>(T payload, CancellationToken cancellationToken)
    {
        var message = JsonHelper.Serialize(payload);

        var request = new PublishRequest
        {
            TopicArn = topicArn,
            Message = message
        };

        await snsClient.PublishAsync(request, cancellationToken);
    }
}
