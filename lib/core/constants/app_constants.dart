class AppConstants {
  // App info
  static const String appName = 'Hiraal Chronic Care';
  static const String appTagline = 'Better Monitoring. Better Health.';
  static const String appSubtitle = 'Your daily readings. Our daily care.\nTogether, we stay ahead.';
  
  // Country
  static const String countryCode = '+252';
  static const String countryFlag = '🇸🇴';
  static const String clinicName = 'Hiraal Health Center';
  static const String clinicAddress = '123 Health Ave, City, Country';
  
  // API endpoints (ERPNext / Frappe)
  static const String baseUrl = 'https://emr.hiraalhealth.so';
  static const String apiPrefix = '/api/method';
  static const String authVerifyOtp = '/chronic_care.auth.verify_otp';
  static const String authBiometric = '/chronic_care.auth.biometric_token';
  static const String readingsSubmit = '/chronic_care.readings.submit';
  static const String readingsSyncBatch = '/chronic_care.readings.sync_batch';
  static const String devicesPair = '/chronic_care.devices.pair';
  static const String appointmentsBook = '/chronic_care.appointments.book';
  static const String labRequest = '/chronic_care.lab.request';
  static const String medicineOrder = '/chronic_care.medicine.order';
  static const String subscriptionPay = '/chronic_care.subscription.pay';
  static const String notificationsList = '/chronic_care.notifications.list';

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
  static const double premiumPlanPrice = 5.00;
  static const String currencySymbol = '\$';
}
