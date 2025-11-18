import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/analytics/config.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/api/constant/api_config.dart';
import 'package:gokwik/api/httpClient.dart';
import 'package:gokwik/api/snowplow_client.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/config/storege.dart';
import 'package:gokwik/module/advertise.dart';
import 'package:gokwik/version.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/types.dart';
import 'sdk_config.dart';
import 'shopify_service.dart';

// Custom exception for Kwikpass health errors
class KwikpassHealthException implements Exception {
  final int status;
  final String error;
  final String message;
  final String timestamp;

  KwikpassHealthException({
    this.status = 503,
    this.error = "ServiceUnavailable",
    this.message = "Kwikpass is unhealthy to make the API calls",
    String? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toIso8601String();

  @override
  String toString() {
    return 'KwikpassHealthException: $message (Status: $status, Error: $error, Timestamp: $timestamp)';
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'error': error,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

abstract class ApiService {
// add kp health api
  static Future<Result<HealthCheckResponseData?>> checkKwikpassHealth() async {
    try {
      final gokwik = DioClient().getClient();

      // Get cached values in parallel
      final results = await Future.wait([
        cacheInstance.getValue(KeyConfig.gkRequestIdKey),
        cacheInstance.getValue(KeyConfig.gkAccessTokenKey),
        cacheInstance.getValue(KeyConfig.gkMerchantIdKey),
      ]);

      final requestId = results[0];
      final accessToken = results[1] ?? "";
      final mid = results[2];

      // Set all headers at once
      final headers = <String, String>{
        KeyConfig.kpMerchantIdKey: mid ?? '',
      };

      if(requestId != null && requestId.isNotEmpty){
        headers[KeyConfig.kpRequestIdKey] = requestId;
      }
      
      if (accessToken.isNotEmpty) {
        headers[KeyConfig.gkAccessTokenKey] = accessToken;
      }

      gokwik.options.headers.addAll(headers);

      final response = (await gokwik.get(APIConfig.kpHealthCheck)).toBaseResponse(
        fromJson: (json) => HealthCheckResponseData.fromJson(json),
      );

      if (response.isSuccess ?? false) {
        final healthData = response.data;
        // Check if kwikpass is healthy
        if (healthData?.isKwikpassHealthy == false) {
          throw KwikpassHealthException();
        }
        return Success(response.data);
      }

      // Throw custom exception when API call fails
      throw KwikpassHealthException();
    } catch (error) {
      debugPrint("ERRORRR $error");
      if (error is KwikpassHealthException) {
        rethrow; // Re-throw the custom exception
      }
      return Failure(handleApiError(error).message);
    }
  }

  static Failure handleApiError(dynamic error) {
    String message = 'An unknown error occurred';
    // String? requestId;

    if (error is DioException) {
      final responseData = error.response?.data;
      final statusCode = error.response?.statusCode;

      if (responseData != null) {
        // Handle nested error.message pattern similar to JavaScript
        if (responseData is Map<String, dynamic>) {
          final errorData = responseData['error'];
          if (errorData != null && errorData is Map<String, dynamic> && errorData['message'] != null) {
            message = errorData['message'].toString();
          } else if (errorData != null) {
            message = errorData.toString();
          } else if (responseData['error_msg'] != null) {
            message = responseData['error_msg'].toString();
          } else if (responseData['message'] != null) {
            message = responseData['message'].toString();
          } else {
            message = 'Unexpected error with status: $statusCode';
          }
        } else {
          // If responseData is not a Map, convert it to string
          message = responseData.toString();
        }
        return Failure(message);
      } else {
        // Handle cases where there's no response data
        message = error.message ?? 'Network error occurred';
        if (statusCode != null) {
          message += ' (Status: $statusCode)';
        }
        return Failure(message);
      }
    }
    
    // Handle non-DioException errors
    if (error is Exception) {
      message = error.toString();
    } else {
      message = error?.toString() ?? 'An unknown error occurred';
    }
    
    return Failure(message);
  }

  static String getHostName(String url) {
    final regex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?([^\/]+).*$');
    return regex.firstMatch(url)?.group(1) ?? '';
  }

  static Future<Result<dynamic>> customerIntelligence() async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    final merchantJson =
        await cacheInstance.getValue(KeyConfig.gkMerchantConfig);
    if (merchantJson == null) {
      return const Success(null); // No merchant config, not an error.
    }

    final merchant = MerchantConfig.fromJson(jsonDecode(merchantJson));
    if (merchant.customerIntelligenceEnabled != true) {
      return const Success(null);
    }

    final customerIntelligenceMetrics =
        merchant.customerIntelligenceMetrics ?? {};
    final gokwik = DioClient().getClient();

    List<String> reduceKeys(Map<String, dynamic> innerObj) {
      return innerObj.entries.fold([], (List<String> acc, entry) {
        if (entry.value == true) {
          acc.add(entry.key);
        } else if (entry.value is Map) {
          acc.addAll(reduceKeys(entry.value as Map<String, dynamic>));
        }
        return acc;
      });
    }

    final trueKeys = reduceKeys(customerIntelligenceMetrics).toSet().toList();

    try {
      final response = (await gokwik.get(
        APIConfig.customerIntelligence,
        queryParameters: {'cstmr-mtrcs': trueKeys.join(',')},
      ))
          .toBaseResponse();
      if (response.isSuccess ?? false) {
        return Success(response.data);
      }

      return Failure(
          response.errorMessage ?? 'Failed to fetch customer intelligence');
    } catch (err) {
      final apiError = handleApiError(err);

      return apiError;
    }
  }

  static Future<Result<dynamic>> activateUserAccount(
      String id, String url, String password, String token) async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    final data = {
      'form_type': 'activate_customer_password',
      'utf8': '✓',
      'customer[password]': password,
      'customer[password_confirmation]': password,
      'token': token,
      'id': id,
    };

    try {
      final phone = await cacheInstance.getValue(KeyConfig.gkUserPhone);
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'account_activated',
        'action': 'automated',
        'property': 'phone_number',
        'value': int.tryParse(phone ?? '0') ?? 0,
      });

      final response = await Dio().post(
        'https://$url/account/activate',
        data: data,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          followRedirects: false,
        ),
      );
      return Success(response);
    } catch (err) {
      final apiError = handleApiError(err);
      return apiError;
    }
  }

  static Future<Result<dynamic>> getBrowserToken() async {
    try {
      final goKwik = DioClient().getClient();
      final response = (await goKwik.get(APIConfig.getBrowserToken)).toBaseResponse();
      final data = response.data ?? {};
      final requestId = data['requestId'];
      final token = data['token'];

      final headers = {
        KeyConfig.gkRequestIdKey: requestId,
        KeyConfig.kpRequestIdKey: requestId,
        'Authorization': token,
      };

      goKwik.options.headers.addAll(headers);

      await Future.wait([
        cacheInstance.setValue(KeyConfig.gkRequestIdKey, requestId),
        cacheInstance.setValue(KeyConfig.kpRequestIdKey, requestId),
        cacheInstance.setValue(KeyConfig.gkAuthTokenKey, token),
      ]);

      return Success(response.data);
    } catch (err) {
      throw handleApiError(err);
    }
  }

  static Future<Result<MerchantConfig?>> initializeMerchant(
      String mid, String environment) async {
    try {
      final gokwik = DioClient().getClient();

      final response = (await gokwik.get('${APIConfig.merchantConfiguration}$mid')).toBaseResponse(
        fromJson: (json) => MerchantConfig.fromJson(json),
      );

      final merchantRes = response.data;
      await cacheInstance.setValue(
        KeyConfig.gkMerchantConfig,
        jsonEncode(merchantRes),
      );

      final requestId = merchantRes?.kpRequestId;
      if (requestId != null) {
        await cacheInstance.setValue(
          KeyConfig.gkRequestIdKey,
          requestId.toString(),
        );
      }

      return Success(merchantRes);
    } catch (error) {
      throw handleApiError(error);
    }
  }

  static Future<Map<String, dynamic>> initializeSdk(
      InitializeSdkProps args) async {
    try {
      final mid = args.mid;
      final environment = args.environment;
      final kcMerchantId = args.kcMerchantId ?? '';
      final kcMerchantToken = args.kcMerchantToken ?? '';
      final isSnowplowTrackingEnabled = args.isSnowplowTrackingEnabled ?? true;
      final mode = args.mode ?? (kDebugMode ? 'debug' : 'release');
      
      // callback function for analytics
      final Function analyticsCallback = args.onAnalytics ?? () {};

      // Create settings with defaults, then merge with provided settings
      final settingsWithDefaults = Settings(
        enableKwikPass: args.settings?.enableKwikPass ?? true,
        enableCheckout: args.settings?.enableCheckout ?? true,
      );
      
      final enableKwikPass = settingsWithDefaults.enableKwikPass;
      final enableCheckout = settingsWithDefaults.enableCheckout;
      // await Logger().log(
      //   'SDK Initialized',
      //   data: jsonEncode({
      //     'mid': mid,
      //     'environment': environment.name,
      //   }),
      // );

      await Future.wait([
        cacheInstance.setValue(
          KeyConfig.gkMode,
          mode.toString(),
        ),
        cacheInstance.setValue(KeyConfig.gkEnvironmentKey, environment.name),
        cacheInstance.setValue(KeyConfig.gkMerchantIdKey, mid),
        cacheInstance.setValue(KeyConfig.kcMerchantId, kcMerchantId),
        cacheInstance.setValue(KeyConfig.kcMerchantToken, kcMerchantToken),
        cacheInstance.setValue(
          KeyConfig.kcNotificationEventUrl,
          SdkConfig.getNotifEventsUrl(environment.name),
        ),
        cacheInstance.setValue(KeyConfig.enableKwikPass, enableKwikPass.toString()),
        cacheInstance.setValue(KeyConfig.enableCheckout, enableCheckout.toString()),
      ]);

      if (enableKwikPass == false) {
        return {'message': 'Initialization Successful without kwikpass'};
      }

      cacheInstance.setValue(
        KeyConfig.isSnowplowTrackingEnabled,
        isSnowplowTrackingEnabled.toString(),
      );
      await DioClient().initialize(args.environment.name);
      final gokwik = DioClient().getClient();
      gokwik.options.headers[KeyConfig.gkMerchantIdKey] = mid;
      gokwik.options.headers[KeyConfig.kpSdkPlatform] = 'flutter';
      gokwik.options.headers[KeyConfig.kpSdkVersion] = KPSdkVersion.version;

      // await Logger().log(
      //   'SDK Initialized',
      //   data: jsonEncode({
      //     'mid': mid,
      //     'environment': environment.name,
      //   }),
      // );

      final results = await Future.wait([
        cacheInstance.getValue(KeyConfig.gkRequestIdKey),
        cacheInstance.getValue(KeyConfig.gkAccessTokenKey),
        cacheInstance.getValue(KeyConfig.checkoutAccessTokenKey),
      ]);

      final accessToken = results[1];
      final checkoutAccessToken = results[2];

      if (accessToken != null) {
        gokwik.options.headers[KeyConfig.gkAccessTokenKey] = accessToken;
      }
      if (checkoutAccessToken != null) {
        gokwik.options.headers[KeyConfig.checkoutAccessTokenKey] =
            checkoutAccessToken;
      }

      final result = await checkKwikpassHealth();
      // await getBrowserToken();
      if(result.isSuccess) {
        final healthData = result.getDataOrThrow();
        if(healthData?.isKwikpassHealthy == false){
          throw Exception('Kwikpass is unhealthy');
        }
      }
      final merchantConfig = await initializeMerchant(mid, environment.name);

      if (merchantConfig.isSuccess) {
        final merchantConfigData = merchantConfig.getDataOrThrow();
        if (merchantConfigData?.platform != null) {
          final platform =
              merchantConfigData!.platform.toString().toLowerCase();
          await cacheInstance.setValue(KeyConfig.gkMerchantTypeKey, platform);
        }

        final hostName = getHostName(merchantConfigData!.host);
        await cacheInstance.setValue(KeyConfig.gkMerchantUrlKey, hostName);
      }

      await SnowplowClient.initializeSnowplowClient(args);

      final deviceInfo = DeviceInfoPlugin();
      String osVersion = 'Unknown';
      String deviceModel = 'Unknown';
      String deviceId = 'Unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osVersion = 'Android ${androidInfo.version.release}';
        deviceModel = androidInfo.model;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.model;
        deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      }

      final packageInfo = await PackageInfo.fromPlatform();
      // ignore: deprecated_member_use
      final window = WidgetsBinding.instance.window;
      final screenSize = window.physicalSize;
      final screenResolution =
          '${screenSize.width.toInt()}x${screenSize.height.toInt()}';

      final deviceInfoDetails = {
        KeyConfig.gkDeviceModel: deviceModel,
        KeyConfig.gkAppDomain: packageInfo.packageName,
        KeyConfig.gkOperatingSystem: osVersion,
        KeyConfig.gkDeviveId: deviceId,
        KeyConfig.gkDeviceUniqueId: deviceId,
        KeyConfig.gkGoogleAnalyticsId: deviceId,
        KeyConfig.gkGoogleAdId: '',
        KeyConfig.gkAppVersion: packageInfo.version,
        KeyConfig.gkAppVersionCode: packageInfo.buildNumber,
        KeyConfig.gkScreenResolution: screenResolution,
        KeyConfig.gkCarrierInfo: 'Unknown',
        KeyConfig.gkBatteryStatus: 'Unknown',
        KeyConfig.gkLanguage: Intl.getCurrentLocale(),
        KeyConfig.gkTimeZone: DateTime.now().timeZoneName,
      };

      try {
        final advertisingInfo = await AdvertisingInfo.getAdvertisingInfo();

        if (advertisingInfo.id != null) {
          deviceInfoDetails[KeyConfig.gkGoogleAdId] = advertisingInfo.id!;
        }
      } catch (e) {
        deviceInfoDetails[KeyConfig.gkGoogleAdId] = "";
      }

      await cacheInstance.setValue(
        KeyConfig.gkDeviceInfo,
        jsonEncode(deviceInfoDetails),
      );

      final requestId = results[0];
      if (requestId != null) {
        gokwik.options.headers[KeyConfig.kpRequestIdKey] = requestId;
        gokwik.options.headers[KeyConfig.gkRequestIdKey] = requestId;
      }


      // Check for MoEngage tracking configuration
      // final isMoEngageTracking = merchantConfig.isSuccess &&
      //     merchantConfig.getDataOrThrow()?.thirdPartyServiceProviders
      //         .where((item) => item.name == 'mo_engage' && item.type == 'analytics')
      //         .length == 1;

      // // Check for WebEngage tracking configuration
      // final isWebEngageTracking = merchantConfig.isSuccess &&
      //     merchantConfig.getDataOrThrow()?.thirdPartyServiceProviders
      //         .where((item) => item.name == 'web_engage' && item.type == 'analytics')
      //         .length == 1;

      // Get verified user data and track identified user event
      final verifiedUserJson =
          await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
      if (verifiedUserJson != null) {
        final verifiedUser = jsonDecode(verifiedUserJson);

        if (verifiedUser['email'] != null && verifiedUser['phone'] != null) {
          analyticsCallback(AnalyticsEvents.appIdentifiedUser, {
            'phone': verifiedUser['phone']?.toString() ?? "",
            'email': verifiedUser['email']?.toString() ?? "",
            'customer_id': verifiedUser['shopifyCustomerId']?.toString() ?? "",
          });
        }
      }

      return {'message': 'Initialization Successful'};
    } catch (error) {
      if (error is Failure) {
        throw handleApiError(error);
      }
      throw handleApiError(error);
    }
  }

  static Future<Result<OtpSentResponseData?>> sendVerificationCode(
    String phoneNumber,
    bool notifications,
  ) async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    try {
      await getBrowserToken();
      final gokwik = DioClient().getClient();

      // await trackAnalyticsEvent(AnalyticsEvents.appLoginPhone, {
      //   'phone': phoneNumber.toString(),
      // });

      await Future.wait([
        cacheInstance.setValue(
          KeyConfig.gkNotificationEnabled,
          notifications.toString(),
        ),
        cacheInstance.setValue(
          KeyConfig.gkUserPhone,
          phoneNumber,
        ),
      ]);

      await Future.wait([
        SnowplowTrackerService.sendCustomEventToSnowPlow({
          'category': 'login_modal',
          'label': 'phone_number_filled',
          'action': 'click',
          'property': 'phone_number',
          'value': int.tryParse(phoneNumber) ?? 0,
        }),
        SnowplowTrackerService.sendCustomEventToSnowPlow({
          'category': 'login_modal',
          'label': 'phone_number_entered',
          'action': 'click',
          'property': 'phone_number',
          'value': int.tryParse(phoneNumber) ?? 0,
        }),
      ]);
      final response = (await gokwik.post(
        APIConfig.sendVerificationCode,
        data: {'phone': phoneNumber},
      ))
          .toBaseResponse(
        fromJson: (json) => OtpSentResponseData.fromJson(json),
      );

      // if(response.statusCode == 200){
      //   var res = OtpSentResponseData.fromJson(response.data);
      // }else{
      //   //manage error
      // }

      if (response.isSuccess == false) {
        return Failure(response.errorMessage ?? 'Failed to send OTP');
      }
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'otp_sent_successfully',
        'action': 'automated',
        'property': 'phone_number',
        'value': int.tryParse(phoneNumber) ?? 0,
      });

      return Success(response.data);
    } catch (error) {
      // var test =   handleApiError(error);
      // return test;
      throw handleApiError(error);
    }
  }

  static Future<Result<LoginResponseData?>> loginKpUser() async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    try {
      final gokwik = DioClient().getClient();
      // final response =
      //     (await gokwik.get('customer/custom/login')).toBaseResponse(
      //   fromJson: (json) => LoginResponseData.fromJson(json),
      // );

      final response =
          (await gokwik.get(APIConfig.customCustomerLogin)).toBaseResponse(
        fromJson: (json) => LoginResponseData.fromJson(json),
      );
      if (response.statusCode == 200) {}
      // if (response.isSuccess == false) {
      //   return Failure(response.errorMessage ?? 'Failed to login');
      // }

      return Success(response.data);
      // return Success(loginKpData);
    } catch (err) {
      throw handleApiError(err);
    }
  }

//ToDo: @Ram
  static Future<Result<Map<String, dynamic>?>> createUserApi({
    required String email,
    required String name,
    String? dob,
    String? gender,
  }) async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    try {
      final gokwik = DioClient().getClient();

      final response = (await gokwik.post(
        APIConfig.customCreateUser,
        data: {
          'email': email,
          'name': name,
          if (dob != null) 'dob': dob,
          if (gender != null) 'gender': gender,
        },
      ))
          .toBaseResponse(
        fromJson: (json) => json,
      );
      if (response.isSuccess == false) {
        return Failure(response.errorMessage ?? 'Failed to create user');
      }

      final data = response.data;
      final merchantResponse = data?['merchantResponse']?['accountCreate'];
      final errors = merchantResponse?['accountErrors'];

      if (merchantResponse?['user'] == null &&
          errors != null &&
          errors.isNotEmpty) {
        throw errors[0];
      }

      final userRes = {
        'email': email,
        'username': name,
        'dob': dob,
        'gender': gender,
        'isSuccess': true,
        'emailRequired': true,
        'merchantResponse': {
          'csrfToken': merchantResponse?['user']?['csrfToken'],
          'id': merchantResponse?['user']?['id'],
          'token': merchantResponse?['user']?['token'],
          'refreshToken': merchantResponse?['user']?['refreshToken'],
          'email': email,
        },
      };

      await cacheInstance.setValue(
        KeyConfig.gkVerifiedUserKey,
        jsonEncode(userRes),
      );

      return Success(userRes);
    } catch (err) {
      throw handleApiError(err);
    }
  }

  static Future<Result<String>> validateUserToken() async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    try {
      final gokwik = DioClient().getClient();

      final results = await Future.wait([
        cacheInstance.getValue(KeyConfig.gkAccessTokenKey),
        cacheInstance.getValue(KeyConfig.checkoutAccessTokenKey),
      ]);

      final accessToken = results[0];
      final checkoutAccessToken = results[1];

      if (accessToken != null) {
        gokwik.options.headers[KeyConfig.gkAccessTokenKey] = accessToken;
      }
      if (checkoutAccessToken != null) {
        gokwik.options.headers[KeyConfig.checkoutAccessTokenKey] =
            checkoutAccessToken;
      }

      final response = (await gokwik.get(APIConfig.validateUserToken))
          .toBaseResponse<ValidateUserTokenResponseData>(
        fromJson: (json) {
          // if (json == null) {
          //   throw Exception('Response data is null');
          // }
          return ValidateUserTokenResponseData.fromJson(json);
        },
      );

      if (response.isSuccess == false) {
        return Failure(response.errorMessage ?? 'Failed to validate token');
      }

      if (response.data == null) {
        return const Failure('No data received from validate token response');
      }

      try {
        final responseData = jsonEncode(response.data);

        await cacheInstance.setValue(
          KeyConfig.gkVerifiedUserKey,
          responseData,
        );

        return Success(responseData);
      } catch (e) {
        return Failure('Error parsing validate token response: $e');
      }
    } catch (err) {
      throw handleApiError(err);
    }
  }

  static Future<Result> verifyCode(String phoneNumber, String code) async {
    final result = await checkKwikpassHealth();
    if(result.isSuccess) {
      final healthData = result.getDataOrThrow();
      if(healthData?.isKwikpassHealthy == false){
        throw Exception('Kwikpass is unhealthy');
      }
    }

    try {
      final gokwik = DioClient().getClient();

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'submit_otp',
        'action': 'automated',
        'property': 'phone_number',
        'value': int.tryParse(phoneNumber) ?? 0,
      });

      final deviceInfoJson =
          await cacheInstance.getValue(KeyConfig.gkDeviceInfo);
      final deviceInfoDetails =
          deviceInfoJson != null ? jsonDecode(deviceInfoJson) : {};

      final Map<String, String> bodyParams = {};

      if (Platform.isAndroid) {
        bodyParams['google_ad_id'] =
            deviceInfoDetails[KeyConfig.gkGoogleAdId] ?? '';
      }
      if (Platform.isIOS) {
        bodyParams['ios_ad_id'] =
            deviceInfoDetails[KeyConfig.gkGoogleAdId] ?? '';
      }

      final response = (await gokwik.post(
        APIConfig.verifyCode,
        data: {
          'phone': phoneNumber,
          'otp': int.tryParse(code),
          ...bodyParams,
        },
      ))
          .toBaseResponse();


      if (response.isSuccess == false) {
        return Failure(response.errorMessage ?? 'Failed to verify OTP');
      }

      final data = response.data;
      final String token = data['token'];
      final coreToken = data['coreToken'];
      final String kpToken = data?['kpToken'];
      String? merchantType = await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);

      if (merchantType! == 'shopify') {
        final res = await _handleShopifyVerifyResponse(
          response.data,
          phoneNumber,
          token,
          coreToken,
          kpToken,
        );

        // final data = response.data as Map<String, dynamic>?;

        // if (data!.containsKey('email')) {
        //   await trackAnalyticsEvent(AnalyticsEvents.appLoginSuccess, {
        //     'email': data['email']?.toString() ?? "",
        //     'phone': phoneNumber,
        //     'customer_id':
        //     response.data?['shopifyCustomerId']?.toString() ?? "",
        //   });
        // }

        return res;
      }

      await cacheInstance.setValue(KeyConfig.gkAccessTokenKey, token);

      if (coreToken != null) {
        await cacheInstance.setValue(
            KeyConfig.checkoutAccessTokenKey, coreToken);
      }

      // final responseForAffluence = await customerIntelligence();
      await validateUserToken();

      final loginResponse = await loginKpUser();

      final responseData = loginResponse.getDataOrThrow();
      if (loginResponse.isSuccess) {
        if (responseData?.email != null) {
          if (responseData != null) {
            final updatedData = LoginResponseData(
              phone: responseData.phone,
              emailRequired: responseData.emailRequired,
              email: responseData.email,
              merchantResponse: responseData.merchantResponse,
              isSuccess: responseData.isSuccess,
              message: responseData.message,
              /*  affluence: responseForAffluence.isSuccess
                  ? responseForAffluence.getDataOrThrow()
                  : responseData.affluence,*/
            );

            await cacheInstance.setValue(
              KeyConfig.gkVerifiedUserKey,
              jsonEncode(updatedData),
            );
            await SnowplowTrackerService.sendCustomEventToSnowPlow({
              'category': 'login_modal',
              'label': 'phone_Number_logged_in',
              'action': 'logged_in',
              'property': 'phone_number',
              'value': int.tryParse(phoneNumber) ?? 0,
            });

            return Success(updatedData);
          }
        }
      }

      return loginResponse;
    } catch (error) {
      throw handleApiError(error);
    }
  }

  static Future<Result> _handleShopifyVerifyResponse(
      dynamic responseData,
      String phoneNumber,
      String? token,
      String? coreToken,
      String? kpToken) async {
    if (token != null) {
      final gokwik = DioClient().getClient();
      gokwik.options.headers[KeyConfig.gkAccessTokenKey] = token;
      await cacheInstance.setValue(KeyConfig.gkAccessTokenKey, token);
    }

    if (kpToken != null) {
      final gokwik = DioClient().getClient();
      gokwik.options.headers[KeyConfig.gkKpToken] = kpToken;
      await cacheInstance.setValue(KeyConfig.gkKpToken, kpToken);
    }

    if (coreToken != null) {
      final gokwik = DioClient().getClient();
      gokwik.options.headers[KeyConfig.checkoutAccessTokenKey] = coreToken;
      await cacheInstance.setValue(KeyConfig.checkoutAccessTokenKey, coreToken);
    }

    if(responseData.containsKey('authRequired')){
      if (responseData?['authRequired'] && (responseData!['email'] as String).isNotEmpty) {
        return Success(responseData);
      }
    }


    final responseForAffluence = await customerIntelligence();

    if ((responseData?['state'] == 'DISABLED' ||
        responseData?['state'] == 'ENABLED') &&
        responseData!['email'] != null &&
        (responseData!['email'] as String).isNotEmpty) {
      final multipassResponse = await ShopifyService.getShopifyMultipassToken(
        phone: phoneNumber,
        email: responseData?['email'],
        id: responseData?['shopifyCustomerId'],
        state: responseData?['state'],
      );

      if (multipassResponse['data']?['accountActivationUrl'] != null &&
          multipassResponse['data']?['shopifyCustomerId'] != null) {
        final activationUrlParts =
            multipassResponse['data']['accountActivationUrl'].split('/');
        final token = activationUrlParts.last;

        final regex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?([^\/]+)');
        final match =
            regex.firstMatch(multipassResponse['data']['accountActivationUrl']);
        final url = match?.group(1) ?? '';

        await activateUserAccount(
          multipassResponse['data']['shopifyCustomerId'],
          url,
          multipassResponse['data']['password'],
          token,
        );
      }

      if (responseForAffluence is Success &&
          responseForAffluence.data != null) {
        multipassResponse['data']['customer_insights'] = responseForAffluence.data;
      }
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'phone_Number_logged_in',
        'action': 'logged_in',
        'property': 'phone_number',
        'value': int.tryParse(phoneNumber) ?? 0,
      });
      return Success(multipassResponse);
    }

    if (responseData?['email'] != null) {
      final multipassResponse = await ShopifyService.getShopifyMultipassToken(
          phone: phoneNumber,
          email: responseData?['email'],
          id: responseData?['shopifyCustomerId'],
          state: responseData?['state']);

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'phone_Number_logged_in',
        'action': 'logged_in',
        'property': 'phone_number',
        'value': int.tryParse(phoneNumber) ?? 0,
      });

      if (responseForAffluence is Success &&
          responseForAffluence.data != null) {
        multipassResponse['data']['customer_insights'] = responseForAffluence.data;
      }
      return Success(multipassResponse['data']);
    }

    final userData = {
      ...responseData,
      'phone': phoneNumber,
      'affluence': ""
    };

    if (responseForAffluence is Success &&
        responseForAffluence.data != null) {
      userData['customer_insights'] = responseForAffluence.data;
    }

    await cacheInstance.setValue(
      KeyConfig.gkVerifiedUserKey,
      jsonEncode(userData),
    );

    await SnowplowTrackerService.sendCustomEventToSnowPlow({
      'category': 'login_modal',
      'label': 'phone_Number_logged_in',
      'action': 'logged_in',
      'property': 'phone_number',
      'value': int.tryParse(phoneNumber) ?? 0,
    });

    return Success(userData);
  }

  static Future<Result<Map<String, dynamic>>> kwikpassLoginWithToken({
    required String token,
    required String phone,
    required String email,
    required String shopifyCustomerId,
  }) async {
    try {
      // Check if user is already authenticated
      final verifiedUserJson =
          await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
      
      if (verifiedUserJson != null) {
        final responseData = jsonDecode(verifiedUserJson) as Map<String, dynamic>;
        
        // Check if user has all required data
        if ((responseData['shopifyCustomerId'] != null &&
            responseData['phone'] != null &&
            responseData['email'] != null) ||
            (responseData['phone'] != null && responseData['email'] != null)) {
          return Success({
            'result': true,
            'message': 'User already authenticated',
            'data': responseData,
          });
        }
      }

      // Validate token
      if (token.isEmpty) {
        return const Failure('Token is required for authentication');
      }

      // Check Kwikpass health
      final kpHealthData = await checkKwikpassHealth();
      if (kpHealthData.isSuccess) {
        final healthData = kpHealthData.getDataOrThrow();
        if (healthData?.isKwikpassHealthy == false) {
          throw KwikpassHealthException();
        }
      }

      final gokwik = DioClient().getClient();

      // Get merchant ID and request ID from cache
      final results = await Future.wait([
        cacheInstance.getValue(KeyConfig.gkMerchantIdKey),
        cacheInstance.getValue(KeyConfig.gkRequestIdKey),
      ]);

      final mid = results[0];
      final requestId = results[1];

      // Prepare headers
      final headers = <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json',
        KeyConfig.kpMerchantIdKey: mid ?? '',
        'token': token,
      };

      // Add request ID if available
      if (requestId != null && requestId.isNotEmpty) {
        headers[KeyConfig.gkRequestIdKey] = requestId;
      }

      final response = await gokwik.get(
        APIConfig.reverseKpAuthLogin,
        options: Options(headers: headers),
      );

      final data = response.data;

      // Handle successful login response
      if (data?['data']?['token'] != null) {
        // Store access token
        final accessToken = data['data']['token'] as String;
        await cacheInstance.setValue(KeyConfig.gkAccessTokenKey, accessToken);
        gokwik.options.headers[KeyConfig.gkAccessTokenKey] = accessToken;
      }

      if (data?['data']?['coreToken'] != null) {
        // Store core token
        await cacheInstance.setValue(KeyConfig.checkoutAccessTokenKey, token);
        gokwik.options.headers[KeyConfig.checkoutAccessTokenKey] = token;
      }

      // Validate user token
      await validateUserToken();

      // Store user data
      final userData = {
        'phone': phone,
        'email': email,
        'shopifyCustomerId': shopifyCustomerId,
        ...?data?['data'] as Map<String, dynamic>?,
      };
      
      await cacheInstance.setValue(
        KeyConfig.gkVerifiedUserKey,
        jsonEncode(userData),
      );

      return Success(data);
    } catch (error) {
      throw handleApiError(error);
    }
  }

  static Future<bool> clearKwikpassSession() async {
    try {
      final userJson =
          await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
      final parsedUser =
          userJson != null ? jsonDecode(userJson) : <String, dynamic>{'phone': '0'};
      final phone = parsedUser['phone']?.toString() ?? '0';
      
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'logged_in_page',
        'label': 'logout_button_click',
        'action': 'automated',
        'property': 'phone_number',
        'value': int.tryParse(phone) ?? 0,
      });

      // await trackAnalyticsEvent(AnalyticsEvents.appLogout, {
      //   'email': parsedUser['email']?.toString() ?? "",
      //   'phone': phone,
      //   'customer_id': parsedUser['shopifyCustomerId']?.toString() ?? "",
      // });

      final env = await cacheInstance.getValue(KeyConfig.gkEnvironmentKey);
      final mid = await cacheInstance.getValue(KeyConfig.gkMerchantIdKey) ?? '';
      final isSnowplowTrackingEnabled =
          await cacheInstance.getValue(KeyConfig.isSnowplowTrackingEnabled) ==
              'true';

      final isKpEnabled =
          await cacheInstance.getValue(KeyConfig.enableKwikPass) ==
              'true';
              final isCheckoutEnabled =
          await cacheInstance.getValue(KeyConfig.enableCheckout) ==
              'true';

              final mode =
          await cacheInstance.getValue(KeyConfig.gkMode);

      final gokwik = DioClient().getClient();

      gokwik.options.headers.remove(KeyConfig.gkAccessTokenKey);
      gokwik.options.headers.remove(KeyConfig.checkoutAccessTokenKey);
      gokwik.options.headers.remove(KeyConfig.kpRequestIdKey);
      gokwik.options.headers.remove(KeyConfig.gkRequestIdKey);
      gokwik.options.headers.remove('Authorization');

      cacheInstance.clearCache();
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove(KeyConfig.gkCoreTokenKey);
      // await prefs.remove(KeyConfig.gkAccessTokenKey);
      // await prefs.remove(KeyConfig.gkVerifiedUserKey);
      // await prefs.remove(KeyConfig.gkRequestIdKey);
      // await prefs.remove(KeyConfig.kpRequestIdKey);
      // await prefs.remove(KeyConfig.gkAuthTokenKey);
      await SecureStorage.clearAllSecureData();

      await initializeSdk(InitializeSdkProps(
        mid: mid,
        environment: Environment.values.firstWhere((e) => e.name == env,
            orElse: () => Environment.sandbox),
        isSnowplowTrackingEnabled: isSnowplowTrackingEnabled,
        mode: mode ?? "",
        settings: Settings(
          enableKwikPass: isKpEnabled,
          enableCheckout: isCheckoutEnabled,
        ),
      ));

      // Logger().clearLogs();

      return true;
    } catch (error) {
      throw handleApiError(error);
    }
  }
}
