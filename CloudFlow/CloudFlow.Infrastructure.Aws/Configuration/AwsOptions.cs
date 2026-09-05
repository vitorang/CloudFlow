namespace CloudFlow.Infrastructure.Aws.Configuration;

public record DynamoDbOptions(
    string? ServiceUrl
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
    string? AccessKey,
    string? SecretKey,
    string? SessionToken = null,
    DynamoDbOptions DynamoDB = null!,
    WebSocketOptions WebSocket = null!,
    S3Options S3 = null!
);
