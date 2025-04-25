// import 'package:snowplow_tracker/snowplow_tracker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';

// import '../config/cache_instance.dart';
// import '../config/types.dart';
// import 'sdk_config.dart';

// class SnowplowTrackerHelper {
//   static const _channel = MethodChannel('logger_module');

//   // Helper to fetch environment
//   static Future<String> getEnvironment() async {
//     return (await CacheInstance.getValue(KeyConfig.gkEnvironmentKey)) ??
//         'sandbox';
//   }

//   // Helper to initialize Snowplow client
//   static Future<TrackerController?> initializeSnowplowClient() async {
//     final snowplowTrackingEnabled =
//         (await CacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled)) ==
//             'true';

//     if (!snowplowTrackingEnabled) return null;

//     final mid = (await CacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
//     final environment = await getEnvironment();
//     final shopDomain =
//         (await CacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

//     return SnowplowTracker.getSnowplowClient(
//       InitializeSdkProps(
//         mid: mid,
//         environment: environment,
//         shopDomain: shopDomain,
//         isSnowplowTrackingEnabled: snowplowTrackingEnabled,
//       ),
//     );
//   }

//   // Generic context creation helper
//   static Future<SelfDescribingJson> createContext(
//       String schemaPath, Map<String, dynamic> data) async {
//     final environment = await getEnvironment();
//     return SelfDescribingJson(
//       schema:
//           'iglu:${SdkConfig.config[environment]!['schemaVendor']}/$schemaPath',
//       data: data,
//     );
//   }

//   // Context Generators
//   static Future<SelfDescribingJson?> getCartContext(String? cartId) async {
//     if (cartId == null || cartId.isEmpty) return null;

//     return createContext('com.shopify/cart/jsonschema/1-0-0', {
//       'id': cartId,
//       'token': cartId,
//     });
//   }

//   static Future<SelfDescribingJson?> getUserContext() async {
//     final userJson =
//         (await CacheInstance.getValue(KeyConfig.gkVerifiedUserKey)) ?? '{}';
//     final user = jsonDecode(userJson) as Map<String, dynamic>;

//     final phone = (user['phone'] as String?)?.replaceAll(RegExp(r'^\+91'), '');
//     final numericPhoneNumber = int.tryParse(phone ?? '');

//     if (numericPhoneNumber != null || user['email'] != null) {
//       return createContext('user/jsonschema/1-0-0', {
//         'phone': numericPhoneNumber?.toString() ?? '',
//         'email': user['email'] ?? '',
//       });
//     }
//     return null;
//   }

//   static Future<SelfDescribingJson> getProductContext(
//       TrackProductEventContext contextData) {
//     return createContext('product/jsonschema/1-1-0', contextData.toJson());
//   }

//   static Future<SelfDescribingJson?> getDeviceInfoContext() async {
//     final deviceFCM =
//         await CacheInstance.getValue(KeyConfig.gkNotificationToken);
//     final deviceInfoJson = await CacheInstance.getValue(KeyConfig.gkDeviceInfo);
//     final deviceInfo =
//         jsonDecode(deviceInfoJson ?? '{}') as Map<String, dynamic>;

//     return createContext('user_device/jsonschema/1-0-0', {
//       'device_id': deviceInfo[KeyConfig.gkDeviceUniqueId],
//       'android_ad_id': defaultTargetPlatform == TargetPlatform.android
//           ? deviceInfo[KeyConfig.gkGoogleAdId]
//           : '',
//       'ios_ad_id': defaultTargetPlatform == TargetPlatform.iOS
//           ? deviceInfo[KeyConfig.gkGoogleAdId]
//           : '',
//       'fcm_token': deviceFCM ?? '',
//       'app_domain': deviceInfo[KeyConfig.gkAppDomain],
//       'device_type': defaultTargetPlatform.toString(),
//       'app_version': deviceInfo[KeyConfig.gkAppVersion],
//     });
//   }

//   static Future<SelfDescribingJson> getCollectionsContext(
//       TrackCollectionEventContext params) {
//     return createContext('product/jsonschema/1-1-0', {
//       'collection_id': params.collectionId,
//       'img_url': params.imgUrl ?? '',
//       'collection_name': params.collectionName,
//       'collection_handle': params.collectionHandle,
//       'type': params.type,
//     });
//   }

//   static Future<SelfDescribingJson> getOtherEventsContext() {
//     return createContext('product/jsonschema/1-1-0', {
//       'type': 'other',
//     });
//   }

//   // Generic event tracker
//   static Future<void> trackEvent(Map<String, dynamic> params,
//       List<SelfDescribingJson> eventContext) async {
//     final isTrackingEnabled =
//         await CacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
//     if (isTrackingEnabled == 'false') return;

//     try {
//       await _channel.invokeMethod('log', {
//         'tag': 'EVENT PARAMS',
//         'message': jsonEncode(params),
//       });
//       await _channel.invokeMethod('log', {
//         'tag': 'EVENT CONTEXT',
//         'message': jsonEncode(eventContext),
//       });
//     } catch (e) {
//       debugPrint('LoggerModule not available: $e');
//     }

//     try {
//       final snowplow = await initializeSnowplowClient();
//       if (snowplow == null) return;

//       await snowplow.trackPageView(
//         pageUrl: params['pageUrl'] as String?,
//         pageTitle: params['pageTitle'] as String?,
//         context: eventContext,
//       );
//     } catch (error) {
//       debugPrint('Error tracking event: $error');
//       throw error;
//     }
//   }

//   // Specific Event Trackers
//   static Future<void> trackProductEvent(TrackProductEventArgs args) async {
//     final isTrackingEnabled =
//         await CacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
//     if (isTrackingEnabled == 'false') return;

//     var cartId = args.cartId ?? '';
//     if (cartId.contains('gid://shopify/Cart/')) {
//       cartId = trimCartId(cartId);
//     }

//     final params = <String, dynamic>{
//       'pageUrl': args.pageUrl,
//       'pageTitle': args.name,
//       'productId': args.productId?.toString(),
//       'variantId': args.variantId?.toString() ?? '',
//       if (cartId.isNotEmpty) 'cartId': cartId,
//     };

//     final contextDetails = {
//       'product_id': args.productId?.toString(),
//       'img_url': args.imgUrl ?? '',
//       'variant_id': args.variantId?.toString() ?? '',
//       'product_name': args.name ?? '',
//       'product_price': args.price?.toString() ?? '',
//       'product_handle': args.handle?.toString() ?? '',
//       'type': 'product',
//     };

//     final contextMap = await Future.wait([
//       getProductContext(TrackProductEventContext.fromJson(contextDetails)),
//       getCartContext(cartId),
//       getUserContext(),
//       getDeviceInfoContext(),
//     ]).then((list) => list.whereType<SelfDescribingJson>().toList());

//     return trackEvent(params, contextMap);
//   }

//   static String trimCartId(String cartId) {
//     final cartIdArray =
//         RegExp(r'gid:\/\/shopify\/Cart\/([^?]+)').firstMatch(cartId);
//     return cartIdArray?.group(1) ?? '';
//   }

//   static Future<void> trackCartEvent(TrackCartEventArgs args) async {
//     final merchantUrl =
//         (await CacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

//     var cartId = args.cartId ?? '';
//     if (cartId.contains('gid://shopify/Cart/')) {
//       cartId = trimCartId(cartId);
//     }

//     final pageUrl = 'https://$merchantUrl/cart';
//     final params = {'pageUrl': pageUrl, 'cart_id': cartId};

//     final contextMap = await Future.wait([
//       getOtherEventsContext(),
//       getCartContext(cartId),
//       getUserContext(),
//       getDeviceInfoContext(),
//     ]).then((list) => list.whereType<SelfDescribingJson>().toList());

//     return trackEvent(params, contextMap);
//   }

//   static Future<void> trackCollectionsEvent(
//       TrackCollectionsEventArgs args) async {
//     final merchantUrl =
//         (await CacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

//     var pageUrl = '';
//     if (args.handle != null && merchantUrl.isNotEmpty) {
//       pageUrl = 'https://$merchantUrl/collections/${args.handle}';
//     }

//     var cartId = args.cartId ?? '';
//     if (cartId.contains('gid://shopify/Cart/')) {
//       cartId = trimCartId(cartId);
//     }

//     final params = {
//       'pageUrl': pageUrl,
//       'cart_id': cartId,
//       'collection_id': args.collectionId?.toString(),
//       'name': args.name,
//       'image_url': args.imageUrl ?? '',
//       'handle': args.handle?.toString() ?? '',
//     };

//     final contextDetails = TrackCollectionEventContext(
//       collectionId: args.collectionId?.toString(),
//       imgUrl: args.imageUrl,
//       collectionName: args.name,
//       collectionHandle: args.handle ?? '',
//       type: 'collection',
//     );

//     final contextMap = await Future.wait([
//       getCollectionsContext(contextDetails),
//       getUserContext(),
//       getCartContext(cartId),
//       getDeviceInfoContext(),
//     ]).then((list) => list.whereType<SelfDescribingJson>().toList());

//     return trackEvent(params, contextMap);
//   }

//   // CUSTOM EVENT TRACKER
//   static const _structEventProperties = [
//     'category',
//     'action',
//     'label',
//     'property',
//     'value',
//     'property_1',
//     'value_1',
//     'property_2',
//     'value_2',
//     'property_3',
//     'value_3',
//     'property_4',
//     'value_4',
//     'property_5',
//     'value_5',
//   ];

//   static const _intTypes = ['value', 'value_5'];

//   static Map<String, dynamic> filterEventValuesAsPerStructSchema(
//       Map<String, dynamic> eventObject) {
//     final filteredEvents = <String, dynamic>{};

//     for (final prop in _structEventProperties) {
//       if (eventObject.containsKey(prop)) {
//         final value = eventObject[prop];
//         filteredEvents[prop] = _intTypes.contains(prop)
//             ? (int.tryParse(value.toString()) ?? 0)
//             : value.toString();
//       }
//     }

//     return filteredEvents;
//   }

//   static Future<void> sendCustomEventToSnowPlow(
//       Map<String, dynamic> eventObject) async {
//     final snowplowTrackingEnabled =
//         await CacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
//     if (snowplowTrackingEnabled == 'false') return;

//     final mid = (await CacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
//     final environment = await getEnvironment();
//     final shopDomain =
//         (await CacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

//     final snowplow = await SnowplowTracker.getSnowplowClient(
//       InitializeSdkProps(
//         mid: mid,
//         environment: environment,
//         shopDomain: shopDomain,
//         isSnowplowTrackingEnabled: snowplowTrackingEnabled == 'true',
//       ),
//     );

//     final contextMap = await Future.wait([
//       getUserContext(),
//       getDeviceInfoContext(),
//     ]).then((list) => list.whereType<SelfDescribingJson>().toList());

//     try {
//       await _channel.invokeMethod('log', {
//         'tag': 'Self Describing Event',
//         'message': jsonEncode(filterEventValuesAsPerStructSchema(eventObject)),
//       });
//       await _channel.invokeMethod('log', {
//         'tag': 'Self Describing Event Context',
//         'message': jsonEncode(contextMap),
//       });
//     } catch (e) {
//       debugPrint('LoggerModule not available: $e');
//     }

//     await snowplow?.trackSelfDescribing(
//       SelfDescribingJson(
//         schema:
//             'iglu:${SdkConfig.config[environment]!['schemaVendor']}/structured/jsonschema/1-0-0',
//         data: filterEventValuesAsPerStructSchema(eventObject),
//       ),
//       context: contextMap,
//     );
//   }

//   static Future<void> snowplowStructuredEvent(StructuredProps args) async {
//     try {
//       final snowplowTrackingEnabled =
//           await CacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled);
//       if (snowplowTrackingEnabled == 'false') return;

//       final mid =
//           (await CacheInstance.getValue(KeyConfig.gkMerchantIdKey)) ?? '';
//       final environment = await getEnvironment();
//       final shopDomain =
//           (await CacheInstance.getValue(KeyConfig.gkMerchantUrlKey)) ?? '';

//       final snowplow = await SnowplowTracker.getSnowplowClient(
//         InitializeSdkProps(
//           mid: mid,
//           environment: environment,
//           shopDomain: shopDomain,
//           isSnowplowTrackingEnabled: snowplowTrackingEnabled == 'true',
//         ),
//       );

//       await snowplow?.trackStructuredEvent(
//         category: args.category,
//         action: args.action,
//         label: args.label,
//         property: args.property,
//         value: args.value,
//       );
//     } catch (err) {
//       debugPrint('Error in snowplowStructuredEvent: $err');
//       throw err;
//     }
//   }

//   static Future<void> trackOtherEvent(TrackOtherEventArgs args) async {
//     var url = args.pageUrl;
//     var cartId = args.cartId ?? '';
//     if (cartId.contains('gid://shopify/Cart/')) {
//       cartId = trimCartId(cartId);
//     }

//     final params = {'pageUrl': url};

//     final contextMap = await Future.wait([
//       getOtherEventsContext(),
//       getCartContext(cartId),
//       getUserContext(),
//       getDeviceInfoContext(),
//     ]).then((list) => list.whereType<SelfDescribingJson>().toList());

//     return trackEvent(params, contextMap);
//   }
// }
