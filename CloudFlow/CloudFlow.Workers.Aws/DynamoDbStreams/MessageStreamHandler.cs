using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using CloudFlow.Core.Constants;
using CloudFlow.Core.Dtos;
using CloudFlow.Core.Enums;
using CloudFlow.Core.Interfaces.Services;

namespace CloudFlow.Workers.Aws.DynamoDbStreams;

public class MessageStreamHandler(IWebSocketNotificationService webSocketNotificationService)
{
    public async Task Handle(DynamoDBEvent dynamoEvent, ILambdaContext? context, CancellationToken cancellationToken)
    {
        foreach (var record in dynamoEvent.Records)
        {
            var task = record.EventName switch
            {
                "INSERT" => HandleCreated(record.Dynamodb.NewImage, cancellationToken),
                "MODIFY" => HandleUpdated(record.Dynamodb.NewImage, record.Dynamodb.OldImage, cancellationToken),
                "REMOVE" => HandleDeleted(record.Dynamodb.OldImage, cancellationToken),
                _ => Task.CompletedTask
            };

            await task;
        }
    }

    private async Task HandleCreated(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> newImage,
        CancellationToken cancellationToken)
    {
        var messageDto = TryGetMessageDto(newImage);
        if (messageDto == null)
            return;

        var webSocketMessage = new WebSocketMessageDto<MessageResponseDto>(WebSocketEvents.MessageCreated, messageDto);
        await webSocketNotificationService.Broadcast(webSocketMessage, cancellationToken);
    }

    private async Task HandleUpdated(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> newImage,
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> oldImage,
        CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
    }

    private async Task HandleDeleted(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> oldImage,
        CancellationToken cancellationToken)
    {
        await Task.CompletedTask;
    }

    private static MessageResponseDto? TryGetMessageDto(
        Dictionary<string, Amazon.Lambda.DynamoDBEvents.DynamoDBEvent.AttributeValue> image)
    {
        if (!image.TryGetValue("Id", out var idAttribute) ||
            !image.TryGetValue("Text", out var textAttribute) ||
            !image.TryGetValue("Type", out var typeAttribute) ||
            !image.TryGetValue("CreatedAt", out var createdAtAttribute))
            return null;

        return new MessageResponseDto(
            Id: idAttribute.S,
            Text: textAttribute.S,
            Type: (MessageType)int.Parse(typeAttribute.N),
            CreatedAt: DateTime.Parse(createdAtAttribute.S)
        );
    }
}
