import 'package:moengage_flutter/moengage_flutter.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';

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
      print('[MoEngage] MOENGAGE WORKSPACE ID: $moeAppId');
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
      print('[MoEngage] ERROR IN INITIALIZING MO-ENGAGE: $error');
    }
    rethrow;
  }
}

/// Tracks MoEngage events with properties
///
/// [eventName] - The name of the event to track (must be non-empty string)
/// [properties] - Optional properties to attach to the event
/// [identifier] - MoEngage app identifier
/// [format] - Phone format rules (optional)
///
/// Supported property types: String, int, double, bool, DateTime
void trackMoEngageEvents(String eventName, [EventProperties properties = const {}, String identifier = "", String? format]) {
  String phoneFormat = '';
  
  // Input validation
  if (eventName.trim().isEmpty) {
    if (kDebugMode) {
      print('[MoEngage] Invalid event name provided. Event name must be a non-empty string.');
    }
    return;
  }

  if(identifier == "phone"){
    phoneFormat = format ?? "";
  }

  // Handle login and identified user events
  if ([AnalyticsEvents.appIdentifiedUser, AnalyticsEvents.appLoginSuccess].contains(eventName)) {
    final userIdentity = properties[identifier]?.toString();
    if (identifier == "phone" && userIdentity != null) {
      if (kDebugMode) {
        print('PHONE EVENT $phoneFormat');
      }
      loginMoEngage('$phoneFormat$userIdentity');
    } else if (userIdentity != null) {
      if (kDebugMode) {
        print('OTHER EVENT $userIdentity');
      }
      loginMoEngage(userIdentity);
    }
  }

  // Handle logout event
  if (eventName == AnalyticsEvents.appLogout) {
    logoutMoEngage();
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
          
          if (key == 'phone') {
            final formattedPhone = '$phoneFormat$value';
            properties['phone'] = formattedPhone;
            moEProperties.addAttribute(key, formattedPhone);
          } else {
            moEProperties.addAttribute(key, value);
          }
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
      print('[MoEngage] Successfully tracked event: $eventName');
      print(moEProperties);
    }

  } catch (error) {
    if (kDebugMode) {
      print('[MoEngage] Failed to track event \'$eventName\': $error');
    }
    
    // Optional: You could implement fallback tracking or error reporting here
    // For example, store failed events for retry later
  }
}

/// Logs in a user to MoEngage by setting their unique ID
///
/// [userUniqueId] - The unique identifier for the user (email, user ID, etc.)
///
/// Returns void
void loginMoEngage(String userUniqueId) {
  // Input validation
  if (userUniqueId.trim().isEmpty) {
    if (kDebugMode) {
      print('[MoEngage] Invalid user unique ID provided. User ID must be a non-empty string.');
    }
    return;
  }

  try {
    _moEngagePlugin?.identifyUser(userUniqueId.trim());
    
    if (kDebugMode) {
      print('[MoEngage] Successfully logged in user: $userUniqueId');
    }
  } catch (error) {
    if (kDebugMode) {
      print('[MoEngage] Failed to login user \'$userUniqueId\': $error');
    }
  }
}

/// Logs out the current user from MoEngage
///
/// Returns void
void logoutMoEngage() {
  try {
    _moEngagePlugin?.logout();
    
    if (kDebugMode) {
      print('[MoEngage] Successfully logged out user');
    }
  } catch (error) {
    if (kDebugMode) {
      print('[MoEngage] Failed to logout user: $error');
    }
  }
}