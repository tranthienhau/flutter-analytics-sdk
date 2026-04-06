import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/analytics_event.dart';
import '../tracking/tracking_provider.dart';

class EventLogScreen extends ConsumerWidget {
  const EventLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(eventHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: events.isEmpty
          ? const Center(child: Text('No events recorded yet.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                // Show newest first.
                final event = events[events.length - 1 - index];
                return _ExpandableEventTile(event: event);
              },
            ),
    );
  }
}

class _ExpandableEventTile extends StatefulWidget {
  const _ExpandableEventTile({required this.event});
  final AnalyticsEvent event;

  @override
  State<_ExpandableEventTile> createState() => _ExpandableEventTileState();
}

class _ExpandableEventTileState extends State<_ExpandableEventTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timestamp);
    final isMeta = event.source == AnalyticsSource.meta;
    final isFirebase = event.source == AnalyticsSource.firebase;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: event.parameters.isNotEmpty
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header ----
              Row(
                children: [
                  _SourceBadge(
                    label: isMeta ? 'Meta' : (isFirebase ? 'Firebase' : 'Custom'),
                    color: isMeta
                        ? Colors.blue
                        : (isFirebase ? Colors.orange : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (event.parameters.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ],
              ),

              // ---- Expanded parameters ----
              if (_expanded && event.parameters.isNotEmpty) ...[
                const Divider(height: 16),
                ...event.parameters.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${e.key}: ',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Expanded(child: Text('${e.value}')),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
