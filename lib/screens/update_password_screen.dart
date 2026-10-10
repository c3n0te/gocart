import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/globals/regex.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newPasswordConfirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Update Password', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 45),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExPatterns.hasUppercase.hasMatch(value)) {
                    return 'Must contain at least one uppercase letter';
                  }
                  if (!RegExPatterns.hasLowercase.hasMatch(value)) {
                    return 'Must contain at least one lowercase letter';
                  }
                  if (!RegExPatterns.hasDigits.hasMatch(value)) {
                    return 'Must contain at least one number';
                  }
                  if (!RegExPatterns.hasSpecialChar.hasMatch(value)) {
                    return 'Must contain at least one special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0,),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExPatterns.hasUppercase.hasMatch(value)) {
                    return 'Must contain at least one uppercase letter';
                  }
                  if (!RegExPatterns.hasLowercase.hasMatch(value)) {
                    return 'Must contain at least one lowercase letter';
                  }
                  if (!RegExPatterns.hasDigits.hasMatch(value)) {
                    return 'Must contain at least one number';
                  }
                  if (!RegExPatterns.hasSpecialChar.hasMatch(value)) {
                    return 'Must contain at least one special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordConfirmController,
                decoration: InputDecoration(
                  labelText: 'New Password Confirm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  if (!RegExPatterns.hasUppercase.hasMatch(value)) {
                    return 'Must contain at least one uppercase letter';
                  }
                  if (!RegExPatterns.hasLowercase.hasMatch(value)) {
                    return 'Must contain at least one lowercase letter';
                  }
                  if (!RegExPatterns.hasDigits.hasMatch(value)) {
                    return 'Must contain at least one number';
                  }
                  if (!RegExPatterns.hasSpecialChar.hasMatch(value)) {
                    return 'Must contain at least one special character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}