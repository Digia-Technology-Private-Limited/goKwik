import 'dart:convert';
import 'dart:io';

import 'package:gokwik/api/snowplow_client.dart';
import 'package:gokwik/api/http_snowplow_tracker.dart';
import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/config_constants.dart';
import 'package:gokwik/version.dart';
import 'package:snowplow_tracker/snowplow_tracker.dart';
import 'package:uuid/uuid.dart';

import '../config/cache_instance.dart';
import '../config/types.dart';
import 'sdk_config.dart';

class SnowplowTrackerService {
  String? eventId = Uuid().v4();

  // Helper to fetch environment
  static Future<String> _getEnvironment() async {
    return (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkEnvironmentKey)!)) ??
        'production';
  }

  // Helper to initialize Snowplow client
  /*static Future<SnowplowTracker?> _initializeSnowplowClient() async {
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
  }*/

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

    final schemas = cdnConfigInstance.getSnowplowSchema();
    final cartSchema = (schemas is Map<String, String>)
        ? (schemas['cart'] ?? 'iglu:com.shopify/cart/jsonschema/1-0-0')
        : 'iglu:com.shopify/cart/jsonschema/1-0-0';

    return SelfDescribing(
      schema: cartSchema,
      data: {
        'id': cartId,
        'token': cartId,
      },
    );
  }

  static Future<SelfDescribing?> getUserContext() async {
    final userJson = await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkVerifiedUserKey)!);
    var user = userJson != null ? jsonDecode(userJson) : null;
    var phone =
        user != null ? user!['phone']?.replaceAll(RegExp(r'^\+91'), '') : null;
    final numericPhoneNumber = int.tryParse(phone ?? '');

    if (numericPhoneNumber != null ||
        (user != null && user?['email'] != null)) {
      final schemas = cdnConfigInstance.getSnowplowSchema();
      final userSchema = (schemas is Map<String, String>)
          ? (schemas['user'] ?? 'user/jsonschema/1-0-0')
          : 'user/jsonschema/1-0-0';
      
      return _createContext(
        userSchema,
        {
          'phone': numericPhoneNumber?.toString() ?? '',
          'email': user?['email'] ?? '',
        },
      );
    }
    return null;
  }

  static Future<SelfDescribing> getProductContext(
      TrackProductEventContext contextData) async {
    final schemas = cdnConfigInstance.getSnowplowSchema();
    final productSchema = (schemas is Map<String, String>)
        ? (schemas['product'] ?? 'product/jsonschema/1-1-0')
        : 'product/jsonschema/1-1-0';
    
    return _createContext(productSchema, contextData.toJson());
  }

  static Future<SelfDescribing?> getDeviceInfoContext() async {
    final deviceFCM =
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkNotificationToken)!);
    final deviceInfoJson = await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkDeviceInfo)!);
    final deviceInfo = deviceInfoJson != null ? jsonDecode(deviceInfoJson) : {};

    // If no device id then dont pass the deviceInfoSchema
    final deviceId = deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkDeviceUniqueId)];
    if (deviceId == null || deviceId.toString().isEmpty) {
      return null;
    }

    // ADD META TO THE USER DEVICE SCHEMA
    final metaItems = <Map<String, dynamic>>[];
    
    final isVersionAddedInMeta = metaItems.any((item) => item['property'] == 'sdk_version');

    if (!isVersionAddedInMeta) {
      metaItems.add({
        'property': 'sdk_version',
        'value': KPSdkVersion.version,
      });
      metaItems.add({
        'property': 'platform',
        'value': 'flutter',
      });
    }

    final schemas = cdnConfigInstance.getSnowplowSchema();
    final userDeviceSchema = (schemas is Map<String, String>)
        ? (schemas['user_device'] ?? 'user_device/jsonschema/1-0-0')
        : 'user_device/jsonschema/1-0-0';

    return _createContext(
      userDeviceSchema,
      {
        'device_id': deviceId,
        'android_ad_id':
            Platform.isAndroid ? deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkGoogleAdId)] : '',
        'ios_ad_id': Platform.isIOS ? deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkGoogleAdId)] : '',
        'fcm_token': deviceFCM ?? '',
        'app_domain': deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkAppDomain)],
        'device_type': Platform.operatingSystem.toLowerCase(),
        'app_version': deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkAppVersion)],
        'meta': metaItems,
      },
    );
  }

  static Future<SelfDescribing> getCollectionsContext(
      TrackCollectionEventContext params) async {
    final schemas = cdnConfigInstance.getSnowplowSchema();
    final productSchema = (schemas is Map<String, String>)
        ? (schemas['product'] ?? 'product/jsonschema/1-1-0')
        : 'product/jsonschema/1-1-0';
    
    return _createContext(productSchema, {
      'collection_id': params.collection_id,
      'img_url': params.img_url ?? '',
      'collection_name': params.collection_name,
      'collection_handle': params.collection_handle,
      'type': params.type,
    });
  }

  static Future<SelfDescribing> getOtherEventsContext() async {
    final schemas = cdnConfigInstance.getSnowplowSchema();
    final productSchema = (schemas is Map<String, String>)
        ? (schemas['product'] ?? 'product/jsonschema/1-1-0')
        : 'product/jsonschema/1-1-0';
    
    return _createContext(productSchema, {'type': 'other'});
  }

  // Generic event tracker using HTTP method
  static Future<void> _trackEvent(
    Map<String, dynamic> params,
    List<SelfDescribing> eventContext,
  ) async {
    final isTrackingEnabled =
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.isSnowplowTrackingEnabled)!);
    if (isTrackingEnabled == 'false') return;

    try {
      // Log event parameters and context
      // Track event via HTTP method
      await _trackEventViaHttp(params, eventContext);
    } catch (error) {
    }
  }

  // HTTP tracker fallback method
  static Future<void> _trackEventViaHttp(
    Map<String, dynamic> params,
    List<SelfDescribing> eventContext,
  ) async {
    // Extract custom properties from context
    Map<String, dynamic>? customProperties;
    String? productId;
    String? collectionId;
    String? cartId;

    for (final context in eventContext) {
      if (context.schema.contains('product/jsonschema')) {
        final data = context.data;
        if (data['type'] == 'product') {
          productId = data['product_id'];
          customProperties = {
            'product_name': data['product_name'],
            'product_price': data['product_price'],
            'product_handle': data['product_handle'],
            'variant_id': data['variant_id'],
            'img_url': data['img_url'],
            'type': data['type']
          };
        } else if (data['type'] == 'collection') {
          collectionId = data['collection_id'];
          customProperties = {
            'collection_name': data['collection_name'],
            'collection_handle': data['collection_handle'],
            'img_url': data['img_url'],
            'type': data['type']
          };
        }
      } else if (context.schema.contains('cart/jsonschema')) {
        cartId = context.data['id'];
      }
    }

    await HttpSnowplowTracker.trackPageView(
      pageUrl: params['page_url']?.toString() ?? '',
      pageTitle: params['page_title']?.toString() ?? '',
      cartId: cartId,
      productId: productId,
      collectionId: collectionId,
      customProperties: customProperties,
    );
  }

  // Specific Event Trackers
  static Future<void> trackProductEvent(TrackProductEventArgs args) async {
    final isTrackingEnabled =
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.isSnowplowTrackingEnabled)!);
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

    final contexts = (await Future.wait([
      getProductContext(contextDetails),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ])).where((context) => context != null).cast<SelfDescribing>().toList();

    await _trackEvent(params, contexts);
  }

  static String _trimCartId(String cartId) {
    final cartIdMatch =
        RegExp(r'gid://shopify/Cart/([^?]+)').firstMatch(cartId);
    return cartIdMatch?.group(1) ?? '';
  }

  static Future<void> trackCartEvent(TrackCartEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantUrlKey)!)) ?? '';

    String cartId = args.cartId;
    if (cartId.contains('gid://shopify/Cart/')) {
      cartId = _trimCartId(cartId);
    }

    String pageUrl = args.pageUrl;
    if (pageUrl.isEmpty) {
      pageUrl = 'https://$merchantUrl/cart';
    }

    final params = {'pageUrl': pageUrl, 'cart_id': cartId};

    final contexts = (await Future.wait([
      getOtherEventsContext(),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ])).where((context) => context != null).cast<SelfDescribing>().toList();

    await _trackEvent(params, contexts);
  }

  static Future<void> trackCollectionsEvent(
      TrackCollectionsEventArgs args) async {
    final merchantUrl =
        (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantUrlKey)!)) ?? '';

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

    final contexts = (await Future.wait([
      getCollectionsContext(contextDetails),
      getUserContext(),
      getCartContext(cartId),
      getDeviceInfoContext(),
    ])).where((context) => context != null).cast<SelfDescribing>().toList();

    await _trackEvent(params, contexts);
  }

  // Custom Event Tracker
  static Future<void> sendCustomEventToSnowPlow(
      Map<String, dynamic> eventObject) async {
    final snowplowTrackingEnabled =
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.isSnowplowTrackingEnabled)!);
    // if (snowplowTrackingEnabled == 'false') return;

    final mid = (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantIdKey)!)) ?? '';
    final environment = await _getEnvironment();
    final shopDomain =
        (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantUrlKey)!)) ?? '';

    final snowplow = await SnowplowClient.getSnowplowClient(
      InitializeSdkProps(
          mid: mid,
          environment:
              Environment.values.firstWhere((e) => e.name == environment),
          shopDomain: shopDomain,
          isSnowplowTrackingEnabled: snowplowTrackingEnabled == 'true'),
    );

    final filteredData = _filterEventValuesAsPerStructSchema(eventObject);

    final contexts = (await Future.wait([
      getUserContext(),
      getDeviceInfoContext(),
    ])).where((context) => context != null).cast<SelfDescribing>().toList();

    final schemas = cdnConfigInstance.getSnowplowSchema();
    final structuredSchema = (schemas is Map<String, String>)
        ? (schemas['structured'] ?? 'structured/jsonschema/1-0-0')
        : 'structured/jsonschema/1-0-0';

    await snowplow?.track(
      SelfDescribing(
        schema:
            'iglu:${SdkConfig.getSchemaVendor(environment)}/$structuredSchema',
        data: filteredData,
      ),
      contexts: contexts,
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
          await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.isSnowplowTrackingEnabled)!);
      if (snowplowTrackingEnabled == 'false') return;

      final mid =
          (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantIdKey)!)) ?? '';
      final environment = await _getEnvironment();
      final shopDomain =
          (await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantUrlKey)!)) ?? '';

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
      rethrow;
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

    final contexts = (await Future.wait([
      getOtherEventsContext(),
      getCartContext(cartId),
      getUserContext(),
      getDeviceInfoContext(),
    ])).where((context) => context != null).cast<SelfDescribing>().toList();

    await _trackEvent(params, contexts);
  }
}
