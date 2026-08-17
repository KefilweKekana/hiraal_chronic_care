import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_so.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('so'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hiraal'**
  String get appName;

  /// No description provided for @appNameFull.
  ///
  /// In en, this message translates to:
  /// **'Hiraal Lifecare'**
  String get appNameFull;

  /// No description provided for @appBrandSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lifecare'**
  String get appBrandSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Better Monitoring. Better Health.'**
  String get appTagline;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Better Monitoring.\nBetter Health.'**
  String get welcomeHeadline;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily readings. Our daily care.\nTogether, we stay ahead.'**
  String get appSubtitle;

  /// No description provided for @trustBadgeDataSafe.
  ///
  /// In en, this message translates to:
  /// **'Your data is\nsafe & secure'**
  String get trustBadgeDataSafe;

  /// No description provided for @trustBadgeTrustedClinics.
  ///
  /// In en, this message translates to:
  /// **'Trusted by clinics\nthat care'**
  String get trustBadgeTrustedClinics;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @needHelpContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Need help? Contact support'**
  String get needHelpContactSupport;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @supportPhoneLine.
  ///
  /// In en, this message translates to:
  /// **'Phone: {primary} / {secondary}'**
  String supportPhoneLine(String primary, String secondary);

  /// No description provided for @supportShortCodeLine.
  ///
  /// In en, this message translates to:
  /// **'Telesom or Somtel: call {shortCode}'**
  String supportShortCodeLine(String shortCode);

  /// No description provided for @supportEmailLine.
  ///
  /// In en, this message translates to:
  /// **'Email: {email}'**
  String supportEmailLine(String email);

  /// No description provided for @supportHoursLine.
  ///
  /// In en, this message translates to:
  /// **'Hours: {hours}'**
  String supportHoursLine(String hours);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @unlockWithBio.
  ///
  /// In en, this message translates to:
  /// **'Unlock with {bioLabel} to continue'**
  String unlockWithBio(String bioLabel);

  /// No description provided for @logInWithBio.
  ///
  /// In en, this message translates to:
  /// **'Log in with {bioLabel}'**
  String logInWithBio(String bioLabel);

  /// No description provided for @signInAnotherWay.
  ///
  /// In en, this message translates to:
  /// **'Sign in another way'**
  String get signInAnotherWay;

  /// No description provided for @biometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get biometricFingerprint;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get letsGetStarted;

  /// No description provided for @enterMobileLinkedToRecord.
  ///
  /// In en, this message translates to:
  /// **'Enter the mobile number linked to your\npatient record.'**
  String get enterMobileLinkedToRecord;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmailHint;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneHint;

  /// No description provided for @otpWillEmailCode.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email your one-time code to this address.'**
  String get otpWillEmailCode;

  /// No description provided for @lookupRecordInHospital.
  ///
  /// In en, this message translates to:
  /// **'We will look up your record in the hospital system'**
  String get lookupRecordInHospital;

  /// No description provided for @sendMyCodeVia.
  ///
  /// In en, this message translates to:
  /// **'Send my code via'**
  String get sendMyCodeVia;

  /// No description provided for @channelSms.
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get channelSms;

  /// No description provided for @channelSmsSublabel.
  ///
  /// In en, this message translates to:
  /// **'SMS to your phone'**
  String get channelSmsSublabel;

  /// No description provided for @channelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get channelEmail;

  /// No description provided for @channelEmailSublabel.
  ///
  /// In en, this message translates to:
  /// **'To the email on file'**
  String get channelEmailSublabel;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @infoSafeWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your information is safe with us'**
  String get infoSafeWithUs;

  /// No description provided for @newToHiraal.
  ///
  /// In en, this message translates to:
  /// **'New to Hiraal?'**
  String get newToHiraal;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @verifyYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your account'**
  String get verifyYourAccount;

  /// No description provided for @otpSentSms.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to'**
  String get otpSentSms;

  /// No description provided for @otpSentEmail.
  ///
  /// In en, this message translates to:
  /// **'We\'ve emailed your 6-digit code to'**
  String get otpSentEmail;

  /// No description provided for @yourEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get yourEmailFallback;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @otpExpiresInMinutes.
  ///
  /// In en, this message translates to:
  /// **'For your security, this code will expire in {minutes} minutes'**
  String otpExpiresInMinutes(int minutes);

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailed;

  /// No description provided for @failedToResendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get failedToResendOtp;

  /// No description provided for @codeResentEmail.
  ///
  /// In en, this message translates to:
  /// **'Code re-sent to your email'**
  String get codeResentEmail;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get otpResentSuccess;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get navServices;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — readings will be saved on this phone'**
  String get offlineBanner;

  /// No description provided for @backOnlineSyncing.
  ///
  /// In en, this message translates to:
  /// **'Back online — syncing…'**
  String get backOnlineSyncing;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get greetingEvening;

  /// No description provided for @patientFallback.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientFallback;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @orderPayToContinue.
  ///
  /// In en, this message translates to:
  /// **'Order #{id} — pay {amount} to continue'**
  String orderPayToContinue(String id, String amount);

  /// No description provided for @nextAppointment.
  ///
  /// In en, this message translates to:
  /// **'Next appointment'**
  String get nextAppointment;

  /// No description provided for @yourDoctor.
  ///
  /// In en, this message translates to:
  /// **'Your doctor'**
  String get yourDoctor;

  /// No description provided for @todaysDate.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Date'**
  String get todaysDate;

  /// No description provided for @lastSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Last Submitted'**
  String get lastSubmitted;

  /// No description provided for @noReadingYetToday.
  ///
  /// In en, this message translates to:
  /// **'No reading yet today'**
  String get noReadingYetToday;

  /// No description provided for @enterReadingsInfo.
  ///
  /// In en, this message translates to:
  /// **'Please enter your readings and send to your care team.'**
  String get enterReadingsInfo;

  /// No description provided for @todaysReading.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reading'**
  String get todaysReading;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @unitMmHg.
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get unitMmHg;

  /// No description provided for @systolicTop.
  ///
  /// In en, this message translates to:
  /// **'Systolic (Top)'**
  String get systolicTop;

  /// No description provided for @diastolicBottom.
  ///
  /// In en, this message translates to:
  /// **'Diastolic (Bottom)'**
  String get diastolicBottom;

  /// No description provided for @hintSystolic.
  ///
  /// In en, this message translates to:
  /// **'e.g. 120'**
  String get hintSystolic;

  /// No description provided for @hintDiastolic.
  ///
  /// In en, this message translates to:
  /// **'e.g. 80'**
  String get hintDiastolic;

  /// No description provided for @bloodSugar.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar'**
  String get bloodSugar;

  /// No description provided for @unitMgDl.
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get unitMgDl;

  /// No description provided for @hintBloodSugar.
  ///
  /// In en, this message translates to:
  /// **'e.g. 140'**
  String get hintBloodSugar;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @hintWeight.
  ///
  /// In en, this message translates to:
  /// **'e.g. 72'**
  String get hintWeight;

  /// No description provided for @medicineTaken.
  ///
  /// In en, this message translates to:
  /// **'Medicine Taken'**
  String get medicineTaken;

  /// No description provided for @medicineTakenPrompt.
  ///
  /// In en, this message translates to:
  /// **'Did you take your medicine as prescribed?'**
  String get medicineTakenPrompt;

  /// No description provided for @yesTaken.
  ///
  /// In en, this message translates to:
  /// **'Yes, taken'**
  String get yesTaken;

  /// No description provided for @noMissed.
  ///
  /// In en, this message translates to:
  /// **'No, missed'**
  String get noMissed;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Note (optional)'**
  String get addNoteOptional;

  /// No description provided for @howFeelingHint.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howFeelingHint;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @importReadingsFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Import readings from your device'**
  String get importReadingsFromDevice;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @saveAndSend.
  ///
  /// In en, this message translates to:
  /// **'Save & Send'**
  String get saveAndSend;

  /// No description provided for @sendReadingToCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Send reading to care team'**
  String get sendReadingToCareTeam;

  /// No description provided for @submittingReading.
  ///
  /// In en, this message translates to:
  /// **'Submitting Your Reading...'**
  String get submittingReading;

  /// No description provided for @dontCloseWhileSending.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t close the app while we send your data.'**
  String get dontCloseWhileSending;

  /// No description provided for @dataSecureProtected.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure and protected.'**
  String get dataSecureProtected;

  /// No description provided for @failedToSubmitReading.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit reading'**
  String get failedToSubmitReading;

  /// No description provided for @allSet.
  ///
  /// In en, this message translates to:
  /// **'All Set!'**
  String get allSet;

  /// No description provided for @readingSavedSent.
  ///
  /// In en, this message translates to:
  /// **'Your reading from today has been\nsaved and sent to your care team.'**
  String get readingSavedSent;

  /// No description provided for @careTeamNotified.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure and your care team\nhas been notified.'**
  String get careTeamNotified;

  /// No description provided for @submissionSummary.
  ///
  /// In en, this message translates to:
  /// **'Submission Summary'**
  String get submissionSummary;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent To'**
  String get sentTo;

  /// No description provided for @yourCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Your Care Team'**
  String get yourCareTeam;

  /// No description provided for @referenceId.
  ///
  /// In en, this message translates to:
  /// **'Reference ID'**
  String get referenceId;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @notifiedWhenReviewed.
  ///
  /// In en, this message translates to:
  /// **'You will be notified when your care team\nreviews your reading.'**
  String get notifiedWhenReviewed;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @chooseCareToday.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to get care today.'**
  String get chooseCareToday;

  /// No description provided for @searchServicesHint.
  ///
  /// In en, this message translates to:
  /// **'Search services, doctors, or medicines...'**
  String get searchServicesHint;

  /// No description provided for @bookDoctor.
  ///
  /// In en, this message translates to:
  /// **'Book Doctor'**
  String get bookDoctor;

  /// No description provided for @bookDoctorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consult with a\ndoctor online'**
  String get bookDoctorSubtitle;

  /// No description provided for @hiraalPharma.
  ///
  /// In en, this message translates to:
  /// **'Hiraal Pharma'**
  String get hiraalPharma;

  /// No description provided for @uploadPrescription.
  ///
  /// In en, this message translates to:
  /// **'Upload a\nprescription'**
  String get uploadPrescription;

  /// No description provided for @labTest.
  ///
  /// In en, this message translates to:
  /// **'Lab Test'**
  String get labTest;

  /// No description provided for @labTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book tests near\nyou'**
  String get labTestSubtitle;

  /// No description provided for @quickSecureHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Quick, secure, and reliable healthcare at your fingertips.'**
  String get quickSecureHealthcare;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @doctorFallback.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorFallback;

  /// No description provided for @departmentGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get departmentGeneral;

  /// No description provided for @yourVideoVisits.
  ///
  /// In en, this message translates to:
  /// **'Your Video Visits'**
  String get yourVideoVisits;

  /// No description provided for @joinLiveVideo.
  ///
  /// In en, this message translates to:
  /// **'Join a live video consultation'**
  String get joinLiveVideo;

  /// No description provided for @orderFromHiraalPharma.
  ///
  /// In en, this message translates to:
  /// **'Order from Hiraal Pharma'**
  String get orderFromHiraalPharma;

  /// No description provided for @uploadRxForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Upload your prescription for\nreview and delivery'**
  String get uploadRxForDelivery;

  /// No description provided for @popularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get popularCategories;

  /// No description provided for @categoryHeartCare.
  ///
  /// In en, this message translates to:
  /// **'Heart Care'**
  String get categoryHeartCare;

  /// No description provided for @categoryChestCare.
  ///
  /// In en, this message translates to:
  /// **'Chest Care'**
  String get categoryChestCare;

  /// No description provided for @categoryDiabetesCare.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Care'**
  String get categoryDiabetesCare;

  /// No description provided for @categoryMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get categoryMentalHealth;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select Doctor'**
  String get selectDoctor;

  /// No description provided for @noSpecialistsShowingAll.
  ///
  /// In en, this message translates to:
  /// **'No {specialty} specialists listed — showing all doctors'**
  String noSpecialistsShowingAll(String specialty);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctors are available right now. Please try again later.'**
  String get noDoctorsAvailable;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointmentDetails;

  /// No description provided for @reasonForVisit.
  ///
  /// In en, this message translates to:
  /// **'Reason for Visit'**
  String get reasonForVisit;

  /// No description provided for @reasonVisitHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe your symptoms or reason for the visit...'**
  String get reasonVisitHint;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @timeSlot.
  ///
  /// In en, this message translates to:
  /// **'Time Slot'**
  String get timeSlot;

  /// No description provided for @availableSlotsHint.
  ///
  /// In en, this message translates to:
  /// **'Showing available slots for today and next 7 days.'**
  String get availableSlotsHint;

  /// No description provided for @visitType.
  ///
  /// In en, this message translates to:
  /// **'Visit Type'**
  String get visitType;

  /// No description provided for @chooseConsultHow.
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to consult.'**
  String get chooseConsultHow;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @consultFromHome.
  ///
  /// In en, this message translates to:
  /// **'Consult from home'**
  String get consultFromHome;

  /// No description provided for @inPersonVisit.
  ///
  /// In en, this message translates to:
  /// **'In-Person Visit'**
  String get inPersonVisit;

  /// No description provided for @visitAtClinic.
  ///
  /// In en, this message translates to:
  /// **'Visit at clinic'**
  String get visitAtClinic;

  /// No description provided for @clinicLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinic Location (for in-person visit)'**
  String get clinicLocationLabel;

  /// No description provided for @selectClinic.
  ///
  /// In en, this message translates to:
  /// **'Select a health center'**
  String get selectClinic;

  /// No description provided for @pleaseSelectStation.
  ///
  /// In en, this message translates to:
  /// **'Please choose a care station for your visit.'**
  String get pleaseSelectStation;

  /// No description provided for @noStationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No care stations are available right now. Please try again later or book a video visit.'**
  String get noStationsAvailable;

  /// No description provided for @appointmentSecureEasy.
  ///
  /// In en, this message translates to:
  /// **'Your appointment is secure and easy to manage.'**
  String get appointmentSecureEasy;

  /// No description provided for @requestAppointment.
  ///
  /// In en, this message translates to:
  /// **'Request Appointment'**
  String get requestAppointment;

  /// No description provided for @confirmationShortly.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a confirmation shortly.'**
  String get confirmationShortly;

  /// No description provided for @pleaseSelectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Please select a doctor first.'**
  String get pleaseSelectDoctor;

  /// No description provided for @pleaseDescribeReason.
  ///
  /// In en, this message translates to:
  /// **'Please describe your reason for the visit.'**
  String get pleaseDescribeReason;

  /// No description provided for @appointmentConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get appointmentConfirmedTitle;

  /// No description provided for @appointmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Appointment Booked!'**
  String get appointmentBooked;

  /// No description provided for @appointmentConfirmedFor.
  ///
  /// In en, this message translates to:
  /// **'Your appointment is confirmed for {date} at {time}.'**
  String appointmentConfirmedFor(String date, String time);

  /// No description provided for @videoVisitJoinReady.
  ///
  /// In en, this message translates to:
  /// **'This is a video visit. Your join link is ready under Video Visits.'**
  String get videoVisitJoinReady;

  /// No description provided for @goToVideoVisit.
  ///
  /// In en, this message translates to:
  /// **'Go to Video Visit'**
  String get goToVideoVisit;

  /// No description provided for @backToServices.
  ///
  /// In en, this message translates to:
  /// **'Back to Services'**
  String get backToServices;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @bookDoctorEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Book a doctor and your appointments\nwill appear here.'**
  String get bookDoctorEmptyHint;

  /// No description provided for @appointmentBookedStatus.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get appointmentBookedStatus;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @filterReadingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter readings'**
  String get filterReadingsTooltip;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get filterAllTime;

  /// No description provided for @filterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get filterLast7Days;

  /// No description provided for @filterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get filterLast30Days;

  /// No description provided for @filterLast90Days.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get filterLast90Days;

  /// No description provided for @tabReadings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get tabReadings;

  /// No description provided for @tabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tabNotes;

  /// No description provided for @tabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// No description provided for @statSubmissionsTotal.
  ///
  /// In en, this message translates to:
  /// **'Submissions\nTotal'**
  String get statSubmissionsTotal;

  /// No description provided for @statAvgSystolic.
  ///
  /// In en, this message translates to:
  /// **'Avg. Systolic\nmonthly'**
  String get statAvgSystolic;

  /// No description provided for @statAvgSugar.
  ///
  /// In en, this message translates to:
  /// **'Avg. Sugar\nmg/dL'**
  String get statAvgSugar;

  /// No description provided for @historyInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Your past readings and care team feedback appear here.'**
  String get historyInfoBanner;

  /// No description provided for @careTeamFeedbackFooter.
  ///
  /// In en, this message translates to:
  /// **'Care team feedback will appear after they review your readings.'**
  String get careTeamFeedbackFooter;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @chartView.
  ///
  /// In en, this message translates to:
  /// **'Chart View'**
  String get chartView;

  /// No description provided for @todayDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String todayDateLabel(String date);

  /// No description provided for @yesterdayDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {date}'**
  String yesterdayDateLabel(String date);

  /// No description provided for @notEnoughChartData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for chart'**
  String get notEnoughChartData;

  /// No description provided for @systolic.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolic;

  /// No description provided for @diastolic.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolic;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get noAlerts;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @memberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID: {id}'**
  String memberId(String id);

  /// No description provided for @yourProgram.
  ///
  /// In en, this message translates to:
  /// **'Your Program'**
  String get yourProgram;

  /// No description provided for @programHypertensionCare.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Care'**
  String get programHypertensionCare;

  /// No description provided for @memberSinceMay2024.
  ///
  /// In en, this message translates to:
  /// **'Member since May 2024'**
  String get memberSinceMay2024;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @myInformation.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get myInformation;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @updatePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get updatePersonalDetails;

  /// No description provided for @healthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get healthInformation;

  /// No description provided for @viewHealthSummary.
  ///
  /// In en, this message translates to:
  /// **'View your health summary'**
  String get viewHealthSummary;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @viewPastRecords.
  ///
  /// In en, this message translates to:
  /// **'View your past records'**
  String get viewPastRecords;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @manageAddresses.
  ///
  /// In en, this message translates to:
  /// **'Manage your addresses'**
  String get manageAddresses;

  /// No description provided for @myActivity.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivity;

  /// No description provided for @countUpcoming.
  ///
  /// In en, this message translates to:
  /// **'{count} Upcoming'**
  String countUpcoming(String count);

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @countScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} Scheduled'**
  String countScheduled(String count);

  /// No description provided for @labTests.
  ///
  /// In en, this message translates to:
  /// **'Lab Tests'**
  String get labTests;

  /// No description provided for @countActive.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String countActive(String count);

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, subscribe, or renew your plan'**
  String get subscriptionSubtitle;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @paymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your payment history and receipts'**
  String get paymentsSubtitle;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// No description provided for @manageAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Manage your account security'**
  String get manageAccountSecurity;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App version and info'**
  String get settingsSubtitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @couldNotLogOut.
  ///
  /// In en, this message translates to:
  /// **'Could not log out. Please try again.'**
  String get couldNotLogOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English or Soomaali'**
  String get languageSubtitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSomali.
  ///
  /// In en, this message translates to:
  /// **'Soomaali'**
  String get languageSomali;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @medicationReminder.
  ///
  /// In en, this message translates to:
  /// **'Medication reminder'**
  String get medicationReminder;

  /// No description provided for @dailyAtTime.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String dailyAtTime(String time);

  /// No description provided for @readingReminder.
  ///
  /// In en, this message translates to:
  /// **'Reading reminder'**
  String get readingReminder;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @largeText.
  ///
  /// In en, this message translates to:
  /// **'Large text'**
  String get largeText;

  /// No description provided for @largeTextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Increase text size throughout the app'**
  String get largeTextSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @buildDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get buildDebug;

  /// No description provided for @buildRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get buildRelease;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @tapNewOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “New Order” to request a medicine delivery.'**
  String get tapNewOrderHint;

  /// No description provided for @prescriptionOrder.
  ///
  /// In en, this message translates to:
  /// **'Prescription order'**
  String get prescriptionOrder;

  /// No description provided for @plusMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String plusMore(int count);

  /// No description provided for @otherMedicine.
  ///
  /// In en, this message translates to:
  /// **'other medicine'**
  String get otherMedicine;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @tapToPay.
  ///
  /// In en, this message translates to:
  /// **'Tap to pay'**
  String get tapToPay;

  /// No description provided for @paymentPendingShort.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPendingShort;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get outForDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// No description provided for @placedAt.
  ///
  /// In en, this message translates to:
  /// **'Placed {datetime}'**
  String placedAt(String datetime);

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get orderNotFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Medicines ({count})'**
  String itemsCount(int count);

  /// No description provided for @awaitingPharmacistReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting pharmacist review — items will appear here once your prescription is processed.'**
  String get awaitingPharmacistReview;

  /// No description provided for @paymentSection.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentSection;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @handlingFee.
  ///
  /// In en, this message translates to:
  /// **'Handling fee'**
  String get handlingFee;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay'**
  String get confirmAndPay;

  /// No description provided for @confirmAndPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay  {amount}'**
  String confirmAndPayAmount(String amount);

  /// No description provided for @stagePrescriptionReceived.
  ///
  /// In en, this message translates to:
  /// **'Prescription received'**
  String get stagePrescriptionReceived;

  /// No description provided for @stageUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under pharmacist review'**
  String get stageUnderReview;

  /// No description provided for @stageAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your payment'**
  String get stageAwaitingPayment;

  /// No description provided for @stagePaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get stagePaymentConfirmed;

  /// No description provided for @stagePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your medicines'**
  String get stagePreparing;

  /// No description provided for @stageOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get stageOutForDelivery;

  /// No description provided for @stageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stageDelivered;

  /// No description provided for @waitingForYourPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment'**
  String get waitingForYourPayment;

  /// No description provided for @paymentPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPendingBadge;

  /// No description provided for @payWith.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWith;

  /// No description provided for @mobileMoneyNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile-money number'**
  String get mobileMoneyNumber;

  /// No description provided for @mobileMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 252612345678'**
  String get mobileMoneyHint;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(String amount);

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method.'**
  String get choosePaymentMethod;

  /// No description provided for @enterMobileMoneyNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile-money number.'**
  String get enterMobileMoneyNumber;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get waitingForPayment;

  /// No description provided for @approvePayWith.
  ///
  /// In en, this message translates to:
  /// **'Allow payment of {amount} via {method}'**
  String approvePayWith(String amount, String method);

  /// No description provided for @requestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {number}'**
  String requestSentTo(String number);

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String expiresIn(String time);

  /// No description provided for @openMobileMoneyApp.
  ///
  /// In en, this message translates to:
  /// **'Open {method} on your phone'**
  String openMobileMoneyApp(String method);

  /// No description provided for @enterPinToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to confirm the payment'**
  String get enterPinToConfirm;

  /// No description provided for @pageConfirmsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'This page will automatically confirm the payment'**
  String get pageConfirmsAutomatically;

  /// No description provided for @iPaidCheckNow.
  ///
  /// In en, this message translates to:
  /// **'I paid — check now'**
  String get iPaidCheckNow;

  /// No description provided for @cancelAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Cancel and try again'**
  String get cancelAndTryAgain;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessful;

  /// No description provided for @preparingMedicinesNow.
  ///
  /// In en, this message translates to:
  /// **'We\'re preparing your medicines now.'**
  String get preparingMedicinesNow;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @senderMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Sending phone number'**
  String get senderMobileNumber;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get noPaymentsYet;

  /// No description provided for @paymentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your subscription and order payments will appear here.'**
  String get paymentsEmptyHint;

  /// No description provided for @careSubscription.
  ///
  /// In en, this message translates to:
  /// **'Care subscription'**
  String get careSubscription;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order {id}'**
  String orderTitle(String id);

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get paymentReceipt;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get shareReceipt;

  /// No description provided for @shareReceiptWithSomeone.
  ///
  /// In en, this message translates to:
  /// **'Share the receipt'**
  String get shareReceiptWithSomeone;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @tabReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get tabReminders;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Messages, reminders and alerts from your\ncare team will appear here.'**
  String get notificationsEmptyHint;

  /// No description provided for @sectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionToday;

  /// No description provided for @sectionYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get sectionYesterday;

  /// No description provided for @sectionThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get sectionThisWeek;

  /// No description provided for @sectionOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get sectionOlder;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @uploadYourPrescription.
  ///
  /// In en, this message translates to:
  /// **'Upload your prescription'**
  String get uploadYourPrescription;

  /// No description provided for @uploadPrescriptionExplain.
  ///
  /// In en, this message translates to:
  /// **'Snap a clear photo of your prescription. Our pharmacist will review it, confirm the price, and ask you to pay before we prepare and deliver it.'**
  String get uploadPrescriptionExplain;

  /// No description provided for @tapToAddPrescriptionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add prescription photo'**
  String get tapToAddPrescriptionPhoto;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery'**
  String get cameraOrGallery;

  /// No description provided for @addYourPrescription.
  ///
  /// In en, this message translates to:
  /// **'Add your prescription'**
  String get addYourPrescription;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @noteForPharmacistOptional.
  ///
  /// In en, this message translates to:
  /// **'Note for the pharmacist (optional)'**
  String get noteForPharmacistOptional;

  /// No description provided for @noteForPharmacistHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. brand preference, allergies, or anything we should know'**
  String get noteForPharmacistHint;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @selectDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Select delivery address'**
  String get selectDeliveryAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get addNewAddress;

  /// No description provided for @addADeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address'**
  String get addADeliveryAddress;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @prescriptionPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your prescription is private and shared only with our pharmacy.'**
  String get prescriptionPrivacyNote;

  /// No description provided for @submitPrescription.
  ///
  /// In en, this message translates to:
  /// **'Submit Prescription'**
  String get submitPrescription;

  /// No description provided for @pleaseAttachPrescription.
  ///
  /// In en, this message translates to:
  /// **'Please attach a photo of your prescription.'**
  String get pleaseAttachPrescription;

  /// No description provided for @pleaseChooseDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Please choose a delivery address.'**
  String get pleaseChooseDeliveryAddress;

  /// No description provided for @couldNotOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Could not open the camera.'**
  String get couldNotOpenCamera;

  /// No description provided for @couldNotOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Could not open the gallery.'**
  String get couldNotOpenGallery;

  /// No description provided for @cancelOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel order?'**
  String get cancelOrderQuestion;

  /// No description provided for @cancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'This will cancel your medicine order. You can place a new one anytime.'**
  String get cancelOrderMessage;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancelling;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get confirming;

  /// No description provided for @iReceivedMyOrder.
  ///
  /// In en, this message translates to:
  /// **'I received my order'**
  String get iReceivedMyOrder;

  /// No description provided for @confirmReceiptQuestion.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt?'**
  String get confirmReceiptQuestion;

  /// No description provided for @confirmReceiptMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you have received this order.'**
  String get confirmReceiptMessage;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @yesReceived.
  ///
  /// In en, this message translates to:
  /// **'Yes, received'**
  String get yesReceived;

  /// No description provided for @receiptConfirmedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Receipt confirmed.'**
  String get receiptConfirmedThanks;

  /// No description provided for @prescriptionAttached.
  ///
  /// In en, this message translates to:
  /// **'Prescription attached'**
  String get prescriptionAttached;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @orderWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled'**
  String get orderWasCancelled;

  /// No description provided for @deliverySection.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliverySection;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @estimatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimatedLabel;

  /// No description provided for @requestLabTest.
  ///
  /// In en, this message translates to:
  /// **'Request Lab Test'**
  String get requestLabTest;

  /// No description provided for @labTestInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab Test Info'**
  String get labTestInfoTitle;

  /// No description provided for @labTestInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a test, describe your reason, and submit. The care team will review and confirm a time.\n\nResults appear in your History once available.'**
  String get labTestInfoBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @whyNeedLabTest.
  ///
  /// In en, this message translates to:
  /// **'Why do you need a lab test?'**
  String get whyNeedLabTest;

  /// No description provided for @labTestReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Doctor advised, feeling unwell, routine check'**
  String get labTestReasonHint;

  /// No description provided for @selectTest.
  ///
  /// In en, this message translates to:
  /// **'Select test'**
  String get selectTest;

  /// No description provided for @searchLabTestsHint.
  ///
  /// In en, this message translates to:
  /// **'Search lab tests...'**
  String get searchLabTestsHint;

  /// No description provided for @preferredDate.
  ///
  /// In en, this message translates to:
  /// **'Preferred date'**
  String get preferredDate;

  /// No description provided for @whereWantTest.
  ///
  /// In en, this message translates to:
  /// **'Where do you want the test?'**
  String get whereWantTest;

  /// No description provided for @visitClinic.
  ///
  /// In en, this message translates to:
  /// **'Visit Clinic'**
  String get visitClinic;

  /// No description provided for @visitClinicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go to a lab near you'**
  String get visitClinicSubtitle;

  /// No description provided for @homeSampleCollection.
  ///
  /// In en, this message translates to:
  /// **'Home Sample Collection'**
  String get homeSampleCollection;

  /// No description provided for @homeSampleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll come to you'**
  String get homeSampleSubtitle;

  /// No description provided for @fastingMayBeRequired.
  ///
  /// In en, this message translates to:
  /// **'Fasting may be required for some tests. We\'ll let you know.'**
  String get fastingMayBeRequired;

  /// No description provided for @requestSecurePrivate.
  ///
  /// In en, this message translates to:
  /// **'Your request is secure and private.'**
  String get requestSecurePrivate;

  /// No description provided for @pleaseSelectAtLeastOneTest.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one test'**
  String get pleaseSelectAtLeastOneTest;

  /// No description provided for @labTestShortTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab Test'**
  String get labTestShortTitle;

  /// No description provided for @testScheduled.
  ///
  /// In en, this message translates to:
  /// **'Test Scheduled!'**
  String get testScheduled;

  /// No description provided for @testScheduledBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve scheduled your request and scheduled your lab test.'**
  String get testScheduledBody;

  /// No description provided for @testType.
  ///
  /// In en, this message translates to:
  /// **'Test Type'**
  String get testType;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @nextAvailable.
  ///
  /// In en, this message translates to:
  /// **'Next available'**
  String get nextAvailable;

  /// No description provided for @viewAllBookings.
  ///
  /// In en, this message translates to:
  /// **'View All Bookings'**
  String get viewAllBookings;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @highBpDetected.
  ///
  /// In en, this message translates to:
  /// **'High Blood Pressure Detected'**
  String get highBpDetected;

  /// No description provided for @highBpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your reading is higher than your safe range.\nPlease follow the steps below.'**
  String get highBpSubtitle;

  /// No description provided for @yourLatestReading.
  ///
  /// In en, this message translates to:
  /// **'Your Latest Reading'**
  String get yourLatestReading;

  /// No description provided for @highBadge.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highBadge;

  /// No description provided for @safeRangeBp.
  ///
  /// In en, this message translates to:
  /// **'Safe range: Below 140/90 mmHg'**
  String get safeRangeBp;

  /// No description provided for @whatYouShouldDo.
  ///
  /// In en, this message translates to:
  /// **'What You Should Do'**
  String get whatYouShouldDo;

  /// No description provided for @contactYourCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact Your Care Team'**
  String get contactYourCareTeam;

  /// No description provided for @contactCareTeamHint.
  ///
  /// In en, this message translates to:
  /// **'We recommend speaking with your care team today.'**
  String get contactCareTeamHint;

  /// No description provided for @restAndRecheck.
  ///
  /// In en, this message translates to:
  /// **'Rest and Recheck'**
  String get restAndRecheck;

  /// No description provided for @restAndRecheckHint.
  ///
  /// In en, this message translates to:
  /// **'Sit quietly for 5 minutes and check your\nblood pressure again.'**
  String get restAndRecheckHint;

  /// No description provided for @restThenRecheckSnack.
  ///
  /// In en, this message translates to:
  /// **'Rest for 5 minutes, then recheck'**
  String get restThenRecheckSnack;

  /// No description provided for @seekUrgentCare.
  ///
  /// In en, this message translates to:
  /// **'Seek Urgent Care if Needed'**
  String get seekUrgentCare;

  /// No description provided for @seekUrgentCareHint.
  ///
  /// In en, this message translates to:
  /// **'If you have chest pain, shortness of breath,\nor severe headache, get help right away.'**
  String get seekUrgentCareHint;

  /// No description provided for @seekUrgentCareDialogBody.
  ///
  /// In en, this message translates to:
  /// **'If you experience chest pain, shortness of breath, severe headache, or vision changes, please go to your nearest emergency room or call emergency services immediately.'**
  String get seekUrgentCareDialogBody;

  /// No description provided for @getHelpNow.
  ///
  /// In en, this message translates to:
  /// **'Get Help Now'**
  String get getHelpNow;

  /// No description provided for @getHelpNowHint.
  ///
  /// In en, this message translates to:
  /// **'If you\'re experiencing any severe symptoms,\ncall emergency services.'**
  String get getHelpNowHint;

  /// No description provided for @callEmergencyNumber.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callEmergencyNumber(String number);

  /// No description provided for @contactMyCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact My Care Team'**
  String get contactMyCareTeam;

  /// No description provided for @recheckMyBloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Recheck My Blood Pressure'**
  String get recheckMyBloodPressure;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @emergencyCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Call'**
  String get emergencyCallTitle;

  /// No description provided for @unableToOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Unable to open dialer. Please call emergency services at {number} immediately.'**
  String unableToOpenDialer(String number);

  /// No description provided for @careTeamCall.
  ///
  /// In en, this message translates to:
  /// **'Care Team Call'**
  String get careTeamCall;

  /// No description provided for @youreCalling.
  ///
  /// In en, this message translates to:
  /// **'You\'re calling...'**
  String get youreCalling;

  /// No description provided for @careTeamNurse.
  ///
  /// In en, this message translates to:
  /// **'Care Team Nurse'**
  String get careTeamNurse;

  /// No description provided for @wereHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help.'**
  String get wereHereToHelp;

  /// No description provided for @expectedWaitTime.
  ///
  /// In en, this message translates to:
  /// **'Expected Wait Time'**
  String get expectedWaitTime;

  /// No description provided for @lessThan2Minutes.
  ///
  /// In en, this message translates to:
  /// **'Less than 2 minutes'**
  String get lessThan2Minutes;

  /// No description provided for @availableHours.
  ///
  /// In en, this message translates to:
  /// **'Available Hours'**
  String get availableHours;

  /// No description provided for @availableHoursValue.
  ///
  /// In en, this message translates to:
  /// **'8:00 AM - 8:00 PM, Daily'**
  String get availableHoursValue;

  /// No description provided for @careTeamCanSeeReadings.
  ///
  /// In en, this message translates to:
  /// **'Your care team can see your recent readings\nand health information to assist you better.'**
  String get careTeamCanSeeReadings;

  /// No description provided for @recentConcern.
  ///
  /// In en, this message translates to:
  /// **'Recent Concern'**
  String get recentConcern;

  /// No description provided for @highBloodPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'High Blood Pressure'**
  String get highBloodPressureTitle;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCall;

  /// No description provided for @callingStatus.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get callingStatus;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @speakerToggled.
  ///
  /// In en, this message translates to:
  /// **'Speaker toggled'**
  String get speakerToggled;

  /// No description provided for @preferToMessage.
  ///
  /// In en, this message translates to:
  /// **'Prefer to message?'**
  String get preferToMessage;

  /// No description provided for @sendMessageArrow.
  ///
  /// In en, this message translates to:
  /// **'Send Message >'**
  String get sendMessageArrow;

  /// No description provided for @messageCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Message Care Team'**
  String get messageCareTeam;

  /// No description provided for @describeYourConcern.
  ///
  /// In en, this message translates to:
  /// **'Describe your concern…'**
  String get describeYourConcern;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @messageSentSnack.
  ///
  /// In en, this message translates to:
  /// **'Message sent. The care team will reply shortly.'**
  String get messageSentSnack;

  /// No description provided for @connectMeasurementDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectMeasurementDevice;

  /// No description provided for @noDeviceConnected.
  ///
  /// In en, this message translates to:
  /// **'No device connected'**
  String get noDeviceConnected;

  /// No description provided for @connectedToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}'**
  String connectedToDevice(String name);

  /// No description provided for @availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get availableDevices;

  /// No description provided for @availableDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan — health monitors nearby and any already paired to this phone show up here. Hiraal takes over the Bluetooth link on Connect.'**
  String get availableDevicesHint;

  /// No description provided for @scanForDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan for Devices'**
  String get scanForDevices;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @lookingForDevices.
  ///
  /// In en, this message translates to:
  /// **'Looking for devices...'**
  String get lookingForDevices;

  /// No description provided for @scanDevicesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan to find your monitor.\nTurn it ON first. If it was paired in phone Bluetooth settings, it will still appear here after Scan.'**
  String get scanDevicesHint;

  /// No description provided for @myDevices.
  ///
  /// In en, this message translates to:
  /// **'My Devices'**
  String get myDevices;

  /// No description provided for @noPairedDevicesYet.
  ///
  /// In en, this message translates to:
  /// **'No paired devices yet. Connect a device above to get started.'**
  String get noPairedDevicesYet;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAction;

  /// No description provided for @turnOnBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get turnOnBluetooth;

  /// No description provided for @removeDeviceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove Device?'**
  String get removeDeviceQuestion;

  /// No description provided for @removeDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from paired devices?'**
  String removeDeviceMessage(String name);

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @measureAction.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get measureAction;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get unknownDevice;

  /// No description provided for @caregiversTitle.
  ///
  /// In en, this message translates to:
  /// **'Caregivers'**
  String get caregiversTitle;

  /// No description provided for @addCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Add Caregiver'**
  String get addCaregiver;

  /// No description provided for @caregiversInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Invite family members to view selected health information and support your care journey.'**
  String get caregiversInfoBanner;

  /// No description provided for @myCaregivers.
  ///
  /// In en, this message translates to:
  /// **'My Caregivers'**
  String get myCaregivers;

  /// No description provided for @noCaregiversYet.
  ///
  /// In en, this message translates to:
  /// **'No caregivers yet'**
  String get noCaregiversYet;

  /// No description provided for @caregiversEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add someone you trust to help monitor your care.'**
  String get caregiversEmptyHint;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @pendingRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Invitations waiting for acceptance will appear here.'**
  String get pendingRequestsHint;

  /// No description provided for @caregiverActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get caregiverActive;

  /// No description provided for @rejectCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectCaregiver;

  /// No description provided for @acceptCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptCaregiver;

  /// No description provided for @viewReadings.
  ///
  /// In en, this message translates to:
  /// **'View readings'**
  String get viewReadings;

  /// No description provided for @viewMedicines.
  ///
  /// In en, this message translates to:
  /// **'View medicines'**
  String get viewMedicines;

  /// No description provided for @viewAppointments.
  ///
  /// In en, this message translates to:
  /// **'View appointments'**
  String get viewAppointments;

  /// No description provided for @viewSubscription.
  ///
  /// In en, this message translates to:
  /// **'View subscription'**
  String get viewSubscription;

  /// No description provided for @addCaregiverIntro.
  ///
  /// In en, this message translates to:
  /// **'Invite a family member or friend via WhatsApp. They will receive a secure invitation link.'**
  String get addCaregiverIntro;

  /// No description provided for @countryCode.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get countryCode;

  /// No description provided for @countryCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a country code'**
  String get countryCodeRequired;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get whatsappNumber;

  /// No description provided for @whatsappRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid WhatsApp number'**
  String get whatsappRequired;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @familyMemberName.
  ///
  /// In en, this message translates to:
  /// **'Family member name (optional)'**
  String get familyMemberName;

  /// No description provided for @familyMemberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hooyo Amina'**
  String get familyMemberHint;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsTitle;

  /// No description provided for @whatsappInviteNote.
  ///
  /// In en, this message translates to:
  /// **'We will open WhatsApp so you can send the invitation directly.'**
  String get whatsappInviteNote;

  /// No description provided for @sendInvitationWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation via WhatsApp'**
  String get sendInvitationWhatsapp;

  /// No description provided for @couldNotOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsapp;

  /// No description provided for @invitationReady.
  ///
  /// In en, this message translates to:
  /// **'Invitation created. WhatsApp opened.'**
  String get invitationReady;

  /// No description provided for @relationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationshipMother;

  /// No description provided for @relationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationshipFather;

  /// No description provided for @relationshipBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relationshipBrother;

  /// No description provided for @relationshipSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relationshipSister;

  /// No description provided for @relationshipSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationshipSpouse;

  /// No description provided for @relationshipChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relationshipChild;

  /// No description provided for @relationshipFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationshipFriend;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @revokeCaregiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke caregiver?'**
  String get revokeCaregiverTitle;

  /// No description provided for @revokeCaregiverMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your caregivers? They will lose access immediately.'**
  String revokeCaregiverMessage(String name);

  /// No description provided for @revokeCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Revoke access'**
  String get revokeCaregiver;

  /// No description provided for @sendInvitationAgain.
  ///
  /// In en, this message translates to:
  /// **'Send invitation again'**
  String get sendInvitationAgain;

  /// No description provided for @savePermissions.
  ///
  /// In en, this message translates to:
  /// **'Save permissions'**
  String get savePermissions;

  /// No description provided for @caregiversMenu.
  ///
  /// In en, this message translates to:
  /// **'Caregivers'**
  String get caregiversMenu;

  /// No description provided for @caregiversMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage who can support your care'**
  String get caregiversMenuSubtitle;

  /// No description provided for @sponsorCareMenu.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Care'**
  String get sponsorCareMenu;

  /// No description provided for @sponsorCareMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and sponsor a loved one\'s care'**
  String get sponsorCareMenuSubtitle;

  /// No description provided for @mySponsorshipMenu.
  ///
  /// In en, this message translates to:
  /// **'My Sponsorship'**
  String get mySponsorshipMenu;

  /// No description provided for @mySponsorshipMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View patients you sponsor'**
  String get mySponsorshipMenuSubtitle;

  /// No description provided for @sponsorCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Care'**
  String get sponsorCareTitle;

  /// No description provided for @sponsorCareCard.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Care'**
  String get sponsorCareCard;

  /// No description provided for @sponsorCareCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay for a family member\'s care plan'**
  String get sponsorCareCardSubtitle;

  /// No description provided for @findPatientTab.
  ///
  /// In en, this message translates to:
  /// **'Find Patient'**
  String get findPatientTab;

  /// No description provided for @connectByWhatsappTab.
  ///
  /// In en, this message translates to:
  /// **'Connect via WhatsApp'**
  String get connectByWhatsappTab;

  /// No description provided for @findPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a patient to sponsor'**
  String get findPatientTitle;

  /// No description provided for @findPatientHint.
  ///
  /// In en, this message translates to:
  /// **'Search by phone number or member ID, or redeem an invitation code from the patient.'**
  String get findPatientHint;

  /// No description provided for @phoneOrMemberId.
  ///
  /// In en, this message translates to:
  /// **'Phone or Member ID'**
  String get phoneOrMemberId;

  /// No description provided for @phoneOrMemberIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HCC-2024-000125 or 612345678'**
  String get phoneOrMemberIdHint;

  /// No description provided for @findPatientButton.
  ///
  /// In en, this message translates to:
  /// **'Find Patient'**
  String get findPatientButton;

  /// No description provided for @redeemInvitationCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Or redeem invitation code'**
  String get redeemInvitationCodeTitle;

  /// No description provided for @invitationCode.
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// No description provided for @invitationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code shared with you'**
  String get invitationCodeHint;

  /// No description provided for @redeemCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Redeem Code'**
  String get redeemCodeButton;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @noPatientsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try a phone number, member ID, or invitation code.'**
  String get noPatientsFoundHint;

  /// No description provided for @connectByWhatsappTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a loved one on WhatsApp'**
  String get connectByWhatsappTitle;

  /// No description provided for @connectByWhatsappHint.
  ///
  /// In en, this message translates to:
  /// **'Send a connection request to someone already using Hiraal. Once they accept, you can sponsor their care.'**
  String get connectByWhatsappHint;

  /// No description provided for @sendConnectionRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Connection Request'**
  String get sendConnectionRequest;

  /// No description provided for @enterSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number or member ID'**
  String get enterSearchTerm;

  /// No description provided for @enterInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter an invitation code'**
  String get enterInvitationCode;

  /// No description provided for @sponsorPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Patient'**
  String get sponsorPatientTitle;

  /// No description provided for @chooseMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a monthly plan'**
  String get chooseMonthlyPlan;

  /// No description provided for @noPlansAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subscription plans are available right now.'**
  String get noPlansAvailable;

  /// No description provided for @sponsorThisPatient.
  ///
  /// In en, this message translates to:
  /// **'Sponsor This Patient'**
  String get sponsorThisPatient;

  /// No description provided for @confirmSponsorshipTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Sponsorship'**
  String get confirmSponsorshipTitle;

  /// No description provided for @memberIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberIdLabel;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @monthlyCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly cost'**
  String get monthlyCostLabel;

  /// No description provided for @payAndStartSponsorship.
  ///
  /// In en, this message translates to:
  /// **'Pay & Start Sponsorship'**
  String get payAndStartSponsorship;

  /// No description provided for @sponsorPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship Payment'**
  String get sponsorPaymentTitle;

  /// No description provided for @startingPayment.
  ///
  /// In en, this message translates to:
  /// **'Starting payment…'**
  String get startingPayment;

  /// No description provided for @startingSponsorPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we send the mobile-money request.'**
  String get startingSponsorPaymentHint;

  /// No description provided for @sponsorshipPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'The sponsorship payment was declined or cancelled.'**
  String get sponsorshipPaymentFailed;

  /// No description provided for @paymentStillProcessing.
  ///
  /// In en, this message translates to:
  /// **'Taking longer than usual. If you approved the request, payment will confirm automatically.'**
  String get paymentStillProcessing;

  /// No description provided for @sponsorshipActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship active'**
  String get sponsorshipActiveTitle;

  /// No description provided for @sponsorshipActiveHint.
  ///
  /// In en, this message translates to:
  /// **'You are now sponsoring {name}\'s care plan. Thank you!'**
  String sponsorshipActiveHint(String name);

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailedTitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneLabel;

  /// No description provided for @mySponsorshipTitle.
  ///
  /// In en, this message translates to:
  /// **'My Sponsorship'**
  String get mySponsorshipTitle;

  /// No description provided for @noSponsorshipsYet.
  ///
  /// In en, this message translates to:
  /// **'No sponsorships yet'**
  String get noSponsorshipsYet;

  /// No description provided for @noSponsorshipsHint.
  ///
  /// In en, this message translates to:
  /// **'When you sponsor someone\'s care, it will appear here.'**
  String get noSponsorshipsHint;

  /// No description provided for @activeSponsorships.
  ///
  /// In en, this message translates to:
  /// **'Active sponsorships'**
  String get activeSponsorships;

  /// No description provided for @nextPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get nextPaymentLabel;

  /// No description provided for @latestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest updates'**
  String get latestUpdates;

  /// No description provided for @patientSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Patient snapshot'**
  String get patientSnapshot;

  /// No description provided for @connectionRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Request'**
  String get connectionRequestTitle;

  /// No description provided for @connectionSentHeadline.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get connectionSentHeadline;

  /// No description provided for @connectionSentBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a connection request to {number}. You will be notified when they accept.'**
  String connectionSentBody(String number);

  /// No description provided for @connectionActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionActiveTitle;

  /// No description provided for @connectionActiveHeadline.
  ///
  /// In en, this message translates to:
  /// **'You are connected'**
  String get connectionActiveHeadline;

  /// No description provided for @connectionActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your connection with {name} is active. You can now sponsor their care.'**
  String connectionActiveBody(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'so'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'so':
      return AppLocalizationsSo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
