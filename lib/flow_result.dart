enum FlowType {
  otpSend,
  otpVerify,
  resendOtp,
  emailOtpSend,
  emailOtpVerify,
  createUser,
  shopifyEmailSubmit,
  resendShopifyEmailOtp,
  alreadyLoggedIn,
  notLoggedIn,
  checkoutSuccess,
  checkoutFailed,
  modalClosed,
  openInBrowserTab
}

class FlowResult {
  final FlowType flowType;
  final dynamic data;
  final dynamic error;
  final Map<String, dynamic>? extra;

  FlowResult({
    required this.flowType,
    this.data,
    this.error,
    this.extra,
  });
}
