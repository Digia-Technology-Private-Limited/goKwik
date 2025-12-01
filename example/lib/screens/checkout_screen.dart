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
              cartId: 'hWN1OwuB0eAycO98kw8pqwOw?key=f4a42b296fa365e142e6e1fd688ec0d5',
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