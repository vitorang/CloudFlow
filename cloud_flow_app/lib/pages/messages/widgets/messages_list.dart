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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfNeedsMoreContent(MessagesListState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (!state.hasPreviousMessages || state.isLoading) return;

      if (_scrollController.position.maxScrollExtent <= 20.0) {
        final configState = context.read<ConfigCubit>().state;
        if (configState is ConfigLoaded) {
          context.read<MessagesListCubit>().loadPreviousMessages(configState.config.apiUrl);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<MessagesListCubit, MessagesListState>(
      listener: (context, state) {
        _checkIfNeedsMoreContent(state);
      },
      builder: (context, state) {
        if (state.messages.isEmpty && state.isLoading) {
          return const Column(children: [LinearProgressIndicator(minHeight: 2)]);
        }

        if (state.errorMessage != null && state.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(state.errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () {
                    final configState = context.read<ConfigCubit>().state;
                    if (configState is ConfigLoaded) {
                      context.read<MessagesListCubit>().loadRecentMessages(configState.config.apiUrl);
                    }
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (state.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma mensagem ainda',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (_scrollController.hasClients) {
                        final maxScroll = _scrollController.position.maxScrollExtent;
                        final currentScroll = _scrollController.offset;

                        if ((maxScroll - currentScroll) <= 100.0) {
                          if (state.hasPreviousMessages && !state.isLoading) {
                            final configState = context.read<ConfigCubit>().state;
                            if (configState is ConfigLoaded) {
                              context.read<MessagesListCubit>().loadPreviousMessages(configState.config.apiUrl);
                            }
                          }
                        }
                      }

                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isSelected = state.selectedMessageIds.contains(message.id);

                        return MessageCard(
                          key: ValueKey(message.id),
                          message: message,
                          isSelectionMode: state.isSelectionMode,
                          isSelected: isSelected,
                          onToggleSelect: () {
                            context.read<MessagesListCubit>().toggleSelection(message.id);
                          },
                          onLongPress: () {
                            context.read<MessagesListCubit>().startSelectionMode(message.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
