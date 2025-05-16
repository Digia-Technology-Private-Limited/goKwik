import 'package:flutter/material.dart';
import 'package:gokwik/screens/root.dart';

// class ShopifyEmailForm extends StatefulWidget {
//   final List<MultipleEmail> multipleEmail;
//   final VoidCallback onSubmit;
//   final bool isLoading;
//   final bool isSuccess;
//   final BoxDecoration? inputContainerStyle;
//   final InputDecoration? inputStyle;
//   // final BoxDecoration? dropdownContainerStyle;
//   // final BoxDecoration? dropdownStyle;
//   final TextStyle? dropdownPlaceholderStyle;
//   final TextStyle? dropdownSelectedTextStyle;
//   final String dropdownPlaceholder;
//   final BoxDecoration? submitButtonStyle;
//   final TextStyle? submitButtonTextStyle;
//   final TextStyle? loadingTextStyle;
//   final String? loadingText;
//   final TextInputConfig? inputConfig;
//   final TextStyle? titleStyle;
//   final TextStyle? subTitleStyle;
//   final FormFieldValidator<String>? validator;
//   final ValueChanged<String>? onChanged;
//   final String? initialValue;

//   const ShopifyEmailForm({
//     super.key,
//     this.multipleEmail = const [],
//     required this.onSubmit,
//     this.isLoading = false,
//     this.isSuccess = false,
//     this.inputContainerStyle,
//     this.inputStyle,
//     // this.dropdownContainerStyle,
//     // this.dropdownStyle,
//     this.dropdownPlaceholderStyle,
//     this.dropdownSelectedTextStyle,
//     this.dropdownPlaceholder = 'Select your email',
//     this.submitButtonStyle,
//     this.submitButtonTextStyle,
//     this.loadingTextStyle,
//     this.loadingText,
//     this.inputConfig,
//     this.titleStyle,
//     this.subTitleStyle,
//     this.validator,
//     this.onChanged,
//     this.initialValue,
//   });

//   @override
//   State<ShopifyEmailForm> createState() => _ShopifyEmailFormState();
// }

// class _ShopifyEmailFormState extends State<ShopifyEmailForm> {
//   final _formKey = GlobalKey<FormState>();
//   String? _selectedEmail;

//   @override
//   void initState() {
//     super.initState();
//     _selectedEmail = widget.initialValue;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final emailPlaceholder =
//         widget.inputConfig?.shopifyEmailScreen?.emailPlaceholder ??
//             'Enter your email';
//     final title =
//         widget.inputConfig?.shopifyEmailScreen?.title ?? 'Submit your details';
//     final submitButtonText =
//         widget.inputConfig?.shopifyEmailScreen?.submitButtonText ?? 'Submit';
//     final subTitle = widget.inputConfig?.shopifyEmailScreen?.subTitle;

//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: widget.titleStyle ??
//                 const TextStyle(
//                   fontSize: 20,
//                   color: Colors.black,
//                 ),
//           ),
//           if (subTitle != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 subTitle,
//                 style: widget.subTitleStyle ??
//                     const TextStyle(
//                       fontSize: 16,
//                       color: Color(0xFF999999),
//                     ),
//               ),
//             ),
//           const SizedBox(height: 16),
//           if (widget.multipleEmail.isNotEmpty)
//             _buildEmailDropdown(emailPlaceholder)
//           else
//             _buildEmailInput(emailPlaceholder),
//           const SizedBox(height: 16),
//           _buildSubmitButton(submitButtonText),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmailInput(String placeholder) {
//     return Container(
//       decoration: widget.inputContainerStyle?.copyWith(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: _hasError() ? Colors.red : Colors.black,
//               width: 1.5,
//             ),
//           ) ??
//           BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: _hasError() ? Colors.red : Colors.black,
//               width: 1.5,
//             ),
//           ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       height: 55,
//       child: Row(
//         children: [
//           Expanded(
//             child: TextFormField(
//               initialValue: _selectedEmail,
//               decoration: widget.inputStyle?.copyWith(
//                     hintText: placeholder,
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: InputBorder.none,
//                     errorBorder: InputBorder.none,
//                     enabledBorder: InputBorder.none,
//                     focusedBorder: InputBorder.none,
//                     disabledBorder: InputBorder.none,
//                     focusedErrorBorder: InputBorder.none,
//                   ) ??
//                   InputDecoration(
//                     hintText: placeholder,
//                     hintStyle: const TextStyle(color: Colors.grey),
//                     border: InputBorder.none,
//                   ),
//               keyboardType: TextInputType.emailAddress,
//               autocorrect: false,
//               enabled: !widget.isLoading && !widget.isSuccess,
//               validator: widget.validator ?? _defaultValidator,
//               onChanged: (value) {
//                 setState(() => _selectedEmail = value);
//                 widget.onChanged?.call(value);
//               },
//               style: const TextStyle(fontSize: 18),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmailDropdown(String placeholder) {
//     return Container(
//       decoration: widget.inputContainerStyle?.copyWith(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: _hasError() ? Colors.red : Colors.black,
//               width: 1.5,
//             ),
//           ) ??
//           BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: _hasError() ? Colors.red : Colors.black,
//               width: 1.5,
//             ),
//           ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       height: 55,
//       child: DropdownButtonFormField<String>(
//         value: _selectedEmail,
//         items: widget.multipleEmail.map((email) {
//           return DropdownMenuItem<String>(
//             value: email.value,
//             child: Text(email.label),
//           );
//         }).toList(),
//         onChanged: (value) {
//           if (value != null) {
//             setState(() => _selectedEmail = value);
//             widget.onChanged?.call(value);
//           }
//         },
//         decoration: InputDecoration(
//           border: InputBorder.none,
//           hintText: _selectedEmail ?? widget.dropdownPlaceholder,
//           hintStyle:
//               widget.dropdownPlaceholderStyle ?? const TextStyle(fontSize: 16),
//         ),
//         style: widget.dropdownSelectedTextStyle ??
//             const TextStyle(fontSize: 16, color: Colors.black),
//         dropdownColor: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         icon: const Icon(Icons.arrow_drop_down),
//         validator: widget.validator ?? _defaultValidator,
//         isExpanded: true,
//         menuMaxHeight: 300,
//       ),
//     );
//   }

//   Widget _buildSubmitButton(String text) {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor:
//               widget.submitButtonStyle?.color ?? const Color(0xFF007BFF),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         onPressed: () {
//           if (_formKey.currentState!.validate()) {
//             widget.onSubmit();
//           }
//         },
//         child: widget.isLoading
//             ? Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   if (widget.loadingText != null)
//                     Text(
//                       widget.loadingText!,
//                       style: widget.loadingTextStyle,
//                     )
//                   else
//                     const CircularProgressIndicator(
//                       color: Colors.white,
//                     ),
//                 ],
//               )
//             : Text(
//                 text,
//                 style: widget.submitButtonTextStyle ??
//                     const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//               ),
//       ),
//     );
//   }

//   bool _hasError() {
//     if (_formKey.currentState == null) return false;
//     return !_formKey.currentState!.validate();
//   }

//   String? _defaultValidator(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Email is required';
//     }
//     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//       return 'Enter a valid email address';
//     }
//     return null;
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShopifyEmailForm extends StatefulWidget {
  final List<MultipleEmail> multipleEmail;
  final ValueChanged<String> onSubmitEmail;
  final bool isLoading;
  final bool isSuccess;
  final LoadingConfig? loaderConfig;
  final ShopifyEmailScreenConfig? config;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const ShopifyEmailForm({
    Key? key,
    this.multipleEmail = const [],
    required this.onSubmitEmail,
    this.isLoading = false,
    this.isSuccess = false,
    this.config,
    this.loaderConfig,
    this.onChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  _ShopifyEmailFormState createState() => _ShopifyEmailFormState();
}

class _ShopifyEmailFormState extends State<ShopifyEmailForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmail;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedEmail = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final emailPlaceholder =
        widget.config?.emailPlaceholder ?? 'Enter your email';
    final title = widget.config?.title ?? 'Submit your details';
    final submitButtonText = widget.config?.submitButtonText ?? 'Submit';
    final subTitle = widget.config?.subTitle;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: widget.config?.titleStyle ??
                const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                ),
          ),
          if (subTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subTitle,
              style: widget.config?.subTitleStyle ??
                  const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF999999),
                  ),
            ),
          ],
          const SizedBox(height: 16),
          if (widget.multipleEmail.isNotEmpty)
            _buildEmailDropdown(emailPlaceholder)
          else
            _buildEmailInput(emailPlaceholder),
          if (_errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: widget.config?.submitButtonStyle ??
                  ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmitEmail(_selectedEmail ?? '');
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
                      submitButtonText,
                      style: widget.config?.submitButtonTextStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput(String placeholder) {
    return Container(
      decoration: widget.config?.inputContainerStyle?.copyWith(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null ? Colors.red : Colors.black,
              width: 1.5,
            ),
          ) ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null ? Colors.red : Colors.black,
              width: 1.5,
            ),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 55,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: _selectedEmail,
              decoration: widget.config?.inputStyle?.copyWith(
                    hintText: placeholder,
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ) ??
                  InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !widget.isLoading && !widget.isSuccess,
              validator: widget.config?.validator ?? _defaultValidator,
              onChanged: (value) {
                setState(() {
                  _selectedEmail = value;
                  _errorText = null;
                });
                widget.onChanged?.call(value);
              },
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDropdown(String placeholder) {
    return Container(
      decoration: widget.config?.inputContainerStyle?.copyWith(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null ? Colors.red : Colors.black,
              width: 1.5,
            ),
          ) ??
          BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null ? Colors.red : Colors.black,
              width: 1.5,
            ),
          ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 55,
      child: DropdownButtonFormField<String>(
        value: _selectedEmail,
        items: widget.multipleEmail.map((email) {
          return DropdownMenuItem<String>(
            value: email.value,
            child: Text(email.label),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedEmail = value;
              _errorText = null;
            });
            widget.onChanged?.call(value);
          }
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: _selectedEmail ?? widget.config?.dropdownPlaceholder,
          hintStyle: widget.config?.dropdownPlaceholderStyle ??
              const TextStyle(fontSize: 16),
        ),
        style: widget.config?.dropdownSelectedTextStyle ??
            const TextStyle(fontSize: 16, color: Colors.black),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.arrow_drop_down),
        validator: widget.config?.validator ?? _defaultValidator,
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      setState(() => _errorText = 'Email is required');
      return _errorText;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      setState(() => _errorText = 'Enter a valid email address');
      return _errorText;
    }
    setState(() => _errorText = null);
    return null;
  }
}
