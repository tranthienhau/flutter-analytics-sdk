import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_analytics_sdk/models/analytics_event.dart';
import 'package:flutter_analytics_sdk/services/analytics_manager.dart';
import 'package:flutter_analytics_sdk/services/firebase_analytics_service.dart';
import 'package:flutter_analytics_sdk/services/meta_sdk_service.dart';
import 'package:flutter_analytics_sdk/features/tracking/tracking_provider.dart';
import 'package:flutter_analytics_sdk/features/tracking/tracking_screen.dart';
import 'package:flutter_analytics_sdk/features/events/event_log_screen.dart';
import 'package:flutter_analytics_sdk/features/events/event_builder_screen.dart';
import 'package:flutter_analytics_sdk/features/attribution/attribution_screen.dart';

// ---------------------------------------------------------------------------
// Test-only seeded notifiers (avoid building the native Meta / Firebase SDKs)
// ---------------------------------------------------------------------------

// Build a manager whose constructor only stores service references (no native
// calls happen until initialize(), which the test never calls).
AnalyticsManager _stubManager() => AnalyticsManager(
      metaSdk: MetaSdkService(),
      firebaseAnalytics: FirebaseAnalyticsService(),
    );

class _SeededEventHistory extends EventHistoryNotifier {
  _SeededEventHistory(List<AnalyticsEvent> events) : super(_stubManager()) {
    state = events;
  }
}

class _SeededConsent extends ConsentNotifier {
  _SeededConsent() : super(_stubManager());
}

List<AnalyticsEvent> _mockEvents() {
  final now = DateTime(2024, 6, 12, 14, 30, 0);
  return [
    AnalyticsEvent(
      name: 'app_open',
      parameters: const {'session_id': 'a1b2c3'},
      timestamp: now.subtract(const Duration(minutes: 12)),
      source: AnalyticsSource.firebase,
    ),
    AnalyticsEvent(
      name: 'ViewContent',
      parameters: const {'content_id': 'sku_12345', 'content_type': 'product'},
      timestamp: now.subtract(const Duration(minutes: 9)),
      source: AnalyticsSource.meta,
    ),
    AnalyticsEvent(
      name: 'add_to_cart',
      parameters: const {'value': 9.99, 'currency': 'USD'},
      timestamp: now.subtract(const Duration(minutes: 6)),
      source: AnalyticsSource.firebase,
    ),
    AnalyticsEvent(
      name: 'AddToCart',
      parameters: const {'value': 9.99, 'currency': 'USD', 'content_id': 'sku_12345'},
      timestamp: now.subtract(const Duration(minutes: 6)),
      source: AnalyticsSource.meta,
    ),
    AnalyticsEvent(
      name: 'CompleteRegistration',
      parameters: const {'registration_method': 'email'},
      timestamp: now.subtract(const Duration(minutes: 4)),
      source: AnalyticsSource.meta,
    ),
    AnalyticsEvent(
      name: 'sign_up',
      parameters: const {'method': 'email'},
      timestamp: now.subtract(const Duration(minutes: 4)),
      source: AnalyticsSource.firebase,
    ),
    AnalyticsEvent(
      name: 'Purchase',
      parameters: const {'value': 49.99, 'currency': 'USD', 'content_id': 'sku_98765'},
      timestamp: now.subtract(const Duration(minutes: 1)),
      source: AnalyticsSource.meta,
    ),
    AnalyticsEvent(
      name: 'purchase',
      parameters: const {'value': 49.99, 'currency': 'USD', 'content_id': 'sku_98765'},
      timestamp: now.subtract(const Duration(minutes: 1)),
      source: AnalyticsSource.firebase,
    ),
  ];
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();


  Future<void> shoot(WidgetTester tester, String name) async {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot(name);
  }

  List<Override> overrides() => [
        eventHistoryProvider.overrideWith(
          (ref) => _SeededEventHistory(_mockEvents()),
        ),
        consentProvider.overrideWith((ref) => _SeededConsent()),
      ];

  Widget wrap(Widget child) => ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            useMaterial3: true,
          ),
          home: child,
        ),
      );

  testWidgets('01 dashboard', (tester) async {
    await tester.pumpWidget(wrap(const TrackingScreen()));
    await tester.pumpAndSettle();
    await shoot(tester, '01-dashboard');
  });

  testWidgets('02 event log', (tester) async {
    await tester.pumpWidget(wrap(const EventLogScreen()));
    await tester.pumpAndSettle();
    await shoot(tester, '02-event-log');
  });

  testWidgets('03 event builder', (tester) async {
    await tester.pumpWidget(wrap(const EventBuilderScreen()));
    await tester.pumpAndSettle();
    await shoot(tester, '03-event-builder');
  });

  testWidgets('04 attribution', (tester) async {
    await tester.pumpWidget(wrap(const AttributionScreen()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await shoot(tester, '04-attribution');
  });
}
