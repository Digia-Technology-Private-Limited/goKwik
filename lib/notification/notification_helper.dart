// import 'dart:convert';
import 'dart:io';

// import 'package:gokwik/config/cache_instance.dart';
// import 'package:gokwik/config/cdn_config.dart';
// import 'package:gokwik/config/config_constants.dart';
// import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  static Future<bool> checkAndRequestUserPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.notification.status;
      if (status.isGranted) {
        return true;
      } else {
        // Request permission if not granted
        var result = await Permission.notification.request();
        return result.isGranted;
      }
    }
    // For other platforms (web, windows, etc.), you can decide default behavior
    return false;
  }

  static Future<void> sendNotificationStatus(
    String messageId,
    String status, {
    String failureReason = '',
    String buttonId = '',
  }) async {
    // try {
    //   final url = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcNotificationEventUrl)!,
    //   ) ?? '';
    //   final userId = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcMerchantId)!,
    //   );
    //   final token = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcMerchantToken)!,
    //   );

    //   if (userId == null || token == null) return;

    //   final data = {
    //     'status': status,
    //     'button_id': buttonId,
    //     'failure_reason': failureReason,
    //     'message_id': messageId,
    //   };

    //   final headers = {
    //     'Content-Type': 'application/json',
    //     'id': userId,
    //     'provider': 'kwikchat-dynamic',
    //     'token': token,
    //   };

    //   // final response = await http.post(
    //   //   Uri.parse(url),
    //   //   headers: headers,
    //   //   body: jsonEncode(data),
    //   // );

    //   // if (response.statusCode != 200) {
    //   //   throw Exception('HTTP error! Status: ${response.statusCode}');
    //   // }
    // } catch (e) {}
  }

  static Future<void> sendOptInStatus(bool status) async {
    // try {
    //   final deviceInfoJson = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.gkDeviceInfo)!,
    //   );
    //   final deviceInfo = jsonDecode(deviceInfoJson ?? '{}');

    //   final url = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcNotificationEventUrl)!,
    //   ) ?? '';
    //   final userId = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcMerchantId)!,
    //   );
    //   final token = await cacheInstance.getValue(
    //     cdnConfigInstance.getKeys(StorageKeyKeys.kcMerchantToken)!,
    //   );

    //   if (userId == null || token == null) return;

    //   final data = {
    //     'subscription_status': status,
    //     'app_domain': deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkAppDomain)],
    //     'device_id': deviceInfo[cdnConfigInstance.getKeys(StorageKeyKeys.gkDeviceUniqueId)],
    //   };

    //   final headers = {
    //     'Content-Type': 'application/json',
    //     'id': userId,
    //     'provider': 'kwikchat-dynamic',
    //     'token': token,
    //   };

    //   // final response = await http.post(
    //   //   Uri.parse(url),
    //   //   headers: headers,
    //   //   body: jsonEncode(data),
    //   // );

    //   // if (response.statusCode != 200) {
    //   //   throw Exception('HTTP error! Status: ${response.statusCode}');
    //   // }
    // } catch (e) {}
  }
}
