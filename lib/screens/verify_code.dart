import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:otp_autofill_plus/otp_autofill_plus.dart';

class VerifyCodeForm extends StatefulWidget {
  final String otpLabel;
  final VoidCallback onResend;
  final VoidCallback onEdit;
  final ValueChanged<String> onVerify;
  final String? Function(String?)? validator;
  final String? initialValue;
  final BoxDecoration? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final String submitButtonText;
  final BoxDecoration? pincodeCellStyle;
  final BoxDecoration? pincodeCellContainerStyle;
  final InputDecoration? inputStyle;
  final bool isLoading;
  final bool isSuccess;
  final TextStyle? loadingTextStyle;
  final String? title;
  final String? subTitle;
  final String? otpPlaceholder;
  final TextStyle? otpPlaceholderStyle;
  final TextStyle? editStyle;
  final TextStyle? editLabelStyle;
  final TextStyle? resendButtonTextStyle;
  final TextStyle? resendTextStyle;
  final TextStyle? cellTextStyle;
  final String? loadingText;
  final String? error;

  const VerifyCodeForm({
    super.key,
    required this.otpLabel,
    required this.onResend,
    required this.onEdit,
    required this.onVerify,
    this.validator,
    this.initialValue,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    this.titleStyle,
    this.subTitleStyle,
    this.submitButtonText = 'Verify',
    this.pincodeCellStyle,
    this.pincodeCellContainerStyle,
    this.inputStyle,
    this.isLoading = false,
    this.isSuccess = false,
    this.loadingTextStyle,
    this.title = 'OTP Verification',
    this.subTitle,
    this.otpPlaceholder,
    this.otpPlaceholderStyle,
    this.editStyle,
    this.editLabelStyle,
    this.resendButtonTextStyle,
    this.resendTextStyle,
    this.cellTextStyle,
    this.loadingText,
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
  final List<TextEditingController> _controllers = [];
  final _formKey = GlobalKey<FormState>();
  String? _errorText;

  final scaffoldKey = GlobalKey();
  late OTPTextEditController controller;
  late OTPInteractor _otpInteractor;

  final pinputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _cellCount; i++) {
      _focusNodes.add(FocusNode());
      _controllers.add(TextEditingController());
    }
    _startTimer();
    // TODO: Implement SMS user consent for Android

    print("INIIIIIIIT");

    _initInteractor();
    controller = OTPTextEditController(
      codeLength: 4,
      //ignore: avoid_print
      onCodeReceive: (code) => print('Your Application receive code - $code'),
      otpInteractor: _otpInteractor,
    )..startListenUserConsent(
        (code) {
          final exp = RegExp(r'(\d{4})');

          final otp = exp.stringMatch(code ?? '') ?? '';
          // widget.onVerify(otp);

          print('code ${code}');
          print('exp ${exp.stringMatch(code ?? '')}');

          pinputController.text = otp;
          pinputController.selection = TextSelection.fromPosition(
            TextPosition(offset: pinputController.text.length),
          );

          return otp;
        },
        strategies: [],
      );
  }

  @override
  void didUpdateWidget(VerifyCodeForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != oldWidget.error) {
      setState(() {
        _errorText = widget.error;
      });
    }
  }

  Future<void> _initInteractor() async {
    _otpInteractor = OTPInteractor();

    // You can receive your app signature by using this method.
    final appSignature = await _otpInteractor.getAppSignature();
    // print('Your app signature: $appSignature');
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    controller.stopListen();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_seconds > 0 && _isResendDisabled) {
        setState(() => _seconds--);
        _startTimer();
      } else {
        setState(() => _isResendDisabled = false);
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
      widget.onResend();
    }
  }

  void _onChanged(String value) {
    print('onChanged value - $value');

    if (value.length == 1 &&
        _controllers.indexWhere((c) => c.text.isEmpty) < _cellCount - 1) {
      _focusNodes[_controllers.indexWhere((c) => c.text.isEmpty)]
          .requestFocus();
    }
    _validateOtp();
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
    _validateOtp();
  }

  void _validateOtp() {
    final otp = pinputController.text;

    final code = _defaultValidator(otp);

    if (otp.length == _cellCount) {
      final error = widget.validator?.call(otp) ?? _defaultValidator(otp);
      setState(() => _errorText = error);
      print("ERROR $error");
      if (error == null) {
        print("CALLLLLLL");
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
          if (widget.title != null)
            Text(
              widget.title!,
              style: widget.titleStyle ??
                  const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
            ),
          if (widget.subTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.subTitle!,
                style: widget.subTitleStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF999999),
                    ),
              ),
            ),
          Row(
            children: [
              Text(
                widget.otpLabel,
                style: widget.editLabelStyle ??
                    const TextStyle(
                      fontSize: 20,
                      color: Color(0x9E000000),
                    ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onEdit,
                child: Text(
                  'Edit',
                  style: widget.editStyle ??
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
            controller: pinputController,
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
            textStyle: widget.cellTextStyle ??
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
                  style: widget.resendTextStyle ??
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
                          style: widget.resendButtonTextStyle ??
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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.submitButtonStyle?.color ?? const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final otp = pinputController.text;
                final error =
                    widget.validator?.call(otp) ?? _defaultValidator(otp);
                print("ERROR ON SUBMIT $error");
                _errorText = error;
                if (error == null) {
                  widget.onVerify(otp);
                }
              },
              child: widget.isLoading
                  ? widget.loadingText != null
                      ? Text(
                          widget.loadingText!,
                          style: widget.loadingTextStyle,
                        )
                      : const CircularProgressIndicator(
                          color: Colors.white,
                        )
                  : Text(
                      widget.submitButtonText,
                      style: widget.submitButtonTextStyle ??
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