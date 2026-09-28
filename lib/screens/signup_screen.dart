import 'package:flutter/material.dart';
import 'package:gocart/main.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class SignupScreen extends StatefulWidget {
   const SignupScreen({super.key});

   @override
   State<SignupScreen> createState() => _SignupScreenState();
 }

 class _SignupScreenState extends State<SignupScreen> {
    bool _isLoading = false; // Track loading state
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _passwordConfirmController = TextEditingController();

    Future<void> _signup() async {
      try {
        await pb.collection('users').create(
          body: {
            'username': _usernameController.text,
            'email': _emailController.text,
            'name': _nameController.text, 
            'password': _passwordController.text,
            'passwordConfirm': _passwordConfirmController.text,
          },
        );
        // Handle successful signup, e.g., navigate to another screen
      } catch (e) {
        // Handle signup error, e.g., show a snackbar or dialog
        logger.e('Signup error: $e');
      }
    }

    @override
    Widget build(BuildContext context) {  
      return Scaffold(
        body: Center(          
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextFormField(
                controller: _passwordConfirmController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
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
                      await _signup();
                      if (!context.mounted) return; // Check if the widget is still mounted
                      if (pb.authStore.isValid) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signup failed. Please check your credentials.')),
                        );
                      }
                    },
                    child: const Text('Sign Up'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the previous screen
                    },
                    child: const Text('Cancel'),
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