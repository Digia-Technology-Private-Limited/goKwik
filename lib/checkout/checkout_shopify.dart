// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/sdk_config.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/flow_result.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutShopify extends StatefulWidget {
  final Function(FlowResult)? onSuccess;
  final Function(FlowResult)? onError;
  final Function(dynamic)? onMessage;
  final String? checkoutId;
  final String? storefrontToken;
  final String? cartId;
  final String? storeId;
  final String? fbpixel;
  final String? gaTrackingID;
  final String? webEngageID;
  final String? moEngageID;
  final String? sessionId;
  final Map<String, dynamic>? utmParams;

  const CheckoutShopify({
    Key? key,
    this.checkoutId,
    this.storefrontToken = '',
    this.cartId,
    this.onMessage,
    this.onSuccess,
    this.onError,
    this.storeId = '',
    this.fbpixel = '',
    this.gaTrackingID = '',
    this.webEngageID = '',
    this.moEngageID = '',
    this.sessionId = '',
    this.utmParams = const {},
  }) : super(key: key);

  @override
  _CheckoutShopifyState createState() => _CheckoutShopifyState();
}

class _CheckoutShopifyState extends State<CheckoutShopify> {
  String webUrl = '';
  late final WebViewController _webViewController;
  late final WebViewCookieManager _cookieManager;
  bool checkoutLoaded = false;
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
window.addEventListener("gokwikLoaded", () => {
  Flutter.postMessage(JSON.stringify({ type: 'gokwikLoaded', data: event.detail }));
    setTimeout(() => {
         console.log("Gokwik SDK Loaded");
        triggerGokwikCustomCheckout();
    }, 1000); // 1 second delay
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
          debugPrint("MESSAGE RECEIVED $message");
          handleMessageAsync(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            final canGoBack = await _webViewController.canGoBack();
            // final canGoForward = await _webViewController.canGoForward();

            _sendNavigationEvent('pageStarted', {
              'url': url,
              'isLoading': true,
              'canGoBack': canGoBack,
            });
          },
          onPageFinished: (url) async {
            await _webViewController.runJavaScript(injectedJavaScript);
            final canGoBack = await _webViewController.canGoBack();
            final canGoForward = await _webViewController.canGoForward();

            _sendNavigationEvent('pageFinished', {
              'url': url,
              'isLoading': false,
              'canGoBack': canGoBack,
              'canGoForward': canGoForward,
            });
          },
          onWebResourceError: (error) {
            // debugPrint('Web resource error: $error');
          },
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Allow standard web links
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }

            // Handle UPI app links
            try {
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.platformDefault,
              );

              if (!launched) {
                // _showAppMissingSnackbar(
                //     context, uri); // Show snackbar instead of dialog
              } else {
                // Send navigation event for navigation request
                _sendNavigationEvent('navigationRequest', {
                  'url': request.url,
                  'isMainFrame': request.isMainFrame,
                });
              }

              return NavigationDecision.prevent;
            } catch (e) {
              // _showAppMissingSnackbar(context, uri);
              return NavigationDecision.prevent;
            }
          },
          onUrlChange: (UrlChange change) {
            // Send navigation event for URL changes
            _sendNavigationEvent('urlChange', {
              'url': change.url,
              'previousUrl': webUrl,
            });
          },
        ),
      );
  }

  // void _showAppMissingSnackbar(BuildContext context, Uri uri) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Please Install a UPI app or use web payment'),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }

  Future<void> initiateCheckout() async {
    final environment =
        await cacheInstance.getValue(KeyConfig.gkEnvironmentKey);

    final merchantType =
        await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
    final sdkConfig = SdkConfig.fromEnvironment(environment!);

    // GET LOGGED IN USER EMAIL HERE
    final verifiedUserData =
        await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);

    String? userEmail;

    if (verifiedUserData != null) {
      final user = jsonDecode(verifiedUserData);
      userEmail = user?['email'];
    }

    debugPrint("MERCHANT TYPE:: $merchantType");

    if (merchantType == 'custom') {
      final merchantId =
          await cacheInstance.getValue(KeyConfig.gkMerchantIdKey);
      final token = await cacheInstance.getValue(KeyConfig.gkAccessTokenKey);

      String appplatform = Platform.operatingSystem.toLowerCase();
      String appversion = (await PackageInfo.fromPlatform()).version;
      String appsource = '${Platform.operatingSystem.toLowerCase()}-app';

      String webviewUrl =
          '${sdkConfig.checkoutUrl['custom']}?m_id=$merchantId&checkout_id=${widget.checkoutId}&appplatform=$appplatform&appversion=$appversion&appsource=$appsource';

      if (userEmail != null && userEmail.isNotEmpty) {
        webviewUrl += '&kp_email=$userEmail';
      }

      if (token != null && token.isNotEmpty) {
        webviewUrl += '&gk_token=$token';
      }

      setState(() {
        webUrl = webviewUrl;
      });
      _webViewController.loadRequest(Uri.parse(webviewUrl));
      return;
    }

    final merchantInfo = {
      'mid': await cacheInstance.getValue(KeyConfig.gkMerchantIdKey),
      'environment': environment,
      'token': await cacheInstance.getValue(KeyConfig.checkoutAccessTokenKey),
      'shopDomain': await cacheInstance.getValue(KeyConfig.gkMerchantUrlKey),
    };

    final storeInfo = {
      'type': 'merchantInfo',
      'source': 'app',
      'platform': Platform.operatingSystem.toLowerCase(),
      'appFlow': 'true',
      'blockExternalEvents': true,
      'mid': merchantInfo['mid'],
      'environment': merchantInfo['environment'],
      'storeId': widget.storeId ?? '',
      'fbpixel': widget.fbpixel ?? '',
      'gaTrackingID': widget.gaTrackingID ?? '',
      'webEngageID': widget.webEngageID ?? '',
      'moEngageID': widget.moEngageID ?? '',
      'sessionID': widget.sessionId ?? '',
      'utmParams': widget.utmParams ?? {},
      'storeData': {
        'cartId': 'gid://shopify/Cart/${widget.cartId}',
        'storefrontAccessToken': widget.storefrontToken ?? '',
        'shopDomain': merchantInfo['shopDomain'],
      },
    };

    final encodedStoreInfo = base64Encode(utf8.encode(jsonEncode(storeInfo)));

    String checkoutBaseUrl =
        SdkConfig.fromEnvironment(environment).checkoutUrl['shopify']!;

    String url = '$checkoutBaseUrl$encodedStoreInfo';

    if (merchantInfo['token'] != null) {
      final tokenPayload = base64Encode(
          utf8.encode(jsonEncode({'coreToken': merchantInfo['token']})));
      url += '&gk_token=$tokenPayload';
    }

    if (userEmail != null && userEmail.isNotEmpty) {
      final encodedEmail = base64Encode(utf8.encode(userEmail));
      url += '&kp_email=$encodedEmail';
    }
    await _webViewController.loadRequest(Uri.parse(url));
    setState(() {
      webUrl = url;
    });
  }

  void _sendNavigationEvent(
      String navigationType, Map<String, dynamic> navigationData) {
    try {
      final navigationEvent = {
        'eventname': 'navigation',
        'type': 'navigation',
        'data': {
          'type': navigationType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...navigationData,
        }
      };

      // Send the navigation event through the onMessage callback
      widget.onMessage?.call(navigationEvent);

      if (kDebugMode) {}
    } catch (error) {
      if (kDebugMode) {}
    }
  }

  Future<void> handleMessageAsync(String message) async {
    try {
      final decoded = jsonDecode(message.toString());
      final merchantType =
          await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
      if (merchantType == 'custom') {
        if (decoded['eventname'] == 'checkout-ready') {
          if (!checkoutLoaded) {
            checkoutLoaded = true;
          }
          setState(() {});
        }
        widget.onMessage?.call(decoded);
      } else {
        // final event = decoded['type'];
        // final data = decoded['data'];
        // debugPrint("EVENT RECEIVED $event");
        // debugPrint("DATA RECEIVED $data");
        if (decoded['type'] == 'gokwikLoaded') {
          if (!checkoutLoaded) {
            checkoutLoaded = true;
          }
          setState(() {});
        }
        widget.onMessage?.call(decoded);
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

  Future<void> _handleBackButton() async {
    final canGoBack = await _webViewController.canGoBack();
    final url = await _webViewController.currentUrl();
    final isHandled = await widget.onMessage?.call({
      'type': 'hardwareBackPress',
      'data': {
        'canGoBack': canGoBack,
        'url': url,
      }
    });

    if (isHandled == true) return;
    if (canGoBack) {
      // If WebView can go back, navigate back in WebView
      await _webViewController.goBack();
    } else {
      await _webViewController.runJavaScript('''
        document.dispatchEvent(new MessageEvent('message', {
          data: JSON.stringify({ action: 'hardwareBackPress' })
        }));
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: !checkoutLoaded
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.black,
              ))
            : WebViewWidget(controller: _webViewController),
      );
    }
    return PopScope(
      canPop: false, // Always handle back button manually
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackButton();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: !checkoutLoaded
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.black,
              ))
            : WebViewWidget(controller: _webViewController),
      ),
    );
  }
}
