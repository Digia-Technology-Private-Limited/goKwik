import 'package:advertising_id/advertising_id.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:gokwik/module/logger.dart';

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

  @override
  String toString() =>
      'AdvertisingInfoResponse(id: ${id != null ? '${id!.substring(0, 5)}...' : null}, '
      'limited: $isAdTrackingLimited)';
}

abstract class AdvertisingInfo {
  // static const MethodChannel _channel =
  //     const MethodChannel('com.yourcompany.advertising_info');

  // static Future<AdvertisingInfoResponse> getAdvertisingInfo() async {
  //   try {
  //     final result = await _channel.invokeMethod('getAdvertisingInfo');
  //     return AdvertisingInfoResponse.fromMap(
  //         result as Map<dynamic, dynamic>? ?? {});
  //   } on PlatformException catch (e, stack) {
  //     _logError('getAdvertisingInfo', e, stack);
  //     return AdvertisingInfoResponse.fallback();
  //   } catch (e, stack) {
  //     _logError('getAdvertisingInfo', e, stack);
  //     return AdvertisingInfoResponse.fallback();
  //   }
  // }

  // static Future<AdvertisingInfoResponse>
  //     getAdvertisingInfoAndCheckAuthorization(
  //   bool check,
  // ) async {
  //   try {
  //     final result = await _channel.invokeMethod(
  //       'getAdvertisingInfoAndCheckAuthorization',
  //       {'check': check},
  //     );
  //     return AdvertisingInfoResponse.fromMap(
  //         result as Map<dynamic, dynamic>? ?? {});
  //   } on PlatformException catch (e, stack) {
  //     _logError('getAdvertisingInfoAndCheckAuthorization', e, stack);
  //     return AdvertisingInfoResponse.fallback();
  //   } catch (e, stack) {
  //     _logError('getAdvertisingInfoAndCheckAuthorization', e, stack);
  //     return AdvertisingInfoResponse.fallback();
  //   }
  // }

  static Future<AdvertisingInfoResponse> getAdvertisingInfo() async {
    try {
      // final havePermission =
      //     await AppTrackingTransparency.requestTrackingAuthorization();
      final isLimitAdTrackingEnabled =
          await AdvertisingId.isLimitAdTrackingEnabled;
      final advertisingId = await AdvertisingId.id(false);
      return AdvertisingInfoResponse(
        id: advertisingId,
        isAdTrackingLimited: isLimitAdTrackingEnabled ?? false,
      );
    } catch (e, stack) {
      _logError('getAdvertisingInfo', e, stack);
      return AdvertisingInfoResponse.fallback();
    }
  }

  Future<void> requestTrackingPermission() async {
    await AppTrackingTransparency.requestTrackingAuthorization();
  }

  static Future<AdvertisingInfoResponse>
      getAdvertisingInfoAndCheckAuthorization(
    bool check,
  ) async {
    try {
      final isLimitAdTrackingEnabled =
          await AdvertisingId.isLimitAdTrackingEnabled;

      // Here, you can use the `check` parameter if you want extra logic.
      // Example: if check == true && isLimitAdTrackingEnabled == true, maybe treat as no ID.
      final advertisingId = await AdvertisingId.id(true);

      if (check && (isLimitAdTrackingEnabled ?? false)) {
        // If tracking is limited and check is required, treat ID as empty
        return AdvertisingInfoResponse.fallback();
      }

      return AdvertisingInfoResponse(
        id: advertisingId ?? '',
        isAdTrackingLimited: isLimitAdTrackingEnabled ?? false,
      );
    } catch (e, stack) {
      _logError('getAdvertisingInfoAndCheckAuthorization', e, stack);
      return AdvertisingInfoResponse.fallback();
    }
  }

  static void _logError(String method, dynamic error, StackTrace stack) {
    Logger().log('$method error: $error\n$stack');
    // Add your crash analytics logging here (Sentry, Firebase Crashlytics, etc.)
  }
}
