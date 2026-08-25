import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class WsConnectionState {}

class WsConnectionInitial extends WsConnectionState {}

class WsConnectionConnecting extends WsConnectionState {}

class WsConnectionConnected extends WsConnectionState {
  final Stream<dynamic> stream;
  final WebSocketSink sink;

  WsConnectionConnected({
    required this.stream,
    required this.sink,
  });
}

class WsConnectionDisconnected extends WsConnectionState {
  final String? reason;
  WsConnectionDisconnected({this.reason});
}

class ConnectionCubit extends Cubit<WsConnectionState> {
  WebSocketChannel? _channel;
  StreamSubscription? _statusSubscription;

  ConnectionCubit() : super(WsConnectionInitial());

  void connect(String webSocketUrl) {
    if (state is WsConnectionConnected || state is WsConnectionConnecting) return;

    emit(WsConnectionConnecting());

    try {
      final channel = WebSocketChannel.connect(Uri.parse(webSocketUrl));
      _channel = channel;

      final broadcastStream = channel.stream.asBroadcastStream();

      _statusSubscription?.cancel();
      _statusSubscription = broadcastStream.listen(
        (_) {},
        onError: (_) {
          _handleDisconnection('Erro na conexão WebSocket.');
        },
        onDone: () {
          _handleDisconnection('Conexão encerrada.');
        },
        cancelOnError: true,
      );

      emit(WsConnectionConnected(
        stream: broadcastStream,
        sink: channel.sink,
      ));
    } catch (_) {
      _handleDisconnection('Falha ao conectar no WebSocket.');
    }
  }

  void _handleDisconnection(String reason) {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _channel = null;

    emit(WsConnectionDisconnected(reason: reason));
  }

  void disconnect() {
    _statusSubscription?.cancel();
    _statusSubscription = null;

    _channel?.sink.close();
    _channel = null;

    emit(WsConnectionDisconnected());
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _channel?.sink.close();
    return super.close();
  }
}
