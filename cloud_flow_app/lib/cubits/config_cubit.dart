import 'dart:convert';
import 'package:cloud_flow_app/extensions/http_response_extensions.dart';
import 'package:cloud_flow_app/models/app_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

sealed class ConfigState {}

class ConfigInitial extends ConfigState {}

class ConfigLoading extends ConfigState {}

class ConfigLoaded extends ConfigState {
  final AppConfig config;
  ConfigLoaded(this.config);
}

class ConfigError extends ConfigState {
  final String message;
  ConfigError(this.message);
}

class ConfigCubit extends Cubit<ConfigState> {
  final http.Client _client;
  String lastUsername = '';
  String lastUrl = 'http://localhost:8080';

  ConfigCubit({http.Client? client})
      : _client = client ?? http.Client(),
        super(ConfigInitial());

  Future<void> connect(String rawUrl, {String username = ''}) async {
    lastUrl = rawUrl.trim();
    lastUsername = username.trim();
    emit(ConfigLoading());

    try {
      final sanitizedUrl = rawUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$sanitizedUrl/api/config');

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));

      if (!response.isSuccess) {
        emit(ConfigError('Servidor respondeu com código ${response.statusCode}.'));
        return;
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        emit(ConfigError('Resposta inválida do servidor.'));
        return;
      }

      final config = AppConfig.fromJson(decoded, username: username);

      if (config.name != 'CloudFlow') {
        emit(ConfigError('O servidor informado não é um nó CloudFlow válido.'));
        return;
      }

      emit(ConfigLoaded(config));
    } catch (_) {
      emit(ConfigError('Não foi possível conectar ao endereço informado.'));
    }
  }

  void reset() {
    emit(ConfigInitial());
  }
}
