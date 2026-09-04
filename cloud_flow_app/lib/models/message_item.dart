class MessageItem {
  final String id;
  final String author;
  final String text;
  final String? attachmentUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final int? expiresAt;

  const MessageItem({
    required this.id,
    required this.author,
    required this.text,
    this.attachmentUrl,
    this.thumbnailUrl,
    required this.createdAt,
    this.expiresAt,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] as String? ?? '',
      author: json['author'] as String? ?? '',
      text: json['text'] as String? ?? '',
      attachmentUrl: json['attachmentUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] as int?,
    );
  }
}
