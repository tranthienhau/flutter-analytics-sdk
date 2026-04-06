import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/attribution_service.dart';
import '../tracking/tracking_provider.dart';

/// Provider that fetches mock attribution data on first access.
final attributionDataProvider = FutureProvider<AttributionData>((ref) async {
  final service = ref.read(attributionServiceProvider);
  return service.getInstallAttribution();
});

class AttributionScreen extends ConsumerWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(attributionDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attribution')),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) => _AttributionBody(data: data),
      ),
    );
  }
}

class _AttributionBody extends StatelessWidget {
  const _AttributionBody({required this.data});
  final AttributionData data;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Install info ----
        _SectionHeader(title: 'Install Attribution'),
        const SizedBox(height: 8),
        _InfoCard(children: [
          _InfoRow(label: 'Source', value: data.installSource),
          _InfoRow(label: 'Campaign', value: data.campaign ?? '-'),
          _InfoRow(label: 'Ad Group', value: data.adGroup ?? '-'),
          _InfoRow(label: 'Creative', value: data.creative ?? '-'),
          _InfoRow(
            label: 'Install Date',
            value: dateFormat.format(data.installTimestamp),
          ),
        ]),
        const SizedBox(height: 20),

        // ---- Attribution model ----
        _SectionHeader(title: 'Attribution Model'),
        const SizedBox(height: 8),
        _InfoCard(children: [
          _InfoRow(
            label: 'Model',
            value: data.attributionModel == AttributionModel.firstTouch
                ? 'First Touch'
                : 'Last Touch',
          ),
        ]),
        const SizedBox(height: 20),

        // ---- Deep link ----
        _SectionHeader(title: 'Deep Link'),
        const SizedBox(height: 8),
        _InfoCard(children: [
          _InfoRow(label: 'URL', value: data.deepLinkUrl ?? 'None'),
        ]),
        const SizedBox(height: 20),

        // ---- IDFA / GAID ----
        _SectionHeader(title: 'Advertising IDs'),
        const SizedBox(height: 8),
        _InfoCard(children: [
          _InfoRow(
            label: 'IDFA (iOS)',
            value: data.idfaAvailable
                ? (data.idfa ?? 'Available')
                : 'Not available (ATT denied)',
          ),
          _InfoRow(label: 'GAID (Android)', value: data.gaid ?? '-'),
        ]),
        const SizedBox(height: 20),

        // ---- UTM parameters ----
        _SectionHeader(title: 'UTM Parameters'),
        const SizedBox(height: 8),
        if (data.utmParameters.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No UTM parameters', style: theme.textTheme.bodyMedium),
            ),
          )
        else
          _InfoCard(
            children: data.utmParameters.entries
                .map((e) => _InfoRow(label: e.key, value: e.value))
                .toList(),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable UI components
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
