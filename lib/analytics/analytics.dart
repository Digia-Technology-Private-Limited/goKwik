import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/cache_instance.dart';
import '../config/key_congif.dart';
import '../config/types.dart';
import 'webengage.dart';
import 'moengage.dart';

// Re-export analytics events for easy access
export 'config.dart' show AnalyticsEvents;

// Re-export initialization functions
export 'webengage.dart' show initializeKpWebengage;
export 'moengage.dart' show initializeKpMoengage;

// Re-export individual tracking functions for advanced use cases
export 'moengage.dart' show trackMoEngageEvents, loginMoEngage, logoutMoEngage;

export 'webengage.dart' show
  setWebengageUserAttributes,
  setWebengageUserLogin,
  webengageUserLogout,
  trackWebengageEvents;

// Type definition for event properties
typedef EventProperties = Map<String, dynamic>;

/// Global function to track analytics events across both MoEngage and WebEngage
///
/// [eventName] - The name of the event to track
/// [properties] - Optional properties to attach to the event
///
/// Returns Future<void>
Future<void> trackAnalyticsEvent(String eventName, [EventProperties? properties]) async {
  final merchantConfig = await cacheInstance.getValue(KeyConfig.gkMerchantConfig);
  if (merchantConfig == null) {
    if (kDebugMode) {
      print('[Analytics] Merchant config not found in cache');
    }
    return;
  }

  final parsedMerchant = MerchantConfig.fromJson(jsonDecode(merchantConfig));
  final thirdPartyIntegrations = parsedMerchant.thirdPartyServiceProviders;

  final moEngageInfo = thirdPartyIntegrations.firstWhere(
    (item) => item.name == 'mo_engage',
    orElse: () => ThirdPartyServiceProvider(
      name: '',
      type: '',
      identifier: '',
      events: [],
      marketingEvents: [],
    ),
  );

  final webEngageInfo = thirdPartyIntegrations.firstWhere(
    (item) => item.name == 'web_engage',
    orElse: () => ThirdPartyServiceProvider(
      name: '',
      type: '',
      identifier: '',
      events: [],
      marketingEvents: [],
    ),
  );

  // Input validation
  if (eventName.isEmpty || eventName.trim().isEmpty) {
    if (kDebugMode) {
      print('[Analytics] Invalid event name provided. Event name must be a non-empty string.');
    }
    return;
  }

  final EventProperties eventProperties = properties ?? {};
try {
  // Track event in MoEngage only if we have valid MoEngage info
  if (moEngageInfo.name.isNotEmpty && moEngageInfo.identifier.isNotEmpty) {
    trackMoEngageEvents(eventName, eventProperties, moEngageInfo.identifier, moEngageInfo.rules['phoneFormat']);
    if (kDebugMode) {
      print('[Analytics] Successfully tracked event in MoEngage: $eventName');
    }
  }

  // Track event in WebEngage only if we have valid WebEngage info
  if (webEngageInfo.name.isNotEmpty && webEngageInfo.identifier.isNotEmpty) {
    sendEventToWebEngage(eventName, eventProperties, webEngageInfo.identifier, webEngageInfo.rules['phoneFormat']);
    if (kDebugMode) {
      print('[Analytics] Successfully tracked event in WebEngage: $eventName');
    }
  }

  if (kDebugMode) {
    print('[Analytics] Event tracking completed for: $eventName');
    print(eventProperties);
  }

} catch (error) {
  if (kDebugMode) {
    print('[Analytics] Failed to track event \'$eventName\': $error');
  }
}
}

/// Initialize both analytics services
///
/// [moeAppId] - MoEngage App ID
/// [webengageAutoRegister] - Whether to auto-register for WebEngage push notifications
///
/// Returns void
void initializeAnalytics(
  String moeAppId, {
  bool webengageAutoRegister = true,
}) {
  try {
    if (moeAppId.isNotEmpty) {
      // Initialize MoEngage
      initializeKpMoengage(moeAppId);
    }

    if (webengageAutoRegister) {
      // Initialize WebEngage
      initializeKpWebengage(webengageAutoRegister);
    }

    if (kDebugMode) {
      print('[Analytics] Successfully initialized all analytics services');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[Analytics] Failed to initialize analytics services: $error');
    }
  }
}
