using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Microsoft.Extensions.Hosting;

namespace CloudFlow.Infrastructure.Aws.Initializers;

public class DynamoDbTableInitializer(IAmazonDynamoDB dynamoClient, IHostEnvironment environment) : IHostedService
{
    private const string MessagesTableName = "Messages";

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        if (!environment.IsDevelopment())
        {
            return;
        }

        var tablesResponse = await dynamoClient.ListTablesAsync(cancellationToken);
        if (tablesResponse.TableNames.Contains(MessagesTableName))
        {
            return;
        }

        var request = new CreateTableRequest
        {
            TableName = MessagesTableName,
            AttributeDefinitions =
            [
                new AttributeDefinition
                {
                    AttributeName = "Id",
                    AttributeType = ScalarAttributeType.S
                }
            ],
            KeySchema =
            [
                new KeySchemaElement
                {
                    AttributeName = "Id",
                    KeyType = KeyType.HASH
                }
            ],
            BillingMode = BillingMode.PAY_PER_REQUEST
        };

        await dynamoClient.CreateTableAsync(request, cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
