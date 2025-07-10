import 'package:moengage_flutter/moengage_flutter.dart';
import 'package:flutter/foundation.dart';

/// Type definition for event properties
typedef EventProperties = Map<String, dynamic>;

/// MoEngage plugin instance
MoEngageFlutter? _moEngagePlugin;

/// Initialize MoEngage with the provided app ID
///
/// [moeAppId] - The MoEngage app ID for initialization
///
/// Throws an exception if initialization fails
Future<void> initializeKpMoengage(String moeAppId) async {
  try {
    if (kDebugMode) {
      print('[MoEngage] MOENGAGE ID: $moeAppId');
    }
    
    // Initialize MoEngage with app ID
    _moEngagePlugin = MoEngageFlutter(moeAppId);

    // Initialize the plugin
    _moEngagePlugin!.initialise();
    
    if (kDebugMode) {
      print('[MoEngage] Successfully initialized with app ID: $moeAppId');
    }
  } catch (error) {
    if (kDebugMode) {
      print('[MoEngage] Initialization failed: $error');
    }
    rethrow;
  }
}

/// Tracks MoEngage events with properties
///
/// [eventName] - The name of the event to track (must be non-empty string)
/// [properties] - Optional properties to attach to the event
///
/// Supported property types: String, int, double, bool, DateTime
void trackMoEngageEvents(String eventName, [EventProperties properties = const {}]) {
  // Input validation
  if (eventName.trim().isEmpty) {
    if (kDebugMode) {
      print('[MoEngage] Invalid event name provided. Event name must be a non-empty string.');
    }
    return;
  }

  try {
    final MoEProperties moEProperties = MoEProperties();

    // Optimize property handling with better type checking and error handling
    for (final MapEntry<String, dynamic> entry in properties.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value == null) {
        if (kDebugMode) {
          print('[MoEngage] Skipping property \'$key\' with null/undefined value');
        }
        continue;
      }

      try {
        if (value is DateTime) {
          // Handle DateTime separately - check for valid date
          if (value.millisecondsSinceEpoch == 0) {
            if (kDebugMode) {
              print('[MoEngage] Skipping property \'$key\' with invalid DateTime value');
            }
            continue;
          }
          moEProperties.addAttribute(key, value.toIso8601String());
        } else if (value is String || value is int || value is double || value is bool) {
          // Handle all primitive types with addAttribute
          if (value is double && (value.isNaN || value.isInfinite)) {
            if (kDebugMode) {
              print('[MoEngage] Skipping property \'$key\' with invalid number value: $value');
            }
            continue;
          }
          moEProperties.addAttribute(key, value);
        } else {
          if (kDebugMode) {
            print('[MoEngage] Unsupported property type for \'$key\': ${value.runtimeType}. Supported types: String, int, double, bool, DateTime');
          }
        }
      } catch (propertyError) {
        if (kDebugMode) {
          print('[MoEngage] Error adding property \'$key\': $propertyError');
        }
      }
    }

    // Track the event
    _moEngagePlugin?.trackEvent(eventName.trim(), moEProperties);
    
    // Optional: Log successful tracking in development
    if (kDebugMode) {
      print('[MoEngage] Successfully tracked event: $eventName with properties: $properties');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[MoEngage] Failed to track event \'$eventName\': $error');
    }
    
    // Optional: You could implement fallback tracking or error reporting here
    // For example, store failed events for retry later
  }
}