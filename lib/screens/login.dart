import 'package:flutter/material.dart';
import 'package:gokwik/screens/root.dart';

class LoginForm {
  String phone;
  bool notifications;
  String otp;
  bool otpSent;
  bool isNewUser;
  List<MultipleEmail> multipleEmail;
  bool emailOtpSent;
  String shopifyEmail;
  String shopifyOTP;
  bool isSuccess;

  LoginForm({
    this.phone = '',
    this.notifications = true,
    this.otp = '',
    this.otpSent = false,
    this.isNewUser = false,
    this.multipleEmail = const [],
    this.emailOtpSent = false,
    this.shopifyEmail = '',
    this.shopifyOTP = '',
    this.isSuccess = false,
  });
}

class Login extends StatelessWidget {
  final VoidCallback onSubmit;
  final String? title;
  final String? subTitle;
  final LoginForm formData;
  final Function(LoginForm) onFormChanged;
  final String submitButtonText;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final ButtonStyle? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final TextStyle? inputStyle;
  final bool isLoading;
  final bool isSuccess;
  final String placeholderText;
  final String updateText;
  final TextStyle? updatesTextStyle;
  final Widget Function(bool, Function(bool))? checkboxComponent;
  final EdgeInsetsGeometry? checkboxContainerPadding;
  final BoxDecoration? checkboxDecoration;
  final BoxDecoration? checkedDecoration;

  Login({
    required this.onSubmit,
    required this.formData,
    required this.onFormChanged,
    this.title,
    this.subTitle,
    this.submitButtonText = 'Continue',
    this.titleStyle,
    this.subTitleStyle,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    this.inputStyle,
    this.isLoading = false,
    this.isSuccess = false,
    this.placeholderText = 'Enter your phone',
    this.updateText = 'Get updates on WhatsApp',
    this.updatesTextStyle,
    this.checkboxComponent,
    this.checkboxContainerPadding,
    this.checkboxDecoration,
    this.checkedDecoration,
  });

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: titleStyle ?? TextStyle(fontSize: 20, color: Colors.black),
          ),
        if (subTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subTitle!,
              style:
                  subTitleStyle ?? TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: placeholderText,
            errorText: _validatePhone(formData.phone),
            border: OutlineInputBorder(),
            // You can add a prefix icon for flag here
            // prefixIcon: Image.network(
            //   'https://cdn.pixabay.com/photo/2022/07/14/17/15/flag-7321641_1280.png',
            //   width: 35,
            //   height: 25,
            // ),
          ),
          keyboardType: TextInputType.phone,
          enabled: !isLoading && !isSuccess,
          maxLength: 10,
          validator: _validatePhone,
          onChanged: (value) {
            onFormChanged(LoginForm(
              phone: value,
              notifications: formData.notifications,
            ));
          },
        ),
        SizedBox(height: 16),
        if (checkboxComponent != null)
          checkboxComponent!(
            formData.notifications,
            (value) {
              onFormChanged(LoginForm(
                phone: formData.phone,
                notifications: value,
              ));
            },
          )
        else
          InkWell(
            onTap: () {
              onFormChanged(LoginForm(
                phone: formData.phone,
                notifications: !formData.notifications,
              ));
            },
            child: Padding(
              padding: checkboxContainerPadding ?? EdgeInsets.zero,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: checkboxDecoration ??
                        BoxDecoration(
                          border:
                              Border.all(color: Color(0xFF0964C5), width: 2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                    child: formData.notifications
                        ? Container(
                            decoration: checkedDecoration ??
                                BoxDecoration(
                                  color: Color(0x9E0964C5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                          )
                        : null,
                  ),
                  SizedBox(width: 8),
                  Text(
                    updateText,
                    style: updatesTextStyle ??
                        TextStyle(fontSize: 16, color: Color(0xFFA8A2A2)),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 24),
        ElevatedButton(
          style: submitButtonStyle ??
              ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 35),
                backgroundColor: Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
                  submitButtonText,
                  style: submitButtonTextStyle ??
                      TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
        ),
      ],
    );
  }
}
