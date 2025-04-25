import 'package:flutter/services.dart';

class AdvertisingInfoResponse {
  final String? id;
  final bool isAdTrackingLimited;

  AdvertisingInfoResponse({
    this.id,
    required this.isAdTrackingLimited,
  });

  factory AdvertisingInfoResponse.fromMap(Map<dynamic, dynamic> map) {
    return AdvertisingInfoResponse(
      id: map['id'] as String?,
      isAdTrackingLimited: map['isAdTrackingLimited'] as bool? ?? true,
    );
  }

  static AdvertisingInfoResponse fallback() {
    return AdvertisingInfoResponse(id: null, isAdTrackingLimited: true);
  }
}

class AdvertisingInfo {
  static final AdvertisingInfo _instance = AdvertisingInfo._internal();
  factory AdvertisingInfo() => _instance;

  static const MethodChannel _channel = MethodChannel('advertising_info');

  AdvertisingInfo._internal();

  Future<AdvertisingInfoResponse> getAdvertisingInfo() async {
    try {
      final result = await _channel.invokeMethod('getAdvertisingInfo');
      return AdvertisingInfoResponse.fromMap(result);
    } catch (e) {
      print('getAdvertisingInfo error: $e');
      return AdvertisingInfoResponse.fallback();
    }
  }

  Future<AdvertisingInfoResponse> getAdvertisingInfoAndCheckAuthorization(
      bool check) async {
    try {
      final result = await _channel
          .invokeMethod('getAdvertisingInfoAndCheckAuthorization', {
        'check': check,
      });
      return AdvertisingInfoResponse.fromMap(result);
    } catch (e) {
      print('getAdvertisingInfoAndCheckAuthorization error: $e');
      return AdvertisingInfoResponse.fallback();
    }
  }
}
