import 'dart:async';
import 'dart:convert';
import 'package:cloud_flow_app/constants/web_socket_events.dart';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/models/message_item.dart';
import 'package:cloud_flow_app/models/web_socket_message.dart';
import 'package:cloud_flow_app/services/messages_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessagesListState {
  final List<MessageItem> messages;
  final bool hasPreviousMessages;
  final bool isLoading;
  final String? errorMessage;

  const MessagesListState({
    this.messages = const [],
    this.hasPreviousMessages = false,
    this.isLoading = false,
    this.errorMessage,
  });

  MessagesListState copyWith({
    List<MessageItem>? messages,
    bool? hasPreviousMessages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MessagesListState(
      messages: messages ?? this.messages,
      hasPreviousMessages: hasPreviousMessages ?? this.hasPreviousMessages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MessagesListCubit extends Cubit<MessagesListState> {
  final MessagesService _messagesService;
  final ConnectionCubit connectionCubit;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _webSocketStreamSubscription;

  MessagesListCubit({required this.connectionCubit, MessagesService? messagesService})
    : _messagesService = messagesService ?? MessagesService(),
      super(const MessagesListState()) {
    _connectionSubscription = connectionCubit.stream.listen((connectionState) {
      if (connectionState is WsConnectionConnected) {
        _listenToWebSocket(connectionState);
      } else {
        _webSocketStreamSubscription?.cancel();
        _webSocketStreamSubscription = null;
      }
    });

    if (connectionCubit.state is WsConnectionConnected) {
      _listenToWebSocket(connectionCubit.state as WsConnectionConnected);
    }
  }

  void _listenToWebSocket(WsConnectionConnected connectedState) {
    _webSocketStreamSubscription?.cancel();
    _webSocketStreamSubscription = connectedState.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String);
          if (decoded is Map<String, dynamic>) {
            final webSocketMessage = WebSocketMessage.fromJson(decoded);
            final event = webSocketMessage.event;

            if (event == WebSocketEvents.messageCreated) {
              final newMessage = webSocketMessage.getData<MessageItem>(MessageItem.fromJson);
              _addMessage(newMessage);
            }
          }
        } catch (_) {}
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> loadRecentMessages(String apiUrl, {DateTime? before}) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _messagesService.getRecentMessages(apiUrl: apiUrl, before: before);
      emit(state.copyWith(
        messages: response.messages,
        hasPreviousMessages: response.hasPreviousMessages,
        isLoading: false,
      ));
    } catch (e) {
      print('Erro ao carregar mensagens recentes: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar as mensagens recentes.',
      ));
    }
  }

  Future<void> loadPreviousMessages(String apiUrl) async {
    if (!state.hasPreviousMessages || state.isLoading || state.messages.isEmpty) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final oldestMessageDate = state.messages.last.createdAt;
      final response = await _messagesService.getRecentMessages(
        apiUrl: apiUrl,
        before: oldestMessageDate,
      );

      final combined = [...state.messages, ...response.messages];
      final seenIds = <String>{};
      final deduplicated = combined.where((m) => seenIds.add(m.id)).toList();

      emit(state.copyWith(
        messages: deduplicated,
        hasPreviousMessages: response.hasPreviousMessages,
        isLoading: false,
      ));
    } catch (e) {
      print('Erro ao carregar mensagens anteriores: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  void _addMessage(MessageItem message) {
    final currentList = List<MessageItem>.from(state.messages);
    currentList.removeWhere((item) => item.id == message.id);
    currentList.insert(0, message);

    emit(state.copyWith(messages: currentList));
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _webSocketStreamSubscription?.cancel();
    return super.close();
  }
}
