import 'dart:math';
import 'package:cloud_flow_app/models/message_item.dart';
import 'package:cloud_flow_app/pages/messages/widgets/link_preview_card.dart';
import 'package:cloud_flow_app/pages/messages/widgets/message_attachment_view.dart';
import 'package:cloud_flow_app/pages/messages/widgets/message_text_with_links.dart';
import 'package:flutter/material.dart';

class _AuthorTheme {
  final IconData icon;
  final Color color;

  const _AuthorTheme(this.icon, this.color);
}

_AuthorTheme _getAuthorTheme(String author) {
  const icons = [
    Icons.wb_sunny_outlined,
    Icons.cloud_outlined,
    Icons.star_outline,
    Icons.ac_unit,
    Icons.bolt_outlined,
    Icons.dark_mode_outlined,
    Icons.cyclone,
    Icons.water_drop_outlined,
  ];

  const colors = [Colors.red, Colors.orange, Colors.green, Colors.blue, Colors.purpleAccent, Colors.lime, Colors.grey];

  final trimmed = author.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return const _AuthorTheme(Icons.cloud_outlined, Colors.grey);
  }

  final seed = trimmed.codeUnits.fold<int>(0, (prev, elem) {
    final mixed = ((prev << 2) ^ elem) & 0xFFFFFFFF;
    return mixed;
  });

  final random = Random(seed);

  final iconIndex = random.nextInt(icons.length);
  final colorIndex = random.nextInt(colors.length);

  return _AuthorTheme(icons[iconIndex], colors[colorIndex]);
}

class MessageCard extends StatelessWidget {
  final MessageItem message;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onLongPress;

  const MessageCard({
    super.key,
    required this.message,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.onLongPress,
  });

  String _formatTimestamp(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final isToday = localTime.year == now.year && localTime.month == now.month && localTime.day == now.day;

    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');

    if (isToday) {
      return '$hour:$minute';
    }

    final day = localTime.day.toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');
    final year = localTime.year;

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorTheme = _getAuthorTheme(message.author);

    final hasText = message.text.trim().isNotEmpty;
    final extractedUrls = MessageTextWithLinks.extractUrls(message.text);

    return InkWell(
      onTap: isSelectionMode ? onToggleSelect : null,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      mouseCursor: isSelectionMode ? SystemMouseCursors.click : MouseCursor.defer,
      hoverColor: isSelectionMode ? null : Colors.transparent,
      splashColor: isSelectionMode ? null : Colors.transparent,
      highlightColor: isSelectionMode ? null : Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectionMode)
              IconButton(
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                  size: 24,
                ),
                onPressed: onToggleSelect,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: authorTheme.color.withValues(alpha: 0.15),
                child: Icon(authorTheme.icon, size: 20, color: authorTheme.color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.author.isNotEmpty ? message.author : 'Anônimo',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${_formatTimestamp(message.createdAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
                      ),
                      if (message.expiresAt != null) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Expira em ${_formatTimestamp(DateTime.fromMillisecondsSinceEpoch(message.expiresAt! * 1000))}',
                          child: Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: Colors.orange.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasText) ...[
                    const SizedBox(height: 4),
                    MessageTextWithLinks(
                      text: message.text,
                      extractedUrls: extractedUrls,
                    ),
                  ],
                  if (message.attachmentUrl != null) ...[
                    SizedBox(height: hasText ? 8 : 4),
                    MessageAttachmentView(
                      attachmentUrl: message.attachmentUrl!,
                      thumbnailUrl: message.thumbnailUrl,
                    ),
                  ],
                  if (extractedUrls.length == 1) ...[
                    const SizedBox(height: 10),
                    LinkPreviewCard(url: extractedUrls.first),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
