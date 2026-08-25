using System.Text.Json;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Runtime;
using CloudFlow.Infrastructure.Aws.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CloudFlow.Infrastructure.Aws.Extensions;

public static class AwsServiceExtensions
{
    public static IServiceCollection AddAwsInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var awsOptions = BuildAwsOptions(configuration);

        services.AddSingleton(awsOptions);

        var dynamoConfig = new AmazonDynamoDBConfig
        {
            AuthenticationRegion = awsOptions.Region,
            ServiceURL = awsOptions.DynamoDB.ServiceUrl
        };

        var credentials = new BasicAWSCredentials(awsOptions.AccessKey, awsOptions.SecretKey);

        services.AddSingleton<IAmazonDynamoDB>(new AmazonDynamoDBClient(credentials, dynamoConfig));
        services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
        services.AddScoped<CloudFlow.Core.Interfaces.Repositories.IMessageRepository, Repositories.DynamoDbMessageRepository>();
        // services.AddScoped<CloudFlow.Core.Interfaces.Repositories.IWebSocketConnectionRepository, Repositories.DynamoDbWebSocketConnectionRepository>();
        services.AddSingleton<CloudFlow.Core.Interfaces.Repositories.IWebSocketConnectionRepository, Repositories.MemoryWebSocketConnectionRepository>();

        var wsConfig = new Amazon.ApiGatewayManagementApi.AmazonApiGatewayManagementApiConfig
        {
            AuthenticationRegion = awsOptions.Region,
            ServiceURL = awsOptions.WebSocket.ServiceUrl
        };

        services.AddSingleton<Amazon.ApiGatewayManagementApi.IAmazonApiGatewayManagementApi>(
            new Amazon.ApiGatewayManagementApi.AmazonApiGatewayManagementApiClient(credentials, wsConfig));
        services.AddScoped<CloudFlow.Core.Interfaces.Services.IWebSocketNotificationService, Services.ApiGatewayWebSocketNotificationService>();

        return services;
    }

    private static AwsOptions BuildAwsOptions(IConfiguration configuration)
    {
        var region = configuration["AWS:Region"]
            ?? throw new InvalidOperationException("Configuração AWS:Region não foi definida.");

        var accessKey = configuration["AWS:AccessKey"]
            ?? throw new InvalidOperationException("Configuração AWS:AccessKey não foi definida.");

        var secretKey = configuration["AWS:SecretKey"]
            ?? throw new InvalidOperationException("Configuração AWS:SecretKey não foi definida.");

        var dynamoServiceUrl = configuration["AWS:DynamoDB:ServiceUrl"]
            ?? throw new InvalidOperationException("Configuração AWS:DynamoDB:ServiceUrl não foi definida.");

        var wsServiceUrl = configuration["AWS:WebSocket:ServiceUrl"]
            ?? throw new InvalidOperationException("Configuração AWS:WebSocket:ServiceUrl não foi definida.");

        var wsPublicUrl = configuration["AWS:WebSocket:PublicUrl"]
            ?? throw new InvalidOperationException("Configuração AWS:WebSocket:PublicUrl não foi definida.");

        return new AwsOptions(
            Region: region,
            AccessKey: accessKey,
            SecretKey: secretKey,
            DynamoDB: new DynamoDbOptions(dynamoServiceUrl),
            WebSocket: new WebSocketOptions(wsServiceUrl, wsPublicUrl)
        );
    }
}

