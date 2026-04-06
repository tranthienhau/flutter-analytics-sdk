import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/tracking/tracking_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[main] Firebase init error (expected in dev): $e');
  }

  // Create the Riverpod container so we can eagerly initialize the
  // AnalyticsManager before the widget tree builds.
  final container = ProviderContainer();

  try {
    await container.read(analyticsManagerProvider).initialize();
  } catch (e) {
    debugPrint('[main] AnalyticsManager init error: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AnalyticsApp(),
    ),
  );
}
