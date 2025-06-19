import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/api/shopify_service.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/key_congif.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/module/single_use_data.dart';
import 'package:gokwik/screens/cubit/root_model.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../flow_result.dart';
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

  final Function(FlowResult)? onSuccessData;
  final Function(FlowResult)? onErrorData;
  final MerchantType merchantType = MerchantType.shopify;
  RootCubit({this.onSuccessData, this.onErrorData})
      : super(const RootState(merchantType: MerchantType.shopify)) {
    _listenMerchantType();
    _listenUserStateUpdated();
    _initializeDevMode();
  }

  Future<void> resendPhoneOtp() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response =
          await ApiService.sendVerificationCode(phoneController.text, true);
      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'label': 'resend_otp',
        'action': 'click',
        'property': 'phone_number',
        'value': int.tryParse(phoneController.text),
      });
      if (response.isFailure) {
        onErrorData?.call(FlowResult(
          flowType: FlowType.resendOtp,
          error: (response as Failure).message,
        ));
        emit(state.copyWith(
            error: SingleUseData((response as Failure).message),
            isLoading: false));
        return;
      }
      // onSuccessData?.call(FlowResult(
      //   flowType: FlowType.resendOtp,
      //   data: (response as Success).data,
      // ));
      emit(state.copyWith(isLoading: false));
    } catch (err) {
      onErrorData?.call(FlowResult(
        flowType: FlowType.resendOtp,
        error: (err as Failure).message,
      ));
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> handleOtpSend() async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.sendVerificationCode(
          phoneController.text, state.notifications);
      if (response.isFailure) {
        onErrorData?.call(FlowResult(
          flowType: FlowType.otpSend,
          error: (response as Failure).message,
        ));
        emit(state.copyWith(
            error: SingleUseData((response as Failure).message),
            isLoading: false));
        return;
      }
      emit(state.copyWith(otpSent: true, isLoading: false));
    } catch (err) {
      onErrorData?.call(FlowResult(
        flowType: FlowType.resendOtp,
        error: (err as Failure).message,
      ));
      emit(state.copyWith(
          error: SingleUseData((err as Failure).message), isLoading: false));
    }
  }

  Future<void> handleEmailOtpVerification(String value) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    otpController.text = value;
    try {
      final response = await ShopifyService.shopifyVerifyEmail(
          shopifyEmailController.text, otpController.text);


      if (response['data']['phone'] == null) {
        response['data']['phone'] = phoneController.text;
      }

      onSuccessData?.call(FlowResult(
        flowType: FlowType.emailOtpVerify,
        data: response['data'],
      ));

      if (response['phone'] != null) {
        emit(state.copyWith(otpSent: true, isNewUser: true, isLoading: false));
      }
      emit(state.copyWith(isSuccess: true, isLoading: false));
    } catch (err) {
      emit(state.copyWith(
          error: SingleUseData((err as Failure).message), isLoading: false));
    }
  }

  void updateNotification(bool value) {
    emit(state.copyWith(notifications: value));
  }

  Future<void> handleOtpVerification(
    String otp,
  ) async {
    if (!formKey.currentState!.validate()) return;
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      dynamic responses =
          ((await ApiService.verifyCode(phoneController.text, otp))
              .getDataOrThrow());

      if (state.merchantType == MerchantType.shopify) {
        if (responses.containsKey('email')) {
          responses['data']?.remove('state');
          responses['data']?.remove('accountActivationUrl');

          if (responses['data']?['phone'] == "null") {
            responses['data']?['phone'] = phoneController.text;
          }
        }

        emit(state.copyWith(isSuccess: true, isLoading: false));
        onSuccessData?.call(
          FlowResult(flowType: FlowType.otpVerify, data: responses['data']),
        );
      }


      if (responses.containsKey('multiple_emails') &&
          responses['multiple_emails'] != "null") {
        emit(state.copyWith(
          multipleEmails: (responses['multiple_emails'] as String?)
              ?.split(',')
              .map((item) {
            return MultipleEmail(label: item.trim(), value: item.trim());
          }).toList(),
        ));
      }

      final responseMap = responses.toJson();


      if (responseMap['emailRequired'] == true &&
          responseMap['email'] == "null") {
        emit(state.copyWith(
          isNewUser: true,
          isLoading: false,
        ));
        return;
      }


      if (responseMap.containsKey('merchantResponse') &&
          responseMap['merchantResponse'].containsKey('email') &&
          responseMap['merchantResponse']['email'] != "null") {
        if (responseMap.containsKey('merchantResponse')) {
          responseMap['merchantResponse']['phone'] ??= phoneController.text;
        }

        onSuccessData?.call(
          FlowResult(
            flowType: FlowType.otpVerify,
            data: responseMap['merchantResponse'],
          ),
        );

        emit(state.copyWith(isSuccess: true, isLoading: false));
      }
      otpController.clear();
      // _listenUserStateUpdated();
    } catch (err) {
      otpController.clear();
      onErrorData?.call(FlowResult(
          flowType: FlowType.otpVerify, error: (err as Failure).message));
      emit(state.copyWith(
          error: SingleUseData((err as Failure).message), isLoading: false));
    }
  }

  void handlePhoneChange() {
    emit(state.copyWith(otpSent: false, isNewUser: false, error: null));
  }

  void handleEmailChange() {
    emit(state.copyWith(emailOtpSent: false, isNewUser: true, error: null));
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

      onSuccessData?.call(
          FlowResult(flowType: FlowType.createUser, data: response.getDataOrThrow()));
      emit(state.copyWith(
          isSuccess: true, isUserLoggedIn: true, isLoading: false));
    } catch (err) {
      emit(state.copyWith(
          error: SingleUseData((err as Failure).message), isLoading: false));
    }
  }

  Future<void> handleShopifySubmit(
    String email,
  ) async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    shopifyEmailController.text = email;
    try {
      // Validate disposable email
      final isValidEmail = await ShopifyService.validateDisposableEmail(email);
      
      if (!isValidEmail) {
        emit(state.copyWith(isLoading: false));
        final errorMessage = 'Entered email is not valid';
        emit(state.copyWith(
            error: SingleUseData(errorMessage),
            isLoading: false,
            emailOtpSent: false));
        onErrorData?.call(FlowResult(
            flowType: FlowType.emailOtpSend,
            error: errorMessage));
        return;
      }

      await ShopifyService.shopifySendEmailVerificationCode(email);

      emit(state.copyWith(
          emailOtpSent: true, isNewUser: false, isLoading: false));
    } catch (err) {
      emit(state.copyWith(
          error: SingleUseData((err is Failure) ? err.message : err.toString()),
          isLoading: false,
          emailOtpSent: false));
      onErrorData
          ?.call(FlowResult(flowType: FlowType.emailOtpSend, error: err));
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
      emit(state.copyWith(
          error: SingleUseData((err as Failure).message), isLoading: false));
    }
  }

  void handleSkip(Function? onGuestLoginPress) {
    if (onGuestLoginPress != null) {
      onGuestLoginPress();
    }
  }

  //Listeners
  void _listenMerchantType() async {
    final merchantType =
        await cacheInstance.getValue(KeyConfig.gkMerchantTypeKey);
    if (merchantType != null) {
      emit(state.copyWith(
          merchantType: merchantType == 'shopify'
              ? MerchantType.shopify
              : MerchantType.custom));
    }
  }

  void _listenUserStateUpdated() {
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
    if (response == null) {
      // onErrorData?.call(FlowResult(
      //     flowType: FlowType.notLoggedIn, error: 'User Not Logged In'));
      return;
    }

    final Map<String, dynamic> responseData = jsonDecode(response);

    if (state.merchantType == MerchantType.shopify) {
      if (
          // responseData['emailRequired'] == true &&
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
              responseData['email'] != null
          // &&
          // responseData['multipassToken'] != null
          ) ||
          (responseData['shopifyCustomerId'] != null &&
              responseData['phone'] != null &&
              responseData['email'] != null &&
              // responseData['multipassToken'] != null &&
              responseData['password'] != null)) {
        onSuccessData?.call(
            FlowResult(flowType: FlowType.alreadyLoggedIn, data: responseData));
        emit(state.copyWith(isUserLoggedIn: true));
        return;
      }
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
    }
  }

  Future<void> _initializeDevMode() async {
    try {
      final mode = await cacheInstance.getValue(KeyConfig.gkMode);
      final isDev = mode == 'debug';
      
      if (isDev) {
        final requestId = await cacheInstance.getValue(KeyConfig.gkRequestIdKey);
        emit(state.copyWith(
          isDevBuild: true,
          reqId: requestId ?? '',
        ));
      } else {
        emit(state.copyWith(isDevBuild: false));
      }
    } catch (err) {
      emit(state.copyWith(isDevBuild: false));
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
