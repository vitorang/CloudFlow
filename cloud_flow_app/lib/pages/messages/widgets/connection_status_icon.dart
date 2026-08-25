import 'package:cloud_flow_app/cubits/connection_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectionStatusIcon extends StatelessWidget {
  const ConnectionStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionCubit, WsConnectionState>(
      builder: (context, state) {
        if (state is WsConnectionConnected) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.cloud_done, color: Colors.green),
          );
        } else if (state is WsConnectionConnecting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.cloud_off, color: Colors.red),
        );
      },
    );
  }
}
