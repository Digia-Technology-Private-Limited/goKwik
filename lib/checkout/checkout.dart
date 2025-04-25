import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/shopify_service.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/sdk_config.dart';

class Checkout extends StatefulWidget {
  final String checkoutId;
  final String storefrontToken;
  final String cartId;
  final Function(dynamic) onMessage;
  final Function(dynamic) onError;
  final String storeId;
  final String fbpixel;
  final String gaTrackingID;
  final String webEngageID;
  final String moEngageID;
  final String sessionId;
  final Map<String, dynamic> utmParams;

  const Checkout({
    Key? key,
    required this.checkoutId,
    this.storefrontToken = '',
    required this.cartId,
    required this.onMessage,
    required this.onError,
    this.storeId = '',
    this.fbpixel = '',
    this.gaTrackingID = '',
    this.webEngageID = '',
    this.moEngageID = '',
    this.sessionId = '',
    this.utmParams = const {},
  }) : super(key: key);

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> with WidgetsBindingObserver {
  late WebViewController _webViewController;
  String? _webviewUrl;
  bool _isLoading = true;
  bool _canGoBack = false;
  AppLifecycleState? _appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize WebView for Android
    // if (Platform.isAndroid) {
    //   WebView.platformCreated;
    // }

    _initializeWebViewController();
    _initiateCheckout();
  }

  void _initializeWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            _webViewController.runJavaScript(_getInjectJavaScript());
            _canGoBack = await _webViewController.canGoBack();
          },
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            setState(() {
              _isLoading = true;
            });
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('WebView error: ${error.description}');
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterPostMessage',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appState = state;
    });
    if (_webviewUrl != null && _webviewUrl!.contains('shopify')) {
      _sendAppStateToWebView(state);
    }
  }

  Future<void> _initiateCheckout() async {
    // In Flutter, you'll need to implement your own CacheInstance equivalent
    // For now, I'll assume we have similar methods available
    final merchantType =
        await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
    final environment =
        await cacheInstance.getValue(KeyConfig.gkEnvironmentKey);
    final sdkConfig = SdkConfig.fromEnvironment(environment!);

    if (merchantType == 'custom') {
      final merchantId =
          await cacheInstance.getValue(KeyConfig.gkMerchantIdKey);
      final token = await cacheInstance.getValue(KeyConfig.gkAccessTokenKey);

      String appplatform = Platform.operatingSystem;
      String appversion = (await PackageInfo.fromPlatform()).version;
      String appsource = '${Platform.operatingSystem}-app';

      final webviewUrl =
          '${sdkConfig.checkoutUrl['custom']}?m_id=$merchantId&checkout_id=${widget.checkoutId}&gokwik_token=$token&&appplatform=$appplatform&appversion=$appversion&appsource=$appsource';

      setState(() {
        _webviewUrl = webviewUrl;
      });
      _webViewController.loadRequest(Uri.parse(webviewUrl));
      return;
    }

    final merchantInfo = {
      'mid': await cacheInstance.getValue(KeyConfig.gkMerchantIdKey),
      'environment': await cacheInstance.getValue(KeyConfig.gkEnvironmentKey),
      'token': await cacheInstance.getValue(KeyConfig.checkoutAccessTokenKey),
      'shopDomain': await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey),
    };

    String cartId = widget.cartId;
    if (!cartId.contains('gid://shopify/Cart')) {
      cartId = 'gid://shopify/Cart/$cartId';
    }

    final storeInfo = {
      'type': 'merchantInfo',
      'source': 'app',
      'platform': Platform.operatingSystem,
      'appFlow': 'true',
      'sessionID': widget.sessionId,
      'blockExternalEvents': true,
      'mid': merchantInfo['mid'],
      'environment': merchantInfo['environment'],
      'storeId': widget.storeId,
      'fbpixel': widget.fbpixel,
      'gaTrackingID': widget.gaTrackingID,
      'webEngageID': widget.webEngageID,
      'moEngageID': widget.moEngageID,
      'utmParams': widget.utmParams,
      'storeData': {
        'cartId': cartId,
        'storefrontAccessToken': widget.storefrontToken,
        'shopDomain': merchantInfo['shopDomain'],
      },
    };

    final storeInfoEncoded = base64Encode(utf8.encode(jsonEncode(storeInfo)));
    String webViewUrl = '${sdkConfig.checkoutUrl['shopify']}$storeInfoEncoded';

    if (merchantInfo['token'] != null) {
      final gkToken = jsonEncode({
        'coreToken': merchantInfo['token'],
      });
      final gkTokenEncoded = base64Encode(utf8.encode(gkToken));
      webViewUrl += '&gk_token=$gkTokenEncoded';
    }

    setState(() {
      _webviewUrl = webViewUrl;
    });
    _webViewController.loadRequest(Uri.parse(webViewUrl));
  }

  void _sendAppStateToWebView(AppLifecycleState state) {
    _webViewController.runJavaScript(
      'window.postMessage(${jsonEncode({
            'action': 'appState',
            'state': state.toString()
          })}, "*")',
    );
  }

  Future<bool> _handleBackButton() async {
    bool canGoBack = await _webViewController.canGoBack();
    if (canGoBack) {
      await _webViewController.goBack();
      return true;
    } else {
      _webViewController.runJavaScript(
        'window.postMessage(${jsonEncode({
              'action': 'hardwareBackPress'
            })}, "*")',
      );
      return true;
    }
  }

  void _handleMessage(dynamic message) async {
    try {
      final merchantType =
          await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
      final parsedData = jsonDecode(message);
      final gkToken = await cacheInstance.getValue(KeyConfig.gkAccessTokenKey);

      if (merchantType == 'shopify' &&
          parsedData['eventname'] == 'orderSuccess' &&
          gkToken == null) {
        final user = {
          'email': parsedData['data']['orderSuccessBody']['email'],
          'phone': parsedData['data']['orderSuccessBody']['phone'],
          'gkAccessToken': parsedData['data']['orderSuccessBody']
              ['gk_access_token'],
        };

        await cacheInstance.setValue(
            KeyConfig.gkAccessTokenKey, user['gkAccessToken']);

        // Implement getCheckoutMultiPassToken, activateUserAccount, and sendCustomEventToSnowPlow in Dart
        final multipassResponse =
            await ShopifyService.getCheckoutMultiPassToken(
          phone: user['phone'],
          email: user['email'],
          gkAccessToken: user['gkAccessToken'],
        );

        final multipassData = multipassResponse['data'];
        if (multipassData['accountActivationUrl'] != null) {
          final regex = RegExp(r'^(?:https?:\/\/)?(?:www\.)?([^\/]+)');
          final match = regex.firstMatch(multipassData['accountActivationUrl']);
          final url = match?.group(1) ?? '';

          await ApiService.activateUserAccount(
            multipassData['shopifyCustomerId'],
            url,
            multipassData['password'],
            multipassData['token'],
          );
        }

        if (multipassData['multipassToken'] != null) {
          parsedData['data']['multipass_token'] =
              multipassData['multipassToken'];
        }

        if (multipassData['email'] != null &&
            multipassData['password'] != null) {
          parsedData['data']['email'] = multipassData['email'];
          parsedData['data']['password'] = multipassData['password'];
        }

        SnowplowTrackerService.sendCustomEventToSnowPlow({
          'category': 'sso_login',
          'label': 'checkout_sso_logged_in',
          'action': 'logged_in',
          'property': 'phone_number',
          'value': int.parse(user['phone']),
        });
      } else if (merchantType == 'custom' &&
          parsedData['eventname'] == 'user-login-successful' &&
          parsedData['data']['user_token'] != null &&
          gkToken == null) {
        await cacheInstance.setValue(
            KeyConfig.gkAccessTokenKey, parsedData['data']['user_token']);

        try {
          await ApiService.validateUserToken();
          final response = await ApiService.loginKpUser();
          final responseData = response.data;
          String? phoneNumber;

          if (responseData.phone != null) {
            phoneNumber = responseData.phone;
            await cacheInstance.setValue(
                KeyConfig.gkUserPhone, responseData.phone);
          } else {
            phoneNumber = await cacheInstance.getValue(KeyConfig.gkUserPhone);
          }

          if (responseData.merchantResponse.email != null) {
            final data = {...responseData.toJson(), 'phone': phoneNumber};
            await cacheInstance.setValue(
              KeyConfig.gkVerifiedUserKey,
              jsonEncode(data),
            );
          }

          SnowplowTrackerService.sendCustomEventToSnowPlow({
            'category': 'sso_login',
            'label': 'checkout_sso_logged_in',
            'action': 'logged_in',
            'property': 'phone_number',
            'value': int.parse(phoneNumber!),
          });
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
      }
      widget.onMessage(parsedData);
    } catch (error) {
      widget.onError(ApiService.handleApiError(error));
    }
  }

  String _getInjectJavaScript() {
    return """
(function checkGoKwikSdk() {
  if (typeof gokwikSdk !== 'undefined') {
    gokwikSdk.on('modal_closed', (data) => {
      console.log("modal_closed", data)
      window.postMessage(JSON.stringify({eventname: 'checkout-close', data: data}), "*");
    });
    
    gokwikSdk.on('orderSuccess', (data) => {
      console.log('orderSuccess', data);
      window.postMessage(JSON.stringify({eventname: 'orderSuccess', data: data}), "*");
    });
    
    gokwikSdk.on('openInBrowserTab', (data) => {
      window.postMessage(JSON.stringify({eventname: 'openInBrowserTab', data: data}), "*");
      if (data.url && (data.url.startsWith('http') || data.url.startsWith('https'))) {
        // Handle opening in webview
      } else if (data.url) {
        // Handle checking if webview can handle the URL
      }
    });
  } else {
    setTimeout(checkGoKwikSdk, 500);
    console.log('GoKwik SDK not available, retrying after 500ms');
  }
})();

document.addEventListener("gk-checkout-disable", (event) => {
  window.postMessage(JSON.stringify({eventname: 'gk-checkout-disable', data: event.data}), "*");
  console.log({event});
});
""";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            if (_webviewUrl != null)
              WebViewWidget(controller: _webViewController),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
