import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'storege.dart';

/// Environment configuration interface
class EnvironmentConfig {
  final String baseUrl;
  final String snowplowUrl;
  final String schemaVendor;
  final Map<String, String> checkoutUrl;
  final String notifEventsUrl;

  EnvironmentConfig({
    required this.baseUrl,
    required this.snowplowUrl,
    required this.schemaVendor,
    required this.checkoutUrl,
    required this.notifEventsUrl,
  });

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) {
    return EnvironmentConfig(
      baseUrl: json['BASE_URL'] as String,
      snowplowUrl: json['SNOWPLOW_URL'] as String,
      schemaVendor: json['schemaVendor'] as String,
      checkoutUrl: Map<String, String>.from(json['CHECKOUT_URL'] as Map),
      notifEventsUrl: json['NOTIF_EVENTS_URL'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BASE_URL': baseUrl,
      'SNOWPLOW_URL': snowplowUrl,
      'schemaVendor': schemaVendor,
      'CHECKOUT_URL': checkoutUrl,
      'NOTIF_EVENTS_URL': notifEventsUrl,
    };
  }
}

/// CDN Configuration interface
class CDNConfig {
  final Map<String, String>? analyticsEvents;
  final Map<String, String>? apiEndpoints;
  final Map<String, EnvironmentConfig>? apiEnvironments;
  final Map<String, String>? apiHeaders;
  final Map<String, String>? keys;
  final String? version;
  final Map<String, dynamic>? additionalData;

  CDNConfig({
    this.analyticsEvents,
    this.apiEndpoints,
    this.apiEnvironments,
    this.apiHeaders,
    this.keys,
    this.version,
    this.additionalData,
  });

  factory CDNConfig.fromJson(Map<String, dynamic> json) {
    return CDNConfig(
      analyticsEvents: json['analytics']?['events'] != null
          ? Map<String, String>.from(json['analytics']['events'] as Map)
          : null,
      apiEndpoints: json['api']?['endpoints'] != null
          ? Map<String, String>.from(json['api']['endpoints'] as Map)
          : null,
      apiEnvironments: json['api']?['environments'] != null
          ? (json['api']['environments'] as Map).map(
              (key, value) => MapEntry(
                key.toString(),
                EnvironmentConfig.fromJson(value as Map<String, dynamic>),
              ),
            )
          : null,
      apiHeaders: json['api']?['headers'] != null
          ? Map<String, String>.from(json['api']['headers'] as Map)
          : null,
      keys: json['keys'] != null
          ? Map<String, String>.from(json['keys'] as Map)
          : null,
      version: json['version'] as String?,
      additionalData: json,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (analyticsEvents != null) {
      data['analytics'] = {'events': analyticsEvents};
    }
    
    if (apiEndpoints != null || apiEnvironments != null || apiHeaders != null) {
      data['api'] = {};
      if (apiEndpoints != null) data['api']['endpoints'] = apiEndpoints;
      if (apiEnvironments != null) {
        data['api']['environments'] = apiEnvironments!.map(
          (key, value) => MapEntry(key, value.toJson()),
        );
      }
      if (apiHeaders != null) data['api']['headers'] = apiHeaders;
    }
    
    if (keys != null) data['keys'] = keys;
    if (version != null) data['version'] = version;
    
    // Add any additional data
    if (additionalData != null) {
      additionalData!.forEach((key, value) {
        if (!data.containsKey(key)) {
          data[key] = value;
        }
      });
    }
    
    return data;
  }
}

/// KwikPass CDN Configuration Manager
class KwikPassCDNConfig {
  final Map<String, String?> _cache = {};
  
  // Cache duration: 5 minutes in milliseconds
  // static const int _cacheDuration = 5 * 60 * 1000;
  
  // Cache duration: 24 hours in milliseconds
  static const int _cacheDuration = 24 * 60 * 60 * 1000;
  
  static const String _configCacheKey = 'kwikpass_cdn_config';
  static const String _configTimestampKey = 'kwikpass_cdn_config_timestamp';
  
  // Bundled JSON config - loaded once during initialization
  late final Map<String, dynamic> _bundledConfig;
  bool _isInitialized = false;

  /// Initialize the CDN config by loading the bundled JSON from package
  /// This should be called once during app initialization
  Future<void> initialize() async {
    
    if (_isInitialized) return;
    
    try {
      // Load from package assets using package path
      final jsonString = await rootBundle.loadString('packages/gokwik/lib/kp-config.json');
      _bundledConfig = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _isInitialized = true;
    } catch (error) {
      // Fallback: try loading without package prefix (for development)
      try {
        final jsonString = await rootBundle.loadString('lib/kp-config.json');
        _bundledConfig = jsonDecode(jsonString) as Map<String, dynamic>;
        
        _isInitialized = true;
      } catch (fallbackError) {
        // ignore: avoid_print
        print('Error loading bundled config: $fallbackError');
        _bundledConfig = {};
        _isInitialized = true;
      }
    }
  }

  /// Ensures the config is initialized before use
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'CDN Config not initialized. Call cdnConfigInstance.initialize() in main() before using.'
      );
    }
  }

  /// Retrieves a value from the cache or SecureStorage
  Future<String?> getValue(String key) async {
    // Check if value is already in the cache
    if (_cache.containsKey(key) && _cache[key] != null) {
      return _cache[key];
    }

    // If not in cache, fetch it from SecureStorage
    try {
      final value = await SecureStorage.getSecureData(key);
      if (value != null) {
        _cache[key] = value;
        return value;
      }
      return null;
    } catch (error) {
      // ignore: avoid_print
      print('Error fetching key $key from SecureStorage: $error');
      return null;
    }
  }

  /// Sets a value in the cache and SecureStorage
  void setValue(String key, String value) {
    _cache[key] = value;
    try {
      SecureStorage.storeSecureData(key, value);
    } catch (error) {
      // ignore: avoid_print
      print('Error storing key $key in SecureStorage: $error');
    }
  }

  /// Clears the in-memory cache
  void clearCache() {
    _cache.clear();
  }

  /// Remove a value from the cache and SecureStorage
  void removeValue(String key) {
    _cache.remove(key);
    SecureStorage.clearSecureData(key);
  }

  /// Checks if cached CDN config is still valid (within cache duration)
  Future<bool> isCacheValid() async {
    try {
      final timestampStr = await getValue(_configTimestampKey);
      if (timestampStr == null) return false;
      
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return false;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return (now - timestamp) < _cacheDuration;
    } catch (error) {
      // ignore: avoid_print
      print('Error checking CDN config cache validity: $error');
      return false;
    }
  }

  /// Gets cached CDN configuration if available and valid
  Future<CDNConfig?> getCachedConfig() async {
    try {
      final isValid = await isCacheValid();
      if (!isValid) return null;
      
      final cachedConfigStr = await getValue(_configCacheKey);
      if (cachedConfigStr == null) return null;
      
      return CDNConfig.fromJson(jsonDecode(cachedConfigStr) as Map<String, dynamic>);
    } catch (error) {
      // ignore: avoid_print
      print('Error retrieving cached CDN config: $error');
      return null;
    }
  }

  /// Caches CDN configuration with current timestamp
  Future<void> cacheConfig(CDNConfig config) async {
    try {
      final configStr = jsonEncode(config.toJson());
      
      setValue(_configCacheKey, configStr);
      setValue(_configTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    } catch (error) {
      // ignore: avoid_print
      print('Error caching CDN config: $error');
    }
  }

  /// Clears the cached CDN configuration
  Future<void> clearConfigCache() async {
    try {
      removeValue(_configCacheKey);
      removeValue(_configTimestampKey);
    } catch (error) {
      // ignore: avoid_print
      print('Error clearing CDN config cache: $error');
    }
  }

  /// Gets the timestamp of the last cached CDN config
  Future<int?> getConfigCacheTimestamp() async {
    try {
      final timestampStr = await getValue(_configTimestampKey);
      return timestampStr != null ? int.tryParse(timestampStr) : null;
    } catch (error) {
      // ignore: avoid_print
      print('Error getting CDN config cache timestamp: $error');
      return null;
    }
  }

  /// Sets CDN config with timestamp for cache management
  void setCDNConfig(CDNConfig config) {
    final configStr = jsonEncode(config.toJson());
    _cache[_configCacheKey] = configStr;
    _cache[_configTimestampKey] = DateTime.now().millisecondsSinceEpoch.toString();
    SecureStorage.storeSecureData(_configCacheKey, configStr);
    SecureStorage.storeSecureData(_configTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// Gets CDN config from cache if valid, otherwise returns null
  CDNConfig? getCDNConfig() {
    final configStr = _cache[_configCacheKey];
    final timestampStr = _cache[_configTimestampKey];

    if (configStr == null || timestampStr == null) {
      return null;
    }

    final timestamp = int.tryParse(timestampStr);
    if (timestamp == null) return null;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (currentTime - timestamp > _cacheDuration) {
      return null;
    }

    try {
      return CDNConfig.fromJson(jsonDecode(configStr) as Map<String, dynamic>);
    } catch (error) {
      // ignore: avoid_print
      print('Error parsing cached CDN config: $error');
      return null;
    }
  }

  /// Gets stored CDN config from SecureStorage if valid
  Future<CDNConfig?> getStoredCDNConfig() async {
    try {
      final configStr = await SecureStorage.getSecureData(_configCacheKey);
      final timestampStr = await SecureStorage.getSecureData(_configTimestampKey);

      if (configStr == null || timestampStr == null) {
        return null;
      }

      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return null;
      
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (currentTime - timestamp > _cacheDuration) {
        return null;
      }

      return CDNConfig.fromJson(jsonDecode(configStr) as Map<String, dynamic>);
    } catch (error) {
      // ignore: avoid_print
      print('Error getting stored CDN config: $error');
      return null;
    }
  }

  /// Processes raw CDN response data
  CDNConfig processCDNResponse(dynamic rawData) {
    try {
      // If rawData is already a Map, convert it
      if (rawData is Map<String, dynamic>) {
        return CDNConfig.fromJson(rawData);
      }
      
      // If it's a string, try to parse as JSON
      if (rawData is String) {
        return CDNConfig.fromJson(jsonDecode(rawData) as Map<String, dynamic>);
      }
      
      throw Exception('Invalid CDN response format');
    } catch (error) {
      // ignore: avoid_print
      print('Error processing CDN response: $error');
      rethrow;
    }
  }

  /// Gets a specific storage key from CDN config using constant identifiers
  String? getKeys(String keyConstant) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();

      // Use the constant to get the property name, then look up the value
      if (cachedConfig?.keys?[keyConstant] != null) {
        final value = cachedConfig!.keys![keyConstant];
        return value;
      }
      
      // Fallback to default config using the same property name
      final defaultValue = (_bundledConfig['keys'] as Map<String, dynamic>?)?[keyConstant] as String?;
      return defaultValue;
    } catch (e) {
      return (_bundledConfig['keys'] as Map<String, dynamic>?)?[keyConstant] as String?;
    }
  }

  /// Gets a specific API endpoint from CDN config using constant identifiers
  String? getEndpoint(String endpointConstant) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();

      // Use the constant to get the property name, then look up the value
      if (cachedConfig?.apiEndpoints?[endpointConstant] != null) {
        final value = cachedConfig!.apiEndpoints![endpointConstant];
        return value;
      }
      
      // Fallback to default config using the same property name
      final defaultValue = (_bundledConfig['api']?['endpoints'] as Map<String, dynamic>?)?[endpointConstant] as String?;
      return defaultValue;
    } catch (e) {
      return (_bundledConfig['api']?['endpoints'] as Map<String, dynamic>?)?[endpointConstant] as String?;
    }
  }

  /// Gets a specific environment configuration from CDN config using constant identifiers
  EnvironmentConfig? getEnvironment(String envConstant) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();
      
      // Use the constant to get the property name, then look up the value
      if (cachedConfig?.apiEnvironments?[envConstant] != null) {
        final value = cachedConfig!.apiEnvironments![envConstant]!;
        return value;
      }
      
      // Fallback to default config using the same property name
      final envData = (_bundledConfig['api']?['environments'] as Map<String, dynamic>?)?[envConstant];
      if (envData != null) {
        final defaultValue = EnvironmentConfig.fromJson(envData as Map<String, dynamic>);
        return defaultValue;
      }
      return null;
    } catch (e) {
      final envData = (_bundledConfig['api']?['environments'] as Map<String, dynamic>?)?[envConstant];
      if (envData != null) {
        return EnvironmentConfig.fromJson(envData as Map<String, dynamic>);
      }
      return null;
    }
  }

  /// Gets a specific analytics event from CDN config using constant identifiers
  String? getAnalyticsEvent(String eventConstant) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();
      
      // Use the constant to get the property name, then look up the value
      if (cachedConfig?.analyticsEvents?[eventConstant] != null) {
        final value = cachedConfig!.analyticsEvents![eventConstant];
        return value;
      }
      
      // Fallback to default config using the same property name
      final defaultValue = (_bundledConfig['analytics']?['events'] as Map<String, dynamic>?)?[eventConstant] as String?;
      return defaultValue;
    } catch (e) {
      return (_bundledConfig['analytics']?['events'] as Map<String, dynamic>?)?[eventConstant] as String?;
    }
  }

  /// Gets a specific header from CDN config using constant identifiers
  String? getHeader(String headerConstant) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();
      
      // Use the constant to get the property name, then look up the value
      if (cachedConfig?.apiHeaders?[headerConstant] != null) {
        final value = cachedConfig!.apiHeaders![headerConstant];
        return value;
      }
      
      // Fallback to default config using the same property name
      final defaultValue = (_bundledConfig['api']?['headers'] as Map<String, dynamic>?)?[headerConstant] as String?;
      return defaultValue;
    } catch (e) {
      return (_bundledConfig['api']?['headers'] as Map<String, dynamic>?)?[headerConstant] as String?;
    }
  }

  /// Gets checkout configuration from CDN config
  dynamic getCheckout([String? key]) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();
      final checkout = cachedConfig?.additionalData?['checkout'];
      
      if (checkout != null) {
        return key != null ? checkout[key] : checkout;
      }
      
      final defaultCheckout = _bundledConfig['checkout'];
      if (key != null && defaultCheckout != null) {
        return defaultCheckout[key];
      }
      return defaultCheckout;
    } catch (e) {
      final checkout = _bundledConfig['checkout'];
      if (key != null && checkout != null) {
        return checkout[key];
      }
      return checkout;
    }
  }

  /// Gets a specific snowplow schema from CDN config using constant identifiers
  /// If no schema constant is provided, returns all schemas
  dynamic getSnowplowSchema([String? schemaConstant]) {
    _ensureInitialized();
    try {
      final cachedConfig = getCDNConfig();
      final schema = cachedConfig?.additionalData?['snowplow']?['schema'];
      
      // If no specific schema requested, return all schemas
      if (schemaConstant == null) {
        if (schema != null && (schema as Map).isNotEmpty) {
          return Map<String, String>.from(schema);
        }
        final bundledSchema = _bundledConfig['snowplow']?['schema'];
        return bundledSchema != null
            ? Map<String, String>.from(bundledSchema as Map)
            : <String, String>{};
      }
      
      // Use the constant to get the property name, then look up the value
      if (schema?[schemaConstant] != null) {
        final value = schema[schemaConstant];
        return value;
      }
      
      // Fallback to default config using the same property name
      final defaultValue = _bundledConfig['snowplow']?['schema']?[schemaConstant];
      return defaultValue;
    } catch (e) {
      if (schemaConstant != null) {
        return _bundledConfig['snowplow']?['schema']?[schemaConstant];
      }
      final bundledSchema = _bundledConfig['snowplow']?['schema'];
      return bundledSchema != null
          ? Map<String, String>.from(bundledSchema as Map)
          : <String, String>{};
    }
  }

}

/// Export a single instance
final cdnConfigInstance = KwikPassCDNConfig();