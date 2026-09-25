import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Set the default state to follow the system settings
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Define your Light Theme configurations
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
  );

  // Define your Dark Theme configurations
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
  );

  // Function to explicitly set a specific theme mode
  void toggleTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners(); // Rebuilds the UI
  }
}