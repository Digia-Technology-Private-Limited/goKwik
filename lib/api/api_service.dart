import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/analytics/analytics.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/api/httpClient.dart';
import 'package:gokwik/api/snowplow_client.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/config/storege.dart';
import 'package:gokwik/module/advertise.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/types.dart';
import 'sdk_config.dart';
import 'shopify_service.dart';

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
        KeyConfig.kpRequestIdKey: requestId ?? '',
      };

      if (accessToken != null) {
        headers[KeyConfig.gkAccessTokenKey] = accessToken;
      }

      gokwik.options.headers.addAll(headers);

      final response = (await gokwik.get('health/merchant')).toBaseResponse(
        fromJson: (json) => HealthCheckResponseData.fromJson(json),
      );

      if (response.isSuccess ?? false) {
        return Success(response.data);
      }

      return Failure(response.errorMessage ?? 'Failed to check health');
    } catch (error) {
      debugPrint("ERRORRR $error");
      return Failure(handleApiError(error).message);
    }
  }

  static Failure handleApiError(dynamic error) {
    String message = 'An unknown error occurred';

    if (error is DioException) {
      final response = error.response?.toBaseResponse();
      if (response != null) {
        // final data = response.error;
        final status = response.statusCode;
        // final requestId = response.requestId ?? 'N/A';
        message = response.error?.toString() ??
            response.errorMessage?.toString() ??
            response.error_msg?.toString() ??
            'Unexpected error with status: $status';
        return Failure(message);
      }
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
        'customer-intelligence',
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
      final response = (await goKwik.get('auth/browser')).toBaseResponse();
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

      final response = (await gokwik.get('configurations/$mid')).toBaseResponse(
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
      
      // Create settings with defaults, then merge with provided settings
      final settingsWithDefaults = Settings(
        enableKwikPass: args.settings?.enableKwikPass ?? true,
        enableCheckout: args.settings?.enableCheckout ?? true,
      );
      
      final enableKwikPass = settingsWithDefaults.enableKwikPass;
      final enableCheckout = settingsWithDefaults.enableCheckout;
      
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

      // await getBrowserToken();
      final merchantConfig = await initializeMerchant(mid, environment.name);
      final result = await checkKwikpassHealth();
      if(result.isSuccess) {
        final healthData = result.getDataOrThrow();
        if(healthData?.isKwikpassHealthy == false){
          throw Exception('Kwikpass is unhealthy');
        }
      }

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

      initializeAnalytics("MOE_ID", webengageAutoRegister: true);

      return {'message': 'Initialization Successful'};
    } catch (error) {
      if (error is Failure) {
        throw handleApiError(error);
      }
      throw error;
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
        'auth/otp/send',
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
          (await gokwik.get('customer/custom/login')).toBaseResponse(
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
        'customer/custom/create-user',
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

      final response = (await gokwik.get('auth/validate-token'))
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
        return Failure('No data received from validate token response');
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
        'auth/otp/verify',
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
      String? merchantType =
          await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);

      if (merchantType! == 'shopify') {
        final res = await _handleShopifyVerifyResponse(
          response.data,
          phoneNumber,
          token,
          coreToken,
          kpToken,
        );
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

    final responseForAffluence = await customerIntelligence();

    if (responseData?['state'] == 'DISABLED' ||
        responseData?['state'] == 'ENABLED') {
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
        multipassResponse['data']['affluence'] = responseForAffluence.data;
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
        multipassResponse['data']['affluence'] = responseForAffluence.data;
      }
      return Success(multipassResponse['data']);
    }

    final userData = {
      ...responseData,
      'phone': phoneNumber,
    };

    await cacheInstance.setValue(
      KeyConfig.gkVerifiedUserKey,
      jsonEncode(userData),
    );

    if (responseForAffluence is Success && responseForAffluence.data != null) {
      responseData['data']['affluence'] = responseForAffluence;
    }
    await SnowplowTrackerService.sendCustomEventToSnowPlow({
      'category': 'login_modal',
      'label': 'phone_Number_logged_in',
      'action': 'logged_in',
      'property': 'phone_number',
      'value': int.tryParse(phoneNumber) ?? 0,
    });

    return Success(responseData);
  }

  static Future<bool> clearKwikpassSession() async {
    try {
      final userJson =
          await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
      final parsedUser =
          userJson != null ? jsonDecode(userJson) : {'phone': '0'};
      final phone = parsedUser['phone']?.toString() ?? '0';
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'logged_in_page',
        'label': 'logout_button_click',
        'action': 'automated',
        'property': 'phone_number',
        'value': int.tryParse(phone) ?? 0,
      });

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
