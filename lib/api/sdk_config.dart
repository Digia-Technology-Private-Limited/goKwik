class SdkConfig {
  final String baseUrl;
  final String snowplowUrl;
  final String schemaVendor;
  final Map<String, String> checkoutUrl;
  final String notifEventsUrl;

  SdkConfig({
    required this.baseUrl,
    required this.snowplowUrl,
    required this.schemaVendor,
    required this.checkoutUrl,
    required this.notifEventsUrl,
  });

  factory SdkConfig.fromEnvironment(String env) {
    switch (env) {
      case 'production':
        return SdkConfig(
          baseUrl: 'https://gkx.gokwik.co/kp/api/v1/',
          snowplowUrl: 'https://sp-kf-collector-prod.gokwik.io',
          schemaVendor: 'co.gokwik',
          checkoutUrl: {
            'shopify':
                'https://pdp.gokwik.co/app/kwik-checkout.html?storeInfo=',
            'custom': 'https://pdp.gokwik.co/v4/auto.html',
          },
          notifEventsUrl: 'https://api-gw.tlphnt.co/webhook/push-notification',
        );
      case 'sandbox':
        return SdkConfig(
          baseUrl: 'https://api-gw-v4.dev.gokwik.io/sandbox/kp/api/v1/',
          snowplowUrl: 'https://sp-kf-collector.dev.gokwik.io/',
          schemaVendor: 'in.gokwik.kwikpass',
          checkoutUrl: {
            'shopify':
                'https://sandbox.pdp.gokwik.co/app/kwik-checkout.html?storeInfo=',
            'custom': 'https://sandbox.pdp.gokwik.co/v4/auto.html',
          },
          notifEventsUrl:
              'https://api-gw.kwikchatdev.qoowk.com/webhook/push-notification',
        );
      case 'qa':
        return SdkConfig(
          baseUrl: 'https://api-gw-v4.dev.gokwik.io/qa/kp/api/v1/',
          snowplowUrl: 'https://sp-kf-collector.dev.gokwik.io/',
          schemaVendor: 'in.gokwik.kwikpass',
          checkoutUrl: {
            'shopify':
                'https://sandbox.pdp.gokwik.co/app/kwik-checkout.html?storeInfo=',
            'custom': 'https://sandbox.pdp.gokwik.co/v4/auto.html',
          },
          notifEventsUrl:
              'https://api-gw.kwikchatdev.qoowk.com/webhook/push-notification',
        );
      default:
        throw ArgumentError('Unknown environment: $env');
    }
  }

  static String getBaseUrl(String env) =>
      SdkConfig.fromEnvironment(env).baseUrl;
  static String getSnowplowUrl(String env) =>
      SdkConfig.fromEnvironment(env).snowplowUrl;
  static String getSchemaVendor(String env) =>
      SdkConfig.fromEnvironment(env).schemaVendor;
  static Map<String, String> getCheckoutUrl(String env) =>
      SdkConfig.fromEnvironment(env).checkoutUrl;
  static String getNotifEventsUrl(String env) =>
      SdkConfig.fromEnvironment(env).notifEventsUrl;
}
