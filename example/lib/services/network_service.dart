import 'package:dio/dio.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  late final Dio _dio;
  final List<Map<String, dynamic>> _logs = [];

  factory NetworkService() {
    return _instance;
  }

  NetworkService._internal() {
    _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logs.add({
          'timestamp': DateTime.now(),
          'url': options.uri.toString(),
          'method': options.method,
          'requestHeaders': options.headers,
          'requestBody': options.data,
          'type': 'request',
        });
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logs.add({
          'timestamp': DateTime.now(),
          'url': response.requestOptions.uri.toString(),
          'method': response.requestOptions.method,
          'statusCode': response.statusCode,
          'responseHeaders': response.headers.map,
          'responseBody': response.data,
          'type': 'response',
        });
        return handler.next(response);
      },
      onError: (error, handler) {
        _logs.add({
          'timestamp': DateTime.now(),
          'url': error.requestOptions.uri.toString(),
          'method': error.requestOptions.method,
          'error': error.message,
          'type': 'error',
        });
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
  List<Map<String, dynamic>> get logs => _logs;
} 