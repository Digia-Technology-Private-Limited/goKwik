import 'package:gokwik/api/api_service.dart';
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
      throw ApiService.handleApiError(err);
    }
  }

  Future<bool> logout() async {
    return await ApiService.checkout();
  }
}
