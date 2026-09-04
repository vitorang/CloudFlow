import 'dart:convert';
import 'package:cloud_flow_app/cubits/audit_events_cubit.dart';
import 'package:cloud_flow_app/models/audit_event_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class AuditEventsDrawer extends StatelessWidget {
  final VoidCallback? onClose;

  const AuditEventsDrawer({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Symbols.fact_check, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Eventos de Auditoria',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                BlocBuilder<AuditEventsCubit, AuditEventsState>(
                  builder: (context, state) {
                    if (state.events.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Symbols.clear_all, size: 20),
                      tooltip: 'Limpar eventos',
                      onPressed: () {
                        context.read<AuditEventsCubit>().clearEvents();
                      },
                    );
                  },
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Symbols.close, size: 20),
                    tooltip: 'Fechar',
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<AuditEventsCubit, AuditEventsState>(
              builder: (context, state) {
                if (state.events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.history_toggle_off,
                          size: 48,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum evento registrado ainda',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Novos eventos do SNS aparecerão aqui',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event = state.events[index];
                    return _AuditEventCard(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEventCard extends StatelessWidget {
  final AuditEventItem event;

  const _AuditEventCard({required this.event});

  String _formatTime(DateTime time) {
    final localTime = time.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final second = localTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    event.topicName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.eventType,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(event.occurredAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (event.payload != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(event.payload),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
