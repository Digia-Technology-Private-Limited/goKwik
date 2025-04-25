import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/screens/create_account.dart';
import 'package:gokwik/screens/login.dart';
import 'package:gokwik/screens/shopify.dart';
import 'package:gokwik/screens/verify_code.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Merchant type
  final String? merchantType;

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
  bool _isUserLoggedIn = false;
  String? _merchantType;
  String? _createAccountError;
  bool _isLoading = false;

  bool _notifications = true;
  bool _otpSent = false;
  bool _isNewUser = false;
  bool _emailOtpSent = false;
  bool _isSuccess = false;
  List<MultipleEmail> _multipleEmails = [];
  String? _gender;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _shopifyEmailController = TextEditingController();
  final _shopifyOtpController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _merchantType = widget.merchantType;
    // TODO: Implement event listeners and initial data fetching
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _shopifyEmailController.dispose();
    _shopifyOtpController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _resendPhoneOtp() async {
    try {
      await ApiService.sendVerificationCode(_phoneController.text, true);
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
    } catch (err) {
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  Future<void> _handleOtpSend() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      // await sendVerificationCode(_phoneController.text, _notifications);
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
    } catch (err) {
      setState(() => _isLoading = false);
      // TODO: Show error to user
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  Future<void> _handleEmailOtpVerification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      // final response = await shopifyVerifyEmail(
      //   _shopifyEmailController.text,
      //   _shopifyOtpController.text,
      // );

      // TODO: Handle response and cache user data
      setState(() => _isSuccess = true);
      if (widget.onSuccess != null) {
        // widget.onSuccess!(response.data);
      }
      // TODO: Implement analytics event
    } catch (err) {
      setState(() => _isLoading = false);
      // TODO: Show error to user
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  Future<void> _handleOtpVerification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      // final response = await verifyCode(
      //   _phoneController.text,
      //   _otpController.text,
      // );

      // TODO: Handle response based on merchant type
      setState(() {
        _otpController.clear();
        _isLoading = false;
      });
    } catch (err) {
      setState(() => _isLoading = false);
      // TODO: Show error to user
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  void _handlePhoneChange() {
    setState(() => _otpSent = false);
  }

  void _handleEmailChange() {
    setState(() {
      _emailOtpSent = false;
      _isNewUser = true;
    });
  }

  Future<void> _linkOpenHandler(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      // final response = await createUserApi(
      //   _emailController.text,
      //   _usernameController.text,
      //   _dobController.text,
      //   _gender,
      // );

      setState(() => _isSuccess = true);
      if (widget.onSuccess != null) {
        // widget.onSuccess!(response.merchantResponse);
      }
      // TODO: Implement analytics event
    } catch (err) {
      setState(() {
        _isLoading = false;
        _createAccountError = err.toString();
      });
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  Future<void> _handleShopifySubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      // await shopifySendEmailVerificationCode(_shopifyEmailController.text);
      setState(() {
        _emailOtpSent = true;
        _isNewUser = false;
        _isLoading = false;
      });
    } catch (err) {
      setState(() => _isLoading = false);
      // TODO: Show error to user
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  Future<void> _resendShopifyEmailOtp() async {
    try {
      // await shopifySendEmailVerificationCode(_shopifyEmailController.text);
      setState(() {
        _emailOtpSent = true;
        _isNewUser = false;
      });
    } catch (err) {
      // TODO: Show error to user
      if (widget.onError != null) {
        widget.onError!(err);
      }
    }
  }

  void _handleSkip() {
    if (widget.onGuestLoginPress != null) {
      widget.onGuestLoginPress!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Form(
            key: _formKey,
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
                      child: widget.bannerImage == null && widget.logo != null
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
                            ? _merchantType == 'custom'
                                ? CreateAccount(
                                    isEmailRequired:
                                        widget.createUserConfig.isEmailRequired,
                                    isNameRequired:
                                        widget.createUserConfig.isNameRequired,
                                    isGenderRequired: widget
                                        .createUserConfig.isGenderRequired,
                                    isDobRequired:
                                        widget.createUserConfig.isDobRequired,
                                    onSubmit: (v) => _handleCreateUser(),
                                    createAccountError: _createAccountError,
                                    onError: (error) =>
                                        widget.onError?.call(error),
                                    isLoading: _isLoading,
                                    inputConfig: widget.inputProps!,
                                    showEmail:
                                        widget.createUserConfig.showEmail,
                                    showUserName:
                                        widget.createUserConfig.showUserName,
                                    showDob: widget.createUserConfig.showDob,
                                    showGender:
                                        widget.createUserConfig.showGender,
                                  )
                                : ShopifyEmailForm(
                                    onSubmit: _handleShopifySubmit,
                                    isLoading: _isLoading,
                                    inputConfig: widget.inputProps,
                                    multipleEmail: _multipleEmails,
                                  )
                            : _emailOtpSent
                                ? VerifyCodeForm(
                                    otpLabel: _shopifyEmailController.text,
                                    onEdit: _handleEmailChange,
                                    // inputConfig: widget.inputProps,
                                    isLoading: _isLoading,
                                    isSuccess: _isSuccess,
                                    onVerify: _handleEmailOtpVerification,
                                    onResend: _resendShopifyEmailOtp,
                                    // controller: _shopifyOtpController,
                                    // errors: const {}, // TODO: Implement error handling
                                  )
                                : _otpSent
                                    ? VerifyCodeForm(
                                        otpLabel:
                                            '+91 ${_phoneController.text}',
                                        onEdit: _handlePhoneChange,
                                        // inputConfig: widget.inputProps,
                                        isLoading: _isLoading,
                                        isSuccess: _isSuccess,
                                        onVerify: _handleOtpVerification,
                                        onResend: _resendPhoneOtp,
                                        // controller: _otpController,
                                        //   errors: const {}, // TODO: Implement error handling
                                      )
                                    : Login(
                                        onSubmit: _handleOtpSend,
                                        //  inputConfig: widget.inputProps,
                                        //    phoneController: _phoneController,
                                        //    notifications: _notifications,
                                        // onNotificationsChanged: (value) {
                                        //   setState(
                                        //       () => _notifications = value);
                                        // },
                                        isLoading: _isLoading,
                                        formData: LoginForm(
                                          phone: _phoneController.text,
                                          notifications: _notifications,
                                          otp: _otpController.text,
                                          otpSent: _otpSent,
                                          isNewUser: _isNewUser,
                                          multipleEmail: _multipleEmails,
                                          emailOtpSent: _emailOtpSent,
                                          shopifyEmail:
                                              _shopifyEmailController.text,
                                          shopifyOTP:
                                              _shopifyOtpController.text,
                                          isSuccess: _isSuccess,
                                        ),
                                        onFormChanged: (LoginForm) {},
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
                              onTap: () => _linkOpenHandler(url.url),
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
              top: widget.bannerImage == null && widget.logo == null ? 8 : 0,
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
                  onPressed: _handleSkip,
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
      ),
    );
  }
}

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
    this.phoneAuthScreen,
    this.otpVerificationScreen,
    this.emailOtpVerificationScreen,
    this.shopifyEmailScreen,
    this.createUserScreen,
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