import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/cubits/messages_list_cubit.dart';
import 'package:cloud_flow_app/pages/connect/connect_page.dart';
import 'package:cloud_flow_app/pages/messages/widgets/message_input_field.dart';
import 'package:cloud_flow_app/pages/messages/widgets/messages_list.dart';
import 'package:cloud_flow_app/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final connectionCubit = ConnectionCubit();
        final configState = context.read<ConfigCubit>().state;
        if (configState is ConfigLoaded) {
          connectionCubit.connect(configState.config.webSocketUrl);
        }
        return connectionCubit;
      },
      child: BlocProvider(
        create: (context) {
          final messagesListCubit = MessagesListCubit(connectionCubit: context.read<ConnectionCubit>());
          final configState = context.read<ConfigCubit>().state;
          if (configState is ConfigLoaded) {
            messagesListCubit.loadRecentMessages(configState.config.apiUrl);
          }
          return messagesListCubit;
        },
        child: const _MessagesView(),
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, WsConnectionState>(
      listener: (context, connectionState) {
        if (connectionState is WsConnectionDisconnected) {
          context.read<ConfigCubit>().reset();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ConnectPage()));
        }
      },
      child: BlocBuilder<MessagesListCubit, MessagesListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: state.isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      tooltip: 'Cancelar seleção',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<MessagesListCubit>().clearSelection();
                      },
                    ),
                    title: Text(
                      '${state.selectedMessageIds.length} selecionada(s)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Excluir selecionadas',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: state.selectedMessageIds.isEmpty
                            ? null
                            : () {
                                final configState = context.read<ConfigCubit>().state;
                                if (configState is ConfigLoaded) {
                                  context
                                      .read<MessagesListCubit>()
                                      .deleteSelectedMessages(configState.config.apiUrl);
                                }
                              },
                      ),
                    ],
                  )
                : AppBar(
                    title: const CloudFlowBrand(fontSize: 22),
                    actions: [
                      IconButton(
                        tooltip: 'Selecionar mensagens',
                        icon: const Icon(Icons.checklist_outlined),
                        onPressed: state.messages.isEmpty
                            ? null
                            : () {
                                context.read<MessagesListCubit>().toggleSelection(state.messages.first.id);
                              },
                      ),
                      IconButton(
                        tooltip: 'Desconectar',
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          context.read<ConnectionCubit>().disconnect();
                        },
                      ),
                    ],
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  if (!state.isSelectionMode) const MessageInputField(),
                  const Expanded(child: MessagesList()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
