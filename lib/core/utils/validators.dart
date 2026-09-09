class AppValidators {
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(value.replaceAll(RegExp(r'[\s\-\+]'), ''))) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? number(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'Value']) {
    final numError = number(value, fieldName);
    if (numError != null) return numError;
    if (double.parse(value!.trim()) <= 0) return '$fieldName must be greater than 0';
    return null;
  }
}
