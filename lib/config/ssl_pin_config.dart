/// SSL Pinning Configuration for Base URLs
///
/// This file contains the public key hashes for SSL certificate pinning.
/// Since all API calls go through Dio with baseURL, we only need to pin the base domains.
///
/// IMPORTANT:
/// - These are SHA-256 hashes of the public keys, not the certificates themselves
/// - Always maintain backup pins for certificate rotation
/// - Update these hashes before certificate expiry (60 days recommended)
///
/// To get the SHA-256 hash of a domain's public key:
/// ```bash
/// openssl s_client -servername DOMAIN -connect DOMAIN:443 | \
///   openssl x509 -pubkey -noout | \
///   openssl pkey -pubin -outform der | \
///   openssl dgst -sha256 -binary | \
///   openssl enc -base64
/// ```

/// SSL Pin Configuration for a domain
class SSLPinConfig {
  final String domain;
  final List<String> pins; // Array of SHA-256 hashes (primary + backup)

  const SSLPinConfig({
    required this.domain,
    required this.pins,
  });
}

/// SSL Certificate Pins for base URLs in each environment
///
/// NOTE: These are the actual hashes from your React Native configuration.
///
/// Each domain should have at least 2 pins:
/// 1. Primary pin (current certificate)
/// 2. Backup pin (for certificate rotation)
class SSLPinningConfig {
  static const Map<String, SSLPinConfig> _sslPinConfig = {
    'production': SSLPinConfig(
      domain: 'gkx.gokwik.co',
      pins: [
        'sha256//Z6UKxL7yChXrmZpCernNajog3qtc5/j/iQo67JEAE0=', // Primary certificate (retrieved 2025-12-01)
        'sha256//Z6UKxL7yChXrmZpCernNajog3qtc5/j/iQo67JEAE0=', // Backup - using same for now, update during cert rotation
      ],
    ),
    'sandbox': SSLPinConfig(
      domain: 'api-gw-v4.dev.gokwik.io',
      pins: [
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Primary certificate (retrieved 2025-12-01)
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Backup - using same for now, update during cert rotation
      ],
    ),
    'qa': SSLPinConfig(
      domain: 'api-gw-v4.dev.gokwik.io',
      pins: [
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Primary certificate (retrieved 2025-12-01)
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Backup - using same for now, update during cert rotation
      ],
    ),
    'dev': SSLPinConfig(
      domain: 'api-gw-v4.dev.gokwik.io',
      pins: [
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Primary certificate (retrieved 2025-12-01)
        'sha256/OXsKjgDT5jKYotwaQAR0l1MzhHKA8YxAsYnG4TW50/s=', // Backup - using same for now, update during cert rotation
      ],
    ),
  };

  /// Get SSL pins for a specific environment
  static SSLPinConfig getSSLPinsForEnvironment(String environment) {
    return _sslPinConfig[environment] ?? _sslPinConfig['production']!;
  }

  /// Extract domain from URL
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      // If URL parsing fails, try to extract domain manually
      final match = RegExp(r'^(?:https?://)?([^/]+)').firstMatch(url);
      return match?.group(1) ?? url;
    }
  }

  /// Get all configured domains for certificate pinning
  static Map<String, List<String>> getAllPinnedDomains() {
    final Map<String, List<String>> pinnedDomains = {};
    
    for (var config in _sslPinConfig.values) {
      // Remove 'sha256/' prefix and keep only the hash for Dio
      final cleanPins = config.pins
          .map((pin) => pin.replaceAll('sha256/', '').replaceAll('sha256//', ''))
          .toList();
      pinnedDomains[config.domain] = cleanPins;
    }
    
    return pinnedDomains;
  }

  /// Get pins for a specific domain
  static List<String> getPinsForDomain(String domain) {
    for (var config in _sslPinConfig.values) {
      if (config.domain == domain) {
        // Remove 'sha256/' prefix and keep only the hash
        return config.pins
            .map((pin) => pin.replaceAll('sha256/', '').replaceAll('sha256//', ''))
            .toList();
      }
    }
    return [];
  }
}
