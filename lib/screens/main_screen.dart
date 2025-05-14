import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/flow_result.dart';
import 'package:gokwik/screens/cubit/root_cubit.dart';
import 'package:gokwik/screens/root.dart';

class GoKwikLoginAndSignUpFlow extends StatelessWidget {
  // Images
  final ImageProvider? bannerImage;
  final ImageProvider? logo;

  // Style props
  final BoxDecoration? bannerImageStyle;
  final BoxDecoration? logoStyle;
  final BoxDecoration? containerStyle;
  final BoxDecoration? formContainerStyle;
  final BoxDecoration? imageContainerStyle;

  // Loader customization props
  final LoadingConfig? loaderConfig;

  // URLs
  final String? footerText;
  final List<FooterUrl>? footerUrls;
  final TextStyle? footerTextStyle;
  final TextStyle? footerHyperlinkStyle;

  // Callbacks
  final Function(FlowResult)? onSuccess;
  final Function(FlowResult)? onError;

  // For new user
  final CreateUserConfig? createUserConfig;

  // Guest user
  final bool enableGuestLogin;
  final String guestLoginButtonLabel;
  final VoidCallback? onGuestLoginPress;
  final BoxDecoration? guestContainerStyle;
  final TextStyle? guesLoginTextStyle;

  // Input config
  final TextInputConfig? inputProps;

  // Merchant type
  final MerchantType? merchantType;
  const GoKwikLoginAndSignUpFlow({
    super.key,
    this.bannerImage,
    this.logo,
    this.bannerImageStyle,
    this.logoStyle,
    this.containerStyle,
    this.formContainerStyle,
    this.imageContainerStyle,
    this.loaderConfig,
    this.footerText,
    this.footerUrls,
    this.footerTextStyle,
    this.footerHyperlinkStyle,
    this.onSuccess,
    this.onError,
    this.createUserConfig,
    this.enableGuestLogin = false,
    this.guestLoginButtonLabel = 'Skip',
    this.onGuestLoginPress,
    this.guestContainerStyle,
    this.inputProps,
    this.merchantType,
    this.guesLoginTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RootCubit(
        onSuccessData: onSuccess,
        onErrorData: onError,
      ),
      child: RootScreen(
        bannerImage: bannerImage,
        logo: logo,
        bannerImageStyle: bannerImageStyle,
        logoStyle: logoStyle,
        containerStyle: containerStyle,
        formContainerStyle: formContainerStyle,
        imageContainerStyle: imageContainerStyle,
        loaderConfig: loaderConfig,
        footerText: footerText,
        footerUrls: footerUrls,
        footerTextStyle: footerTextStyle,
        footerHyperlinkStyle: footerHyperlinkStyle,
        guesLoginTextStyle: guesLoginTextStyle,
        createUserConfig: createUserConfig,
        enableGuestLogin: enableGuestLogin,
        guestLoginButtonLabel: guestLoginButtonLabel,
        onGuestLoginPress: onGuestLoginPress,
        guestContainerStyle: guestContainerStyle,
        inputProps: inputProps,
        merchantType: merchantType ?? MerchantType.shopify,
      ),
    );
  }
}
