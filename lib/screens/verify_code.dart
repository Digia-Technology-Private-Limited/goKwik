import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:smart_auth/smart_auth.dart';
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

class _VerifyCodeFormState extends State<VerifyCodeForm> {
  final int _cellCount = 4;
  final int _maxAttempts = 5;
  int _seconds = 30;
  bool _isResendDisabled = true;
  int _attempts = 0;
  String? _errorText;
  bool _isVerifying = false;

  final pinputController = TextEditingController();
  final smartAuth = SmartAuth();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startUserConsent();
  }

  Future<void> _startUserConsent() async {
    try {
      final res = await smartAuth.getSmsCode(useUserConsentApi: true); // ← consent
      if (!mounted) return;

      if (res.codeFound) {
        final otp = res.code ?? RegExp(r'\b(\d{4})\b').firstMatch(res.sms ?? '')?.group(1);
        if (otp != null && otp.isNotEmpty) {
          pinputController.text = otp;
          pinputController.selection = TextSelection.fromPosition(
            TextPosition(offset: pinputController.text.length),
          );
          _validateOtp();
        }
      }
    } catch (_) {
      // allow manual entry
    }
  }

  void _restartListening() {
    smartAuth.removeSmsListener();
    _startUserConsent();
  }

  @override
  void dispose() {
    smartAuth.removeSmsListener();
    pinputController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
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
      _restartListening();
    }
  }

  void _onChanged(String value) {
    _validateOtp();
  }

  void _validateOtp() {
    final otp = pinputController.text;
    if (otp.length == _cellCount && !_isVerifying) {
      final error = widget.validator?.call(otp) ?? _defaultValidator(otp);
      setState(() => _errorText = error);
      if (error == null) {
        setState(() => _isVerifying = true);
        smartAuth.removeSmsListener();
        widget.onVerify(otp);
      }
    } else {
      setState(() => _errorText = null);
    }
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) return 'Enter a valid OTP';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PinCodeTextField(
          appContext: context,
          length: 4,
          controller: pinputController,
          onChanged: _onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (_errorText != null)
          Text(_errorText!, style: const TextStyle(color: Colors.red)),
        TextButton(
          onPressed: _isResendDisabled ? null : _handleResendOtp,
          child: Text(_isResendDisabled
              ? 'Resend in ${_seconds}s'
              : 'Resend OTP'),
        ),
      ],
    );
  }
}


