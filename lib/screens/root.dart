import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/screens/create_account.dart';
import 'package:gokwik/screens/cubit/root_cubit.dart';
import 'package:gokwik/screens/cubit/root_model.dart';
import 'package:gokwik/screens/login.dart';
import 'package:gokwik/screens/shopify.dart';
import 'package:gokwik/screens/verify_code.dart';

class RootScreen extends StatefulWidget {
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
  final Function(dynamic)? onSuccess;
  final Function(dynamic)? onError;

  // For new user
  final CreateUserConfig createUserConfig;

  // Guest user
  final bool enableGuestLogin;
  final String guestLoginButtonLabel;
  final VoidCallback? onGuestLoginPress;
  final BoxDecoration? guestContainerStyle;

  // Input config
  final TextInputConfig? inputProps;

  //Data

  // Merchant type
  final MerchantType? merchantType;

  const RootScreen({
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
    required this.createUserConfig,
    this.enableGuestLogin = false,
    this.guestLoginButtonLabel = 'Skip',
    this.onGuestLoginPress,
    this.guestContainerStyle,
    this.inputProps,
    this.merchantType,
  });

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RootCubit, RootState>(
        builder: (context, state) {
          final cubit = context.read<RootCubit>();
          final _isUserLoggedIn = state.isUserLoggedIn;
          final _isNewUser = state.isNewUser;
          // final _isLoading = state.isLoading;
          final _otpSent = state.otpSent;
          final _emailOtpSent = state.emailOtpSent;
          // final _isSuccess = state.isSuccess;
          final _createAccountError = state.createAccountError;
          // final _multipleEmails = state.multipleEmails;
          final _merchantType = state.merchantType;
          // final _notifications = state.notifications;
          return Stack(
            children: [
              Form(
                key: cubit.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      if (widget.bannerImage != null || widget.logo != null)
                        Container(
                          width: double.infinity,
                          height: widget.bannerImage != null ? 300 : 200,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: widget.imageContainerStyle?.copyWith(
                                image: widget.bannerImage != null
                                    ? DecorationImage(
                                        image: widget.bannerImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ) ??
                              (widget.bannerImage != null
                                  ? BoxDecoration(
                                      image: DecorationImage(
                                        image: widget.bannerImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : null),
                          child:
                              widget.bannerImage == null && widget.logo != null
                                  ? Center(
                                      child: Image(
                                        image: widget.logo!,
                                        height: 80,
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : null,
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: widget.formContainerStyle,
                        child: _isUserLoggedIn
                            ? const Text(
                                'You are already logged in',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              )
                            : _isNewUser
                                ? _merchantType == MerchantType.custom
                                    ? CreateAccount(
                                        titleStyle:
                                            widget.inputProps?.titleStyle,
                                        isEmailRequired: widget
                                            .createUserConfig.isEmailRequired,
                                        isNameRequired: widget
                                            .createUserConfig.isNameRequired,
                                        isGenderRequired: widget
                                            .createUserConfig.isGenderRequired,
                                        isDobRequired: widget
                                            .createUserConfig.isDobRequired,
                                        createAccountError: _createAccountError,
                                        inputConfig: widget.inputProps!,
                                        showEmail:
                                            widget.createUserConfig.showEmail,
                                        showUserName: widget
                                            .createUserConfig.showUserName,
                                        showDob:
                                            widget.createUserConfig.showDob,
                                        showGender:
                                            widget.createUserConfig.showGender,
                                      )
                                    : ShopifyEmailForm(
                                        initialValue:
                                            cubit.shopifyEmailController.text,
                                        onSubmit: () =>
                                            cubit.handleShopifySubmit(
                                          cubit.shopifyEmailController.text,
                                        ),
                                        isLoading: state.isLoading,
                                        inputConfig: widget.inputProps,
                                        multipleEmail: state.multipleEmails,
                                      )
                                : _emailOtpSent
                                    ? VerifyCodeForm(
                                        otpLabel: widget
                                                .inputProps
                                                ?.otpVerificationScreen
                                                ?.title ??
                                            '',
                                        // onEdit: () => cubit.handleShopifySubmit(
                                        //     _emailController.text, _formKey),
                                        onEdit: () {},
                                        isLoading: state.isLoading,
                                        isSuccess: state.isSuccess,
                                        onVerify: (value) => cubit
                                            .handleEmailOtpVerification(value),
                                        onResend: () =>
                                            cubit.resendShopifyEmailOtp(),
                                        initialValue:
                                            cubit.shopifyOtpController.text,
                                      )
                                    : _otpSent
                                        ? VerifyCodeForm(
                                            otpLabel:
                                                '+91 ${cubit.phoneController.text}',
                                            onEdit: () =>
                                                cubit.handlePhoneChange(),
                                            // inputConfig: widget.inputProps,
                                            isLoading: state.isLoading,
                                            isSuccess: state.isSuccess,
                                            onVerify: (value) =>
                                                cubit.handleOtpVerification(
                                              value,
                                            ),
                                            onResend: () =>
                                                cubit.resendPhoneOtp(),
                                            initialValue:
                                                cubit.otpController.text,
                                          )
                                        : Login(
                                            onSubmit: () =>
                                                cubit.handleOtpSend(),
                                            isLoading: state.isLoading,
                                            formData: LoginForm(
                                              phone: cubit.phoneController.text,
                                              notifications:
                                                  state.notifications,
                                              // otp: _otpController.text,
                                              // otpSent: _otpSent,
                                              // isNewUser: _isNewUser,
                                              // multipleEmail: _multipleEmails,
                                              // emailOtpSent: _emailOtpSent,
                                              // shopifyEmail:
                                              //     _shopifyEmailController.text,
                                              // shopifyOTP:
                                              //     _shopifyOtpController.text,
                                              // isSuccess: _isSuccess,
                                            ),
                                            onFormChanged: (form) {
                                              cubit.phoneController.text =
                                                  form.phone;
                                              cubit.updateNotification(
                                                  form.notifications);
                                            },
                                          ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            if (widget.footerText != null)
                              Text(
                                widget.footerText!,
                                style: widget.footerTextStyle ??
                                    const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: (widget.footerUrls ?? []).map((url) {
                                return GestureDetector(
                                  onTap: () => cubit.linkOpenHandler(url.url),
                                  child: Text(
                                    url.label,
                                    style: widget.footerHyperlinkStyle ??
                                        const TextStyle(
                                          color: Color(0x66000000),
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.enableGuestLogin)
                Positioned(
                  top:
                      widget.bannerImage == null && widget.logo == null ? 8 : 0,
                  right: 20,
                  child: Container(
                    decoration: widget.guestContainerStyle?.copyWith(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ) ??
                        BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    child: TextButton(
                      onPressed: () =>
                          cubit.handleSkip(widget.onGuestLoginPress),
                      child: Text(
                        widget.guestLoginButtonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// class CreateAccountForm {
//   final String email;
//   final String name;
//   final String dob;
//   final String gender;

//   CreateAccountForm(
//       {required this.email,
//       required this.name,
//       required this.dob,
//       required this.gender});
// }
// Supporting classes and enums

class CreateUserConfig {
  final bool isEmailRequired;
  final bool isNameRequired;
  final bool isGenderRequired;
  final bool isDobRequired;

  final bool showEmail;
  final bool showUserName;
  final bool showGender;
  final bool showDob;

  const CreateUserConfig({
    required this.isEmailRequired,
    required this.isNameRequired,
    this.isGenderRequired = false,
    this.isDobRequired = false,
    required this.showEmail,
    required this.showUserName,
    this.showDob = false,
    this.showGender = false,
  });
}

class TextInputConfig {
  final BoxDecoration? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final BoxDecoration? inputContainerStyle;
  final InputDecoration? inputStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final String? otpPlaceholder;
  final TextStyle? otpPlaceholderStyle;
  final TextStyle? cellTextStyle;
  final BoxDecoration? pincodeCellStyle;
  final BoxDecoration? pincodeCellContainerStyle;
  final TextStyle? resendTextStyle;
  final TextStyle? resendButtonTextStyle;

  final PhoneAuthScreenConfig? phoneAuthScreen;
  final OtpVerificationScreenConfig? otpVerificationScreen;
  final EmailOtpVerificationScreenConfig? emailOtpVerificationScreen;
  final ShopifyEmailScreenConfig? shopifyEmailScreen;
  final CreateUserScreenConfig? createUserScreen;

  const TextInputConfig({
    this.phoneAuthScreen,
    this.otpVerificationScreen,
    this.emailOtpVerificationScreen,
    this.shopifyEmailScreen,
    this.createUserScreen,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    this.inputContainerStyle,
    this.inputStyle,
    this.titleStyle,
    this.subTitleStyle,
    this.otpPlaceholder,
    this.otpPlaceholderStyle,
    this.cellTextStyle,
    this.pincodeCellStyle,
    this.pincodeCellContainerStyle,
    this.resendTextStyle,
    this.resendButtonTextStyle,
  });
}

class PhoneAuthScreenConfig {
  final String? title;
  final String? subTitle;
  final String? phoneNumberPlaceholder;
  final String? updatesPlaceholder;
  final String? submitButtonText;
  final TextStyle? updatesTextStyle;
  final Widget Function(bool, Function(bool))? checkboxComponent;
  final BoxDecoration? checkboxContainerStyle;
  final BoxDecoration? checkboxStyle;
  final BoxDecoration? checkedStyle;

  const PhoneAuthScreenConfig({
    this.title,
    this.subTitle,
    this.phoneNumberPlaceholder,
    this.updatesPlaceholder,
    this.submitButtonText,
    this.updatesTextStyle,
    this.checkboxComponent,
    this.checkboxContainerStyle,
    this.checkboxStyle,
    this.checkedStyle,
  });
}

class OtpVerificationScreenConfig {
  final String? title;
  final String? subTitle;
  final String? submitButtonText;
  final TextStyle? editStyle;
  final TextStyle? phoneTextStyle;

  const OtpVerificationScreenConfig({
    this.title,
    this.subTitle,
    this.submitButtonText,
    this.editStyle,
    this.phoneTextStyle,
  });
}

class EmailOtpVerificationScreenConfig {
  final String? title;
  final String? subTitle;
  final String? submitButtonText;
  final TextStyle? editStyle;
  final TextStyle? emailTextStyle;

  const EmailOtpVerificationScreenConfig({
    this.title,
    this.subTitle,
    this.submitButtonText,
    this.editStyle,
    this.emailTextStyle,
  });
}

class ShopifyEmailScreenConfig {
  final String? title;
  final String? subTitle;
  final String? emailPlaceholder;
  final String? submitButtonText;
  final BoxDecoration? dropdownContainerStyle;
  final BoxDecoration? dropdownStyle;
  final TextStyle? dropdownPlaceholderStyle;
  final TextStyle? dropdownSelectedTextStyle;
  final String? dropdownPlaceholder;

  const ShopifyEmailScreenConfig({
    this.title,
    this.subTitle,
    this.emailPlaceholder,
    this.submitButtonText,
    this.dropdownContainerStyle,
    this.dropdownStyle,
    this.dropdownPlaceholderStyle,
    this.dropdownSelectedTextStyle,
    this.dropdownPlaceholder,
  });
}

class CreateUserScreenConfig {
  final String? title;
  final String? subTitle;
  final String? emailPlaceholder;
  final String? namePlaceholder;
  final String? dobPlaceholder;
  final String? genderPlaceholder;
  final String? submitButtonText;
  final String? dobFormat;
  final BoxDecoration? radioContainerStyle;
  final BoxDecoration? radioCircleStyle;
  final BoxDecoration? radioSelectedStyle;
  final TextStyle? radioTextStyle;
  final TextStyle? genderTitleStyle;
  final String? genderTitle;

  const CreateUserScreenConfig({
    this.title,
    this.subTitle,
    this.emailPlaceholder,
    this.namePlaceholder,
    this.dobPlaceholder,
    this.genderPlaceholder,
    this.submitButtonText,
    this.dobFormat,
    this.radioContainerStyle,
    this.radioCircleStyle,
    this.radioSelectedStyle,
    this.radioTextStyle,
    this.genderTitleStyle,
    this.genderTitle,
  });
}

class LoadingConfig {
  final String? loadingText;
  final TextStyle? loadingTextStyle;

  const LoadingConfig({
    this.loadingText,
    this.loadingTextStyle,
  });
}

class FooterUrl {
  final String label;
  final String url;

  const FooterUrl({
    required this.label,
    required this.url,
  });
}

class MultipleEmail {
  final String label;
  final String value;

  const MultipleEmail({
    required this.label,
    required this.value,
  });
}

// Form widgets would be implemented separately (LoginForm, VerifyCodeForm, CreateAccountForm, ShopifyEmailForm)