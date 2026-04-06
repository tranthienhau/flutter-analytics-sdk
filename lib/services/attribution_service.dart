import 'package:flutter/foundation.dart';

/// Mock attribution data returned by [AttributionService].
class AttributionData {
  final String installSource;
  final String? campaign;
  final String? adGroup;
  final String? creative;
  final String? deepLinkUrl;
  final bool idfaAvailable;
  final String? idfa;
  final String? gaid;
  final AttributionModel attributionModel;
  final Map<String, String> utmParameters;
  final DateTime installTimestamp;

  const AttributionData({
    required this.installSource,
    this.campaign,
    this.adGroup,
    this.creative,
    this.deepLinkUrl,
    this.idfaAvailable = false,
    this.idfa,
    this.gaid,
    this.attributionModel = AttributionModel.lastTouch,
    this.utmParameters = const {},
    required this.installTimestamp,
  });
}

enum AttributionModel { firstTouch, lastTouch }

/// Simulates attribution tracking, deep-link handling, campaign tracking,
/// UTM parsing, and IDFA/GAID collection status.
class AttributionService {
  AttributionData? _cachedAttribution;

  // ------------------------------------------------------------------
  // Install attribution (mock)
  // ------------------------------------------------------------------

  Future<AttributionData> getInstallAttribution() async {
    if (_cachedAttribution != null) return _cachedAttribution!;

    // Simulate network delay for attribution fetch.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _cachedAttribution = AttributionData(
      installSource: 'Facebook Ads',
      campaign: 'summer_promo_2024',
      adGroup: 'us_18_35_interest',
      creative: 'video_testimonial_v2',
      deepLinkUrl: 'myapp://promo?code=SUMMER24',
      idfaAvailable: false,
      idfa: null,
      gaid: 'b5f3c8a2-1234-5678-abcd-ef0123456789',
      attributionModel: AttributionModel.lastTouch,
      utmParameters: {
        'utm_source': 'facebook',
        'utm_medium': 'cpc',
        'utm_campaign': 'summer_promo_2024',
        'utm_content': 'video_testimonial_v2',
      },
      installTimestamp: DateTime.now().subtract(const Duration(days: 7)),
    );

    debugPrint('[AttributionService] attribution fetched');
    return _cachedAttribution!;
  }

  // ------------------------------------------------------------------
  // Deep link handling (mock)
  // ------------------------------------------------------------------

  Future<String?> handleDeepLink(String url) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('[AttributionService] deep link: ${uri.path}');
      return uri.path;
    } catch (e) {
      debugPrint('[AttributionService] deep link error: $e');
      return null;
    }
  }

  // ------------------------------------------------------------------
  // UTM parameter parsing
  // ------------------------------------------------------------------

  Map<String, String> parseUtmParameters(String url) {
    try {
      final uri = Uri.parse(url);
      final utm = <String, String>{};
      for (final key in [
        'utm_source',
        'utm_medium',
        'utm_campaign',
        'utm_term',
        'utm_content',
      ]) {
        final value = uri.queryParameters[key];
        if (value != null) utm[key] = value;
      }
      return utm;
    } catch (e) {
      debugPrint('[AttributionService] UTM parse error: $e');
      return {};
    }
  }

  // ------------------------------------------------------------------
  // IDFA / GAID status
  // ------------------------------------------------------------------

  Future<bool> isIdfaAvailable() async {
    // In a real implementation this would check ATT status on iOS.
    return false;
  }

  Future<String?> getAdvertisingId() async {
    // Returns mock GAID on Android, null on iOS when ATT denied.
    return _cachedAttribution?.gaid;
  }

  // ------------------------------------------------------------------
  // Campaign tracking
  // ------------------------------------------------------------------

  Future<Map<String, String>> getCampaignData() async {
    final attr = await getInstallAttribution();
    return {
      'source': attr.installSource,
      if (attr.campaign != null) 'campaign': attr.campaign!,
      if (attr.adGroup != null) 'ad_group': attr.adGroup!,
      if (attr.creative != null) 'creative': attr.creative!,
    };
  }

  void clearCache() {
    _cachedAttribution = null;
  }
}
