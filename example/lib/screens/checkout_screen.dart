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
              // cartId: 'hWN11qIpsH360MZu1SS5t2QO?key=d9e7d5fb318b9c9d3fa45ca704a19d6e',
              merchantCheckoutId: "ckout_17697562172048139"
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