import 'package:flutter/material.dart';
import 'package:gokwik/screens/root.dart';

class LoginForm {
  String phone;
  bool notifications;

  LoginForm({
    this.phone = '',
    this.notifications = true,
  });
}

class Login extends StatefulWidget {
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

  const Login({
    Key? key,
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
  }) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.formData.phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: widget.titleStyle ??
                  const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (widget.subTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.subTitle!,
                style: widget.subTitleStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: widget.placeholderText,
              border: const OutlineInputBorder(),
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Text('+1', style: TextStyle(fontSize: 16)),
              ),
              errorStyle: const TextStyle(color: Colors.red),
            ),
            style: widget.inputStyle,
            keyboardType: TextInputType.phone,
            enabled: !widget.isLoading && !widget.isSuccess,
            maxLength: 10,
            validator: _validatePhone,
            onChanged: (value) {
              widget.onFormChanged(LoginForm(
                phone: value,
                notifications: widget.formData.notifications,
              ));
            },
          ),
          const SizedBox(height: 16),
          if (widget.checkboxComponent != null)
            widget.checkboxComponent!(
              widget.formData.notifications,
              (value) {
                widget.onFormChanged(LoginForm(
                  phone: widget.formData.phone,
                  notifications: value,
                ));
              },
            )
          else
            InkWell(
              onTap: () {
                final newValue = !widget.formData.notifications;
                widget.onFormChanged(LoginForm(
                  phone: widget.formData.phone,
                  notifications: newValue,
                ));
              },
              child: Padding(
                padding: widget.checkboxContainerPadding ??
                    const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: widget.checkboxDecoration ??
                          BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF0964C5), width: 2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                      child: widget.formData.notifications
                          ? Container(
                              decoration: widget.checkedDecoration ??
                                  BoxDecoration(
                                    color: const Color(0xFF0964C5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.updateText,
                      style: widget.updatesTextStyle ??
                          const TextStyle(
                              fontSize: 16, color: Color(0xFFA8A2A2)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: widget.submitButtonStyle ??
                  ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
              onPressed: widget.isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit();
                      }
                    },
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.submitButtonText,
                      style: widget.submitButtonTextStyle ??
                          const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
