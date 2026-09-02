class AuditEventItem {
  final String topicName;
  final String eventType;
  final DateTime occurredAt;
  final dynamic payload;

  AuditEventItem({
    required this.topicName,
    required this.eventType,
    required this.occurredAt,
    required this.payload,
  });

  factory AuditEventItem.fromJson(Map<String, dynamic> json) {
    return AuditEventItem(
      topicName: json['topicName'] as String? ?? 'Desconhecido',
      eventType: json['eventType'] as String? ?? 'Evento',
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : DateTime.now(),
      payload: json['payload'],
    );
  }
}
