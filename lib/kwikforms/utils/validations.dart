// Address validation
String validatePinCodeFormat(String? pinCode) {
  final pinCodeRegex = RegExp(r'^\d{6}$');

  if (pinCode == null || pinCode.isEmpty) {
    return 'PIN Code is required';
  }

  if (!pinCodeRegex.hasMatch(pinCode)) {
    return 'PIN Code must be 6 digits';
  }

  return '';
}

String validateCity(String city) {
  if (city.trim().isEmpty) {
    return 'City is required';
  }

  final invalidCharsRegex = RegExp(r'[^a-zA-Z\s]+');
  if (invalidCharsRegex.hasMatch(city)) {
    return 'Please enter a valid City (letters and spaces only)';
  }

  return '';
}

String validateState(String state) {
  if (state.trim().isEmpty) {
    return 'State is required';
  }

  final invalidCharsRegex = RegExp(r'[^a-zA-Z\s]+');
  if (invalidCharsRegex.hasMatch(state)) {
    return 'Please enter a valid State (letters and spaces only)';
  }

  return '';
}

String validateCompleteAddress(String address) {
  if (address.trim().isEmpty) {
    return 'Complete Address is required';
  }

  final disallowedChars = RegExp(r'[<>{}]');
  if (disallowedChars.hasMatch(address)) {
    return 'Please enter a valid address (avoid special characters like <, >, {, })';
  }

  if (address.length > 255) {
    return 'Address cannot exceed 255 characters';
  }

  return '';
}

// Phone validation
String validateMobile(String? mobile) {
  if (mobile == null || mobile.isEmpty) {
    return 'Mobile number is required';
  }

  String processedMobile = mobile;

  final nonDigitRegex = RegExp(r'[^0-9+]');
  if (nonDigitRegex.hasMatch(processedMobile)) {
    return 'Please enter a valid mobile number (digits only)';
  }

  if (processedMobile.startsWith('+91')) {
    processedMobile = processedMobile.substring(3);
  } else if (processedMobile.startsWith('91') && processedMobile.length > 10) {
    processedMobile = processedMobile.substring(2);
  } else if (processedMobile.startsWith('0')) {
    processedMobile = processedMobile.substring(1);
  }

  if (processedMobile.length != 10) {
    return 'Mobile number must be 10 digits (excluding country code)';
  }

  if (!RegExp(r'^[6-9]').hasMatch(processedMobile)) {
    return 'Mobile number must start with 6, 7, 8, or 9';
  }

  return '';
}

bool validatePhone(String? phoneNumber) {
  final phoneRegex = RegExp(r'^[6-9][0-9]{9}$');
  return phoneNumber != null &&
      phoneNumber.length == 10 &&
      phoneRegex.hasMatch(phoneNumber);
}

String handlePhoneInputValidationHelper(String val) {
  if (val.length > 11 && val.substring(0, 2) == '91') {
    val = val.replaceFirst('91', '');
  }
  if (val.length > 11 && val.substring(0, 3) == '+91') {
    val = val.replaceFirst('+91', '');
  }
  val = val.replaceAll(RegExp(r'[^0-9]'), '');
  if (val.isNotEmpty && val[0] == '0') {
    val = val.substring(1);
  }
  val = val.substring(0, val.length > 10 ? 10 : val.length);
  return val;
}

bool validateName(String name) {
  return name.replaceAll(' ', '').length >= 3 &&
      RegExp(r'^[a-zA-Z]+(?:[ .][a-zA-Z]*)*$').hasMatch(name);
}

bool validateAddress(String? address) {
  return address != null &&
      address.isNotEmpty &&
      RegExp(r'[a-zA-Z]').hasMatch(address) &&
      address.replaceAll(' ', '').length >= 12;
}

String validateEmail(String email) {
  if (email.trim().isEmpty) {
    return 'Email is required';
  }

  final atIndex = email.indexOf('@');
  if (atIndex == -1) {
    return 'Please enter a valid email address';
  }

  final lastDotIndex = email.lastIndexOf('.');
  if (lastDotIndex == -1 || lastDotIndex < atIndex) {
    return 'Please enter a valid email address';
  }

  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(email.trim())) {
    return 'Please enter a valid email address';
  }

  return '';
}
