import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gocart/globals/regex.dart';
import 'package:gocart/globals/auth_notifier.dart';
import 'package:gocart/globals/pocketbase.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _newPasswordConfirmController =
      TextEditingController();

  String? _validatePassword(String? value) {
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
  }

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
                validator: _validatePassword,
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                validator: _validatePassword,
                obscureText: true,
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
                validator: _validatePassword,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? SpinKitWave(size: 30.0, color: Colors.black)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });

                              await ref
                                  .read(authProvider.notifier)
                                  .updatePassword(
                                    _currentPasswordController.text.trim(),
                                    _newPasswordController.text.trim(),
                                    _newPasswordConfirmController.text.trim(),
                                  );

                              setState(() {
                                _isLoading = false;
                              });

                              if (!context.mounted) return;

                              if (pb.authStore.isValid) {
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Update failed. Please check your credentials.',
                                    ),
                                  ),
                                );
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                50,
                              ), // Full width button
                              backgroundColor:
                                  Colors.black, // Change button color to black
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(
                                double.infinity,
                                50,
                              ), // Full width button
                              backgroundColor:
                                  Colors.black, // Change button color to black
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
