import 'dart:convert';
import 'dart:io';

import 'package:gokwik/api/snowplow_client.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:snowplow_tracker/snowplow_tracker.dart';
import '../config/cache_instance.dart';
import '../config/types.dart';
import 'sdk_config.dart';

class SnowplowTrackerService {
  static SnowplowTracker? _snowplowClient;

  // Helper to fetch environment
  static Future<String> _getEnvironment() async {
    return (await cacheInstance.getValue(KeyConfig.gkEnvironmentKey)) ??
        'sandbox';
  }

  // Helper to initialize Snowplow client
  static Future<SnowplowTracker?> _initializeSnowplowClient() async {
    final snowplowTrackingEnabled =
        (await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled)) ==
            'true';

    if (!snowplowTrackingEnabled) return null;

    final mid = (await cacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
    final environment = await _getEnvironment();
    final shopDomain =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

    return await SnowplowClient.getSnowplowClient(
      InitializeSdkProps(
          mid: mid,
          environment:
              Environment.values.firstWhere((e) => e.name == environment),
          shopDomain: shopDomain,
          isSnowplowTrackingEnabled: snowplowTrackingEnabled),
    );
  }

  // Generic context creation helper
  static Future<SelfDescribing> _createContext(
      String schemaPath, Map<String, dynamic> data) async {
    final environment = await _getEnvironment();
    final schema = 'iglu:${SdkConfig.getSchemaVendor(environment)}/$schemaPath';
    return SelfDescribing(schema: schema, data: data);
  }

  // Context Generators
  static Future<SelfDescribing> getCartContext(String cartId) async {
    return _createContext(
        'cart/jsonschema/1-0-0', {'id': cartId, 'token': cartId});
  }

  static Future<SelfDescribing> getUserContext() async {
    final userJson =
        (await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey)) ?? '{}';
    final user = VerifiedUser.fromJson(jsonDecode(userJson));

    final phone = user.phone.replaceAll(RegExp(r'^\+91'), '');
    final numericPhoneNumber = int.tryParse(phone ?? '');

    return _createContext(
      'user/jsonschema/1-0-0',
      {
        'phone': numericPhoneNumber ?? '',
        'email': user.email ?? '',
      },
    );
  }

  static Future<SelfDescribing> getProductContext(
      TrackProductEventArgs contextData) async {
    return _createContext('product/jsonschema/1-0-0', contextData.toJson());
  }

  static Future<SelfDescribing> getDeviceInfoContext() async {
    final deviceFCM =
        await cacheInstance.getValue(KeyConfig.gkNotificationToken);
    final deviceInfoJson = await cacheInstance.getValue(KeyConfig.gkDeviceInfo);
    final deviceInfo = deviceInfoJson != null ? jsonDecode(deviceInfoJson) : {};

    return _createContext(
      'user_device/jsonschema/1-0-0',
      {
        'device_id': deviceInfo[KeyConfig.gkDeviceUniqueId],
        'android_ad_id':
            Platform.isAndroid ? deviceInfo[KeyConfig.gkGoogleAdId] : '',
        'ios_ad_id': Platform.isIOS ? deviceInfo[KeyConfig.gkGoogleAdId] : '',
        'fcm_token': deviceFCM ?? '',
      },
    );
  }

  static Future<SelfDescribing> getCollectionsContext(
      String collectionId) async {
    return _createContext(
        'product/jsonschema/1-0-0', {'product_id': collectionId});
  }

  // Generic event tracker
  static Future<void> _trackEvent({
    required String pageUrl,
    required String pageTitle,
    required List<SelfDescribing> contexts,
    String? productId,
    String? cartId,
  }) async {
    final isTrackingEnabled =
        await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
    if (isTrackingEnabled == 'false') return;

    try {
      final snowplow = await _initializeSnowplowClient();
      if (snowplow == null) return;

      await snowplow.track(
        SelfDescribing(
          schema: 'iglu:com.snowplowanalytics.mobile/web_page/jsonschema/1-0-0',
          data: {
            'page_url': pageUrl,
            'page_title': pageTitle,
            'product_id': productId,
            'cart_id': cartId,
          },
        ),
        contexts: contexts,
      );
    } catch (error) {
      print('Error tracking event: $error');
      throw error;
    }
  }

  // Specific Event Trackers
  static Future<void> trackProductEvent(TrackProductEventArgs args) async {
    final isTrackingEnabled =
        await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
    if (isTrackingEnabled == 'false') return;

    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';
    final pageUrl = '$merchantUrl/product/${args.productId}';

    final contexts = await Future.wait([
      getProductContext(args),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(
      pageUrl: pageUrl,
      pageTitle: args.name ?? '',
      contexts: contexts,
      productId: args.productId,
    );
  }

  static Future<void> trackCartEvent(TrackCartEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';
    final pageUrl = '$merchantUrl/cart';

    final contexts = await Future.wait([
      getCartContext(args.cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(
      pageUrl: pageUrl,
      pageTitle: 'Cart',
      contexts: contexts,
      cartId: args.cartId,
    );
  }

  static Future<void> trackCollectionsEvent(
      TrackCollectionsEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';
    final pageUrl = '$merchantUrl/collections/${args.handle}';

    final contexts = await Future.wait([
      getCollectionsContext(args.collectionId),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(
      pageUrl: pageUrl,
      pageTitle: args.name,
      contexts: contexts,
    );
  }

  // Custom Event Tracker
  static Future<void> sendCustomEventToSnowPlow(
      Map<String, dynamic> eventObject) async {
    final snowplowTrackingEnabled =
        await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
    if (snowplowTrackingEnabled == 'false') return;

    final mid = (await cacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
    final environment = await _getEnvironment();
    final shopDomain =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

    final snowplow = await SnowplowClient.getSnowplowClient(
      InitializeSdkProps(
          mid: mid,
          environment:
              Environment.values.firstWhere((e) => e.name == environment),
          shopDomain: shopDomain,
          isSnowplowTrackingEnabled: snowplowTrackingEnabled == 'true'),
    );

    final filteredData = _filterEventValuesAsPerStructSchema(eventObject);

    await snowplow?.track(
      SelfDescribing(
        schema:
            'iglu:com.snowplowanalytics.snowplow/link_click/jsonschema/1-0-1',
        data: filteredData,
      ),
    );
  }

  static Map<String, dynamic> _filterEventValuesAsPerStructSchema(
      Map<String, dynamic> eventObject) {
    const structEventProperties = [
      'category',
      'action',
      'label',
      'property',
      'value',
      'property_1',
      'value_1',
      'property_2',
      'value_2',
      'property_3',
      'value_3',
      'property_4',
      'value_4',
      'property_5',
      'value_5',
    ];

    const intTypes = ['value', 'value_5'];

    final filtered = <String, dynamic>{};

    for (final prop in structEventProperties) {
      if (eventObject.containsKey(prop)) {
        final value = eventObject[prop];
        filtered[prop] = intTypes.contains(prop)
            ? int.tryParse(value.toString()) ?? 0
            : value.toString();
      }
    }

    return filtered;
  }

  static Future<void> snowplowStructuredEvent(dynamic args) async {
    try {
      final snowplowTrackingEnabled =
          await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
      if (snowplowTrackingEnabled == 'false') return;

      final mid =
          (await cacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
      final environment = await _getEnvironment();
      final shopDomain =
          (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

      final snowplow = await SnowplowClient.getSnowplowClient(
        InitializeSdkProps(
            mid: mid,
            environment:
                Environment.values.firstWhere((e) => e.name == environment),
            shopDomain: shopDomain,
            isSnowplowTrackingEnabled: snowplowTrackingEnabled == 'true'),
      );

      await snowplow?.track(
        SelfDescribing(schema: 'cds', data: args),
      );
    } catch (error) {
      print('Error in snowplowStructuredEvent: $error');
      throw error;
    }
  }

  static Future<void> trackOtherEvent([TrackOtherEventArgs? args]) async {
    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';
    final pageUrl = merchantUrl.isNotEmpty ? '$merchantUrl/cart' : '';

    final contexts = await Future.wait([
      getCartContext(args?.cartId ?? ''),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(
      pageUrl: pageUrl,
      pageTitle: 'Cart',
      contexts: contexts,
      cartId: args?.cartId,
    );
  }
}
