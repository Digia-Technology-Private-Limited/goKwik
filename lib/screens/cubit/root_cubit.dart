import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/shopify_service.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/screens/create_account.dart';
import 'package:gokwik/screens/cubit/root_model.dart';
// Removed unused import
import 'package:url_launcher/url_launcher.dart';

import '../root.dart';

class RootCubit extends Cubit<RootState> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final shopifyEmailController = TextEditingController();
  final shopifyOtpController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final dobController = ValueNotifier<DateTime?>(null);
  final genderController = ValueNotifier<String?>(null);

  final formKey = GlobalKey<FormState>();

  final Function(dynamic)? onSuccessData;
  final Function(dynamic)? onErrorData;
  final MerchantType merchantType = MerchantType.shopify;
  RootCubit({this.onSuccessData, this.onErrorData})
      : super(const RootState(merchantType: MerchantType.shopify)) {
    _listenMerchantType();
    _listenUserStateUpdated();
  }

  Future<void> resendPhoneOtp() async {
    emit(state.copyWith(isLoading: true));
    try {
      emit(state.copyWith(isLoading: false));
    } catch (err) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> handleOtpSend() async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      await ApiService.sendVerificationCode(phoneController.text, true);
      emit(state.copyWith(otpSent: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  Future<void> handleEmailOtpVerification(String value) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    otpController.text = value;
    try {
      final response = await ShopifyService.shopifyVerifyEmail(
          emailController.text, otpController.text);
      // if(response['phone']!=null) {
      //   emit(state.copyWith(otpSent: true, isNewUser: true, isLoading: false));
      // }
      state.copyWith(isSuccess: true, isLoading: false);
    } catch (err) {
      state.copyWith(createAccountError: err.toString(), isLoading: false);
    }
  }

  void updateNotification(bool value) {
    emit(state.copyWith(notifications: value));
  }

  Future<void> handleOtpVerification(
    String otp,
  ) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.verifyCode(phoneController.text, otp);
      if (state.merchantType.name == 'shopify' && response['email'] != null) {
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

  Future<void> handleCreateUser() async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.createUserApi(
        email: emailController.text,
        name: usernameController.text,
        dob: dobController.value?.toIso8601String(),
        gender: genderController.value,
      );

      emit(state.copyWith(
          isSuccess: true, isUserLoggedIn: true, isLoading: false));
    } catch (err) {
      emit(
          state.copyWith(createAccountError: err.toString(), isLoading: false));
    }
  }

  Future<void> handleShopifySubmit(
    String email,
  ) async {
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

  Future<void> resendShopifyEmailOtp() async {
    emit(state.copyWith(isLoading: true));
    try {
      await ShopifyService.shopifySendEmailVerificationCode(
          emailController.text);
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

  //Listeners
  void _listenMerchantType() async {
    // This mimics DeviceEventEmitter listening
    final merchantType =
        await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
    if (merchantType != null) {
      emit(state.copyWith(
          merchantType: merchantType == 'shopify'
              ? MerchantType.shopify
              : MerchantType.custom));
    }
    // immediately emit event after adding listener
    onMerchantTypeUpdated();
  }

  void _listenUserStateUpdated() {
    // You can just trigger when merchantType updates or manually call
    onUserStateUpdated();
  }

  Future<void> onMerchantTypeUpdated() async {
    final merchantType =
        await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
    if (merchantType != null) {
      emit(state.copyWith(
          merchantType: merchantType == 'shopify'
              ? MerchantType.shopify
              : MerchantType.custom));
    }
  }

  Future<void> onUserStateUpdated() async {
    final response = await cacheInstance.getValue(KeyConfig.gkVerifiedUserKey);
    if (response == null) return;

    final Map<String, dynamic> responseData = jsonDecode(response);

    if (state.merchantType == MerchantType.shopify) {
      if (responseData['emailRequired'] == true &&
          (responseData['email'] == null || responseData['email'].isEmpty)) {
        emit(state.copyWith(isNewUser: true));
        if (responseData['multipleEmail'] != null) {
          final multipleEmails = (responseData['multipleEmail'] as String)
              .split(',')
              .map((email) => email.trim())
              .toList();
          emit(state.copyWith(
              multipleEmails: multipleEmails
                  .map((email) => MultipleEmail(label: email, value: email))
                  .toList()));
        }
        return;
      }

      if ((responseData['shopifyCustomerId'] != null &&
              responseData['phone'] != null &&
              responseData['email'] != null &&
              responseData['multipassToken'] != null) ||
          (responseData['shopifyCustomerId'] != null &&
              responseData['phone'] != null &&
              responseData['email'] != null &&
              responseData['multipassToken'] != null &&
              responseData['password'] != null)) {
        emit(state.copyWith(isUserLoggedIn: true));
        return;
      }

      SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'open_login_modal',
        'action': 'click',
      });
    }

    if (state.merchantType == MerchantType.custom) {
      if (responseData['emailRequired'] == true &&
          (responseData['email'] == null || responseData['email'].isEmpty)) {
        emit(state.copyWith(isNewUser: true));
        return;
      }

      if (responseData['phone'] != null && responseData['email'] != null) {
        emit(state.copyWith(isUserLoggedIn: true));
        return;
      }
      SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'open_login_modal',
        'action': 'click',
      });
    }
  }

  @override
  Future<void> close() {
    phoneController.dispose();
    otpController.dispose();
    shopifyEmailController.dispose();
    shopifyOtpController.dispose();
    emailController.dispose();
    usernameController.dispose();
    dobController.dispose();
    return super.close();
  }
}
