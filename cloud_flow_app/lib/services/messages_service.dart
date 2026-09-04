import 'dart:convert';
import 'package:cloud_flow_app/extensions/http_response_extensions.dart';
import 'package:cloud_flow_app/models/recent_messages_response.dart';
import 'package:cloud_flow_app/models/upload_urls_response.dart';
import 'package:http/http.dart' as http;

class MessagesService {
  final http.Client _client;

  MessagesService({http.Client? client}) : _client = client ?? http.Client();

  Future<void> sendMessage({
    required String apiUrl,
    required String author,
    required String text,
    String? attachmentKey,
    String? thumbnailKey,
    int? expiresInHours,
  }) async {
    final uri = Uri.parse('$apiUrl/api/messages');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'author': author,
        'text': text,
        'attachmentKey': attachmentKey,
        'thumbnailKey': thumbnailKey,
        'expiresInHours': expiresInHours,
      }),
    );

    if (!response.isSuccess) {
      throw Exception('Falha ao enviar mensagem: status ${response.statusCode}');
    }
  }

  Future<RecentMessagesResponse> getRecentMessages({required String apiUrl, DateTime? before}) async {
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

  Future<UploadUrlsResponse> getUploadUrls({
    required String apiUrl,
    required String fileExtension,
    bool hasThumbnail = false,
  }) async {
    final uri = Uri.parse('$apiUrl/api/files/presigned-urls');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fileExtension': fileExtension,
        'hasThumbnail': hasThumbnail,
      }),
    );

    if (!response.isSuccess) {
      throw Exception('Falha ao obter URLs para upload: status ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    return UploadUrlsResponse.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required Map<String, String> formFields,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(uploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields.addAll(formFields);

    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    );
    request.files.add(multipartFile);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (!response.isSuccess && response.statusCode != 204) {
      throw Exception('Falha ao enviar arquivo para o S3: status ${response.statusCode}');
    }
  }

  Future<void> deleteMessages({required String apiUrl, required List<String> ids}) async {
    final uri = Uri.parse('$apiUrl/api/messages');
    final response = await _client.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ids': ids}),
    );

    if (!response.isSuccess) {
      throw Exception('Falha ao excluir mensagens: status ${response.statusCode}');
    }
  }
}
