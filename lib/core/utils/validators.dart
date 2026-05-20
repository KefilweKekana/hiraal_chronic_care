/// Input validators used across forms.
class Validators {
  Validators._();

  /// Phone number – digits only, 7-15 length (after stripping spaces/dashes).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Only digits are allowed';
    }
    return null;
  }

  /// OTP – exactly N digits.
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) return 'Enter the OTP code';
    if (value.length != length || !RegExp(r'^\d+$').hasMatch(value)) {
      return 'Enter a valid $length-digit code';
    }
    return null;
  }

  /// Required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Numeric value within range.
  static String? numericRange(
    String? value, {
    required String fieldName,
    required double min,
    required double max,
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    final n = double.tryParse(value);
    if (n == null) return 'Enter a valid number';
    if (n < min || n > max) return '$fieldName must be between ${min.toInt()} and ${max.toInt()}';
    return null;
  }

  /// Systolic BP (40-300).
  static String? systolic(String? value) =>
      numericRange(value, fieldName: 'Systolic', min: 40, max: 300);

  /// Diastolic BP (20-200).
  static String? diastolic(String? value) =>
      numericRange(value, fieldName: 'Diastolic', min: 20, max: 200);

  /// Blood sugar (20-600).
  static String? bloodSugar(String? value) =>
      numericRange(value, fieldName: 'Blood sugar', min: 20, max: 600);

  /// Weight (1-300).
  static String? weight(String? value) =>
      numericRange(value, fieldName: 'Weight', min: 1, max: 300);
}
