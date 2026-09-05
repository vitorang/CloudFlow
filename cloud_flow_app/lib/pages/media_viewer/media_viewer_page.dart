import 'package:cloud_flow_app/constants/media_formats.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaViewerPage extends StatefulWidget {
  final String mediaUrl;

  const MediaViewerPage({super.key, required this.mediaUrl});

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  Player? _player;
  VideoController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = MediaFormats.isVideoUrl(widget.mediaUrl);
    if (_isVideo) {
      _player = Player();
      _videoController = VideoController(_player!);
      _player!.open(Media(widget.mediaUrl));
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _downloadFile() async {
    final uri = Uri.tryParse(widget.mediaUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back, color: Colors.white),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.download, color: Colors.white),
            tooltip: 'Baixar',
            onPressed: _downloadFile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(child: _isVideo ? _buildVideoViewer() : _buildImageViewer()),
    );
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: NetworkImage(widget.mediaUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) {
        final progress = event == null || event.expectedTotalBytes == null
            ? null
            : event.cumulativeBytesLoaded / event.expectedTotalBytes!;

        return Center(
          child: CircularProgressIndicator(value: progress, color: Colors.white, strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.broken_image, color: Colors.white54, size: 56),
            const SizedBox(height: 12),
            const Text('Não foi possível carregar a imagem', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloadFile,
              icon: const Icon(Symbols.download, size: 18),
              label: const Text('Tentar baixar arquivo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoViewer() {
    if (_videoController == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    return Center(
      child: Video(controller: _videoController!),
    );
  }
}
