using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using CloudFlow.Infrastructure.Aws.Extensions;

[assembly: LambdaSerializer(typeof(DefaultLambdaJsonSerializer))]

namespace CloudFlow.Workers.Aws;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);
        builder.Services.AddAwsInfrastructure(builder.Configuration);
        builder.Services.AddScoped<DynamoDbStreams.MessageStreamHandler>();
        builder.Services.AddScoped<WebSocketApi.WebSocketConnectionHandler>();
        builder.Services.AddScoped<Sns.AuditEventSnsHandler>();

        var host = builder.Build();
        host.Run();
    }
}
