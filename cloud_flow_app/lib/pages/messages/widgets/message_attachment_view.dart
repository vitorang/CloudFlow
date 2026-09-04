import 'package:cloud_flow_app/constants/media_formats.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageAttachmentView extends StatelessWidget {
  final String attachmentUrl;
  final String? thumbnailUrl;

  const MessageAttachmentView({super.key, required this.attachmentUrl, this.thumbnailUrl});

  Future<void> _openAttachment() async {
    final uri = Uri.tryParse(attachmentUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasThumbnail = thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

    if (hasThumbnail) {
      final isVideo = MediaFormats.isVideoUrl(attachmentUrl);

      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: _openAttachment,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(child: Icon(Symbols.broken_image, color: theme.colorScheme.outline)),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Center(
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  },
                ),
                if (isVideo) const _VideoPlayBadge(),
              ],
            ),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Symbols.attach_file, size: 18),
      label: const Text('Abrir anexo'),
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: _openAttachment,
    );
  }
}

class _VideoPlayBadge extends StatelessWidget {
  const _VideoPlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
      ),
      child: const Icon(Symbols.play_arrow, size: 32, color: Colors.white, fill: 1),
    );
  }
}
