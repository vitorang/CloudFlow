namespace CloudFlow.Infrastructure.Aws.Constants;

public static class AwsEnvironmentVariables
{
    public const string WebSocketServiceUrl = "AWS_WEBSOCKET_SERVICE_URL";
    public const string SnsMessagesTopicArn = "AWS_SNS_MESSAGES_TOPIC_ARN";
    public const string SnsUsersTopicArn = "AWS_SNS_USERS_TOPIC_ARN";
    public const string S3BucketName = "AWS_S3_BUCKET_NAME";
    public const string Region = "AWS_REGION";
}
