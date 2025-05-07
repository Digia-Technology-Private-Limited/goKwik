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

  const Login({
    Key? key,
    required this.onSubmit,
    required this.formData,
    required this.onFormChanged,
    this.isLoading = false,
    this.isSuccess = false,
    this.config,
    this.loaderConfig,
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
          if (widget.config?.title != null)
            Text(
              widget.config!.title!,
              style: widget.config?.titleTextStyle ??
                  const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (widget.config?.subTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.config!.subTitle!,
                style: widget.config?.subtitleTextStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: widget.config?.textFieldInputStyle ??
                InputDecoration(
                  labelText: widget.config?.phoneNumberPlaceholder,
                  border: const OutlineInputBorder(),
                  errorStyle: const TextStyle(color: Colors.red),
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
            },
          ),
          const SizedBox(height: 16),
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
            InkWell(
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
                            border: Border.all(
                                color: const Color(0xFF0964C5), width: 2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                      child: widget.formData.notifications
                          ? Container(
                              decoration: widget.config?.checkboxStyle ??
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: widget.config?.submitButtonStyle ??
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
                  ? widget.loaderConfig != null
                      ? Text(
                          widget.loaderConfig?.loadingText ?? 'Loading...',
                          style: widget.loaderConfig?.loadingTextStyle,
                        )
                      : const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
