import 'dart:async';
import 'dart:convert';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/models/message_item.dart';
import 'package:cloud_flow_app/services/messages_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class MessagesListState {}

class MessagesListInitial extends MessagesListState {}

class MessagesListLoading extends MessagesListState {}

class MessagesListLoaded extends MessagesListState {
  final List<MessageItem> messages;
  MessagesListLoaded(this.messages);
}

class MessagesListError extends MessagesListState {
  final String message;
  MessagesListError(this.message);
}

class MessagesListCubit extends Cubit<MessagesListState> {
  final MessagesService _messagesService;
  final ConnectionCubit connectionCubit;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _webSocketStreamSubscription;

  MessagesListCubit({
    required this.connectionCubit,
    MessagesService? messagesService,
  }) : _messagesService = messagesService ?? MessagesService(),
       super(MessagesListInitial()) {
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
            final newMessage = MessageItem.fromJson(decoded);
            _addMessage(newMessage);
          }
        } catch (_) {}
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> loadRecentMessages(String apiUrl) async {
    emit(MessagesListLoading());

    try {
      final messages = await _messagesService.getRecentMessages(apiUrl: apiUrl);
      emit(MessagesListLoaded(messages));
    } catch (_) {
      emit(
        MessagesListError('Não foi possível carregar as mensagens recentes.'),
      );
    }
  }

  void _addMessage(MessageItem message) {
    final currentList = state is MessagesListLoaded
        ? List<MessageItem>.from((state as MessagesListLoaded).messages)
        : <MessageItem>[];

    currentList.removeWhere((item) => item.id == message.id);
    currentList.add(message);

    emit(MessagesListLoaded(currentList));
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _webSocketStreamSubscription?.cancel();
    return super.close();
  }
}
