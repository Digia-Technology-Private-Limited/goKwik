import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'config/cdn_config.dart';

/// CDN Configuration options
class CDNConfigOptions {
  final String cdnBaseUrl;
  final String configPath;

  CDNConfigOptions({
    this.cdnBaseUrl = 'https://assets.gokwik.co',
    this.configPath = '/scripts/mobile-sdk-config',
  });

  CDNConfigOptions copyWith({
    String? cdnBaseUrl,
    String? configPath,
  }) {
    return CDNConfigOptions(
      cdnBaseUrl: cdnBaseUrl ?? this.cdnBaseUrl,
      configPath: configPath ?? this.configPath,
    );
  }
}

/// Fetches configuration from CDN with automatic caching
/// This function never throws errors - it always returns a valid config from cache, CDN, or local file
///
/// Strategy:
/// 1. Check if cache is valid (within 5 minutes) -> return cached config
/// 2. If cache invalid/missing -> fetch from CDN URL
/// 3. If CDN fetch fails -> try to return stored config
/// 4. If all fails -> return local bundled kp-config.json
///
/// @param options CDN configuration options
/// @returns Future<CDNConfig> Configuration from CDN, cache, or local fallback
Future<CDNConfig> fetchConfigFromCDN([CDNConfigOptions? options]) async {
  // Ensure CDN config is initialized
  await cdnConfigInstance.initialize();
  
  try {
    final opts = CDNConfigOptions();
    
    // Strategy 1: Check cache validity first
    final isValid = await cdnConfigInstance.isCacheValid();
    
    if (isValid) {
      final cachedConfig = await cdnConfigInstance.getCachedConfig();
      if (cachedConfig != null) {
        // Alert: Config fetched from local cache
        debugPrint('🟢 [CDN Config] ✅ Data source: LOCAL CACHE (valid, within 24 hours)');
        _showConfigSourceNotification('Config loaded from local cache', isLocal: true);
        return cachedConfig;
      }
    }
    
    // Strategy 2: Cache is invalid or doesn't exist, fetch from CDN
    final url = '${opts.cdnBaseUrl}${opts.configPath}.json';

    try {
      // Alert: Fetching config from remote CDN
      debugPrint('🔵 [CDN Config] 🌐 Data source: Fetching from REMOTE CDN URL: $url');
      _showConfigSourceNotification('Fetching config from remote CDN...', isLocal: false);
      
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'KwikPass-SDK-Flutter',
          },
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // Process the CDN response (handles minified JSON)
        final jsonData = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;
        final processedConfig = cdnConfigInstance.processCDNResponse(jsonData);
        
        // Cache the fresh config with new timestamp
        await cdnConfigInstance.cacheConfig(processedConfig);
        
        // Alert: Successfully fetched from remote CDN
        debugPrint('🟢 [CDN Config] ✅ Data source: REMOTE CDN (successfully fetched and cached)');
        _showConfigSourceNotification('Config successfully fetched from remote CDN', isLocal: false);
        debugPrint("CDN CONFIG FETCHED: THIS IS PROCESSED CONFIG:::: $processedConfig");
        return processedConfig;
      } else {
        throw Exception('CDN returned status code: ${response.statusCode}');
      }
    } catch (cdnError) {
      // print('[CDN Config] ⚠️ CDN fetch failed: $cdnError');
      
      // Strategy 3: Try to return existing stored config if valid
      try {
        final storedConfig = await cdnConfigInstance.getStoredCDNConfig();
        if (storedConfig != null) {
          // Alert: Using stored config as fallback
          debugPrint('🟡 [CDN Config] ✅ Data source: STORED CONFIG (fallback, valid cache exists)');
          _showConfigSourceNotification('Using stored config (CDN unavailable)', isLocal: true);
          return storedConfig;
        }
      } catch (storageError) {
        // print('[CDN Config] ⚠️ Failed to retrieve stored config: $storageError');
      }
      
      // Strategy 4: Final fallback - use the local kp-config.json file
      // Alert: Using local bundled config as final fallback
      debugPrint('🟡 [CDN Config] ✅ Data source: LOCAL kp-config.json (final fallback)');
      _showConfigSourceNotification('Using local bundled config (fallback)', isLocal: true);
      final localConfig = await _loadLocalConfig();
      
      // Cache the local config for future use
      try {
        await cdnConfigInstance.cacheConfig(localConfig);
      } catch (cacheError) {
        // print('[CDN Config] ⚠️ Failed to cache local config: $cacheError');
      }
      
      return localConfig;
    }
  } catch (error) {
    // Ultimate fallback - if everything fails, return local config
    // print('[CDN Config] ❌ Unexpected error, using local kp-config.json: $error');
    return await _loadLocalConfig();
  }
}

/// Loads the local bundled kp-config.json file
Future<CDNConfig> _loadLocalConfig() async {
  try {
    final jsonString = await rootBundle.loadString('lib/kp-config.json');
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    return CDNConfig.fromJson(jsonData);
  } catch (error) {
    // print('[CDN Config] ❌ Failed to load local config: $error');
    // Return empty config as last resort
    return CDNConfig();
  }
}

/// Convenience function to get configuration with automatic caching
/// 
/// Usage:
/// ```dart
/// final config = await getConfig();
/// ```
/// 
/// With custom options:
/// ```dart
/// final config = await getConfig(
///   customOptions: CDNConfigOptions(
///     cdnBaseUrl: 'https://custom-cdn.com',
///     configPath: '/custom-path',
///   ),
/// );
/// ```
/// 
/// @param customOptions Optional custom configuration options
/// @returns Future<CDNConfig> Configuration from CDN or cache
Future<CDNConfig> getConfig({CDNConfigOptions? customOptions}) async {
  return fetchConfigFromCDN(customOptions);
}

/// Clears the cached configuration
/// 
/// Usage:
/// ```dart
/// await clearConfigCache();
/// ```
/// 
/// @returns Future<void>
Future<void> clearConfigCache() async {
  await cdnConfigInstance.clearConfigCache();
}

/// Gets the timestamp of the last cached config
/// 
/// Usage:
/// ```dart
/// final timestamp = await getConfigCacheTimestamp();
/// if (timestamp != null) {
///   final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
///   print('Config cached at: $cacheDate');
/// }
/// ```
/// 
/// @returns Future<int?> Timestamp in milliseconds or null if no cache exists
Future<int?> getConfigCacheTimestamp() async {
  return await cdnConfigInstance.getConfigCacheTimestamp();
}

/// Checks if the cached configuration is still valid
/// 
/// Usage:
/// ```dart
/// final isValid = await isConfigCacheValid();
/// if (!isValid) {
///   // Fetch fresh config
///   await getConfig();
/// }
/// ```
/// 
/// @returns Future<bool> True if cache is valid, false otherwise
Future<bool> isConfigCacheValid() async {
  return await cdnConfigInstance.isCacheValid();
}

/// Forces a refresh of the configuration from CDN
/// This will bypass the cache and fetch fresh data
/// 
/// Usage:
/// ```dart
/// final config = await refreshConfig();
/// ```
/// 
/// @param options Optional CDN configuration options
/// @returns Future<CDNConfig> Fresh configuration from CDN or fallback
Future<CDNConfig> refreshConfig([CDNConfigOptions? options]) async {
  // Clear the cache first
  await clearConfigCache();
  cdnConfigInstance.clearCache();
  
  // Fetch fresh config
  return await fetchConfigFromCDN(options);
}

/// Gets the current cached configuration without fetching from CDN
/// Returns null if no valid cache exists
/// 
/// Usage:
/// ```dart
/// final config = await getCachedConfigOnly();
/// if (config == null) {
///   // No cache, fetch from CDN
///   final freshConfig = await getConfig();
/// }
/// ```
/// 
/// @returns Future<CDNConfig?> Cached configuration or null
Future<CDNConfig?> getCachedConfigOnly() async {
  final isValid = await cdnConfigInstance.isCacheValid();
  if (!isValid) return null;
  
  return await cdnConfigInstance.getCachedConfig();
}

/// Preloads configuration in the background
/// This is useful to call during app initialization
/// 
/// Usage:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await SecureStorage.init();
///   
///   // Preload config in background
///   preloadConfig();
///   
///   runApp(MyApp());
/// }
/// ```
/// 
/// @param options Optional CDN configuration options
void preloadConfig([CDNConfigOptions? options]) {
  // Fire and forget - don't await
  fetchConfigFromCDN(options).then((config) {
    // print('[CDN Config] ✅ Preloaded configuration');
  }).catchError((error) {
    // print('[CDN Config] ⚠️ Preload failed: $error');
  });
}

/// Shows a notification about the config source
/// This can be used to display snackbars/toasts in the UI
void _showConfigSourceNotification(String message, {required bool isLocal}) {
  // This is a utility function that can be called from anywhere
  // For actual UI notifications, you can use a global key or callback
  
  // Option 1: Using debugPrint (always works)
  final icon = isLocal ? '📦' : '🌐';
  debugPrint('$icon [Config Notification] $message');
  
  // Option 2: If you have a BuildContext, you can show a SnackBar
  // This would need to be implemented where you have access to context
  // Example usage in your app:
  // ScaffoldMessenger.of(context).showSnackBar(
  //   SnackBar(
  //     content: Text(message),
  //     duration: Duration(seconds: 2),
  //     backgroundColor: isLocal ? Colors.orange : Colors.blue,
  //   ),
  // );
}

/// Gets configuration with retry logic
/// Attempts to fetch config multiple times before falling back
/// 
/// Usage:
/// ```dart
/// final config = await getConfigWithRetry(maxRetries: 3);
/// ```
/// 
/// @param options Optional CDN configuration options
/// @param maxRetries Maximum number of retry attempts (default: 2)
/// @param retryDelay Delay between retries in milliseconds (default: 1000)
/// @returns Future<CDNConfig> Configuration from CDN or fallback
Future<CDNConfig> getConfigWithRetry({
  CDNConfigOptions? options,
  int maxRetries = 2,
  int retryDelay = 1000,
}) async {
  int attempts = 0;
  Exception? lastError;
  
  while (attempts <= maxRetries) {
    try {
      return await fetchConfigFromCDN(options);
    } catch (error) {
      lastError = error as Exception;
      attempts++;
      
      if (attempts <= maxRetries) {
        // print('[CDN Config] ⚠️ Attempt $attempts failed, retrying in ${retryDelay}ms...');
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }
  }
  
  // All retries failed, return local config
  // print('[CDN Config] ❌ All $maxRetries retry attempts failed: $lastError');
  return await _loadLocalConfig();
}