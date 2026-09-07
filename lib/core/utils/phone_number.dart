/// Canonical mobile numbers for the OTP/SMS APIs.
///
/// Telesom (and UAT `request_otp`) expect digits with the Somali country code
/// and no plus: `636197117` → `252636197117`. The sign-in screens used to send
/// `+252636197117`, which the gateway can reject while the API still reports
/// "OTP sent".
class PhoneNumber {
  PhoneNumber._();

  static const somaliCountryDigits = '252';

  /// True when [raw] is an email login identifier, not a mobile number.
  static bool isEmail(String raw) => raw.trim().contains('@');

  /// Combine the country-code dropdown with the national field, without
  /// doubling `252` if the user pasted a full MSISDN.
  static String combine(String countryCode, String national) {
    final nationalDigits = _digits(national);
    final ccDigits = _digits(countryCode);

    if (ccDigits.isNotEmpty && nationalDigits.startsWith(ccDigits)) {
      return normalize(nationalDigits, defaultCountryCode: countryCode);
    }
    return normalize(
      '$countryCode$national',
      defaultCountryCode: countryCode,
    );
  }

  /// Digits-only MSISDN. Somali 9-digit numbers starting with 6 get `252`.
  static String normalize(String raw, {String defaultCountryCode = '+252'}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || isEmail(trimmed)) return trimmed;

    var digits = _digits(trimmed);
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    final ccDigits = _digits(defaultCountryCode);

    if (digits.startsWith(somaliCountryDigits)) {
      final nsn = digits.substring(3).replaceFirst(RegExp(r'^0+'), '');
      return nsn.isEmpty ? digits : '$somaliCountryDigits$nsn';
    }

    if (digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }

    // Local Somali mobile: 9 digits, first digit 6 (Telesom / Somtel / Hormuud).
    if (digits.length == 9 && digits.startsWith('6')) {
      return '$somaliCountryDigits$digits';
    }

    if (ccDigits == somaliCountryDigits &&
        digits.length >= 8 &&
        digits.length <= 10 &&
        digits.startsWith('6')) {
      return '$somaliCountryDigits$digits';
    }

    if (ccDigits.isNotEmpty &&
        digits.isNotEmpty &&
        !digits.startsWith(ccDigits)) {
      return '$ccDigits$digits';
    }
    return digits;
  }

  static String _digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');
}
