namespace CloudFlow.Infrastructure.Aws.Constants;

public static class AwsEnvironmentVariables
{
    public const string Region = "AWS_REGION";
    public const string AccessKey = "AWS_ACCESS_KEY_ID";
    public const string SecretKey = "AWS_SECRET_ACCESS_KEY";
    public const string SessionToken = "AWS_SESSION_TOKEN";

    public const string DynamoDbServiceUrl = "AWS_DYNAMODB_SERVICE_URL";

    public const string WebSocketServiceUrl = "AWS_WEBSOCKET_SERVICE_URL";
    public const string WebSocketPublicUrl = "AWS_WEBSOCKET_PUBLIC_URL";

    public const string S3BucketName = "AWS_S3_BUCKET_NAME";

    public const string SnsMessagesTopicArn = "AWS_SNS_MESSAGES_TOPIC_ARN";
    public const string SnsUsersTopicArn = "AWS_SNS_USERS_TOPIC_ARN";
}
