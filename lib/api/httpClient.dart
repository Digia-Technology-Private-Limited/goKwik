import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/config_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'base_response.dart';
import 'sdk_config.dart';
import 'ssl_pinning_adapter.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  Dio? _gokwikHttpClient;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal();

  Future<void> initialize(String env) async {
    if (_gokwikHttpClient != null) return;

    String appPlatform;

    if (defaultTargetPlatform == TargetPlatform.android) {
      appPlatform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      appPlatform = 'ios';
    } else {
      appPlatform = 'unknown';
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final source = '${appPlatform}-app';

    // Get environment config - automatically falls back to bundled kp-config.json
    final envConfig = cdnConfigInstance.getEnvironment(env);
    final baseUrl = envConfig?.baseUrl ?? SdkConfig.getBaseUrl(env);

    _gokwikHttpClient = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'accept': '*/*',
        cdnConfigInstance.getHeader(APIHeaderKeys.appplatform)!: appPlatform,
        cdnConfigInstance.getHeader(APIHeaderKeys.appversion)!: appVersion,
        cdnConfigInstance.getHeader(APIHeaderKeys.source)!: source,
      },
    ));

    // Configure SSL pinning for the environment
    try {
      SSLPinningAdapter.configureDio(_gokwikHttpClient!, env);
      if (kDebugMode) {
        // print('✅ SSL Pinning configured for environment: $env');
        // print('   Pinned domain: ${SSLPinningAdapter.getPinnedDomain(env)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to configure SSL pinning: $e');
      }
      // Continue without SSL pinning in case of configuration error
    }
  }

  Dio getClient() {
    if (_gokwikHttpClient == null) {
      throw Exception(
          'HTTP client not initialized. Please call initialize first or provide environment.');
    }

    _gokwikHttpClient?.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) => handler.next(options),
    ));

    return _gokwikHttpClient!;
  }

  static convertToBaseResponse<T>(
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    return BaseResponse.fromJson(data, fromJson);
  }

  void dispose() {
    _gokwikHttpClient?.close();
    _gokwikHttpClient = null;
  }
}

extension DioResponseExtension on Response {BaseResponse<T> toBaseResponse<T>({T Function(Map<String, dynamic>)? fromJson}) {
    return BaseResponse<T>.fromJson(data, fromJson);
  }
}
