import 'package:flutter/material.dart';
import 'package:gokwik/screens/main_screen.dart';
import 'package:gokwik/screens/root.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: GoKwikLoginAndSignUpFlow(
          onSuccess: (data) {
            print("onSuccess ${data}");

            if (data.data != null) {
              Navigator.pop(context);
            }
          },
          onError: (error) {
            print("onError::: APPLICATION SIDE ${error.error}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.error)),
            );
          },
          enableGuestLogin: true,
          guestLoginButtonLabel: 'Skip',
          onGuestLoginPress: () {
            print('Guest login pressed');
            Navigator.pop(context);
          },
          inputProps: const TextInputConfig(
              phoneAuthScreen: PhoneAuthScreenConfig(
                title: "HELLLO",
                subTitle: "SUBTITLE",
                phoneNumberPlaceholder: "Enter your phone",
                submitButtonText: "Submit",
                updatesPlaceholder: "Receive updates on WhatsApp",
                updatesTextStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              otpVerificationScreen: OtpVerificationScreenConfig(
                title: "Enter the code sent to your phone",
                subTitle: "Submit",
              )),
          footerText: 'By continuing, you agree to our',
          // footerHyperlinkStyle: const TextStyle(
          //   color: Colors.black,
          //   fontSize: 22,
          // ),
          // footerTextStyle: const TextStyle(
          //   color: Colors.black,
          //   fontSize: 22,
          // ),
          footerUrls: const [
            FooterUrl(
              label: 'Terms of Service',
              url: 'https://www.google.com/',
            ),
            FooterUrl(label: 'Privacy Policy', url: 'https://www.google.com/'),
          ],
          bannerImage: const NetworkImage(
            "https://images.ctfassets.net/ihx0a8chifpc/GTlzd4xkx4LmWsG1Kw1BB/ad1834111245e6ee1da4372f1eb5876c/placeholder.com-1280x720.png?w=1920&q=60&fm=webp",
          ),
          logo: const NetworkImage(
            "https://www.beautylabinternational.com/wp-content/uploads/2020/03/Hero-Banner-Placeholder-Light-1024x480-1.png",
          ),
        ),
      ),
    );
  }
}
