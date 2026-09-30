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
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),),
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
              ),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() : Column(
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
                      
                      await _signup();
                      
                      setState(() {
                        _isLoading = false;
                      });
                      
                      if (!context.mounted) return; // Check if the widget is still mounted
                      
                      if (pb.authStore.isValid) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeLayout()));
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
      );
    }
 }