import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gokwik/config/cache_instance.dart';
import 'package:gokwik/config/config_constants.dart';
import 'package:gokwik/config/types.dart';
import 'package:gokwik/api/api_service.dart';
import 'package:gokwik/flow_result.dart';
import 'package:gokwik/kwikforms/utils/validations.dart';
import 'package:gokwik/screens/main_screen.dart';
import 'package:gokwik/screens/root.dart';

// ─── View State ───────────────────────────────────────────────────────────────

enum KwikViewState {
  login,
  otp,
  shopifyEmail,
  emailOtp,
  createAccount,
  form,
  selectAddress,
  addAddress,
  success,
}

// ─── KfAssets Config Models ───────────────────────────────────────────────────

class KfInputField {
  final String id;
  final String type;
  final String label;
  final bool required;
  final List<String> options;
  final bool isKpStandard;

  const KfInputField({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.options = const [],
    this.isKpStandard = false,
  });

  static String _toTitleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  factory KfInputField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return KfInputField(
      id: json['id'] as String,
      type: json['type'] as String,
      label: _toTitleCase(json['label'] as String),
      required: json['required'] == true,
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
      isKpStandard: json['is_kp_standard'] == true,
    );
  }
}

class KfFormScreen {
  final String title;
  final String subTitle;
  final String buttonText;
  final List<KfInputField> inputFields;

  const KfFormScreen({
    required this.title,
    required this.subTitle,
    required this.buttonText,
    required this.inputFields,
  });

  factory KfFormScreen.fromJson(Map<String, dynamic> json) {
    final rawFields = json['input_field'];
    return KfFormScreen(
      title: json['title']?.toString() ?? '',
      subTitle: json['sub_title']?.toString() ?? '',
      buttonText: json['button_text']?.toString() ?? 'Submit',
      inputFields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(KfInputField.fromJson)
              .toList()
          : const [],
    );
  }
}

class KfAddressScreen {
  final List<KfInputField> inputFields;

  const KfAddressScreen({required this.inputFields});

  factory KfAddressScreen.fromJson(Map<String, dynamic> json) {
    final rawFields = json['input_field'];
    return KfAddressScreen(
      inputFields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(KfInputField.fromJson)
              .toList()
          : const [],
    );
  }
}

class KfSuccessScreen {
  final String logo;
  final String heading;
  final String message;
  final int screenTimeout;

  const KfSuccessScreen({
    required this.logo,
    required this.heading,
    required this.message,
    required this.screenTimeout,
  });

  factory KfSuccessScreen.fromJson(Map<String, dynamic> json) {
    return KfSuccessScreen(
      logo: json['logo']?.toString() ?? '',
      heading: json['heading']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      screenTimeout: json['screen_timeout'] is int
          ? json['screen_timeout'] as int
          : int.tryParse(json['screen_timeout']?.toString() ?? '') ?? 5,
    );
  }
}

class KfAssetsConfig {
  final String primaryColour;
  final KfFormScreen formScreen;
  final KfAddressScreen addressScreen;
  final KfSuccessScreen successScreen;

  const KfAssetsConfig({
    required this.primaryColour,
    required this.formScreen,
    required this.addressScreen,
    required this.successScreen,
  });

  Color get primaryColor {
    try {
      final hex = primaryColour.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6B3FA0);
    }
  }

  /// Parses the raw API response from getKfAssetsProperties.
  /// Expects: data.components.LEAD_GENE_POPUP.properties
  static KfAssetsConfig? fromApiResponse(dynamic apiResponse) {
    try {
      final data = apiResponse is Map ? apiResponse['data'] : null;
      final components = data is Map ? data['components'] : null;
      final popup = components is Map ? components['LEAD_GENE_POPUP'] : null;
      final props = popup is Map ? popup['properties'] : null;
      if (props is! Map<String, dynamic>) return null;

      return KfAssetsConfig(
        primaryColour: props['PrimaryColour']?.toString() ?? '#112693',
        formScreen: props['form_screen'] is Map<String, dynamic>
            ? KfFormScreen.fromJson(props['form_screen'] as Map<String, dynamic>)
            : const KfFormScreen(title: '', subTitle: '', buttonText: 'Submit', inputFields: []),
        addressScreen: props['address_screen'] is Map<String, dynamic>
            ? KfAddressScreen.fromJson(props['address_screen'] as Map<String, dynamic>)
            : const KfAddressScreen(inputFields: []),
        successScreen: props['success_screen'] is Map<String, dynamic>
            ? KfSuccessScreen.fromJson(props['success_screen'] as Map<String, dynamic>)
            : const KfSuccessScreen(logo: '', heading: '', message: '', screenTimeout: 5),
      );
    } catch (e) {
      return null;
    }
  }
}

// ─── KwikForms Style ──────────────────────────────────────────────────────────

/// Style customisations for the KwikForms address flow.
/// Only visual/style properties — no text overrides.
/// For text/content customisation of the login step, use [KwikLoginConfig].
class KwikFormsStyle {
  /// Overrides the primary colour from the API config.
  /// Falls back to the API-defined primaryColour, then to GoKwik purple.
  final Color? primaryColor;

  /// Style for the main action buttons (Deliver Here, Save & Deliver, Submit).
  final ButtonStyle? buttonStyle;

  /// Text style for labels on the main action buttons.
  final TextStyle? buttonTextStyle;

  /// Base [InputDecoration] applied to all text input fields.
  /// Hint text, suffix icons, and error/focus borders are still applied on top.
  final InputDecoration? inputStyle;

  /// Decoration for address tile cards in the Select Address list.
  final BoxDecoration? cardStyle;

  /// Text style for the screen header title (e.g. "Select Address").
  final TextStyle? headerTitleStyle;

  const KwikFormsStyle({
    this.primaryColor,
    this.buttonStyle,
    this.buttonTextStyle,
    this.inputStyle,
    this.cardStyle,
    this.headerTitleStyle,
  });
}

// ─── KwikForms Theme ──────────────────────────────────────────────────────────

class _KwikTheme extends InheritedWidget {
  final Color primaryColor;
  final KwikFormsStyle? style;

  const _KwikTheme({
    required this.primaryColor,
    this.style,
    required super.child,
  });

  /// Returns the primary colour, falling back to GoKwik purple if no theme is set.
  static Color of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_KwikTheme>()
            ?.primaryColor ??
        const Color(0xFF6B3FA0);
  }

  /// Returns the [KwikFormsStyle] passed by the host app, or null if none.
  static KwikFormsStyle? styleOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_KwikTheme>()?.style;
  }

  @override
  bool updateShouldNotify(_KwikTheme old) =>
      primaryColor != old.primaryColor || style != old.style;
}

// ─── Login Config ─────────────────────────────────────────────────────────────

/// Full customisation config for the login step inside KwikForms.
/// Mirrors every prop accepted by [GoKwikLoginAndSignUpFlow] so the host app
/// has the same degree of control as when embedding the login flow standalone.
class KwikLoginConfig {
  // ── Callbacks ────────────────────────────────────────────────────────────
  final Function(FlowResult)? onSuccess;
  final Function(FlowResult)? onError;
  final void Function(String, Map<String, dynamic>)? onAnalytics;

  // ── Images ───────────────────────────────────────────────────────────────
  final ImageProvider? logo;
  final ImageProvider? bannerImage;

  // ── Style props ──────────────────────────────────────────────────────────
  final BoxDecoration? bannerImageStyle;
  final BoxDecoration? logoStyle;
  final BoxDecoration? containerStyle;
  final BoxDecoration? formContainerStyle;
  final BoxDecoration? imageContainerStyle;

  // ── Input / form config ──────────────────────────────────────────────────
  final TextInputConfig? inputProps;
  final CreateUserConfig? createUserConfig;
  final LoadingConfig? loaderConfig;

  // ── Footer ───────────────────────────────────────────────────────────────
  final String? footerText;
  final List<FooterUrl>? footerUrls;
  final TextStyle? footerTextStyle;
  final TextStyle? footerHyperlinkStyle;

  // ── Guest login ──────────────────────────────────────────────────────────
  final bool enableGuestLogin;
  final String guestLoginButtonLabel;
  final VoidCallback? onGuestLoginPress;
  final BoxDecoration? guestContainerStyle;
  final TextStyle? guestLoginTextStyle;

  // ── Merchant ─────────────────────────────────────────────────────────────
  final MerchantType? merchantType;

  const KwikLoginConfig({
    this.onSuccess,
    this.onError,
    this.onAnalytics,
    this.logo,
    this.bannerImage,
    this.bannerImageStyle,
    this.logoStyle,
    this.containerStyle,
    this.formContainerStyle,
    this.imageContainerStyle,
    this.inputProps,
    this.createUserConfig,
    this.loaderConfig,
    this.footerText,
    this.footerUrls,
    this.footerTextStyle,
    this.footerHyperlinkStyle,
    this.enableGuestLogin = false,
    this.guestLoginButtonLabel = 'Skip',
    this.onGuestLoginPress,
    this.guestContainerStyle,
    this.guestLoginTextStyle,
    this.merchantType,
  });
}

// ─── Address Model ────────────────────────────────────────────────────────────

class KwikAddress {
  final String id;

  /// Address type label — "Home", "Work", "Other", etc.
  final String label;

  /// Full combined address string for display.
  final String addressLine;

  final String name;
  final String phone;
  final String? email;

  /// Source tag shown on the tile.
  /// Host-app addresses carry their own source (e.g. "1mg").
  /// GoKwik-network addresses (API-fetched or manually added) use "GoKwik Network".
  final String? source;

  // Individual address components
  final String? houseNo;
  final String? area;
  final String? landmark;
  final String? pincode;
  final String? city;
  final String? state;
  final String? country;

  const KwikAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.name,
    required this.phone,
    this.source,
    this.email,
    this.houseNo,
    this.area,
    this.landmark,
    this.pincode,
    this.city,
    this.state,
    this.country,
  });

  /// True when this address belongs to the GoKwik network section.
  bool get _isGoKwikNetwork => source == 'GoKwik Network';

  KwikAddress _withoutSource() => KwikAddress(
        id: id,
        label: label,
        addressLine: addressLine,
        name: name,
        phone: phone,
        email: email,
        houseNo: houseNo,
        area: area,
        landmark: landmark,
        pincode: pincode,
        city: city,
        state: state,
        country: country,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'addressLine': addressLine,
    'name': name,
    'phone': phone,
    if (source != null) 'source': source,
    if (email != null) 'email': email,
    if (houseNo != null) 'houseNo': houseNo,
    if (area != null) 'area': area,
    if (landmark != null) 'landmark': landmark,
    if (pincode != null) 'pincode': pincode,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
  };
}

// ─── User Prefill Data ────────────────────────────────────────────────────────

class _KwikUserPrefill {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? pincode;
  final String? city;
  final String? phone;

  const _KwikUserPrefill({
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.pincode,
    this.city,
    this.phone,
  });

  factory _KwikUserPrefill.fromDti(Map<String, dynamic> dti, {String? phone}) {
    return _KwikUserPrefill(
      firstName: dti['fn'] as String?,
      lastName: dti['ln'] as String?,
      email: dti['em'] as String?,
      gender: dti['ge'] as String?,
      pincode: dti['pc'] as String?,
      city: dti['ct'] as String?,
      phone: phone,
    );
  }

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ');
  }
}

// ─── Entry Widget ─────────────────────────────────────────────────────────────

class KwikForms extends StatefulWidget {
  final List<KwikAddress> addresses;
  final bool consent;

  /// Timestamp (in milliseconds since epoch) when the user granted consent.
  final int? consentTimestamp;

  /// Called when the user confirms an address for delivery.
  /// Receives the selected [KwikAddress] in the same format as addresses passed in.
  final ValueChanged<KwikAddress>? onFormSubmit;

  /// Called when the address submission API call fails.
  /// Receives the error for the host app to handle (e.g. show a toast).
  final ValueChanged<dynamic>? onSubmissionFailed;

  /// Called when the user taps back on the first screen (selectAddress).
  final VoidCallback? onClose;

  /// Config for the login step. When provided, a login entry point is available.
  final KwikLoginConfig? loginConfig;

  /// Style customisations for the address flow UI.
  /// Only visual/style properties — text content is not overridable here.
  final KwikFormsStyle? style;

  const KwikForms({
    super.key,
    required this.addresses,
    required this.consent,
    this.consentTimestamp,
    this.onFormSubmit,
    this.onSubmissionFailed,
    this.onClose,
    this.loginConfig,
    this.style,
  });

  @override
  State<KwikForms> createState() => _KwikFormsState();
}

class _KwikFormsState extends State<KwikForms> {
  KwikViewState? _viewState; // null = still checking auth
  bool? _kwikFormsEnabled; // null = still checking
  KfAssetsConfig? _kfAssetsProperties;
  dynamic _kwikFormData;
  dynamic _addressData;
  _KwikUserPrefill _userPrefill = const _KwikUserPrefill();
  bool _isFetchingAddresses = false;
  bool _isDelivering = false;
  late List<KwikAddress> _addresses;
  late String? _selectedId;
  int? _consentTimestamp;

  @override
  void initState() {
    super.initState();
    _addresses = List.of(widget.addresses);
    _selectedId = _addresses.isNotEmpty ? _addresses.first.id : null;
    _consentTimestamp = widget.consentTimestamp;
    _resolveInitialState();
  }

  Future<void> _resolveInitialState() async {

    final results = await Future.wait([
      cacheInstance.getValue(StorageKey.gkVerifiedUserKey),
      cacheInstance.getValue(StorageKey.gkMerchantConfig),
    ]);

    final verifiedUser = results[0];
    final merchantConfigJson = results[1];

    bool kwikFormsEnabled = false;
    if (merchantConfigJson != null) {
      final parsedMerchantConfig = jsonDecode(merchantConfigJson) as Map<String, dynamic>?;
      final kpFeatures = parsedMerchantConfig?['kpFeatures'];
      if (kpFeatures is List) {
        kwikFormsEnabled = kpFeatures.contains('kwikform');
      }
    }

    final parsedVerifiedUser = verifiedUser != null
        ? jsonDecode(verifiedUser) as Map<String, dynamic>?
        : null;
    final userPhone = parsedVerifiedUser?['phone'] as String?;

    final isLoggedIn = verifiedUser != null && verifiedUser.isNotEmpty;

    if (isLoggedIn) {
      setState(() => _viewState = KwikViewState.selectAddress);
    }

    KfAssetsConfig? kfAssetsProperties;
    dynamic kwikFormData;
    dynamic addressData;

    if (kwikFormsEnabled) {
      final assetsResult = await ApiService.getKfAssetsProperties();
      if (assetsResult.isSuccess) {
        kfAssetsProperties = KfAssetsConfig.fromApiResponse(assetsResult.getDataOrThrow());
      }

      if (isLoggedIn && widget.consent && kfAssetsProperties != null) {
        setState(() => _isFetchingAddresses = true);

        final formDataResult = await ApiService.getKwikFormData();
        if (formDataResult.isSuccess) {
          kwikFormData = formDataResult.getDataOrThrow();
        }

        if (userPhone != null && userPhone.isNotEmpty) {
          // await _saveHostAddressesToNetwork(userPhone);
          final addressResult = await ApiService.getAddressByPhone(userPhone);
          if (addressResult.isSuccess) {
            addressData = addressResult.getDataOrThrow();

            // NOW I HAVE THE DATA HERE addressData['data']
            // Need to update the addresses state to show the list of addresses from the api call.
          }
        }
      }
    }

    // Parse GoKwik network addresses from getAddressByPhone API
    final List<KwikAddress> gokwikAddresses = _parseGokwikAddresses(addressData);

    final resolvedViewState = isLoggedIn ? KwikViewState.selectAddress : KwikViewState.login;

    final dti = (kwikFormData?['data'] as Map<String, dynamic>?)?['dti'] as Map<String, dynamic>?;
    final userPrefill = _KwikUserPrefill.fromDti(dti ?? {}, phone: userPhone);

    setState(() {
      _kwikFormsEnabled = kwikFormsEnabled;
      _kfAssetsProperties = kfAssetsProperties;
      _kwikFormData = kwikFormData;
      _addressData = addressData;
      _userPrefill = userPrefill;
      _addresses = [..._addresses, ...gokwikAddresses];
      _isFetchingAddresses = false;
      _viewState = resolvedViewState;
    });
  }

  void _goTo(KwikViewState state) {
    setState(() => _viewState = state);
  }

  /// Parses a GoKwik network address list from a raw API response.
  List<KwikAddress> _parseGokwikAddresses(dynamic addressData) {
    final List<KwikAddress> result = [];
    if (addressData == null) return result;
    final rawList = addressData is List
        ? addressData
        : (addressData['data']?['addresses'] ?? addressData['addresses']);
    if (rawList is! List) return result;
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;
      final rawType = item['address_type']?.toString() ?? 'home';
      final label = rawType[0].toUpperCase() + rawType.substring(1).toLowerCase();
      final firstName = item['first_name']?.toString() ?? '';
      final lastName = item['last_name']?.toString() ?? '';
      final name = [firstName, lastName]
          .where((s) => s.isNotEmpty && s != '.')
          .join(' ');
      result.add(KwikAddress(
        id: item['address_id']?.toString() ?? UniqueKey().toString(),
        label: label,
        addressLine: item['address']?.toString() ?? '',
        name: name,
        phone: item['recipient_phone']?.toString() ?? '',
        email: item['email']?.toString(),
        source: 'GoKwik Network',
        houseNo: item['address_line1']?.toString(),
        area: item['address_line2']?.toString(),
        landmark: item['landmark']?.toString(),
        pincode: item['pincode']?.toString(),
        city: item['city']?.toString(),
        state: item['state']?.toString(),
        country: item['country']?.toString(),
      ));
    }
    return result;
  }

  /// Saves each host-app address to the GoKwik network via the Add Address API.
  /// Called before fetching addresses so the network list is up-to-date.
  Future<void> _saveHostAddressesToNetwork(String userPhone) async {
    final hostAddresses = widget.addresses.where((a) => !a._isGoKwikNetwork).toList();
    for (final address in hostAddresses) {
      try {
        final nameParts = address.name.trim().split(RegExp(r'\s+'));
        final firstName = nameParts.first;
        final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
        final body = {
          'address':         address.addressLine,
          'address_type':    address.label.toLowerCase(),
          'city':            address.city ?? '',
          'email':           address.email ?? '',
          'first_name':      firstName,
          'last_name':       lastName,
          'pincode':         address.pincode ?? '',
          'state':           address.state ?? '',
          'country':         address.country ?? 'India',
          'recipient_phone': userPhone,
          'source':          'kwikForm',
        };
        await ApiService.addAddress(body);
      } catch (e) {
      }
    }
  }

  /// Called after a successful login.
  /// Navigates to selectAddress immediately, then fetches GoKwik network
  /// addresses in the background (if consent is true and kwikforms is enabled).
  Future<void> _onAfterLogin(FlowResult result) async {

    // Go to selectAddress straight away — the loader will show while we fetch.
    setState(() {
      _viewState = KwikViewState.selectAddress;
      _isFetchingAddresses = widget.consent && (_kwikFormsEnabled ?? false) && _kfAssetsProperties != null;
    });

    if (!widget.consent || !(_kwikFormsEnabled ?? false) || _kfAssetsProperties == null) {
      return;
    }

    // Read the phone number that was just persisted by the login flow.
    final verifiedUserJson = await cacheInstance.getValue(StorageKey.gkVerifiedUserKey);
    if (!mounted) return;

    final parsedUser = verifiedUserJson != null
        ? jsonDecode(verifiedUserJson) as Map<String, dynamic>?
        : null;
    final userPhone = parsedUser?['phone'] as String?;

    if (userPhone == null || userPhone.isEmpty) {
      if (mounted) setState(() => _isFetchingAddresses = false);
      return;
    }

    try {
      // await _saveHostAddressesToNetwork(userPhone);
      final addressResult = await ApiService.getAddressByPhone(userPhone);
      if (!mounted) return;

      if (addressResult.isSuccess) {
        final gokwikAddresses = _parseGokwikAddresses(addressResult.getDataOrThrow());
        // Merge: keep host-app addresses, replace any previously fetched GoKwik ones.
        final hostAddresses = _addresses.where((a) => !a._isGoKwikNetwork).toList();
        setState(() {
          _addresses = [...hostAddresses, ...gokwikAddresses];
          if (_selectedId == null && _addresses.isNotEmpty) {
            _selectedId = _addresses.first.id;
          }
        });
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isFetchingAddresses = false);
    }
  }

  Future<void> _handleDeliver(KwikAddress address) async {
    if (_isDelivering) return;

    // For host-app addresses, skip the API call and fire directly.
    if (!address._isGoKwikNetwork) {
      widget.onFormSubmit?.call(address._withoutSource());
      return;
    }

    setState(() => _isDelivering = true);
    try {
      final nameParts = address.name.split(' ');
      final result = await ApiService.submitKwikFormData(
        phone: address.phone,
        countryCode: '+91',
        address: address.addressLine,
        name: address.name,
        gender: '',
        firstName: nameParts.first,
        lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
        email: address.email ?? '',
        consent: true,
      );
      widget.onFormSubmit?.call(address._withoutSource());
    } catch (e) {
      widget.onSubmissionFailed?.call(e);
    } finally {
      if (mounted) setState(() => _isDelivering = false);
    }
  }

  String get _title => switch (_viewState) {
        KwikViewState.selectAddress => 'Select Address',
        KwikViewState.addAddress => 'Add New Address',
        KwikViewState.login => 'Login',
        KwikViewState.otp => 'Verify OTP',
        KwikViewState.shopifyEmail => 'Enter Email',
        KwikViewState.emailOtp => 'Verify Email',
        KwikViewState.createAccount => 'Create Account',
        KwikViewState.form =>
          _kfAssetsProperties?.formScreen.title.isNotEmpty == true
              ? _kfAssetsProperties!.formScreen.title
              : 'Details',
        KwikViewState.success => 'Success',
        null => '',
      };

  VoidCallback? get _onBack => switch (_viewState) {
        KwikViewState.selectAddress => widget.onClose,
        KwikViewState.addAddress => () => _goTo(KwikViewState.selectAddress),
        KwikViewState.login => widget.onClose,
        KwikViewState.otp => () => _goTo(KwikViewState.login),
        KwikViewState.shopifyEmail => () => _goTo(KwikViewState.login),
        KwikViewState.emailOtp => () => _goTo(KwikViewState.shopifyEmail),
        KwikViewState.createAccount => () => _goTo(KwikViewState.otp),
        KwikViewState.form => () => _goTo(KwikViewState.selectAddress),
        KwikViewState.success => () => _goTo(KwikViewState.selectAddress),
        null => null,
      };

  Widget get _body => switch (_viewState) {
        KwikViewState.selectAddress => _SelectAddressView(
            addresses: _addresses,
            selectedId: _selectedId,
            consent: widget.consent,
            isFetchingAddresses: _isFetchingAddresses,
            isDelivering: _isDelivering,
            onAddressSelected: (id) => setState(() => _selectedId = id),
            onDeliver: _handleDeliver,
            onAddAddress: () => _goTo(KwikViewState.addAddress),
          ),
        KwikViewState.addAddress => _AddAddressView(
            onFormSubmit: widget.onFormSubmit,
            onSubmissionFailed: widget.onSubmissionFailed,
            prefill: _userPrefill,
            kfAssetsConfig: _kfAssetsProperties,
          ),
        KwikViewState.form => _FormScreenView(
            kfAssetsConfig: _kfAssetsProperties,
            prefill: _userPrefill,
            onSuccess: () => _goTo(KwikViewState.success),
            onSubmissionFailed: widget.onSubmissionFailed,
          ),
        _ => _PlaceholderView(state: _viewState ?? KwikViewState.form),
      };

  @override
  Widget build(BuildContext context) {
    // Still checking auth / feature flags — show a neutral loading indicator.
    // if (_viewState == null || _kwikFormsEnabled == null) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    // Host style overrides API color; API overrides default GoKwik purple.
    final primaryColor = widget.style?.primaryColor
        ?? _kfAssetsProperties?.primaryColor
        ?? const Color(0xFF6B3FA0);

    // Login state: show our header + GoKwikLoginAndSignUpFlow in the body.
    // GoKwikLoginAndSignUpFlow manages OTP, email, create-account internally.
    if (_viewState == KwikViewState.login) {
      final cfg = widget.loginConfig ?? const KwikLoginConfig();
      return _KwikTheme(
        primaryColor: primaryColor,
        style: widget.style,
        child: Column(
          children: [
            _KwikHeader(title: _title, onBack: _onBack),
            Expanded(
              child: GoKwikLoginAndSignUpFlow(
                logo: null,
                bannerImage: null,
                bannerImageStyle: cfg.bannerImageStyle,
                logoStyle: cfg.logoStyle,
                containerStyle: cfg.containerStyle,
                formContainerStyle: cfg.formContainerStyle,
                imageContainerStyle: cfg.imageContainerStyle,
                loaderConfig: cfg.loaderConfig,
                inputProps: cfg.inputProps,
                createUserConfig: cfg.createUserConfig,
                footerText: cfg.footerText,
                footerUrls: cfg.footerUrls,
                footerTextStyle: cfg.footerTextStyle,
                footerHyperlinkStyle: cfg.footerHyperlinkStyle,
                enableGuestLogin: cfg.enableGuestLogin,
                guestLoginButtonLabel: cfg.guestLoginButtonLabel,
                onGuestLoginPress: cfg.onGuestLoginPress,
                guestContainerStyle: cfg.guestContainerStyle,
                guesLoginTextStyle: cfg.guestLoginTextStyle,
                merchantType: cfg.merchantType,
                onAnalytics: cfg.onAnalytics,
                onError: cfg.onError,
                onSuccess: (result) {
                  cfg.onSuccess?.call(result);
                  _onAfterLogin(result);
                },
              ),
            ),
          ],
        ),
      );
    }

    return _KwikTheme(
      primaryColor: primaryColor,
      style: widget.style,
      child: Column(
        children: [
          _KwikHeader(title: _title, onBack: _onBack),
          Expanded(child: _body),
        ],
      ),
    );
  }
}

// ─── Shared Header ────────────────────────────────────────────────────────────

class _KwikHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const _KwikHeader({required this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Text(
            title,
            style: _KwikTheme.styleOf(context)?.headerTitleStyle
                ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Select Address View ──────────────────────────────────────────────────────

class _SelectAddressView extends StatelessWidget {
  final List<KwikAddress> addresses;
  final String? selectedId;
  final bool consent;
  final bool isFetchingAddresses;
  final bool isDelivering;
  final ValueChanged<String> onAddressSelected;
  final ValueChanged<KwikAddress>? onDeliver;
  final VoidCallback onAddAddress;

  const _SelectAddressView({
    required this.addresses,
    required this.selectedId,
    required this.consent,
    required this.isFetchingAddresses,
    required this.isDelivering,
    required this.onAddressSelected,
    required this.onAddAddress,
    this.onDeliver,
  });

  KwikAddress? get _selectedAddress {
    if (selectedId == null) return null;
    try {
      return addresses.firstWhere((a) => a.id == selectedId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantAddresses =
        addresses.where((a) => !a._isGoKwikNetwork).toList();
    final gokwikAddresses =
        addresses.where((a) => a._isGoKwikNetwork).toList();

    // Show empty state only when done loading and still nothing to show
    if (!isFetchingAddresses && addresses.isEmpty) {
      return _EmptyAddressState(onAddAddress: onAddAddress);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              if (merchantAddresses.isNotEmpty) ...[
                const _SectionHeader(title: 'YOUR SAVED ADDRESSES'),
                ...merchantAddresses.map((a) => _AddressTile(
                      address: a,
                      isSelected: selectedId == a.id,
                      onTap: () => onAddressSelected(a.id),
                    )),
                const SizedBox(height: 8),
              ],
              if (isFetchingAddresses)
                const _FetchingAddressesLoader()
              else if (gokwikAddresses.isNotEmpty) ...[
                const _SectionHeader(title: 'FROM YOUR GOKWIK NETWORK'),
                ...gokwikAddresses.map((a) => _AddressTile(
                      address: a,
                      isSelected: selectedId == a.id,
                      onTap: () => onAddressSelected(a.id),
                    )),
                const SizedBox(height: 8),
              ],
              if (consent) const _GoKwikConsentBanner(),
            ],
          ),
        ),
        _SelectAddressBottomBar(
          selectedAddress: _selectedAddress,
          isDelivering: isDelivering,
          onAddAddress: onAddAddress,
          onDeliver: onDeliver,
        ),
      ],
    );
  }
}

// ─── Fetching Addresses Loader ────────────────────────────────────────────────

class _FetchingAddressesLoader extends StatefulWidget {
  const _FetchingAddressesLoader();

  @override
  State<_FetchingAddressesLoader> createState() => _FetchingAddressesLoaderState();
}

class _FetchingAddressesLoaderState extends State<_FetchingAddressesLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _KwikTheme.of(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_KwikTheme.of(context)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Fetching your addresses...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _KwikTheme.of(context),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final primary = _KwikTheme.of(context);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3;
                  final t = (_controller.value + delay) % 1.0;
                  final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(opacity),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Empty Address State ──────────────────────────────────────────────────────

class _EmptyAddressState extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _EmptyAddressState({required this.onAddAddress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 72,
              color: _KwikTheme.of(context).withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Saved Addresses Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We couldn't find any saved addresses in the GoKwik network for your number. Add a new address to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onAddAddress,
              style: OutlinedButton.styleFrom(
                foregroundColor: _KwikTheme.of(context),
                side: BorderSide(color: _KwikTheme.of(context)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add New Address',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Address View ─────────────────────────────────────────────────────────

class _AddAddressView extends StatefulWidget {
  final ValueChanged<KwikAddress>? onFormSubmit;
  final ValueChanged<dynamic>? onSubmissionFailed;
  final _KwikUserPrefill prefill;
  final KfAssetsConfig? kfAssetsConfig;

  const _AddAddressView({
    this.onFormSubmit,
    this.onSubmissionFailed,
    required this.prefill,
    this.kfAssetsConfig,
  });

  @override
  State<_AddAddressView> createState() => _AddAddressViewState();
}

class _AddAddressViewState extends State<_AddAddressView> {
  static const List<KfInputField> _defaultAddressFields = [
    KfInputField(id: 'fullName',    type: 'text',     label: 'Full Name',    required: true),
    KfInputField(id: 'email',       type: 'email',    label: 'Email'),
    KfInputField(id: 'pincode',     type: 'text',     label: 'Pincode'),
    KfInputField(id: 'city',        type: 'text',     label: 'City'),
    KfInputField(id: 'state',       type: 'text',     label: 'State'),
    KfInputField(id: 'fullAddress', type: 'textArea', label: 'Full Address', required: true),
  ];

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  String _addressType = 'home';
  bool _saveToNetwork = true;
  bool _isSubmitting = false;
  bool _isFetchingGeoInfo = false;
  String _lastFetchedPincode = '';
  Timer? _pincodeDebounce;

  List<KfInputField> get _fields {
    final fields = widget.kfAssetsConfig?.addressScreen.inputFields;
    return (fields != null && fields.isNotEmpty) ? fields : _defaultAddressFields;
  }

  TextEditingController _ctrl(String id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f.id] = TextEditingController();
    }
    final p = widget.prefill;
    _ctrl('fullName').text = p.fullName;
    _ctrl('email').text = p.email ?? '';
    _ctrl('pincode').text = p.pincode ?? '';
    _ctrl('city').text = p.city ?? '';
    if (p.gender != null) _selectValues['gender'] = _normalizeGender(p.gender!);
    _ctrl('pincode').addListener(_onPincodeChanged);
    // If pincode is already prefilled, the listener above won't fire (text was
    // set before it was attached). Kick off a geo fetch manually so city/state
    // are auto-populated on first render.
    final prefillPincode = p.pincode?.trim() ?? '';
    if (prefillPincode.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchGeoInfo(prefillPincode);
      });
    }
  }

  String? _normalizeGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'm':
        return 'male';
      case 'female':
      case 'f':
        return 'female';
      default:
        return null;
    }
  }

  void _onPincodeChanged() {
    final pincode = _ctrl('pincode').text.trim();
    if (pincode.length != 6 || pincode == _lastFetchedPincode) return;
    _pincodeDebounce?.cancel();
    _pincodeDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchGeoInfo(pincode);
    });
  }

  Future<void> _fetchGeoInfo(String pincode) async {
    if (_isFetchingGeoInfo) return;
    _lastFetchedPincode = pincode;
    setState(() => _isFetchingGeoInfo = true);
    try {
      final result = await ApiService.getGeoInfo(pincode);
      if (!mounted) return;
      if (result.isSuccess) {
        final data = result.getDataOrThrow();
        final geoData = data is Map ? (data['data'] as Map?) : null;
        if (geoData != null) {
          final city = geoData['city']?.toString() ?? '';
          final state = (geoData['state']
                      ?? geoData['stateName']
                      ?? geoData['state_name'])
                    ?.toString() ?? '';
          if (city.isNotEmpty) _ctrl('city').text = city;
          if (state.isNotEmpty) _ctrl('state').text = state;
        }
      }
    } catch (e, st) {
      debugPrint('[GeoInfo] error: $e\n$st');
    } finally {
      if (mounted) setState(() => _isFetchingGeoInfo = false);
    }
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _controllers['pincode']?.removeListener(_onPincodeChanged);
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _getAddAddressBody() async {
    final name = _ctrl('fullName').text.trim();
    final nameParts = name.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    String phone = widget.prefill.phone ?? '';
    if (phone.isEmpty) {
      final verifiedUserJson = await cacheInstance.getValue(StorageKey.gkVerifiedUserKey);
      final parsedUser = verifiedUserJson != null
          ? jsonDecode(verifiedUserJson) as Map?
          : null;
      phone = parsedUser?['phone'] as String? ?? '';
    }

    return {
      'address':         _ctrl('fullAddress').text.trim(),
      'address_type':    _addressType,
      'city':            _ctrl('city').text.trim(),
      'email':           _ctrl('email').text.trim(),
      'first_name':      firstName,
      'last_name':       lastName,
      'pincode':         _ctrl('pincode').text.trim(),
      'state':           _ctrl('state').text.trim(),
      'country':         'India',
      'recipient_phone': phone,
      'source':          'kwikForm',
    };
  }

  // ── Field renderers ──────────────────────────────────────────────────────────

  String? Function(String?)? _validatorFor(KfInputField field) {
    if (field.id == 'fullName') {
      return (v) {
        if (v == null || v.trim().isEmpty) return '${field.label} is required';
        if (!validateName(v.trim())) return 'Please enter a valid full name';
        return null;
      };
    }
    if (field.id == 'email') {
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return field.required ? '${field.label} is required' : null;
        }
        final err = validateEmail(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (field.id == 'pincode') {
      return (v) {
        final err = validatePinCodeFormat(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (field.id == 'city') {
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return field.required ? '${field.label} is required' : null;
        }
        final err = validateCity(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (field.id == 'state') {
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return field.required ? '${field.label} is required' : null;
        }
        final err = validateState(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (!field.required) return null;
    return (v) =>
        (v == null || v.trim().isEmpty) ? '${field.label} is required' : null;
  }

  Widget _buildDynamicField(KfInputField field) {
    final label = field.required
        ? _FieldLabel(field.label)
        : _FieldLabel.optional(field.label);

    switch (field.type) {
      case 'textArea':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _AddressField(
              controller: _ctrl(field.id),
              hint: field.label,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              validator: _validatorFor(field),
            ),
          ],
        );

      case 'select':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _SelectField(
              value: _selectValues[field.id],
              options: field.options,
              hint: field.label,
              onChanged: (v) => setState(() => _selectValues[field.id] = v),
              validator: field.required
                  ? (v) => (v == null || v.isEmpty)
                      ? '${field.label} is required'
                      : null
                  : null,
            ),
          ],
        );

      case 'date':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _DateField(
              controller: _ctrl(field.id),
              label: field.label,
              required: field.required,
            ),
          ],
        );

      case 'tel':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _PhoneField(controller: _ctrl(field.id)),
          ],
        );

      default:
        // text, email, number — with pincode special-case for geo-spinner
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _AddressField(
              controller: _ctrl(field.id),
              hint: field.label,
              keyboardType: switch (field.type) {
                'email'  => TextInputType.emailAddress,
                'number' => TextInputType.number,
                _        => TextInputType.text,
              },
              maxLength: field.id == 'pincode' ? 6 : null,
              suffix: (field.id == 'pincode' && _isFetchingGeoInfo)
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _KwikTheme.of(context),
                      ),
                    )
                  : null,
              validator: _validatorFor(field),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Type chips — always shown
                  _FieldLabel('Address Type'),
                  Row(
                    children: [
                      for (final type in ['home', 'work', 'other']) ...[
                        _AddressTypeChip(
                          label: type[0].toUpperCase() + type.substring(1),
                          icon: switch (type) {
                            'home' => Icons.home_outlined,
                            'work' => Icons.work_outline,
                            _      => Icons.location_on_outlined,
                          },
                          selected: _addressType == type,
                          onTap: () => setState(() => _addressType = type),
                        ),
                        if (type != 'other') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dynamic fields from kfAssets address_screen config
                  for (final field in _fields) ...[
                    _buildDynamicField(field),
                    const SizedBox(height: 14),
                  ],

                  // GoKwik network consent
                  _NetworkConsentBanner(
                    value: _saveToNetwork,
                    onChanged: (v) => setState(() => _saveToNetwork = v),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // Save & Deliver button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      setState(() => _isSubmitting = true);
                      final body = await _getAddAddressBody();
                      try {
                        if (_saveToNetwork) {
                          await ApiService.addAddress(body);
                        }
                        final result = await ApiService.submitKwikFormData(
                          phone: body['recipient_phone'] as String,
                          countryCode: '+91',
                          address: body['address'] as String,
                          name: _ctrl('fullName').text.trim(),
                          gender: _selectValues['gender'] ?? '',
                          firstName: body['first_name'] as String,
                          lastName: body['last_name'] as String,
                          email: body['email'] as String,
                          consent: _saveToNetwork,
                        );
                        widget.onFormSubmit?.call(KwikAddress(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          label: body['address_type'] as String,
                          addressLine: body['address'] as String,
                          name: _ctrl('fullName').text.trim(),
                          phone: body['recipient_phone'] as String,
                          email: (body['email'] as String).isNotEmpty
                              ? body['email'] as String
                              : null,
                          pincode: body['pincode'] as String,
                          city: body['city'] as String,
                          state: body['state'] as String,
                          country: 'India',
                        ));
                      } catch (e) {
                        widget.onSubmissionFailed?.call(e);
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              style: _KwikTheme.styleOf(context)?.buttonStyle ?? ElevatedButton.styleFrom(
                backgroundColor: _KwikTheme.of(context),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _KwikTheme.of(context).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(
                'Save & Deliver Here',
                style: _KwikTheme.styleOf(context)?.buttonTextStyle
                    ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Address Type Chip ────────────────────────────────────────────────────────

class _AddressTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _KwikTheme.of(context).withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _KwikTheme.of(context) : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? _KwikTheme.of(context) : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _KwikTheme.of(context) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isOptional;

  const _FieldLabel(this.text) : isOptional = false;
  const _FieldLabel.optional(this.text) : isOptional = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          if (isOptional) ...[
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Address Field ────────────────────────────────────────────────────────────

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _AddressField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _KwikTheme.of(context);
    final hostInputStyle = _KwikTheme.styleOf(context)?.inputStyle;
    final suffixWidget = suffix != null
        ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
        : null;

    // Default decoration is always the base. Host inputStyle overrides specific
    // fields on top — runtime pieces (hint, suffix, error borders) are always applied.
    final defaultDecoration = InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      suffixIcon: suffixWidget,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
    );

    final decoration = hostInputStyle != null
        ? defaultDecoration.copyWith(
            filled: hostInputStyle.filled ?? defaultDecoration.filled,
            fillColor: hostInputStyle.fillColor ?? defaultDecoration.fillColor,
            contentPadding: hostInputStyle.contentPadding ?? defaultDecoration.contentPadding,
            hintStyle: hostInputStyle.hintStyle ?? defaultDecoration.hintStyle,
            enabledBorder: hostInputStyle.enabledBorder ?? defaultDecoration.enabledBorder,
            focusedBorder: hostInputStyle.focusedBorder ?? defaultDecoration.focusedBorder,
            errorBorder: hostInputStyle.errorBorder ?? defaultDecoration.errorBorder,
            focusedErrorBorder: hostInputStyle.focusedErrorBorder ?? defaultDecoration.focusedErrorBorder,
          )
        : defaultDecoration;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: decoration,
    );
  }
}

// ─── Select Field ─────────────────────────────────────────────────────────────

class _SelectField extends StatelessWidget {
  final String? value;
  final List<String> options;
  final String hint;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _SelectField({
    required this.value,
    required this.options,
    required this.hint,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _KwikTheme.of(context);
    final hostInputStyle = _KwikTheme.styleOf(context)?.inputStyle;

    final defaultDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
    );

    final decoration = hostInputStyle != null
        ? defaultDecoration.copyWith(
            filled: hostInputStyle.filled ?? defaultDecoration.filled,
            fillColor: hostInputStyle.fillColor ?? defaultDecoration.fillColor,
            contentPadding: hostInputStyle.contentPadding ?? defaultDecoration.contentPadding,
            enabledBorder: hostInputStyle.enabledBorder ?? defaultDecoration.enabledBorder,
            focusedBorder: hostInputStyle.focusedBorder ?? defaultDecoration.focusedBorder,
            errorBorder: hostInputStyle.errorBorder ?? defaultDecoration.errorBorder,
            focusedErrorBorder: hostInputStyle.focusedErrorBorder ?? defaultDecoration.focusedErrorBorder,
          )
        : defaultDecoration;

    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
      items: options
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: decoration,
    );
  }
}

// ─── Date Field ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;

  const _DateField({
    required this.controller,
    required this.label,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        }
      },
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: () {
        final primary = _KwikTheme.of(context);
        final hostInputStyle = _KwikTheme.styleOf(context)?.inputStyle;
        final defaultDecoration = InputDecoration(
          hintText: 'DD/MM/YYYY',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
        );
        if (hostInputStyle == null) return defaultDecoration;
        return defaultDecoration.copyWith(
          filled: hostInputStyle.filled ?? defaultDecoration.filled,
          fillColor: hostInputStyle.fillColor ?? defaultDecoration.fillColor,
          contentPadding: hostInputStyle.contentPadding ?? defaultDecoration.contentPadding,
          enabledBorder: hostInputStyle.enabledBorder ?? defaultDecoration.enabledBorder,
          focusedBorder: hostInputStyle.focusedBorder ?? defaultDecoration.focusedBorder,
          errorBorder: hostInputStyle.errorBorder ?? defaultDecoration.errorBorder,
          focusedErrorBorder: hostInputStyle.focusedErrorBorder ?? defaultDecoration.focusedErrorBorder,
        );
      }(),
    );
  }
}

// ─── Phone Field ──────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        final error = validateMobile(controller.text);
        return error.isNotEmpty ? error : null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: field.hasError
                      ? const Color(0xFFD32F2F)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Always-visible country code
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 22,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1A1A1A)),
                      onChanged: (_) => field.didChange(controller.text),
                      decoration: InputDecoration(
                        hintText: '987xxxxxxx',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFD32F2F)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Network Consent Banner ───────────────────────────────────────────────────

class _NetworkConsentBanner extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NetworkConsentBanner({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _KwikTheme.of(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? true),
              activeColor: _KwikTheme.of(context),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4A4A4A),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'This address will be saved to your '),
                  TextSpan(
                    text: 'GoKwik Network',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _KwikTheme.of(context),
                    ),
                  ),
                  const TextSpan(
                      text: ' for faster checkout across 500+ brands.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder View (other states) ─────────────────────────────────────────

class _PlaceholderView extends StatelessWidget {
  final KwikViewState state;

  const _PlaceholderView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      // child: Text(
      //   '${state.name} — coming soon',
      //   style: const TextStyle(color: Colors.grey),
      // ),
    );
  }
}

// ─── Form Screen View ─────────────────────────────────────────────────────────

class _FormScreenView extends StatefulWidget {
  final KfAssetsConfig? kfAssetsConfig;
  final _KwikUserPrefill prefill;
  final VoidCallback onSuccess;
  final ValueChanged<dynamic>? onSubmissionFailed;

  const _FormScreenView({
    this.kfAssetsConfig,
    required this.prefill,
    required this.onSuccess,
    this.onSubmissionFailed,
  });

  @override
  State<_FormScreenView> createState() => _FormScreenViewState();
}

class _FormScreenViewState extends State<_FormScreenView> {
  static const List<KfInputField> _defaultFormFields = [
    KfInputField(id: 'firstName', type: 'text',   label: 'First Name',    required: true),
    KfInputField(id: 'lastName',  type: 'text',   label: 'Last Name',     required: true),
    KfInputField(id: 'phone',     type: 'tel',    label: 'Phone Number',  required: true),
    KfInputField(id: 'email',     type: 'email',  label: 'Email'),
    KfInputField(id: 'gender',    type: 'select', label: 'Gender',        options: ['male', 'female']),
  ];

  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selectValues = {};
  bool _isSubmitting = false;
  bool _isFetchingGeoInfo = false;
  String _lastFetchedPincode = '';
  Timer? _pincodeDebounce;

  List<KfInputField> get _fields {
    final fields = widget.kfAssetsConfig?.formScreen.inputFields;
    return (fields != null && fields.isNotEmpty) ? fields : _defaultFormFields;
  }

  TextEditingController _ctrl(String id) =>
      _controllers.putIfAbsent(id, TextEditingController.new);

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f.id] = TextEditingController();
    }
    final p = widget.prefill;
    _ctrl('firstName').text = p.firstName ?? '';
    _ctrl('lastName').text = p.lastName ?? '';
    _ctrl('email').text = p.email ?? '';
    _ctrl('pincode').text = p.pincode ?? '';
    _ctrl('city').text = p.city ?? '';
    if (p.gender != null) _selectValues['gender'] = p.gender;
    _ctrl('pincode').addListener(_onPincodeChanged);
  }

  void _onPincodeChanged() {
    final pincode = _ctrl('pincode').text.trim();
    if (pincode.length != 6 || pincode == _lastFetchedPincode) return;
    _pincodeDebounce?.cancel();
    _pincodeDebounce = Timer(const Duration(milliseconds: 600), () {
      _fetchGeoInfo(pincode);
    });
  }

  Future<void> _fetchGeoInfo(String pincode) async {
    if (_isFetchingGeoInfo) return;
    _lastFetchedPincode = pincode;
    setState(() => _isFetchingGeoInfo = true);
    try {
      final result = await ApiService.getGeoInfo(pincode);
      if (!mounted) return;
      if (result.isSuccess) {
        final data = result.getDataOrThrow();
        final geoData = data is Map ? (data['data'] as Map?) : null;
        if (geoData != null) {
          final city = geoData['city']?.toString() ?? '';
          final state = (geoData['state']
                      ?? geoData['stateName']
                      ?? geoData['state_name'])
                    ?.toString() ?? '';
          if (city.isNotEmpty) _ctrl('city').text = city;
          if (state.isNotEmpty) _ctrl('state').text = state;
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isFetchingGeoInfo = false);
    }
  }

  @override
  void dispose() {
    _pincodeDebounce?.cancel();
    _controllers['pincode']?.removeListener(_onPincodeChanged);
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String? Function(String?)? _validatorFor(KfInputField field) {
    if (field.id == 'firstName' || field.id == 'lastName') {
      return (v) {
        if (v == null || v.trim().isEmpty) return '${field.label} is required';
        if (!validateName(v.trim())) return 'Please enter a valid name';
        return null;
      };
    }
    if (field.id == 'email') {
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return field.required ? '${field.label} is required' : null;
        }
        final err = validateEmail(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (field.id == 'pincode') {
      return (v) {
        final err = validatePinCodeFormat(v);
        return err.isNotEmpty ? err : null;
      };
    }
    if (!field.required) return null;
    return (v) =>
        (v == null || v.trim().isEmpty) ? '${field.label} is required' : null;
  }

  Widget _buildField(KfInputField field) {
    final label = field.required
        ? _FieldLabel(field.label)
        : _FieldLabel.optional(field.label);

    switch (field.type) {
      case 'textArea':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _AddressField(
              controller: _ctrl(field.id),
              hint: field.label,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              validator: _validatorFor(field),
            ),
          ],
        );

      case 'select':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _SelectField(
              value: _selectValues[field.id],
              options: field.options,
              hint: field.label,
              onChanged: (v) => setState(() => _selectValues[field.id] = v),
              validator: field.required
                  ? (v) => (v == null || v.isEmpty)
                      ? '${field.label} is required'
                      : null
                  : null,
            ),
          ],
        );

      case 'date':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _DateField(
              controller: _ctrl(field.id),
              label: field.label,
              required: field.required,
            ),
          ],
        );

      case 'tel':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _PhoneField(controller: _ctrl(field.id)),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label,
            _AddressField(
              controller: _ctrl(field.id),
              hint: field.label,
              keyboardType: switch (field.type) {
                'email'  => TextInputType.emailAddress,
                'number' => TextInputType.number,
                _        => TextInputType.text,
              },
              maxLength: field.id == 'pincode' ? 6 : null,
              suffix: (field.id == 'pincode' && _isFetchingGeoInfo)
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _KwikTheme.of(context),
                      ),
                    )
                  : null,
              validator: _validatorFor(field),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.kfAssetsConfig?.formScreen;
    final buttonText =
        config?.buttonText.isNotEmpty == true ? config!.buttonText : 'Submit';
    final subTitle = config?.subTitle ?? '';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sub-title from config
                  if (subTitle.isNotEmpty) ...[
                    Text(
                      subTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Dynamic fields from form_screen config
                  for (final field in _fields) ...[
                    _buildField(field),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Submit button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      setState(() => _isSubmitting = true);
                      try {
                        final firstName = _ctrl('firstName').text.trim();
                        final lastName  = _ctrl('lastName').text.trim();
                        final name = [firstName, lastName]
                            .where((s) => s.isNotEmpty)
                            .join(' ');
                        final result = await ApiService.submitKwikFormData(
                          phone:       _ctrl('phone').text.trim(),
                          countryCode: _selectValues['countryCode'] ?? '+91',
                          address:     _ctrl('address').text.trim(),
                          name:        name,
                          gender:      _selectValues['gender'] ?? '',
                          firstName:   firstName,
                          lastName:    lastName,
                          email:       _ctrl('email').text.trim(),
                          consent:     true,
                        );
                        widget.onSuccess();
                      } catch (e) {
                        widget.onSubmissionFailed?.call(e);
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    },
              style: _KwikTheme.styleOf(context)?.buttonStyle ?? ElevatedButton.styleFrom(
                backgroundColor: _KwikTheme.of(context),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _KwikTheme.of(context).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: _KwikTheme.styleOf(context)?.buttonTextStyle
                          ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Address Tile ─────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final KwikAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _KwikTheme.of(context);

    final hostCardStyle = _KwikTheme.styleOf(context)?.cardStyle;
    final defaultCardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border(
        left: BorderSide(
          color: isSelected ? primary : Colors.transparent,
          width: 3,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
    // Host cardStyle overrides the base decoration; selected left-border is always applied.
    final cardDecoration = hostCardStyle != null
        ? hostCardStyle.copyWith(
            border: hostCardStyle.border ?? Border(
              left: BorderSide(
                color: isSelected ? primary : Colors.transparent,
                width: 3,
              ),
            ),
          )
        : defaultCardDecoration;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: cardDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSelected ? primary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_outlined,
                            size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          address.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (address.source != null)
                          _SourceTag(
                            label: address.source!,
                            isGoKwik: address._isGoKwikNetwork,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.addressLine,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.name}  •  ${address.phone}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Source Tag ───────────────────────────────────────────────────────────────

class _SourceTag extends StatelessWidget {
  final String label;
  final bool isGoKwik;

  const _SourceTag({required this.label, required this.isGoKwik});

  @override
  Widget build(BuildContext context) {
    final primary = _KwikTheme.of(context);
    final bg = primary.withOpacity(isGoKwik ? 0.08 : 0.12);
    final fg = primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

// ─── GoKwik Consent Banner ────────────────────────────────────────────────────

class _GoKwikConsentBanner extends StatelessWidget {
  const _GoKwikConsentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _KwikTheme.of(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _KwikTheme.of(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'GK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Addresses powered by GoKwik',
            style: TextStyle(fontSize: 12, color: Color(0xFF4A4A4A)),
          ),
        ],
      ),
    );
  }
}

// ─── Select Address Bottom Bar ────────────────────────────────────────────────

class _SelectAddressBottomBar extends StatelessWidget {
  final KwikAddress? selectedAddress;
  final VoidCallback onAddAddress;
  final ValueChanged<KwikAddress>? onDeliver;
  final bool isDelivering;

  const _SelectAddressBottomBar({
    required this.selectedAddress,
    required this.onAddAddress,
    required this.isDelivering,
    this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onAddAddress,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Add a new address',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedAddress != null && !isDelivering
                  ? () => onDeliver?.call(selectedAddress!)
                  : null,
              style: _KwikTheme.styleOf(context)?.buttonStyle ?? ElevatedButton.styleFrom(
                backgroundColor: _KwikTheme.of(context),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _KwikTheme.of(context).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isDelivering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Deliver to Selected Address',
                      style: _KwikTheme.styleOf(context)?.buttonTextStyle
                          ?? const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
