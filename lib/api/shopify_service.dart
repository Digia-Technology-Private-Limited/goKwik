import 'dart:convert';

import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/api/constant/api_config.dart';
import 'package:gokwik/api/httpClient.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/key_congif.dart';

import '../config/cache_instance.dart';

class ShopifyService {

  ShopifyService._internal();
  static Future<Map<String, dynamic>> getShopifyMultipassToken({
    required String phone,
    required String email,
    String? id,
    String? state,
  }) async {
    try {
      final gokwik = DioClient().getClient();

      final results = await Future.wait([
        cacheInstance.getValue(cdnConfigInstance.getKeyOrDefault(KeyConfig.gkAccessTokenKey)),
        cacheInstance.getValue(cdnConfigInstance.getKeyOrDefault(KeyConfig.checkoutAccessTokenKey)),
        cacheInstance.getValue(cdnConfigInstance.getKeyOrDefault(KeyConfig.gkNotificationEnabled)),
      ]);

      final accessToken = results[0];
      final checkoutAccessToken = results[1];
      final notifications = results[2];

      if (accessToken != null) {
        gokwik.options.headers[cdnConfigInstance.getHeaderOrDefault(APIHeader.gkAccessToken)] = accessToken;
      }
      if (checkoutAccessToken != null) {
        gokwik.options.headers[cdnConfigInstance.getHeaderOrDefault(APIHeader.checkoutAccessToken)] =
            checkoutAccessToken;
      }

      final response = await gokwik.post(
        cdnConfigInstance.getEndpointOrDefault(APIConfig.shopifyMultipass),
        data: {
          'id': id ?? '',
          'email': email,
          'redirectUrl': '/',
          'isMarketingEventSubscribed': notifications == 'true',
          'state': state ?? '',
        },
      );

      final userData = {
        ...response.data?['data'],
        'phone': phone,
      };

      await cacheInstance.setValue(
        cdnConfigInstance.getKeyOrDefault(KeyConfig.gkVerifiedUserKey),
        jsonEncode(userData),
      );

      return response.data;
    } catch (error) {
      throw ApiService.handleApiError(error);
    }
  }

  static Future<Result> shopifySendEmailVerificationCode(
    String email,
  ) async {
    try {
      final gokwik = DioClient().getClient();

      final phoneNumber = await cacheInstance.getValue(cdnConfigInstance.getKeyOrDefault(KeyConfig.gkUserPhone));

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'email_filled',
        'action': 'click',
        'property': 'email',
        'value': int.tryParse(phoneNumber ?? '0') ?? 0,
      });

      final response = (await gokwik.post(
        cdnConfigInstance.getEndpointOrDefault(APIConfig.sendEmailVerificationCode),
        data: {'email': email},
      ))
          .toBaseResponse();
      if (response.isSuccess == false) {
        return Failure(response.errorMessage ?? '');
      }

      
      return Success(response.data);
    } catch (error) {
      throw ApiService.handleApiError(error);
    }
  }

  static Future<Map<String, dynamic>> shopifyVerifyEmail(
    String email,
    String otp,
  ) async {
    try {
      final gokwik = DioClient().getClient();

      final notifications = await cacheInstance.getValue(
        cdnConfigInstance.getKeyOrDefault(KeyConfig.gkNotificationEnabled),
      );

      final response = await gokwik.post(
        cdnConfigInstance.getEndpointOrDefault(APIConfig.verifyEmailCode),
        data: {
          'email': email,
          'otp': otp,
          'redirectUrl': '/',
          'isMarketingEventSubscribed': notifications == 'true',
        },
      );

      final userData =
          await cacheInstance.getValue(cdnConfigInstance.getKeyOrDefault(KeyConfig.gkVerifiedUserKey));
      final userDataObj = userData != null ? jsonDecode(userData) : {};

      final user = {
        ...response.data?['data'],
        'phone': userDataObj['phone'],
      };

      await cacheInstance.setValue(
        cdnConfigInstance.getKeyOrDefault(KeyConfig.gkVerifiedUserKey),
        jsonEncode(user),
      );

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'otp_verified',
        'action': 'logged_in',
        'property': 'phone_number',
        'value': int.tryParse(user['phone'] ?? '0') ?? 0,
      });

      return response.data;
    } catch (error) {
      throw await ApiService.handleApiError(error);
    }
  }

  static Future<Map<String, dynamic>> getCheckoutMultiPassToken({
    required String phone,
    required String email,
    required String gkAccessToken,
    String? id,
    bool? notifications,
  }) async {
    try {
      final gokwik = DioClient().getClient();

      gokwik.options.headers[cdnConfigInstance.getHeaderOrDefault(APIHeader.gkAccessToken)] = gkAccessToken;

      final response = await gokwik.post(
        cdnConfigInstance.getEndpointOrDefault(APIConfig.shopifyMultipass),
        data: {
          'id': id ?? '',
          'email': email,
          'redirectUrl': '/',
          'isMarketingEventSubscribed': notifications,
          'skipEmailOtp': true,
        },
      );

      final userData = {
        ...response.data?['data'],
        'phone': phone,
      };

      // await trackAnalyticsEvent(AnalyticsEvents.appLoginShopifySuccess, {
      //   'email': userData['email']?.toString() ?? "",
      //   'phone': phone,
      //   'customer_id': userData['shopifyCustomerId']?.toString() ?? "",
      // });

      await cacheInstance.setValue(
        cdnConfigInstance.getKeyOrDefault(KeyConfig.gkVerifiedUserKey),
        jsonEncode(userData),
      );

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'sso_login',
        'label': 'checkout_sso_logged_in',
        'action': 'logged_in',
        'property': 'phone_number',
        'value': int.tryParse(phone) ?? 0,
      });

      return response.data;
    } catch (error) {
      throw await ApiService.handleApiError(error);
    }
  }

  static Future<bool> validateDisposableEmail(String email) async {
    try {
      final gokwik = DioClient().getClient();

      final response = await gokwik.get('${cdnConfigInstance.getEndpointOrDefault(APIConfig.disposableEmailCheck)}$email');

      return response.data?['data'] != null &&
             response.data?['success'] == true;
    } catch (error) {
      throw ApiService.handleApiError(error);
    }
  }

  static Future<Map<String, dynamic>> customerShopifySession({
    required String email,
    required String shopifyCustomerId,
    required bool isMarketingEventSubscribed,
  }) async {
    try {
      final gokwik = DioClient().getClient();
      
      // Set the integration type header
      gokwik.options.headers[cdnConfigInstance.getHeaderOrDefault(APIHeader.kpIntegrationType)] = 'APP_MAKER';

      final Map<String, dynamic> body = {
        'email': email,
        'redirectUrl': '/',
        'isMarketingEventSubscribed': isMarketingEventSubscribed,
      };

      // Add id field if shopifyCustomerId is provided
      if (shopifyCustomerId.isNotEmpty) {
        body['id'] = shopifyCustomerId;
      }

      final response = await gokwik.post(
        cdnConfigInstance.getEndpointOrDefault(APIConfig.customerShopifySession),
        data: body,
      );

      return response.data;
    } catch (error) {
      throw ApiService.handleApiError(error);
    }
  }
}
