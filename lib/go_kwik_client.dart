import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/config/storege.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/module/logger.dart';

class GoKwikClient {
  static final GoKwikClient _instance = GoKwikClient._();

  GoKwikClient._();

  static GoKwikClient get instance => _instance;

  late InitializeSdkProps props;

  // Add your methods and properties here
  Future<void> initializeSDK(InitializeSdkProps props) async {
    try {
      this.props = props;
      Logger();
      await SecureStorage.init();
      await ApiService.initializeSdk(props);
    } catch (err) {
      rethrow;
    }
  }

  /// Perform reverse login with Kwikpass token
  ///
  /// This method should be called after SDK initialization to authenticate
  /// the user with their existing credentials.
  ///
  /// Parameters:
  /// - [token]: Authentication token from the host app
  /// - [phone]: User's phone number
  /// - [email]: User's email address
  /// - [shopifyCustomerId]: Shopify customer ID
  ///
  /// Returns a [Result] containing the login response data or failure message
  Future<Result<Map<String, dynamic>>> reverseLogin({
    required String token,
    required String phone,
    required String email,
    required String shopifyCustomerId,
  }) async {
    try {
      return await ApiService.kwikpassLoginWithToken(
        token: token,
        phone: phone,
        email: email,
        shopifyCustomerId: shopifyCustomerId,
      );
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> logout() async {
    return await ApiService.clearKwikpassSession();
  }
}
