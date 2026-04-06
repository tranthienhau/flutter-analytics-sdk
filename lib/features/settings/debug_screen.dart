import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tracking/tracking_provider.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verbose = ref.watch(verboseProvider);
    final pendingCount = ref.watch(pendingQueueCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Queue info ----
          Text('Event Queue', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pending Events'),
                      Chip(
                        label: Text('$pendingCount'),
                        backgroundColor:
                            pendingCount > 0 ? Colors.orange.shade100 : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final manager =
                                ref.read(analyticsManagerProvider);
                            await manager.flush();
                            ref.read(eventHistoryProvider.notifier).refresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Queue flushed'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Flush Events'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final manager =
                                ref.read(analyticsManagerProvider);
                            await manager.clearQueue();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Queue cleared'),
                                ),
                              );
                            }
                          },
                          icon:
                              const Icon(Icons.delete_sweep, color: Colors.red),
                          label: const Text('Clear Queue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Event log management ----
          Text(
            'Event Log',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Event Log'),
              subtitle: const Text('Remove all events from in-memory log'),
              onTap: () {
                ref.read(analyticsManagerProvider).clearEventLog();
                ref.read(eventHistoryProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event log cleared')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ---- Logging ----
          Text('Logging', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Verbose Logging'),
              subtitle: const Text('Print detailed logs to debug console'),
              value: verbose,
              onChanged: (v) =>
                  ref.read(verboseProvider.notifier).setValue(v),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Connection test ----
          Text(
            'Connection Test',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.blue),
                  title: const Text('Test Meta SDK Connection'),
                  subtitle: const Text('Fire a test event to Meta'),
                  onTap: () async {
                    final manager = ref.read(analyticsManagerProvider);
                    await manager.logEvent(
                      name: 'debug_test_meta',
                      parameters: {'source': 'debug_panel'},
                    );
                    ref.read(eventHistoryProvider.notifier).refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test event sent to Meta SDK'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud, color: Colors.orange),
                  title: const Text('Test Firebase Connection'),
                  subtitle: const Text('Fire a test event to Firebase'),
                  onTap: () async {
                    final manager = ref.read(analyticsManagerProvider);
                    await manager.logEvent(
                      name: 'debug_test_firebase',
                      parameters: {'source': 'debug_panel'},
                    );
                    ref.read(eventHistoryProvider.notifier).refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test event sent to Firebase'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- SDK status ----
          Text('SDK Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatusRow(
                    label: 'Meta SDK',
                    initialized:
                        ref.read(metaSdkServiceProvider).isInitialized,
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: 'Firebase Analytics',
                    initialized: ref
                        .read(firebaseAnalyticsServiceProvider)
                        .isInitialized,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.initialized});
  final String label;
  final bool initialized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          initialized ? Icons.check_circle : Icons.error,
          color: initialized ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          initialized ? 'Initialized' : 'Not initialized',
          style: TextStyle(
            color: initialized ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
