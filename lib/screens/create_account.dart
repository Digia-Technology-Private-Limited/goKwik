import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gokwik/screens/cubit/root_cubit.dart';
import 'package:gokwik/screens/cubit/root_model.dart';
import 'package:gokwik/screens/root.dart';
import 'package:intl/intl.dart';
// import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

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
  // final Function(CreateAccountForm) onSubmit;
  final TextStyle? inputStyle;
  final TextStyle? titleStyle;
  final TextStyle? subTitleStyle;
  final ButtonStyle? submitButtonStyle;
  final TextStyle? submitButtonTextStyle;
  // final bool isLoading;
  // final bool isSuccess;
  final TextInputConfig inputConfig;

  const CreateAccount({
    super.key,
    this.isEmailRequired = true,
    this.isNameRequired = true,
    this.isGenderRequired = false,
    this.isDobRequired = false,
    this.createAccountError,
    this.showEmail = true,
    this.showUserName = true,
    this.showGender = false,
    this.showDob = false,
    // required this.onSubmit,
    this.inputStyle,
    this.titleStyle,
    this.subTitleStyle,
    this.submitButtonStyle,
    this.submitButtonTextStyle,
    // this.isLoading = false,
    // this.isSuccess = false,
    required this.inputConfig,
  });

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final List<String> genders = ['Male', 'Female'];
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _nameError;
  String? _genderError;
  String? _dobError;

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
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateForm(RootCubit cubit) {
    setState(() {
      _emailError = _validateEmail(cubit.emailController.text);
      _nameError = _validateName(cubit.usernameController.text);
      _genderError = _validateGender(cubit.genderController.value);
      _dobError = _validateDob(cubit.dobController.value);
    });
    if (widget.isGenderRequired &&
        widget.isDobRequired &&
        widget.isNameRequired &&
        widget.isEmailRequired) {
      if (_emailError == null &&
          _nameError == null &&
          _genderError == null &&
          _dobError == null) {
        //_submitForm(cubit);
        debugPrint("Called");
      }
    } else if (widget.isNameRequired && widget.isEmailRequired) {
      if (_emailError == null && _nameError == null) {
        //_submitForm(cubit);
        debugPrint("Second Called");
      }
    }
  }

  void _submitForm(RootCubit cubit) {
    cubit.handleCreateUser();
  }

  String? _validateEmail(String? value) {
    if (widget.isEmailRequired && (value == null || value.isEmpty)) {
      return 'Email is required';
    }
    if (widget.isEmailRequired &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
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

    return BlocBuilder<RootCubit, RootState>(
      builder: (context, state) {
        final cubit = context.read<RootCubit>();
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.createUserScreen?.title ?? 'Enter your details',
                style: widget.titleStyle ??
                    const TextStyle(fontSize: 20, color: Colors.black),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  config.createUserScreen?.subTitle ??
                      'Enter your details to continue',
                  style: widget.subTitleStyle ??
                      const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.showEmail)
                TextFormField(
                  controller: cubit.emailController,
                  decoration: InputDecoration(
                    labelText: config.createUserScreen?.emailPlaceholder ??
                        "Enter your email",
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !state.isLoading && !state.isSuccess,
                  onChanged: (value) {
                    setState(() {
                      _emailError = _validateEmail(value);
                    });
                  },
                  validator: _validateEmail,
                ),
              if (widget.showEmail) const SizedBox(height: 16),
              if (widget.showUserName)
                TextFormField(
                  controller: cubit.usernameController,
                  decoration: InputDecoration(
                    labelText: config.createUserScreen?.namePlaceholder ??
                        "Enter your name",
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                  ),
                  enabled: !state.isLoading && !state.isSuccess,
                  onChanged: (value) {
                    setState(() {
                      _nameError = _validateName(value);
                    });
                  },
                  validator: _validateName,
                ),
              if (widget.showUserName) const SizedBox(height: 16),
              if (widget.showDob)
                ValueListenableBuilder(
                    valueListenable: cubit.dobController,
                    builder: (context, dob, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: state.isLoading || state.isSuccess
                                ? null
                                : () async {
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: dob ?? DateTime.now(),
                                      firstDate: DateTime(1900, 1, 1),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null) {
                                      cubit.dobController.value = pickedDate;
                                      setState(() {
                                        _dobError = _validateDob(pickedDate);
                                      });
                                    }
                                  },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText:
                                    config.createUserScreen?.dobPlaceholder ??
                                        "Select your date of birth",
                                border: const OutlineInputBorder(),
                                errorText: _dobError,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dob != null
                                        ? DateFormat(dobFormat)
                                            .format(dob ?? DateTime.now())
                                        : 'Select your date of birth',
                                    style: dob != null
                                        ? widget.inputStyle ??
                                            const TextStyle(fontSize: 18)
                                        : const TextStyle(
                                            fontSize: 18, color: Colors.grey),
                                  ),
                                  const Icon(Icons.calendar_today),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
              if (widget.showDob) const SizedBox(height: 16),
              if (widget.showGender)
                ValueListenableBuilder(
                    valueListenable: cubit.genderController,
                    builder: (context, gender, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.createUserScreen?.genderTitle ??
                                config.createUserScreen?.genderPlaceholder ??
                                'Select your gender',
                            style: config.createUserScreen?.genderTitleStyle ??
                                const TextStyle(
                                    fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: genders.map((genderOption) {
                              return Row(
                                children: [
                                  Radio<String>(
                                    value: genderOption,
                                    groupValue: gender,
                                    onChanged:
                                        state.isLoading || state.isSuccess
                                            ? null
                                            : (value) {
                                                cubit.genderController.value =
                                                    value ?? 'Male';
                                                setState(() {
                                                  _genderError =
                                                      _validateGender(value);
                                                });
                                              },
                                  ),
                                  Text(genderOption,
                                      style: config
                                          .createUserScreen?.radioTextStyle),
                                  const SizedBox(width: 16),
                                ],
                              );
                            }).toList(),
                          ),
                          if (_genderError != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Text(
                                _genderError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    }),
              if (widget.showGender) const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      state.isLoading ? null : _validateForm(cubit),
                  child: state.isSuccess
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Signing you in...',
                              style: widget.submitButtonTextStyle ??
                                  const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                            )
                          ],
                        )
                      : state.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              config.createUserScreen?.submitButtonText ??
                                  'Submit',
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
      },
    );
  }
}
