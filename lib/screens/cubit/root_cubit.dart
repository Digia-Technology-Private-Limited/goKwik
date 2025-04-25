import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/shopify_service.dart';
// Removed unused import
import 'package:url_launcher/url_launcher.dart';

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

class RootCubit extends Cubit<RootState> {
  RootCubit() : super(const RootState());

  Future<void> resendPhoneOtp(String phoneNumber) async {
    emit(state.copyWith(isLoading: true));
    try {
      emit(state.copyWith(isLoading: false));
    } catch (err) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> handleOtpSend(
      String phoneNumber, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      await ApiService.sendVerificationCode(phoneNumber, true);
      emit(state.copyWith(otpSent: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  Future<void> handleEmailOtpVerification(
      String email, String otp, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ShopifyService.shopifyVerifyEmail(email, otp);
      // if(response['phone']!=null) {
      //   emit(state.copyWith(otpSent: true, isNewUser: true, isLoading: false));
      // }
      state.copyWith(isSuccess: true, isLoading: false);
    } catch (err) {
      state.copyWith(createAccountError: err.toString(), isLoading: false);
    }
  }

  Future<void> handleOtpVerification(
      String phoneNumber, String otp, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.verifyCode(phoneNumber, otp);
      if (state.merchantType == 'shopify' && response['email'] != null) {
        // if(response['phone']!=null) {
        //   emit(state.copyWith(otpSent: true, isNewUser: true, isLoading: false));
        // }
        emit(state.copyWith(isSuccess: true, isLoading: false));
      }
      if (response['multiple_emails'] != null) {
        emit(state.copyWith(
          multipleEmails: response['multiple_emails'],
          isSuccess: true,
        ));
      }
      if (response['emailRequired'] != null && response['email']) {
        emit(state.copyWith(
          isNewUser: true,
        ));
      }
      if (response['merchantResponse']['email'] != null) {
        //  if(response['merchantResponse']['phone']!=null) {
        //     emit(state.copyWith(otpSent: true, isNewUser: true, isLoading: false));
        //   }
        emit(state.copyWith(isSuccess: true, isLoading: false));
      }
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  void handlePhoneChange() {
    emit(state.copyWith(
        otpSent: false, isNewUser: true, createAccountError: null));
  }

  void handleEmailChange() {
    emit(state.copyWith(
        emailOtpSent: false, isNewUser: true, createAccountError: null));
  }

  Future<void> linkOpenHandler(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> handleCreateUser(String email, String username, String dob,
      String gender, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.createUserApi(
          email: email, name: username, dob: dob, gender: gender);

      emit(state.copyWith(
          isSuccess: true, isUserLoggedIn: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  Future<void> handleShopifySubmit(
      String email, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));

    try {
      await ShopifyService.shopifySendEmailVerificationCode(email);
      emit(state.copyWith(
          emailOtpSent: true, isNewUser: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  Future<void> resendShopifyEmailOtp(String email) async {
    emit(state.copyWith(isLoading: true));
    try {
      await ShopifyService.shopifySendEmailVerificationCode(email);
      emit(state.copyWith(
          emailOtpSent: true, isNewUser: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  void handleSkip(Function? onGuestLoginPress) {
    if (onGuestLoginPress != null) {
      onGuestLoginPress();
    }
  }
}
