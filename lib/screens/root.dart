import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gokwik/api/snowplow_events.dart';
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
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    sendCustomEvent();
    super.initState();
  }

  void sendCustomEvent() {
    SnowplowTrackerService.sendCustomEventToSnowPlow({
      'category': 'login_modal',
      'action': 'click',
      'label': 'open_login_modal',
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<RootCubit, RootState>(
        listener: (context, state) {
          // if (state.error != null) {
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(content: Text(state.error?.consume())),
          //     );
          //   });
          // }
        },
        builder: (context, state) {
          final cubit = context.read<RootCubit>();
          final isUserLoggedIn = state.isUserLoggedIn;
          final isNewUserState = state.isNewUser;
          final isLoading = state.isLoading;
          final otpSent = state.otpSent;
          final emailOtpSent = state.emailOtpSent;
          // final _isSuccess = state.isSuccess;
          final errorState = state.error;
          // final _multipleEmails = state.multipleEmails;
          final merchantType = state.merchantType;
          // final _notifications = state.notifications;
          final isDevBuild = state.isDevBuild;
          final reqId = state.reqId;

          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: cubit.formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              if (widget.bannerImage != null ||
                                  widget.logo != null)
                                Container(
                                  width: double.infinity,
                                  height:
                                      widget.bannerImage != null ? 300 : 200,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration:
                                      widget.imageContainerStyle?.copyWith(
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
                                  child: widget.bannerImage == null &&
                                          widget.logo != null
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 22),
                                decoration: widget.formContainerStyle,
                                //Todo:Uncomment this part
                                child: isUserLoggedIn && !state.isSuccess
                                    ? const Text(
                                        'You are already logged in',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      )
                                    : isNewUserState
                                        ? merchantType == MerchantType.custom
                                            ? CreateAccount(
                                                titleStyle: widget
                                                    .inputProps?.titleStyle,
                                                isEmailRequired: widget
                                                        .createUserConfig
                                                        ?.isEmailRequired ??
                                                    true,
                                                isNameRequired: widget
                                                        .createUserConfig
                                                        ?.isNameRequired ??
                                                    true,
                                                isGenderRequired: widget
                                                        .createUserConfig
                                                        ?.isGenderRequired ??
                                                    false,
                                                isDobRequired: widget
                                                        .createUserConfig
                                                        ?.isDobRequired ??
                                                    false,
                                                createAccountError: errorState,
                                                inputConfig: widget.inputProps!,
                                                showEmail: widget
                                                        .createUserConfig
                                                        ?.showEmail ??
                                                    true,
                                                showUserName: widget
                                                        .createUserConfig
                                                        ?.showUserName ??
                                                    true,
                                                showDob: widget.createUserConfig
                                                        ?.showDob ??
                                                    false,
                                                showGender: widget
                                                        .createUserConfig
                                                        ?.showGender ??
                                                    false,
                                              )
                                            : ShopifyEmailForm(
                                                initialValue: cubit
                                                    .shopifyEmailController
                                                    .text,
                                                onSubmitEmail: (value) => cubit
                                                    .handleShopifySubmit(value),
                                                isLoading: state.isLoading,
                                                config: widget.inputProps
                                                    ?.shopifyEmailScreen,
                                                loaderConfig:
                                                    widget.loaderConfig,
                                                multipleEmail:
                                                    state.multipleEmails,
                                              )
                                        : emailOtpSent
                                            ? VerifyCodeForm(
                                                otpLabel: cubit
                                                    .shopifyEmailController
                                                    .text,
                                                onEdit: () {
                                                  cubit.handleEmailChange();
                                                },
                                                isLoading: isLoading,
                                                isSuccess: state.isSuccess,
                                                onVerify: (value) { cubit
                                                    .handleEmailOtpVerification(
                                                        value);
                                                },
                                                onResend: () => cubit
                                                    .resendShopifyEmailOtp(),
                                                initialValue: cubit
                                                    .shopifyOtpController,
                                                config: widget.inputProps
                                                    ?.emailOtpVerificationScreen,
                                              )
                                            : otpSent
                                                ? VerifyCodeForm(
                                                    otpLabel:
                                                        '+91 ${cubit.phoneController.text}',
                                                    onEdit: () => cubit
                                                        .handlePhoneChange(),
                                                    config: widget.inputProps
                                                        ?.otpVerificationScreen,
                                                    isLoading: isLoading,
                                                    isSuccess: state.isSuccess,
                                                    onVerify: (value) {
                                                      cubit
                                                          .handleOtpVerification(
                                                        value,
                                                      );
                                                    },
                                                    onResend: () =>
                                                        cubit.resendPhoneOtp(),
                                                    initialValue: cubit
                                                        .otpController,
                                                  )
                                                : Login(
                                                    onSubmit: () =>
                                                        cubit.handleOtpSend(),
                                                    isLoading: state.isLoading,
                                                    formData: LoginForm(
                                                      phone: cubit
                                                          .phoneController.text,
                                                      notifications:
                                                          state.notifications,
                                                    ),
                                                    loaderConfig:
                                                        widget.loaderConfig,
                                                    onFormChanged: (form) {
                                                      cubit.phoneController
                                                          .text = form.phone;
                                                      cubit.updateNotification(
                                                          form.notifications);
                                                    },
                                                    config: widget.inputProps
                                                        ?.phoneAuthScreen,
                                                  ),
                              ),
                              const SizedBox(height: 16),
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
                                      children:
                                          (widget.footerUrls ?? []).map((url) {
                                        return GestureDetector(
                                          onTap: () =>
                                              cubit.linkOpenHandler(url.url),
                                          child: Text(
                                            url.label,
                                            style:
                                                widget.footerHyperlinkStyle ??
                                                    const TextStyle(
                                                      color: Color(0x66000000),
                                                      fontSize: 14,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              // Dev mode debug info
                              if (isDevBuild && reqId.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    border: Border.all(color: Colors.red, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DEBUG MODE',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (reqId.isNotEmpty)
                                        Text(
                                          'Request ID: $reqId',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.enableGuestLogin)
                  Positioned(
                    top: 8,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => cubit.handleSkip(widget.onGuestLoginPress),
                      child: Container(
                        decoration: widget.guestContainerStyle ??
                            BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        child: Text(
                          widget.guestLoginButtonLabel,
                          style: widget.guesLoginTextStyle ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final ButtonStyle? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final InputDecoration? textFieldInputStyle;
  final TextStyle? inputTextStyle;
  final String phoneNumberPlaceholder;
  final String updatesPlaceholder;
  final String submitButtonText;
  final TextStyle? updatesTextStyle;
  final Widget Function(bool, Function(bool))? checkboxComponent;
  final BoxDecoration? checkboxContainerStyle;
  final BoxDecoration? checkboxStyle;
  final EdgeInsets? checkboxContainerPadding;

  const PhoneAuthScreenConfig({
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    this.textFieldInputStyle,
    this.title,
    this.subTitle,
    this.phoneNumberPlaceholder = 'Enter your phone',
    this.updatesPlaceholder = 'Get updates on WhatsApp',
    this.submitButtonText = "Continue",
    this.updatesTextStyle,
    this.checkboxComponent,
    this.checkboxContainerStyle,
    this.checkboxStyle,
    this.inputTextStyle,
    this.checkboxContainerPadding,
  });
}

class OtpVerificationScreenConfig {
  final String title;
  final String? subTitle;
  final String submitButtonText;
  final TextStyle? editStyle;
  final TextStyle? editLabelStyle;

  final ButtonStyle? submitButtonStyleBox;
  final TextStyle? submitButtonTextStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  // final BoxDecoration? pincodeCellStyle;
  // final BoxDecoration? pincodeCellContainerStyle;
  // final InputDecoration? inputStyle;

  final TextStyle? loadingTextStyle;
  // final String? otpPlaceholder;
  // final TextStyle? otpPlaceholderStyle;
  final TextStyle? resendButtonTextStyle;
  final TextStyle? resendTextStyle;
  final TextStyle? cellTextStyle;
  final String? loadingText;

  const OtpVerificationScreenConfig({
    this.title = 'Verify Code',
    this.subTitle = 'Enter the 4-digit code sent to your phone',
    this.submitButtonText = 'Verify',
    this.editStyle,
    // this.phoneTextStyle,
    this.submitButtonStyleBox,
    this.submitButtonTextStyle,
    this.titleStyle,
    this.subTitleStyle,
    // this.pincodeCellStyle,
    // this.pincodeCellContainerStyle,
    // this.inputStyle,
    this.loadingTextStyle,
    // this.otpPlaceholder,
    // this.otpPlaceholderStyle,
    this.editLabelStyle,
    this.resendButtonTextStyle,
    this.resendTextStyle,
    this.cellTextStyle,
    this.loadingText,
  });
}

class EmailOtpVerificationScreenConfig {
  final String? title;
  final String? subTitle;
  final String? submitButtonText;
  final TextStyle? editStyle;
  final TextStyle? emailTextStyle;

  const EmailOtpVerificationScreenConfig({
    this.title = 'Verify Email',
    this.subTitle = 'Enter the 4-digit code sent to your email-address',
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
  final BoxDecoration? inputContainerStyle;
  final InputDecoration? inputStyle;
  final ButtonStyle? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final FormFieldValidator<String>? validator;

  const ShopifyEmailScreenConfig(
      {this.title,
      this.subTitle,
      this.emailPlaceholder,
      this.submitButtonText,
      this.dropdownContainerStyle,
      this.dropdownStyle,
      this.dropdownPlaceholderStyle,
      this.dropdownSelectedTextStyle,
      this.dropdownPlaceholder = 'Select your email',
      this.inputContainerStyle,
      this.inputStyle,
      this.submitButtonStyle,
      this.submitButtonTextStyle,
      this.titleStyle,
      this.subTitleStyle,
      this.validator});
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
  final DateTime? dob;
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
    this.dob,
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
