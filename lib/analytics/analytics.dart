import 'package:flutter/foundation.dart';
import 'webengage.dart';
import 'moengage.dart';

// Re-export analytics events for easy access
export 'config.dart' show AnalyticsEvents;

// Re-export initialization functions
export 'webengage.dart' show initializeKpWebengage;
export 'moengage.dart' show initializeKpMoengage;

// Re-export individual tracking functions for advanced use cases
export 'moengage.dart' show trackMoEngageEvents;

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
/// Returns void
void trackAnalyticsEvent(String eventName, [EventProperties? properties]) {
  // Input validation
  if (eventName.isEmpty || eventName.trim().isEmpty) {
    if (kDebugMode) {
      print('[Analytics] Invalid event name provided. Event name must be a non-empty string.');
    }
    return;
  }

  final EventProperties eventProperties = properties ?? {};

  try {
    // Track event in MoEngage
    trackMoEngageEvents(eventName, eventProperties);
    
    // Track event in WebEngage using the enhanced sendEventToWebEngage function
    // which handles user identification and attributes
    sendEventToWebEngage(eventName, eventProperties);

    if (kDebugMode) {
      print('[Analytics] Successfully tracked event across all platforms: $eventName');
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
/// Returns Future<void>
Future<void> initializeAnalytics(
  String moeAppId, {
  bool webengageAutoRegister = true,
}) async {
  try {
    // Initialize MoEngage (async)
    await initializeKpMoengage(moeAppId);
    
    // Initialize WebEngage (sync)
    initializeKpWebengage(webengageAutoRegister);

    if (kDebugMode) {
      print('[Analytics] Successfully initialized all analytics services');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[Analytics] Failed to initialize analytics services: $error');
    }
    rethrow;
  }
}
