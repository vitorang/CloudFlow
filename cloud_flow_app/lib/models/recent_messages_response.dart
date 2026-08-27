import 'package:cloud_flow_app/models/message_item.dart';

class RecentMessagesResponse {
  final List<MessageItem> messages;
  final bool hasPreviousMessages;

  const RecentMessagesResponse({
    required this.messages,
    required this.hasPreviousMessages,
  });

  factory RecentMessagesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['messages'];
    final messages = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => MessageItem.fromJson(item))
            .toList()
        : <MessageItem>[];

    return RecentMessagesResponse(
      messages: messages,
      hasPreviousMessages: json['hasPreviousMessages'] as bool? ?? false,
    );
  }
}
