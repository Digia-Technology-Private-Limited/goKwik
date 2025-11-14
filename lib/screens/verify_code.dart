import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gokwik/screens/root.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:sms_consent_for_otp_autofill/sms_consent_for_otp_autofill.dart';
import 'package:smart_auth/smart_auth.dart';

class VerifyCodeForm extends StatefulWidget {
  final String otpLabel;
  final VoidCallback onResend;
  final VoidCallback onEdit;
  final ValueChanged<String> onVerify;
  final String? Function(String?)? validator;
  final TextEditingController initialValue;
  final dynamic
      config; // Can be OtpVerificationScreenConfig or EmailOtpVerificationScreenConfig
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const VerifyCodeForm({
    super.key,
    required this.otpLabel,
    required this.onResend,
    required this.onEdit,
    required this.onVerify,
    this.config,
    this.validator,
    required this.initialValue,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  @override
  State<VerifyCodeForm> createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  final int _cellCount = 4;
  final int _maxAttempts = 5;
  int _seconds = 30;
  bool _isResendDisabled = true;
  int _attempts = 0;
  final List<FocusNode> _focusNodes = [];
  // final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isVerifying = false; // Add flag to prevent duplicate API calls

  final scaffoldKey = GlobalKey();
  // late OTPTextEditController controller;
  // late OTPInteractor _otpInteractor;

  // final pinputController = TextEditingController();
  final smartAuth = SmartAuth.instance;

  // Helper methods to safely access config properties
  String get configTitle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).title;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).title ??
          "Verify Code";
    }
    return "Verify Code";
  }

  TextStyle? get configTitleStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).titleStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).titleTextStyle;
    }
    return null;
  }

  String? get configSubTitle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).subTitle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).subTitle;
    }
    return null;
  }

  TextStyle? get configSubTitleStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).subTitleStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).subTitleTextStyle;
    }
    return null;
  }

  TextStyle? get configEditLabelStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).editLabelStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).editLabelStyle;
    }
    return null;
  }

  TextStyle? get configEditStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).editStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).editStyle;
    }
    return null;
  }

  TextStyle? get configCellTextStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).cellTextStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).cellTextStyle;
    }
    return null;
  }

  TextStyle? get configResendTextStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).resendTextStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).resendTextStyle;
    }
    return null;
  }

  TextStyle? get configResendButtonTextStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig)
          .resendButtonTextStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig)
          .resendButtonTextStyle;
    }
    return null;
  }

  ButtonStyle? get configSubmitButtonStyleBox {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig)
          .submitButtonStyleBox;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig)
          .submitButtonStyle;
    }
    return null;
  }

  String get configLoadingText {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).loadingText ??
          'Signing you in...';
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).loadingText ??
          'Signing you in...';
    }
    return 'Signing you in...';
  }

  TextStyle? get configLoadingTextStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).loadingTextStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig).loadingTextStyle;
    }
    return null;
  }

  String get configSubmitButtonText {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig).submitButtonText;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig)
              .submitButtonText ??
          'Verify';
    }
    return 'Verify';
  }

  TextStyle? get configSubmitButtonTextStyle {
    if (widget.config is OtpVerificationScreenConfig) {
      return (widget.config as OtpVerificationScreenConfig)
          .submitButtonTextStyle;
    } else if (widget.config is EmailOtpVerificationScreenConfig) {
      return (widget.config as EmailOtpVerificationScreenConfig)
          .submitButtonTextStyle;
    }
    return null;
  }

  Future<void> _startUserConsent() async {
    try {
      final res =
          await smartAuth.getSmsWithUserConsentApi(); // ← consent
      if (!mounted) return;

      if (res.hasData) {
        final code = res.requireData.code;
        final otp = code ??
            RegExp(r'\b(\d{4})\b').firstMatch(code ?? '')?.group(1);
        if (otp != null && otp.isNotEmpty) {
          widget.initialValue.text = otp;
          widget.initialValue.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.initialValue.text.length),
          );
          _validateOtp();
        }
      }
    } catch (_) {
      // allow manual entry
    }
  }

  @override
  void initState() {
    super.initState();
    // Set initial value if provided
    _startTimer();
    _startUserConsent();
    // controller = OTPTextEditController(
    //   codeLength: 4,
    //   //ignore: avoid_print
    //   onCodeReceive: (code) =>
    //       debugPrint('Your Application receive code - $code'),
    //   otpInteractor: _otpInteractor,
    // )..startListenUserConsent(
    //     (code) {
    //       final exp = RegExp(r'(\d{4})');

    //       final otp = exp.stringMatch(code ?? '') ?? '';
    //       widget.initialValue?.text = otp;
    //       widget.initialValue?.selection = TextSelection.fromPosition(
    //         TextPosition(offset: widget.initialValue?.text.length),
    //       );

    //       return otp;
    //     },
    //     strategies: [],
    //   );

    // smsConsentForOtpAutoFill = SmsConsentForOtpAutofill(phoneNumberListener: (number) {
    //   phoneNumber = number;
    //   debugPrint("number...................${number}");
    // }, smsListener: (code) {
    //   debugPrint("otp...................${code}");

    //   final exp = RegExp(r'(\d{4})');

    //   final otp = exp.stringMatch(code ?? '') ?? '';
    //   widget.initialValue?.text = otp;
    //   widget.initialValue?.selection = TextSelection.fromPosition(
    //     TextPosition(offset: widget.initialValue?.text.length),
    //   );

    //   return otp;
    // });

    // _initInteractor();
  }

  @override
  void didUpdateWidget(VerifyCodeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error) {
      setState(() {
        _errorText = widget.error;
      });
    }
    // Reset verification flag when loading state changes (for retry scenarios)
    if (widget.isLoading != oldWidget.isLoading && !widget.isLoading) {
      setState(() {
        _isVerifying = false;
      });
    }
    // Update widget.initialValue? text when initialValue changes
    if (widget.initialValue != oldWidget.initialValue) {
      if (widget.initialValue.text.isNotEmpty) {
    widget.initialValue.text = widget.initialValue.text;
        widget.initialValue.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.initialValue.text.length),
        );
      } else {
        widget.initialValue.clear();
      }
      // Validate the new OTP value
      _validateOtp();
    }
  }

  // Future<void> _initInteractor() async {
  //   // _otpInteractor = OTPInteractor();
  //   // await _otpInteractor.getAppSignature();
  //   debugPrint("CALLLING>>>......");
  //   // smsConsentForOtpAutoFill.requestSms();
  // }

  @override
  void dispose() {
    // controller.stopListen();
    smartAuth.removeUserConsentApiListener();
    // widget.initialValue.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_seconds > 0 && _isResendDisabled) {
          setState(() => _seconds--);
          _startTimer();
        } else {
          setState(() => _isResendDisabled = false);
        }
      }
    });
  }

  void _handleResendOtp() {
    if (_attempts < _maxAttempts) {
      setState(() {
        _attempts++;
        _seconds = 30;
        _isResendDisabled = true;
      });
      _startTimer();
      _restartListening();
      widget.onResend();
    }
  }

  void _restartListening() {
    smartAuth.removeUserConsentApiListener();
    _startUserConsent();
  }

  void _onChanged(String value) {
    widget.initialValue.text = value;
    _validateOtp();
  }

  // void _onBackspace(int index) {
  //   _validateOtp();
  // }

  void _validateOtp() {
    final otp = widget.initialValue.text;

    // final code = _defaultValidator(otp);

    if (otp.length == _cellCount && !_isVerifying) {
      final error = widget.validator?.call(otp) ?? _defaultValidator(otp);
      setState(() => _errorText = error);
      if (error == null) {
        setState(() => _isVerifying = true);
        // Stop listening for OTP to prevent late detections
        // controller.stopListen();
        // smsConsentForOtpAutoFill.dispose();
        smartAuth.removeUserConsentApiListener();
        widget.onVerify(otp);
      }
    } else {
      setState(() => _errorText = null);
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
      return 'Enter a valid OTP';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            configTitle,
            style: configTitleStyle ??
                const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
          ),
          if (configSubTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                configSubTitle!,
                style: configSubTitleStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.otpLabel,
                  style: configEditLabelStyle ??
                      const TextStyle(
                        fontSize: 20,
                        color: Color(0x9E000000),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onEdit,
                child: Text(
                  'Edit',
                  style: configEditStyle ??
                      const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PinCodeTextField(
            enabled: true,
            enablePinAutofill: true,
            appContext: context,
            validator: widget.validator,
            onChanged: _onChanged,
            controller: widget.initialValue,
            cursorColor: Colors.black,
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            length: 4,
            obscureText: false,
            autoDisposeControllers: false,
            animationCurve: Curves.linear,
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 0),
                blurRadius: 1,
              )
            ],
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldOuterPadding: const EdgeInsets.only(right: 6),
              borderWidth: 2,
              fieldHeight: 60,
              fieldWidth: 60,
              activeColor: Colors.black,
              activeFillColor: Colors.white,
              inactiveColor: _errorText != null ? Colors.red : Colors.black,
              inactiveFillColor: Colors.white,
              selectedColor: Colors.black,
              selectedFillColor: Colors.white,
            ),
            mainAxisAlignment: MainAxisAlignment.start,
            textStyle: configCellTextStyle ??
                const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          if (_attempts < _maxAttempts)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  text: 'OTP not received? ',
                  style: configResendTextStyle ??
                      const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: _isResendDisabled ? null : _handleResendOtp,
                        child: Text(
                          _isResendDisabled
                              ? 'Resend in ${_seconds}s'
                              : 'Resend OTP',
                          style: configResendButtonTextStyle ??
                              const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0964C5),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: configSubmitButtonStyleBox ??
                  ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              onPressed: _isVerifying
                  ? null
                  : () {
                      if (_isVerifying) return; // Prevent duplicate calls
                      final otp = widget.initialValue.text;
                      final error =
                          widget.validator?.call(otp) ?? _defaultValidator(otp);
                      setState(() => _errorText = error);
                      if (error == null) {
                        setState(() => _isVerifying = true);
                        widget.onVerify(otp);
                      }
                    },
              child: widget.isSuccess
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          configLoadingText,
                          style: configLoadingTextStyle ??
                              const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        )
                      ],
                    )
                  : widget.isLoading
                      ? configLoadingText.isNotEmpty
                          ? Text(
                              configLoadingText,
                              style: configLoadingTextStyle,
                            )
                          : const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                      : Text(
                          configSubmitButtonText,
                          style: configSubmitButtonTextStyle ??
                              const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
