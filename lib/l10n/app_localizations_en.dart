// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Hiraal';

  @override
  String get appNameFull => 'Hiraal Lifecare';

  @override
  String get appBrandSubtitle => 'Lifecare';

  @override
  String get appTagline => 'Better Monitoring. Better Health.';

  @override
  String get welcomeHeadline => 'Better Monitoring.\nBetter Health.';

  @override
  String get appSubtitle =>
      'Your daily readings. Our daily care.\nTogether, we stay ahead.';

  @override
  String get trustBadgeDataSafe => 'Your data is\nsafe & secure';

  @override
  String get trustBadgeTrustedClinics => 'Trusted by clinics\nthat care';

  @override
  String get getStarted => 'Get Started';

  @override
  String get needHelpContactSupport => 'Need help? Contact support';

  @override
  String get contactSupportTitle => 'Contact Support';

  @override
  String supportPhoneLine(String primary, String secondary) {
    return 'Phone: $primary / $secondary';
  }

  @override
  String supportShortCodeLine(String shortCode) {
    return 'Telesom or Somtel: call $shortCode';
  }

  @override
  String supportEmailLine(String email) {
    return 'Email: $email';
  }

  @override
  String supportHoursLine(String hours) {
    return 'Hours: $hours';
  }

  @override
  String get close => 'Close';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String unlockWithBio(String bioLabel) {
    return 'Unlock with $bioLabel to continue';
  }

  @override
  String logInWithBio(String bioLabel) {
    return 'Log in with $bioLabel';
  }

  @override
  String get signInAnotherWay => 'Sign in another way';

  @override
  String get biometricFingerprint => 'Fingerprint';

  @override
  String get letsGetStarted => 'Let\'s get started';

  @override
  String get enterMobileLinkedToRecord =>
      'Enter the mobile number linked to your\npatient record.';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmailHint => 'Enter your email address';

  @override
  String get enterPhoneHint => 'Enter phone number';

  @override
  String get otpWillEmailCode =>
      'We\'ll email your one-time code to this address.';

  @override
  String get lookupRecordInHospital =>
      'We will look up your record in the hospital system';

  @override
  String get sendMyCodeVia => 'Send my code via';

  @override
  String get channelSms => 'Text message';

  @override
  String get channelSmsSublabel => 'SMS to your phone';

  @override
  String get channelEmail => 'Email';

  @override
  String get channelEmailSublabel => 'To the email on file';

  @override
  String get sendCode => 'Send Code';

  @override
  String get infoSafeWithUs => 'Your information is safe with us';

  @override
  String get newToHiraal => 'New to Hiraal?';

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get verifyYourAccount => 'Verify your account';

  @override
  String get otpSentSms => 'We\'ve sent a 6-digit code to';

  @override
  String get otpSentEmail => 'We\'ve emailed your 6-digit code to';

  @override
  String get yourEmailFallback => 'your email';

  @override
  String get edit => 'Edit';

  @override
  String get enterSixDigitCode => 'Enter 6-digit code';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resend => 'Resend';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String otpExpiresInMinutes(int minutes) {
    return 'For your security, this code will expire in $minutes minutes';
  }

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get verificationFailed => 'Verification failed. Please try again.';

  @override
  String get failedToResendOtp => 'Failed to resend OTP';

  @override
  String get codeResentEmail => 'Code re-sent to your email';

  @override
  String get otpResentSuccess => 'OTP resent successfully';

  @override
  String get navHome => 'Home';

  @override
  String get navServices => 'Services';

  @override
  String get navHistory => 'History';

  @override
  String get navProfile => 'Profile';

  @override
  String get offlineBanner =>
      'You\'re offline — readings will be saved on this phone';

  @override
  String get backOnlineSyncing => 'Back online — syncing…';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get patientFallback => 'Patient';

  @override
  String get paymentPending => 'Payment pending';

  @override
  String orderPayToContinue(String id, String amount) {
    return 'Order #$id — pay $amount to continue';
  }

  @override
  String get nextAppointment => 'Next appointment';

  @override
  String get yourDoctor => 'Your doctor';

  @override
  String get todaysDate => 'Today\'s Date';

  @override
  String get lastSubmitted => 'Last Submitted';

  @override
  String get noReadingYetToday => 'No reading yet today';

  @override
  String get enterReadingsInfo =>
      'Please enter your readings and send to your care team.';

  @override
  String get todaysReading => 'Today\'s Reading';

  @override
  String get required => 'Required';

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String get unitMmHg => 'mmHg';

  @override
  String get systolicTop => 'Systolic (Top)';

  @override
  String get diastolicBottom => 'Diastolic (Bottom)';

  @override
  String get hintSystolic => 'e.g. 120';

  @override
  String get hintDiastolic => 'e.g. 80';

  @override
  String get bloodSugar => 'Blood Sugar';

  @override
  String get unitMgDl => 'mg/dL';

  @override
  String get hintBloodSugar => 'e.g. 140';

  @override
  String get weight => 'Weight';

  @override
  String get unitKg => 'kg';

  @override
  String get hintWeight => 'e.g. 72';

  @override
  String get medicineTaken => 'Medicine Taken';

  @override
  String get medicineTakenPrompt => 'Did you take your medicine as prescribed?';

  @override
  String get yesTaken => 'Yes, taken';

  @override
  String get noMissed => 'No, missed';

  @override
  String get addNoteOptional => 'Add Note (optional)';

  @override
  String get howFeelingHint => 'How are you feeling today?';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String get importReadingsFromDevice => 'Import readings from your device';

  @override
  String get connected => 'Connected';

  @override
  String get saveAndSend => 'Save & Send';

  @override
  String get sendReadingToCareTeam => 'Send reading to care team';

  @override
  String get submittingReading => 'Submitting Your Reading...';

  @override
  String get dontCloseWhileSending =>
      'Please don\'t close the app while we send your data.';

  @override
  String get dataSecureProtected => 'Your data is secure and protected.';

  @override
  String get failedToSubmitReading => 'Failed to submit reading';

  @override
  String get allSet => 'All Set!';

  @override
  String get readingSavedSent =>
      'Your reading from today has been\nsaved and sent to your care team.';

  @override
  String get careTeamNotified =>
      'Your data is secure and your care team\nhas been notified.';

  @override
  String get submissionSummary => 'Submission Summary';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get sentTo => 'Sent To';

  @override
  String get yourCareTeam => 'Your Care Team';

  @override
  String get referenceId => 'Reference ID';

  @override
  String get notAvailable => 'N/A';

  @override
  String get notifiedWhenReviewed =>
      'You will be notified when your care team\nreviews your reading.';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get viewHistory => 'View History';

  @override
  String get servicesTitle => 'Services';

  @override
  String get chooseCareToday => 'Choose how you\'d like to get care today.';

  @override
  String get searchServicesHint => 'Search services, doctors, or medicines...';

  @override
  String get bookDoctor => 'Book Doctor';

  @override
  String get bookDoctorSubtitle => 'Consult with a\ndoctor online';

  @override
  String get hiraalPharma => 'Hiraal Pharma';

  @override
  String get uploadPrescription => 'Upload a\nprescription';

  @override
  String get labTest => 'Lab Test';

  @override
  String get labTestSubtitle => 'Book tests near\nyou';

  @override
  String get quickSecureHealthcare =>
      'Quick, secure, and reliable healthcare at your fingertips.';

  @override
  String get recommendedForYou => 'Recommended for You';

  @override
  String get viewAll => 'View all';

  @override
  String get doctorFallback => 'Doctor';

  @override
  String get departmentGeneral => 'General';

  @override
  String get yourVideoVisits => 'Your Video Visits';

  @override
  String get joinLiveVideo => 'Join a live video consultation';

  @override
  String get orderFromHiraalPharma => 'Order from Hiraal Pharma';

  @override
  String get uploadRxForDelivery =>
      'Upload your prescription for\nreview and delivery';

  @override
  String get popularCategories => 'Popular Categories';

  @override
  String get categoryHeartCare => 'Heart Care';

  @override
  String get categoryChestCare => 'Chest Care';

  @override
  String get categoryDiabetesCare => 'Diabetes Care';

  @override
  String get categoryMentalHealth => 'Mental Health';

  @override
  String get selectDoctor => 'Select Doctor';

  @override
  String noSpecialistsShowingAll(String specialty) {
    return 'No $specialty specialists listed — showing all doctors';
  }

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get noDoctorsAvailable =>
      'No doctors are available right now. Please try again later.';

  @override
  String get appointmentDetails => 'Appointment Details';

  @override
  String get reasonForVisit => 'Reason for Visit';

  @override
  String get reasonVisitHint =>
      'Please describe your symptoms or reason for the visit...';

  @override
  String get selectDate => 'Select Date';

  @override
  String get timeSlot => 'Time Slot';

  @override
  String get availableSlotsHint =>
      'Showing available slots for today and next 7 days.';

  @override
  String get visitType => 'Visit Type';

  @override
  String get chooseConsultHow => 'Choose how you would like to consult.';

  @override
  String get videoCall => 'Video Call';

  @override
  String get consultFromHome => 'Consult from home';

  @override
  String get inPersonVisit => 'In-Person Visit';

  @override
  String get visitAtClinic => 'Visit at clinic';

  @override
  String get clinicLocationLabel => 'Clinic Location (for in-person visit)';

  @override
  String get selectClinic => 'Select a health center';

  @override
  String get pleaseSelectStation =>
      'Please choose a care station for your visit.';

  @override
  String get noStationsAvailable =>
      'No care stations are available right now. Please try again later or book a video visit.';

  @override
  String get appointmentSecureEasy =>
      'Your appointment is secure and easy to manage.';

  @override
  String get requestAppointment => 'Request Appointment';

  @override
  String get confirmationShortly => 'You\'ll receive a confirmation shortly.';

  @override
  String get pleaseSelectDoctor => 'Please select a doctor first.';

  @override
  String get pleaseDescribeReason =>
      'Please describe your reason for the visit.';

  @override
  String get appointmentConfirmedTitle => 'Appointment Confirmed';

  @override
  String get appointmentBooked => 'Appointment Booked!';

  @override
  String appointmentConfirmedFor(String date, String time) {
    return 'Your appointment is confirmed for $date at $time.';
  }

  @override
  String get videoVisitJoinReady =>
      'This is a video visit. Your join link is ready under Video Visits.';

  @override
  String get goToVideoVisit => 'Go to Video Visit';

  @override
  String get backToServices => 'Back to Services';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get bookDoctorEmptyHint =>
      'Book a doctor and your appointments\nwill appear here.';

  @override
  String get appointmentBookedStatus => 'Booked';

  @override
  String get historyTitle => 'History';

  @override
  String get filterReadingsTooltip => 'Filter readings';

  @override
  String get filter => 'Filter';

  @override
  String get filterAllTime => 'All time';

  @override
  String get filterLast7Days => 'Last 7 days';

  @override
  String get filterLast30Days => 'Last 30 days';

  @override
  String get filterLast90Days => 'Last 90 days';

  @override
  String get tabReadings => 'Readings';

  @override
  String get tabNotes => 'Notes';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get statSubmissionsTotal => 'Submissions\nTotal';

  @override
  String get statAvgSystolic => 'Avg. Systolic\nmonthly';

  @override
  String get statAvgSugar => 'Avg. Sugar\nmg/dL';

  @override
  String get historyInfoBanner =>
      'Your past readings and care team feedback appear here.';

  @override
  String get careTeamFeedbackFooter =>
      'Care team feedback will appear after they review your readings.';

  @override
  String get listView => 'List View';

  @override
  String get chartView => 'Chart View';

  @override
  String todayDateLabel(String date) {
    return 'Today, $date';
  }

  @override
  String yesterdayDateLabel(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get notEnoughChartData => 'Not enough data for chart';

  @override
  String get systolic => 'Systolic';

  @override
  String get diastolic => 'Diastolic';

  @override
  String get sugar => 'Sugar';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noAlerts => 'No alerts';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusSent => 'Sent';

  @override
  String get profileTitle => 'Profile';

  @override
  String memberId(String id) {
    return 'Member ID: $id';
  }

  @override
  String get yourProgram => 'Your Program';

  @override
  String get programHypertensionCare => 'Hypertension Care';

  @override
  String get memberSinceMay2024 => 'Member since May 2024';

  @override
  String get statusActive => 'Active';

  @override
  String get myInformation => 'My Information';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get updatePersonalDetails => 'Update your personal details';

  @override
  String get healthInformation => 'Health Information';

  @override
  String get viewHealthSummary => 'View your health summary';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get viewPastRecords => 'View your past records';

  @override
  String get addresses => 'Addresses';

  @override
  String get manageAddresses => 'Manage your addresses';

  @override
  String get myActivity => 'My Activity';

  @override
  String countUpcoming(String count) {
    return '$count Upcoming';
  }

  @override
  String get appointments => 'Appointments';

  @override
  String countScheduled(String count) {
    return '$count Scheduled';
  }

  @override
  String get labTests => 'Lab Tests';

  @override
  String countActive(String count) {
    return '$count Active';
  }

  @override
  String get orders => 'Orders';

  @override
  String get account => 'Account';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionSubtitle => 'View, subscribe, or renew your plan';

  @override
  String get payments => 'Payments';

  @override
  String get paymentsSubtitle => 'View your payment history and receipts';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get manageAccountSecurity => 'Manage your account security';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'App version and info';

  @override
  String get logOut => 'Log Out';

  @override
  String get couldNotLogOut => 'Could not log out. Please try again.';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'English or Soomaali';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Soomaali';

  @override
  String get reminders => 'Reminders';

  @override
  String get medicationReminder => 'Medication reminder';

  @override
  String dailyAtTime(String time) {
    return 'Daily at $time';
  }

  @override
  String get readingReminder => 'Reading reminder';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get largeText => 'Large text';

  @override
  String get largeTextSubtitle => 'Increase text size throughout the app';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'App Version';

  @override
  String get build => 'Build';

  @override
  String get buildDebug => 'Debug';

  @override
  String get buildRelease => 'Release';

  @override
  String get myOrders => 'My Orders';

  @override
  String get newOrder => 'New Order';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get tapNewOrderHint =>
      'Tap “New Order” to request a medicine delivery.';

  @override
  String get prescriptionOrder => 'Prescription order';

  @override
  String plusMore(int count) {
    return '+$count more';
  }

  @override
  String get otherMedicine => 'other medicine';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get tapToPay => 'Tap to pay';

  @override
  String get paymentPendingShort => 'Payment pending';

  @override
  String get outForDelivery => 'Out for delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get trackOrder => 'Track Order';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String placedAt(String datetime) {
    return 'Placed $datetime';
  }

  @override
  String get orderNotFound => 'Order not found.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String itemsCount(int count) {
    return 'Medicines ($count)';
  }

  @override
  String get awaitingPharmacistReview =>
      'Awaiting pharmacist review — items will appear here once your prescription is processed.';

  @override
  String get paymentSection => 'Payment';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get handlingFee => 'Handling fee';

  @override
  String get tax => 'Tax';

  @override
  String get total => 'Total';

  @override
  String get status => 'Status';

  @override
  String get confirmAndPay => 'Confirm & Pay';

  @override
  String confirmAndPayAmount(String amount) {
    return 'Confirm & Pay  $amount';
  }

  @override
  String get stagePrescriptionReceived => 'Prescription received';

  @override
  String get stageUnderReview => 'Under pharmacist review';

  @override
  String get stageAwaitingPayment => 'Awaiting your payment';

  @override
  String get stagePaymentConfirmed => 'Payment confirmed';

  @override
  String get stagePreparing => 'Preparing your medicines';

  @override
  String get stageOutForDelivery => 'Out for delivery';

  @override
  String get stageDelivered => 'Delivered';

  @override
  String get waitingForYourPayment => 'Waiting for your payment';

  @override
  String get paymentPendingBadge => 'Payment pending';

  @override
  String get payWith => 'Pay with';

  @override
  String get mobileMoneyNumber => 'Mobile-money number';

  @override
  String get mobileMoneyHint => 'e.g. 252612345678';

  @override
  String payAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get choosePaymentMethod => 'Choose a payment method.';

  @override
  String get enterMobileMoneyNumber => 'Enter your mobile-money number.';

  @override
  String get waitingForPayment => 'Waiting for payment';

  @override
  String approvePayWith(String amount, String method) {
    return 'Allow payment of $amount via $method';
  }

  @override
  String requestSentTo(String number) {
    return 'Request sent to $number';
  }

  @override
  String expiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String openMobileMoneyApp(String method) {
    return 'Open $method on your phone';
  }

  @override
  String get enterPinToConfirm => 'Enter your PIN to confirm the payment';

  @override
  String get pageConfirmsAutomatically =>
      'This page will automatically confirm the payment';

  @override
  String get iPaidCheckNow => 'I paid — check now';

  @override
  String get cancelAndTryAgain => 'Cancel and try again';

  @override
  String get paymentSuccessful => 'Payment successful';

  @override
  String get preparingMedicinesNow => 'We\'re preparing your medicines now.';

  @override
  String get exit => 'Exit';

  @override
  String get senderMobileNumber => 'Sending phone number';

  @override
  String get noPaymentsYet => 'No payments yet';

  @override
  String get paymentsEmptyHint =>
      'Your subscription and order payments will appear here.';

  @override
  String get careSubscription => 'Care subscription';

  @override
  String orderTitle(String id) {
    return 'Order $id';
  }

  @override
  String get paid => 'Paid';

  @override
  String get paymentReceipt => 'Payment receipt';

  @override
  String get item => 'Item';

  @override
  String get service => 'Service';

  @override
  String get reference => 'Reference';

  @override
  String get amount => 'Amount';

  @override
  String get shareReceipt => 'Share receipt';

  @override
  String get shareReceiptWithSomeone => 'Share the receipt';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get tabAll => 'All';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabReminders => 'Reminders';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'Messages, reminders and alerts from your\ncare team will appear here.';

  @override
  String get sectionToday => 'Today';

  @override
  String get sectionYesterday => 'Yesterday';

  @override
  String get sectionThisWeek => 'This week';

  @override
  String get sectionOlder => 'Older';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get uploadYourPrescription => 'Upload your prescription';

  @override
  String get uploadPrescriptionExplain =>
      'Snap a clear photo of your prescription. Our pharmacist will review it, confirm the price, and ask you to pay before we prepare and deliver it.';

  @override
  String get tapToAddPrescriptionPhoto => 'Tap to add prescription photo';

  @override
  String get cameraOrGallery => 'Camera or gallery';

  @override
  String get addYourPrescription => 'Add your prescription';

  @override
  String get takeAPhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get noteForPharmacistOptional => 'Note for the pharmacist (optional)';

  @override
  String get noteForPharmacistHint =>
      'e.g. brand preference, allergies, or anything we should know';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get selectDeliveryAddress => 'Select delivery address';

  @override
  String get addNewAddress => 'Add new address';

  @override
  String get addADeliveryAddress => 'Add a delivery address';

  @override
  String get change => 'Change';

  @override
  String get prescriptionPrivacyNote =>
      'Your prescription is private and shared only with our pharmacy.';

  @override
  String get submitPrescription => 'Submit Prescription';

  @override
  String get pleaseAttachPrescription =>
      'Please attach a photo of your prescription.';

  @override
  String get pleaseChooseDeliveryAddress => 'Please choose a delivery address.';

  @override
  String get couldNotOpenCamera => 'Could not open the camera.';

  @override
  String get couldNotOpenGallery => 'Could not open the gallery.';

  @override
  String get cancelOrderQuestion => 'Cancel order?';

  @override
  String get cancelOrderMessage =>
      'This will cancel your medicine order. You can place a new one anytime.';

  @override
  String get keepOrder => 'Keep order';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get cancelling => 'Cancelling…';

  @override
  String get confirming => 'Confirming…';

  @override
  String get iReceivedMyOrder => 'I received my order';

  @override
  String get confirmReceiptQuestion => 'Confirm receipt?';

  @override
  String get confirmReceiptMessage =>
      'Confirm that you have received this order.';

  @override
  String get notYet => 'Not yet';

  @override
  String get yesReceived => 'Yes, received';

  @override
  String get receiptConfirmedThanks => 'Thank you! Receipt confirmed.';

  @override
  String get prescriptionAttached => 'Prescription attached';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get orderWasCancelled => 'This order was cancelled';

  @override
  String get deliverySection => 'Delivery';

  @override
  String get typeLabel => 'Type';

  @override
  String get addressLabel => 'Address';

  @override
  String get estimatedLabel => 'Estimated';

  @override
  String get requestLabTest => 'Request Lab Test';

  @override
  String get labTestInfoTitle => 'Lab Test Info';

  @override
  String get labTestInfoBody =>
      'Choose a test, describe your reason, and submit. The care team will review and confirm a time.\n\nResults appear in your History once available.';

  @override
  String get gotIt => 'Got it';

  @override
  String get whyNeedLabTest => 'Why do you need a lab test?';

  @override
  String get labTestReasonHint =>
      'e.g. Doctor advised, feeling unwell, routine check';

  @override
  String get selectTest => 'Select test';

  @override
  String get searchLabTestsHint => 'Search lab tests...';

  @override
  String get preferredDate => 'Preferred date';

  @override
  String get whereWantTest => 'Where do you want the test?';

  @override
  String get visitClinic => 'Visit Clinic';

  @override
  String get visitClinicSubtitle => 'Go to a lab near you';

  @override
  String get homeSampleCollection => 'Home Sample Collection';

  @override
  String get homeSampleSubtitle => 'We\'ll come to you';

  @override
  String get fastingMayBeRequired =>
      'Fasting may be required for some tests. We\'ll let you know.';

  @override
  String get requestSecurePrivate => 'Your request is secure and private.';

  @override
  String get pleaseSelectAtLeastOneTest => 'Please select at least one test';

  @override
  String get labTestShortTitle => 'Lab Test';

  @override
  String get testScheduled => 'Test Scheduled!';

  @override
  String get testScheduledBody =>
      'We\'ve scheduled your request and scheduled your lab test.';

  @override
  String get testType => 'Test Type';

  @override
  String get timeLabel => 'Time';

  @override
  String get nextAvailable => 'Next available';

  @override
  String get viewAllBookings => 'View All Bookings';

  @override
  String get alert => 'Alert';

  @override
  String get highBpDetected => 'High Blood Pressure Detected';

  @override
  String get highBpSubtitle =>
      'Your reading is higher than your safe range.\nPlease follow the steps below.';

  @override
  String get yourLatestReading => 'Your Latest Reading';

  @override
  String get highBadge => 'High';

  @override
  String get safeRangeBp => 'Safe range: Below 140/90 mmHg';

  @override
  String get whatYouShouldDo => 'What You Should Do';

  @override
  String get contactYourCareTeam => 'Contact Your Care Team';

  @override
  String get contactCareTeamHint =>
      'We recommend speaking with your care team today.';

  @override
  String get restAndRecheck => 'Rest and Recheck';

  @override
  String get restAndRecheckHint =>
      'Sit quietly for 5 minutes and check your\nblood pressure again.';

  @override
  String get restThenRecheckSnack => 'Rest for 5 minutes, then recheck';

  @override
  String get seekUrgentCare => 'Seek Urgent Care if Needed';

  @override
  String get seekUrgentCareHint =>
      'If you have chest pain, shortness of breath,\nor severe headache, get help right away.';

  @override
  String get seekUrgentCareDialogBody =>
      'If you experience chest pain, shortness of breath, severe headache, or vision changes, please go to your nearest emergency room or call emergency services immediately.';

  @override
  String get getHelpNow => 'Get Help Now';

  @override
  String get getHelpNowHint =>
      'If you\'re experiencing any severe symptoms,\ncall emergency services.';

  @override
  String callEmergencyNumber(String number) {
    return 'Call $number';
  }

  @override
  String get contactMyCareTeam => 'Contact My Care Team';

  @override
  String get recheckMyBloodPressure => 'Recheck My Blood Pressure';

  @override
  String get ok => 'OK';

  @override
  String get emergencyCallTitle => 'Emergency Call';

  @override
  String unableToOpenDialer(String number) {
    return 'Unable to open dialer. Please call emergency services at $number immediately.';
  }

  @override
  String get careTeamCall => 'Care Team Call';

  @override
  String get youreCalling => 'You\'re calling...';

  @override
  String get careTeamNurse => 'Care Team Nurse';

  @override
  String get wereHereToHelp => 'We\'re here to help.';

  @override
  String get expectedWaitTime => 'Expected Wait Time';

  @override
  String get lessThan2Minutes => 'Less than 2 minutes';

  @override
  String get availableHours => 'Available Hours';

  @override
  String get availableHoursValue => '8:00 AM - 8:00 PM, Daily';

  @override
  String get careTeamCanSeeReadings =>
      'Your care team can see your recent readings\nand health information to assist you better.';

  @override
  String get recentConcern => 'Recent Concern';

  @override
  String get highBloodPressureTitle => 'High Blood Pressure';

  @override
  String get viewAction => 'View';

  @override
  String get endCall => 'End Call';

  @override
  String get callingStatus => 'Calling...';

  @override
  String get speaker => 'Speaker';

  @override
  String get speakerToggled => 'Speaker toggled';

  @override
  String get preferToMessage => 'Prefer to message?';

  @override
  String get sendMessageArrow => 'Send Message >';

  @override
  String get messageCareTeam => 'Message Care Team';

  @override
  String get describeYourConcern => 'Describe your concern…';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get messageSentSnack =>
      'Message sent. The care team will reply shortly.';

  @override
  String get connectMeasurementDevice => 'Connect Device';

  @override
  String get noDeviceConnected => 'No device connected';

  @override
  String connectedToDevice(String name) {
    return 'Connected to $name';
  }

  @override
  String get availableDevices => 'Available Devices';

  @override
  String get availableDevicesHint =>
      'Tap Scan — health monitors nearby and any already paired to this phone show up here. Hiraal takes over the Bluetooth link on Connect.';

  @override
  String get scanForDevices => 'Scan for Devices';

  @override
  String get scanning => 'Scanning…';

  @override
  String get lookingForDevices => 'Looking for devices...';

  @override
  String get scanDevicesHint =>
      'Tap Scan to find your monitor.\nTurn it ON first. If it was paired in phone Bluetooth settings, it will still appear here after Scan.';

  @override
  String get myDevices => 'My Devices';

  @override
  String get noPairedDevicesYet =>
      'No paired devices yet. Connect a device above to get started.';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connectAction => 'Connect';

  @override
  String get turnOnBluetooth => 'Turn on Bluetooth';

  @override
  String get removeDeviceQuestion => 'Remove Device?';

  @override
  String removeDeviceMessage(String name) {
    return 'Remove \"$name\" from paired devices?';
  }

  @override
  String get cancelAction => 'Cancel';

  @override
  String get removeAction => 'Remove';

  @override
  String get measureAction => 'Measure';

  @override
  String get unknownDevice => 'Unknown Device';

  @override
  String get caregiversTitle => 'Caregivers';

  @override
  String get addCaregiver => 'Add Caregiver';

  @override
  String get caregiversInfoBanner =>
      'Invite family members to view selected health information and support your care journey.';

  @override
  String get myCaregivers => 'My Caregivers';

  @override
  String get noCaregiversYet => 'No caregivers yet';

  @override
  String get caregiversEmptyHint =>
      'Add someone you trust to help monitor your care.';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get pendingRequestsHint =>
      'Invitations waiting for acceptance will appear here.';

  @override
  String get caregiverActive => 'Active';

  @override
  String get rejectCaregiver => 'Reject';

  @override
  String get acceptCaregiver => 'Accept';

  @override
  String get viewReadings => 'View readings';

  @override
  String get viewMedicines => 'View medicines';

  @override
  String get viewAppointments => 'View appointments';

  @override
  String get viewSubscription => 'View subscription';

  @override
  String get addCaregiverIntro =>
      'Invite a family member or friend via WhatsApp. They will receive a secure invitation link.';

  @override
  String get countryCode => 'Country code';

  @override
  String get countryCodeRequired => 'Enter a country code';

  @override
  String get whatsappNumber => 'WhatsApp number';

  @override
  String get whatsappRequired => 'Enter a valid WhatsApp number';

  @override
  String get relationship => 'Relationship';

  @override
  String get familyMemberName => 'Family member name (optional)';

  @override
  String get familyMemberHint => 'e.g. Hooyo Amina';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get whatsappInviteNote =>
      'We will open WhatsApp so you can send the invitation directly.';

  @override
  String get sendInvitationWhatsapp => 'Send Invitation via WhatsApp';

  @override
  String get couldNotOpenWhatsapp => 'Could not open WhatsApp';

  @override
  String get invitationReady => 'Invitation created. WhatsApp opened.';

  @override
  String get relationshipMother => 'Mother';

  @override
  String get relationshipFather => 'Father';

  @override
  String get relationshipBrother => 'Brother';

  @override
  String get relationshipSister => 'Sister';

  @override
  String get relationshipSpouse => 'Spouse';

  @override
  String get relationshipChild => 'Child';

  @override
  String get relationshipFriend => 'Friend';

  @override
  String get relationshipOther => 'Other';

  @override
  String get revokeCaregiverTitle => 'Revoke caregiver?';

  @override
  String revokeCaregiverMessage(String name) {
    return 'Remove $name from your caregivers? They will lose access immediately.';
  }

  @override
  String get revokeCaregiver => 'Revoke access';

  @override
  String get sendInvitationAgain => 'Send invitation again';

  @override
  String get savePermissions => 'Save permissions';

  @override
  String get caregiversMenu => 'Caregivers';

  @override
  String get caregiversMenuSubtitle => 'Manage who can support your care';

  @override
  String get sponsorCareMenu => 'Sponsor Care';

  @override
  String get sponsorCareMenuSubtitle => 'Find and sponsor a loved one\'s care';

  @override
  String get mySponsorshipMenu => 'My Sponsorship';

  @override
  String get mySponsorshipMenuSubtitle => 'View patients you sponsor';

  @override
  String get sponsorCareTitle => 'Sponsor Care';

  @override
  String get sponsorCareCard => 'Sponsor Care';

  @override
  String get sponsorCareCardSubtitle => 'Pay for a family member\'s care plan';

  @override
  String get findPatientTab => 'Find Patient';

  @override
  String get connectByWhatsappTab => 'Connect via WhatsApp';

  @override
  String get findPatientTitle => 'Find a patient to sponsor';

  @override
  String get findPatientHint =>
      'Search by phone number or member ID, or redeem an invitation code from the patient.';

  @override
  String get phoneOrMemberId => 'Phone or Member ID';

  @override
  String get phoneOrMemberIdHint => 'e.g. HCC-2024-000125 or 612345678';

  @override
  String get findPatientButton => 'Find Patient';

  @override
  String get redeemInvitationCodeTitle => 'Or redeem invitation code';

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get invitationCodeHint => 'Enter the code shared with you';

  @override
  String get redeemCodeButton => 'Redeem Code';

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String get noPatientsFoundHint =>
      'Try a phone number, member ID, or invitation code.';

  @override
  String get connectByWhatsappTitle => 'Find a loved one on WhatsApp';

  @override
  String get connectByWhatsappHint =>
      'Send a connection request to someone already using Hiraal. Once they accept, you can sponsor their care.';

  @override
  String get sendConnectionRequest => 'Send Connection Request';

  @override
  String get enterSearchTerm => 'Enter a phone number or member ID';

  @override
  String get enterInvitationCode => 'Enter an invitation code';

  @override
  String get sponsorPatientTitle => 'Sponsor Patient';

  @override
  String get chooseMonthlyPlan => 'Choose a monthly plan';

  @override
  String get noPlansAvailable =>
      'No subscription plans are available right now.';

  @override
  String get sponsorThisPatient => 'Sponsor This Patient';

  @override
  String get confirmSponsorshipTitle => 'Confirm Sponsorship';

  @override
  String get memberIdLabel => 'Member ID';

  @override
  String get planLabel => 'Plan';

  @override
  String get monthlyCostLabel => 'Monthly cost';

  @override
  String get payAndStartSponsorship => 'Pay & Start Sponsorship';

  @override
  String get sponsorPaymentTitle => 'Sponsorship Payment';

  @override
  String get startingPayment => 'Starting payment…';

  @override
  String get startingSponsorPaymentHint =>
      'Please wait while we send the mobile-money request.';

  @override
  String get sponsorshipPaymentFailed =>
      'The sponsorship payment was declined or cancelled.';

  @override
  String get paymentStillProcessing =>
      'Taking longer than usual. If you approved the request, payment will confirm automatically.';

  @override
  String get sponsorshipActiveTitle => 'Sponsorship active';

  @override
  String sponsorshipActiveHint(String name) {
    return 'You are now sponsoring $name\'s care plan. Thank you!';
  }

  @override
  String get paymentFailedTitle => 'Payment failed';

  @override
  String get tryAgain => 'Try again';

  @override
  String get doneLabel => 'Done';

  @override
  String get mySponsorshipTitle => 'My Sponsorship';

  @override
  String get noSponsorshipsYet => 'No sponsorships yet';

  @override
  String get noSponsorshipsHint =>
      'When you sponsor someone\'s care, it will appear here.';

  @override
  String get activeSponsorships => 'Active sponsorships';

  @override
  String get nextPaymentLabel => 'Next payment';

  @override
  String get latestUpdates => 'Latest updates';

  @override
  String get patientSnapshot => 'Patient snapshot';

  @override
  String get connectionRequestTitle => 'Connection Request';

  @override
  String get connectionSentHeadline => 'Request sent';

  @override
  String connectionSentBody(String number) {
    return 'We sent a connection request to $number. You will be notified when they accept.';
  }

  @override
  String get connectionActiveTitle => 'Connected';

  @override
  String get connectionActiveHeadline => 'You are connected';

  @override
  String connectionActiveBody(String name) {
    return 'Your connection with $name is active. You can now sponsor their care.';
  }
}
