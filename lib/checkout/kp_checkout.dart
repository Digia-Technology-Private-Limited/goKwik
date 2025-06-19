import 'package:flutter/material.dart';
import 'package:gokwik/checkout/checkout_shopify.dart';
import 'package:gokwik/config/types.dart';

typedef EventCallback = void Function(Map<String, dynamic> message);
typedef ErrorCallback = void Function(Object error);

class KPCheckout extends StatelessWidget {
  final KPCheckoutProps checkoutData;

  const KPCheckout({
    super.key,
    required this.checkoutData,
  });

  void _handleCheckoutMessage(dynamic message) {
    // Similar to message: { eventname: string; data: any } in React
    if (checkoutData.onEvent != null) {
      checkoutData.onEvent!(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantParams = checkoutData.checkoutData?.merchantParams;

    return CheckoutShopify(
      checkoutId: merchantParams?.merchantCheckoutId ?? '',
      cartId: merchantParams?.cartId ?? '',
      storefrontToken: merchantParams?.storefrontToken ?? '',
      storeId: merchantParams?.storeId ?? '',
      fbpixel: merchantParams?.fbPixel ?? '',
      gaTrackingID: merchantParams?.gaTrackingID ?? '',
      webEngageID: merchantParams?.webEngageID ?? '',
      moEngageID: merchantParams?.moEngageID ?? '',
      sessionId: merchantParams?.sessionId ?? '',
      utmParams: merchantParams?.utmParams ?? {},
      onMessage: _handleCheckoutMessage,
      onError: (error) {
        if (checkoutData.onError != null) {
          checkoutData.onError!(error);
        }
      },
    );
  }
}
