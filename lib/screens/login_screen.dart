import 'package:flutter/material.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';
import 'package:gocart/main.dart';
import 'package:gocart/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // Track loading state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      await pb.collection('users').authWithPassword(
        _emailController.text,
        _passwordController.text,
      );
      // Handle successful login, e.g., navigate to another screen
    } catch (e) {
      // Handle login error, e.g., show a snackbar or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return pb.authStore.isValid ? 
    Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You are already logged in as ${pb.authStore.record?.id ?? 'Unknown User'}'),
            ElevatedButton(
              onPressed: () {
                pb.authStore.clear();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
                logger.i('User logged out successfully.');
                setState(() {}); // Refresh the UI after logout
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    ) :
    Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator() : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await _login();
                    if (!context.mounted) return;
                    if (pb.authStore.isValid) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login failed. Please check your credentials.')),
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}