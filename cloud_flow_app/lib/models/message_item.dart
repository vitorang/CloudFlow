import 'package:cloud_flow_app/enums/message_type.dart';

class MessageItem {
  final String id;
  final String author;
  final String text;
  final MessageType type;
  final DateTime createdAt;

  const MessageItem({
    required this.id,
    required this.author,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as int? ?? 1;
    final type = MessageType.values.firstWhere(
      (element) => element.value == typeValue,
      orElse: () => MessageType.text,
    );

    return MessageItem(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      text: json['text'] as String? ?? '',
      type: type,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
