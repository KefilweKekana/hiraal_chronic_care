// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppLocalizationsSo extends AppLocalizations {
  AppLocalizationsSo([String locale = 'so']) : super(locale);

  @override
  String get appName => 'Hiraal';

  @override
  String get appNameFull => 'Hiraal Lifecare';

  @override
  String get appBrandSubtitle => 'Daryeel Caafimaad';

  @override
  String get appTagline => 'Kormeer Wanaagsan. Caafimaad Wanaagsan.';

  @override
  String get welcomeHeadline => 'Kormeer Wanaagsan.\nCaafimaad Wanaagsan.';

  @override
  String get appSubtitle =>
      'Cabbirradaada maalinlaha ah. Daryeelkayaga maalinlaha ah.\nWadajir ayaynu caafimaadkaaga ula soconnaa.';

  @override
  String get trustBadgeDataSafe =>
      'Xogtaadu waa ammaan,\nsi fiicanna waa loo ilaaliyey.';

  @override
  String get trustBadgeTrustedClinics =>
      'Waxa nagu kalsoon\nxarumaha caafimaadka ee ku daryeela.';

  @override
  String get getStarted => 'Bilow';

  @override
  String get needHelpContactSupport =>
      'Ma u baahan tahay caawimo? La xidhiidh taageerada.';

  @override
  String get contactSupportTitle => 'La xidhiidh taageerada';

  @override
  String supportPhoneLine(String primary, String secondary) {
    return 'Taleefan: $primary / $secondary';
  }

  @override
  String supportShortCodeLine(String shortCode) {
    return 'Telesom ama Somtel: wac $shortCode';
  }

  @override
  String supportEmailLine(String email) {
    return 'Iimayl: $email';
  }

  @override
  String supportHoursLine(String hours) {
    return 'Saacadaha: $hours';
  }

  @override
  String get close => 'Xir';

  @override
  String get welcomeBack => 'Ku soo dhawoow';

  @override
  String unlockWithBio(String bioLabel) {
    return 'Fur $bioLabel si aad u sii wadato';
  }

  @override
  String logInWithBio(String bioLabel) {
    return 'Gal $bioLabel';
  }

  @override
  String get signInAnotherWay => 'Si kale u gal';

  @override
  String get biometricFingerprint => 'Faraha';

  @override
  String get letsGetStarted => 'Aan bilowno';

  @override
  String get enterMobileLinkedToRecord =>
      'Geli lambarka moobaylka ee ku xidhan\ndiiwaankaaga bukaanka.';

  @override
  String get mobileNumber => 'Lambarka Moobaylka';

  @override
  String get emailAddress => 'Cinwaanka Iimaylka';

  @override
  String get enterEmailHint => 'Geli cinwaanka iimaylkaaga';

  @override
  String get enterPhoneHint => 'Geli lambarka moobaylka';

  @override
  String get otpWillEmailCode =>
      'Waxaan koodhka hal-mar ah kuugu soo diri doonnaa iimaylkan.';

  @override
  String get lookupRecordInHospital =>
      'Waxaannu diiwaankaaga ka raadin doonnaa nidaamka cusbitaalka.';

  @override
  String get sendMyCodeVia => 'Koodhka iigu soo dir';

  @override
  String get channelSms => 'Farriin qoraal ah';

  @override
  String get channelSmsSublabel => 'SMS moobaylkaaga';

  @override
  String get channelEmail => 'Iimayl';

  @override
  String get channelEmailSublabel => 'Iimaylka ku qoran diiwaankaaga';

  @override
  String get sendCode => 'Soo dir koodhka';

  @override
  String get infoSafeWithUs =>
      'Macluumaadkaagu waa ammaan, si fiicanna waannu u ilaalinaa.';

  @override
  String get newToHiraal => 'Hiraal ma ku cusub tahay?';

  @override
  String get createAnAccount => 'Samayso akoon';

  @override
  String get verifyYourAccount => 'Xaqiiji akoonkaaga';

  @override
  String get otpSentSms => 'Waxannu koodh 6 lambar ah u dirnay';

  @override
  String get otpSentEmail =>
      'Waxannu koodh 6 lambar ah iimayl kuugu soo dirnay';

  @override
  String get yourEmailFallback => 'iimaylkaaga';

  @override
  String get edit => 'Beddel';

  @override
  String get enterSixDigitCode => 'Geli koodhka 6-da lambar ah';

  @override
  String get didntReceiveCode => 'Koodhku miyaanu kusoo gaadhin?';

  @override
  String get resend => 'Dib u dir';

  @override
  String resendInSeconds(int seconds) {
    return 'Dib u dir $seconds ilbidhiqsi kadib';
  }

  @override
  String otpExpiresInMinutes(int minutes) {
    return 'Ammaankaaga awgiis, koodhkani wuxuu dhacayaa $minutes daqiiqo gudahood.';
  }

  @override
  String get verifyAndContinue => 'Xaqiiji oo sii wad';

  @override
  String get verificationFailed =>
      'Xaqiijintu way fashilantay. Fadlan isku day mar kale.';

  @override
  String get failedToResendOtp => 'Dib u dirista koodhka way fashilantay';

  @override
  String get codeResentEmail => 'Koodhka ayaa iimayl dib loogu diray';

  @override
  String get otpResentSuccess => 'Koodhka si guul leh ayaa dib loo diray';

  @override
  String get navHome => 'Hore';

  @override
  String get navServices => 'Adeegyo';

  @override
  String get navHistory => 'Diiwaan';

  @override
  String get navProfile => 'Akoon';

  @override
  String get offlineBanner =>
      'Ma ku xirnidin — cabbirrada waxa lagu kaydinayaa taleefankan';

  @override
  String get backOnlineSyncing =>
      'Dib ayaad u xirmay — waa la isku-dubbaridayaa…';

  @override
  String get greetingMorning => 'Subax wanaagsan,';

  @override
  String get greetingAfternoon => 'Galab wanaagsan,';

  @override
  String get greetingEvening => 'Fiid wanaagsan,';

  @override
  String get patientFallback => 'Bukaan';

  @override
  String get paymentPending => 'Lacag sugaysa';

  @override
  String orderPayToContinue(String id, String amount) {
    return 'Dalab #$id — bixi $amount si aad u sii wadato';
  }

  @override
  String get nextAppointment => 'Ballanta xigta';

  @override
  String get yourDoctor => 'Dhakhtarkaaga';

  @override
  String get todaysDate => 'Taariikhda maanta';

  @override
  String get lastSubmitted => 'Ugu dambeeyey';

  @override
  String get noReadingYetToday => 'Weli maanta lama dirin';

  @override
  String get enterReadingsInfo =>
      'Fadlan geli cabbirradaada oo u dir kooxda ku daryeesha.';

  @override
  String get todaysReading => 'Cabbirrada maanta';

  @override
  String get required => 'Waa khasab';

  @override
  String get bloodPressure => 'Cadaadiska dhiigga';

  @override
  String get unitMmHg => 'mmHg';

  @override
  String get systolicTop => 'Cadaadiska sare';

  @override
  String get diastolicBottom => 'Cadaadiska hoose';

  @override
  String get hintSystolic => 'Tusaale: 120';

  @override
  String get hintDiastolic => 'Tusaale: 80';

  @override
  String get bloodSugar => 'Sonkorta dhiigga';

  @override
  String get unitMgDl => 'mg/dL';

  @override
  String get hintBloodSugar => 'Tusaale: 140';

  @override
  String get weight => 'Miisaanka';

  @override
  String get unitKg => 'kg';

  @override
  String get hintWeight => 'Tusaale: 70';

  @override
  String get medicineTaken => 'Dawada laguu qoray';

  @override
  String get medicineTakenPrompt => 'Ma qaadatay dawadaada sida laguugu qoray?';

  @override
  String get yesTaken => 'Haa, waan qaatay';

  @override
  String get noMissed => 'Maya, waan seegay';

  @override
  String get addNoteOptional => 'Ku dar qoraal (ikhtiyaari)';

  @override
  String get howFeelingHint => 'Sidee ayaad maanta dareemaysaa?';

  @override
  String get connectDevice => 'Ku xidh qalabka';

  @override
  String get importReadingsFromDevice => 'Soo geli cabbirrada qalabkaaga';

  @override
  String get connected => 'Waa la xidhay';

  @override
  String get saveAndSend => 'Kaydi oo Dir';

  @override
  String get sendReadingToCareTeam => 'U dir cabbirka kooxda ku daryeesha';

  @override
  String get submittingReading => 'Waa la dirayaa cabbirkaaga...';

  @override
  String get dontCloseWhileSending =>
      'Fadlan ha xirin app-ka inta aan xogta dirayno.';

  @override
  String get dataSecureProtected => 'Xogtaadu waa ammaan oo waa la ilaaliyey.';

  @override
  String get failedToSubmitReading => 'Dirista cabbirka way fashilantay';

  @override
  String get allSet => 'Waa dhammaatay!';

  @override
  String get readingSavedSent =>
      'Cabbirkaaga maanta waa la kaydiyey\noo waa loo diray kooxda ku daryeesha.';

  @override
  String get careTeamNotified =>
      'Xogtaadu waa ammaan oo kooxda ku daryeesha\nwaa la ogeysiiyey.';

  @override
  String get submissionSummary => 'Soo koobidda dirista';

  @override
  String get date => 'Taariikhda';

  @override
  String get time => 'Wakhtiga';

  @override
  String get sentTo => 'Loo diray';

  @override
  String get yourCareTeam => 'Kooxda ku daryeesha';

  @override
  String get referenceId => 'Lambarka tixraaca';

  @override
  String get notAvailable => '—';

  @override
  String get notifiedWhenReviewed =>
      'Waa lagu ogeysiin doonaa marka kooxda ku daryeesha\nay eegto cabbirkaaga.';

  @override
  String get goToHome => 'Tag bogga hore';

  @override
  String get viewHistory => 'Eeg diiwaanka';

  @override
  String get servicesTitle => 'Adeegyada';

  @override
  String get chooseCareToday =>
      'Dooro adeegga caafimaad ee aad maanta u baahan tahay.';

  @override
  String get searchServicesHint => 'Raadi adeeg, dhakhtar, ama dawo...';

  @override
  String get bookDoctor => 'Dhakhtar';

  @override
  String get bookDoctorSubtitle => 'La tasho\nmaqal iyo muuqaal';

  @override
  String get hiraalPharma => 'Hiraal Pharma';

  @override
  String get uploadPrescription => 'Soo geli\nrijeeto';

  @override
  String get labTest => 'Shaybaadh';

  @override
  String get labTestSubtitle => 'Baadhitaan\nmeel kuu dhow';

  @override
  String get quickSecureHealthcare =>
      'Daryeel caafimaad oo degdeg ah, ammaan ah, laguna kalsoonaan karo.';

  @override
  String get recommendedForYou => 'Adiga lagugula taliyey';

  @override
  String get viewAll => 'Eeg dhammaan';

  @override
  String get doctorFallback => 'Dhakhtar';

  @override
  String get departmentGeneral => 'Guud';

  @override
  String get yourVideoVisits => 'La-tashiyadaada Fiidyowga';

  @override
  String get joinLiveVideo => 'Ku biir la-tashiga fiidyowga tooska ah';

  @override
  String get orderFromHiraalPharma => 'Ka dalbo Hiraal Pharma';

  @override
  String get uploadRxForDelivery =>
      'Soo geli warqadda dawada si loo eego\nloo keenona';

  @override
  String get popularCategories => 'Qaybaha caanka ah';

  @override
  String get categoryHeartCare => 'Daryeelka Wadnaha';

  @override
  String get categoryChestCare => 'Daryeelka Laabta';

  @override
  String get categoryDiabetesCare => 'Daryeelka Sonkorta';

  @override
  String get categoryMentalHealth => 'Caafimaadka Maskaxda';

  @override
  String get selectDoctor => 'Dooro Dhakhtar';

  @override
  String noSpecialistsShowingAll(String specialty) {
    return 'Ma jiro dhakhtar ku takhasusay $specialty oo liiska ku jira — dhammaan dhakhaatiirta ayaa lagu tusayaa.';
  }

  @override
  String get retry => 'Isku day mar kale';

  @override
  String get refresh => 'Cusboonaysii';

  @override
  String get noDoctorsAvailable =>
      'Ma jiro dhakhtar hadda diyaar ah. Fadlan isku day mar dambe.';

  @override
  String get appointmentDetails => 'Faahfaahinta ballanta';

  @override
  String get reasonForVisit => 'Sababta Booqashada';

  @override
  String get reasonVisitHint =>
      'Fadlan sheeg calaamadaha aad dareemayso ama sababta aad dhakhtarka u booqanayso...';

  @override
  String get selectDate => 'Dooro Taariikhda';

  @override
  String get timeSlot => 'Dooro Wakhtiga';

  @override
  String get availableSlotsHint =>
      'Waxa lagu tusayaa wakhtiyada bannaan ee maanta iyo 7-da maalmood ee soo socda.';

  @override
  String get visitType => 'Nooca Booqashada';

  @override
  String get chooseConsultHow => 'Dooro sida aad dhakhtarka ula tashan lahayd.';

  @override
  String get videoCall => 'Maqal iyo Muuqaal';

  @override
  String get consultFromHome => 'Guriga ka la tasho';

  @override
  String get inPersonVisit => 'Booqasho xarunta ah';

  @override
  String get visitAtClinic => 'Xarunta ku booqo';

  @override
  String get clinicLocationLabel =>
      'Goobta Xarunta Caafimaadka (booqashada tooska ah)';

  @override
  String get selectClinic => 'Dooro xarunta caafimaadka';

  @override
  String get pleaseSelectStation =>
      'Fadlan dooro saldhigga daryeelka ee booqashadaada.';

  @override
  String get noStationsAvailable =>
      'Ma jiro saldhig daryeel hadda diyaar ah. Fadlan isku day mar dambe ama ballan fiidyow qabso.';

  @override
  String get appointmentSecureEasy =>
      'Ballantaadu waa ammaan oo si fudud ayaa loo maamuli karaa.';

  @override
  String get requestAppointment => 'Codso Ballan';

  @override
  String get confirmationShortly => 'Waxaad heli doontaa xaqiijin dhawaan.';

  @override
  String get pleaseSelectDoctor => 'Fadlan marka hore dooro dhakhtar.';

  @override
  String get pleaseDescribeReason => 'Fadlan sheeg sababta booqashada.';

  @override
  String get appointmentConfirmedTitle => 'Ballanta waa la xaqiijiyey';

  @override
  String get appointmentBooked => 'Ballanta waa la qabtay!';

  @override
  String appointmentConfirmedFor(String date, String time) {
    return 'Ballantaadu waxay xaqiijisan tahay $date saacadda $time.';
  }

  @override
  String get videoVisitJoinReady =>
      'Tani waa booqasho fiidyow. Xiriirka ka-qaybgalka wuxuu diyaar ku yahay La-tashiyada Fiidyowga.';

  @override
  String get goToVideoVisit => 'Tag la-tashiga fiidyowga';

  @override
  String get backToServices => 'Ku noqo Adeegyada';

  @override
  String get myAppointments => 'Ballamahayga';

  @override
  String get noUpcomingAppointments => 'Ma jiraan ballamo soo socda';

  @override
  String get bookDoctorEmptyHint =>
      'Ballan dhakhtar qabso oo ballamahaagu\nhalkan ayay ka muuqan doonaan.';

  @override
  String get appointmentBookedStatus => 'Waa la qabtay ballanta';

  @override
  String get historyTitle => 'Diiwaanka';

  @override
  String get filterReadingsTooltip => 'Shaandhee cabbirrada';

  @override
  String get filter => 'Shaandheeye';

  @override
  String get filterAllTime => 'Wakhtiga oo dhan';

  @override
  String get filterLast7Days => '7 maalmood';

  @override
  String get filterLast30Days => '30 maalmood';

  @override
  String get filterLast90Days => '90 maalmood';

  @override
  String get tabReadings => 'Cabbirrada';

  @override
  String get tabNotes => 'Qoraallada';

  @override
  String get tabAlerts => 'Digniinaha';

  @override
  String get statSubmissionsTotal => 'Wadarta\ncabbirrada';

  @override
  String get statAvgSystolic => 'Celcelis\ncadaadis sare';

  @override
  String get statAvgSugar => 'Celcelis\nsonkor';

  @override
  String get historyInfoBanner =>
      'Cabbirradaadii hore iyo jawaabaha kooxda ku daryeesha ayaa halkan ka muuqan doona.';

  @override
  String get careTeamFeedbackFooter =>
      'Jawaabaha kooxda ku daryeesha ayaa halkan ka muuqan doona marka ay eegaan cabbirradaada.';

  @override
  String get listView => 'Liis ahaan';

  @override
  String get chartView => 'Jaantus ahaan';

  @override
  String todayDateLabel(String date) {
    return 'Maanta, $date';
  }

  @override
  String yesterdayDateLabel(String date) {
    return 'Shalay, $date';
  }

  @override
  String get notEnoughChartData => 'Xogta kuma filna jaantuska';

  @override
  String get systolic => 'Sare';

  @override
  String get diastolic => 'Hoose';

  @override
  String get sugar => 'Sonkor';

  @override
  String get noNotesYet => 'Weli qoraal ma jiro';

  @override
  String get noAlerts => 'Digniin ma jirto';

  @override
  String get statusPending => 'Sugaya';

  @override
  String get statusSent => 'La diray';

  @override
  String get profileTitle => 'Akoonkayga';

  @override
  String memberId(String id) {
    return 'Lambarka xubinimada: $id';
  }

  @override
  String get yourProgram => 'Xidhmadaada';

  @override
  String get programHypertensionCare => 'Xidhmada Daryeelka Dhiig-karka';

  @override
  String get memberSinceMay2024 => 'Xubin ah tan iyo May 2024';

  @override
  String get statusActive => 'Socda';

  @override
  String get myInformation => 'Xogtayda';

  @override
  String get personalInformation => 'Xogtayda shakhsiga ah';

  @override
  String get updatePersonalDetails => 'Wax ka bedel xogtaada shakhsiga ah';

  @override
  String get healthInformation => 'Xogtaada caafimaad';

  @override
  String get viewHealthSummary => 'Warbixin caafimaad';

  @override
  String get medicalHistory => 'Diiwaanka xaaladaha caafimaad';

  @override
  String get viewPastRecords => 'Eeg diiwaannadaadii hore';

  @override
  String get addresses => 'Cinwaannada';

  @override
  String get manageAddresses => 'Maamul cinwaannadaada';

  @override
  String get myActivity => 'Dhaqdhaqaaqayga';

  @override
  String countUpcoming(String count) {
    return '$count Soo socda';
  }

  @override
  String get appointments => 'Ballamaha';

  @override
  String countScheduled(String count) {
    return '$count Ballan la qabtay';
  }

  @override
  String get labTests => 'Baadhitaannada';

  @override
  String countActive(String count) {
    return '$count Hadda socda';
  }

  @override
  String get orders => 'Dalabyada';

  @override
  String get account => 'Akoonka';

  @override
  String get subscription => 'Xidhmo';

  @override
  String get subscriptionSubtitle =>
      'Eeg, isdiiwaangeli, ama cusboonaysii qorshahaaga';

  @override
  String get payments => 'Lacag-bixinnada';

  @override
  String get paymentsSubtitle =>
      'Eeg taariikhda lacag-bixintaada iyo rasiidhada';

  @override
  String get privacyAndSecurity => 'Asturnaanta & Amniga';

  @override
  String get manageAccountSecurity => 'Maamul amniga akoonkaaga';

  @override
  String get settings => 'Dejinta';

  @override
  String get settingsSubtitle => 'Nooca app-ka iyo macluumaadka';

  @override
  String get logOut => 'Ka bax';

  @override
  String get couldNotLogOut =>
      'Ka bixitaanku way fashilantay. Fadlan isku day mar kale.';

  @override
  String get language => 'Luqadda';

  @override
  String get languageSubtitle => 'English ama Soomaali';

  @override
  String get chooseLanguage => 'Dooro luqadda';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Soomaali';

  @override
  String get reminders => 'Xasuusinta';

  @override
  String get medicationReminder => 'Xasuusinta dawada';

  @override
  String dailyAtTime(String time) {
    return 'Maalin kasta $time';
  }

  @override
  String get readingReminder => 'Xasuusinta cabbirrada';

  @override
  String get accessibility => 'Fududaynta isticmaalka';

  @override
  String get largeText => 'Qoraal far muuqata';

  @override
  String get largeTextSubtitle => 'Weynee farta qoraalka App-ka oo dhan';

  @override
  String get about => 'Ku saabsan';

  @override
  String get appVersion => 'Nooca app-ka';

  @override
  String get build => 'Dhismaha';

  @override
  String get buildDebug => 'Cilad-saar';

  @override
  String get buildRelease => 'Siidayn';

  @override
  String get myOrders => 'Dalabyadayda';

  @override
  String get newOrder => 'Dalab cusub';

  @override
  String get noOrdersYet => 'Weli dalab ma jiro';

  @override
  String get tapNewOrderHint =>
      'Taabo “Dalab cusub” si aad u dalbato keenista dawo.';

  @override
  String get prescriptionOrder => 'Dalab warqadda dawada';

  @override
  String plusMore(int count) {
    return '+$count kale';
  }

  @override
  String get otherMedicine => 'dawo kale';

  @override
  String get cancelled => 'Waa la joojiyey';

  @override
  String get tapToPay => 'Taabo si aad u bixiso';

  @override
  String get paymentPendingShort => 'Lacag-bixin sugaysa';

  @override
  String get outForDelivery => 'Waa lagu soo wadaa';

  @override
  String get delivered => 'Waa lagu soo gaadhsiiyey';

  @override
  String get trackOrder => 'La soco dalabka';

  @override
  String orderNumber(String id) {
    return 'Dalab #$id';
  }

  @override
  String placedAt(String datetime) {
    return 'La dalbaday $datetime';
  }

  @override
  String get orderNotFound => 'Dalabka lama helin.';

  @override
  String get somethingWentWrong => 'Wax baa khaldamay';

  @override
  String itemsCount(int count) {
    return 'Dawooyinka ($count)';
  }

  @override
  String get awaitingPharmacistReview =>
      'Waxa la sugayaa eegista farmashiistaha — alaabtu waxay halkan ka muuqan doontaa marka warqadda la farsameeyo.';

  @override
  String get paymentSection => 'Lacag-bixinta';

  @override
  String get subtotal => 'Wadarta hore';

  @override
  String get deliveryFee => 'Kharashka keenista';

  @override
  String get handlingFee => 'Kharashka xamaalka';

  @override
  String get tax => 'Canshuur';

  @override
  String get total => 'Wadarta guud';

  @override
  String get status => 'Xaaladda';

  @override
  String get confirmAndPay => 'Xaqiiji oo Bixi';

  @override
  String confirmAndPayAmount(String amount) {
    return 'Xaqiiji oo Bixi  $amount';
  }

  @override
  String get stagePrescriptionReceived => 'Warqadda dawada waa la helay';

  @override
  String get stageUnderReview => 'Farmashiistaha ayaa eegaya';

  @override
  String get stageAwaitingPayment => 'Waxa la sugayaa lacag-bixintaada';

  @override
  String get stagePaymentConfirmed => 'Lacag-bixinta waa la xaqiijiyey';

  @override
  String get stagePreparing => 'Dawooyinkaaga waa la diyaarinayaa';

  @override
  String get stageOutForDelivery => 'Dawooyinkaaga waa lagu soo wadaa';

  @override
  String get stageDelivered => 'Waa lagu soo gaadhsiiyey';

  @override
  String get waitingForYourPayment => 'Waxa la sugayaa lacag-bixintaada';

  @override
  String get paymentPendingBadge => 'Lacag-bixinta ayaa la sugayaa';

  @override
  String get payWith => 'Ku bixi';

  @override
  String get mobileMoneyNumber => 'Lambarka lacagta moobilka';

  @override
  String get mobileMoneyHint => 'Tusaale: 252612345678';

  @override
  String payAmount(String amount) {
    return 'Bixi $amount';
  }

  @override
  String get choosePaymentMethod => 'Dooro habka lacag-bixinta.';

  @override
  String get enterMobileMoneyNumber => 'Geli lambarka lacagta moobilka.';

  @override
  String get waitingForPayment => 'Waxa la sugayaa lacag-bixinta';

  @override
  String approvePayWith(String amount, String method) {
    return 'Ogolow in aad $method ku bixiso $amount';
  }

  @override
  String requestSentTo(String number) {
    return 'Codsiga waxa loo diray $number';
  }

  @override
  String expiresIn(String time) {
    return 'Wuxuu dhacayaa $time kadib';
  }

  @override
  String openMobileMoneyApp(String method) {
    return '$method ka taleefankaaga fur';
  }

  @override
  String get enterPinToConfirm =>
      'Geli PIN-kaaga si aad u xaqiijiso lacag-bixinta';

  @override
  String get pageConfirmsAutomatically =>
      'Boggani si toos ah ayuu u xaqiijinayaa lacag-bixinta';

  @override
  String get iPaidCheckNow => 'Waan bixiyey — hadda hubi';

  @override
  String get cancelAndTryAgain => 'Jooji oo mar kale isku day';

  @override
  String get paymentSuccessful => 'Lacag-bixintu way guulaysatay';

  @override
  String get preparingMedicinesNow =>
      'Hadda waxa la diyaarinayaa dawooyinkaaga.';

  @override
  String get exit => 'Ka bax';

  @override
  String get senderMobileNumber => 'Lambarka lacagta diraya';

  @override
  String get noPaymentsYet => 'Weli lacag-bixin ma jirto';

  @override
  String get paymentsEmptyHint =>
      'Lacag-bixinnada xidhmooyinka iyo dalabyada ayaa halkan ka muuqan doona.';

  @override
  String get careSubscription => 'Xidhmada daryeelka';

  @override
  String orderTitle(String id) {
    return 'Dalab $id';
  }

  @override
  String get paid => 'Waa la bixiyey';

  @override
  String get paymentReceipt => 'Rasiidhka lacag-bixinta';

  @override
  String get item => 'Shayga';

  @override
  String get service => 'Adeegga';

  @override
  String get reference => 'Tixraaca';

  @override
  String get amount => 'Lacagta';

  @override
  String get shareReceipt => 'Wadaag rasiidhka';

  @override
  String get shareReceiptWithSomeone => 'Cid la wadaag rasiidhka';

  @override
  String get notifications => 'Ogeysiisyada';

  @override
  String get markAllRead => 'Akhri dhammaan';

  @override
  String get tabAll => 'Dhammaan';

  @override
  String get tabMessages => 'Farriimaha';

  @override
  String get tabReminders => 'Xasuusinta';

  @override
  String get noNotificationsYet => 'Weli ogeysiis ma jiro';

  @override
  String get notificationsEmptyHint =>
      'Farriimaha, xasuusinta iyo digniinaha kooxda\nku daryeesha ayaa halkan ka muuqan doona.';

  @override
  String get sectionToday => 'Maanta';

  @override
  String get sectionYesterday => 'Shalay';

  @override
  String get sectionThisWeek => 'Toddobaadkan';

  @override
  String get sectionOlder => 'Ka hore';

  @override
  String get justNow => 'hadda';

  @override
  String minutesAgo(int minutes) {
    return '$minutes daqiiqo ka hor';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours saacadood ka hor';
  }

  @override
  String daysAgo(int days) {
    return '$days maalmood ka hor';
  }

  @override
  String get monthJanuary => 'Janaayo';

  @override
  String get monthFebruary => 'Febraayo';

  @override
  String get monthMarch => 'Maarso';

  @override
  String get monthApril => 'Abriil';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'Juun';

  @override
  String get monthJuly => 'Luulyo';

  @override
  String get monthAugust => 'Agoosto';

  @override
  String get monthSeptember => 'Sebtembar';

  @override
  String get monthOctober => 'Oktoobar';

  @override
  String get monthNovember => 'Nofembar';

  @override
  String get monthDecember => 'Disembar';

  @override
  String get weekdayMonday => 'Isniin';

  @override
  String get weekdayTuesday => 'Talaado';

  @override
  String get weekdayWednesday => 'Arbaco';

  @override
  String get weekdayThursday => 'Khamiis';

  @override
  String get weekdayFriday => 'Jimce';

  @override
  String get weekdaySaturday => 'Sabti';

  @override
  String get weekdaySunday => 'Axad';

  @override
  String get uploadYourPrescription => 'Soo geli warqadda dawada';

  @override
  String get uploadPrescriptionExplain =>
      'Sawir cad ka qaad warqadda dawada. Farmashiistahayagu wuu eegi doonaa, qiimaha ayuu kuu xaqiijin doonaa, kadibna wuxuu ku weydiin doonaa inaad bixiso lacagta ka hor inta aan dawada la diyaarin oo laguugu keenin.';

  @override
  String get tapToAddPrescriptionPhoto =>
      'Taabo si aad ugu darto sawirka warqadda dawada';

  @override
  String get cameraOrGallery => 'Kaamirada ama sawirrada';

  @override
  String get addYourPrescription => 'Ku dar warqadda dawada';

  @override
  String get takeAPhoto => 'Sawir qaado';

  @override
  String get chooseFromGallery => 'Ka dooro sawirrada';

  @override
  String get noteForPharmacistOptional =>
      'Qoraal u reeb farmashiistaha (ikhtiyaari)';

  @override
  String get noteForPharmacistHint =>
      'Tusaale: nooca dawada aad doorbidayso, xasaasiyad, ama wax kale oo ay tahay inaan ogaano';

  @override
  String get deliveryAddress => 'Cinwaanka laguugu keenayo';

  @override
  String get selectDeliveryAddress => 'Dooro cinwaanka laguugu keenayo';

  @override
  String get addNewAddress => 'Ku dar cinwaan cusub';

  @override
  String get addADeliveryAddress => 'Ku dar cinwaanka laguugu keenayo';

  @override
  String get change => 'Beddel';

  @override
  String get prescriptionPrivacyNote =>
      'Warqadda dawadaadu waa qarsoodi, waxaana lala wadaagayaa farmashiyahayaga oo keliya.';

  @override
  String get submitPrescription => 'Gudbi warqadda dawada';

  @override
  String get pleaseAttachPrescription =>
      'Fadlan ku dar sawirka warqadda dawada.';

  @override
  String get pleaseChooseDeliveryAddress =>
      'Fadlan dooro cinwaanka laguugu keenayo.';

  @override
  String get couldNotOpenCamera => 'Kaamirada lama furi karin.';

  @override
  String get couldNotOpenGallery => 'Sawirrada lama furi karin.';

  @override
  String get cancelOrderQuestion => 'Ma joojinaysaa dalabka?';

  @override
  String get cancelOrderMessage =>
      'Tani waxay joojinaysaa dalabkaaga dawada. Waxaad samayn kartaa dalab cusub wakhti kasta.';

  @override
  String get keepOrder => 'Dalabka sii hay';

  @override
  String get cancelOrder => 'Jooji dalabka';

  @override
  String get cancelling => 'Waa la joojinayaa…';

  @override
  String get confirming => 'Waa la xaqiijinayaa…';

  @override
  String get iReceivedMyOrder => 'Dalabkayga waan helay';

  @override
  String get confirmReceiptQuestion => 'Ma xaqiijinaysaa helidda?';

  @override
  String get confirmReceiptMessage => 'Xaqiiji inaad heshay dalabkan.';

  @override
  String get notYet => 'Weli maya';

  @override
  String get yesReceived => 'Haa, waan helay';

  @override
  String get receiptConfirmedThanks => 'Mahadsanid! Helidda waa la xaqiijiyey.';

  @override
  String get prescriptionAttached => 'Warqadda dawada waa lagu daray';

  @override
  String get outOfStock => 'Ma jiro keyd';

  @override
  String get orderWasCancelled => 'Dalabkan waa la joojiyey';

  @override
  String get deliverySection => 'Gaadhsiin';

  @override
  String get typeLabel => 'Nooca';

  @override
  String get addressLabel => 'Cinwaanka';

  @override
  String get estimatedLabel => 'Qiyaasta';

  @override
  String get requestLabTest => 'Codso baadhitaanka shaybaadhka';

  @override
  String get labTestInfoTitle => 'Macluumaadka baadhitaanka';

  @override
  String get labTestInfoBody =>
      'Dooro baadhitaan, sharax sababtaada, kadibna gudbi. Kooxda daryeelku way eegi doonaan oo wakhti bay kuu xaqiijin doonaan.\n\nNatiijooyinku waxay ka muuqan doonaan Diiwaankaaga marka ay diyaar noqdaan.';

  @override
  String get gotIt => 'Waan fahmay';

  @override
  String get whyNeedLabTest =>
      'Maxaad ugu baahan tahay baadhitaanka shaybaadhka?';

  @override
  String get labTestReasonHint =>
      'Tusaale: Dhakhtar ayaa kugula taliyey, caafimaad-darro ayaad dareemaysaa, ama baadhitaan joogto ah';

  @override
  String get selectTest => 'Dooro baadhitaanka';

  @override
  String get searchLabTestsHint => 'Raadi baadhitaannada shaybaadhka...';

  @override
  String get preferredDate => 'Taariikhda aad doorbidayso';

  @override
  String get whereWantTest =>
      'Xaggee ayaad rabtaa in baadhitaanka lagugu sameeyo?';

  @override
  String get visitClinic => 'Booqo xarunta caafimaadka';

  @override
  String get visitClinicSubtitle => 'Tag shaybaadh kuu dhow';

  @override
  String get homeSampleCollection => 'Guriga lagaaga qaado';

  @override
  String get homeSampleSubtitle => 'Gurigaaga ayaan kuugu iman doonaa';

  @override
  String get fastingMayBeRequired =>
      'Baadhitaannada qaarkood waxaa laga yaabaa inaad soonto. Waan kuu sheegi doonaa.';

  @override
  String get requestSecurePrivate => 'Codsigaagu waa ammaan oo waa qarsoodi.';

  @override
  String get pleaseSelectAtLeastOneTest =>
      'Fadlan dooro ugu yaraan hal baadhitaan';

  @override
  String get labTestShortTitle => 'Baadhitaanka shaybaadhka';

  @override
  String get testScheduled =>
      'Baadhitaanka shaybaadhka balantii waa loo qabtay!';

  @override
  String get testScheduledBody =>
      'Codsigaga waanu qorshaynay, baadhitaanka shaybaadhkana ballan ayaa loo qabtay.';

  @override
  String get testType => 'Nooca baadhitaanka';

  @override
  String get timeLabel => 'Saacadda';

  @override
  String get nextAvailable => 'Wakhtiga ugu dhow ee bannaan';

  @override
  String get viewAllBookings => 'Eeg dhammaan ballamaha';

  @override
  String get alert => 'Digniin';

  @override
  String get highBpDetected => 'Cadaadis dhiig oo sarreeya ayaa la ogaaday';

  @override
  String get highBpSubtitle =>
      'Cabbirkaagu wuxuu ka sarreeyaa heerka badbaadada leh.\nFadlan raac tallaabooyinka hoose.';

  @override
  String get yourLatestReading => 'Cabbirkaagii ugu dambeeyay';

  @override
  String get highBadge => 'Sarreeya';

  @override
  String get safeRangeBp => 'Heerka badbaadada leh: Ka hooseeya 140/90 mmHg';

  @override
  String get whatYouShouldDo => 'Waxa ay tahay inaad samayso';

  @override
  String get contactYourCareTeam => 'La xidhiidh kooxdaada daryeelka';

  @override
  String get contactCareTeamHint =>
      'Waxaan kugula talinaynaa inaad maanta la hadasho kooxdaada daryeelka.';

  @override
  String get restAndRecheck => 'Naso oo mar kale cabbir';

  @override
  String get restAndRecheckHint =>
      'Si deggan u fadhiiso 5 daqiiqo, kadibna mar kale cabbir cadaadiska dhiiggaaga.';

  @override
  String get restThenRecheckSnack => 'Naso 5 daqiiqo, kadibna mar kale cabbir';

  @override
  String get seekUrgentCare => 'Raadi daryeel degdeg ah haddii loo baahdo';

  @override
  String get seekUrgentCareHint =>
      'Haddii aad qabto xanuun laabta ah, neefta oo kugu yaraata, ama madax-xanuun daran, gargaar degdeg ah raadso.';

  @override
  String get seekUrgentCareDialogBody =>
      'Haddii aad dareento xanuun laabta ah, neefta oo kugu yaraata, madax-xanuun daran, ama isbeddel aragga, fadlan tag qolka gurmadka ugu dhow ama isla markiiba wac adeegga gurmadka.';

  @override
  String get getHelpNow => 'Hel gargaar hadda';

  @override
  String get getHelpNowHint =>
      'Haddii aad leedahay calaamado daran,\nwac adeegga gurmadka degdegga ah.';

  @override
  String callEmergencyNumber(String number) {
    return 'Wac $number';
  }

  @override
  String get contactMyCareTeam => 'La xidhiidh kooxdayda daryeelka';

  @override
  String get recheckMyBloodPressure => 'Mar kale cabbir cadaadiska dhiiggayga';

  @override
  String get ok => 'Haye';

  @override
  String get emergencyCallTitle => 'Wicitaanka degdegga ah';

  @override
  String unableToOpenDialer(String number) {
    return 'Wicitaanka lama furi karin. Fadlan isla markiiba wac adeegga gurmadka $number.';
  }

  @override
  String get careTeamCall => 'Wicitaanka kooxda daryeelka';

  @override
  String get youreCalling => 'Waxaad wacaysaa...';

  @override
  String get careTeamNurse => 'Kalkaalisada kooxda daryeelka';

  @override
  String get wereHereToHelp => 'Waxaan halkan u joognaa inaan ku caawino.';

  @override
  String get expectedWaitTime => 'Wakhtiga sugitaanka';

  @override
  String get lessThan2Minutes => 'Wax ka yar 2 daqiiqo';

  @override
  String get availableHours => 'Saacadaha la heli karo';

  @override
  String get availableHoursValue => '8:00 AM – 8:00 PM, maalin kasta';

  @override
  String get careTeamCanSeeReadings =>
      'Kooxdaada daryeelku waxay arki karaan cabbirradaadii u dambeeyay iyo xogtaada caafimaad si ay si fiican kuugu caawiyaan.';

  @override
  String get recentConcern => 'Xaaladdii u dambaysay';

  @override
  String get highBloodPressureTitle => 'Cadaadis dhiig oo sarreeya';

  @override
  String get viewAction => 'Eeg';

  @override
  String get endCall => 'Jooji wicitaanka';

  @override
  String get callingStatus => 'Wacaya...';

  @override
  String get speaker => 'Sameecadda';

  @override
  String get speakerToggled => 'Sameecadda waa la beddelay';

  @override
  String get preferToMessage => 'Ma doorbidaysaa farriin?';

  @override
  String get sendMessageArrow => 'Dir farriin >';

  @override
  String get messageCareTeam => 'Farriin u dir kooxda daryeelka';

  @override
  String get describeYourConcern => 'Sharax xaaladda ku haysa...';

  @override
  String get sendMessage => 'Dir farriin';

  @override
  String get messageSentSnack =>
      'Farriinta waa la diray. Kooxda daryeelku way kuu jawaabi doonaan dhawaan.';

  @override
  String get connectMeasurementDevice => 'Ku xidh qalabka cabbirka';

  @override
  String get noDeviceConnected => 'Wax qalab ah kuma xidhna';

  @override
  String connectedToDevice(String name) {
    return 'Waxa lagu xidhay $name';
  }

  @override
  String get availableDevices => 'Qalabka diyaarka ah in lagu xidho';

  @override
  String get availableDevicesHint =>
      'Taabo Raadi — qalabka caafimaadka ee kuu dhow iyo kuwa hore loogu xidhay taleefankan ayaa halkan ka soo muuqanaya. Hiraal ayaa la wareegaysa xidhiidhka Bluetooth marka qalabka lagu xidho taleefanka.';

  @override
  String get scanForDevices => 'Raadi qalabka';

  @override
  String get scanning => 'Waa la raadinayaa...';

  @override
  String get lookingForDevices => 'Qalabka ayaa la raadinayaa...';

  @override
  String get scanDevicesHint =>
      'Taabo Raadi, si aad u hesho qalabkaaga cabbiraadda. Marka hore shid qalabka. Haddii hore loogu xidhay Bluetooth-ka taleefanka, halkan ayuu ka soo muuqandoonaa marka la raadiyo.';

  @override
  String get myDevices => 'Qalabkayga';

  @override
  String get noPairedDevicesYet =>
      'Weli wax qalab ah laguma xidhin. Ku xidh qalab xagga sare si aad u bilowdo.';

  @override
  String get disconnect => 'Ka xidh';

  @override
  String get connectAction => 'Ku xidh';

  @override
  String get turnOnBluetooth => 'Shid Bluetooth-ka';

  @override
  String get removeDeviceQuestion => 'Ma ka saaraysaa qalabka?';

  @override
  String removeDeviceMessage(String name) {
    return 'Ka saar \"$name\" qalabka la xidhay?';
  }

  @override
  String get cancelAction => 'Jooji';

  @override
  String get removeAction => 'Ka saar';

  @override
  String get measureAction => 'Cabbir';

  @override
  String get unknownDevice => 'Qalab aan la aqoon';

  @override
  String get caregiversTitle => 'Daryeelayaasha';

  @override
  String get addCaregiver => 'Ku dar daryeele';

  @override
  String get caregiversInfoBanner =>
      'Ku casuum xubnaha qoyska si ay u arkaan macluumaadka caafimaad ee aad doorato oo ay ku taageeraan daryeelkaaga.';

  @override
  String get myCaregivers => 'Daryeelayaashayda';

  @override
  String get noCaregiversYet => 'Weli daryeele ma jiro';

  @override
  String get caregiversEmptyHint =>
      'Ku dar qof aad ku kalsoon tahay si uu uga caawiyo kormeerka daryeelkaaga.';

  @override
  String get pendingRequests => 'Codsiyada sugaya';

  @override
  String get noPendingRequests => 'Ma jiraan codsiyo sugaya';

  @override
  String get pendingRequestsHint =>
      'Casuumadaha sugaya in la aqbalo ayaa halkan ka muuqan doona.';

  @override
  String get caregiverActive => 'Socda';

  @override
  String get rejectCaregiver => 'Diid';

  @override
  String get acceptCaregiver => 'Aqbal';

  @override
  String get viewReadings => 'Eeg cabbirrada';

  @override
  String get viewMedicines => 'Eeg dawooyinka';

  @override
  String get viewAppointments => 'Eeg ballamaha';

  @override
  String get viewSubscription => 'Eeg xidhmada';

  @override
  String get addCaregiverIntro =>
      'Ku casuum xubin qoyska ama saaxiib WhatsApp. Waxay heli doonaan xiriir casuumad oo ammaan ah.';

  @override
  String get countryCode => 'Koodhka waddanka';

  @override
  String get countryCodeRequired => 'Geli koodhka waddanka';

  @override
  String get whatsappNumber => 'Lambarka WhatsApp';

  @override
  String get whatsappRequired => 'Geli lambarka WhatsApp oo sax ah';

  @override
  String get relationship => 'Xiriirka';

  @override
  String get familyMemberName => 'Magaca xubinta qoyska (ikhtiyaari)';

  @override
  String get familyMemberHint => 'Tusaale: Hooyo Amina';

  @override
  String get permissionsTitle => 'Ogolaanshaha';

  @override
  String get whatsappInviteNote =>
      'Waxaan furi doonnaa WhatsApp si aad si toos ah ugu dirto casuumadda.';

  @override
  String get sendInvitationWhatsapp => 'Dir casuumadda WhatsApp';

  @override
  String get couldNotOpenWhatsapp => 'WhatsApp lama furi karin';

  @override
  String get invitationReady =>
      'Casuumadda waa la sameeyey. WhatsApp waa la furay.';

  @override
  String get relationshipMother => 'Hooyo';

  @override
  String get relationshipFather => 'Aabo';

  @override
  String get relationshipBrother => 'Walaal (lab)';

  @override
  String get relationshipSister => 'Walaal (dhedig)';

  @override
  String get relationshipSpouse => 'Lamaane';

  @override
  String get relationshipChild => 'Ilmaha';

  @override
  String get relationshipFriend => 'Saaxiib';

  @override
  String get relationshipOther => 'Kale';

  @override
  String get revokeCaregiverTitle => 'Ma ka saaraysaa daryeelaha?';

  @override
  String revokeCaregiverMessage(String name) {
    return 'Ka saar $name daryeelayaashaada? Isla markiiba wuu lumin doonaa gelitaanka.';
  }

  @override
  String get revokeCaregiver => 'Ka saar gelitaanka';

  @override
  String get sendInvitationAgain => 'Dib u dir casuumadda';

  @override
  String get savePermissions => 'Kaydi ogolaanshaha';

  @override
  String get caregiversMenu => 'Daryeelayaasha';

  @override
  String get caregiversMenuSubtitle => 'Maamul cidda taageerta daryeelkaaga';

  @override
  String get sponsorCareMenu => 'Maalgelinta daryeelka';

  @override
  String get sponsorCareMenuSubtitle =>
      'Raadi oo maalgeli daryeelka qof aad jeceshahay';

  @override
  String get mySponsorshipMenu => 'Maalgelintayda';

  @override
  String get mySponsorshipMenuSubtitle => 'Eeg bukaannada aad maalgeliso';

  @override
  String get sponsorCareTitle => 'Maalgelinta daryeelka';

  @override
  String get sponsorCareCard => 'Maalgelinta daryeelka';

  @override
  String get sponsorCareCardSubtitle =>
      'Bixi qorshaha daryeelka xubinta qoyska';

  @override
  String get findPatientTab => 'Raadi bukaanka';

  @override
  String get connectByWhatsappTab => 'Ku xidh WhatsApp';

  @override
  String get findPatientTitle => 'Raadi bukaanka aad maalgelin lahayd';

  @override
  String get findPatientHint =>
      'Ku raadi lambarka taleefanka ama lambarka xubinimada, ama isticmaal koodhka casuumadda ee bukaanku ku siiyey.';

  @override
  String get phoneOrMemberId => 'Taleefan ama lambarka xubinimada';

  @override
  String get phoneOrMemberIdHint => 'Tusaale: HCC-2024-000125 ama 612345678';

  @override
  String get findPatientButton => 'Raadi bukaanka';

  @override
  String get redeemInvitationCodeTitle => 'Ama isticmaal koodhka casuumadda';

  @override
  String get invitationCode => 'Koodhka casuumadda';

  @override
  String get invitationCodeHint => 'Geli koodhka laguu soo diray';

  @override
  String get redeemCodeButton => 'Isticmaal koodhka';

  @override
  String get noPatientsFound => 'Bukaan lama helin';

  @override
  String get noPatientsFoundHint =>
      'Isku day lambarka taleefanka, lambarka xubinimada, ama koodhka casuumadda.';

  @override
  String get connectByWhatsappTitle => 'Raadi qof aad jeceshahay WhatsApp';

  @override
  String get connectByWhatsappHint =>
      'U dir codsiga xidhiidhka qof hore u isticmaala Hiraal. Marka uu aqbalo, waxaad maalgelin kartaa daryeelkiisa.';

  @override
  String get sendConnectionRequest => 'Dir codsiga xidhiidhka';

  @override
  String get enterSearchTerm =>
      'Geli lambarka taleefanka ama lambarka xubinimada';

  @override
  String get enterInvitationCode => 'Geli koodhka casuumadda';

  @override
  String get sponsorPatientTitle => 'Maalgeli bukaanka';

  @override
  String get chooseMonthlyPlan => 'Dooro qorshaha billaha ah';

  @override
  String get noPlansAvailable => 'Ma jiraan qorshe xidhmadeed hadda.';

  @override
  String get sponsorThisPatient => 'Maalgeli bukaankan';

  @override
  String get confirmSponsorshipTitle => 'Xaqiiji maalgelinta';

  @override
  String get memberIdLabel => 'Lambarka xubinimada';

  @override
  String get planLabel => 'Qorshaha';

  @override
  String get monthlyCostLabel => 'Qiimaha billaha ah';

  @override
  String get payAndStartSponsorship => 'Bixi oo bilow maalgelinta';

  @override
  String get sponsorPaymentTitle => 'Lacag-bixinta maalgelinta';

  @override
  String get startingPayment => 'Lacag-bixinta ayaa bilaabmaysa…';

  @override
  String get startingSponsorPaymentHint =>
      'Fadlan sug inta aan codsiga lacagta moobilka u dirayno.';

  @override
  String get sponsorshipPaymentFailed =>
      'Lacag-bixinta maalgelinta waa la diiday ama waa la joojiyey.';

  @override
  String get paymentStillProcessing =>
      'Way qaadanaysaa waqti ka badan caadiga. Haddii aad ogolaatay codsiga, lacag-bixintu si toos ah ayay u xaqiijin doontaa.';

  @override
  String get sponsorshipActiveTitle => 'Maalgelintu waa socotaa';

  @override
  String sponsorshipActiveHint(String name) {
    return 'Hadda waxaad maalgelinaysaa qorshaha daryeelka $name. Mahadsanid!';
  }

  @override
  String get paymentFailedTitle => 'Lacag-bixintu way fashilantay';

  @override
  String get tryAgain => 'Isku day mar kale';

  @override
  String get doneLabel => 'Dhammaad';

  @override
  String get mySponsorshipTitle => 'Maalgelintayda';

  @override
  String get noSponsorshipsYet => 'Weli maalgelin ma jirto';

  @override
  String get noSponsorshipsHint =>
      'Markaad maalgeliso daryeelka qof, halkan ayuu ka muuqan doonaa.';

  @override
  String get activeSponsorships => 'Maalgelinta socota';

  @override
  String get nextPaymentLabel => 'Lacag-bixinta xigta';

  @override
  String get latestUpdates => 'Wararkii ugu dambeeyay';

  @override
  String get patientSnapshot => 'Soo koobidda bukaanka';

  @override
  String get connectionRequestTitle => 'Codsiga xidhiidhka';

  @override
  String get connectionSentHeadline => 'Codsiga waa la diray';

  @override
  String connectionSentBody(String number) {
    return 'Waxaan u dirnay codsiga xidhiidhka $number. Waan ku ogeysiin doonnaa marka uu aqbalo.';
  }

  @override
  String get connectionActiveTitle => 'Waa la xidhay';

  @override
  String get connectionActiveHeadline => 'Waad isku xidhan tihiin';

  @override
  String connectionActiveBody(String name) {
    return 'Xidhiidhkaaga $name waa socdaa. Hadda waxaad maalgelin kartaa daryeelkiisa.';
  }
}
