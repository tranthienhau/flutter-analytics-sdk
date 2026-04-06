import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/analytics_event.dart';
import '../models/conversion_event.dart';
import '../models/user_properties.dart';
import 'firebase_analytics_service.dart';
import 'meta_sdk_service.dart';

/// Consent flags for GDPR / ATT compliance.
class ConsentStatus {
  final bool analyticsConsent;
  final bool personalizedAdsConsent;

  const ConsentStatus({
    this.analyticsConsent = true,
    this.personalizedAdsConsent = true,
  });

  ConsentStatus copyWith({
    bool? analyticsConsent,
    bool? personalizedAdsConsent,
  }) {
    return ConsentStatus(
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      personalizedAdsConsent:
          personalizedAdsConsent ?? this.personalizedAdsConsent,
    );
  }
}

/// Unified analytics facade that dispatches to both Meta SDK and Firebase.
///
/// Features:
/// - Dual dispatch (Meta + Firebase) in parallel
/// - Offline event queue persisted with Hive
/// - Consent gating (events are silently dropped when consent is revoked)
/// - Automatic flush when connectivity returns
class AnalyticsManager {
  AnalyticsManager({
    required MetaSdkService metaSdk,
    required FirebaseAnalyticsService firebaseAnalytics,
  })  : _meta = metaSdk,
        _firebase = firebaseAnalytics;

  final MetaSdkService _meta;
  final FirebaseAnalyticsService _firebase;

  ConsentStatus _consent = const ConsentStatus();
  bool _verbose = false;
  bool _online = true;

  late final Box<String> _queueBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final List<AnalyticsEvent> _eventLog = [];

  // ------------------------------------------------------------------
  // Getters
  // ------------------------------------------------------------------

  ConsentStatus get consent => _consent;
  bool get isVerbose => _verbose;
  List<AnalyticsEvent> get eventLog => List.unmodifiable(_eventLog);
  int get pendingQueueCount => _queueBox.length;

  int get totalEvents => _eventLog.length;
  int get metaEvents =>
      _eventLog.where((e) => e.source == AnalyticsSource.meta).length;
  int get firebaseEvents =>
      _eventLog.where((e) => e.source == AnalyticsSource.firebase).length;

  // ------------------------------------------------------------------
  // Initialization
  // ------------------------------------------------------------------

  Future<void> initialize() async {
    await Hive.initFlutter();
    _queueBox = await Hive.openBox<String>('analytics_queue');

    await Future.wait([
      _meta.initialize(),
      _firebase.initialize(),
    ]);

    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    // Try to flush any events queued from a previous session.
    await _flushQueue();
    _log('AnalyticsManager initialized');
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _queueBox.close();
  }

  // ------------------------------------------------------------------
  // Consent management
  // ------------------------------------------------------------------

  void updateConsent(ConsentStatus status) {
    _consent = status;
    _log('Consent updated: analytics=${status.analyticsConsent}, '
        'ads=${status.personalizedAdsConsent}');
  }

  // ------------------------------------------------------------------
  // Verbose / debug
  // ------------------------------------------------------------------

  void setVerbose(bool value) => _verbose = value;

  // ------------------------------------------------------------------
  // Event dispatching
  // ------------------------------------------------------------------

  /// Logs a custom event to both Meta and Firebase.
  Future<void> logEvent({
    required String name,
    Map<String, Object> parameters = const {},
  }) async {
    if (!_consent.analyticsConsent) {
      _log('Event "$name" blocked by consent');
      return;
    }

    if (!_online) {
      _enqueue(name, parameters);
      return;
    }

    final results = await Future.wait([
      _meta.logEvent(name: name, parameters: parameters),
      _firebase.logEvent(name: name, parameters: parameters),
    ]);

    for (final event in results) {
      if (event != null) _eventLog.add(event);
    }
  }

  /// Logs a purchase conversion to both platforms.
  Future<void> logPurchase(ConversionEvent event) async {
    if (!_consent.analyticsConsent) return;

    if (!_online) {
      _enqueue(event.eventName, event.toParameters());
      return;
    }

    final results = await Future.wait([
      _meta.logPurchase(event),
      _firebase.logPurchase(event),
    ]);

    for (final e in results) {
      if (e != null) _eventLog.add(e);
    }
  }

  /// Logs a standard conversion event (AddToCart, ViewContent, etc.)
  Future<void> logConversion(ConversionEvent event) async {
    if (!_consent.analyticsConsent) return;

    if (!_online) {
      _enqueue(event.eventName, event.toParameters());
      return;
    }

    final List<AnalyticsEvent?> results;

    switch (event.eventName) {
      case 'AddToCart':
        results = await Future.wait([
          _meta.logAddToCart(event),
          _firebase.logEvent(
              name: 'add_to_cart', parameters: event.toParameters()),
        ]);
      case 'ViewContent':
        results = await Future.wait([
          _meta.logViewContent(event),
          _firebase.logEvent(
              name: 'view_item', parameters: event.toParameters()),
        ]);
      case 'CompleteRegistration':
        results = await Future.wait([
          _meta.logCompleteRegistration(),
          _firebase.logSignUp(),
        ]);
      default:
        results = await Future.wait([
          _meta.logEvent(name: event.eventName, parameters: event.toParameters()),
          _firebase.logEvent(
              name: event.eventName, parameters: event.toParameters()),
        ]);
    }

    for (final e in results) {
      if (e != null) _eventLog.add(e);
    }
  }

  /// Sets user properties on both platforms.
  Future<void> setUserProperties(UserProperties props) async {
    await Future.wait([
      _meta.setUserData(props),
      _firebase.applyUserProperties(props),
    ]);
  }

  // ------------------------------------------------------------------
  // Queue / offline support
  // ------------------------------------------------------------------

  void _enqueue(String name, Map<String, Object> parameters) {
    final payload = jsonEncode({
      'name': name,
      'parameters': parameters,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _queueBox.add(payload);
    _log('Queued event "$name" (${_queueBox.length} pending)');
  }

  Future<void> _flushQueue() async {
    if (_queueBox.isEmpty) return;

    _log('Flushing ${_queueBox.length} queued events');
    final keys = _queueBox.keys.toList();

    for (final key in keys) {
      final raw = _queueBox.get(key);
      if (raw == null) continue;

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final name = json['name'] as String;
        final params = Map<String, Object>.from(json['parameters'] as Map);

        await Future.wait([
          _meta.logEvent(name: name, parameters: params),
          _firebase.logEvent(name: name, parameters: params),
        ]).then((results) {
          for (final e in results) {
            if (e != null) _eventLog.add(e);
          }
        });

        await _queueBox.delete(key);
      } catch (e) {
        debugPrint('[AnalyticsManager] flush item error: $e');
      }
    }
  }

  /// Manually flush the offline queue and both SDKs.
  Future<void> flush() async {
    await _flushQueue();
    await _meta.flush();
    _log('Manual flush complete');
  }

  /// Clears the offline event queue.
  Future<void> clearQueue() async {
    await _queueBox.clear();
    _log('Queue cleared');
  }

  /// Clears the in-memory event log.
  void clearEventLog() {
    _eventLog.clear();
    _log('Event log cleared');
  }

  // ------------------------------------------------------------------
  // Connectivity
  // ------------------------------------------------------------------

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = !_online;
    _online = results.any((r) => r != ConnectivityResult.none);

    if (_online && wasOffline) {
      _log('Back online, flushing queue');
      _flushQueue();
    }
  }

  // ------------------------------------------------------------------
  // Logging
  // ------------------------------------------------------------------

  void _log(String message) {
    if (_verbose) {
      debugPrint('[AnalyticsManager] $message');
    }
  }
}
