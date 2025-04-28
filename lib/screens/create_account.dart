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
    this.isEmailRequired = false,
    this.isNameRequired = false,
    this.isGenderRequired = false,
    this.isDobRequired = false,
    this.createAccountError,
    this.showEmail = true,
    this.showUserName = true,
    this.showGender = true,
    this.showDob = true,
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

  void _submitForm(RootCubit cubit) {
    cubit.handleCreateUser();
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

    return BlocBuilder<RootCubit, RootState>(
      builder: (context, state) {
        final cubit = context.read<RootCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.createUserScreen?.title ?? '',
              style: widget.titleStyle ??
                  const TextStyle(fontSize: 20, color: Colors.black),
            ),
            if (config.createUserScreen?.subTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  config.createUserScreen?.subTitle ?? '',
                  style: widget.subTitleStyle ??
                      const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            if (widget.showEmail)
              TextFormField(
                controller: cubit.emailController,
                decoration: InputDecoration(
                  labelText: config.createUserScreen?.emailPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !state.isLoading && !state.isSuccess,
                validator: _validateEmail,
              ),
            if (widget.showEmail) const SizedBox(height: 16),
            if (widget.showUserName)
              TextFormField(
                controller: cubit.usernameController,
                decoration: InputDecoration(
                  labelText: config.createUserScreen?.namePlaceholder,
                  border: const OutlineInputBorder(),
                ),
                enabled: !state.isLoading && !state.isSuccess,
                validator: _validateName,
              ),
            if (widget.showUserName) const SizedBox(height: 16),
            if (widget.showDob)
              ValueListenableBuilder(
                  valueListenable: cubit.dobController,
                  builder: (context, dob, child) {
                    return InkWell(
                      onTap: state.isLoading || state.isSuccess
                          ? null
                          : () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dob ?? DateTime.now(),
                                firstDate: DateTime(1900, 1, 1),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                // Update the dob using your Cubit or Bloc
                                dob = pickedDate;
                              }
                            },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: config.createUserScreen?.dobPlaceholder,
                          border: const OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dob != null
                                  ? DateFormat(dobFormat)
                                      .format(dob ?? DateTime.now())
                                  : '',
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
                              '',
                          style: config.createUserScreen?.genderTitleStyle ??
                              const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: genders.map((gender) {
                            return Row(
                              children: [
                                Radio<String>(
                                  value: gender,
                                  groupValue: gender,
                                  onChanged: state.isLoading || state.isSuccess
                                      ? null
                                      : (value) {
                                          gender = value ?? 'Male';
                                        },
                                ),
                                Text(gender,
                                    style: config
                                        .createUserScreen?.radioTextStyle),
                                const SizedBox(width: 16),
                              ],
                            );
                          }).toList(),
                        ),
                        if (_validateGender(gender) != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              _validateGender(gender) ?? '',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  }),
            if (widget.showGender) const SizedBox(height: 24),
            ElevatedButton(
              style: widget.submitButtonStyle,
              onPressed: () => state.isLoading ? null : _submitForm(cubit),
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      config.createUserScreen?.submitButtonText ?? '',
                      style: widget.submitButtonTextStyle ??
                          const TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }
}
