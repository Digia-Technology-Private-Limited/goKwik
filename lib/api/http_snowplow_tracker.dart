import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../config/cache_instance.dart';
import '../config/key_congif.dart';
import '../config/types.dart';
import 'sdk_config.dart';

class HttpSnowplowTracker {
  static final Dio _dio = Dio();
  static String? _userId;
  static String? _sessionId;
  static int _sessionIndex = 1;
  static DateTime? _lastEventTime;
  
  // Cache frequently accessed values
  static String? _cachedEnvironment;
  static String? _cachedAppId;
  static String? _cachedCollectorUrl;
  static Map<String, String>? _cachedScreenInfo;
  static String? _cachedTimezone;
  static String? _cachedLanguage;
  
  // Constants
  static const String _trackerVersion = 'flutter-1.0.0';
  static const String _trackerNamespace = 'appTracker';
  static const String _colorDepth = '24';
  static const String _charset = 'UTF-8';
  static const String _cookieEnabled = '1';
  static const int _sessionTimeoutMinutes = 30;
  
  static const Map<String, String> _timezoneMap = {
    'IST': 'Asia/Calcutta',
    'UTC': 'UTC',
    'EST': 'America/New_York',
    'PST': 'America/Los_Angeles',
    'CST': 'America/Chicago',
    'MST': 'America/Denver',
  };

  // Initialize the HTTP tracker
  static Future<void> initialize() async {
    if (_userId != null) return; // Already initialized
    
    _userId = await cacheInstance.getStoredSnowplowUserId();
    if (_userId == null) {
      _userId = const Uuid().v4();
      await cacheInstance.setSnowplowUserId(_userId!);
    }
    
    _sessionId = const Uuid().v4();
    _lastEventTime = DateTime.now();
    
    // Pre-cache static values
    await _cacheStaticValues();
  }

  // Cache static values that don't change during session
  static Future<void> _cacheStaticValues() async {
    _cachedEnvironment = await cacheInstance.getValue(KeyConfig.gkEnvironmentKey) ?? 'sandbox';
    _cachedAppId = await cacheInstance.getValue(KeyConfig.gkMerchantIdKey) ?? '';
    
    final url = SdkConfig.getSnowplowUrl(_cachedEnvironment!);
    _cachedCollectorUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    
    _cachedScreenInfo = _getScreenInfo();
    _cachedTimezone = _getTimezone();
    _cachedLanguage = _getLanguage();
  }

  // Generate a new session if needed (30 minutes timeout)
  static void _checkSession() {
    final now = DateTime.now();
    if (_lastEventTime == null || 
        now.difference(_lastEventTime!).inMinutes > _sessionTimeoutMinutes) {
      _sessionId = const Uuid().v4();
      _sessionIndex++;
    }
    _lastEventTime = now;
  }

  // Get dynamic timezone
  static String _getTimezone() {
    final now = DateTime.now();
    final timeZoneName = now.timeZoneName;
    
    // Check predefined mappings first
    if (_timezoneMap.containsKey(timeZoneName)) {
      return _timezoneMap[timeZoneName]!;
    }
    
    // Fallback to offset calculation for IST
    final offset = now.timeZoneOffset;
    if (offset.inHours == 5 && offset.inMinutes == 30) {
      return 'Asia/Calcutta';
    }
    
    return timeZoneName.isNotEmpty ? timeZoneName : 'UTC';
  }

  // Get dynamic screen information
  static Map<String, String> _getScreenInfo() {
    final view = ui.PlatformDispatcher.instance.views.first;
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    
    final logicalWidth = (physicalSize.width / devicePixelRatio).round();
    final logicalHeight = (physicalSize.height / devicePixelRatio).round();
    final physicalWidth = physicalSize.width.round();
    final physicalHeight = physicalSize.height.round();
    
    final logicalSize = '${logicalWidth}x${logicalHeight}';
    
    return {
      'res': logicalSize,
      'vp': logicalSize,
      'ds': '${physicalWidth}x${physicalHeight}',
    };
  }

  // Get dynamic language
  static String _getLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    return '${locale.languageCode}-${locale.countryCode ?? locale.languageCode.toUpperCase()}';
  }

  // Create base event payload
  static Future<Map<String, dynamic>> _createBasePayload(String eventType) async {
    await initialize();
    _checkSession();

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final platform = Platform.isAndroid || Platform.isIOS ? 'mob' : 'web';

    return {
      'e': eventType,
      'tv': _trackerVersion,
      'tna': _trackerNamespace,
      'aid': _cachedAppId!,
      'p': platform,
      'uid': _userId!,
      'sid': _sessionId!,
      'duid': _userId!,
      'vid': _sessionIndex.toString(),
      'dtm': timestamp,
      'stm': timestamp,
      'tz': _cachedTimezone!,
      'lang': _cachedLanguage!,
      'res': _cachedScreenInfo!['res']!,
      'vp': _cachedScreenInfo!['vp']!,
      'ds': _cachedScreenInfo!['ds']!,
      'cd': _colorDepth,
      'cs': _charset,
      'cookie': _cookieEnabled,
      'eid': const Uuid().v4(),
    };
  }

  // Validate payload has required fields
  static bool _validatePayload(Map<String, dynamic> payload) {
    const requiredFields = ['e', 'tv', 'tna', 'aid', 'p', 'uid', 'sid', 'vid', 'dtm', 'stm', 'eid'];
    
    for (final field in requiredFields) {
      final value = payload[field];
      if (value == null || value.toString().isEmpty) {
        print('Missing or empty required field: $field');
        return false;
      }
    }
    return true;
  }

  // Get user context
  static Future<Map<String, dynamic>?> _getUserContext() async {
    final userJson = await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
    if (userJson == null) return null;

    try {
      final user = jsonDecode(userJson);
      final phone = user['phone']?.replaceAll(RegExp(r'^\+91'), '');
      final numericPhoneNumber = int.tryParse(phone ?? '');

      if (numericPhoneNumber != null || user['email'] != null) {
        return {
          'schema': 'iglu:${SdkConfig.getSchemaVendor(_cachedEnvironment!)}/user/jsonschema/1-0-0',
          'data': {
            'phone': numericPhoneNumber?.toString() ?? '',
            'email': user['email'] ?? '',
          }
        };
      }
    } catch (e) {
      print('Error parsing user context: $e');
    }
    return null;
  }

  // Get device context
  static Future<Map<String, dynamic>> _getDeviceContext() async {
    final deviceFCM = await cacheInstance.getValue(KeyConfig.gkNotificationToken);
    final deviceInfoJson = await cacheInstance.getValue(KeyConfig.gkDeviceInfo);
    final deviceInfo = deviceInfoJson != null ? jsonDecode(deviceInfoJson) : <String, dynamic>{};

    return {
      'schema': 'iglu:${SdkConfig.getSchemaVendor(_cachedEnvironment!)}/user_device/jsonschema/1-0-0',
      'data': {
        'device_id': deviceInfo[KeyConfig.gkDeviceUniqueId] ?? '',
        'android_ad_id': Platform.isAndroid ? deviceInfo[KeyConfig.gkGoogleAdId] ?? '' : '',
        'ios_ad_id': Platform.isIOS ? deviceInfo[KeyConfig.gkGoogleAdId] ?? '' : '',
        'fcm_token': deviceFCM ?? '',
        'app_domain': deviceInfo[KeyConfig.gkAppDomain] ?? '',
        'device_type': Platform.operatingSystem.toLowerCase(),
        'app_version': deviceInfo[KeyConfig.gkAppVersion] ?? '',
      }
    };
  }

  // Get cart context
  static Map<String, dynamic>? _getCartContext(String? cartId) {
    if (cartId == null || cartId.isEmpty) return null;

    return {
      'schema': 'iglu:com.shopify/cart/jsonschema/1-0-0',
      'data': {
        'id': cartId,
        'token': cartId,
      }
    };
  }

  // Build contexts array
  static Future<List<Map<String, dynamic>>> _buildContexts({
    String? cartId,
    String? productId,
    String? collectionId,
    Map<String, dynamic>? customProperties,
  }) async {
    final contexts = <Map<String, dynamic>>[];
    
    // Add user context
    final userContext = await _getUserContext();
    if (userContext != null) contexts.add(userContext);
    
    // Add device context
    final deviceContext = await _getDeviceContext();
    contexts.add(deviceContext);
    
    // Add cart context
    final cartContext = _getCartContext(cartId);
    if (cartContext != null) contexts.add(cartContext);

    // Add custom context if provided
    if (customProperties != null && customProperties.isNotEmpty) {
      contexts.add({
        'schema': 'iglu:${SdkConfig.getSchemaVendor(_cachedEnvironment!)}/product/jsonschema/1-1-0',
        'data': {
          'product_id': productId,
          'collection_id': collectionId,
          ...customProperties,
        }..removeWhere((key, value) => value == null),
      });
    }
    return contexts;
  }

  // Helper method to print large JSON strings without truncation
  static void _printLargeJson(String label, String jsonString) {
    const int chunkSize = 800; // Safe chunk size for console output
    print('=== $label START ===');
    
    if (jsonString.length <= chunkSize) {
      print(jsonString);
    } else {
      for (int i = 0; i < jsonString.length; i += chunkSize) {
        int end = (i + chunkSize < jsonString.length) ? i + chunkSize : jsonString.length;
        print('${jsonString.substring(i, end)}');
      }
    }
    
    print('=== $label END ===');
  }

  // Send event to Snowplow collector
  static Future<void> _sendEvent(Map<String, dynamic> payload, String eventType) async {
    try {
      final jsonPayload = {
        'schema': 'iglu:com.snowplowanalytics.snowplow/payload_data/jsonschema/1-0-4',
        'data': [payload]
      };

      print('Sending $eventType to: $_cachedCollectorUrl/com.snowplowanalytics.snowplow/tp2');
      print('Event ID: ${payload['eid']}');

      final response = await _dio.post(
        '$_cachedCollectorUrl/com.snowplowanalytics.snowplow/tp2',
        data: jsonEncode(jsonPayload),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Snowplow Flutter Tracker $_trackerVersion',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('$eventType sent successfully');
      } else {
        print('Failed to send $eventType: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
    } catch (error) {
      print('Error sending $eventType: $error');
    }
  }

  // Check if tracking is enabled
  static Future<bool> _isTrackingEnabled() async {
    final isEnabled = await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
    return isEnabled == 'true';
  }

  // Track pageview event via HTTP
  static Future<void> trackPageView({
    required String pageUrl,
    required String pageTitle,
    String? cartId,
    String? productId,
    String? collectionId,
    Map<String, dynamic>? customProperties,
  }) async {
    if (!await _isTrackingEnabled()) return;

    print('Tracking pageview: $pageTitle - $pageUrl');

    final payload = await _createBasePayload('pv');
    payload['url'] = pageUrl;
    payload['page'] = pageTitle;

    if (!_validatePayload(payload)) {
      print('Invalid payload for pageview event');
      return;
    }

    final contexts = await _buildContexts(
      cartId: cartId,
      productId: productId,
      collectionId: collectionId,
      customProperties: customProperties,
    );

    if (contexts.isNotEmpty) {
      payload['cx'] = base64Encode(utf8.encode(jsonEncode({
        'schema': 'iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-0',
        'data': contexts,
      })));
    }

    // print payload in json string after cx property is added
    _printLargeJson('PAYLOAD JSON ', jsonEncode(payload));

    await _sendEvent(payload, 'pageview');
  }

  // Track structured event via HTTP
  static Future<void> trackStructuredEvent({
    required String category,
    required String action,
    String? label,
    String? property,
    double? value,
    List<Map<String, dynamic>>? contexts,
  }) async {
    if (!await _isTrackingEnabled()) return;

    final payload = await _createBasePayload('se');
    payload['se_ca'] = category;
    payload['se_ac'] = action;
    if (label != null) payload['se_la'] = label;
    if (property != null) payload['se_pr'] = property;
    if (value != null) payload['se_va'] = value.toString();

    if (!_validatePayload(payload)) {
      print('Invalid payload for structured event');
      return;
    }

    if (contexts != null && contexts.isNotEmpty) {
      // print contexts in json string
      _printLargeJson('CONTEXTS JSON', jsonEncode(contexts));
      
      payload['cx'] = base64Encode(utf8.encode(jsonEncode({
        'schema': 'iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-0',
        'data': contexts,
      })));
    }

    // print payload in json string after cx property is added
    _printLargeJson('PAYLOAD JSON', jsonEncode(payload));

    await _sendEvent(payload, 'structured event');
  }
}