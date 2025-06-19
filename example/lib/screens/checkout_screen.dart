import 'package:flutter/material.dart';
import 'package:gokwik/checkout/kp_checkout.dart';
import 'package:gokwik/config/types.dart';


class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: KPCheckout(
        checkoutData: KPCheckoutProps(
          checkoutData: CheckoutData(
            merchantParams: MerchantParams(
              cartId: 'Z2NwLWFzaWEtc291dGhlYXN0MTowMUpXUjdIQlg3MjlFSEVCRDUzUE5NTVdFRQ?key=d77972c322e9e3b66596cb432d2b360b',
            ),
          ),
          onEvent: (message) {
            print('Checkout event: $message');
          },
          onError: (error) {
            print('Checkout error: $error');
          },
        ),
      ),
    );
  }
}