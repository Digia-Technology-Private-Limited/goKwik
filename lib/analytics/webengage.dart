import 'package:webengage_flutter/webengage_flutter.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';

/// Type definition for event properties
typedef EventProperties = Map<String, dynamic>;

/// Constants for Flutter implementation
const String _countryCodeIndia = '+91';

/// Initializes WebEngage SDK
/// Note: WebEngage is initialized automatically via native configuration.
/// This function can be used for any additional setup if needed.
/// [autoRegister] - Whether to auto-register for push notifications (optional)
/// Returns void
void initializeKpWebengage([bool autoRegister = true]) {
  try {
    // Initialize WebEngage with auto-register option
    // Note: In Flutter, WebEngage is initialized automatically via native configuration
    // This function can be used for any additional setup if needed

    if (kDebugMode) {
      print('[WebEngage] SDK initialized successfully');
    }
  } catch (error) {
    if (kDebugMode) {
      print('[WebEngage] Failed to initialize:');
      print(error);
    }
    rethrow;
  }
}

/// Tracks WebEngage events with properties
/// [eventName] - The name of the event to track (must be non-empty string)
/// [properties] - Optional properties to attach to the event
/// Returns void
void trackWebengageEvents(String eventName, [EventProperties properties = const {}]) {
  // Input validation
  if (eventName.isEmpty || eventName.trim().isEmpty) {
    if (kDebugMode) {
      print('[WebEngage] Invalid event name provided. Event name must be a non-empty string.');
    }
    return;
  }

  try {
    final Map<String, dynamic> processedProperties = <String, dynamic>{};

    // Process properties with type checking and error handling
    for (final MapEntry<String, dynamic> entry in properties.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value == null) {
        if (kDebugMode) {
          print('[WebEngage] Skipping property \'$key\' with null/undefined value');
        }
        continue;
      }

      try {
        if (value is DateTime) {
          // Handle DateTime objects
          if (value.millisecondsSinceEpoch == 0) {
            if (kDebugMode) {
              print('[WebEngage] Skipping property \'$key\' with invalid Date value');
            }
            continue;
          }
          processedProperties[key] = value.toIso8601String();
        } else if (value is String || value is int || value is double || value is bool) {
          // Handle primitive types
          if (value is double && (value.isNaN || value.isInfinite)) {
            if (kDebugMode) {
              print('[WebEngage] Skipping property \'$key\' with invalid number value: $value');
            }
            continue;
          }
          processedProperties[key] = value;
        } else {
          if (kDebugMode) {
            print('[WebEngage] Unsupported property type for \'$key\': ${value.runtimeType}. Supported types: string, number, boolean, Date');
          }
        }
      } catch (propertyError) {
        if (kDebugMode) {
          print('[WebEngage] Error processing property \'$key\': $propertyError');
        }
      }
    }

    // Track the event using WebEngage static method
    WebEngagePlugin.trackEvent(eventName.trim(), processedProperties);

    // Optional: Log successful tracking in development
    if (kDebugMode) {
      print('[WebEngage] Successfully tracked event: $eventName');
      print(processedProperties);
    }

  } catch (error) {
    if (kDebugMode) {
      print('[WebEngage] Failed to track event \'$eventName\': $error');
    }

    // Optional: You could implement fallback tracking or error reporting here
    // For example, store failed events for retry later
  }
}

/// Sets user attributes in WebEngage
/// [attributes] - User attributes to set
/// Returns void
void setWebengageUserAttributes(EventProperties attributes) {
  try {
    // Process attributes with type checking
    for (final MapEntry<String, dynamic> entry in attributes.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value == null) {
        if (kDebugMode) {
          print('[WebEngage] Skipping attribute \'$key\' with null/undefined value');
        }
        continue;
      }

      try {
        dynamic processedValue;

        if (value is DateTime) {
          if (value.millisecondsSinceEpoch == 0) {
            if (kDebugMode) {
              print('[WebEngage] Skipping attribute \'$key\' with invalid Date value');
            }
            continue;
          }
          processedValue = value.toIso8601String();
        } else if (value is String || value is int || value is double || value is bool) {
          if (value is double && (value.isNaN || value.isInfinite)) {
            if (kDebugMode) {
              print('[WebEngage] Skipping attribute \'$key\' with invalid number value: $value');
            }
            continue;
          }
          processedValue = value;
        } else {
          if (kDebugMode) {
            print('[WebEngage] Unsupported attribute type for \'$key\': ${value.runtimeType}. Supported types: string, number, boolean, Date');
          }
          continue;
        }

        // Set individual attribute using WebEngage static method
        WebEngagePlugin.setUserAttribute(key, processedValue);

      } catch (attributeError) {
        if (kDebugMode) {
          print('[WebEngage] Error setting attribute \'$key\': $attributeError');
        }
      }
    }

    if (kDebugMode) {
      print('[WebEngage] Successfully set user attributes: $attributes');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[WebEngage] Failed to set user attributes: $error');
    }
  }
}

/// Sets user login in WebEngage
/// [userId] - The unique user identifier
/// Returns void
void setWebengageUserLogin(String userId) {
  try {
    if (userId.isEmpty || userId.trim().length == 0) {
      if (kDebugMode) {
        print('[WebEngage] Invalid user ID provided. User ID must be a non-empty string.');
      }
      return;
    }

    WebEngagePlugin.userLogin(userId.trim());

    if (kDebugMode) {
      print('[WebEngage] Successfully set user login: $userId');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[WebEngage] Failed to set user login: $error');
    }
  }
}

/// Logs out the current user in WebEngage
/// Returns void
void webengageUserLogout() {
  try {
    WebEngagePlugin.userLogout();

    if (kDebugMode) {
      print('[WebEngage] Successfully logged out user');
    }

  } catch (error) {
    if (kDebugMode) {
      print('[WebEngage] Failed to logout user: $error');
    }
  }
}

/// Sends event to WebEngage with user identification and attribute handling
/// Equivalent to the React Native sendEventToWebEngage function
/// [eventName] - The name of the event to track
/// [properties] - Event properties containing user data and other attributes
/// [identifier] - WebEngage identifier
/// [format] - Phone format rules (optional)
/// Returns void
void sendEventToWebEngage(String eventName, [EventProperties properties = const {}, String identifier = "", String? format]) {
  try {
    if (kDebugMode) {
      print("FORMAT AVAILABLE $format");
    }
    
    String phoneFormat = '';
    if (identifier == "phone") {
      phoneFormat = format ?? "";
    }
    // Handle login and identified user events
    if ([AnalyticsEvents.appIdentifiedUser, AnalyticsEvents.appLoginSuccess].contains(eventName)) {
      final userIdentity = properties[identifier]?.toString();
      if (identifier == "phone" && userIdentity != null) {
        setWebengageUserLogin('${phoneFormat}$userIdentity');
      } else if (userIdentity != null) {
        setWebengageUserLogin(userIdentity);
      }
    }

    // Handle logout event
    if (eventName == AnalyticsEvents.appLogout) {
      webengageUserLogout();
    }

    // Filter out null/undefined values from properties
    final Map<String, dynamic> payload = Map<String, dynamic>.fromEntries(
      properties.entries.where((entry) => entry.value != null)
    );

    final dynamic phone = payload['phone'];
    final dynamic email = payload['email'];

    // Handle phone-based user identification and attributes
    if (phone != null && phone is String && phone.isNotEmpty) {
      final String formattedPhone = '${phoneFormat.isNotEmpty ? phoneFormat : _countryCodeIndia}$phone';
      payload['phone'] = formattedPhone;
      
      // Set phone attribute
      setWebengageUserAttributes({'we_phone': formattedPhone});
    }

    // Handle email-based user identification and attributes
    if (email != null && email is String && email.isNotEmpty) {
      // Set email attribute
      setWebengageUserAttributes({'we_email': email});
    }

    // Always set user_tag attribute
    setWebengageUserAttributes({'user_tag': 'kwikPass'});

    // Track the event with processed payload
    trackWebengageEvents(eventName, payload);

  } catch (err) {
    if (kDebugMode) {
      print('Error While Sending Event To WebEngage');
      print(err);
    }
  }
}