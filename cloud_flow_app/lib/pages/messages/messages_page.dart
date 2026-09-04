import 'package:cloud_flow_app/cubits/audit_events_cubit.dart';
import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/cubits/messages_list_cubit.dart';
import 'package:cloud_flow_app/extensions/context_extensions.dart';
import 'package:cloud_flow_app/pages/connect/connect_page.dart';
import 'package:cloud_flow_app/pages/messages/widgets/audit_events_drawer.dart';
import 'package:cloud_flow_app/pages/messages/widgets/message_input_field.dart';
import 'package:cloud_flow_app/pages/messages/widgets/messages_list.dart';
import 'package:cloud_flow_app/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final messagesListCubit = MessagesListCubit(connectionCubit: context.read<ConnectionCubit>());
              final configState = context.read<ConfigCubit>().state;
              if (configState is ConfigLoaded) {
                messagesListCubit.loadRecentMessages(configState.config.apiUrl);
              }
              return messagesListCubit;
            },
          ),
          BlocProvider(create: (context) => AuditEventsCubit(connectionCubit: context.read<ConnectionCubit>())),
        ],
        child: const _MessagesView(),
      ),
    );
  }
}

class _MessagesView extends StatefulWidget {
  const _MessagesView();

  @override
  State<_MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<_MessagesView> {
  static const double _largeScreenBreakpoint = 900;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isAuditPanelOpen = false;

  void _toggleAuditPanel(bool isLargeScreen) {
    if (isLargeScreen) {
      setState(() {
        _isAuditPanelOpen = !_isAuditPanelOpen;
      });
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = screenWidth >= _largeScreenBreakpoint;

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
            key: _scaffoldKey,
            endDrawer: !isLargeScreen
                ? Drawer(
                    width: screenWidth < 380 ? screenWidth : 380,
                    child: const SafeArea(child: AuditEventsDrawer()),
                  )
                : null,
            appBar: state.isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      tooltip: 'Cancelar seleção',
                      icon: const Icon(Symbols.close),
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
                        icon: const Icon(Symbols.delete, color: Colors.redAccent),
                        onPressed: state.selectedMessageIds.isEmpty
                            ? null
                            : () async {
                                final configState = context.read<ConfigCubit>().state;
                                if (configState is ConfigLoaded) {
                                  try {
                                    await context.read<MessagesListCubit>().deleteSelectedMessages(
                                      configState.config.apiUrl,
                                    );
                                  } catch (_) {
                                    if (context.mounted) context.showSnackBar('Erro ao excluir mensagem.');
                                  }
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
                        icon: const Icon(Symbols.select_all),
                        onPressed: state.messages.isEmpty
                            ? null
                            : () {
                                context.read<MessagesListCubit>().toggleSelection(state.messages.first.id);
                              },
                      ),
                      IconButton(
                        tooltip: isLargeScreen
                            ? (_isAuditPanelOpen ? 'Ocultar auditoria' : 'Exibir auditoria')
                            : 'Auditoria de eventos',
                        icon: Icon(Symbols.fact_check, fill: _isAuditPanelOpen && isLargeScreen ? 1 : 0),
                        onPressed: () => _toggleAuditPanel(isLargeScreen),
                      ),
                      IconButton(
                        tooltip: 'Desconectar',
                        icon: const Icon(Symbols.logout),
                        onPressed: () {
                          context.read<ConnectionCubit>().disconnect();
                        },
                      ),
                    ],
                  ),
            body: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (!state.isSelectionMode) const MessageInputField(),
                        const Expanded(child: MessagesList()),
                      ],
                    ),
                  ),
                  if (isLargeScreen && _isAuditPanelOpen)
                    AuditEventsDrawer(onClose: () => setState(() => _isAuditPanelOpen = false)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
