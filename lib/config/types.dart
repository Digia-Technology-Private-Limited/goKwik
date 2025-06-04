enum Environment {
  sandbox,
  production,
}

enum MerchantType {
  shopify,
  custom,
}

class InitializeSdkProps {
  final String mid;
  final Environment environment; // 'sandbox' or 'production'
  final String? shopDomain;
  final bool? isSnowplowTrackingEnabled;
  final MerchantType? merchantType; // 'shopify' or 'custom'
  final String? kcMerchantId;
  final String? kcMerchantToken;
  final String? mode; // 'debug' or 'release'

  InitializeSdkProps({
    required this.mid,
    required this.environment,
    this.shopDomain,
    this.isSnowplowTrackingEnabled,
    this.merchantType,
    this.kcMerchantId,
    this.kcMerchantToken,
    this.mode,
  });
}

class SendVerificationCodeProps {
  final String phoneNumber;
  final bool notifications;

  SendVerificationCodeProps({
    required this.phoneNumber,
    required this.notifications,
  });
}

class VerifyCodeProps {
  final String phoneNumber;
  final String code;

  VerifyCodeProps({
    required this.phoneNumber,
    required this.code,
  });
}

class Token {
  final bool isValid;

  Token({required this.isValid});
}

class TokenData {
  final bool isExpired;
  final bool isValid;
  final String jwe;

  TokenData({
    required this.isExpired,
    required this.isValid,
    required this.jwe,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      isExpired: json['isExpired'] ?? false,
      isValid: json['isValid'] ?? false,
      jwe: json['jwe'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isExpired': isExpired,
      'isValid': isValid,
      'jwe': jwe,
    };
  }
}

class VerifyCodeResponseData {
  final String? kpToken;
  final String? token;
  final String? coreToken;

  VerifyCodeResponseData({this.kpToken, this.token, this.coreToken});

  factory VerifyCodeResponseData.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponseData(
      kpToken: json['kpToken'],
      token: json['token'],
      coreToken: json['coreToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kpToken': kpToken,
      'token': token,
      'coreToken': coreToken,
    };
  }
}

class VerifyCodeResponse {
  final VerifyCodeResponseData data;
  final String error;
  final bool isSuccess;
  final int statusCode;
  final bool success;
  final int timestamp;

  VerifyCodeResponse({
    required this.data,
    required this.error,
    required this.isSuccess,
    required this.statusCode,
    required this.success,
    required this.timestamp,
  });
}

class OtpSentResponseData {
  final int interval;
  final bool otpRequired;
  final String? token;
  final String userType;

  OtpSentResponseData({
    required this.interval,
    required this.otpRequired,
    this.token,
    required this.userType,
  });

  factory OtpSentResponseData.fromJson(Map<String, dynamic> json) {
    return OtpSentResponseData(
      interval: json['interval'],
      otpRequired: json['otp_required'],
      token: json['token'],
      userType: json['user_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'otp_required': otpRequired,
      'token': token,
      'user_type': userType,
    };
  }
}

class OtpSentResponse {
  final OtpSentResponseData data;
  final String error;
  final bool isSuccess;
  final int statusCode;
  final bool success;
  final int timestamp;

  OtpSentResponse({
    required this.data,
    required this.error,
    required this.isSuccess,
    required this.statusCode,
    required this.success,
    required this.timestamp,
  });

  factory OtpSentResponse.fromJson(Map<String, dynamic> json) {
    return OtpSentResponse(
      data: OtpSentResponseData(
        interval: json['interval'],
        otpRequired: json['otp_required'],
        token: json['token'],
        userType: json['user_type'],
      ),
      error: json['error'],
      isSuccess: json['isSuccess'],
      statusCode: json['status_code'],
      success: json['success'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'interval': data.interval,
        'otpRequired': data.otpRequired,
        'token': data.token,
        'userType': data.userType,
      },
      'error': error,
      'isSuccess': isSuccess,
      'statusCode': statusCode,
      'success': success,
      'timestamp': timestamp,
    };
  }
}

class LoginResponse {
  final LoginResponseData data;
  final bool success;
  final int statusCode;
  final int timestamp;
  final bool isSuccess;
  final String error;

  LoginResponse({
    required this.data,
    required this.success,
    required this.statusCode,
    required this.timestamp,
    required this.isSuccess,
    required this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      data: LoginResponseData(
        phone: json['data']['phone'],
        emailRequired: json['data']['emailRequired'],
        email: json['data']['email'],
        merchantResponse: MerchantResponse(
          email: json['data']['merchantResponse']['email'],
          id: json['data']['merchantResponse']['id'],
          token: json['data']['merchantResponse']['token'],
          refreshToken: json['data']['merchantResponse']['refreshToken'],
          csrfToken: json['data']['merchantResponse']['csrfToken'],
        ),
        isSuccess: json['data']['isSuccess'],
        message: json['data']['message'],
      ),
      success: json['success'],
      statusCode: json['statusCode'],
      timestamp: json['timestamp'],
      isSuccess: json['isSuccess'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'phone': data.phone,
        'emailRequired': data.emailRequired,
        'email': data.email,
        'merchantResponse': {
          'email': data.merchantResponse.email,
          'id': data.merchantResponse.id,
          'token': data.merchantResponse.token,
          'refreshToken': data.merchantResponse.refreshToken,
          'csrfToken': data.merchantResponse.csrfToken,
        },
        'isSuccess': data.isSuccess,
        'message': data.message,
      },
      'success': success,
      'statusCode': statusCode,
      'timestamp': timestamp,
      'isSuccess': isSuccess,
      'error': error,
    };
  }
}

class ValidateUserTokenResponseData {
  final TokenData? coreToken;
  final TokenData token;
  final String phone;
  final String? email;

  ValidateUserTokenResponseData({
    this.coreToken,
    required this.token,
    required this.phone,
    this.email,
  });

  factory ValidateUserTokenResponseData.fromJson(Map<String, dynamic> json) {
    return ValidateUserTokenResponseData(
      coreToken: json['coreToken'] != null
          ? TokenData.fromJson(json['coreToken'])
          : null,
      token: TokenData.fromJson(json['token']),
      phone: json['phone'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coreToken': coreToken?.toJson(),
      'token': token.toJson(),
      'phone': phone,
      'email': email,
    };
  }
}

class ValidateUserTokenResponse {
  final ValidateUserTokenResponseData data;
  final bool success;
  final int statusCode;
  final int timestamp;
  final bool isSuccess;
  final String error;

  ValidateUserTokenResponse({
    required this.data,
    required this.success,
    required this.statusCode,
    required this.timestamp,
    required this.isSuccess,
    required this.error,
  });

  factory ValidateUserTokenResponse.fromJson(Map<String, dynamic> json) {
    return ValidateUserTokenResponse(
      data: ValidateUserTokenResponseData.fromJson(json['data']),
      success: json['success'] ?? false,
      statusCode: json['status_code'] ?? 200,
      timestamp: json['timestamp'] ?? 0,
      isSuccess: json['isSuccess'] ?? false,
      error: json['error'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'success': success,
      'status_code': statusCode,
      'timestamp': timestamp,
      'isSuccess': isSuccess,
      'error': error,
    };
  }
}

class TrackProductEventContext {
  final String productId;
  final String imgUrl;
  final String variantId;
  final String productName;
  final String productPrice;
  final String productHandle;
  final String type;

  TrackProductEventContext({
    required this.productId,
    required this.imgUrl,
    required this.variantId,
    required this.productName,
    required this.productPrice,
    required this.productHandle,
    required this.type,
  });

  factory TrackProductEventContext.fromJson(Map<String, dynamic> json) {
    return TrackProductEventContext(
      productId: json['product_id'] ?? '',
      imgUrl: json['img_url'] ?? '',
      variantId: json['variant_id'] ?? '',
      productName: json['product_name'] ?? '',
      productPrice: json['product_price'] ?? '',
      productHandle: json['product_handle'] ?? '',
      type: json['type'] ?? 'product',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'img_url': imgUrl,
      'variant_id': variantId,
      'product_name': productName,
      'product_price': productPrice,
      'product_handle': productHandle,
      'type': type,
    };
  }
}

class TrackCollectionEventContext {
  final String collection_id;
  final String? img_url;
  final String collection_name;
  final String collection_handle;
  final String type;

  TrackCollectionEventContext({
    required this.collection_id,
    this.img_url,
    required this.collection_name,
    required this.collection_handle,
    required this.type,
  });

  factory TrackCollectionEventContext.fromJson(Map<String, dynamic> json) {
    return TrackCollectionEventContext(
      collection_id: json['collection_id'] ?? '',
      img_url: json['img_url'],
      collection_name: json['collection_name'] ?? '',
      collection_handle: json['collection_handle'] ?? '',
      type: json['type'] ?? 'collection',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection_id': collection_id,
      'img_url': img_url ?? '',
      'collection_name': collection_name,
      'collection_handle': collection_handle,
      'type': type,
    };
  }
}

class TrackProductEventArgs {
  final String cartId;
  final String productId;
  final String pageUrl;
  final String variantId;
  final String? imgUrl;
  final String? name;
  final String? price;
  final String? handle;

  TrackProductEventArgs({
    required this.cartId,
    required this.productId,
    required this.pageUrl,
    required this.variantId,
    this.imgUrl,
    this.name,
    this.price,
    this.handle,
  });

  factory TrackProductEventArgs.fromJson(Map<String, dynamic> json) {
    return TrackProductEventArgs(
      cartId: json['cart_id'] ?? '',
      productId: json['product_id'] ?? '',
      pageUrl: json['page_url'] ?? '',
      variantId: json['variant_id'] ?? '',
      imgUrl: json['img_url'],
      name: json['product_name'],
      price: json['product_price'],
      handle: json['product_handle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'product_id': productId,
      'page_url': pageUrl,
      'variant_id': variantId,
      'img_url': imgUrl,
      'product_name': name,
      'product_price': price,
      'product_handle': handle,
    };
  }
}

class TrackCartEventArgs {
  final String cartId;
  final String pageUrl;

  TrackCartEventArgs({
    required this.cartId,
    required this.pageUrl,
  });
}

class TrackCollectionsEventArgs {
  final String cartId;
  final String collectionId;
  final String name;
  final String? imageUrl;
  final String? handle;
  final String? pageUrl;

  TrackCollectionsEventArgs({
    required this.cartId,
    required this.collectionId,
    required this.name,
    this.imageUrl,
    this.handle,
    this.pageUrl,
  });

  factory TrackCollectionsEventArgs.fromJson(Map<String, dynamic> json) {
    return TrackCollectionsEventArgs(
      cartId: json['cart_id'] ?? '',
      collectionId: json['collection_id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'],
      handle: json['handle'],
      pageUrl: json['page_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'collection_id': collectionId,
      'name': name,
      'image_url': imageUrl,
      'handle': handle,
      'page_url': pageUrl,
    };
  }
}

class TrackOtherEventArgs {
  final String? cartId;
  final String pageUrl;

  TrackOtherEventArgs({
    this.cartId,
    required this.pageUrl,
  });
}

class LoginResponseData {
  final String phone;
  final bool emailRequired;
  final String email;
  final MerchantResponse merchantResponse;
  final bool isSuccess;
  final String? message;
  final dynamic affluence;

  LoginResponseData({
    required this.phone,
    required this.emailRequired,
    required this.email,
    required this.merchantResponse,
    required this.isSuccess,
    this.message,
    this.affluence,
  });

  factory LoginResponseData.fromJson(Map<String, dynamic> json) {
    return LoginResponseData(
        phone: json['phone'].toString(),
        emailRequired: json['emailRequired'],
        email: json['email'].toString(),
        merchantResponse: MerchantResponse(
          email: json['merchantResponse']['email'].toString(),
          id: json['merchantResponse']['id'].toString(),
          token: json['merchantResponse']['token'].toString(),
          refreshToken: json['merchantResponse']['refreshToken'].toString(),
          csrfToken: json['merchantResponse']['csrfToken'].toString(),
        ),
        isSuccess: json['isSuccess'],
        message: json['message'].toString(),
        affluence: json['affluence']);
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'emailRequired': emailRequired,
      'email': email,
      'merchantResponse': {
        'email': merchantResponse.email,
        'id': merchantResponse.id,
        'token': merchantResponse.token,
        'refreshToken': merchantResponse.refreshToken,
        'csrfToken': merchantResponse.csrfToken,
      },
      'isSuccess': isSuccess,
      'message': message,
      'affluence': affluence,
    };
  }
}

class MerchantResponse {
  final String email;
  final String id;
  final String token;
  final String refreshToken;
  final String csrfToken;

  MerchantResponse({
    required this.email,
    required this.id,
    required this.token,
    required this.refreshToken,
    required this.csrfToken,
  });
}

class CheckoutEventResponse {
  final String eventName;
  final CheckoutData data;

  CheckoutEventResponse({
    required this.eventName,
    required this.data,
  });
}

class CheckoutData {
  final MerchantParams merchantParams;

  CheckoutData({
    required this.merchantParams,
  });
}

class ShopifyVerifyCodeResponse {
  final ShopifyVerifyCodeData data;
  final bool success;
  final int statusCode;
  final int timestamp;
  final bool isSuccess;
  final String error;

  ShopifyVerifyCodeResponse({
    required this.data,
    required this.success,
    required this.statusCode,
    required this.timestamp,
    required this.isSuccess,
    required this.error,
  });
}

class VerifiedUser {
  final String? coreToken;
  // final Token? token;
  final String phone;
  final String? email;

  VerifiedUser({
    this.coreToken,
    // required this.token,
    required this.phone,
    this.email,
  });

  factory VerifiedUser.fromJson(Map<String, dynamic> json) {
    return VerifiedUser(
      coreToken: json['coreToken'],
      // token: Token(isValid: json['token']?['isValid']),
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coreToken': coreToken,
      // 'token': {'isValid': token.isValid},
      'phone': phone,
      'email': email,
    };
  }
}

class ShopifyVerifyCodeData {
  final dynamic affluence;
  final String email;
  final String? phone;
  final bool isNewUser;
  final String? token;
  final String? coreToken;
  final String? kpToken;
  final String? shopifyCustomerId;
  final String? state;
  final String? accountActivationUrl;

  ShopifyVerifyCodeData({
    this.affluence,
    required this.email,
    this.phone,
    required this.isNewUser,
    this.token,
    this.coreToken,
    this.kpToken,
    this.shopifyCustomerId,
    this.state,
    this.accountActivationUrl,
  });
}

class MerchantConfig {
  final int id;
  final String merchantId;
  final String name;
  final String host;
  final String platform;
  final bool kwikpassEnabled;
  final bool isWhatsappOtpLessActive;
  final bool isTruecallerActive;
  final String integrationType;
  final bool isLogoutBtnDisabled;
  final String popupBreakpoint;
  final String apiKey;
  final bool isPublicAppInstalled;
  final List<ThirdPartyServiceProvider> thirdPartyServiceProviders;
  final String kpRequestId;
  final bool customerIntelligenceEnabled;
  final dynamic customerIntelligenceMetrics;
  final String marketingPopupGlobalLimit;
  final String customerAccountsVersion;

  MerchantConfig({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.host,
    required this.platform,
    required this.kwikpassEnabled,
    required this.isWhatsappOtpLessActive,
    required this.isTruecallerActive,
    required this.integrationType,
    required this.isLogoutBtnDisabled,
    required this.popupBreakpoint,
    required this.apiKey,
    required this.isPublicAppInstalled,
    required this.thirdPartyServiceProviders,
    required this.kpRequestId,
    required this.customerIntelligenceEnabled,
    required this.customerIntelligenceMetrics,
    required this.marketingPopupGlobalLimit,
    required this.customerAccountsVersion,
  });

  factory MerchantConfig.fromJson(Map<String, dynamic> json) {
    return MerchantConfig(
      id: json['id'],
      merchantId: json['merchantId'],
      name: json['name'],
      host: json['host'],
      platform: json['platform'],
      kwikpassEnabled: json['kwikpassEnabled'],
      isWhatsappOtpLessActive: json['isWhatsappOtpLessActive'],
      isTruecallerActive: json['isTruecallerActive'],
      integrationType: json['integrationType'],
      isLogoutBtnDisabled: json['isLogoutBtnDisabled'],
      popupBreakpoint: json['popupBreakpoint'],
      apiKey: json['apiKey'],
      isPublicAppInstalled: json['isPublicAppInstalled'],
      thirdPartyServiceProviders: (json['thirdPartyServiceProviders'] as List)
          .map((e) => ThirdPartyServiceProvider.fromJson(e))
          .toList(),
      kpRequestId: json['kpRequestId'],
      customerIntelligenceEnabled: json['customerIntelligenceEnabled'],
      customerIntelligenceMetrics: json['customerIntelligenceMetrics'],
      marketingPopupGlobalLimit: json['marketingPopupGlobalLimit'],
      customerAccountsVersion: json['customerAccountsVersion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'host': host,
      'platform': platform,
      'kwikpassEnabled': kwikpassEnabled,
      'isWhatsappOtpLessActive': isWhatsappOtpLessActive,
      'isTruecallerActive': isTruecallerActive,
      'integrationType': integrationType,
      'isLogoutBtnDisabled': isLogoutBtnDisabled,
      'popupBreakpoint': popupBreakpoint,
      'apiKey': apiKey,
      'isPublicAppInstalled': isPublicAppInstalled,
      'thirdPartyServiceProviders':
          thirdPartyServiceProviders.map((e) => e.toJson()).toList(),
      'kpRequestId': kpRequestId,
      'customerIntelligenceEnabled': customerIntelligenceEnabled,
      'customerIntelligenceMetrics': customerIntelligenceMetrics,
      'marketingPopupGlobalLimit': marketingPopupGlobalLimit,
      'customerAccountsVersion': customerAccountsVersion,
    };
  }
}

class ThirdPartyServiceProvider {
  final String name;
  final String type;
  final String identifier;
  final List<dynamic> events;
  final List<dynamic> marketingEvents;
  final dynamic rules;

  ThirdPartyServiceProvider({
    required this.name,
    required this.type,
    required this.identifier,
    required this.events,
    required this.marketingEvents,
    this.rules,
  });

  factory ThirdPartyServiceProvider.fromJson(Map<String, dynamic> json) {
    return ThirdPartyServiceProvider(
      name: json['name'],
      type: json['type'],
      identifier: json['identifier'],
      events: json['events'] ?? [],
      marketingEvents: json['marketingEvents'] ?? [],
      rules: json['rules'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'identifier': identifier,
      'events': events,
      'marketingEvents': marketingEvents,
      'rules': rules,
    };
  }
}

class CheckoutShopifyProps {
  final String? cartId;
  final String? storefrontToken;
  final String? storeId;
  final String? fbPixel;
  final String? gaTrackingID;
  final String? webEngageID;
  final String? moEngageID;
  final String? sessionId;
  final Map<String, String>? utmParams;

  CheckoutShopifyProps({
    this.cartId,
    this.storefrontToken,
    this.storeId,
    this.fbPixel,
    this.gaTrackingID,
    this.webEngageID,
    this.moEngageID,
    this.sessionId,
    this.utmParams,
  });
}

class MerchantParams extends CheckoutShopifyProps {
  final String? merchantCheckoutId;

  MerchantParams({
    this.merchantCheckoutId,
    super.cartId,
    super.storefrontToken,
    super.storeId,
    super.fbPixel,
    super.gaTrackingID,
    super.webEngageID,
    super.moEngageID,
    super.sessionId,
    super.utmParams,
  });
}

class KPCheckoutProps {
  final CheckoutData checkoutData;
  final Function(dynamic)? onEvent;
  final Function(dynamic)? onError;

  KPCheckoutProps({
    required this.checkoutData,
    this.onEvent,
    this.onError,
  });
}

class CheckoutProps extends CheckoutShopifyProps {
  final String? checkoutId;
  final Function(dynamic)? onMessage;
  final Function(dynamic)? onError;

  CheckoutProps({
    this.checkoutId,
    this.onMessage,
    this.onError,
    String? cartId,
    String? storefrontToken,
    String? storeId,
    String? fbPixel,
    String? gaTrackingID,
    String? webEngageID,
    String? moEngageID,
    String? sessionId,
    Map<String, String>? utmParams,
  }) : super(
          cartId: cartId,
          storefrontToken: storefrontToken,
          storeId: storeId,
          fbPixel: fbPixel,
          gaTrackingID: gaTrackingID,
          webEngageID: webEngageID,
          moEngageID: moEngageID,
          sessionId: sessionId,
          utmParams: utmParams,
        );
}

class ApiErrorResponseData {
  final ResponseData data;
  final int status;
  final Map<String, String> headers;
  final Map<String, String> config;
  final Map<String, String> request;
  final Map<String, String> responseHeaders;

  ApiErrorResponseData({
    required this.data,
    required this.status,
    required this.headers,
    required this.config,
    required this.request,
    required this.responseHeaders,
  });
}

class ResponseData {
  final bool isSuccess;
  final String? error;
  final dynamic data;

  ResponseData({
    required this.isSuccess,
    this.error,
    this.data,
  });
}

class ApiErrorResponse {
  final String message;
  final dynamic messageLBL;
  final int? errorCode;
  final String requestId;
  final bool result;
  final dynamic? response;

  ApiErrorResponse({
    required this.message,
    this.messageLBL,
    this.errorCode,
    required this.requestId,
    this.result = false,
    this.response,
  });
}
