import 'package:gokwik/screens/root.dart';

class RootState {
  final bool isUserLoggedIn;
  final String? merchantType;
  final String? createAccountError;
  final bool isLoading;

  final bool notifications;
  final bool otpSent;
  final bool isNewUser;
  final bool emailOtpSent;
  final bool isSuccess;
  final List<MultipleEmail> multipleEmails;
  final String? gender;

  const RootState({
    this.isUserLoggedIn = false,
    this.merchantType,
    this.createAccountError,
    this.isLoading = false,
    this.notifications = true,
    this.otpSent = false,
    this.isNewUser = false,
    this.emailOtpSent = false,
    this.isSuccess = false,
    this.multipleEmails = const [],
    this.gender,
  });

  RootState copyWith({
    bool? isUserLoggedIn,
    String? merchantType,
    String? createAccountError,
    bool? isLoading,
    bool? notifications,
    bool? otpSent,
    bool? isNewUser,
    bool? emailOtpSent,
    bool? isSuccess,
    List<MultipleEmail>? multipleEmails,
    String? gender,
  }) {
    return RootState(
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      merchantType: merchantType ?? this.merchantType,
      createAccountError: createAccountError ?? this.createAccountError,
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      otpSent: otpSent ?? this.otpSent,
      isNewUser: isNewUser ?? this.isNewUser,
      emailOtpSent: emailOtpSent ?? this.emailOtpSent,
      isSuccess: isSuccess ?? this.isSuccess,
      multipleEmails: multipleEmails ?? this.multipleEmails,
      gender: gender ?? this.gender,
    );
  }
}
