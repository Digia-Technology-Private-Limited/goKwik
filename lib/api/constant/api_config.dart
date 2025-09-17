class APIConfig {
  static const String kpHealthCheck = 'kp/api/v1/health/merchant';
  static const String merchantConfiguration = 'kp/api/v1/configurations/';
  static const String getBrowserToken = 'kp/api/v1/auth/browser';
  static const String sendVerificationCode = 'kp/api/v1/auth/otp/send';
  static const String verifyCode = 'kp/api/v2/auth/otp/verify';
  static const String customerIntelligence = 'kp/api/v1/customer-intelligence';
  static const String customCustomerLogin = 'kp/api/v1/customer/custom/login';
  static const String customCreateUser = 'kp/api/v1/customer/custom/create-user';
  static const String validateUserToken = 'kp/api/v1/auth/validate-token';
  static const String customerShopifySession = 'kp/api/v1/customer/shopify-session';
  static const String disposableEmailCheck = 'kp/api/v1/disposable-email/validate/';
  static const String sendEmailVerificationCode = 'kp/api/v1/auth/email-otp/send';
  static const String verifyEmailCode = 'kp/api/v1/auth/email-otp/verify';
  static const String shopifyMultipass = 'kp/api/v2/customer/shopify/multipass';
}

class TruecallerConfig {
  static const String type = 'btmsheet';
  static const String partnerKey = '';
  static const String partnerName = '';
  static const String lang = 'en';
  static const String privacyUrl = 'https://www.gokwik.co/data-policy';
  static const String termsUrl = 'https://www.gokwik.co/terms';
  static const String loginSuffix = 'verifymobile';
  static const String ctaPrefix = 'continuewith';
  static const String btnShape = 'rect';
  static const String skipOption = 'useanothermethod';
}

class KPLoginSource {
  static const String value = 'KWIKPASS';
}