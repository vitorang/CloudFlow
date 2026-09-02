import 'dart:async';
import 'dart:convert';
import 'package:cloud_flow_app/constants/web_socket_events.dart';
import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:cloud_flow_app/models/audit_event_item.dart';
import 'package:cloud_flow_app/models/web_socket_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuditEventsState {
  final List<AuditEventItem> events;

  const AuditEventsState({
    this.events = const [],
  });

  AuditEventsState copyWith({
    List<AuditEventItem>? events,
  }) {
    return AuditEventsState(
      events: events ?? this.events,
    );
  }
}

class AuditEventsCubit extends Cubit<AuditEventsState> {
  final ConnectionCubit connectionCubit;
  static const int _maxEvents = 100;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _webSocketStreamSubscription;

  AuditEventsCubit({required this.connectionCubit})
      : super(const AuditEventsState()) {
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
            if (webSocketMessage.event == WebSocketEvents.auditEvent) {
              final newEvent = webSocketMessage.getData<AuditEventItem>(
                AuditEventItem.fromJson,
              );
              _addEvent(newEvent);
            }
          }
        } catch (_) {}
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _addEvent(AuditEventItem event) {
    final updatedList = [event, ...state.events];
    if (updatedList.length > _maxEvents) {
      updatedList.removeRange(_maxEvents, updatedList.length);
    }
    emit(state.copyWith(events: updatedList));
  }

  void clearEvents() {
    emit(const AuditEventsState(events: []));
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _webSocketStreamSubscription?.cancel();
    return super.close();
  }
}
