using System.Text.Json;
using Amazon;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Runtime;
using CloudFlow.Infrastructure.Aws.Configuration;
using CloudFlow.Infrastructure.Aws.Constants;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CloudFlow.Infrastructure.Aws.Extensions;

public static class AwsServiceExtensions
{
    public static IServiceCollection AddAwsInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var awsOptions = BuildAwsOptions(configuration);

        services.AddSingleton(awsOptions);

        AWSCredentials? credentials = null;
        if (!string.IsNullOrWhiteSpace(awsOptions.AccessKey) && !string.IsNullOrWhiteSpace(awsOptions.SecretKey))
        {
            credentials = !string.IsNullOrWhiteSpace(awsOptions.SessionToken)
                ? new SessionAWSCredentials(awsOptions.AccessKey, awsOptions.SecretKey, awsOptions.SessionToken)
                : new BasicAWSCredentials(awsOptions.AccessKey, awsOptions.SecretKey);
        }

        var dynamoConfig = new AmazonDynamoDBConfig
        {
            AuthenticationRegion = awsOptions.Region
        };

        if (!string.IsNullOrWhiteSpace(awsOptions.DynamoDB.ServiceUrl))
            dynamoConfig.ServiceURL = awsOptions.DynamoDB.ServiceUrl;

        var dynamoClient = credentials != null
            ? new AmazonDynamoDBClient(credentials, dynamoConfig)
            : new AmazonDynamoDBClient(dynamoConfig);

        services.AddSingleton<IAmazonDynamoDB>(dynamoClient);
        services.AddSingleton<IDynamoDBContext, DynamoDBContext>();
        services.AddScoped<CloudFlow.Core.Interfaces.Repositories.IMessageRepository, Repositories.DynamoDbMessageRepository>();
        services.AddScoped<CloudFlow.Core.Interfaces.Repositories.IWebSocketConnectionRepository, Repositories.DynamoDbWebSocketConnectionRepository>();

        var wsConfig = new Amazon.ApiGatewayManagementApi.AmazonApiGatewayManagementApiConfig
        {
            AuthenticationRegion = awsOptions.Region,
            ServiceURL = awsOptions.WebSocket.ServiceUrl
        };

        var wsClient = credentials != null
            ? new Amazon.ApiGatewayManagementApi.AmazonApiGatewayManagementApiClient(credentials, wsConfig)
            : new Amazon.ApiGatewayManagementApi.AmazonApiGatewayManagementApiClient(wsConfig);

        services.AddSingleton<Amazon.ApiGatewayManagementApi.IAmazonApiGatewayManagementApi>(wsClient);
        services.AddScoped<CloudFlow.Core.Interfaces.Services.IWebSocketNotificationService, Services.ApiGatewayWebSocketNotificationService>();

        var s3Config = new Amazon.S3.AmazonS3Config
        {
            RegionEndpoint = RegionEndpoint.GetBySystemName(awsOptions.Region)
        };

        var s3Client = credentials != null
            ? new Amazon.S3.AmazonS3Client(credentials, s3Config)
            : new Amazon.S3.AmazonS3Client(s3Config);

        services.AddSingleton<Amazon.S3.IAmazonS3>(s3Client);
        services.AddScoped<CloudFlow.Core.Interfaces.Services.IStorageService, Services.S3StorageService>();

        return services;
    }

    private static AwsOptions BuildAwsOptions(IConfiguration configuration)
    {
        var region = GetString(configuration, AwsEnvironmentVariables.Region, "AWS:Region");
        var accessKey = GetStringOrNull(configuration, AwsEnvironmentVariables.AccessKey, "AWS:AccessKey");
        var secretKey = GetStringOrNull(configuration, AwsEnvironmentVariables.SecretKey, "AWS:SecretKey");
        var sessionToken = GetStringOrNull(configuration, AwsEnvironmentVariables.SessionToken, "AWS:SessionToken");
        var dynamoServiceUrl = GetStringOrNull(configuration, AwsEnvironmentVariables.DynamoDbServiceUrl, "AWS:DynamoDB:ServiceUrl");
        var wsServiceUrl = GetString(configuration, AwsEnvironmentVariables.WebSocketServiceUrl, "AWS:WebSocket:ServiceUrl");
        var wsPublicUrl = GetString(configuration, AwsEnvironmentVariables.WebSocketPublicUrl, "AWS:WebSocket:PublicUrl");
        var s3BucketName = GetString(configuration, AwsEnvironmentVariables.S3BucketName, "AWS:S3:BucketName");

        return new AwsOptions(
            Region: region,
            AccessKey: accessKey,
            SecretKey: secretKey,
            SessionToken: sessionToken,
            DynamoDB: new DynamoDbOptions(dynamoServiceUrl),
            WebSocket: new WebSocketOptions(wsServiceUrl, wsPublicUrl),
            S3: new S3Options(s3BucketName)
        );
    }

    private static string GetString(IConfiguration configuration, string primaryKey, string secondaryKey)
    {
        return GetStringOrNull(configuration, primaryKey, secondaryKey)
            ?? throw new InvalidOperationException($"Configuração {primaryKey} ou {secondaryKey} não foi definida.");
    }

    private static string? GetStringOrNull(IConfiguration configuration, string primaryKey, string secondaryKey)
    {
        return configuration[primaryKey] ?? configuration[secondaryKey];
    }
}
