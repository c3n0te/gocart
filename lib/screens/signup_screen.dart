import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/globals/auth_notifier.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/globals/regex.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SignupScreen extends ConsumerStatefulWidget {
   const SignupScreen({super.key});

   @override
   ConsumerState<SignupScreen> createState() => _SignupScreenState();
 }

 class _SignupScreenState extends ConsumerState<SignupScreen> {
    bool _isLoading = false; // Track loading state
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _passwordConfirmController = TextEditingController();

    @override
    Widget build(BuildContext context) {  
      return Scaffold(
          body: Center(          
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                    }
                    ),
                    const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExPatterns.email.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    }
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                    ),
                    validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                    }
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                    ),
                    obscureText: true,
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
                    controller: _passwordConfirmController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                    ),
                    obscureText: true,
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
                  _isLoading ? const SpinKitWave(size: 30.0, color: Colors.black) : 
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to the previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),// Make button full width
                          backgroundColor: Colors.black, // Change button color to black
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          await ref.read(authProvider.notifier).signup(
                            _usernameController.text.trim(),
                            _emailController.text.trim(),
                            _nameController.text.trim(),
                            _passwordController.text.trim(),
                            _passwordConfirmController.text.trim(),
                          );
                          
                          setState(() {
                            _isLoading = false;
                          });
                          
                          if (!context.mounted) return; // Check if the widget is still mounted
                          
                          if (pb.authStore.isValid) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signup failed. Please check your credentials.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50), // Make button full width
                          backgroundColor: Colors.black, // Change button color to black
                          foregroundColor: Colors.white, // Change text color to white
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
 }