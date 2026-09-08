import 'package:cloud_flow_app/constants/environment_theme.dart';
import 'package:cloud_flow_app/cubits/config_cubit.dart';
import 'package:cloud_flow_app/pages/connect/connect_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const CloudFlowApp());
}

class CloudFlowApp extends StatelessWidget {
  const CloudFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ConfigCubit(),
      child: BlocBuilder<ConfigCubit, ConfigState>(
        builder: (context, state) {
          final environment = state is ConfigLoaded
              ? state.config.environment
              : context.read<ConfigCubit>().lastEnvironment;
          final seedColor = EnvironmentTheme.getPrimaryColor(environment);

          return MaterialApp(
            title: 'CloudFlow',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.system,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
            ),
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final targetTheme = isDark
                  ? ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: seedColor,
                        brightness: Brightness.dark,
                      ),
                    )
                  : ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: seedColor,
                        brightness: Brightness.light,
                      ),
                    );

              return AnimatedTheme(
                data: targetTheme,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const ConnectPage(),
          );
        },
      ),
    );
  }
}
