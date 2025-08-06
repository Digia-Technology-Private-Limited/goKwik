import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gokwik/screens/root.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyCodeForm extends StatefulWidget {
  final String otpLabel;
  final VoidCallback onResend;
  final VoidCallback onEdit;
  final ValueChanged<String> onVerify;
  final String? Function(String?)? validator;
  final String? initialValue;
  final dynamic config;
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
    this.initialValue,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  @override
  State<VerifyCodeForm> createState() => _VerifyCodeFormState();
}

class _VerifyCodeFormState extends State<VerifyCodeForm> with CodeAutoFill {
  final int _cellCount = 4;
  final int _maxAttempts = 5;
  int _seconds = 30;
  bool _isResendDisabled = true;
  int _attempts = 0;
  final List<FocusNode> _focusNodes = [];
  final _formKey = GlobalKey<FormState>();
  String? _errorText;
  bool _isVerifying = false;
  final pinputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
    listenForCode();
  }

  @override
  void codeUpdated() {
    final code = this.code;
    if (code != null && code.length == _cellCount) {
      pinputController.text = code;
      pinputController.selection = TextSelection.fromPosition(
        TextPosition(offset: code.length),
      );
      _validateOtp();
    }
  }

  @override
  void dispose() {
    cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    pinputController.dispose();
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
      widget.onResend();
    }
  }

  void _onChanged(String value) {
    pinputController.text = value;
    _validateOtp();
  }

  void _validateOtp() {
    final otp = pinputController.text;
    if (otp.length == _cellCount && !_isVerifying) {
      final error = widget.validator?.call(otp) ?? _defaultValidator(otp);
      setState(() => _errorText = error);
      if (error == null) {
        setState(() => _isVerifying = true);
        cancel();
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
    if (!RegExp(r'^[0-9]{4}\$').hasMatch(value)) {
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
            'Enter OTP',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          PinCodeTextField(
            controller: pinputController,
            appContext: context,
            length: _cellCount,
            onChanged: _onChanged,
            animationType: AnimationType.fade,
            keyboardType: TextInputType.number,
            cursorColor: Colors.black,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 60,
              fieldWidth: 50,
              activeColor: Colors.black,
              inactiveColor: Colors.grey,
              selectedColor: Colors.blue,
            ),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _isResendDisabled ? 'Resend in $_seconds s' : 'Didn\'t get code?',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isResendDisabled ? null : _handleResendOtp,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: _isResendDisabled ? Colors.grey : Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isVerifying ? null : () {
              final error = widget.validator?.call(pinputController.text) ?? _defaultValidator(pinputController.text);
              setState(() => _errorText = error);
              if (error == null) {
                setState(() => _isVerifying = true);
                widget.onVerify(pinputController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blue,
            ),
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              'Verify',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
