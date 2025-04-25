import 'package:flutter/material.dart';
import 'package:gokwik/screens/root.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

class CreateAccountForm {
  String email;
  String username;
  String gender;
  DateTime? dob;

  CreateAccountForm({
    this.email = '',
    this.username = '',
    this.gender = '',
    this.dob,
  });
}

class InputConfig {
  final String title;
  final String? subTitle;
  final String emailPlaceholder;
  final String namePlaceholder;
  final String dobPlaceholder;
  final String genderPlaceholder;
  final String submitButtonText;
  final String dobFormat;
  final TextStyle? radioTextStyle;
  final String? genderTitle;
  final TextStyle? genderTitleStyle;

  InputConfig({
    this.title = 'Submit your details',
    this.subTitle,
    this.emailPlaceholder = 'Enter your email',
    this.namePlaceholder = 'Enter your name',
    this.dobPlaceholder = 'Enter your date of birth',
    this.genderPlaceholder = 'Select your gender',
    this.submitButtonText = 'Submit',
    this.dobFormat = 'dd MMM, yyyy',
    this.radioTextStyle,
    this.genderTitle,
    this.genderTitleStyle,
  });
}

class CreateAccount extends StatefulWidget {
  final bool isEmailRequired;
  final bool isNameRequired;
  final bool isGenderRequired;
  final bool isDobRequired;
  final dynamic createAccountError;
  final bool showEmail;
  final bool showUserName;
  final bool showGender;
  final bool showDob;
  final Function(CreateAccountForm) onSubmit;
  final Function(dynamic) onError;
  final TextStyle? inputStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final ButtonStyle? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  final bool isLoading;
  final bool isSuccess;
  final TextInputConfig inputConfig;

  CreateAccount({
    this.isEmailRequired = false,
    this.isNameRequired = false,
    this.isGenderRequired = false,
    this.isDobRequired = false,
    this.createAccountError,
    this.showEmail = true,
    this.showUserName = true,
    this.showGender = true,
    this.showDob = true,
    required this.onSubmit,
    required this.onError,
    this.inputStyle,
    this.titleStyle,
    this.subTitleStyle,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    this.isLoading = false,
    this.isSuccess = false,
    required this.inputConfig,
  });

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  CreateAccountForm _formData = CreateAccountForm();
  final List<String> genders = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    if (widget.createAccountError != null) {
      _handleError(widget.createAccountError);
    }
  }

  @override
  void didUpdateWidget(CreateAccount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createAccountError != oldWidget.createAccountError) {
      _handleError(widget.createAccountError);
    }
  }

  void _handleError(dynamic error) {
    // Handle error state if needed
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      widget.onSubmit(_formData);
    }
  }

  String? _validateEmail(String? value) {
    if (widget.isEmailRequired && (value == null || value.isEmpty)) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (widget.isNameRequired && (value == null || value.isEmpty)) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (widget.isGenderRequired && (value == null || value.isEmpty)) {
      return 'Gender is required';
    }
    return null;
  }

  String? _validateDob(DateTime? value) {
    if (widget.isDobRequired && value == null) {
      return 'Your date of birth is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.inputConfig;
    final dobFormat = config.createUserScreen?.dobFormat ?? 'dd MMM, yyyy';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.createUserScreen?.title ?? '',
            style: widget.titleStyle ??
                TextStyle(fontSize: 20, color: Colors.black),
          ),
          if (config.createUserScreen?.subTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                config.createUserScreen?.subTitle ?? '',
                style: widget.subTitleStyle ??
                    TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          SizedBox(height: 16),
          if (widget.showEmail)
            TextFormField(
              decoration: InputDecoration(
                labelText: config.createUserScreen?.emailPlaceholder,
                errorText: _validateEmail(_formData.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !widget.isLoading && !widget.isSuccess,
              validator: _validateEmail,
              onSaved: (value) => _formData.email = value ?? '',
            ),
          if (widget.showEmail) SizedBox(height: 16),
          if (widget.showUserName)
            TextFormField(
              decoration: InputDecoration(
                labelText: config.createUserScreen?.namePlaceholder,
                errorText: _validateName(_formData.username),
                border: OutlineInputBorder(),
              ),
              enabled: !widget.isLoading && !widget.isSuccess,
              validator: _validateName,
              onSaved: (value) => _formData.username = value ?? '',
            ),
          if (widget.showUserName) SizedBox(height: 16),
          if (widget.showDob)
            InkWell(
              onTap: widget.isLoading || widget.isSuccess
                  ? null
                  : () {
                      DatePicker.showDatePicker(
                        context,
                        showTitleActions: true,
                        minTime: DateTime(1900, 1, 1),
                        maxTime: DateTime.now(),
                        onConfirm: (date) {
                          setState(() {
                            _formData.dob = date;
                          });
                        },
                      );
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: config.createUserScreen?.dobPlaceholder,
                  errorText: _validateDob(_formData.dob),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formData.dob != null
                          ? DateFormat(dobFormat)
                              .format(_formData.dob ?? DateTime.now())
                          : '',
                      style: _formData.dob != null
                          ? widget.inputStyle ?? TextStyle(fontSize: 18)
                          : TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
          if (widget.showDob) SizedBox(height: 16),
          if (widget.showGender)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.createUserScreen?.genderTitle ??
                      config.createUserScreen?.genderPlaceholder ??
                      '',
                  style: config.createUserScreen?.genderTitleStyle ??
                      const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                SizedBox(height: 8),
                Row(
                  children: genders.map((gender) {
                    return Row(
                      children: [
                        Radio<String>(
                          value: gender,
                          groupValue: _formData.gender,
                          onChanged: widget.isLoading || widget.isSuccess
                              ? null
                              : (value) {
                                  setState(() {
                                    _formData.gender = value ?? 'Male';
                                  });
                                },
                        ),
                        Text(gender,
                            style: config.createUserScreen?.radioTextStyle),
                        SizedBox(width: 16),
                      ],
                    );
                  }).toList(),
                ),
                if (_validateGender(_formData.gender) != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      _validateGender(_formData.gender) ?? '',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          if (widget.showGender) SizedBox(height: 24),
          ElevatedButton(
            style: widget.submitButtonStyle,
            onPressed: widget.isLoading ? null : _submitForm,
            child: widget.isLoading
                ? CircularProgressIndicator()
                : Text(
                    config.createUserScreen?.submitButtonText ?? '',
                    style: widget.submitButtonTextStyle ??
                        TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
