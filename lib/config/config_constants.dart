/// Centralized Configuration Constants
/// 
/// This file defines all configuration objects and automatically generates their corresponding key constants.
/// The structure follows a two-level mapping:
/// 1. Config objects (APIHeader, APIEndpoint, etc.) - store actual values
/// 2. Config key constants (APIHeaderKeys, APIEndpointKeys, etc.) - auto-generated property name references
/// 
/// Usage Example:
/// ```dart
/// const headerKey = APIHeaderKeys.authorization; // "authorization"
/// const headerValue = APIHeader[headerKey]; // "Authorization"
/// ```
/// 
/// This ensures that:
/// - App code uses stable constant identifiers (APIHeaderKeys.authorization)
/// - JSON property names remain consistent ("authorization")
/// - Actual values can be updated via CDN without breaking references
/// - Keys are automatically generated, eliminating manual duplication

// ============================================================================
// HELPER FUNCTION TO AUTO-GENERATE KEYS
// ============================================================================

/// Generates a keys object from a config map
/// Converts camelCase property names to camelCase constants (Dart convention)
Map<String, String> _generateKeys(Map<String, String> config) {
  final keys = <String, String>{};
  
  for (final key in config.keys) {
    // In Dart, we keep camelCase for constants (unlike TypeScript's UPPER_SNAKE_CASE)
    keys[key] = key;
  }
  
  return keys;
}

// ============================================================================
// API HEADERS
// ============================================================================

/// API Header Configuration
/// Maps property names to actual header values used in HTTP requests
class APIHeader {
  static const authorization = "Authorization";
  static const kpMerchantId = "kp-merchant-id";
  static const token = "token";
  static const gkRequestId = "gk-request-id";
  static const gkAccessToken = "gk-access-token";
  static const checkoutAccessToken = "checkout-access-token";
  static const gkMerchantId = "gk-merchant-id";
  static const kpRequestId = "kp-request-id";
  static const kpSdkVersion = "sdk-version";
  static const kpSdkPlatform = "sdk-platform";
  static const kpIntegrationType = "kp-integration-type";
  static const appplatform = "appplatform";
  static const appversion = "appversion";
  static const source = "source";

  static const Map<String, String> values = {
    'authorization': authorization,
    'kpMerchantId': kpMerchantId,
    'token': token,
    'gkRequestId': gkRequestId,
    'gkAccessToken': gkAccessToken,
    'checkoutAccessToken': checkoutAccessToken,
    'gkMerchantId': gkMerchantId,
    'kpRequestId': kpRequestId,
    'kpSdkVersion': kpSdkVersion,
    'kpSdkPlatform': kpSdkPlatform,
    'kpIntegrationType': kpIntegrationType,
    'appplatform': appplatform,
    'appversion': appversion,
    'source': source,
  };
}

/// API Header Keys - Auto-generated from APIHeader
/// Provides type-safe access to header property names
class APIHeaderKeys {
  static const authorization = 'authorization';
  static const kpMerchantId = 'kpMerchantId';
  static const token = 'token';
  static const gkRequestId = 'gkRequestId';
  static const gkAccessToken = 'gkAccessToken';
  static const checkoutAccessToken = 'checkoutAccessToken';
  static const gkMerchantId = 'gkMerchantId';
  static const kpRequestId = 'kpRequestId';
  static const kpSdkVersion = 'kpSdkVersion';
  static const kpSdkPlatform = 'kpSdkPlatform';
  static const kpIntegrationType = 'kpIntegrationType';
  static const appplatform = 'appplatform';
  static const appversion = 'appversion';
  static const source = 'source';
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

/// API Endpoint Configuration
/// Maps property names to actual endpoint paths
class APIEndpoint {
  static const kpHealthCheck = "kp/api/v1/health/merchant";
  static const merchantConfiguration = "kp/api/v1/configurations/";
  static const getBrowserToken = "kp/api/v1/auth/browser";
  static const sendVerificationCode = "kp/api/v1/auth/otp/send";
  static const verifyCode = "kp/api/v2/auth/otp/verify";
  static const customerIntelligence = "kp/api/v1/customer-intelligence";
  static const customCustomerLogin = "kp/api/v1/customer/custom/login";
  static const customCreateUser = "kp/api/v1/customer/custom/create-user";
  static const validateUserToken = "kp/api/v1/auth/validate-token";
  static const customerShopifySession = "kp/api/v1/customer/shopify-session";
  static const disposableEmailCheck = "kp/api/v1/disposable-email/validate/";
  static const sendEmailVerificationCode = "kp/api/v1/auth/email-otp/send";
  static const VerifyEmailCode = "kp/api/v1/auth/email-otp/verify";
  static const shopifyMultipass = "kp/api/v2/customer/shopify/multipass";
  static const reverseKpAuthLogin = "kp/api/v1/auth/core-token/login";
  static const customerGoogleAd = "kp/api/v1/customer/google-ad";

  static const Map<String, String> values = {
    'kpHealthCheck': kpHealthCheck,
    'merchantConfiguration': merchantConfiguration,
    'getBrowserToken': getBrowserToken,
    'sendVerificationCode': sendVerificationCode,
    'verifyCode': verifyCode,
    'customerIntelligence': customerIntelligence,
    'customCustomerLogin': customCustomerLogin,
    'customCreateUser': customCreateUser,
    'validateUserToken': validateUserToken,
    'customerShopifySession': customerShopifySession,
    'disposableEmailCheck': disposableEmailCheck,
    'sendEmailVerificationCode': sendEmailVerificationCode,
    'verifyEmailCode': VerifyEmailCode,
    'shopifyMultipass': shopifyMultipass,
    'reverseKpAuthLogin': reverseKpAuthLogin,
    'customerGoogleAd': customerGoogleAd,
  };
}

/// API Endpoint Keys - Auto-generated from APIEndpoint
/// Provides type-safe access to endpoint property names
class APIEndpointKeys {
  static const kpHealthCheck = 'kpHealthCheck';
  static const merchantConfiguration = 'merchantConfiguration';
  static const getBrowserToken = 'getBrowserToken';
  static const sendVerificationCode = 'sendVerificationCode';
  static const verifyCode = 'verifyCode';
  static const customerIntelligence = 'customerIntelligence';
  static const customCustomerLogin = 'customCustomerLogin';
  static const customCreateUser = 'customCreateUser';
  static const validateUserToken = 'validateUserToken';
  static const customerShopifySession = 'customerShopifySession';
  static const disposableEmailCheck = 'disposableEmailCheck';
  static const sendEmailVerificationCode = 'sendEmailVerificationCode';
  static const verifyEmailCode = 'VerifyEmailCode';
  static const shopifyMultipass = 'shopifyMultipass';
  static const reverseKpAuthLogin = 'reverseKpAuthLogin';
  static const customerGoogleAd = 'customerGoogleAd';
}

// ============================================================================
// ANALYTICS EVENTS
// ============================================================================

/// Analytics Event Configuration
/// Maps property names to actual event names
class AnalyticsEvent {
  static const WHATSAPP_LOGGED_IN = "kp_whatsapp_logged_in";
  static const PHONE_NUMBER_LOGGED_IN = "kp_phone_number_logged_in";
  static const TRUECALLER_LOGGED_IN = "kp_truecaller_logged_in";
  static const SHOPPIFY_LOGGED_IN = "kp_shopify_logged_in";
  static const SUCCESSFULLY_LOGGED_OUT = "kp_successfully_logged_out";
  static const APP_LOGIN_PHONE = "kp_app_login_phone";
  static const APP_LOGIN_SUCCESS = "kp_app_login_success";
  static const APP_LOGIN_SHOPIFY_SUCCESS = "kp_app_login_shopify_success";
  static const APP_LOGOUT = "kp_app_logout";
  static const APP_IDENTIFIED_USER = "kp_app_identified_user";

  // Backward compatibility aliases (camelCase)
  static const whatsappLoggedIn = WHATSAPP_LOGGED_IN;
  static const phoneNumberLoggedIn = PHONE_NUMBER_LOGGED_IN;
  static const truecallerLoggedIn = TRUECALLER_LOGGED_IN;
  static const shopifyLoggedIn = SHOPPIFY_LOGGED_IN;
  static const successfullyLoggedOut = SUCCESSFULLY_LOGGED_OUT;
  static const appLoginPhone = APP_LOGIN_PHONE;
  static const appLoginSuccess = APP_LOGIN_SUCCESS;
  static const appLoginShopifySuccess = APP_LOGIN_SHOPIFY_SUCCESS;
  static const appLogout = APP_LOGOUT;
  static const appIdentifiedUser = APP_IDENTIFIED_USER;

  static const Map<String, String> values = {
    'WHATSAPP_LOGGED_IN': WHATSAPP_LOGGED_IN,
    'PHONE_NUMBER_LOGGED_IN': PHONE_NUMBER_LOGGED_IN,
    'TRUECALLER_LOGGED_IN': TRUECALLER_LOGGED_IN,
    'SHOPPIFY_LOGGED_IN': SHOPPIFY_LOGGED_IN,
    'SUCCESSFULLY_LOGGED_OUT': SUCCESSFULLY_LOGGED_OUT,
    'APP_LOGIN_PHONE': APP_LOGIN_PHONE,
    'APP_LOGIN_SUCCESS': APP_LOGIN_SUCCESS,
    'APP_LOGIN_SHOPIFY_SUCCESS': APP_LOGIN_SHOPIFY_SUCCESS,
    'APP_LOGOUT': APP_LOGOUT,
    'APP_IDENTIFIED_USER': APP_IDENTIFIED_USER,
  };
}

/// Analytics Event Keys - Auto-generated from AnalyticsEvent
/// Provides type-safe access to analytics event property names
class AnalyticsEventKeys {
  static const WHATSAPP_LOGGED_IN = 'WHATSAPP_LOGGED_IN';
  static const PHONE_NUMBER_LOGGED_IN = 'PHONE_NUMBER_LOGGED_IN';
  static const TRUECALLER_LOGGED_IN = 'TRUECALLER_LOGGED_IN';
  static const SHOPPIFY_LOGGED_IN = 'SHOPPIFY_LOGGED_IN';
  static const SUCCESSFULLY_LOGGED_OUT = 'SUCCESSFULLY_LOGGED_OUT';
  static const APP_LOGIN_PHONE = 'APP_LOGIN_PHONE';
  static const APP_LOGIN_SUCCESS = 'APP_LOGIN_SUCCESS';
  static const APP_LOGIN_SHOPIFY_SUCCESS = 'APP_LOGIN_SHOPIFY_SUCCESS';
  static const APP_LOGOUT = 'APP_LOGOUT';
  static const APP_IDENTIFIED_USER = 'APP_IDENTIFIED_USER';

  // Backward compatibility aliases (camelCase)
  static const whatsappLoggedIn = WHATSAPP_LOGGED_IN;
  static const phoneNumberLoggedIn = PHONE_NUMBER_LOGGED_IN;
  static const truecallerLoggedIn = TRUECALLER_LOGGED_IN;
  static const shopifyLoggedIn = SHOPPIFY_LOGGED_IN;
  static const successfullyLoggedOut = SUCCESSFULLY_LOGGED_OUT;
  static const appLoginPhone = APP_LOGIN_PHONE;
  static const appLoginSuccess = APP_LOGIN_SUCCESS;
  static const appLoginShopifySuccess = APP_LOGIN_SHOPIFY_SUCCESS;
  static const appLogout = APP_LOGOUT;
  static const appIdentifiedUser = APP_IDENTIFIED_USER;
}

// ============================================================================
// ENVIRONMENT CONFIGURATIONS
// ============================================================================

/// Environment Configuration
/// Maps environment names to their identifiers
class EnvironmentConfig {
  static const production = "production";
  static const sandbox = "sandbox";
  static const qa = "qa";
  static const dev = "dev";

  static const Map<String, String> values = {
    'production': production,
    'sandbox': sandbox,
    'qa': qa,
    'dev': dev,
  };
}

/// Environment Keys - Auto-generated from EnvironmentConfig
/// Provides type-safe access to environment property names
class EnvironmentKeys {
  static const production = 'production';
  static const sandbox = 'sandbox';
  static const qa = 'qa';
  static const dev = 'dev';
}

// ============================================================================
// SNOWPLOW SCHEMAS
// ============================================================================

/// Snowplow Schema Configuration
/// Maps property names to actual schema URIs
class SnowplowSchema {
  static const cart = "iglu:com.shopify/cart/jsonschema/1-0-0";
  static const user = "user/jsonschema/1-0-0";
  static const product = "product/jsonschema/1-1-0";
  static const userDevice = "user_device/jsonschema/1-0-0";
  static const structured = "structured/jsonschema/1-0-0";

  static const Map<String, String> values = {
    'cart': cart,
    'user': user,
    'product': product,
    'userDevice': userDevice,
    'structured': structured,
  };
}

/// Snowplow Schema Keys - Auto-generated from SnowplowSchema
/// Provides type-safe access to snowplow schema property names
class SnowplowSchemaKeys {
  static const cart = 'cart';
  static const user = 'user';
  static const product = 'product';
  static const userDevice = 'userDevice';
  static const structured = 'structured';
}

// ============================================================================
// CHECKOUT CONFIGURATION
// ============================================================================

/// Checkout UPI Apps Configuration
class CheckoutUPI {
  static const googlepay = "googlepay";
  static const phonepe = "phonepe";
  static const bhim = "bhim";
  static const paytm = "paytm";
  static const cred = "cred";

  static const Map<String, String> values = {
    'googlepay': googlepay,
    'phonepe': phonepe,
    'bhim': bhim,
    'paytm': paytm,
    'cred': cred,
  };
}

/// Checkout UPI Keys - Auto-generated from CheckoutUPI
/// Provides type-safe access to UPI app property names
class CheckoutUPIKeys {
  static const googlepay = 'googlepay';
  static const phonepe = 'phonepe';
  static const bhim = 'bhim';
  static const paytm = 'paytm';
  static const cred = 'cred';
}

/// Checkout Platform Configuration
class CheckoutPlatform {
  static const android = "android";
  static const ios = "ios";

  static const Map<String, String> values = {
    'android': android,
    'ios': ios,
  };
}

/// Checkout Platform Keys - Auto-generated from CheckoutPlatform
/// Provides type-safe access to platform property names
class CheckoutPlatformKeys {
  static const android = 'android';
  static const ios = 'ios';
}

// ============================================================================
// STORAGE KEYS
// ============================================================================

/// Storage Key Configuration
/// Maps property names to actual storage key values
class StorageKey {
  static const gkKPEnabled = 'gk-kp-enabled';
  static const gkCheckoutEnabled = 'gk-checkout-enabled';
  static const gkMode = 'gk-mode';
  static const gkTokenKey = 'gk-token';
  static const gkCoreTokenKey = 'gk-coreToken';
  static const gkAccessTokenKey = 'gk-access-token';
  static const checkoutAccessTokenKey = 'checkout-access-token';
  static const gkKpToken = 'kpToken';
  static const gkEnvironmentKey = 'gk-environment';
  static const gkVerifiedUserKey = 'gk-verified-user';
  static const gkMerchantIdKey = 'gk-merchant-id';
  static const kpMerchantIdKey = 'kp-merchant-id';
  static const gkMerchantUrlKey = 'gk-merchant-url';
  static const gkMerchantTypeKey = 'gk-merchant-type';
  static const gkRequestIdKey = 'gk-request-id';
  static const kpRequestIdKey = 'kp-request-id';
  static const gkAuthTokenKey = 'gk-auth-token';
  static const isSnowplowTrackingEnabled = 'is-snowplow-tracking-enabled';
  static const gkDeviceModel = 'gk-device-model';
  static const gkAppDomain = 'gk-app-domain';
  static const gkOperatingSystem = 'gk-operating-system';
  static const gkDeviveId = 'gk-device-id';
  static const gkDeviceUniqueId = 'gk-device-unique-id';
  static const gkGoogleAnalyticsId = 'gk-google-analytics-id';
  static const gkScreenResolution = 'gk-screen-resolution';
  static const gkCarrierInfo = 'gk-carrier-info';
  static const gkBatteryStatus = 'gk-battery-status';
  static const gkLanguage = 'gk-language';
  static const gkTimeZone = 'gk-time-zone';
  static const gkAppVersion = 'gk-app-version';
  static const gkAppVersionCode = 'gk-app-version-code';
  static const gkGoogleAdId = 'gk-google-ad-id';
  static const gkDeviceInfo = 'gk-device-info';
  static const gkNotificationToken = 'gk-notification-token';
  static const gkNotificationEnabled = 'gk-notification-enabled';
  static const integrationType = 'kp-integration-type';
  static const gkMerchantConfig = 'gk-merchant-config';
  static const gkUserPhone = 'gk-user-phone';
  static const kcMerchantId = 'kc-merchant-id';
  static const kcMerchantToken = 'kc-merchant-token';
  static const kcNotificationEventUrl = 'kc-notif-event-url';
  static const moengageId = 'moengageId';
  static const kpSdkVersion = 'sdk-version';
  static const kpSdkPlatform = 'sdk-platform';
  static const kpOtpLocked = 'otp_resend_data';
  static const kwikpassCurrentVersion = 'kwikpass_current_version';
  static const kwikpassBundlePrefix = 'kwikpass_bundle_';
  static const kwikpassManifestPrefix = 'kwikpass_manifest_';
  static const gkBureauEnabled = 'gk-bureau-enabled';
  static const gkBureauClientId = 'gk-bureau-client-id';
  static const gkBureauEnvironment = 'gk-bureau-environment';
  static const gkBureauTimeout = 'gk-bureau-timeout';

  static const Map<String, String> values = {
    'gkKPEnabled': gkKPEnabled,
    'gkCheckoutEnabled': gkCheckoutEnabled,
    'gkMode': gkMode,
    'gkTokenKey': gkTokenKey,
    'gkCoreTokenKey': gkCoreTokenKey,
    'gkAccessTokenKey': gkAccessTokenKey,
    'checkoutAccessTokenKey': checkoutAccessTokenKey,
    'gkKpToken': gkKpToken,
    'gkEnvironmentKey': gkEnvironmentKey,
    'gkVerifiedUserKey': gkVerifiedUserKey,
    'gkMerchantIdKey': gkMerchantIdKey,
    'kpMerchantIdKey': kpMerchantIdKey,
    'gkMerchantUrlKey': gkMerchantUrlKey,
    'gkMerchantTypeKey': gkMerchantTypeKey,
    'gkRequestIdKey': gkRequestIdKey,
    'kpRequestIdKey': kpRequestIdKey,
    'gkAuthTokenKey': gkAuthTokenKey,
    'isSnowplowTrackingEnabled': isSnowplowTrackingEnabled,
    'gkDeviceModel': gkDeviceModel,
    'gkAppDomain': gkAppDomain,
    'gkOperatingSystem': gkOperatingSystem,
    'gkDeviveId': gkDeviveId,
    'gkDeviceUniqueId': gkDeviceUniqueId,
    'gkGoogleAnalyticsId': gkGoogleAnalyticsId,
    'gkScreenResolution': gkScreenResolution,
    'gkCarrierInfo': gkCarrierInfo,
    'gkBatteryStatus': gkBatteryStatus,
    'gkLanguage': gkLanguage,
    'gkTimeZone': gkTimeZone,
    'gkAppVersion': gkAppVersion,
    'gkAppVersionCode': gkAppVersionCode,
    'gkGoogleAdId': gkGoogleAdId,
    'gkDeviceInfo': gkDeviceInfo,
    'gkNotificationToken': gkNotificationToken,
    'gkNotificationEnabled': gkNotificationEnabled,
    'integrationType': integrationType,
    'gkMerchantConfig': gkMerchantConfig,
    'gkUserPhone': gkUserPhone,
    'kcMerchantId': kcMerchantId,
    'kcMerchantToken': kcMerchantToken,
    'kcNotificationEventUrl': kcNotificationEventUrl,
    'moengageId': moengageId,
    'kp_sdk_version': kpSdkVersion,
    'kp_sdk_platform': kpSdkPlatform,
    'kp_otp_locked': kpOtpLocked,
    'kwikpass_current_version': kwikpassCurrentVersion,
    'kwikpass_bundle_prefix': kwikpassBundlePrefix,
    'kwikpass_manifest_prefix': kwikpassManifestPrefix,
    'gkBureauEnabled': gkBureauEnabled,
    'gkBureauClientId': gkBureauClientId,
    'gkBureauEnvironment': gkBureauEnvironment,
    'gkBureauTimeout': gkBureauTimeout,
  };
}

/// Storage Key Keys - Auto-generated from StorageKey
/// Provides type-safe access to storage key property names
class StorageKeyKeys {
  static const gkKPEnabled = 'gkKPEnabled';
  static const gkCheckoutEnabled = 'gkCheckoutEnabled';
  static const gkMode = 'gkMode';
  static const gkTokenKey = 'gkTokenKey';
  static const gkCoreTokenKey = 'gkCoreTokenKey';
  static const gkAccessTokenKey = 'gkAccessTokenKey';
  static const checkoutAccessTokenKey = 'checkoutAccessTokenKey';
  static const gkKpToken = 'gkKpToken';
  static const gkEnvironmentKey = 'gkEnvironmentKey';
  static const gkVerifiedUserKey = 'gkVerifiedUserKey';
  static const gkMerchantIdKey = 'gkMerchantIdKey';
  static const kpMerchantIdKey = 'kpMerchantIdKey';
  static const gkMerchantUrlKey = 'gkMerchantUrlKey';
  static const gkMerchantTypeKey = 'gkMerchantTypeKey';
  static const gkRequestIdKey = 'gkRequestIdKey';
  static const kpRequestIdKey = 'kpRequestIdKey';
  static const gkAuthTokenKey = 'gkAuthTokenKey';
  static const isSnowplowTrackingEnabled = 'isSnowplowTrackingEnabled';
  static const gkDeviceModel = 'gkDeviceModel';
  static const gkAppDomain = 'gkAppDomain';
  static const gkOperatingSystem = 'gkOperatingSystem';
  static const gkDeviveId = 'gkDeviveId';
  static const gkDeviceUniqueId = 'gkDeviceUniqueId';
  static const gkGoogleAnalyticsId = 'gkGoogleAnalyticsId';
  static const gkScreenResolution = 'gkScreenResolution';
  static const gkCarrierInfo = 'gkCarrierInfo';
  static const gkBatteryStatus = 'gkBatteryStatus';
  static const gkLanguage = 'gkLanguage';
  static const gkTimeZone = 'gkTimeZone';
  static const gkAppVersion = 'gkAppVersion';
  static const gkAppVersionCode = 'gkAppVersionCode';
  static const gkGoogleAdId = 'gkGoogleAdId';
  static const gkDeviceInfo = 'gkDeviceInfo';
  static const gkNotificationToken = 'gkNotificationToken';
  static const gkNotificationEnabled = 'gkNotificationEnabled';
  static const integrationType = 'integrationType';
  static const gkMerchantConfig = 'gkMerchantConfig';
  static const gkUserPhone = 'gkUserPhone';
  static const kcMerchantId = 'kcMerchantId';
  static const kcMerchantToken = 'kcMerchantToken';
  static const kcNotificationEventUrl = 'kcNotificationEventUrl';
  static const moengageId = 'moengageId';
  static const kp_sdk_version = 'kp_sdk_version';
  static const kp_sdk_platform = 'kp_sdk_platform';
  static const kp_otp_locked = 'kp_otp_locked';
  static const kwikpass_current_version = 'kwikpass_current_version';
  static const kwikpass_bundle_prefix = 'kwikpass_bundle_prefix';
  static const kwikpass_manifest_prefix = 'kwikpass_manifest_prefix';
  static const gkBureauEnabled = 'gkBureauEnabled';
  static const gkBureauClientId = 'gkBureauClientId';
  static const gkBureauEnvironment = 'gkBureauEnvironment';
  static const gkBureauTimeout = 'gkBureauTimeout';
}