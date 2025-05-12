import 'package:gokwik/config/types.dart';
import 'package:gokwik/module/single_use_data.dart';
import 'package:gokwik/screens/root.dart';

enum RootScreenStep {
  phoneInput,
  phoneOtpVerification,
  emailInput,
  emailOtpVerification,
  multipleEmailsScreen,
  newUserRegistration,
  loggedIn,
}

class RootState {
  final bool isUserLoggedIn;
  final MerchantType merchantType;
  final SingleUseData? error;
  final bool isLoading;

  final bool notifications;
  final bool otpSent;
  final bool isNewUser;
  final bool emailOtpSent;
  final bool isSuccess;
  final List<MultipleEmail> multipleEmails;
  final String? gender;
  final RootScreenStep currentStep;

  const RootState({
    this.isUserLoggedIn = false,
    this.merchantType = MerchantType.shopify,
    this.error,
    this.isLoading = false,
    this.notifications = true,
    this.otpSent = false,
    this.isNewUser = false,
    this.emailOtpSent = false,
    this.isSuccess = false,
    this.multipleEmails = const [],
    this.gender,
    this.currentStep = RootScreenStep.phoneInput,
  });

  RootState copyWith({
    bool? isUserLoggedIn,
    MerchantType? merchantType,
    SingleUseData? error,
    bool? isLoading,
    bool? notifications,
    bool? otpSent,
    bool? isNewUser,
    bool? emailOtpSent,
    bool? isSuccess,
    List<MultipleEmail>? multipleEmails,
    String? gender,
    RootScreenStep? currentStep,
  }) {
    return RootState(
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      merchantType: merchantType ?? this.merchantType,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      otpSent: otpSent ?? this.otpSent,
      isNewUser: isNewUser ?? this.isNewUser,
      emailOtpSent: emailOtpSent ?? this.emailOtpSent,
      isSuccess: isSuccess ?? this.isSuccess,
      multipleEmails: multipleEmails ?? this.multipleEmails,
      gender: gender ?? this.gender,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
