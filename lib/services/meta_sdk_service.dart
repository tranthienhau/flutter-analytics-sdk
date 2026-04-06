import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

import '../models/analytics_event.dart';
import '../models/conversion_event.dart';
import '../models/user_properties.dart';

/// Wrapper around the Facebook App Events (Meta SDK) package.
///
/// All public methods are guarded with try/catch so the app degrades
/// gracefully when the Meta SDK is not configured or unavailable.
class MetaSdkService {
  MetaSdkService() : _fb = FacebookAppEvents();

  final FacebookAppEvents _fb;
  bool _initialized = false;

  // ------------------------------------------------------------------
  // Initialization
  // ------------------------------------------------------------------

  Future<void> initialize() async {
    try {
      // Enable advertiser tracking (required for iOS 14+ ATT).
      await _fb.setAdvertiserTracking(enabled: true);
      _initialized = true;
      debugPrint('[MetaSdkService] initialized');
    } catch (e, st) {
      debugPrint('[MetaSdkService] init error: $e\n$st');
    }
  }

  bool get isInitialized => _initialized;

  // ------------------------------------------------------------------
  // Generic event logging
  // ------------------------------------------------------------------

  Future<AnalyticsEvent?> logEvent({
    required String name,
    Map<String, Object> parameters = const {},
  }) async {
    try {
      await _fb.logEvent(
        name: name,
        parameters: _stringifyParams(parameters),
      );
      return AnalyticsEvent(
        name: name,
        parameters: parameters,
        timestamp: DateTime.now(),
        source: AnalyticsSource.meta,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] logEvent error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // Standard events
  // ------------------------------------------------------------------

  Future<AnalyticsEvent?> logPurchase(ConversionEvent event) async {
    try {
      await _fb.logPurchase(
        amount: event.value ?? 0,
        currency: event.currency ?? 'USD',
        parameters: _stringifyParams(event.toParameters()),
      );
      return AnalyticsEvent(
        name: 'Purchase',
        parameters: event.toParameters(),
        timestamp: DateTime.now(),
        source: AnalyticsSource.meta,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] logPurchase error: $e');
      return null;
    }
  }

  Future<AnalyticsEvent?> logAddToCart(ConversionEvent event) async {
    try {
      await _fb.logAddToCart(
        id: event.contentId ?? '',
        type: event.contentType ?? 'product',
        price: event.value ?? 0,
        currency: event.currency ?? 'USD',
      );
      return AnalyticsEvent(
        name: 'AddToCart',
        parameters: event.toParameters(),
        timestamp: DateTime.now(),
        source: AnalyticsSource.meta,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] logAddToCart error: $e');
      return null;
    }
  }

  Future<AnalyticsEvent?> logCompleteRegistration({
    String registrationMethod = 'email',
  }) async {
    try {
      await _fb.logEvent(
        name: 'CompleteRegistration',
        parameters: {'registration_method': registrationMethod},
      );
      return AnalyticsEvent(
        name: 'CompleteRegistration',
        parameters: {'registration_method': registrationMethod},
        timestamp: DateTime.now(),
        source: AnalyticsSource.meta,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] logCompleteRegistration error: $e');
      return null;
    }
  }

  Future<AnalyticsEvent?> logViewContent(ConversionEvent event) async {
    try {
      await _fb.logViewContent(
        id: event.contentId ?? '',
        type: event.contentType ?? 'page',
        price: event.value ?? 0,
        currency: event.currency ?? 'USD',
      );
      return AnalyticsEvent(
        name: 'ViewContent',
        parameters: event.toParameters(),
        timestamp: DateTime.now(),
        source: AnalyticsSource.meta,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] logViewContent error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // User data
  // ------------------------------------------------------------------

  Future<void> setUserData(UserProperties props) async {
    try {
      await _fb.setUserData(
        email: props.email,
        gender: props.gender,
      );
    } catch (e) {
      debugPrint('[MetaSdkService] setUserData error: $e');
    }
  }

  // ------------------------------------------------------------------
  // Flush
  // ------------------------------------------------------------------

  Future<void> flush() async {
    try {
      await _fb.flush();
      debugPrint('[MetaSdkService] flushed');
    } catch (e) {
      debugPrint('[MetaSdkService] flush error: $e');
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Map<String, dynamic> _stringifyParams(Map<String, Object> params) {
    return params.map((k, v) => MapEntry(k, v));
  }
}
