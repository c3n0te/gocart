import 'package:flutter/material.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/main.dart';
import 'package:gocart/screens/account_screen.dart';
import 'package:gocart/screens/signup_screen.dart';
import 'package:gocart/screens/forgot_password_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RegExPatterns {
  static final RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp hasUppercase = RegExp(r'[A-Z]');
  static final RegExp hasLowercase = RegExp(r'[a-z]');
  static final RegExp hasDigits = RegExp(r'[0-9]');
  static final RegExp hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // Track loading state
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    try {
      await pb.collection('users').authWithPassword(
        _emailController.text,
        _passwordController.text,
      );
      // Handle successful login, e.g., navigate to another screen
    } catch (e) {
      logger.e('Login failed: $e'); // Handle login error, e.g., show a snackbar or dialog
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return pb.authStore.isValid ? 
    AccountScreen() :
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              const SizedBox(height: 45),
              Text('Welcome', style: TextStyle(fontSize: 24)),
              Text('Sign in to continue'),
              const SizedBox(height: 45),
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
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
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
              _isLoading ? const SpinKitWave(
                color: Colors.black,
                size: 30.0,
                type: SpinKitWaveType.center, // Options: .start, .end, .center
              ) : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      await _login();

                      setState(() {
                        _isLoading = false;
                      });

                      if (!context.mounted) return;
                      
                      if (pb.authStore.isValid) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Login failed. Please check your credentials.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50), // Full width button
                      backgroundColor: Colors.black, // Change button color to black
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign in', style: TextStyle(fontSize: 18),),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                    },
                    child: const Text(
                      "Forgot Password?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline, // Gives it a hyperlink look
                      ),
                    ),
                  ),   
                  const SizedBox(height: 16),                             
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                        },
                        child: const Text(
                          "Sign up.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline, // Gives it a hyperlink look
                          ),
                        ),
                      ),
                    ],
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