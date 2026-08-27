class WebSocketMessage {
  final String event;
  final dynamic _data;

  WebSocketMessage.fromJson(Map<String, dynamic> json)
    : event = _validateEvent(json['event']),
      _data = json['data'];

  static String _validateEvent(dynamic event) {
    if (event is! String || event.trim().isEmpty) {
      throw const FormatException(
        'Evento WebSocket inválido ou ausente no JSON.',
      );
    }
    return event;
  }

  T getData<T>([T Function(Map<String, dynamic> json)? fromJson]) {
    if (fromJson != null) {
      if (_data is! Map<String, dynamic>) {
        throw FormatException(
          'Dados inválidos para conversão em objeto: $_data',
        );
      }
      return fromJson(_data);
    }

    return _data as T;
  }
}
