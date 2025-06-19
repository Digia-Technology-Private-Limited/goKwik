import 'package:flutter/material.dart';
import 'package:gokwik/screens/main_screen.dart';
import 'package:gokwik/screens/root.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

           //GoKwikClient.instance.logout();

            if (data.data['email'] != null) {
              // add 5 seconds of delay
              Future.delayed(const Duration(seconds: 5), () {
                Navigator.pop(context);
              });
            }
          },
          onError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.error)),
            );
          },
          enableGuestLogin: true,
          guestLoginButtonLabel: 'Skip',
          onGuestLoginPress: () {
            Navigator.pop(context);
          },
          inputProps: const TextInputConfig(
            phoneAuthScreen: PhoneAuthScreenConfig(
              title: "Login to your account",
              subTitle: "Enter your phone number",
              phoneNumberPlaceholder: "Enter your phone number",
              submitButtonText: "Submit",
              updatesPlaceholder: "Receive updates on WhatsApp",
              updatesTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            otpVerificationScreen: OtpVerificationScreenConfig(
              title: "Verify your phone number",
              subTitle: "Enter the 4 digit code sent to your phone",
              submitButtonText: "Verify",
            ),
            createUserScreen: CreateUserScreenConfig(
              title: "Enter your details",
              subTitle: "Enter your details to continue",
              emailPlaceholder: "Enter your email-address",
              namePlaceholder: "Enter your username"
            ),
            emailOtpVerificationScreen: EmailOtpVerificationScreenConfig(
              title: "Verify your email",
              subTitle: "Enter the 4 digit code sent to your email",
              submitButtonText: "Verify",
            ),
            shopifyEmailScreen: ShopifyEmailScreenConfig(
              title: "Enter your email",
              subTitle: "Enter your email",
              submitButtonText: "Submit",
            ),
          ),
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
