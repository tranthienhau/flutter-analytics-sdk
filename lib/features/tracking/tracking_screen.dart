import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/analytics_event.dart';
import 'tracking_provider.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventHistoryProvider);
    final totalCount = ref.watch(totalEventsProvider);
    final metaCount = ref.watch(metaEventCountProvider);
    final firebaseCount = ref.watch(firebaseEventCountProvider);
    final consent = ref.watch(consentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(eventHistoryProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Stats cards ----
            _StatsRow(
              total: totalCount,
              metaCount: metaCount,
              firebaseCount: firebaseCount,
            ),
            const SizedBox(height: 16),

            // ---- Consent toggle ----
            Card(
              child: SwitchListTile(
                title: const Text('Analytics Consent'),
                subtitle: Text(
                  consent.analyticsConsent ? 'Enabled' : 'Disabled',
                ),
                value: consent.analyticsConsent,
                onChanged: (v) =>
                    ref.read(consentProvider.notifier).setAnalyticsConsent(v),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Recent events ----
            Text(
              'Recent Events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No events yet. Fire one from the Events tab.'),
                ),
              )
            else
              ...events.reversed.take(50).map(
                    (e) => _EventTile(event: e),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.total,
    required this.metaCount,
    required this.firebaseCount,
  });

  final int total;
  final int metaCount;
  final int firebaseCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Total', value: total, color: Colors.blueGrey),
        const SizedBox(width: 8),
        _StatCard(label: 'Meta', value: metaCount, color: Colors.blue),
        const SizedBox(width: 8),
        _StatCard(
            label: 'Firebase', value: firebaseCount, color: Colors.orange),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event tile
// ---------------------------------------------------------------------------

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AnalyticsEvent event;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(event.timestamp);
    final isMeta = event.source == AnalyticsSource.meta;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMeta ? Colors.blue : Colors.orange,
          radius: 16,
          child: Text(
            isMeta ? 'M' : 'F',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(event.name),
        subtitle: Text(timeStr),
        trailing: event.parameters.isNotEmpty
            ? const Icon(Icons.chevron_right)
            : null,
      ),
    );
  }
}
