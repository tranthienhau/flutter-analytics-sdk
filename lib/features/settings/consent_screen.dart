import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tracking/tracking_provider.dart';

class ConsentScreen extends ConsumerWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(consentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Consent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- GDPR section ----
          Text('GDPR Consent', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Analytics Consent'),
                  subtitle: const Text(
                    'Allow collection of anonymized usage data',
                  ),
                  value: consent.analyticsConsent,
                  onChanged: (v) =>
                      ref.read(consentProvider.notifier).setAnalyticsConsent(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Personalized Ads'),
                  subtitle: const Text(
                    'Allow personalized ad targeting via Meta SDK',
                  ),
                  value: consent.personalizedAdsConsent,
                  onChanged: (v) =>
                      ref.read(consentProvider.notifier).setPersonalizedAds(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- ATT simulation (iOS) ----
          Text(
            'App Tracking Transparency (iOS)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'On iOS 14+, the system shows a native ATT prompt before '
                    'any tracking. This button simulates that flow.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => _showAttSimulation(context, ref),
                    child: const Text('Simulate ATT Prompt'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ---- Data management ----
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Request Data Deletion'),
                  subtitle: const Text(
                    'Submit a GDPR data deletion request',
                  ),
                  onTap: () => _showDeletionDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.policy_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opens privacy policy URL'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Current status ----
          Card(
            color: consent.analyticsConsent
                ? Colors.green.withValues(alpha: 0.05)
                : Colors.red.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    consent.analyticsConsent
                        ? Icons.check_circle
                        : Icons.block,
                    color: consent.analyticsConsent
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      consent.analyticsConsent
                          ? 'Analytics events are being sent to Meta and Firebase.'
                          : 'Analytics events are blocked. No data is sent.',
                      style: TextStyle(
                        color: consent.analyticsConsent
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttSimulation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allow Tracking?'),
        content: const Text(
          '"Analytics SDK" would like permission to track your activity '
          'across other companies\' apps and websites.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(consentProvider.notifier).setAnalyticsConsent(false);
              ref.read(consentProvider.notifier).setPersonalizedAds(false);
              Navigator.of(ctx).pop();
            },
            child: const Text('Ask App Not to Track'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(consentProvider.notifier).setAnalyticsConsent(true);
              ref.read(consentProvider.notifier).setPersonalizedAds(true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Deletion Request'),
        content: const Text(
          'This will submit a GDPR data deletion request. In a production '
          'app this would call your backend API. All locally stored '
          'analytics data would also be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data deletion request submitted (mock)'),
                ),
              );
            },
            child: const Text('Confirm Deletion'),
          ),
        ],
      ),
    );
  }
}
