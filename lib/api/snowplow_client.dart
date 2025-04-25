import 'dart:math';

import 'package:gokwik/config/key_congif.dart';
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

  static Future<void> initializeSnowplowClient(InitializeSdkProps args) async {
    final environment = args.environment;
    final mid = args.mid;

    final collectorUrl = SdkConfig.getSnowplowUrl(environment.name);
    final shopDomain = await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey);

    String appId = '';
    if (shopDomain != null && mid != null) {
      appId = mid;
    }

    // Initialize Snowplow tracker
    _snowplowClient = await Snowplow.createTracker(
      namespace: 'appTracker',
      endpoint: collectorUrl,
      method: Method.get,
      trackerConfig: TrackerConfiguration(
        appId: appId,
        // screenViewAutotracking: false,
        // lifecycleAutotracking: false,
        // installAutotracking: true,
        // exceptionAutotracking: true,
        // diagnosticAutotracking: false,
        // applicationContext: true,
        platformContext: true,
        geoLocationContext: false,
        sessionContext: true,
        // deepLinkContext: true,
        // screenContext: true,
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

  static Future<SnowplowTracker?> getSnowplowClient(
      [InitializeSdkProps? args]) async {
    final snowplowTrackingEnabled = await cacheInstance.getValue(
      KeyConfig.isSnowplowTrackingEnabled,
    );

    if (snowplowTrackingEnabled == 'false') {
      return _snowplowClient;
    }

    if (_snowplowClient == null && args != null) {
      await initializeSnowplowClient(args);
    }

    return _snowplowClient;
  }
}
