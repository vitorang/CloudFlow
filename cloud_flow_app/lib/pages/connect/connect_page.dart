import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/extensions/context_extensions.dart';
import 'package:cloud_flow_app/pages/messages/messages_page.dart';
import 'package:cloud_flow_app/services/environment_service.dart';
import 'package:cloud_flow_app/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  late final TextEditingController _usernameController;
  Map<String, String> _environments = const {};
  String? _selectedEnvironmentKey;
  bool _isLoadingEnvironments = true;

  @override
  void initState() {
    super.initState();
    final configCubit = context.read<ConfigCubit>();
    _usernameController = TextEditingController(text: configCubit.lastUsername);
    _loadEnvironments();
  }

  Future<void> _loadEnvironments() async {
    final envs = await EnvironmentService.loadEnvironments();
    if (!mounted) return;

    final configCubit = context.read<ConfigCubit>();
    String? matchedKey;

    if (configCubit.lastUrl.isNotEmpty) {
      for (final entry in envs.entries) {
        if (entry.value == configCubit.lastUrl) {
          matchedKey = entry.key;
          break;
        }
      }
    }

    final initialKey = matchedKey ?? (envs.isNotEmpty ? envs.keys.first : null);
    if (initialKey != null) {
      configCubit.selectEnvironment(initialKey);
    }

    setState(() {
      _environments = envs;
      _selectedEnvironmentKey = initialKey;
      _isLoadingEnvironments = false;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool _validateUsername(String username) {
    if (username.isEmpty) {
      context.showSnackBar('Informe um nome de usuário.');
      return false;
    }

    if (username.contains(' ')) {
      context.showSnackBar('O nome de usuário não pode conter espaços.');
      return false;
    }

    if (username.length > 12) {
      context.showSnackBar('O nome de usuário deve ter no máximo 12 caracteres.');
      return false;
    }

    return true;
  }

  void _onConnect() {
    final usernameText = _usernameController.text.trim();

    if (!_validateUsername(usernameText)) return;

    final selectedUrl = _selectedEnvironmentKey != null ? _environments[_selectedEnvironmentKey] : null;

    if (selectedUrl == null || selectedUrl.isEmpty) {
      context.showSnackBar('Selecione um ambiente válido.');
      return;
    }

    context.read<ConfigCubit>().connect(
      selectedUrl,
      username: usernameText,
      environment: _selectedEnvironmentKey ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ConfigCubit, ConfigState>(
        listener: (context, state) {
          if (state is ConfigError) {
            context.showSnackBar(state.message);
          } else if (state is ConfigLoaded) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MessagesPage()));
          }
        },
        builder: (context, state) {
          final isLoading = state is ConfigLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CloudFlowBrand(fontSize: 36, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedEnvironmentKey),
                      initialValue: _selectedEnvironmentKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ambiente',
                        prefixIcon: Icon(Symbols.dns),
                        border: OutlineInputBorder(),
                      ),
                      items: _environments.keys.map((environmentKey) {
                        return DropdownMenuItem<String>(value: environmentKey, child: Text(environmentKey));
                      }).toList(),
                      onChanged: isLoading || _isLoadingEnvironments
                          ? null
                          : (value) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              setState(() {
                                _selectedEnvironmentKey = value;
                              });
                              if (value != null) {
                                context.read<ConfigCubit>().selectEnvironment(value);
                              }
                            },
                      hint: Text(_isLoadingEnvironments ? 'Carregando ambientes...' : 'Selecione um ambiente'),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      enabled: !isLoading,
                      maxLength: 12,
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      decoration: const InputDecoration(
                        labelText: 'Nome de usuário',
                        prefixIcon: Icon(Symbols.person),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onConnect(),
                    ),

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading || _isLoadingEnvironments ? null : _onConnect,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
