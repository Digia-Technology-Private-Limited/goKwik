import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/httpClient.dart';
import 'package:gokwik/config/types.dart';

class GoKwikClient {
  static final GoKwikClient _instance = GoKwikClient._();

  GoKwikClient._();

  static GoKwikClient get instance => _instance;

  late InitializeSdkProps props;

  // Add your methods and properties here
  Future<void> initializeSDK(InitializeSdkProps props) async {
    this.props = props;
    await DioClient().initialize(props.environment.name);
    await ApiService.initializeSdk(props);
  }
}
