const kfPages = {
  'LOADING': 'loading',
  'LOGIN': 'login',
  'OTP': 'otp',
  'FORM': 'form',
  'FORM_SUBMITTED': 'form_submited',
};

const kfDefaultData = {
  'fn': 'firstName',
  'ln': 'lastName',
  'dob': 'dateOfBirth',
  'ann': 'anniversaryDate',
  'prf': 'profession',
  'em': 'email',
  'age': 'age',
  'pc': 'pincode',
  'cc': 'countryCode',
  'ct': 'city',
  'ge': 'gender',
  'address': 'address',
};

const kfEventsLabel = {
  'KF_LOADED': 'kwikforms_widget_loaded',
  'KF_SSO': 'kwikforms_sso',
  'KF_OTP': 'kwikforms_otptriggeredmanually',
  'KF_OTP_VERIFIED': 'kwikforms_otpverified',
  'KF_SUBMITTED': 'kwikform_submitted',
  'KF_POPUP_DISMISSED': 'kwikforms_dismissed',
  'KF_AUTOFILLED_FILL': 'kwikform_autofilled_fill',
  'KF_POPUP_TYPE_ID': 'kwikform_popup_type_id',
};

const kfEventsCategory = {
  'KWIK_FORM': 'kwikform',
};

const kfEventsActions = {
  'CLICK': 'click',
  'PAGE_LOAD': 'page_load',
  'SUBMITTED': 'submitted',
};

const errorMsg = {
  'NAME': 'Please enter valid name',
  'EMAIL': 'Please enter a valid email address',
  'PHONE': 'Please enter a valid phone number',
  'PINCODE': 'Please enter a valid 6-digit pincode',
  'AGE': 'Please enter a valid age',
  'DATE': 'Please select a valid date',
  'OTP_ATTEMPTS_ERROR': 'Maximum resend attempts reached',
  'PHONE_REQUIRED': 'Phone number is required',
};

const kfContent = {
  'PHONE_LABEL': 'Enter Phone Number',
  'OTP_TITLE': 'Verify Your Phone',
  'OTP_SUB_TITLE': "We've sent a 4-digit code to",
  'OTP_LABEL': 'Enter OTP',
  'CONSENT':
      'I agree to use my personal information for future retargeting and other use cases',
  'SSO_CONSENT':
      ' authorize GoKwik & <merchant> to use my data for autofill, marketing & personalization per their Privacy Policies',
};

const kfFieldName = {
  'FIRST_NAME': 'firstName',
  'LAST_NAME': 'lastName',
  'PINCODE': 'pincode',
  'AGE': 'age',
  'EMAIL': 'email',
  'PHONE': 'phone',
  'DATE_OF_BIRTH': 'dateOfBirth',
  'DATE': 'date',
};

const merchantConsentType = {
  'OPT_IN': 'opt_in',
  'OPT_OUT': 'opt_out',
};

const addressErrorMessages = {
  'address': {
    'error': 'Enter complete address including house, street, area & landmark',
    'verify': 'Please verify your address',
    'repeated_words': 'Please remove repeated words for address accuracy',
    'short': 'Address seems to be a bit short, please verify it again.',
  },
  'phone': {
    'invalid': 'Invalid Phone no.',
    'missing': 'Phone no. is required',
    'verify': 'Please verify your Phone No.',
  },
  'email': {
    'invalid': 'Invalid email address',
    'missing': 'Email address is required',
    'existing': 'Email already exist',
  },
  'full-name': 'Full name required',
  'city': {'invalid': 'Enter a valid city', 'missing': 'City is required'},
  'firstname': 'First name required',
  'pincode': {
    'invalid': 'Invalid Pincode',
    'missing': 'Pincode is required',
    'mismatch': 'Mismatched Pincodes detected, please verify',
  },
  'name': {'missing': 'Full name required'},
};

const customErrors = {
  'invalidPaymentMethods':
      'Products in the cart are not eligible for cash on delivery.',
  'invalidAddress':
      'Enter complete address including house, street, area & landmark.',
  'gstRemoveError': 'Could not remove GST. Please try again.',
  'getNetbankingListError':
      'Could not fetch netbanking options. Please try again.',
  'createOrderError': 'Could not create order. Please try again.',
  'getAbcDataError': 'Could not get Abandoned Cart Data. Please try again.',
};

const mobileNumber = {
  'enterPhone': 'Enter your mobile number',
  'countryCode': ' +91',
  'enterOtp': 'To use your saved address, enter the OTP sent to ',
  'resendOtp': 'Resend OTP in',
  'orderOtp': 'Enter the OTP sent to ',
  'messages': {
    'invalidPhoneNumber': 'Please enter a valid mobile number',
    'invalidOtp': 'OTP entered is invalid. Please try again.',
  },
  'truecallerError':
      'Sorry, we are unable to fetch your details currently, please proceed manually',
};

const rtoAddressValidations = {
  'is_bad_quality_phone': {
    'field': 'recipient_phone',
    'type': 'warning',
    'errorMessage': 'Please verify your Phone No.',
    'warning': true,
    'verifyMessage': 'Please verify your Phone No.',
  },
  'is_bad_phone_format': {
    'field': 'recipient_phone',
    'errorMessage': 'Invalid Phone no.',
  },
  'is_bad_pincode': {
    'field': 'pincode',
    'errorMessage': 'Invalid Pincode',
  },
  'is_address_pin_different': {
    'field': 'address',
    'errorMessage': 'Mismatched Pincodes detected, please verify',
  },
  'is_address_gibberish': {
    'field': 'address',
    'errorMessage': 'Enter complete address including house, street, area & landmark',
  },
  'is_address_bad_length': {
    'field': 'address',
    'errorMessage': 'Enter complete address including house, street, area & landmark',
    'warning': true,
    'verify': true,
    'verifyMessage': 'Address seems to be a bit short, please verify it again.',
  },
  'is_subset': {
    'field': 'address',
    'errorMessage': 'Please remove repeated words for address accuracy',
  },
  'is_bad_email_format': {
    'field': 'email',
    'errorMessage': 'Invalid email address',
  },
  'is_test_email': {
    'field': 'email',
    'errorMessage': 'Invalid email address',
  },
  'is_name_missing': {
    'field': 'firstname',
    'errorMessage': 'Full name required',
  },
  'is_name_gibberish': {
    'field': 'firstname',
    'errorMessage': 'Full name required',
  },
  'is_bad_address_score': {
    'field': 'address',
    'errorMessage': 'Enter complete address including house, street, area & landmark',
    'warning': true,
    'verify': true,
    'verifyMessage': 'Please verify your address',
  },
  'is_email_high_phone_count': {
    'field': 'email',
    'errorMessage': 'Email already exist',
  },
  'is_address_short': {
    'field': 'address',
    'errorMessage': 'Address seems to be a bit short, please verify it again.',
    'warning': true,
  },
  'is_email_missing': {
    'field': 'email',
    'errorMessage': 'Email address is required',
  },
};
