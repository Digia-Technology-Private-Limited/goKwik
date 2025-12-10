/// Example usage of CDN Config in Flutter
///
/// This file demonstrates how to use the KwikPassCDNConfig class
/// to retrieve configuration values with automatic fallback to bundled config.

import 'cdn_config.dart';

class CDNConfigUsageExample {
  /// Example 0: Initialize CDN Config (REQUIRED - call this first!)
  static Future<void> initializeConfig() async {
    // MUST be called before using any config methods
    await cdnConfigInstance.initialize();
    print('CDN Config initialized');
  }

  /// Example 1: Getting a key value (synchronous after initialization)
  void exampleGetKey() {
    // Get a specific key from CDN config or fallback to bundled config
    final gkMode = cdnConfigInstance.getKeys('gkMode');
    print('GK Mode: $gkMode');
    
    // Using the helper method with default fallback
    final gkModeWithDefault = cdnConfigInstance.getKeyOrDefault('gk-mode');
    print('GK Mode with default: $gkModeWithDefault');
  }

  /// Example 2: Getting an API endpoint (synchronous)
  void exampleGetEndpoint() {
    // Get a specific endpoint
    final verifyCodeEndpoint = cdnConfigInstance.getEndpoint('verifyCode');
    print('Verify Code Endpoint: $verifyCodeEndpoint');
    
    // Using the helper method with default fallback
    final endpoint = cdnConfigInstance.getEndpointOrDefault('kp/api/v2/auth/otp/verify');
    print('Endpoint with default: $endpoint');
  }

  /// Example 3: Getting environment configuration (synchronous)
  void exampleGetEnvironment() {
    // Get production environment config
    final prodEnv = cdnConfigInstance.getEnvironment('production');
    if (prodEnv != null) {
      print('Production Base URL: ${prodEnv.baseUrl}');
      print('Production Snowplow URL: ${prodEnv.snowplowUrl}');
      print('Production Schema Vendor: ${prodEnv.schemaVendor}');
      print('Production Checkout URLs: ${prodEnv.checkoutUrl}');
    }
    
    // Get sandbox environment config
    final sandboxEnv = cdnConfigInstance.getEnvironmentOrDefault('sandbox');
    if (sandboxEnv != null) {
      print('Sandbox Base URL: ${sandboxEnv.baseUrl}');
    }
  }

  /// Example 4: Getting analytics events (synchronous)
  void exampleGetAnalyticsEvent() {
    // Get a specific analytics event
    final loginEvent = cdnConfigInstance.getAnalyticsEvent('WHATSAPP_LOGGED_IN');
    print('WhatsApp Login Event: $loginEvent');
    
    // Using the helper method with default fallback
    final event = cdnConfigInstance.getAnalyticsEventOrDefault('kp_whatsapp_logged_in');
    print('Event with default: $event');
  }

  /// Example 5: Getting API headers (synchronous)
  void exampleGetHeader() {
    // Get a specific header
    final authHeader = cdnConfigInstance.getHeader('authorization');
    print('Authorization Header: $authHeader');
    
    // Using the helper method with default fallback
    final header = cdnConfigInstance.getHeaderOrDefault('Authorization');
    print('Header with default: $header');
  }

  /// Example 6: Getting checkout configuration (synchronous)
  void exampleGetCheckout() {
    // Get entire checkout config
    final checkoutConfig = cdnConfigInstance.getCheckout();
    print('Checkout Config: $checkoutConfig');
    
    // Get specific checkout property
    final upiPackages = cdnConfigInstance.getCheckout('upi_packages');
    print('UPI Packages: $upiPackages');
    
    // Using the helper method
    final checkout = cdnConfigInstance.getCheckoutOrDefault('upi_packages');
    print('Checkout with default: $checkout');
  }

  /// Example 7: Getting Snowplow schema (synchronous)
  void exampleGetSnowplowSchema() {
    // Get Snowplow schema
    final schema = cdnConfigInstance.getSnowplowSchema();
    print('Snowplow Schema: $schema');
    
    // Access specific schema
    print('Cart Schema: ${schema['cart']}');
    print('User Schema: ${schema['user']}');
    
    // Using the helper method
    final schemaWithDefault = cdnConfigInstance.getSnowplowSchemaOrDefault();
    print('Schema with default: $schemaWithDefault');
  }

  /// Example 8: Caching CDN configuration
  Future<void> exampleCachingConfig() async {
    // Simulate fetching config from CDN API
    final Map<String, dynamic> cdnResponse = {
      'analytics': {
        'events': {
          'CUSTOM_EVENT': 'kp_custom_event',
        }
      },
      'api': {
        'endpoints': {
          'customEndpoint': 'kp/api/v1/custom',
        }
      },
      'keys': {
        'customKey': 'custom-key-value',
      },
      'version': '2.0.0',
    };
    
    // Process and cache the CDN response
    final config = cdnConfigInstance.processCDNResponse(cdnResponse);
    await cdnConfigInstance.cacheConfig(config);
    
    print('CDN config cached successfully');
    
    // Check if cache is valid
    final isValid = await cdnConfigInstance.isCacheValid();
    print('Cache is valid: $isValid');
    
    // Get cached config
    final cachedConfig = await cdnConfigInstance.getCachedConfig();
    print('Cached config version: ${cachedConfig?.version}');
  }

  /// Example 9: Using synchronous methods (from in-memory cache)
  void exampleSyncMethods() {
    // These methods work with in-memory cache only
    // They return null if config is not in cache or expired
    
    final config = cdnConfigInstance.getCDNConfig();
    if (config != null) {
      print('Config from memory cache: ${config.version}');
    } else {
      print('No valid config in memory cache');
    }
  }

  /// Example 10: Cache management
  Future<void> exampleCacheManagement() async {
    // Get cache timestamp
    final timestamp = await cdnConfigInstance.getConfigCacheTimestamp();
    if (timestamp != null) {
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      print('Config cached at: $cacheDate');
    }
    
    // Clear config cache
    await cdnConfigInstance.clearConfigCache();
    print('Config cache cleared');
    
    // Clear in-memory cache
    cdnConfigInstance.clearCache();
    print('In-memory cache cleared');
  }

  /// Example 11: Complete workflow
  Future<void> exampleCompleteWorkflow() async {
    // 1. Try to get config from cache
    var config = cdnConfigInstance.getCDNConfig();
    
    if (config == null) {
      // 2. Try to get from storage
      config = await cdnConfigInstance.getStoredCDNConfig();
    }
    
    if (config == null) {
      // 3. Fetch from CDN API (simulated)
      print('Fetching fresh config from CDN...');
      
      // Simulate API call
      final cdnResponse = {
        'version': '2.1.0',
        'keys': {'newKey': 'new-value'},
      };
      
      // 4. Process and cache the response
      config = cdnConfigInstance.processCDNResponse(cdnResponse);
      cdnConfigInstance.setCDNConfig(config);
    }
    
    // 5. Use the config
    print('Using config version: ${config.version}');
    
    // 6. Get specific values with automatic fallback (now synchronous)
    final endpoint = cdnConfigInstance.getEndpointOrDefault('kp/api/v1/health/merchant');
    print('Health check endpoint: $endpoint');
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    print('=== CDN Config Usage Examples ===\n');
    
    print('--- Example 0: Initialize Config (REQUIRED) ---');
    await initializeConfig();
    
    print('\n--- Example 1: Getting Keys ---');
    exampleGetKey();
    
    print('\n--- Example 2: Getting Endpoints ---');
    exampleGetEndpoint();
    
    print('\n--- Example 3: Getting Environments ---');
    exampleGetEnvironment();
    
    print('\n--- Example 4: Getting Analytics Events ---');
    exampleGetAnalyticsEvent();
    
    print('\n--- Example 5: Getting Headers ---');
    exampleGetHeader();
    
    print('\n--- Example 6: Getting Checkout Config ---');
    exampleGetCheckout();
    
    print('\n--- Example 7: Getting Snowplow Schema ---');
    exampleGetSnowplowSchema();
    
    print('\n--- Example 8: Caching Config ---');
    await exampleCachingConfig();
    
    print('\n--- Example 9: Sync Methods ---');
    exampleSyncMethods();
    
    print('\n--- Example 10: Cache Management ---');
    await exampleCacheManagement();
    
    print('\n--- Example 11: Complete Workflow ---');
    await exampleCompleteWorkflow();
  }
}

/// Usage in your app:
/// 
/// ```dart
/// // Initialize storage and CDN config first (in main.dart)
/// await SecureStorage.init();
/// await cdnConfigInstance.initialize();
/// 
/// // Now use the singleton instance synchronously
/// final endpoint = cdnConfigInstance.getEndpoint('verifyCode');
/// 
/// // Or with fallback
/// final endpointWithFallback = cdnConfigInstance.getEndpointOrDefault('kp/api/v2/auth/otp/verify');
/// 
/// // Get environment config
/// final prodEnv = cdnConfigInstance.getEnvironment('production');
/// final baseUrl = prodEnv?.baseUrl ?? 'https://default-url.com';