namespace CloudFlow.Infrastructure.Aws.Configuration;

public record DynamoDbOptions(
    string ServiceUrl
);

public record WebSocketOptions(
    string ServiceUrl,
    string PublicUrl
);

public record S3Options(
    string BucketName
);

public record AwsOptions(
    string Region,
    string AccessKey,
    string SecretKey,
    DynamoDbOptions DynamoDB,
    WebSocketOptions WebSocket,
    S3Options S3
);
