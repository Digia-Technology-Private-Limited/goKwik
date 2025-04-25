import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gokwik/api/sdk_config.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutShopify extends StatefulWidget {
  final String cartId;

  const CheckoutShopify({Key? key, required this.cartId}) : super(key: key);

  @override
  _CheckoutShopifyState createState() => _CheckoutShopifyState();
}

class _CheckoutShopifyState extends State<CheckoutShopify> {
  String webUrl = '';
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
    initiateCheckout();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          handleMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (error) {
            debugPrint('Web resource error: $error');
          },
        ),
      );
  }

  Future<void> initiateCheckout() async {
    final environment =
        await cacheInstance.getValue(KeyConfig.gkEnvironmentKey);

    final merchantInfo = {
      'mid': await cacheInstance.getValue(KeyConfig.gkMerchantIdKey),
      'environment': environment,
      'token': await cacheInstance.getValue(KeyConfig.checkoutAccessTokenKey),
      'shopDomain': await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey),
    };

    final storeInfo = {
      'type': 'merchantInfo',
      'source': 'app',
      'appFlow': 'true',
      'blockExternalEvents': true,
      'mid': merchantInfo['mid'],
      'environment': merchantInfo['environment'],
      'storeId': '',
      'fbpixel': '',
      'gaTrackingID': '',
      'webEngageID': '',
      'moEngageID': '',
      'storeData': {
        'cartId': 'gid://shopify/Cart/${widget.cartId}',
        'storefrontAccessToken': '',
        'shopDomain': merchantInfo['shopDomain'],
      },
    };

    final encodedStoreInfo = base64Encode(utf8.encode(jsonEncode(storeInfo)));

    String checkoutBaseUrl =
        SdkConfig.fromEnvironment(environment!).checkoutUrl['shopify']!;

    String url = '$checkoutBaseUrl$encodedStoreInfo';

    if (merchantInfo['token'] != null) {
      final tokenPayload = base64Encode(
          utf8.encode(jsonEncode({'coreToken': merchantInfo['token']})));
      url += '&gk_token=$tokenPayload';
    }

    debugPrint('Final WebView URL: $url');

    setState(() {
      webUrl = url;
      _webViewController.loadRequest(Uri.parse(url));
    });
  }

  void handleMessage(String message) {
    final decoded = jsonDecode(message);
    debugPrint('Received message from WebView: $decoded');
  }

  @override
  Widget build(BuildContext context) {
    if (webUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _webViewController);
  }
}
