import 'dart:math';
import 'package:cloud_flow_app/models/message_item.dart';
import 'package:cloud_flow_app/pages/messages/widgets/link_preview_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

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

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildTextWithLinks(BuildContext context, ThemeData theme, List<String> extractedUrls) {
    if (extractedUrls.isEmpty) {
      return SelectableText(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, height: 1.45),
      );
    }

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in _urlRegex.allMatches(message.text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: message.text.substring(lastIndex, match.start),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, height: 1.45),
          ),
        );
      }

      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary,
            height: 1.45,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < message.text.length) {
      spans.add(
        TextSpan(
          text: message.text.substring(lastIndex),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface, height: 1.45),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorTheme = _getAuthorTheme(message.author);

    final extractedUrls = _urlRegex
        .allMatches(message.text)
        .map((m) => m.group(0)!)
        .toList();

    return InkWell(
      onTap: isSelectionMode ? onToggleSelect : null,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 4),
                  _buildTextWithLinks(context, theme, extractedUrls),
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
