import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/cubits/messages_list_cubit.dart';
import 'package:cloud_flow_app/pages/messages/widgets/message_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesList extends StatefulWidget {
  const MessagesList({super.key});

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
  final ScrollController _scrollController = ScrollController();
  bool _wasAtBottom = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return (maxScroll - currentScroll) <= 60.0;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<MessagesListCubit, MessagesListState>(
      listenWhen: (previous, current) => current is MessagesListLoaded,
      listener: (context, state) {
        if (_wasAtBottom) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is MessagesListLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is MessagesListError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {
                    final configState = context.read<ConfigCubit>().state;
                    if (configState is ConfigLoaded) {
                      context
                          .read<MessagesListCubit>()
                          .loadRecentMessages(configState.config.apiUrl);
                    }
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (state is MessagesListLoaded) {
          if (state.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma mensagem ainda',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _wasAtBottom = _isAtBottom();
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                return MessageCard(message: message);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
