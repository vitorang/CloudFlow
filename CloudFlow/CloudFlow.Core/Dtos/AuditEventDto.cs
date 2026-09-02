namespace CloudFlow.Core.Dtos;

public record AuditEventDto(
    string TopicName,
    string EventType,
    DateTime OccurredAt,
    object Payload
);
