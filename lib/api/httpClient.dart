import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'base_response.dart';
import 'sdk_config.dart';

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

    final baseUrl = SdkConfig.getBaseUrl(env);

    _gokwikHttpClient = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'accept': '*/*',
        'appplatform': appPlatform,
        'appversion': appVersion,
        'source': source,
        'origin': 'https://pdp.gokwik.co',
        'referer': 'https://pdp.gokwik.co',
      },
    ));
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
    debugPrint("check 1" + data.toString());
    debugPrint("check 2" + fromJson.toString());
    debugPrint("check 3" + data['isSuccess'].toString());
    var temp= BaseResponse<T>.fromJson(data, fromJson);
    print("check 5"+temp.toString());
    return BaseResponse<T>.fromJson(data, fromJson);
  }
}
