import 'dart:math';

import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/config_constants.dart';
import 'package:snowplow_tracker/snowplow_tracker.dart';

import '../config/cache_instance.dart';
import '../config/types.dart';
import 'sdk_config.dart';

abstract class SnowplowClient {
  static SnowplowTracker? _snowplowClient;
  static String? _snowplowUserId;

  // Generate a UUID v4
  static String _generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (Match match) {
        final r = Random().nextInt(16);
        final v = match.group(0) == 'x' ? r : (r % 4) + 8;
        return v.toRadixString(16);
      },
    );
  }

  static Future<void> initializeSnowplowClient({
    required String mid,
    required Environment environment,
    String merchantType = 'shopify',
  }) async {

    final collectorUrl = SdkConfig.getSnowplowUrl(environment.name);

    String appId = mid;

    final integrationType =
        ['shopify', 'custom_shopify'].contains(merchantType.toLowerCase())
            ? 'APP_MAKER'
            : 'CUSTOM';

    final platformHeaderKey =
        cdnConfigInstance.getHeader(APIHeaderKeys.gkPlatform) ?? 'gk-platform';
    final integrationTypeHeaderKey =
        cdnConfigInstance.getHeader(APIHeaderKeys.kpIntegrationType) ??
            'kp-integration-type';

    // Initialize Snowplow tracker
    _snowplowClient = await Snowplow.createTracker(
      namespace: 'appTracker',
      endpoint: collectorUrl,
      method: Method.get,
      requestHeaders: {
        platformHeaderKey: merchantType,
        integrationTypeHeaderKey: integrationType,
      },
      trackerConfig: TrackerConfiguration(
        appId: appId,
        screenEngagementAutotracking: false,
        applicationContext: true,
        platformContext: true,
        geoLocationContext: false,
        sessionContext: true,
      ),
    );

    // Get or create user ID
    _snowplowUserId = await cacheInstance.getStoredSnowplowUserId();
    if (_snowplowUserId == null) {
      final uuid = _generateUUID();
      _snowplowUserId = uuid;
      await cacheInstance.setSnowplowUserId(uuid);
    }

    // Set user ID for tracking
    _snowplowClient?.setUserId(_snowplowUserId!);
  }

  static Future<SnowplowTracker?> getSnowplowClient({
    String? mid,
    Environment? environment,
    String? merchantType,
  }) async {
    final snowplowTrackingEnabled = await cacheInstance.getValue(
      cdnConfigInstance.getKeys(StorageKeyKeys.isSnowplowTrackingEnabled)!,
    );

    if (snowplowTrackingEnabled == 'true' &&
        _snowplowClient == null &&
        mid != null &&
        environment != null) {
      await initializeSnowplowClient(
        mid: mid,
        environment: environment,
        merchantType: merchantType ?? 'shopify',
      );
    }

    return _snowplowClient;
  }
}
