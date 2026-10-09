import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Check if the user is already logged in when the app starts
    return pb.authStore.isValid;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      // Perform the PocketBase login
      await pb.collection('users').authWithPassword(email, password);
      
      // Update the state. Because pb.authStore.isValid is now true,
      // any widget listening to this provider will rebuild.
      state = AsyncValue.data(pb.authStore.isValid);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signup(String username, String email, String name, String password, String passwordConfirm) async {
    state = AsyncValue.loading();
    try {
      await pb.collection('users').create(
        body: {
          'username': username,
          'email': email,
          'name': name, 
          'password': password,
          'passwordConfirm': passwordConfirm,
        },
      );

      await pb.collection('users').authWithPassword(email, password);
      state = AsyncValue.data(pb.authStore.isValid);
    } catch (e, st) {
      // Handle signup error, e.g., show a snackbar or dialog
      state = AsyncValue.error(e, st);
    }
  }

  void logout() {
    pb.authStore.clear();
    state = const AsyncValue.data(false);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});