import 'dart:convert';
import 'package:cloud_flow_app/enums/message_type.dart';
import 'package:cloud_flow_app/extensions/http_response_extensions.dart';
import 'package:http/http.dart' as http;

class MessagesService {
  final http.Client _client;

  MessagesService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> sendMessage({
    required String apiUrl,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    final uri = Uri.parse('$apiUrl/api/messages');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'type': type.value,
      }),
    );

    if (!response.isSuccess) {
      throw Exception('Falha ao enviar mensagem: status ${response.statusCode}');
    }
  }
}
