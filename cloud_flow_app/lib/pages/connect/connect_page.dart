import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/extensions/context_extensions.dart';
import 'package:cloud_flow_app/pages/messages/messages_page.dart';
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
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final configCubit = context.read<ConfigCubit>();
    _urlController = TextEditingController(text: configCubit.lastUrl);
    _usernameController = TextEditingController(text: configCubit.lastUsername);
  }

  @override
  void dispose() {
    _urlController.dispose();
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
    final urlText = _urlController.text.trim();
    final usernameText = _usernameController.text.trim();

    if (!_validateUsername(usernameText)) return;

    if (urlText.isEmpty) {
      context.showSnackBar('Informe um endereço válido.');
      return;
    }

    context.read<ConfigCubit>().connect(urlText, username: usernameText);
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
                    TextField(
                      controller: _urlController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        hintText: 'http://localhost:8080',
                        prefixIcon: Icon(Symbols.dns),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      onSubmitted: (_) => _onConnect(),
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
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _onConnect,
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
