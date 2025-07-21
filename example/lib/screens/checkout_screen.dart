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
              cartId: 'Z2NwLWFzaWEtc291dGhlYXN0MTowMUswOTM4WkNQQVoxOVpGNjRTODlXVDQzRw?key=45c58e4b1c2166ab125e708250555c9b',
            ),
          ),
          onEvent: (message) {
            if(message['type'] == "modal_closed"){
              Navigator.pop(context);
            }
          },
          onError: (error) {
            print('Checkout error: $error');
          },
        ),
      ),
    );
  }
}