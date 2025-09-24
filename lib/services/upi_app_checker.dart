import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UpiAppChecker {
  static const MethodChannel _channel = MethodChannel('upi_app_checker');

  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool result = await _channel
          .invokeMethod('isAppInstalled', {'packageName': packageName});
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error checking UPI app installation: $e');
        print(stackTrace);
      }
      return false;
    }
  }
}
