import 'dart:convert';
import 'package:cloud_flow_app/enums/message_type.dart';
import 'package:cloud_flow_app/extensions/http_response_extensions.dart';
import 'package:cloud_flow_app/models/recent_messages_response.dart';
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

  Future<RecentMessagesResponse> getRecentMessages({
    required String apiUrl,
    DateTime? before,
  }) async {
    final baseUri = Uri.parse('$apiUrl/api/messages');
    final uri = before != null
        ? baseUri.replace(queryParameters: {'before': before.toUtc().toIso8601String()})
        : baseUri;
    final response = await _client.get(uri);

    if (!response.isSuccess) {
      throw Exception('Falha ao carregar mensagens: status ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const RecentMessagesResponse(messages: [], hasPreviousMessages: false);
    }

    return RecentMessagesResponse.fromJson(decoded);
  }
}
