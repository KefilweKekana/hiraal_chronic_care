class AppConstants {
  // App info
  static const String appName = 'Hiraal Lifecare';
  static const String appTagline = 'Better Monitoring. Better Health.';
  static const String appSubtitle = 'Your daily readings. Our daily care.\nTogether, we stay ahead.';
  
  // Country
  static const String countryCode = '+252';
  // Somaliland has no Unicode flag emoji; the UI renders an SVG asset
  // (assets/flags/somaliland.svg) instead of a glyph for this entry.
  static const String countryName = 'Somaliland';
  static const String countryFlagAsset = 'assets/flags/somaliland.svg';
  // Clinic / support contact — REPLACE these placeholders with the real
  // clinic details. Shown on the booking screen and the support dialog.
  static const String clinicName = 'Hiraal Health Center';
  static const String clinicAddress = '123 Health Ave, City, Country';
  static const String supportEmail = 'support@hiraalhealth.so';
  static const String supportPhonePrimary = '0657002889';
  static const String supportPhoneSecondary = '0638902929';
  // Toll-free short code reachable from Telesom / Somtel lines.
  static const String supportShortCode = '2933';
  static const String supportHours = '8:00 AM - 8:00 PM (EAT)';

  // Alert thresholds
  static const double bpSystolicVeryHigh = 180;
  static const double bpDiastolicVeryHigh = 120;
  static const double bpSystolicHigh = 160;
  static const double bpDiastolicHigh = 100;
  static const double bpSystolicMedium = 140;
  static const double bpDiastolicMedium = 90;
  static const double bpSystolicLow = 130;
  static const double bpDiastolicLow = 85;
  static const double sugarVeryHigh = 300;
  static const double sugarHigh = 250;
  static const double sugarMedium = 200;
  static const double sugarLow = 180;
  static const double bpSafeMax = 140;
  static const double bpSafeDiastolicMax = 90;

  // Session
  static const int sessionTimeoutMinutes = 30;
  static const int otpLength = 6;
  static const int otpResendSeconds = 25;
  static const int otpExpiryMinutes = 5;

  // Subscription
  static const double standardPlanPrice = 5.00;
  static const double premiumPlanPrice = 10.00;
  static const String currencySymbol = '\$';
}
