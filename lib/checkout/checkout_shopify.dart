import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gokwik/api/sdk_config.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/flow_result.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutShopify extends StatefulWidget {
  final String cartId;
  final Function(FlowResult)? onSuccess;
  final Function(FlowResult)? onError;

  const CheckoutShopify({
    Key? key,
    required this.cartId,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  _CheckoutShopifyState createState() => _CheckoutShopifyState();
}

class _CheckoutShopifyState extends State<CheckoutShopify> {
  String webUrl = '';
  late final WebViewController _webViewController;
  late final WebViewCookieManager _cookieManager;

  final String injectedJavaScript = '''
  (function checkGoKwikSdk() {
  if (typeof gokwikSdk !== 'undefined' && typeof gokwikSdk.on === 'function') {
    gokwikSdk.on('modal_closed', function (data) {
      Flutter.postMessage(JSON.stringify({ type: 'modal_closed', data: data }));
    });

    gokwikSdk.on('orderSuccess', function (data) {
      Flutter.postMessage(JSON.stringify({ type: 'orderSuccess', data: data }));
    });

    gokwikSdk.on('openInBrowserTab', function (data) {
      Flutter.postMessage(JSON.stringify({ type: 'openInBrowserTab', data: data }));
    });

    console.log('GoKwik SDK hooks set');
  } else {
    setTimeout(checkGoKwikSdk, 500);
    console.log('Retrying: GoKwik SDK not ready');
  }
})();

document.addEventListener("gk-checkout-disable", function(event) {
  Flutter.postMessage(JSON.stringify({ type: 'gk-checkout-disable', data: event.detail }));
});
window.addEventListener('load', function() {
  checkGoKwikSdk();
});

  ''';

  @override
  void initState() {
    super.initState();
    _cookieManager = WebViewCookieManager();
    _initWebViewController();
    initiateCheckout();
  }

  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..runJavaScript(injectedJavaScript)
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
          onPageFinished: (url) async {
            debugPrint('Page finished loading: $url');
            await _webViewController.runJavaScript(injectedJavaScript);
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
    });

    _webViewController.loadRequest(Uri.parse(url));
  }

  void handleMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      final event = decoded['type'];
      final data = decoded['data'];

      switch (event) {
        case 'orderSuccess':
          widget.onSuccess?.call(
            FlowResult(
              flowType: FlowType.checkoutSuccess,
              data: data,
              extra: decoded,
            ),
          );
          break;
        case 'modal_closed':
          widget.onError?.call(
            FlowResult(
              flowType: FlowType.modalClosed,
              error: 'User closed modal',
              extra: decoded,
            ),
          );
          break;
        case 'openInBrowserTab':
          widget.onSuccess?.call(
            FlowResult(
              flowType: FlowType.openInBrowserTab,
              data: data,
              extra: decoded,
            ),
          );
          break;
        default:
          widget.onError?.call(
            FlowResult(
              flowType: FlowType.checkoutFailed,
              error: 'Some error Occured',
              extra: decoded,
            ),
          );
          debugPrint('Unhandled WebView event: $event');
          break;
      }
    } catch (e) {
      widget.onError?.call(
        FlowResult(
          flowType: FlowType.checkoutFailed,
          error: e,
        ),
      );
    }
  }

  @override
  void dispose() {
    _resetWebView();
    super.dispose();
  }

  // Clear cache and cookies first
  void _resetWebView() async {
    await _webViewController.clearCache();
    await _webViewController.clearLocalStorage();
    await _cookieManager.clearCookies();
  }

  @override
  Widget build(BuildContext context) {
    if (webUrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _webViewController);
  }
}
