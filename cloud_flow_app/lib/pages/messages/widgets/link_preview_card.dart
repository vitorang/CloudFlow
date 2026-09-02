import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreviewCard extends StatefulWidget {
  final String url;

  const LinkPreviewCard({super.key, required this.url});

  static const Duration _timeoutDuration = Duration(seconds: 5);
  static final Map<String, Metadata> _cache = {};
  static final Set<String> _failedUrls = {};

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late Future<Metadata?> _metadataFuture;

  @override
  void initState() {
    super.initState();
    _metadataFuture = _loadMetadata();
  }

  @override
  void didUpdateWidget(covariant LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _metadataFuture = _loadMetadata();
    }
  }

  Future<Metadata?> _loadMetadata() async {
    if (LinkPreviewCard._failedUrls.contains(widget.url)) {
      return null;
    }

    if (LinkPreviewCard._cache.containsKey(widget.url)) {
      return LinkPreviewCard._cache[widget.url];
    }

    try {
      final metadata = await AnyLinkPreview.getMetadata(
        link: widget.url,
        cache: const Duration(days: 7),
      ).timeout(LinkPreviewCard._timeoutDuration);

      if (metadata == null || (metadata.title == null && metadata.image == null)) {
        LinkPreviewCard._failedUrls.add(widget.url);
        return null;
      }

      LinkPreviewCard._cache[widget.url] = metadata;
      return metadata;
    } catch (_) {
      LinkPreviewCard._failedUrls.add(widget.url);
      return null;
    }
  }

  void _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (LinkPreviewCard._failedUrls.contains(widget.url)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return FutureBuilder<Metadata?>(
      future: _metadataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 90,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
              ),
            ),
          );
        }

        final metadata = snapshot.data;
        if (metadata == null) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: () => _openUrl(widget.url),
              child: SizedBox(
                height: 90,
                child: Row(
                  children: [
                    if (metadata.image != null && metadata.image!.isNotEmpty)
                      Image.network(
                        metadata.image!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (metadata.title != null && metadata.title!.isNotEmpty)
                              Text(
                                metadata.title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            if (metadata.desc != null && metadata.desc!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                metadata.desc!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
