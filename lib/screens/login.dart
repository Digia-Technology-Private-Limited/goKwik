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

  final LoginForm formData;
  final Function(LoginForm) onFormChanged;
  final PhoneAuthScreenConfig? config;
  final LoadingConfig? loaderConfig;
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String placeholderText;
  final String updateText;
  final TextStyle? updatesTextStyle;
  final Widget Function(bool, Function(bool))? checkboxComponent;
  final EdgeInsetsGeometry? checkboxContainerPadding;
  final BoxDecoration? checkboxDecoration;
  final BoxDecoration? checkedDecoration;

  const Login({
    super.key,
    required this.onSubmit,
    required this.formData,
    required this.onFormChanged,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.placeholderText = 'Enter your phone',
    this.updateText = 'Get updates on WhatsApp',
    this.updatesTextStyle,
    this.checkboxComponent,
    this.checkboxContainerPadding,
    this.checkboxDecoration,
    this.checkedDecoration,
    this.config,
    this.loaderConfig,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
/*  String? _errorText;*/
  static const _phoneRegex = r'^[0-9]{10}$';

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
    if (!RegExp(_phoneRegex).hasMatch(value)) {
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
          const SizedBox(height: 10),
          Text(
            widget.config?.title ?? "Login/ Signup",
            style: widget.config?.titleTextStyle ??
                const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            widget.config?.subTitle ?? "Enter your phone number to continue",
            style: widget.config?.subtitleTextStyle ??
                const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            decoration: widget.config?.textFieldInputStyle ??
                const InputDecoration(
                  labelText: 'Enter your phone',
                  border: OutlineInputBorder(),
                  errorStyle: TextStyle(color: Colors.red),
                  counterText: "",
                ),
            style: widget.config?.inputTextStyle,
            keyboardType: TextInputType.phone,
            enabled: !widget.isLoading && !widget.isSuccess,
            maxLength: 10,
            validator: _validatePhone,
            onChanged: (value) {
              widget.onFormChanged(LoginForm(
                phone: value,
                notifications: widget.formData.notifications,
              ));
              if (value.length == 10 && _validatePhone(value) == null) {
                widget.onSubmit();
              }
            },
          ),
          const SizedBox(height: 10),
          if (widget.config?.checkboxComponent != null)
            widget.config!.checkboxComponent!(
              widget.formData.notifications,
              (value) {
                widget.onFormChanged(LoginForm(
                  phone: widget.formData.phone,
                  notifications: value,
                ));
              },
            )
          else
            GestureDetector(
              onTap: () {
                final newValue = !widget.formData.notifications;
                widget.onFormChanged(LoginForm(
                  phone: widget.formData.phone,
                  notifications: newValue,
                ));
              },
              child: Padding(
                padding: widget.config?.checkboxContainerPadding ??
                    const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: widget.config?.checkboxContainerStyle ??
                          BoxDecoration(
                            border:
                                Border.all(color: const Color(0xFF0964C5), width: 2),
                            borderRadius: const BorderRadius.all(Radius.circular(5)),
                          ),
                      child: widget.formData.notifications
                          ? Container(
                              decoration: widget.config?.checkboxStyle ??
                                  const BoxDecoration(
                                    color: Color(0xFF0964C5),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(3)),
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
                      widget.config?.updatesPlaceholder ??
                          'Get updates on WhatsApp',
                      style: widget.config?.updatesTextStyle ??
                          const TextStyle(
                              fontSize: 16, color: Color(0xFFA8A2A2)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: widget.config?.submitButtonStyle ??
                  ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF007AFF),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
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
                  ? widget.loaderConfig != null
                      ? Text(
                          widget.loaderConfig?.loadingText ?? 'Loading...',
                          style: widget.loaderConfig?.loadingTextStyle,
                        )
                      : const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                  : Text(
                      widget.config?.submitButtonText ?? 'Continue',
                      style: widget.config?.submitButtonTextStyle ??
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
