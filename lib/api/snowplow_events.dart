import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:gokwik/api/snowplow_client.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:snowplow_tracker/snowplow_tracker.dart';
import '../config/cache_instance.dart';
import '../config/types.dart';
import 'sdk_config.dart';

class SnowplowTrackerService {
  static SnowplowTracker? _snowplowClient;
  String? eventId = Uuid().v4();

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
  static Future<SelfDescribing?> getCartContext(String cartId) async {
    if (cartId.isEmpty) {
      return null;
    }

    return SelfDescribing(
      schema: 'iglu:com.shopify/cart/jsonschema/1-0-0',
      data: {
        'id': cartId,
        'token': cartId,
      },
    );
  }

  static Future<SelfDescribing?> getUserContext() async {
    final userJson =
        (await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey)) ?? '{}';
    var user =
        userJson != "{}" ? VerifiedUser.fromJson(jsonDecode(userJson)) : null;

    var phone =
        user != null ? user!.phone.replaceAll(RegExp(r'^\+91'), '') : null;
    final numericPhoneNumber = int.tryParse(phone ?? '');

    if (numericPhoneNumber != null || (user != null && user.email != null)) {
      return _createContext(
        'user/jsonschema/1-0-0',
        {
          'phone': numericPhoneNumber?.toString() ?? '',
          'email': user!.email ?? '',
        },
      );
    }
    return null;
  }

  static Future<SelfDescribing> getProductContext(
      TrackProductEventContext contextData) async {
    return _createContext('product/jsonschema/1-1-0', contextData.toJson());
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
        'app_domain': deviceInfo[KeyConfig.gkAppDomain],
        'device_type': Platform.operatingSystem.toLowerCase(),
        'app_version': deviceInfo[KeyConfig.gkAppVersion],
      },
    );
  }

  static Future<SelfDescribing> getCollectionsContext(
      TrackCollectionEventContext params) async {
    return _createContext('product/jsonschema/1-1-0', {
      'collection_id': params.collection_id,
      'img_url': params.img_url ?? '',
      'collection_name': params.collection_name,
      'collection_handle': params.collection_handle,
      'type': params.type,
    });
  }

  static Future<SelfDescribing> getOtherEventsContext() async {
    return _createContext('product/jsonschema/1-1-0', {'type': 'other'});
  }

  // Generic event tracker
  static Future<void> _trackEvent(
    Map<String, dynamic> params,
    List<SelfDescribing> eventContext,
  ) async {
    final isTrackingEnabled =
        await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
    if (isTrackingEnabled == 'false') return;

    try {
      // Log event parameters and context
      print('EVENT PARAMS: ${jsonEncode(params)}');
      print('EVENT CONTEXT: ${jsonEncode(eventContext.map((e) => {
            'schema': e.schema,
            'data': e.data,
          }).toList())}');

      final snowplow = await _initializeSnowplowClient();
      if (snowplow == null) return;

      final data = {
        'page_url': params['pageUrl']?.toString() ?? '',
        'page_title': params['pageTitle']?.toString() ?? '',
        'product_id': params['productId']?.toString() ?? '',
        'cart_id': params['cartId']?.toString() ?? '',
      };

      await snowplow.track(
        SelfDescribing(
          schema: 'iglu:com.snowplowanalytics.mobile/web_page/jsonschema/1-0-0',
          data: data,
        ),
        contexts: eventContext,
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

    String cartId = args.cartId;
    if (cartId.contains('gid://shopify/Cart/')) {
      cartId = _trimCartId(cartId);
    }

    final params = {
      'page_url': args.pageUrl,
      'page_title': args.name ?? '',
      'product_id': args.productId.toString(),
      'variant_id': args.variantId.toString(),
    };

    if (cartId.isNotEmpty) {
      params['cart_id'] = cartId;
    }

    final contextDetails = TrackProductEventContext(
      productId: args.productId.toString(),
      imgUrl: args.imgUrl ?? '',
      variantId: args.variantId.toString(),
      productName: args.name ?? '',
      productPrice: args.price?.toString() ?? '',
      productHandle: args.handle?.toString() ?? '',
      type: 'product',
    );

    final contexts = await Future.wait([
      getProductContext(contextDetails),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(params, contexts.whereType<SelfDescribing>().toList());
  }

  static String _trimCartId(String cartId) {
    final cartIdMatch =
        RegExp(r'gid://shopify/Cart/([^?]+)').firstMatch(cartId);
    return cartIdMatch?.group(1) ?? '';
  }

  static Future<void> trackCartEvent(TrackCartEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

    String cartId = args.cartId ?? '';
    if (cartId.contains('gid://shopify/Cart/')) {
      cartId = _trimCartId(cartId);
    }

    String pageUrl = args.pageUrl ?? '';
    if (pageUrl.isEmpty) {
      pageUrl = 'https://$merchantUrl/cart';
    }

    final params = {'pageUrl': pageUrl, 'cart_id': cartId};

    final contexts = await Future.wait([
      getOtherEventsContext(),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(params, contexts.whereType<SelfDescribing>().toList());
  }

  static Future<void> trackCollectionsEvent(
      TrackCollectionsEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

    String pageUrl = args.pageUrl ?? '';
    if (args.handle != null && merchantUrl.isNotEmpty && pageUrl.isEmpty) {
      pageUrl = 'https://$merchantUrl/collections/${args.handle}';
    }

    String cartId = args.cartId;
    if (cartId.contains('gid://shopify/Cart/')) {
      cartId = _trimCartId(cartId);
    }

    final params = {
      'pageUrl': pageUrl,
      'cart_id': cartId,
      'collection_id': args.collectionId.toString(),
      'name': args.name,
      'image_url': args.imageUrl ?? '',
      'handle': args.handle?.toString() ?? '',
    };

    final contextDetails = TrackCollectionEventContext(
      collection_id: args.collectionId.toString(),
      img_url: args.imageUrl,
      collection_name: args.name,
      collection_handle: args.handle ?? '',
      type: 'collection',
    );

    final contexts = await Future.wait([
      getCollectionsContext(contextDetails),
      getUserContext(),
      getCartContext(cartId),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(params, contexts.whereType<SelfDescribing>().toList());
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

    final contexts = await Future.wait([
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await snowplow?.track(
      SelfDescribing(
        schema:
            'iglu:${SdkConfig.getSchemaVendor(environment)}/structured/jsonschema/1-0-0',
        data: filteredData,
      ),
      contexts: contexts.whereType<SelfDescribing>().toList(),
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
        SelfDescribing(
          schema:
              'iglu:com.snowplowanalytics.snowplow/structured_event/jsonschema/1-0-0',
          data: {
            'category': args['category'],
            'action': args['action'],
            'label': args['label'],
            'property': args['property'],
            'value': args['value'],
          },
        ),
      );
    } catch (error) {
      print('Error in snowplowStructuredEvent: $error');
      throw error;
    }
  }

  static Future<void> trackOtherEvent(TrackOtherEventArgs? args) async {
    String url = args?.pageUrl ?? '';

    String cartId = args?.cartId ?? '';
    if (cartId.contains('gid://shopify/Cart/')) {
      cartId = _trimCartId(cartId);
    }

    final params = {
      'pageUrl': url,
    };

    final contexts = await Future.wait([
      getOtherEventsContext(),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ]);

    await _trackEvent(params, contexts.whereType<SelfDescribing>().toList());
  }
}
