import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../models/analytics_event.dart';
import '../models/conversion_event.dart';
import '../models/user_properties.dart';

/// Wrapper around Firebase Analytics.
///
/// Every public method is wrapped in try/catch for graceful degradation
/// when Firebase is not configured.
class FirebaseAnalyticsService {
  /// Default constructor used in production. Resolves the Firebase Analytics
  /// singleton lazily so that simply constructing the service does not require
  /// Firebase to be initialized (useful for tests / screenshot tooling).
  FirebaseAnalyticsService();

  FirebaseAnalytics get _analytics =>
      _injected ?? FirebaseAnalytics.instance;

  FirebaseAnalytics? _injected;
  bool _initialized = false;

  // ------------------------------------------------------------------
  // Initialization
  // ------------------------------------------------------------------

  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _initialized = true;
      debugPrint('[FirebaseAnalyticsService] initialized');
    } catch (e, st) {
      debugPrint('[FirebaseAnalyticsService] init error: $e\n$st');
    }
  }

  bool get isInitialized => _initialized;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ------------------------------------------------------------------
  // Generic event logging
  // ------------------------------------------------------------------

  Future<AnalyticsEvent?> logEvent({
    required String name,
    Map<String, Object> parameters = const {},
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      return AnalyticsEvent(
        name: name,
        parameters: parameters,
        timestamp: DateTime.now(),
        source: AnalyticsSource.firebase,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] logEvent error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Screen views
  // ------------------------------------------------------------------

  Future<AnalyticsEvent?> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      return AnalyticsEvent(
        name: 'screen_view',
        parameters: {
          'screen_name': screenName,
          // ignore: use_null_aware_elements
          if (screenClass != null) 'screen_class': screenClass,
        },
        timestamp: DateTime.now(),
        source: AnalyticsSource.firebase,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] logScreenView error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Standard events
  // ------------------------------------------------------------------

  Future<AnalyticsEvent?> logPurchase(ConversionEvent event) async {
    try {
      await _analytics.logPurchase(
        value: event.value,
        currency: event.currency,
        items: [
          if (event.contentId != null)
            AnalyticsEventItem(
              itemId: event.contentId,
              itemCategory: event.contentType,
            ),
        ],
      );
      return AnalyticsEvent(
        name: 'purchase',
        parameters: event.toParameters(),
        timestamp: DateTime.now(),
        source: AnalyticsSource.firebase,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] logPurchase error: $e');
      return null;
    }
  }

  Future<AnalyticsEvent?> logSignUp({String method = 'email'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      return AnalyticsEvent(
        name: 'sign_up',
        parameters: {'method': method},
        timestamp: DateTime.now(),
        source: AnalyticsSource.firebase,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] logSignUp error: $e');
      return null;
    }
  }

  Future<AnalyticsEvent?> logLogin({String method = 'email'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      return AnalyticsEvent(
        name: 'login',
        parameters: {'method': method},
        timestamp: DateTime.now(),
        source: AnalyticsSource.firebase,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] logLogin error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // User properties
  // ------------------------------------------------------------------

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] setUserId error: $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('[FirebaseAnalyticsService] setUserProperty error: $e');
    }
  }

  Future<void> applyUserProperties(UserProperties props) async {
    await setUserId(props.userId);
    for (final entry in props.toMap().entries) {
      if (entry.key != 'user_id') {
        await setUserProperty(name: entry.key, value: entry.value);
      }
    }
  }
}
