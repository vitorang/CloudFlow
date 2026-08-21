using CloudFlow.Infrastructure.Aws.Extensions;

namespace CloudFlow.Workers.Aws;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);
        builder.Services.AddAwsInfrastructure(builder.Configuration);
        builder.Services.AddHostedService<Worker>();

        var host = builder.Build();
        host.Run();
    }
}
