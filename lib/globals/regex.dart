class RegExPatterns {
  static final RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp hasUppercase = RegExp(r'[A-Z]');
  static final RegExp hasLowercase = RegExp(r'[a-z]');
  static final RegExp hasDigits = RegExp(r'[0-9]');
  static final RegExp hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
}