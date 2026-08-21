using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Runtime;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CloudFlow.Infrastructure.Aws.Extensions;

public static class AwsServiceExtensions
{
    public static IServiceCollection AddAwsInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var serviceUrl = configuration["AWS:DynamoDB:ServiceUrl"];
        var region = configuration["AWS_REGION"] 
            ?? configuration["AWS:Region"] 
            ?? throw new InvalidOperationException("Configuração AWS_REGION não foi definida.");

        var accessKey = configuration["AWS_ACCESS_KEY_ID"] 
            ?? configuration["AWS:AccessKey"] 
            ?? throw new InvalidOperationException("Configuração AWS_ACCESS_KEY_ID não foi definida.");

        var secretKey = configuration["AWS_SECRET_ACCESS_KEY"] 
            ?? configuration["AWS:SecretKey"] 
            ?? throw new InvalidOperationException("Configuração AWS_SECRET_ACCESS_KEY não foi definida.");

        var dynamoConfig = new AmazonDynamoDBConfig
        {
            AuthenticationRegion = region
        };

        if (!string.IsNullOrWhiteSpace(serviceUrl))
        {
            dynamoConfig.ServiceURL = serviceUrl;
        }

        var credentials = new BasicAWSCredentials(accessKey, secretKey);

        services.AddSingleton<IAmazonDynamoDB>(new AmazonDynamoDBClient(credentials, dynamoConfig));
        services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
        services.AddScoped<CloudFlow.Core.Interfaces.Repositories.IMessageRepository, Repositories.DynamoDbMessageRepository>();
        services.AddHostedService<Initializers.DynamoDbTableInitializer>();

        return services;
    }
}

