import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gokwik/go_kwik.dart';

// ─── Brand tokens ─────────────────────────────────────────────────────────────
// Change these two values to instantly re-skin the entire KwikForms + Login UI.

const _brandPrimary = Color(0xFF1B8A4C); // green
const _brandRadius = 10.0; // button & input corner radius

// ─── Shared style helpers ─────────────────────────────────────────────────────

/// Input decoration applied to every text field — forms AND login screens.
InputDecoration get _sharedInputDecoration => InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF2FAF6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_brandRadius),
        borderSide: const BorderSide(color: Color(0xFFC3E6D3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_brandRadius),
        borderSide: const BorderSide(color: _brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_brandRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_brandRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
    );

/// ButtonStyle applied to every primary action button — forms AND login screens.
ButtonStyle get _sharedButtonStyle => ElevatedButton.styleFrom(
      backgroundColor: _brandPrimary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: _brandPrimary.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_brandRadius),
      ),
      elevation: 0,
    );

const TextStyle _sharedButtonTextStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.2,
);

const TextStyle _sharedTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Color(0xFF1A1A2E),
);

const TextStyle _sharedSubtitleStyle = TextStyle(
  fontSize: 13,
  color: Color(0xFF6B7280),
  height: 1.4,
);

// ─── KwikFormsStyle (address list, add address, form screens) ─────────────────

KwikFormsStyle get _kwikFormsStyle => KwikFormsStyle(
      primaryColor: _brandPrimary,
      buttonStyle: _sharedButtonStyle,
      buttonTextStyle: _sharedButtonTextStyle,
      inputStyle: _sharedInputDecoration,
      cardStyle: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_brandRadius),
        boxShadow: [
          BoxShadow(
            color: _brandPrimary.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      headerTitleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );

// ─── KwikLoginConfig (login, OTP, email, create-account screens) ──────────────
// Per-screen configs mirror the same border radius / fill colour as
// _sharedInputDecoration and _sharedButtonStyle so the login steps look
// identical to the address form steps.

KwikLoginConfig get _kwikLoginConfig => KwikLoginConfig(
      inputProps: TextInputConfig(
        // Global text styles applied across login screens
        submitButtonTextStyle: _sharedButtonTextStyle,
        titleStyle: _sharedTitleStyle,
        subTitleStyle: _sharedSubtitleStyle,
        inputStyle: _sharedInputDecoration,

        // Phone number entry screen
        phoneAuthScreen: PhoneAuthScreenConfig(
          submitButtonStyle: _sharedButtonStyle,
          submitButtonTextStyle: _sharedButtonTextStyle,
          textFieldInputStyle: _sharedInputDecoration,
          titleTextStyle: _sharedTitleStyle,
          subtitleTextStyle: _sharedSubtitleStyle,
        ),

        // OTP verification screen
        otpVerificationScreen: OtpVerificationScreenConfig(
          submitButtonStyleBox: _sharedButtonStyle,
          submitButtonTextStyle: _sharedButtonTextStyle,
          titleStyle: _sharedTitleStyle,
          subTitleStyle: _sharedSubtitleStyle,
        ),

        // Email OTP verification screen (Shopify flow)
        emailOtpVerificationScreen: EmailOtpVerificationScreenConfig(
          submitButtonStyle: _sharedButtonStyle,
          submitButtonTextStyle: _sharedButtonTextStyle,
          titleTextStyle: _sharedTitleStyle,
          subTitleTextStyle: _sharedSubtitleStyle,
        ),
      ),
    );

// ─── Screen ───────────────────────────────────────────────────────────────────

class GokwikKwikformsScreen extends StatelessWidget {
  final String title;

  /// Pass a populated list to show saved addresses,
  /// or an empty list [] to show the "No Saved Addresses" empty state.
  final List<KwikAddress> addresses;
  final bool consent;

  /// Timestamp (in milliseconds since epoch) when the user granted consent.
  final int? consentTimestamp;

  const GokwikKwikformsScreen({
    super.key,
    required this.title,
    this.addresses = const [],
    this.consent = true,
    this.consentTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: KwikForms(
          addresses: addresses,
          consent: consent,
          consentTimestamp: consentTimestamp,
          style: _kwikFormsStyle,
          loginConfig: _kwikLoginConfig,
          onFormSubmit: (address) {
            debugPrint(
                'onFormSubmit: id=${address.id} name=${address.name} phone=${address.phone}');
            debugPrint('  addressLine=${address.addressLine}');
            debugPrint(
                '  houseNo=${address.houseNo} area=${address.area} landmark=${address.landmark}');
            debugPrint(
                '  pincode=${address.pincode} city=${address.city} state=${address.state} country=${address.country}');
            debugPrint('  json=${jsonEncode(address.toJson())}');
            Navigator.of(context).pop(address);
          },
          onSubmissionFailed: (error) {
            debugPrint('onSubmissionFailed: $error');
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Submission Failed'),
                content: Text(error?.toString() ??
                    'Something went wrong. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
