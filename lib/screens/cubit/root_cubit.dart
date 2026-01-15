import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/api/base_response.dart';
import 'package:gokwik/api/httpClient.dart';
import 'package:gokwik/api/shopify_service.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/cdn_config.dart';
import 'package:gokwik/config/config_constants.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/module/single_use_data.dart';
import 'package:gokwik/screens/cubit/root_model.dart';
import 'package:onetaplogin/onetaplogin.dart';

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
  final void Function(String eventName, Map<String, dynamic> properties)?
      onAnalytics;
  final MerchantType merchantType = MerchantType.shopify;
  RootCubit({this.onSuccessData, this.onErrorData, this.onAnalytics})
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

  Future<void> handlePhoneSubmission() async {
    // Get merchant config from cache
    final merchantConfigStr = await cacheInstance.getValue(
        cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantConfig)!);
    
    Map<String, dynamic> merchantConfig = {};
    if (merchantConfigStr != null && merchantConfigStr.isNotEmpty) {
      try {
        merchantConfig = jsonDecode(merchantConfigStr);
      } catch (e) {
        merchantConfig = {};
      }
    }

    debugPrint("HELLO MERCHANT??? $merchantConfig");
    debugPrint("IS SILENT AUTH ENABLED??? ${merchantConfig['isSilentAuth']}");

    // Check if phone was edited after bureau or if silent auth is disabled
    if (state.phoneEditedAfterBureau || merchantConfig['isSilentAuth'] != true) {
      // await handleOtpSend();
      return;
    }

    // Otherwise, handle bureau submit
    await handleBureauSubmit();
  }

  Future<void> handleBureauSubmit() async {
    try {
      print("BUREAU CALLED");
      
      // Get environment from cache
      final env = await cacheInstance.getValue(
        cdnConfigInstance.getKeys(StorageKeyKeys.gkEnvironmentKey)!
      ) ?? 'production';

      print("ENV:: $env");

      // Get Bureau client ID from credentials - using 'sandbox' as per RN code
      final bureauClientId = cdnConfigInstance.getCredentials('sandbox');
      
      emit(state.copyWith(isLoading: true));
      
      // Get transaction ID from API
      final uuid = await ApiService.getBureauTransactionId();
      print("UUID FROM API:: $uuid");
      
      // Parse phone number to int (phoneNumber should be starting with 91)
      final phoneNumberInt = int.tryParse('91${phoneController.text}');
      final fullPhoneNumber = '+91${phoneController.text}';

      // Validate required parameters
      if (bureauClientId == null || uuid == null || phoneNumberInt == null || env.isEmpty) {
        print('Missing required Bureau parameters, falling back to OTP');
        emit(state.copyWith(isLoading: false));
        await handleOtpSend();
        return;
      }

      print('Calling Bureau with: bureauClientId=$bureauClientId, uuid=$uuid, phone=$fullPhoneNumber, env=$env');

      // Bureau timeout configuration
      const bureauTimeout = Duration(milliseconds: 5000);
      
      // Start timing authentication
      final authStartTime = DateTime.now();
      print('🕐 Authentication started at: ${authStartTime.toIso8601String()}');

      // Call Bureau SDK authentication with timeout race
      final bureauPromise = Onetaplogin.authenticate(
        bureauClientId!,
        uuid,
        phoneNumberInt,
        env: env,
        timeoutinMs: bureauTimeout.inMilliseconds,
      );

      final timeoutPromise = Future.delayed(
        bureauTimeout,
        () => throw Exception(jsonEncode({
          'status': 503,
          'error': 'BureauTimeout',
          'message': 'Authentication Failed! Fallback to OTP',
          'timestamp': DateTime.now().toIso8601String(),
        })),
      );

      // Race between bureau authentication and timeout
      final status = await Future.any([
        bureauPromise,
        timeoutPromise,
      ]);

      // End timing authentication
      final authEndTime = DateTime.now();
      final authDurationMs = authEndTime.difference(authStartTime).inMilliseconds;
      final authDurationSeconds = (authDurationMs / 1000).toStringAsFixed(2);
      
      print('✅ Authentication completed at: ${authEndTime.toIso8601String()}');
      print('⏱️ Authentication Response Time: ${authDurationMs}ms ($authDurationSeconds seconds)');
      print('Authentication STATUS: $status');
      
      // Check if authentication was successful (status 1 = completed)
      final isCompleted = status == 1;
      
      if (isCompleted) {
        // Bureau success - show loading modal
        emit(state.copyWith(
          showLoadingModal: true,
          loadingModalTitle: 'Hang tight!',
          loadingModalMessage: 'Verifying your account...',
        ));

        try {
          // Call sendBureauData API
          final responseFromBureauAPI = await ApiService.sendBureauData(
            transactionId: uuid,
          );

          // Update loading modal
          emit(state.copyWith(
            showLoadingModal: true,
            loadingModalTitle: 'Almost there...',
            loadingModalMessage: 'Logging you in...',
          ));

          // Handle bureau response using helper function
          final response = await _handleBureauResponse(
            responseFromBureauAPI,
            phoneController.text,
          );
          
          final responseData = response['data'];

          // Get merchant type
          final merchantTypeStr = await cacheInstance.getValue(
            cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantTypeKey)!
          );

          // Store shopifyCustomerId if present
          if (responseData?['shopifyCustomerId'] != null) {
            emit(state.copyWith(
              shopifyCustomerId: responseData['shopifyCustomerId'].toString(),
            ));
          }

          // Store state if present
          if (responseData?['state'] != null) {
            // Store state in cubit if needed for later use
          }

          // Handle Shopify and custom_shopify merchant types
          if (['shopify', 'custom_shopify'].contains(merchantTypeStr) &&
              responseData?['email'] != null) {
            
            // Remove unnecessary fields
            responseData?.remove('state');
            responseData?.remove('accountActivationUrl');

            print("INSIDE THE CONDITION $merchantTypeStr");

            // Handle auth required case
            if (responseData?['authRequired'] == true && responseData?['email'] != null) {
              shopifyEmailController.text = responseData['email'];
              otpController.clear();
              shopifyOtpController.clear();

              emit(state.copyWith(
                lastSubmittedEmail: responseData['email'],
              ));

              await ShopifyService.shopifySendEmailVerificationCode(responseData['email']);

              emit(state.copyWith(
                emailOtpSent: true,
                isNewUser: false,
                isLoading: false,
                showLoadingModal: false,
                loadingModalTitle: '',
                loadingModalMessage: '',
              ));
              return;
            }

            // Add phone if not present
            if (responseData?['phone'] == null) {
              responseData['phone'] = phoneController.text;
            }

            // Success case
            emit(state.copyWith(isSuccess: true));

            await SnowplowTrackerService.sendCustomEventToSnowPlow({
              'category': 'login_modal',
              'action': 'automated',
              'label': 'success_screen',
              'property': 'phone_number',
              'value': int.tryParse(phoneController.text),
            });

            if (onAnalytics != null) {
              onAnalytics!(
                cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
                {
                  'email': responseData?['email'],
                  'phone': phoneController.text,
                  'customer_id': responseData?['shopifyCustomerId']?.toString() ?? '',
                },
              );
            }

            onSuccessData?.call(FlowResult(
              flowType: FlowType.otpVerify,
              data: responseData,
            ));

            emit(state.copyWith(
              isLoading: false,
              showLoadingModal: false,
              loadingModalTitle: '',
              loadingModalMessage: '',
            ));
            return;
          }

          // Handle multiple emails
          if (responseData?['multipleEmail'] != null) {
            emit(state.copyWith(
              multipleEmails: (responseData['multipleEmail'] as String)
                  .split(',')
                  .map((item) => MultipleEmail(
                        label: item.trim(),
                        value: item.trim(),
                      ))
                  .toList(),
              showLoadingModal: false,
              loadingModalTitle: '',
              loadingModalMessage: '',
            ));
          }

          // Handle email required case
          if (responseData?['emailRequired'] == true &&
              (responseData?['email'] == null || responseData?['email'].isEmpty)) {
            emit(state.copyWith(
              isNewUser: true,
              showLoadingModal: false,
              loadingModalTitle: '',
              loadingModalMessage: '',
            ));
          }

          // Handle merchant response with email
          if (responseData?['merchantResponse']?['email'] != null) {
            if (responseData['merchantResponse']['phone'] == null) {
              responseData['merchantResponse']['phone'] = phoneController.text;
            }

            emit(state.copyWith(isSuccess: true));

            await SnowplowTrackerService.sendCustomEventToSnowPlow({
              'category': 'login_modal',
              'action': 'automated',
              'label': 'success_screen',
              'property': 'phone_number',
              'value': int.tryParse(phoneController.text),
            });

            if (onAnalytics != null) {
              onAnalytics!(
                cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
                {
                  'email': responseData['merchantResponse']['email'],
                  'phone': phoneController.text,
                  'customer_id': responseData['merchantResponse']['id']?.toString() ?? '',
                },
              );
            }

            onSuccessData?.call(FlowResult(
              flowType: FlowType.otpVerify,
              data: responseData['merchantResponse'],
            ));

            emit(state.copyWith(
              isLoading: false,
              showLoadingModal: false,
              loadingModalTitle: '',
              loadingModalMessage: '',
            ));
          }
        } catch (e) {
          // Handle API error from sendBureauData
          emit(state.copyWith(
            showLoadingModal: false,
            loadingModalMessage: '',
            isLoading: false,
          ));
          
          print('Error in Bureau API call: $e');
          
          emit(state.copyWith(
            error: SingleUseData(e.toString()),
          ));
        }
      } else {
        // Bureau failed - fallback to OTP
        print('Bureau authentication failed, falling back to OTP');
        emit(state.copyWith(
          showLoadingModal: false,
          loadingModalMessage: '',
          isLoading: false,
        ));
        await handleOtpSend();
      }
    } catch (error) {
      // Timeout or error - fallback to OTP
      print('Bureau error/timeout, falling back to OTP: $error');
      emit(state.copyWith(
        showLoadingModal: false,
        loadingModalMessage: '',
        isLoading: false,
      ));
      await handleOtpSend();
    }
  }

  /// Helper function to handle bureau API response
  /// Processes tokens, user data, and merchant-specific logic
  Future<Map<String, dynamic>> _handleBureauResponse(
    Map<String, dynamic> data,
    String phone,
  ) async {
    final gokwik = DioClient().getClient();
    final merchantType = await cacheInstance.getValue(
      cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantTypeKey)!
    );

    if (['shopify', 'custom_shopify'].contains(merchantType)) {
      // Handle tokens from the response
      if (data['data']?['token'] != null) {
        // Store access token
        await cacheInstance.setValue(
          cdnConfigInstance.getKeys(StorageKeyKeys.gkAccessTokenKey)!,
          data['data']['token'],
        );
        gokwik.options.headers[cdnConfigInstance.getHeader(APIHeaderKeys.gkAccessToken)!] =
          data['data']['token'];
      }

      if (data['data']?['coreToken'] != null) {
        // Store core token
        await cacheInstance.setValue(
          cdnConfigInstance.getKeys(StorageKeyKeys.checkoutAccessTokenKey)!,
          data['data']['coreToken'],
        );
        gokwik.options.headers[cdnConfigInstance.getHeader(APIHeaderKeys.checkoutAccessToken)!] =
          data['data']['coreToken'];
      }

      if (data['data']?['kpToken'] != null) {
        // Store KP token
        await cacheInstance.setValue(
          cdnConfigInstance.getKeys(StorageKeyKeys.gkKpToken)!,
          data['data']['kpToken'],
        );
      }

      // If email exists and auth is required, return early
      if (data['data']?['email'] != null && data['data']?['authRequired'] == true) {
        return data;
      }

      // Get customer intelligence
      final responseForAffluence = await ApiService.customerIntelligence();

      // Handle DISABLED or ENABLED state with email
      if ((data['data']?['state'] == 'DISABLED' || data['data']?['state'] == 'ENABLED') &&
          data['data']?['email'] != null) {
        final multipassResponse = await ShopifyService.getShopifyMultipassToken(
          phone: phone,
          email: data['data']['email'],
          id: data['data']['shopifyCustomerId'],
          state: data['data']['state'],
        );

        if (multipassResponse['data']?['accountActivationUrl'] != null &&
            multipassResponse['data']?['shopifyCustomerId'] != null) {
          final accountActivationUrl = multipassResponse['data']['accountActivationUrl'] as String;
          final activationUrlParts = accountActivationUrl.split('/');
          final token = activationUrlParts.last;

          final merchantConfigJSON = await cacheInstance.getValue(
            cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantConfig)!
          );
          
          if (merchantConfigJSON != null) {
            final merchant = jsonDecode(merchantConfigJSON);
            await ApiService.activateUserAccount(
              multipassResponse['data']['shopifyCustomerId'],
              merchant['host'],
              multipassResponse['data']['password'],
              token,
            );
          }
        }

        if (responseForAffluence.isSuccess && responseForAffluence.getDataOrThrow() != null) {
          multipassResponse['data']['customer_insights'] = responseForAffluence.getDataOrThrow();
        }

        await SnowplowTrackerService.sendCustomEventToSnowPlow({
          'category': 'login_modal',
          'action': 'logged_in',
          'label': 'phone_Number_logged_in',
          'property': 'phone_number',
          'value': int.tryParse(phone),
        });

        return multipassResponse;
      }

      // Handle case with email but no specific state
      if (data['data']?['email'] != null) {
        final multipassResponse = await ShopifyService.getShopifyMultipassToken(
          phone: phone,
          email: data['data']['email'],
          id: data['data']['shopifyCustomerId'],
        );

        await SnowplowTrackerService.sendCustomEventToSnowPlow({
          'category': 'login_modal',
          'action': 'logged_in',
          'label': 'phone_Number_logged_in',
          'property': 'phone_number',
          'value': int.tryParse(phone),
        });

        if (responseForAffluence.isSuccess && responseForAffluence.getDataOrThrow() != null) {
          multipassResponse['data']['customer_insights'] = responseForAffluence.getDataOrThrow();
        }

        return multipassResponse;
      }

      // Default case: store user data and return
      final userData = {
        ...data['data'],
        'phone': phone,
      };

      await cacheInstance.setValue(
        cdnConfigInstance.getKeys(StorageKeyKeys.gkVerifiedUserKey)!,
        jsonEncode(userData),
      );

      if (responseForAffluence.isSuccess && responseForAffluence.getDataOrThrow() != null) {
        data['data']['customer_insights'] = responseForAffluence.getDataOrThrow();
      }

      await SnowplowTrackerService.sendCustomEventToSnowPlow({
        'category': 'login_modal',
        'action': 'logged_in',
        'label': 'phone_Number_logged_in',
        'property': 'phone_number',
        'value': int.tryParse(phone),
      });

      return data;
    }

    // For non-Shopify merchants, just return the data
    return data;
  }

  Future<void> handleOtpSend() async {
    if (!formKey.currentState!.validate()) return;
    emit(state.copyWith(isLoading: true));
    try {
      if (state.lastSubmittedPhone != null &&
          state.lastSubmittedPhone == phoneController.text.trim()) {
        emit(state.copyWith(otpSent: true, isLoading: false));
        return;
      }

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

      if (onAnalytics != null) {
        onAnalytics!(
          cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginPhone)!,
          {
            'phone': phoneController.text.toString(),
          },
        );
      }
      emit(state.copyWith(
        otpSent: true,
        isLoading: false,
        lastSubmittedPhone: phoneController.text.trim(),
      ));
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

      if (!response['data'].containsKey('phone')) {
        response['data']['phone'] = phoneController.text;
      }
      emit(state.copyWith(isSuccess: true, isLoading: false));
      if (onAnalytics != null) {
        onAnalytics!(
          cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
          {
            'phone': phoneController.text.toString(),
            'email': shopifyEmailController.text,
            'customer_id': response['data']['shopifyCustomerId']?.toString() ?? ""
          },
        );
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
      onErrorData?.call(FlowResult(
        flowType: FlowType.emailOtpVerify,
        error: (err as Failure).message,
      ));
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
      final responses =
          ((await ApiService.verifyCode(phoneController.text, otp))
              .getDataOrThrow());

      // Convert to Map for consistent handling
      final responseMap = responses is Map
          ? Map<String, dynamic>.from(responses)
          : responses.toJson();

      // Check if merchant type is shopify or custom_shopify
      final merchantTypeString =
          await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantTypeKey)!);
      final isShopifyOrCustomShopify =
          merchantTypeString == "shopify" ||
              merchantTypeString == "custom_shopify";

      // Handle Shopify merchant type
      if (isShopifyOrCustomShopify) {
        // shopify customer id
        if (responseMap.containsKey('data')) {
          if (!responseMap['data'].containsKey('phone')) {
            responseMap['data']['phone'] = phoneController.text;
          }
          if (responseMap['data'].containsKey('shopifyCustomerId')) {
            emit(state.copyWith(
              shopifyCustomerId:
                  responseMap['data']['shopifyCustomerId']?.toString(),
            ));
          }
        }
        if (!responseMap.containsKey('phone')) {
          responseMap['phone'] = phoneController.text;
        }
        // Handle auth required condition
        if (responseMap.containsKey('authRequired')) {
          if (responseMap['authRequired'] == true &&
              responseMap['email'] != null) {
            shopifyEmailController.text = responseMap['email'];
            otpController.clear();
            otpController.text = "";
            shopifyOtpController.clear();
            shopifyOtpController.text = "";

            try {
              await ShopifyService.shopifySendEmailVerificationCode(
                  responseMap['email']);

              emit(state.copyWith(
                lastSubmittedEmail: responseMap['email'],
                emailOtpSent: true,
                isNewUser: false,
                isLoading: false,
              ));
              return;
            } catch (err) {
              emit(state.copyWith(
                error: SingleUseData((err as Failure).message),
                isLoading: false,
              ));
              return;
            }
          }
        }

        if (responseMap.containsKey('email')) {
          if (responseMap != null) {
            responseMap!.remove('state');
            responseMap!.remove('accountActivationUrl');
          }
          emit(state.copyWith(isSuccess: true, isLoading: false));
          if (onAnalytics != null) {
            onAnalytics!(
              cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
              {
                'phone': phoneController.text.toString(),
                'email': responseMap['email'],
                'customer_id':
                responseMap['shopifyCustomerId']?.toString() ?? ""
              },
            );
          }
          onSuccessData?.call(
            FlowResult(flowType: FlowType.otpVerify, data: responseMap),
          );
          return;
        }

        // Handle multiple emails
        if (responseMap.containsKey('multipleEmail') &&
            responseMap['multipleEmail'] != null &&
            responseMap['multipleEmail'] != "null") {
          emit(state.copyWith(
            multipleEmails: (responseMap['multipleEmail'] as String?)
                ?.split(',')
                .map((item) {
              return MultipleEmail(label: item.trim(), value: item.trim());
            }).toList(),
          ));
          emit(state.copyWith(
            isNewUser: true,
            isLoading: false,
          ));
          return;
        }

        // Handle multiple emails
        if (responseMap.containsKey('multipleEmail') &&
            responseMap['multipleEmail'] != null &&
            responseMap['multipleEmail'] != "null") {
          emit(state.copyWith(
            multipleEmails: (responseMap['multipleEmail'] as String?)
                ?.split(',')
                .map((item) {
              return MultipleEmail(label: item.trim(), value: item.trim());
            }).toList(),
          ));
        }

        // Handle email required case
        if (responseMap.containsKey('emailRequired')) {
          if (responseMap['emailRequired'] == true) {
            emit(state.copyWith(
              isNewUser: true,
              isLoading: false,
            ));
            otpController.clear();
            return;
          }
        }

        emit(state.copyWith(isSuccess: true, isLoading: false));
        if (onAnalytics != null) {
          onAnalytics!(
            cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
            {
              'phone': phoneController.text.toString(),
              'email': responseMap['data']['email'],
              'customer_id':
                  responseMap['data']['shopifyCustomerId']?.toString() ?? ""
            },
          );
        }
        onSuccessData?.call(
          FlowResult(flowType: FlowType.otpVerify, data: responseMap['data']),
        );
        // otpController.clear();
        return;
      }

      // Handle email required case
      if (responseMap['emailRequired'] == true &&
          responseMap['email'] == "null") {
        emit(state.copyWith(
          isNewUser: true,
          isLoading: false,
        ));
        otpController.clear();
        return;
      }

      // Handle merchant response
      if (responseMap.containsKey('merchantResponse') &&
          responseMap['merchantResponse'] is Map &&
          responseMap['merchantResponse'].containsKey('email') &&
          responseMap['merchantResponse']['email'] != "null") {
        // Set phone if not present
        if (responseMap['merchantResponse']['phone'] == null) {
          responseMap['merchantResponse']['phone'] = phoneController.text;
        }

        if (onAnalytics != null) {
          onAnalytics!(
            cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
            {
              'phone': phoneController.text.toString(),
              'email': responseMap['merchantResponse']['email'],
              'customer_id': responseMap['data']['id']?.toString() ?? ""
            },
          );
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
    emit(state.copyWith(
      otpSent: false,
      isNewUser: false,
      error: null,
      lastSubmittedPhone: null,
    ));
  }

  void handleEmailChange() {
    emit(state.copyWith(
      emailOtpSent: false,
      isNewUser: true,
      error: null,
      lastSubmittedEmail: null,
    ));
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

      // final responseMap = response.getDataOrThrow()

      // onAnalytics!(AnalyticsEvents.appLoginSuccess, {
      //   'phone': phoneController.text.toString(),
      //   'email': responseMap?['data']['merchantResponse']['email'],
      //   'customer_id': responseMap?['data']['merchantResponse']['id']?.toString() ?? ""
      // });
      onSuccessData?.call(FlowResult(
          flowType: FlowType.createUser, data: response.getDataOrThrow()));
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
      // Check if the submitted email matches the previous submitted email
      if (state.lastSubmittedEmail != null &&
          state.lastSubmittedEmail == email.trim()) {
        emit(state.copyWith(emailOtpSent: true, isLoading: false));
        return;
      }
      // Validate disposable email
      final isValidEmail = await ShopifyService.validateDisposableEmail(email);

      if (!isValidEmail) {
        emit(state.copyWith(isLoading: false));
        const errorMessage = 'Entered email is not valid';
        emit(state.copyWith(
            error: SingleUseData(errorMessage),
            isLoading: false,
            emailOtpSent: false));
        onErrorData?.call(
            FlowResult(flowType: FlowType.emailOtpSend, error: errorMessage));
        return;
      }

      // Check if user is new by calling customerShopifySession
      Map<String, dynamic>? responseToCheckIfUserIsNew;
      if (email.isNotEmpty && state.multipleEmails.isEmpty) {
        try {
          responseToCheckIfUserIsNew =
              await ShopifyService.customerShopifySession(
            email: email,
            shopifyCustomerId: state.shopifyCustomerId ??
                "", // Use saved shopifyCustomerId if available
            isMarketingEventSubscribed: state.notifications,
          );
        } catch (err) {
          // If customerShopifySession fails, continue with normal flow
        }
      }

      if (responseToCheckIfUserIsNew?['data']?['isNewUser'] == true) {
        if (onAnalytics != null) {
          onAnalytics!(
            cdnConfigInstance.getAnalyticsEvent(AnalyticsEventKeys.appLoginSuccess)!,
            {
              'email': email,
              'phone': phoneController.text.toString(),
              'customer_id': responseToCheckIfUserIsNew?['data']
                          ?['shopifyCustomerId']
                      ?.toString() ??
                  "",
            },
          );
        }
        if (responseToCheckIfUserIsNew!.containsKey('data')) {
          if (!responseToCheckIfUserIsNew['data'].containsKey('phone')) {
            responseToCheckIfUserIsNew['data']['phone'] =
                phoneController.text.toString();
          }
        }
        onSuccessData?.call(FlowResult(
          flowType: FlowType.emailOtpSend,
          data: responseToCheckIfUserIsNew?['data'],
        ));
        emit(state.copyWith(isSuccess: true, isLoading: false));
        return;
      }

      await ShopifyService.shopifySendEmailVerificationCode(email);

      emit(state.copyWith(
          emailOtpSent: true,
          isNewUser: false,
          isLoading: false,
          lastSubmittedEmail: email.trim()));
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
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantTypeKey)!);
    if (merchantType != null) {
      emit(state.copyWith(
          merchantType: merchantType == 'shopify'
              ? MerchantType.shopify
              : merchantType == 'custom_shopify'
                  ? MerchantType.custom_shopify
                  : MerchantType.custom));
    }
  }

  void _listenUserStateUpdated() {
    onUserStateUpdated();
  }

  Future<void> onMerchantTypeUpdated() async {
    final merchantType =
        await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMerchantTypeKey)!);
    if (merchantType != null) {
      emit(state.copyWith(
          merchantType: merchantType == 'shopify'
              ? MerchantType.shopify
              : merchantType == 'custom_shopify'
                  ? MerchantType.custom_shopify
                  : MerchantType.custom));
    }
  }

  Future<void> onUserStateUpdated() async {
    final response = await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkVerifiedUserKey)!);
    if (response == null) {
      // onErrorData?.call(FlowResult(
      //     flowType: FlowType.notLoggedIn, error: 'User Not Logged In'));
      return;
    }

    final Map<String, dynamic> responseData = jsonDecode(response);

    final isShopifyOrCustomShopify =
        state.merchantType == "shopify" ||
            state.merchantType == "custom_shopify";

    if (isShopifyOrCustomShopify) {
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
          ) ||
          (responseData['shopifyCustomerId'] != null &&
              responseData['phone'] != null &&
              responseData['email'] != null)) {
        onSuccessData?.call(
            FlowResult(flowType: FlowType.alreadyLoggedIn, data: responseData));
        emit(state.copyWith(isUserLoggedIn: true));
        if (onAnalytics != null) {
          // onAnalytics!(
          //   cdnConfigInstance.getAnalyticsEventOrDefault(AnalyticsEvents.appIdentifiedUser),
          //   {
          //     'phone': responseData['phone'],
          //     'email': responseData['email'],
          //     'customer_id':
          //         responseData['shopifyCustomerId'] ?? (responseData['id'] ?? ""),
          //   },
          // );
        }
        return;
      }
    }

    if (state.merchantType == "custom") {
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
      final mode = await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkMode)!);
      final isDev = mode == 'debug';

      if (isDev) {
        final requestId =
            await cacheInstance.getValue(cdnConfigInstance.getKeys(StorageKeyKeys.gkRequestIdKey)!);
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
