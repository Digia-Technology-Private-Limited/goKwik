class KeyConfig {
  static const moEngageId = 'moEngageId';
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

  static const gkMerchantConfig = 'gk-merchant-config';
  static const gkUserPhone = 'gk-user-phone';

  static const kcMerchantId = 'kc-merchant-id';
  static const kcMerchantToken = 'kc-merchant-token';
  static const kcNotificationEventUrl = 'kc-notif-event-url';
  
  // Keys from JSON config (matching JSON key names)
  static const gkKPEnabled = 'gk-kp-enabled';
  static const gkCheckoutEnabled = 'gk-checkout-enabled';
  static const integrationType = 'kp-integration-type';
  static const kpOtpLocked = 'otp_resend_data';
  static const kwikpassCurrentVersion = 'kwikpass_current_version';
  static const kwikpassBundlePrefix = 'kwikpass_bundle_';
  static const kwikpassManifestPrefix = 'kwikpass_manifest_';
  
  // Legacy keys (for backward compatibility - keeping old naming)
  static const enableKwikPass = 'gk-kp-enabled';  // Updated value to match JSON
  static const enableCheckout = 'gk-checkout-enabled';  // Updated value to match JSON
  
  static const kpSdkVersion = 'sdk-version';
  static const kpSdkPlatform = 'sdk-platform';

  static const List<String> allKeys = [
    gkTokenKey,
    gkCoreTokenKey,
    gkAccessTokenKey,
    checkoutAccessTokenKey,
    gkKpToken,
    gkEnvironmentKey,
    gkVerifiedUserKey,
    gkMerchantIdKey,
    gkMerchantUrlKey,
    gkMerchantTypeKey,
    gkRequestIdKey,
    kpRequestIdKey,
    gkAuthTokenKey,
    isSnowplowTrackingEnabled,
    gkDeviceModel,
    gkAppDomain,
    gkOperatingSystem,
    gkDeviveId,
    gkDeviceUniqueId,
    gkGoogleAnalyticsId,
    gkScreenResolution,
    gkCarrierInfo,
    gkBatteryStatus,
    gkLanguage,
    gkTimeZone,
    gkAppVersion,
    gkAppVersionCode,
    gkGoogleAdId,
    gkDeviceInfo,
    gkNotificationToken,
    gkNotificationEnabled,
    gkMerchantConfig,
    gkUserPhone,
    kcMerchantId,
    kcMerchantToken,
    kcNotificationEventUrl,
    gkKPEnabled,
    gkCheckoutEnabled,
    integrationType,
    kpOtpLocked,
    kwikpassCurrentVersion,
    kwikpassBundlePrefix,
    kwikpassManifestPrefix,
    kpSdkVersion,
    kpSdkPlatform,
  ];

  /// 🔄 Function to get all keys (optional if you want a method instead of accessing `KeyConfig.allKeys`)
  static List<String> getAllKeys() => allKeys;
}
