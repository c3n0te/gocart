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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  pb.authStore.clear();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
                  logger.i('User logged out successfully.');
                  setState(() {}); // Refresh the UI after logout
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Full width button
                  backgroundColor: Colors.black, // Change button color to black
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
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
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
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
            ),
            const SizedBox(height: 20),
            _isLoading ? const CircularProgressIndicator() : Column(
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
                  child: const Text('Login'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,MaterialPageRoute(builder: (context) => const SignupScreen()),);
                      },
                      child: const Text(
                        "Create one...",
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
    );
  }
}