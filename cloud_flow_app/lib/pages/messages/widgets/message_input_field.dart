import 'dart:async';
import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/extensions/context_extensions.dart';
import 'package:cloud_flow_app/services/messages_service.dart';
import 'package:cloud_flow_app/services/thumbnail_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class _SelectedAttachment {
  final String name;
  final String extension;
  final Uint8List bytes;
  final String? path;
  final int size;

  const _SelectedAttachment({
    required this.name,
    required this.extension,
    required this.bytes,
    this.path,
    required this.size,
  });
}

class MessageInputField extends StatefulWidget {
  const MessageInputField({super.key});

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MessagesService _messagesService = MessagesService();
  final ThumbnailService _thumbnailService = ThumbnailService();

  bool _isSending = false;
  String _uploadStatus = '';
  bool _showUploadStatus = false;
  Timer? _statusTimer;
  _SelectedAttachment? _selectedAttachment;
  int? _selectedExpiresInHours;

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    if (_isSending) return;

    if (_selectedAttachment != null) {
      setState(() => _selectedAttachment = null);
      return;
    }

    try {
      final files = await FilePicker.pickFiles(type: FileType.any);

      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) context.showSnackBar('Não foi possível ler o arquivo selecionado.');
        return;
      }

      final fileSize = await file.length();
      final fileName = file.name;
      final extension = file.extension ?? (fileName.contains('.') ? fileName.split('.').last : '');

      setState(() {
        _selectedAttachment = _SelectedAttachment(
          name: fileName,
          extension: extension,
          bytes: bytes,
          path: file.path,
          size: fileSize,
        );
      });
    } catch (_) {
      if (mounted) context.showSnackBar('Erro ao selecionar arquivo.');
    }
  }

  Future<void> _onSendMessage() async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedAttachment == null) || _isSending) return;

    final configState = context.read<ConfigCubit>().state;
    if (configState is! ConfigLoaded) return;

    final connectionState = context.read<ConnectionCubit>().state;
    if (connectionState is! WsConnectionConnected) return;

    final attachmentToUpload = _selectedAttachment;
    final textToSend = text;

    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _isSending) {
        setState(() => _showUploadStatus = true);
      }
    });

    setState(() {
      _isSending = true;
      _showUploadStatus = false;
      _uploadStatus = attachmentToUpload != null ? 'Preparando anexo...' : 'Enviando...';
    });

    try {
      String? attachmentKey;
      String? thumbnailKey;

      if (attachmentToUpload != null) {
        final canGenerate = _thumbnailService.canGenerateThumbnail(attachmentToUpload.extension);

        setState(() => _uploadStatus = 'Obtendo permissão de envio...');
        final uploadUrlsResponse = await _messagesService.getUploadUrls(
          apiUrl: configState.config.apiUrl,
          fileExtension: attachmentToUpload.extension,
          hasThumbnail: canGenerate,
        );
        attachmentKey = uploadUrlsResponse.attachment.key;

        setState(() => _uploadStatus = 'Enviando arquivo...');
        await _messagesService.uploadBytesToS3(
          uploadUrl: uploadUrlsResponse.attachment.uploadUrl,
          formFields: uploadUrlsResponse.attachment.formFields,
          bytes: attachmentToUpload.bytes,
          filename: attachmentToUpload.name,
        );

        if (uploadUrlsResponse.thumbnail != null) {
          setState(() => _uploadStatus = 'Gerando miniatura...');
          final thumbnailTarget = uploadUrlsResponse.thumbnail!;
          final thumbnailBytes = await _thumbnailService.generateThumbnail(
            fileBytes: attachmentToUpload.bytes,
            fileExtension: attachmentToUpload.extension,
            filePath: attachmentToUpload.path,
            maxWidth: thumbnailTarget.maxWidthPx,
            maxHeight: thumbnailTarget.maxHeightPx,
            quality: 85,
          );

          if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
            setState(() => _uploadStatus = 'Enviando miniatura...');
            await _messagesService.uploadBytesToS3(
              uploadUrl: thumbnailTarget.uploadUrl,
              formFields: thumbnailTarget.formFields,
              bytes: thumbnailBytes,
              filename: 'thumbnail.webp',
            );
            thumbnailKey = thumbnailTarget.key;
          }
        }
      }

      setState(() => _uploadStatus = 'Publicando mensagem...');
      await _messagesService.sendMessage(
        apiUrl: configState.config.apiUrl,
        author: configState.config.username,
        text: textToSend,
        attachmentKey: attachmentKey,
        thumbnailKey: thumbnailKey,
        expiresInHours: _selectedExpiresInHours,
      );

      if (mounted) {
        _messageController.clear();
        setState(() => _selectedAttachment = null);
      }
    } catch (_) {
      if (mounted) context.showSnackBar('Erro ao enviar mensagem.');
    } finally {
      _statusTimer?.cancel();
      _statusTimer = null;
      if (mounted) {
        setState(() {
          _isSending = false;
          _showUploadStatus = false;
          _uploadStatus = '';
        });
        _focusNode.requestFocus();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isHardwareKeyboard =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (!isHardwareKeyboard) return KeyEventResult.ignored;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if (isEnter) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

      if (!isShiftPressed) {
        _onSendMessage();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  String _getExpirationTooltip() {
    return switch (_selectedExpiresInHours) {
      1 => 'Expira em 1 hora',
      24 => 'Expira em 1 dia',
      168 => 'Expira em 1 semana',
      _ => 'Definir expiração',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ConnectionCubit, WsConnectionState>(
      builder: (context, connectionState) {
        final isConnected = connectionState is WsConnectionConnected;
        final hasExpiration = _selectedExpiresInHours != null;
        final hasAttachment = _selectedAttachment != null;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: hasAttachment ? 'Descartar anexo' : 'Anexar arquivo',
                          icon: Icon(
                            hasAttachment ? Symbols.attach_file_off : Symbols.attach_file,
                            color: hasAttachment ? theme.colorScheme.error : null,
                          ),
                          onPressed: (isConnected && !_isSending) ? _pickAttachment : null,
                        ),
                        Expanded(
                          child: Focus(
                            onKeyEvent: _handleKeyEvent,
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              readOnly: !isConnected || _isSending,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText: _isSending
                                    ? 'Enviando...'
                                    : isConnected
                                    ? 'Digite uma mensagem...'
                                    : 'Conectando ao servidor...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<int>(
                          tooltip: _getExpirationTooltip(),
                          enabled: isConnected && !_isSending,
                          icon: Icon(
                            hasExpiration ? Symbols.timer : Symbols.timer,
                            color: hasExpiration ? Colors.orange : theme.colorScheme.onSurfaceVariant,
                          ),
                          onSelected: (hours) {
                            setState(() => _selectedExpiresInHours = hours > 0 ? hours : null);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<int>(
                              value: 0,
                              child: Text(
                                'Nenhum',
                                style: TextStyle(
                                  color: _selectedExpiresInHours == null ? theme.colorScheme.primary : null,
                                  fontWeight: _selectedExpiresInHours == null ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 1,
                              child: Text(
                                '1 hora',
                                style: TextStyle(
                                  color: _selectedExpiresInHours == 1 ? theme.colorScheme.primary : null,
                                  fontWeight: _selectedExpiresInHours == 1 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 24,
                              child: Text(
                                '1 dia',
                                style: TextStyle(
                                  color: _selectedExpiresInHours == 24 ? theme.colorScheme.primary : null,
                                  fontWeight: _selectedExpiresInHours == 24 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            PopupMenuItem<int>(
                              value: 168,
                              child: Text(
                                '1 semana',
                                style: TextStyle(
                                  color: _selectedExpiresInHours == 168 ? theme.colorScheme.primary : null,
                                  fontWeight: _selectedExpiresInHours == 168 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Enviar mensagem',
                          icon: _isSending
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                                )
                              : Icon(
                                  Symbols.send,
                                  color: (isConnected && !_isSending)
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                                ),
                          onPressed: (isConnected && !_isSending) ? _onSendMessage : null,
                        ),
                      ],
                    ),
                  ),
                  if (!_isSending && hasAttachment)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 14, right: 14),
                      child: Row(
                        children: [
                          Icon(
                            _thumbnailService.isImage(_selectedAttachment!.extension)
                                ? Symbols.image
                                : _thumbnailService.isVideo(_selectedAttachment!.extension)
                                ? Symbols.videocam
                                : Symbols.draft,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedAttachment!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isSending && _showUploadStatus && _uploadStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 14, right: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _uploadStatus,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
