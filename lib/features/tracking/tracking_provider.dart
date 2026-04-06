import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analytics_event.dart';
import '../../services/analytics_manager.dart';
import '../../services/attribution_service.dart';
import '../../services/firebase_analytics_service.dart';
import '../../services/meta_sdk_service.dart';

// ---------------------------------------------------------------------------
// Service singletons
// ---------------------------------------------------------------------------

final metaSdkServiceProvider = Provider<MetaSdkService>((ref) {
  return MetaSdkService();
});

final firebaseAnalyticsServiceProvider =
    Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

final attributionServiceProvider = Provider<AttributionService>((ref) {
  return AttributionService();
});

final analyticsManagerProvider = Provider<AnalyticsManager>((ref) {
  return AnalyticsManager(
    metaSdk: ref.read(metaSdkServiceProvider),
    firebaseAnalytics: ref.read(firebaseAnalyticsServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// State notifiers
// ---------------------------------------------------------------------------

/// Holds the full event history for display in the UI.
class EventHistoryNotifier extends StateNotifier<List<AnalyticsEvent>> {
  EventHistoryNotifier(this._manager) : super([]);

  final AnalyticsManager _manager;

  void refresh() {
    state = _manager.eventLog;
  }
}

final eventHistoryProvider =
    StateNotifierProvider<EventHistoryNotifier, List<AnalyticsEvent>>((ref) {
  return EventHistoryNotifier(ref.read(analyticsManagerProvider));
});

/// Tracks consent status for the UI.
class ConsentNotifier extends StateNotifier<ConsentStatus> {
  ConsentNotifier(this._manager) : super(const ConsentStatus());

  final AnalyticsManager _manager;

  void toggleAnalyticsConsent() {
    state = state.copyWith(analyticsConsent: !state.analyticsConsent);
    _manager.updateConsent(state);
  }

  void togglePersonalizedAds() {
    state = state.copyWith(
        personalizedAdsConsent: !state.personalizedAdsConsent);
    _manager.updateConsent(state);
  }

  void setAnalyticsConsent(bool value) {
    state = state.copyWith(analyticsConsent: value);
    _manager.updateConsent(state);
  }

  void setPersonalizedAds(bool value) {
    state = state.copyWith(personalizedAdsConsent: value);
    _manager.updateConsent(state);
  }
}

final consentProvider =
    StateNotifierProvider<ConsentNotifier, ConsentStatus>((ref) {
  return ConsentNotifier(ref.read(analyticsManagerProvider));
});

// ---------------------------------------------------------------------------
// Derived / computed providers
// ---------------------------------------------------------------------------

final totalEventsProvider = Provider<int>((ref) {
  return ref.watch(eventHistoryProvider).length;
});

final metaEventCountProvider = Provider<int>((ref) {
  return ref
      .watch(eventHistoryProvider)
      .where((e) => e.source == AnalyticsSource.meta)
      .length;
});

final firebaseEventCountProvider = Provider<int>((ref) {
  return ref
      .watch(eventHistoryProvider)
      .where((e) => e.source == AnalyticsSource.firebase)
      .length;
});

final pendingQueueCountProvider = Provider<int>((ref) {
  return ref.read(analyticsManagerProvider).pendingQueueCount;
});

/// Verbose logging toggle.
class VerboseNotifier extends StateNotifier<bool> {
  VerboseNotifier(this._manager) : super(false);

  final AnalyticsManager _manager;

  void toggle() {
    state = !state;
    _manager.setVerbose(state);
  }

  void setValue(bool value) {
    state = value;
    _manager.setVerbose(value);
  }
}

final verboseProvider =
    StateNotifierProvider<VerboseNotifier, bool>((ref) {
  return VerboseNotifier(ref.read(analyticsManagerProvider));
});
