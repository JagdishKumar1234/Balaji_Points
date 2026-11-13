// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'பலாஜி பாயிண்ட்ஸ்';

  @override
  String get loading => 'லோடிங்...';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get ok => 'சரி';

  @override
  String get cancel => 'ரத்து';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get delete => 'அழிக்கவும்';

  @override
  String get edit => 'திருத்து';

  @override
  String get submit => 'சமர்ப்பிக்கவும்';

  @override
  String get back => 'பின் செல்ல';

  @override
  String get next => 'அடுத்தது';

  @override
  String get done => 'முடிந்தது';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get refresh => 'ரிஃப்ரெஷ்';

  @override
  String get loginWithPhone => 'கைபேசி எண்கொண்டு உள்நுளையவும்';

  @override
  String get enterPhoneNumber => 'பதிவு செய்யப்பட்ட கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get phoneNumber => 'கைபேசி எண்';

  @override
  String get enterPhoneHint => '10 இலக்க கைபேசி எண்';

  @override
  String get sendOTP => 'OTP அனுப்பவும்';

  @override
  String get verifyOTP => 'OTP சரிபார்க்கவும்';

  @override
  String get enterOTPCode => 'அனுப்பப்பட்ட 6 இலக்க OTP ஐ உள்ளிடவும்';

  @override
  String get didntReceiveOTP => 'OTP வரலையா? ';

  @override
  String get resend => 'மீண்டும் அனுப்பவும்';

  @override
  String resendIn(int seconds) {
    return '$seconds விநாடிகளில் மீண்டும்';
  }

  @override
  String get invalidPhone => 'கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get invalidPhoneLength => 'கைபேசி எண் 10 இலக்கமாக இருக்க வேண்டும்';

  @override
  String get invalidPhoneFormat =>
      'கைபேசி எண் இலக்கங்கள் மட்டுமே இருக்க வேண்டும்';

  @override
  String get invalidOTP => 'செல்லுபடியாகாத OTP';

  @override
  String get selectRole => 'உங்கள் பாத்திரத்தை தேர்வுசெய்க';

  @override
  String get carpenter => 'தச்சர்';

  @override
  String get admin => 'நிர்வாகி';

  @override
  String get welcomeBack => 'மீண்டும் வரவேற்கிறோம்';

  @override
  String get createAccount => 'கணக்கு உருவாக்கு';

  @override
  String get continueWithPhone => 'கைபேசியுடன் தொடரவும்';

  @override
  String get continueWithPin => 'PIN உடன் தொடரவும்';

  @override
  String get loginInfo =>
      'உங்கள் பதிவு செய்யப்பட்ட கைபேசி எண்ணை பயன்படுத்தி உள்நுழைக. OTP அனுப்பப்படும்.';

  @override
  String get poweredBy => 'இனால் இயக்கப்படுகிறது';

  @override
  String get companyName => 'பலாஜி பாயிண்ட்ஸ்';

  @override
  String get enterPinPageTitle => '4 இலக்க PIN ஐ உள்ளிடவும்';

  @override
  String get enter4DigitPin => '4 இலக்க PIN ஐ உள்ளிடவும்';

  @override
  String get pinLabel => 'பின்';

  @override
  String get fourDigitPin => '4 இலக்க PIN';

  @override
  String get login => 'உள்நுளை';

  @override
  String get forgotPin => 'PIN மறந்துவிட்டதா?';

  @override
  String get newUserSetPin => 'புதிய பயனரா? PIN அமைக்கவும்';

  @override
  String get invalidPin => 'தவறான PIN';

  @override
  String get createPinTitle => '4 இலக்க PIN உருவாக்கவும்';

  @override
  String get createPinSubtitle => 'இந்த PIN உள்நுழைவுக்காக பயன்படுத்தப்படும்';

  @override
  String get mobileNumber => 'கைபேசி எண்';

  @override
  String get firstName => 'முதல் பெயர்';

  @override
  String get firstNameRequired => 'முதல் பெயர் *';

  @override
  String get lastName => 'கடைசி பெயர்';

  @override
  String get confirmPin => 'PIN உறுதிப்படுத்தவும்';

  @override
  String get savePin => 'PIN சேமிக்கவும்';

  @override
  String get pinCreatedSuccess => 'PIN வெற்றிகரமாக உருவாக்கப்பட்டது';

  @override
  String get failedToSavePin => 'PIN சேமிக்கத் தவறிவிட்டது';

  @override
  String get pinsDoNotMatch => 'PIN மற்றும் உறுதிப்படுத்தல் PIN பொருந்தவில்லை';

  @override
  String get resetPinTitle => 'PIN மீட்டமைக்கவும்';

  @override
  String get resetPinSubtitle =>
      'PIN மீட்டமைக்க பதிவு செய்யப்பட்ட கைபேசி எண்ணை உள்ளிடவும்.';

  @override
  String get mustBeLoggedInToResetPin =>
      'உங்கள் PIN ஐ மீட்டமைக்க நீங்கள் உள்நுழைய வேண்டும். முதலில் உள்நுழையவும்.';

  @override
  String get canOnlyResetOwnPin =>
      'நீங்கள் உங்கள் சொந்த PIN ஐ மட்டுமே மீட்டமைக்க முடியும். தொலைபேசி எண் உங்கள் உள்நுழைந்த கணக்குடன் பொருந்த வேண்டும்.';

  @override
  String get enterCurrentPin =>
      'உரிமையை சரிபார்க்க உங்கள் தற்போதைய PIN ஐ உள்ளிடவும்.';

  @override
  String get currentPinLabel => 'தற்போதைய PIN';

  @override
  String get newPinMustBeDifferent =>
      'புதிய PIN உங்கள் தற்போதைய PIN இலிருந்து வேறுபட்டதாக இருக்க வேண்டும்.';

  @override
  String get contactAdminForPinReset =>
      'உங்கள் PIN ஐ மீட்டமைக்க நீங்கள் உள்நுழைய வேண்டும். உங்கள் PIN ஐ மறந்துவிட்டால், உதவிக்காக நிர்வாகியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get forgotCurrentPin => 'உங்கள் தற்போதைய PIN ஐ மறந்துவிட்டீர்களா?';

  @override
  String get forgotPinHelp =>
      'உங்கள் தற்போதைய PIN ஐ நீங்கள் நினைவில் இல்லையென்றால், உதவிக்காக எங்கள் ஆதரவு குழுவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get adminSupportInfo => 'நிர்வாகி ஆதரவு';

  @override
  String get callSupport => 'ஆதரவை அழைக்கவும்';

  @override
  String get adminResetPin => 'PIN மீட்டமைக்கவும்';

  @override
  String adminResetPinTitle(String carpenterName) {
    return '$carpenterName க்கான PIN மீட்டமைக்கவும்';
  }

  @override
  String get adminResetPinSubtitle =>
      'இந்த தச்சருக்கு புதிய 4 இலக்க PIN ஐ உள்ளிடவும்.';

  @override
  String adminResetPinConfirm(String carpenterName) {
    return 'நீங்கள் $carpenterName க்கான PIN ஐ மீட்டமைக்க விரும்புகிறீர்களா?';
  }

  @override
  String adminResetPinSuccess(String carpenterName) {
    return '$carpenterName க்கான PIN வெற்றிகரமாக மீட்டமைக்கப்பட்டது';
  }

  @override
  String get adminResetPinFailed =>
      'PIN மீட்டமைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get adminNotAuthorized =>
      'இந்த செயலைச் செய்ய உங்களுக்கு அனுமதி இல்லை.';

  @override
  String get enterNewPinForCarpenter => 'புதிய 4 இலக்க PIN ஐ உள்ளிடவும்';

  @override
  String get confirmNewPinForCarpenter =>
      'புதிய 4 இலக்க PIN ஐ உறுதிப்படுத்தவும்';

  @override
  String get newPinLabel => 'புதிய 4 இலக்க PIN';

  @override
  String get checkNumber => 'எண் சரிபார்க்கவும்';

  @override
  String get verified => 'சரிபார்க்கப்பட்டது';

  @override
  String get pleaseVerifyMobile => 'முதலில் கைபேசி எண்ணை சரிபார்க்கவும்';

  @override
  String get noAccountFound => 'இந்த எண்ணுக்கான கணக்கு இல்லை';

  @override
  String get pinResetSuccess =>
      'PIN வெற்றிகரமாக மீட்டமைக்கப்பட்டது. மீண்டும் உள்நுழையவும்.';

  @override
  String get failedToResetPin =>
      'PIN மீட்டமைக்கத் தவறிவிட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get enterValidTenDigit => 'செல்லுபடியான 10 இலக்க எண்ணை உள்ளிடவும்';

  @override
  String get enter4Digits => '4 இலக்கங்களை உள்ளிடவும்';

  @override
  String get pinMismatch => 'PIN கள் பொருந்தவில்லை';

  @override
  String get enterValidFirstName => 'செல்லுபடியான முதல் பெயரை உள்ளிடவும்';

  @override
  String get imageError => 'படப் பிழை';

  @override
  String get resetPin => 'PIN மீட்டமைக்கவும்';

  @override
  String get changePin => 'PIN மாற்றவும்';

  @override
  String get rememberMe => 'என்னை நினைவில் வைக்கவும்';

  @override
  String get accountExistsUseReset =>
      'கணக்கு ஏற்கனவே உள்ளது. உங்கள் PIN ஐ மாற்ற Reset PIN ஐ பயன்படுத்தவும்.';

  @override
  String get home => 'முகப்பு';

  @override
  String get addPoints => 'பாயிண்ட்ஸ் சேர்க்கவும்';

  @override
  String get latestOffers => 'சமீபத்திய ஆஃபர்கள்';

  @override
  String get goodMorningGreeting => 'காலை வணக்கம்,';

  @override
  String get goodAfternoonGreeting => 'மதிய வணக்கம்,';

  @override
  String get goodEveningGreeting => 'மாலை வணக்கம்,';

  @override
  String get homeBrowseProductsTitle => 'மரம் & பிளைவுட்';

  @override
  String get homeBrowseProductsSubtitle =>
      'பிரீமியம் லேமினேட் மற்றும் மேற்பரப்புகள்';

  @override
  String get viewAll => 'அனைத்தும்';

  @override
  String get homeStoreBranch => 'ஈ ரோடு';

  @override
  String get homeTierSuffix => 'நிலை';

  @override
  String get homeRankingsSectionTitle => 'தரவரிசை & இன்றைய வெற்றியாளர்';

  @override
  String get homeRankingsSectionSubtitle =>
      'லீடர்போர்டு, உங்கள் தரம், இன்றைய பரிசு';

  @override
  String get drawerProductsTitle => 'தயாரிப்புகள்';

  @override
  String get drawerProductsSubtitle => 'வகைகள் & கேட்டலாக்';

  @override
  String get drawerCart => 'கார்ட்';

  @override
  String get drawerSectionMainNav => 'முக்கிய வழிசெலுத்தல்';

  @override
  String get drawerSectionMore => 'மேலும்';

  @override
  String get myOrders => 'எனது ஆர்டர்கள்';

  @override
  String get profileSectionAccount => 'கணக்கு';

  @override
  String get profileSectionPreferences => 'விருப்பங்கள்';

  @override
  String get profileSectionSupport => 'ஆதரவு';

  @override
  String get profileAboutLink => 'ஆப்பைப் பற்றி';

  @override
  String get routeErrorTitle => 'பக்கம் கிடைக்கவில்லை';

  @override
  String get routeErrorNotFound =>
      'இந்த இணைப்பு தவறானது அல்லது பக்கம் நீக்கப்பட்டது.';

  @override
  String get routeErrorGoHome => 'முகப்புக்குச் செல்';

  @override
  String get routeErrorDetailsLabel => 'தொழில்நுட்ப விவரங்கள்';

  @override
  String get topCarpenters => 'சிறந்த 3 உறுப்பினர்கள்';

  @override
  String get todaysWinner => 'இன்றைய வெற்றியாளர்';

  @override
  String get yourPosition => 'உங்கள் நிலை';

  @override
  String rank(int rank) {
    return 'தரவரிசை #$rank';
  }

  @override
  String points(int points) {
    return '$points பாயிண்ட்ஸ்';
  }

  @override
  String get noOffersAvailable => 'தற்போது எந்த ஆஃபர்களும் இல்லை';

  @override
  String get dailySpinWinner => '🎉 தினசரி ஸ்பின் வெற்றியாளர்';

  @override
  String get congratulations => 'வாழ்த்துக்கள்!';

  @override
  String won(int points) {
    return '$points பாயிண்ட்ஸ் வென்றுள்ளீர்கள்!';
  }

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get editProfile => 'சுயவிவரம் திருத்து';

  @override
  String get completeProfile => 'சுயவிவரத்தை நிறைவு செய்யவும்';

  @override
  String get profileIncomplete => 'சுயவிவரம் முழுமையில்லை';

  @override
  String get completeProfileMessage =>
      'பில்ல்களைச் சேர்த்து பாயிண்ட்ஸ் பெற உங்கள் சுயவிவரத்தை நிறைவு செய்யவும்';

  @override
  String get completeProfileDetails =>
      'முதல் பெயர், கடைசி பெயர் மற்றும் புகைப்படத்தைச் சேர்க்கவும்';

  @override
  String get completeNow => 'இப்போதே நிறைவு செய்';

  @override
  String get helpSupport => 'உதவி & ஆதரவு';

  @override
  String get contactUs => 'எங்களை தொடர்பு கொள்ள';

  @override
  String get darkMode => 'டார்க் மோட்';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get logoutConfirmation => 'நீங்கள் வெளியேற விரும்புகிறீர்களா?';

  @override
  String get name => 'பெயர்';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get phone => 'கைபேசி';

  @override
  String get role => 'பாத்திரம்';

  @override
  String get memberSince => 'உறுப்பினர் ஆன தேதி';

  @override
  String get totalPoints => 'மொத்த பாயிண்ட்ஸ்';

  @override
  String get notVerified => 'சரிபார்க்கப்படவில்லை';

  @override
  String get needHelp => 'உதவி வேண்டுமா?';

  @override
  String get contactSupport => 'எங்கள் ஆதரவு குழுவை தொடர்பு கொள்ளவும்.';

  @override
  String get callNow => 'இப்போது அழைக்கவும்';

  @override
  String get getInTouch => 'எங்களை தொடர்பு கொள்ளவும்';

  @override
  String get mobile => 'மொபைல்';

  @override
  String get landline => 'லேண்ட்லைன்';

  @override
  String get addBill => 'பில் சேர்க்கவும்';

  @override
  String get billDetails => 'பில் விவரங்கள்';

  @override
  String get billNumber => 'பில் எண்';

  @override
  String get billAmount => 'பில் தொகை';

  @override
  String get billDate => 'பில் தேதி';

  @override
  String get uploadBillImage => 'பில் படத்தை பதிவேற்றவும்';

  @override
  String get selectImage => 'படத்தைத் தேர்வு செய்';

  @override
  String get changeImage => 'படத்தை மாற்று';

  @override
  String get pointsConversion => '₹1000 = 1 பாயிண்ட்';

  @override
  String get estimatedPoints => 'மதிப்பிடப்பட்ட பாயிண்ட்ஸ்';

  @override
  String youWillEarn(int points) {
    return 'நீங்கள் கணக்கில் $points பாயிண்ட்ஸ் பெறுவீர்கள்';
  }

  @override
  String get enterBillNumber => 'பில் எண்ணை உள்ளிடவும்';

  @override
  String get enterBillAmount => 'பில் தொகையை உள்ளிடவும்';

  @override
  String get enterValidAmount => 'சரியான தொகையை உள்ளிடவும்';

  @override
  String get selectBillDate => 'பில் தேதியைத் தேர்வு செய்யவும்';

  @override
  String get uploadBillPhoto => 'பில் புகைப்படத்தை பதிவேற்றவும்';

  @override
  String get billSubmitted => 'பில் வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது';

  @override
  String get billSubmitError => 'பில் சமர்ப்பிப்பு தோல்வியடைந்தது';

  @override
  String get wallet => 'வாலெட்';

  @override
  String get availablePoints => 'கிடைக்கும் பாயிண்ட்ஸ்';

  @override
  String get redeemPoints => 'பாயிண்ட்ஸ் ரீடீம்';

  @override
  String get transactionHistory => 'பரிவர்த்தனை வரலாறு';

  @override
  String get earned => 'பெற்றது';

  @override
  String get spent => 'செலவிட்டது';

  @override
  String get pending => 'நிலுவையில்';

  @override
  String get offers => 'ஆஃபர்கள்';

  @override
  String get viewDetails => 'விவரங்களைப் பார்க்க';

  @override
  String get redeemNow => 'இப்போதே ரீடீம் செய்யவும்';

  @override
  String pointsRequired(int points) {
    return '$points பாயிண்ட்ஸ் தேவை';
  }

  @override
  String get offerRedeemed => 'ஆஃபர் வெற்றிகரமாக ரீடீம் செய்யப்பட்டது';

  @override
  String get insufficientPoints => 'பாயிண்ட்ஸ் போதவில்லை';

  @override
  String get offerExpired => 'இந்த ஆஃபர் காலாவதியானது';

  @override
  String validUntil(String date) {
    return 'செல்லுபடியாகும் தேதி: $date';
  }

  @override
  String get dailySpin => 'டெய்லி ஸ்பின்';

  @override
  String get spinNow => 'இப்போதே ஸ்பின் செய்';

  @override
  String get spinning => 'ஸ்பின் நடக்கிறது...';

  @override
  String get spinWheel => 'சக்கரத்தை ஸ்பின் செய்';

  @override
  String get dailySpinCompleted =>
      'நீங்கள் இன்று ஏற்கனவே ஸ்பின் செய்துவிட்டீர்கள்';

  @override
  String get comeBackTomorrow => 'நாளை மீண்டும் முயற்சிக்கவும்!';

  @override
  String nextSpinIn(int hours, int minutes) {
    return 'அடுத்த ஸ்பின்: $hoursமணி $minutesநிமி';
  }

  @override
  String winner(String name) {
    return 'வெற்றியாளர்: $name';
  }

  @override
  String prizePoints(int points) {
    return '🎁 $points பாயிண்ட்ஸ்';
  }

  @override
  String get adminPanel => 'அட்மின் பேனல்';

  @override
  String get adminSubtitle =>
      'பில்கள், ஆஃபர்கள், பயனர்கள் & டெய்லி ஸ்பின் மேலாண்மை';

  @override
  String get dashboard => 'டாஷ்போர்ட்';

  @override
  String get users => 'பயனர்கள்';

  @override
  String get manageUsers => 'பயனர்களை மேலாண்மை செய்';

  @override
  String get manageBills => 'பில்களை மேலாண்மை செய்';

  @override
  String get manageOffers => 'ஆஃபர்களை மேலாண்மை செய்';

  @override
  String get manageDailySpin => 'டெய்லி ஸ்பின் மேலாண்மை';

  @override
  String get pendingBills => 'நிலுவை பில்கள்';

  @override
  String get approvedBills => 'ஒப்புதல் அளிக்கப்பட்ட பில்கள்';

  @override
  String get rejectedBills => 'நிராகரிக்கப்பட்ட பில்கள்';

  @override
  String get pendingUsers => 'நிலுவை பயனர்கள்';

  @override
  String get verifiedUsers => 'சரிபார்க்கப்பட்ட பயனர்கள்';

  @override
  String get approve => 'ஒப்புதல்';

  @override
  String get reject => 'நிராகரி';

  @override
  String get userApproved => 'பயனர் வெற்றிகரமாக ஒப்புதல் பெற்றார்';

  @override
  String get userRejected => 'பயனர் நிராகரிக்கப்பட்டார்';

  @override
  String get billApproved => 'பில் வெற்றிகரமாக ஒப்புதல் பெற்றது';

  @override
  String get billRejected => 'பில் நிராகரிக்கப்பட்டது';

  @override
  String get createOffer => 'ஆஃபர் உருவாக்கு';

  @override
  String get offerTitle => 'ஆஃபர் தலைப்பு';

  @override
  String get offerDescription => 'ஆஃபர் விளக்கம்';

  @override
  String get offerCreated => 'ஆஃபர் வெற்றிகரமாக உருவாக்கப்பட்டது';

  @override
  String get logoutFailed => 'வெளியேற முடியவில்லை';

  @override
  String get errorOccurred => 'பிழை ஏற்பட்டது';

  @override
  String get networkError => 'இணைய பிழை. உங்கள் இணைப்பை சரிபார்க்கவும்.';

  @override
  String get permissionDenied => 'அனுமதி மறுக்கப்பட்டது';

  @override
  String get sessionExpired => 'செஷன் காலாவதியானது. மீண்டும் உள்நுழைக.';

  @override
  String get invalidCredentials => 'செல்லுபடியாகாத தகவல்கள்';

  @override
  String get userNotFound => 'பயனர் கிடைக்கவில்லை';

  @override
  String get phoneAuthFailed => 'கைபேசி சரிபார்ப்பு தோல்வியடைந்தது';

  @override
  String get configError => 'கட்டமைப்பு பிழை';

  @override
  String get missingClientId =>
      'Firebase-ல் SHA-1 இல்லை. scripts/get_sha1.sh ஐ இயக்கவும்.';

  @override
  String get tooManyRequests =>
      'அதிகமான கோரிக்கைகள். சில நிமிடங்கள் காத்திருங்கள்.';

  @override
  String get invalidVerificationCode => 'செல்லுபடியாகாத OTP';

  @override
  String get verificationExpired => 'OTP காலாவதியானது';

  @override
  String get userDisabled => 'இந்த கணக்கு முடக்கப்பட்டுள்ளது';

  @override
  String get fieldRequired => 'இந்த புலம் அவசியம்';

  @override
  String get invalidEmail => 'செல்லுபடியாகாத மின்னஞ்சல்';

  @override
  String get invalidName => 'செல்லுபடியாகாத பெயர்';

  @override
  String get nameTooShort => 'பெயர் குறைந்தது 2 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get invalidAmount => 'செல்லுபடியாகாத தொகை';

  @override
  String get amountTooLow => 'தொகை 0-ஐ விட அதிகமாக இருக்க வேண்டும்';

  @override
  String get searchHint => 'தேடுக...';

  @override
  String get noResultsFound => 'முடிவுகள் இல்லை';

  @override
  String get noDataAvailable => 'தரவுகள் இல்லை';

  @override
  String get pullToRefresh => 'ரீஃபிரெஷ் செய்ய இழுக்கவும்';

  @override
  String get releaseToRefresh => 'ரீஃபிரெஷ் செய்ய விடவும்';

  @override
  String get refreshing => 'ரீஃபிரெஷ் செய்கிறது...';

  @override
  String get loadMore => 'மேலும் ஏற்றவும்';

  @override
  String get seeAll => 'அனைத்தையும் காண்க';

  @override
  String get close => 'மூடு';

  @override
  String get confirm => 'உறுதி செய்';

  @override
  String get areYouSure => 'உறுதியாக உள்ளீர்களா?';

  @override
  String get cannotUndo => 'இந்த செயலை ரத்து செய்ய முடியாது.';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get today => 'இன்று';

  @override
  String get yesterday => 'நேற்று';

  @override
  String get tomorrow => 'நாளை';

  @override
  String get january => 'ஜனவரி';

  @override
  String get february => 'பிப்ரவரி';

  @override
  String get march => 'மார்ச்';

  @override
  String get april => 'ஏப்ரல்';

  @override
  String get may => 'மே';

  @override
  String get june => 'ஜூன்';

  @override
  String get july => 'ஜூலை';

  @override
  String get august => 'ஆகஸ்ட்';

  @override
  String get september => 'செப்டம்பர்';

  @override
  String get october => 'அக்டோபர்';

  @override
  String get november => 'நவம்பர்';

  @override
  String get december => 'டிசம்பர்';

  @override
  String get jan => 'ஜன்';

  @override
  String get feb => 'பிப்';

  @override
  String get mar => 'மார்';

  @override
  String get apr => 'ஏப்';

  @override
  String get jun => 'ஜூன்';

  @override
  String get jul => 'ஜூலை';

  @override
  String get aug => 'ஆக';

  @override
  String get sep => 'செப்';

  @override
  String get oct => 'அக்';

  @override
  String get nov => 'நவ';

  @override
  String get dec => 'டிச';

  @override
  String get approveBill => 'பிலை ஒப்புதல் அளி';

  @override
  String approveBillConfirmation(String amount, String phone) {
    return '$phone க்கான ₹$amount பிலை ஒப்புதல் அளிக்கவா?';
  }

  @override
  String get approvingBill => 'பிலை ஒப்புதல் அளிக்கிறது...';

  @override
  String get billApprovedSuccess => 'பில் ஒப்புதல் பெற்றது!';

  @override
  String get failedToApproveBill =>
      'பிலை ஒப்புதல் செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get rejectBill => 'பிலை நிராகரி';

  @override
  String get rejectBillConfirmation =>
      'இந்த பிலை நிராகரிக்க விரும்புகிறீர்களா?';

  @override
  String get billRejectedSuccess => 'பில் நிராகரிக்கப்பட்டது';

  @override
  String get failedToRejectBill => 'பிலை நிராகரிக்க முடியவில்லை';

  @override
  String get failedToLoadImage => 'படத்தை ஏற்ற முடியவில்லை';

  @override
  String get noImageAvailable => 'படம் இல்லை';

  @override
  String get errorLoadingBills => 'பில்களை ஏற்றும்போது பிழை';

  @override
  String get noPendingBills => 'நிலுவை பில்கள் இல்லை';

  @override
  String get pendingStatus => 'நிலுவை';

  @override
  String get noDate => 'தேதி இல்லை';

  @override
  String get deleteOffer => 'ஆஃபரை நீக்கு';

  @override
  String get deleteOfferConfirmation =>
      'இந்த ஆஃபரை நீக்க விரும்புகிறீர்களா? மீட்டெடுக்க முடியாது.';

  @override
  String get offerDeletedSuccess => 'ஆஃபர் வெற்றிகரமாக நீக்கப்பட்டது';

  @override
  String get failedToDeleteOffer => 'ஆஃபரை நீக்க முடியவில்லை';

  @override
  String get errorLoadingOffers => 'ஆஃபர்களை ஏற்றும்போது பிழை';

  @override
  String get noOffersCreated => 'ஆஃபர்கள் உருவாக்கப்படவில்லை';

  @override
  String get createFirstOffer =>
      'உங்கள் முதல் ஆஃபரை பாயிண்ட்ஸ் மற்றும் பேனர் உடன் உருவாக்கவும்';

  @override
  String get active => 'செயலில்';

  @override
  String get inactive => 'செயலற்றது';

  @override
  String get createdLabel => 'உருவாக்கப்பட்டது';

  @override
  String get editOffer => 'ஆஃபரை திருத்து';

  @override
  String get createNewOffer => 'புதிய ஆஃபர் உருவாக்கு';

  @override
  String get tapToUploadBanner => 'பேனரை பதிவேற்ற தட்டவும்';

  @override
  String get offerTitleLabel => 'ஆஃபர் தலைப்பு *';

  @override
  String get offerTitleHint => 'சலுகை தலைப்பு உள்ளிடவும்';

  @override
  String get enterOfferTitle => 'ஆஃபர் தலைப்பை உள்ளிடவும்';

  @override
  String get descriptionLabel => 'விளக்கம்';

  @override
  String get descriptionHint => 'விளக்கம் உள்ளிடவும்';

  @override
  String get pointsRequiredLabel => 'தேவையான பாயிண்ட்ஸ் *';

  @override
  String get pointsHint => 'புள்ளிகளை உள்ளிடவும்';

  @override
  String get enterPointsError => 'பாயிண்ட்ஸை உள்ளிடவும்';

  @override
  String get enterValidNumber => 'செல்லுபடியாகாத எண்';

  @override
  String get setValidUntilDate => 'Valid until தேதியை அமைக்கவும் (விருப்பம்)';

  @override
  String validUntilDisplay(String date) {
    return 'செல்லுபடியாகும் தேதி: $date';
  }

  @override
  String get offerStatus => 'ஆஃபர் நிலை';

  @override
  String get uploadingBanner => 'பேனர் பதிவேற்றுகிறது...';

  @override
  String get updateOffer => 'ஆஃபரை புதுப்பிக்கவும்';

  @override
  String get offerUpdatedSuccess => 'ஆஃபர் வெற்றிகரமாக புதுப்பிக்கப்பட்டது';

  @override
  String get offerCreatedSuccess => 'ஆஃபர் வெற்றிகரமாக உருவாக்கப்பட்டது';

  @override
  String get failedToSaveOffer => 'ஆஃபரை சேமிக்க முடியவில்லை';

  @override
  String get failedToPickImage => 'படத்தைத் தேர்வு செய்ய இயலவில்லை';

  @override
  String get searchByNameOrPhone => 'பெயர் அல்லது போன் தேடு';

  @override
  String get add => 'சேர்க்கவும்';

  @override
  String get all => 'அனைத்தும்';

  @override
  String get platinum => 'பிளாட்டினம்';

  @override
  String get gold => 'கோல்டு';

  @override
  String get silver => 'சில்வர்';

  @override
  String get bronze => 'ப்ரான்ஸ்';

  @override
  String get errorLoadingUsers => 'பயனர்களை ஏற்றும்போது பிழை';

  @override
  String get noUsersFound => 'பயனர்கள் கிடைக்கவில்லை';

  @override
  String get tryDifferentSearch => 'வேறு தேடல் சொற்களை முயற்சிக்கவும்';

  @override
  String get noCarpentersYet => 'தச்சர்கள் இன்னும் பதிவு செய்யவில்லை';

  @override
  String joinedLabel(String date) {
    return '$date அன்று சேர்ந்தார்';
  }

  @override
  String get addCarpenter => 'தச்சரை சேர்க்கவும்';

  @override
  String get deleteCarpenter => 'தச்சரை நீக்கவும்';

  @override
  String get deleteCarpenterConfirmation =>
      'இந்த தச்சரை நீக்க விரும்புகிறீர்களா? இது நிரந்தரமாக நீக்கும்:\n\n• பயனர் கணக்கு\n• அனைத்து பாயிண்ட்ஸ் மற்றும் பரிவர்த்தனை வரலாறு\n• அனைத்து சமர்ப்பிக்கப்பட்ட பில்கள்\n• அனைத்து ஆஃபர் ரீடீம்கள்\n\nஇந்த செயலை ரத்து செய்ய முடியாது.';

  @override
  String get deleteCarpenterWarning =>
      'தச்சரை நீக்குவது அவர்களின் அனைத்து தரவையும் கணினியிலிருந்து நிரந்தரமாக அகற்றும். இந்த செயலை ரத்து செய்ய முடியாது.';

  @override
  String get carpenterDeletedSuccess => 'தச்சர் வெற்றிகரமாக நீக்கப்பட்டார்';

  @override
  String get failedToDeleteCarpenter => 'தச்சரை நீக்க முடியவில்லை';

  @override
  String get dangerZone => 'ஆபத்து மண்டலம்';

  @override
  String get phoneNumberLabel => 'கைபேசி எண்';

  @override
  String get phoneNumberHint => 'போன் எண்ணை உள்ளிடவும்';

  @override
  String get enterOTP => 'OTP உள்ளிடவும்';

  @override
  String get verifyAndCreate => 'சரிபார்த்து உருவாக்கவும்';

  @override
  String get adminSignOutNote =>
      'குறிப்பு: OTP சரிபார்ப்பின் போது தற்காலிகமாக தச்சர் கணக்காக உள்நுழையும். பின்னர் மீண்டும் வெளியேறும். நிர்வாகி மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get carpenterCreated => 'தச்சர் உருவாக்கப்பட்டார்';

  @override
  String get carpenterCreatedMessage =>
      'தச்சர் கணக்கு வெற்றிகரமாக உருவாக்கப்பட்டது. தற்காலிகமாக உள்நுழைந்து பின்னர் வெளியேறப்பட்டது. நிர்வாகி மீண்டும் உள்நுழைய வேண்டும்.';

  @override
  String get enterValidPhone => 'செல்லுபடியாகும் கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get phoneAlreadyExists => 'கைபேசி எண் ஏற்கனவே உள்ளது';

  @override
  String get verificationFailed => 'சரிபார்ப்பு தோல்வியடைந்தது';

  @override
  String get otpSent => 'OTP அனுப்பப்பட்டது';

  @override
  String get failedToSignIn => 'OTP உள்நுழைவு தோல்வியடைந்தது';

  @override
  String get authError => 'அங்கீகார பிழை';

  @override
  String get totalPointsLabel => 'மொத்த பாயிண்ட்ஸ்';

  @override
  String tierLabel(String tier) {
    return '$tier நிலை';
  }

  @override
  String get recentActivity => 'சமீபத்திய செயல்கள்';

  @override
  String get noActivityYet => 'ஏதும் செயல்கள் இல்லை';

  @override
  String get noWinnerYetToday => 'இன்று இன்னும் வெற்றியாளர் இல்லை';

  @override
  String get youWonPrize => '🎉 நீங்கள் வென்றுள்ளீர்கள்!';

  @override
  String get todaysWinnerLabel => '🏆 இன்றைய வெற்றியாளர்';

  @override
  String get myPoints => 'என் பாயிண்ட்ஸ்';

  @override
  String get leaderboard => 'தரவரிசை பட்டியல்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get rankShort => 'ரேங்க்';

  @override
  String get earn => 'வாலட்';

  @override
  String get approved => 'ஒப்புதல்';

  @override
  String get addNewBill => 'புதிய பில் சேர்க்கவும்';

  @override
  String get recentBills => 'சமீபத்திய பில்கள்';

  @override
  String get noBillsYet => 'இன்னும் பில்கள் இல்லை';

  @override
  String get submitFirstBill =>
      'பாயிண்ட்ஸ் பெற உங்கள் முதல் பிலை சமர்ப்பிக்கவும்';

  @override
  String get justNow => 'இப்பொழுது';

  @override
  String minutesAgo(int minutes) {
    return '$minutes நிமி முன்பு';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count மணி நேரம் முன்',
      one: '1 மணி நேரம் முன்',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நாட்கள் முன்',
      one: '1 நாள் முன்',
    );
    return '$_temp0';
  }

  @override
  String get billLabel => 'பில்';

  @override
  String get statusApproved => 'ஒப்புதல்';

  @override
  String get statusPending => 'நிலுவை';

  @override
  String get statusRejected => 'நிராகரி';

  @override
  String get exitApp => 'ஆப் இலிருந்து வெளியேறவா?';

  @override
  String get exitAppMessage =>
      'நீங்கள் ஆப்பிலிருந்து வெளியேற விரும்புகிறீர்களா?';

  @override
  String get exit => 'வெளியேறு';

  @override
  String get discardChanges => 'மாற்றங்களை நிராகரிக்கவா?';

  @override
  String get discardChangesMessage =>
      'நீங்கள் சேமிக்கப்படாத மாற்றங்கள் உள்ளன. அவற்றை நிராகரிக்க விரும்புகிறீர்களா?';

  @override
  String get discard => 'நிராகரி';

  @override
  String get pressBackAgainToExit => 'வெளியேற மீண்டும் பின் செல்லவும்';

  @override
  String get pleaseWait => 'தயவுசெய்து காத்திருக்கவும்...';

  @override
  String get pleaseWaitForSpin => 'ஸ்பின் முடியும் வரை காத்திருக்கவும்';

  @override
  String get discardBill => 'பிலை நிராகரிக்கவா?';

  @override
  String get discardBillMessage =>
      'நீங்கள் சேமிக்கப்படாத பில் தரவு உள்ளது. அதை நிராகரிக்க விரும்புகிறீர்களா?';

  @override
  String get pleaseCompleteProfile =>
      'தயவுசெய்து உங்கள் சுயவிவரத்தை நிறைவு செய்யவும்';

  @override
  String get rewardsLoyaltyProgram => 'வெகுமதிகள் & விசுவாச திட்டம்';

  @override
  String get billImage => 'பில் படம்';

  @override
  String get billDateOptional => 'பில் தேதி (விருப்பம்)';

  @override
  String get storeVendorNameOptional => 'கடை/விற்பனையாளர் பெயர் (விருப்பம்)';

  @override
  String get billInvoiceNumberOptional => 'பில்/விலைப்பட்டியல் எண் (விருப்பம்)';

  @override
  String get notesOptional => 'குறிப்புகள் (விருப்பம்)';

  @override
  String get tapToAddBillImage => 'பில் படத்தைச் சேர்க்க தட்டவும்';

  @override
  String get selectBillDateOptional =>
      'பில் தேதியைத் தேர்ந்தெடுக்கவும் (விருப்பம்)';

  @override
  String get enterStoreOrVendorNameOptional =>
      'கடை அல்லது விற்பனையாளர் பெயரை உள்ளிடவும் (விருப்பம்)';

  @override
  String get enterBillOrInvoiceNumberOptional =>
      'பில் அல்லது விலைப்பட்டியல் எண்ணை உள்ளிடவும் (விருப்பம்)';

  @override
  String get addAnyAdditionalNotes =>
      'எந்த கூடுதல் குறிப்புகளையும் சேர்க்கவும்...';

  @override
  String get submitBill => 'பிலை சமர்ப்பிக்கவும்';

  @override
  String get saveChanges => 'மாற்றங்களை சேமிக்கவும்';

  @override
  String get withdrawBill => 'பில்லைத் திரும்பப் பெறு';

  @override
  String get withdrawBillConfirmation =>
      'அனுமதிக்கப்பட்ட இந்த பில்லைத் திரும்பப் பெற வேண்டுமா? தச்சருக்கு வழங்கிய புள்ளிகள் திருப்பப்படும்.';

  @override
  String get withdraw => 'திரும்பப் பெறு';

  @override
  String get billWithdrawnSuccess =>
      'பில் திரும்பப் பெறப்பட்டது. புள்ளிகள் திருப்பப்பட்டன.';

  @override
  String get failedToWithdrawBill => 'பில்லைத் திரும்பப் பெற முடியவில்லை';

  @override
  String get withdrawApproval => 'அனுமதியைத் திரும்பப் பெறு';

  @override
  String get reversePointsAndUndoApproval =>
      'புள்ளிகளைத் திருப்பி அனுமதியை ரத்துசெய்';

  @override
  String get approveBillAction => 'பில்லை அனுமதி';

  @override
  String get awardPointsAndMarkAsApproved =>
      'புள்ளிகள் வழங்கி அனுமதித்ததாகக் குறி';

  @override
  String get selectCarpenter => 'தச்சரைத் தேர்ந்தெடு';

  @override
  String get errorLoadingCarpenters => 'தச்சர்களை ஏற்றுவதில் பிழை';

  @override
  String get noCarpentersFound => 'தச்சர்கள் இல்லை';

  @override
  String get noCarpentersAvailable => 'தச்சர்கள் கிடைக்கவில்லை';

  @override
  String get billHistory => 'பில் வரலாறு';

  @override
  String get filters => 'வடிகட்டிகள்';

  @override
  String get from => 'இருந்து';

  @override
  String get to => 'வரை';

  @override
  String get searchCarpenter => 'தச்சரைத் தேடு...';

  @override
  String get errorLoadingBillHistory => 'பில்களை ஏற்றுவதில் பிழை';

  @override
  String get noBillsFoundMatchingFilters =>
      'வடிகட்டிக்குப் பொருந்தும் பில்கள் இல்லை';

  @override
  String get noBillsFoundHistory => 'பில்கள் இல்லை';

  @override
  String get billDateLabel => 'பில் தேதி';

  @override
  String get submittedLabel => 'சமர்ப்பிக்கப்பட்டது';

  @override
  String get approvedLabel => 'அனுமதிக்கப்பட்டது';

  @override
  String get rejectedLabel => 'நிராகரிக்கப்பட்டது';

  @override
  String get pts => 'புள்ளிகள்';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get aboutUs => 'எங்களைப் பற்றி';

  @override
  String get aboutUsMenuSubtitle =>
      'உறுப்பினர்களுக்கான வெகுமதி & நம்பிக்கை திட்டம்';

  @override
  String get aboutUsSubtitle => 'உங்கள் ஹார்டுவேர் வெகுமதி துணை';

  @override
  String get aboutUsOverviewTitle => 'பாலாஜி பாயிண்ட்ஸ் என்றால் என்ன?';

  @override
  String get aboutUsOverviewBody =>
      'பாலாஜி பாயிண்ட்ஸ் தச்சர்களுக்கும் ஹார்டுவேர் கடைகளுக்கும் ஒரு டிஜிட்டல் நம்பிக்கை தளம். தகுதியான பொருள் கொள்முதல்களைப் புள்ளிகள், வெகுமதிகள் மற்றும் அங்கீகாரமாக மாற்ற உதவுகிறது. நீங்கள் செயலியில் பில்களைச் சமர்ப்பிக்கிறீர்கள்; நீங்கள் இணைந்துள்ள கடை அவற்றைச் சரிபார்த்து ஒப்புதல் அளிக்கிறது; உங்கள் பணப்பையும் வரலாறும் தானாக புதுப்பிக்கப்படுவதால் நிலையை எப்போதும் தெரிந்துகொள்ளலாம்.';

  @override
  String get aboutUsEarningTitle => 'புள்ளிகளை எப்படிச் சம்பாதிப்பது';

  @override
  String get aboutUsEarningBody =>
      'தெளிவான புகைப்படங்கள், சரியான தொகை மற்றும் கடை கேட்கும் விவரங்களுடன் கொள்முதல் பில்களைப் பதிவேற்றவும். நியாயமான திட்டமும் தவறுகள்/துஷ்பிரயோகம் குறைவும் இருக்க நிர்வாகி ஒவ்வொரு சமர்ப்பிப்பையும் சரிபார்க்கிறார். ஒப்புதலுக்குப் பிறகு அந்தக் கடையின் விதிகளின்படி புள்ளிகள் சேர்க்கப்படும் (உதா: ரூபாய்–புள்ளி மாற்றம்). செயலியில் இருப்பு, பரிவர்த்தனை வரலாறு, நிலை முன்னேற்றம் ஆகியவற்றை எப்போதும் காணலாம்.';

  @override
  String get aboutUsOffersTitle => 'தலைமைப் பலகை, சலுகைகள் மற்றும் தகவல்கள்';

  @override
  String get aboutUsOffersBody =>
      'பல கடைகள் தலைமைப் பலகை நடத்துகின்றன; அந்தத் திட்டத்தில் மற்ற தச்சர்களிடையே உங்கள் நிலையைக் காணலாம். பேனர், சலுகைகள், அறிவிப்புகள்—பருவ சலுகைகள், கூடுதல் புள்ளி நிகழ்வுகள்—உங்கள் கடை வழங்கும் வாய்ப்புகளைத் தவறவிடாமல் இருக்க உதவும்.';

  @override
  String get aboutUsFairnessTitle => 'ஒப்புதல், வெளிப்படைத்தன்மை மற்றும் ஆதரவு';

  @override
  String get aboutUsFairnessBody =>
      'ஒவ்வொரு பில்லும் கவனமாகச் சரிபார்க்கப்படுவதால் சிறிது நேரம் ஆகலாம். நிராகரிப்பானால் காரணம் செயலியில் தெரிய வேண்டும் அல்லது கடைக் குழு வழிகாட்டும். உள்நுழைவு, PIN, சுயவிவரம் அல்லது அறிவிப்புப் பிரச்சினைகளுக்குச் செயலி வழிகளையும் தேவையில் கடையையும் தொடர்புகொள்ளவும். நிலுவை, ஒப்புதல், நிராகரிப்பு ஆகியவற்றிற்குத் தெளிவான விதிகள் மற்றும் நிலை காட்சி முக்கியம்.';

  @override
  String get aboutUsStoresTitle => 'உங்கள் கடை, உங்கள் திட்டம்';

  @override
  String get aboutUsStoresBody =>
      'புள்ளிகள், நிலைகள் மற்றும் சலுகைகள் இந்தச் செயலியில் நீங்கள் இணைந்த ஹார்டுவேர் கடையுடன் இணைக்கப்பட்டவை. வெவ்வேறு கடைகள் வெவ்வேறு விதிகள், மாற்ற விகிதங்கள் மற்றும் நன்மைகளைக் கொண்டிருக்கலாம். பல கடைகளில் வாங்கினால் ஒவ்வொரு உறவும் பொதுவாகத் தனி; கடை வேறுவிதமாகச் சொல்லாவிட்டால்—விவரங்களுக்கு உங்களைச் சேர்த்த கடையை உறுதிப்படுத்தவும்.';

  @override
  String get aboutUsClosing =>
      'பாலாஜி பாயிண்ட்ஸ் பயன்படுத்துவதற்கு நன்றி—தச்சர்களுக்கும் உங்களுடன் இணைந்த கடைகளுக்கும் உதவுவதில் பெருமை கொள்கிறோம்.';

  @override
  String get aboutUsCreditsHeading => 'வடிவமைப்பு மற்றும் உருவாக்கம்';

  @override
  String get aboutUsCreditsStudio => 'Aaiji Tech Studio — Vadodara, Gujarat';

  @override
  String get onboardingSkip => 'தவிர்';

  @override
  String get onboardingGetStarted => 'தொடங்கு';

  @override
  String get onboardingSlide1Title => 'பில்களைச் சமர்ப்பி, புள்ளிகளைச் சம்பாதி';

  @override
  String get onboardingSlide1Body =>
      'உங்கள் ஹார்டுவேர் கொள்முதல் பில்களைப் பதிவேற்றவும். உங்கள் கடை ஒப்புதல் அளிக்கும்போது புள்ளிகள் உங்கள் பணப்பையில் சேரும்.';

  @override
  String get onboardingSlide2Title => 'வெகுமதிகளைக் கண்காணி';

  @override
  String get onboardingSlide2Body =>
      'இருப்பு, நிலை மற்றும் தலைமைப் பலகை நிலையைக் காண்க. உங்களைப் போன்ற தச்சர்களுக்கான சலுகைகளை உலாவவும்.';

  @override
  String get onboardingSlide3Title => 'புதுப்பித்த நிலையில் இருங்கள்';

  @override
  String get onboardingSlide3Body =>
      'பில்கள் ஒப்புதல் அல்லது நிராகரிப்பு பற்றி அறிவிப்புகளைப் பெறுங்கள். சுயவிவரம் மற்றும் விருப்பங்களை எப்போதும் மேலாண்மை செய்யுங்கள்.';

  @override
  String errorWithDetails(String details) {
    return 'பிழை: $details';
  }

  @override
  String get siteNameRequired => 'தளத்தின் பெயர் அவசியம்';

  @override
  String get billDateFuture => 'பில் தேதி எதிர்காலமாக இருக்கக்கூடாது';

  @override
  String get duplicateBillDetected => 'நகல் பில் கண்டறியப்பட்டது';

  @override
  String get duplicateBillIntro =>
      'இதே தளம், தொகை, தேதியுடன் ஒரு பில் ஏற்கனவே உள்ளது:';

  @override
  String get siteNameLabel => 'தளத்தின் பெயர்';

  @override
  String get amountLabel => 'தொகை';

  @override
  String get pointsLabel => 'புள்ளிகள்';

  @override
  String get dateLabel => 'தேதி';

  @override
  String ptsValue(String points) {
    return '$points புள்ளிகள்';
  }

  @override
  String get duplicateBillVerify =>
      'இது நகல் பதிவாக இருக்கலாம். சேர்க்கும் முன் சரிபார்க்கவும்.';

  @override
  String get addBillAnywayQuestion =>
      'இருந்தாலும் இந்த பில்லைச் சேர்க்க வேண்டுமா?';

  @override
  String get addAnyway => 'இருந்தாலும் சேர்';

  @override
  String get billsPausedDiwali =>
      'தீபாவளி கொண்டாட்டத்திற்காக பில் சமர்ப்பிப்பு நிறுத்தப்பட்டுள்ளது.';

  @override
  String earnPointsWhenApproved(String points) {
    return 'அனுமதிக்கப்பட்டதும் $points புள்ளிகள் கிடைக்கும்';
  }

  @override
  String get vendorNameLabel => 'விற்பனையாளர் பெயர்';

  @override
  String get menu => 'மெனு';

  @override
  String get hintPassword => 'கடவுச்சொல் உள்ளிடவும்';

  @override
  String get hintPasswordMin => 'கடவுச்சொல் உள்ளிடவும்';

  @override
  String get hintConfirmPassword => 'மீண்டும் உள்ளிடவும்';

  @override
  String get hintFullName => 'முழுப் பெயர் உள்ளிடவும்';

  @override
  String get hintAmount => 'தொகையை உள்ளிடவும்';

  @override
  String get hintBranchFullName => 'கிளை பெயர் உள்ளிடவும்';

  @override
  String get hintShortName => 'குறுகிய பெயர் உள்ளிடவும்';

  @override
  String get hintBranchCode => 'கிளை குறியீடு உள்ளிடவும்';

  @override
  String get hintAddress => 'முகவரி உள்ளிடவும்';

  @override
  String get hintRoleName => 'பங்கு பெயர் உள்ளிடவும்';

  @override
  String get hintEmail => 'மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get hintPhone => 'போன் எண்ணை உள்ளிடவும்';

  @override
  String get hintPin => 'PIN உள்ளிடவும்';

  @override
  String get hintConfirmPin => 'PIN மீண்டும் உள்ளிடவும்';

  @override
  String get hintBranchId => 'கிளை ID உள்ளிடவும்';

  @override
  String get diwaliYourPrize => 'உங்கள் தீபாவளி பரிசு';

  @override
  String get diwaliYou => 'நீங்கள்';

  @override
  String get diwaliPosition => 'இடம்';

  @override
  String get navAddBill => 'பில் சேர்';

  @override
  String get navAlerts => 'அறிவிப்பு';

  @override
  String get readMore => 'மேலும் படிக்க';

  @override
  String get showLess => 'குறைவாகக் காட்டு';

  @override
  String get diwaliPrizeLoadFailed =>
      'தீபாவளி பரிசுப் பட்டியலை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get featureEarnMore => 'அதிகம் சம்பாதி';

  @override
  String get featureEarnBody => 'பில் பதிவேற்று\nபுள்ளிகள் பெறு';

  @override
  String get featureRedeemMore => 'அதிகம் பெறு';

  @override
  String get featureRedeemBody => 'அருமையான வெகுமதிகள்\n& பரிசுகள்';

  @override
  String get featureGrowMore => 'முன்னேறு';

  @override
  String get featureGrowBody => 'தரவரிசையில் உயரு\nசிறந்த உறுப்பினராகு';

  @override
  String get featureExclusive => 'சிறப்பு';

  @override
  String get featureExclusiveBody => 'சிறப்பு நன்மைகள்\nஉங்களுக்காக மட்டும்';

  @override
  String get newAnnouncement => 'புதிய அறிவிப்பு';

  @override
  String ptsToNextLabel(String points, String tier) {
    return '$tier வரை $points புள்ளிகள்';
  }

  @override
  String get platinumHighestTier => 'பிளாட்டினம் — உச்ச நிலை!';

  @override
  String get topCarpentersTitle => 'சிறந்த உறுப்பினர்கள்';

  @override
  String get noRankingYet => 'இன்னும் தரவரிசை தரவு இல்லை';

  @override
  String get noWinnerToday => 'இன்று வெற்றியாளர் இல்லை';

  @override
  String spinNotDoneYet(String date) {
    return 'இன்னும் சுழற்றவில்லை · $date';
  }

  @override
  String get todaysLuckyWinner => 'இன்றைய அதிர்ஷ்ட வெற்றியாளர்';

  @override
  String selectedViaDailySpin(String date) {
    return 'தினசரி சுழற்சி மூலம் தேர்வு · $date';
  }

  @override
  String get notificationDeleted => 'அறிவிப்பு நீக்கப்பட்டது';

  @override
  String get deleteAllNotifications => 'எல்லா அறிவிப்புகளையும் நீக்கு';

  @override
  String get deleteAllNotificationsConfirm =>
      'எல்லா அறிவிப்புகளையும் நீக்க வேண்டுமா? இதைத் திரும்பப் பெற முடியாது.';

  @override
  String get deleteAll => 'அனைத்தையும் நீக்கு';

  @override
  String notificationsDeleted(String count) {
    return '$count அறிவிப்புகள் நீக்கப்பட்டன';
  }

  @override
  String get unableToLoadNotifications => 'அறிவிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get errorLoadingNotifications => 'அறிவிப்புகளை ஏற்றுவதில் பிழை';

  @override
  String get noNotificationsTitle => 'அறிவிப்புகள் இல்லை';

  @override
  String get noNotificationsYet => 'உங்களுக்கு இன்னும் அறிவிப்புகள் இல்லை';

  @override
  String get deleteNotification => 'அறிவிப்பை நீக்கு';

  @override
  String get deleteNotificationConfirm => 'இந்த அறிவிப்பை நீக்க வேண்டுமா?';

  @override
  String get addProfilePhoto => 'சுயவிவரப் படத்தைச் சேர்க்கவும்';

  @override
  String get profileUpdatedSuccess => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get failedToUpdateProfile => 'சுயவிவரத்தைப் புதுப்பிக்க முடியவில்லை';

  @override
  String get tapToChangePhoto => 'படத்தை மாற்ற தட்டவும்';

  @override
  String get lastNameRequired => 'குடும்பப் பெயர் *';

  @override
  String get uploadingImage => 'படம் பதிவேற்றப்படுகிறது...';

  @override
  String get completeProfileToContinue =>
      'தொடர உங்கள் சுயவிவரத்தை நிறைவு செய்யவும்';

  @override
  String get couldNotMakeCall => 'அழைக்க முடியவில்லை';

  @override
  String get themeLabel => 'தீம்';

  @override
  String get themeLight => 'ஒளி';

  @override
  String get themeDark => 'இருள்';

  @override
  String get youWonLabel => 'நீங்கள் வென்றது';

  @override
  String pointsWon(String points) {
    return '$points புள்ளிகள்!';
  }

  @override
  String get pointsAddedToAccount =>
      'புள்ளிகள் உங்கள் கணக்கில் சேர்க்கப்பட்டன.';

  @override
  String get great => 'அருமை!';

  @override
  String get spinAndWin => 'சுழற்றி புள்ளிகளை வெல்லுங்கள்!';

  @override
  String get spinAndWinSubtitle =>
      'தினமும் சுழற்றி அருமையான புள்ளிகளை வெல்லுங்கள்';

  @override
  String get alreadySpunToday =>
      'இன்று ஏற்கனவே சுழற்றிவிட்டீர்கள்!\nநாளை மீண்டும் வாருங்கள்.';

  @override
  String nextTierLabel(String tier) {
    return 'அடுத்த நிலை: $tier';
  }

  @override
  String ptsToNextTier(String points) {
    return 'அடுத்த நிலைக்கு $points புள்ளிகள்';
  }

  @override
  String get platinumMaxLevel => 'பிளாட்டினம் நிலை — அதிகபட்சம்';

  @override
  String get filterLabel => 'வடிகட்டு';

  @override
  String get totalApprovedPoints => 'மொத்த அனுமதிக்கப்பட்ட புள்ளிகள்';

  @override
  String billsCount(String count) {
    return '$count பில்கள்';
  }

  @override
  String get billAttachment => 'பில் இணைப்பு';

  @override
  String get pendingApproval => 'அனுமதி நிலுவையில்';

  @override
  String get backToSignIn => 'உள்நுழைவுக்குத் திரும்பு';

  @override
  String get noPinAccount =>
      'இந்த எண்ணுக்கு PIN கணக்கு இல்லை. மின்னஞ்சல், கடவுச்சொல் அல்லது Google மூலம் உள்நுழையவும்.';

  @override
  String get signInWithMobile => 'மொபைல் எண் மூலம் உள்நுழை';

  @override
  String get continueToPin => 'PIN-க்குத் தொடர்';

  @override
  String get backToOtherSignIn => 'பிற உள்நுழைவு வழிகளுக்குத் திரும்பு';

  @override
  String get branchHasAdminDefaulted =>
      'தேர்ந்தெடுத்த கிளையில் ஏற்கனவே நிர்வாகி உள்ளார். பங்கு தச்சர் என அமைக்கப்பட்டது.';

  @override
  String get selectBranchToContinue => 'தொடர ஒரு கிளையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get oneAdminPerBranch =>
      'இந்தக் கிளைக்கு ஏற்கனவே நிர்வாகி உள்ளார். ஒரு கிளைக்கு ஒரு நிர்வாகி மட்டுமே.';

  @override
  String get branchRequired => 'கிளை *';

  @override
  String get selectYourBranch => 'உங்கள் கிளையைத் தேர்ந்தெடு';

  @override
  String get userRoleRequired => 'பயனர் பங்கு *';

  @override
  String get roleCarpenterWoodworker => 'தச்சர் / மரவேலையாளர்';

  @override
  String get roleArchitect => 'கட்டடக் கலைஞர்';

  @override
  String get roleInteriorDesigner => 'உள்ளக வடிவமைப்பாளர்';

  @override
  String get fullName => 'முழுப் பெயர்';

  @override
  String get passwordLabel => 'கடவுச்சொல்';

  @override
  String get confirmPasswordLabel => 'கடவுச்சொல்லை உறுதிப்படுத்து';

  @override
  String get noActiveRoles =>
      'செயலில் உள்ள பங்குகள் இல்லை. சூப்பர் நிர்வாகியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get noActiveBranches =>
      'செயலில் உள்ள கிளைகள் இல்லை. உங்கள் நிர்வாகியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get cancelReturnToSignIn => 'ரத்துசெய்து உள்நுழைவுக்குத் திரும்பு';

  @override
  String get selectRoleRequired => 'பங்கைத் தேர்ந்தெடு *';

  @override
  String get previousPage => 'முந்தைய';

  @override
  String tablePageInfo(
    String page,
    String pages,
    String from,
    String to,
    String total,
  ) {
    return 'பக்கம் $page/$pages · $total-இல் $from–$to';
  }

  @override
  String get noRows => 'வரிசைகள் இல்லை';

  @override
  String get updateNow => 'இப்போது புதுப்பி';

  @override
  String get maybeLater => 'பிறகு';

  @override
  String get requiredLabel => 'அவசியம்';

  @override
  String get installedLabel => 'நிறுவப்பட்டது';

  @override
  String get updateMandatory =>
      'ஆப்பைத் தொடர்ந்து பயன்படுத்த இந்தப் புதுப்பிப்பு அவசியம்.';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get billsAppearHere =>
      'நீங்கள் சமர்ப்பிக்கும் பில்கள் இங்கே தெரியும்.';

  @override
  String get pendingBillsAppearHere =>
      'தச்சர்களின் புதிய பில்கள் அனுமதிக்காக இங்கே தெரியும்.';

  @override
  String get tryChangingFilters =>
      'வடிகட்டிகளை மாற்றி அல்லது நீக்கிப் பாருங்கள்.';

  @override
  String get carpentersAppearHere => 'பதிவுசெய்த தச்சர்கள் இங்கே தெரியும்.';

  @override
  String get statCarpenters => 'தச்சர்கள்';

  @override
  String get statPendingBills => 'நிலுவை பில்கள்';

  @override
  String get statAwaitingReview => 'சரிபார்ப்புக்குக் காத்திருக்கிறது';

  @override
  String get statBillsThisMonth => 'இந்த மாத பில்கள்';

  @override
  String statApprovedThisMonth(String count) {
    return '$count அனுமதிக்கப்பட்டது';
  }

  @override
  String get statPointsIssued => 'வழங்கிய புள்ளிகள்';

  @override
  String get statThisMonth => 'இந்த மாதம்';

  @override
  String get statRegistered => 'பதிவுசெய்தவர்கள்';

  @override
  String version(String version, String buildNumber) {
    return 'பதிப்பு $version ($buildNumber)';
  }

  @override
  String get switchToLight => 'ஒளி பயன்முறைக்கு மாற்று';

  @override
  String get switchToDark => 'இருள் பயன்முறைக்கு மாற்று';

  @override
  String get max => 'அதிகபட்சம்';

  @override
  String get status => 'நிலை';

  @override
  String to2(String nextLabel) {
    return '$nextLabel வரை';
  }

  @override
  String get spinNow2 => 'இப்போது சுழற்று!';

  @override
  String get pleaseCompleteYourProfileFirstName =>
      'பில்களைச் சேர்த்து புள்ளிகள் பெற உங்கள் சுயவிவரத்தை (முதல் பெயர், குடும்பப் பெயர், சுயவிவரப் படம்) நிறைவு செய்யவும்.';

  @override
  String get goBack => 'பின்செல்';

  @override
  String get chooseFromGallery => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get takePhoto => 'படம் எடு';

  @override
  String get pleaseLoginToSubmitBills => 'பில்களைச் சமர்ப்பிக்க உள்நுழையவும்';

  @override
  String get billSubmittedSuccessfullyAdminWillReview =>
      'பில் சமர்ப்பிக்கப்பட்டது! நிர்வாகி சரிபார்ப்பார்.';

  @override
  String get failedToSubmitBillPleaseTry =>
      'பில்லைச் சமர்ப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get pleaseEnterBillAmount => 'பில் தொகையை உள்ளிடவும்';

  @override
  String get billDate2 => 'பில் தேதி *';

  @override
  String get selectBillDate2 => 'பில் தேதியைத் தேர்ந்தெடு';

  @override
  String get siteName => 'தளத்தின் பெயர் *';

  @override
  String get enterSiteLocationName => 'தள பெயர் உள்ளிடவும்';

  @override
  String get vendorNameOptional => 'விற்பனையாளர் பெயர் (விருப்பம்)';

  @override
  String get enterVendorStoreNameOptional => 'விற்பனையாளர் பெயர் உள்ளிடவும்';

  @override
  String get noUserLoggedIn => 'பயனர் உள்நுழையவில்லை';

  @override
  String get firstNameMustBeAtLeast =>
      'முதல் பெயர் குறைந்தது 2 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get firstNameIsTooLongMax =>
      'முதல் பெயர் மிக நீளம் (அதிகபட்சம் 50 எழுத்துகள்)';

  @override
  String get lastNameMustBeAtLeast =>
      'குடும்பப் பெயர் குறைந்தது 2 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get lastNameIsTooLongMax =>
      'குடும்பப் பெயர் மிக நீளம் (அதிகபட்சம் 50 எழுத்துகள்)';

  @override
  String get failedToUploadProfileImage =>
      'சுயவிவரப் படத்தைப் பதிவேற்ற முடியவில்லை';

  @override
  String failedToUploadProfileImage2(String e) {
    return 'சுயவிவரப் படத்தைப் பதிவேற்ற முடியவில்லை: $e';
  }

  @override
  String get enterYourFirstName => 'முதல் பெயர் உள்ளிடவும்';

  @override
  String get pleaseEnterYourFirstName =>
      'தயவுசெய்து உங்கள் முதல் பெயரை உள்ளிடவும்';

  @override
  String get enterYourLastName => 'கடைசி பெயர் உள்ளிடவும்';

  @override
  String get pleaseEnterYourLastName =>
      'தயவுசெய்து உங்கள் குடும்பப் பெயரை உள்ளிடவும்';

  @override
  String get user => 'பயனர்';

  @override
  String get language => 'மொழி';

  @override
  String get trackYourPointsAndManageYour =>
      'உங்கள் புள்ளிகளையும் பில்களையும் நிர்வகிக்கவும்';

  @override
  String mAgo(String inMinutes) {
    return '$inMinutes நிமி. முன்';
  }

  @override
  String hAgo(String inHours) {
    return '$inHours மணி. முன்';
  }

  @override
  String dAgo(String inDays) {
    return '$inDays நாள் முன்';
  }

  @override
  String get notification => 'அறிவிப்பு';

  @override
  String get noCarpenterAccountsAreListedFor =>
      'இந்தக் கிளையில் இன்னும் உறுப்பினர் கணக்குகள் இல்லை.';

  @override
  String get continueToHome => 'முகப்புக்குச் செல்';

  @override
  String get shubhDeepawali => 'இனிய தீபாவளி!';

  @override
  String carpenters(String branchName, String carpenterCount) {
    return '$branchName  ·  $carpenterCount தச்சர்கள்';
  }

  @override
  String carpenterRewardBonusReport(String dateFormat) {
    return 'தச்சர் வெகுமதி & போனஸ் அறிக்கை  ·  $dateFormat';
  }

  @override
  String get closeCelebration => 'கொண்டாட்டத்தை மூடு';

  @override
  String get deepawaliPrizeNight => '✦  தீபாவளி பரிசு இரவு  ✦';

  @override
  String get topPerformersGoldTier => 'சிறந்தவர்கள் — தங்க நிலை';

  @override
  String get ranks110 => 'தரவரிசை 1-10';

  @override
  String get highPerformersSilverTier => 'உயர் செயல்திறன் — வெள்ளி நிலை';

  @override
  String get ranks1130 => 'தரவரிசை 11-30';

  @override
  String get activePerformersBronzeTier => 'செயலில் உள்ளவர்கள் — வெண்கல நிலை';

  @override
  String get ranks31Onwards => 'தரவரிசை 31 முதல்';

  @override
  String totalCarpenters(String entries) {
    return 'மொத்த தச்சர்கள்: $entries';
  }

  @override
  String get totalPoints2 => 'மொத்த புள்ளிகள்';

  @override
  String get totalReward => 'மொத்த வெகுமதி';

  @override
  String get totalBonus => 'மொத்த போனஸ்';

  @override
  String carpentersPointsRewardBonus(
    String entries,
    String totalPoints,
    String totalReward,
    String totalBonus,
  ) {
    return '$entries தச்சர்கள்  ·  $totalPoints புள்ளிகள்  ·  $totalReward வெகுமதி  ·  $totalBonus போனஸ்';
  }

  @override
  String bonus(String bonusAmount, String giftDetails) {
    return '$bonusAmount போனஸ்  ·  $giftDetails';
  }

  @override
  String get mobileNumberUnavailable => 'மொபைல் எண் கிடைக்கவில்லை';

  @override
  String get reward => 'வெகுமதி';

  @override
  String get bonus2 => 'போனஸ்';

  @override
  String get nil => 'இல்லை';

  @override
  String get gift => 'பரிசு';

  @override
  String get reward2 => 'வெகுமதி ₹';

  @override
  String get bonus3 => 'போனஸ் ₹';

  @override
  String get giftDetails => 'பரிசு விவரம்';

  @override
  String get remarks => 'குறிப்பு';

  @override
  String get verifyYourIdentityToOpenBalaji =>
      'Balaji Points-ஐத் திறக்க உங்கள் அடையாளத்தைச் சரிபார்க்கவும்';

  @override
  String get passwordResetLinksAreSentSecurely =>
      'கடவுச்சொல் மீட்டமைப்பு இணைப்புகள் பாதுகாப்பாக அனுப்பப்படும்.';

  @override
  String get checkYourEmail => 'உங்கள் மின்னஞ்சலைப் பாருங்கள்';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டதா?';

  @override
  String get ifAnAccountExistsForThis =>
      'இந்த முகவரிக்கு கணக்கு இருந்தால், கடவுச்சொல் மீட்டமைப்பு வழிமுறைகள் அனுப்பப்பட்டுள்ளன. இன்பாக்ஸ் மற்றும் ஸ்பேம் கோப்புறையைப் பாருங்கள்.';

  @override
  String get enterTheEmailAddressLinkedTo =>
      'உங்கள் கணக்குடன் இணைந்த மின்னஞ்சலை உள்ளிடவும். புதிய கடவுச்சொல்லுக்கு பாதுகாப்பான இணைப்பை அனுப்புவோம்.';

  @override
  String get enterAValidEmailAddress => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get sendAnotherResetLink => 'மற்றொரு மீட்டமைப்பு இணைப்பை அனுப்பு';

  @override
  String get sendResetLink => 'மீட்டமைப்பு இணைப்பை அனுப்பு';

  @override
  String get welcomeBack2 => 'மீண்டும் வருக';

  @override
  String signInToContinueTo(String appName) {
    return '$appName-இல் தொடர உள்நுழையவும்';
  }

  @override
  String get signIn => 'உள்நுழை';

  @override
  String get useYourEmailAndPasswordOr =>
      'மின்னஞ்சல், கடவுச்சொல் அல்லது உங்கள் PIN மூலம் உள்நுழையவும்.';

  @override
  String get pleaseEnterAValidEmailAddress =>
      'தயவுசெய்து சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get passwordMustBeAtLeast6 =>
      'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get loginWithPin => 'PIN மூலம் உள்நுழை';

  @override
  String get newToBalajiPoints => 'Balaji Points-க்கு புதியவரா? ';

  @override
  String get createAccount2 => 'கணக்கை உருவாக்கு';

  @override
  String designedAndDevelopedBy(String companyName) {
    return '$companyName வடிவமைத்து உருவாக்கியது';
  }

  @override
  String get signInWithGoogle => 'Google மூலம் உள்நுழை';

  @override
  String get hindi => 'இந்தி';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get forCurrentMobilePinAccounts =>
      'தற்போதைய மொபைல் + PIN கணக்குகளுக்கு';

  @override
  String get enterAValid10DigitMobile =>
      'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get yourDataIs100SecureWith =>
      'உங்கள் தரவு எங்களிடம் 100% பாதுகாப்பாக உள்ளது';

  @override
  String get userAlreadyExists => 'பயனர் ஏற்கனவே உள்ளார்';

  @override
  String get permissionDeniedPleaseCheckFirebaseConfiguration =>
      'அனுமதி மறுக்கப்பட்டது. நிர்வாகியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get branchAdminAlreadyAssigned =>
      'கிளை நிர்வாகி (ஏற்கனவே ஒதுக்கப்பட்டது)';

  @override
  String get branchAdmin1PerBranch => 'கிளை நிர்வாகி (கிளைக்கு 1)';

  @override
  String get selectABranchToContinue => 'தொடர ஒரு கிளையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get selectARoleToContinue => 'தொடர ஒரு பங்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get selectAnActiveRoleToContinue =>
      'தொடர செயலில் உள்ள பங்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get yourInformationIsProtected => 'உங்கள் தகவல் பாதுகாக்கப்பட்டுள்ளது';

  @override
  String get completeYourGoogleRegistration =>
      'உங்கள் Google பதிவை நிறைவு செய்யவும்';

  @override
  String get createYourAccount => 'உங்கள் கணக்கை உருவாக்கவும்';

  @override
  String get addYourMobileNumberAndChoose =>
      'கணக்கை அமைக்க உங்கள் மொபைல் எண்ணைச் சேர்த்து, கிளை மற்றும் பங்கைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get chooseYourRoleAndTheBranch =>
      'உங்கள் பங்கையும் கிளையையும் தேர்ந்தெடுக்கவும்.';

  @override
  String get enterYourFullName => 'உங்கள் முழுப் பெயரை உள்ளிடவும்';

  @override
  String get hidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get showPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get useAtLeast6Characters => 'குறைந்தது 6 எழுத்துகள் பயன்படுத்தவும்';

  @override
  String get passwordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get yourAccountAlreadyHasAnAdmin =>
      'உங்கள் கணக்கில் ஏற்கனவே நிர்வாகி பங்கு உள்ளது. தொடர்வதற்கு முன் சூப்பர் நிர்வாகியிடம் கிளையை ஒதுக்கச் சொல்லுங்கள்.';

  @override
  String get branchAdminAccessIsAssignedBy =>
      'கிளை நிர்வாகி அனுமதியை சூப்பர் நிர்வாகி வழங்குவார்.';

  @override
  String get completeRegistration => 'பதிவை நிறைவு செய்';

  @override
  String get loadingRoles => 'பங்குகள் ஏற்றப்படுகின்றன…';

  @override
  String get chooseOneRole => 'ஒரு பங்கைத் தேர்ந்தெடு';

  @override
  String get selectARoleToContinue2 => 'தொடர ஒரு பங்கைத் தேர்ந்தெடு';

  @override
  String get loadingBranches => 'கிளைகள் ஏற்றப்படுகின்றன…';

  @override
  String get selectABranch => 'கிளையைத் தேர்ந்தெடு';

  @override
  String cannotMakePhoneCallTo(String phoneNumber) {
    return '$phoneNumber-க்கு அழைக்க முடியவில்லை';
  }

  @override
  String errorMakingPhoneCall(String e) {
    return 'அழைப்பதில் பிழை: $e';
  }

  @override
  String get member => 'உறுப்பினர்';

  @override
  String get updateRequired => 'புதுப்பிப்பு அவசியம்';

  @override
  String get newVersionAvailable => 'புதிய பதிப்பு கிடைக்கிறது';

  @override
  String get latest => 'சமீபத்தியது';

  @override
  String get completed => 'முடிந்தது';

  @override
  String get processing => 'செயலாக்கத்தில்';

  @override
  String installLatestToContinue(String appName) {
    return 'தொடர $appName-இன் சமீபத்திய பதிப்பை நிறுவவும்.';
  }

  @override
  String get newerVersionReady =>
      'மேம்பாடுகள் மற்றும் திருத்தங்களுடன் புதிய பதிப்பு தயார்.';

  @override
  String get pleaseSelectACarpenter => 'தயவுசெய்து தச்சரைத் தேர்ந்தெடுக்கவும்';

  @override
  String get billSubmittedSuccessfullyItWillBe =>
      'பில் சமர்ப்பிக்கப்பட்டது! சரிபார்க்கப்படும்.';

  @override
  String get duplicateBill => 'நகல் பில்';

  @override
  String get aBillWithTheSameSite =>
      'இந்தத் தச்சருக்கு இதே தளம், தொகை, தேதியுடன் ஒரு பில் ஏற்கனவே உள்ளது:';

  @override
  String get site => 'தளம்';

  @override
  String pts2(String duplicatePoints) {
    return '$duplicatePoints புள்ளிகள்';
  }

  @override
  String get pleaseVerifyThisIsNotA =>
      'இது நகல் பதிவு அல்ல என்பதைச் சரிபார்க்கவும்.';

  @override
  String error2(String e) {
    return 'பிழை: $e';
  }

  @override
  String get addAnyway2 => 'இருந்தாலும் சேர்';

  @override
  String get addBillForCarpenter => 'தச்சருக்கான பில்லைச் சேர்';

  @override
  String get carpenter2 => 'தச்சர் *';

  @override
  String get billAmount2 => 'பில் தொகை (₹) *';

  @override
  String get billImageOptional => 'பில் படம் (விருப்பம்)';

  @override
  String get siteName2 => 'தளத்தின் பெயர்';

  @override
  String get vendorName => 'விற்பனையாளர் பெயர்';

  @override
  String get pendingApproval2 => 'அனுமதி நிலுவையில்';

  @override
  String areYouSureYouWantTo(String billData) {
    return 'இந்த பில்லை அனுமதிக்க வேண்டுமா?\n\n₹$billData செயலாக்கப்படும்.';
  }

  @override
  String get billRejected2 => 'பில் நிராகரிக்கப்பட்டது';

  @override
  String get share => 'பகிர்';

  @override
  String get billNotFound => 'பில் கிடைக்கவில்லை';

  @override
  String get billId => 'பில் ஐடி';

  @override
  String submitted(String createdAt) {
    return 'சமர்ப்பித்தது $createdAt';
  }

  @override
  String get submittedOn => 'சமர்ப்பித்த தேதி';

  @override
  String get store => 'கடை';

  @override
  String get carpenterInfo => 'தச்சர் தகவல்';

  @override
  String get viewProfile => 'சுயவிவரத்தைப் பார்';

  @override
  String pts3(String totalPoints) {
    return '$totalPoints புள்ளிகள்';
  }

  @override
  String get billSummary => 'பில் சுருக்கம்';

  @override
  String get billAmount3 => 'பில் தொகை';

  @override
  String get pointsToCredit => 'வரவு வைக்கும் புள்ளிகள்';

  @override
  String get billNo => 'பில் எண்';

  @override
  String get pointsRate => 'புள்ளி விகிதம்';

  @override
  String get t1Pt1000 => '1 புள்ளி / ₹1000';

  @override
  String get billType => 'பில் வகை';

  @override
  String get purchase => 'கொள்முதல்';

  @override
  String get billAttachment2 => 'பில் இணைப்பு';

  @override
  String get viewFullSize => 'முழு அளவில் பார்';

  @override
  String get downloadImage => 'படத்தைப் பதிவிறக்கு';

  @override
  String get generatePdf => 'PDF உருவாக்கு';

  @override
  String get timeline => 'காலவரிசை';

  @override
  String get billCreated => 'பில் உருவாக்கப்பட்டது';

  @override
  String get waitingForApproval => 'அனுமதிக்காகக் காத்திருக்கிறது';

  @override
  String get pendingActionFromAdmin => 'நிர்வாகியின் நடவடிக்கை நிலுவையில்';

  @override
  String get justNow2 => 'இப்போது';

  @override
  String minAgo(String inMinutes) {
    return '$inMinutes நிமி. முன்';
  }

  @override
  String billDetails2(String billId) {
    return 'பில் விவரம் - $billId';
  }

  @override
  String get errorLoadingBillDetails => 'பில் விவரங்களை ஏற்றுவதில் பிழை';

  @override
  String get noBillFound => 'பில் கிடைக்கவில்லை';

  @override
  String get totalInstances => 'மொத்த பதிவுகள்';

  @override
  String get billEntries => 'பில் பதிவுகள்';

  @override
  String instance(String index) {
    return 'பதிவு $index';
  }

  @override
  String get time => 'நேரம்';

  @override
  String get noBillsToExportApplyFilters =>
      'ஏற்றுமதிக்கு பில்கள் இல்லை. வடிகட்டியைப் பயன்படுத்துங்கள் அல்லது காத்திருங்கள்.';

  @override
  String get preparingPdf => 'PDF தயாராகிறது...';

  @override
  String get noBillsMatchCurrentFiltersFor =>
      'தற்போதைய வடிகட்டிக்குப் பொருந்தும் பில்கள் இல்லை.';

  @override
  String exportFailed(String e) {
    return 'ஏற்றுமதி தோல்வி: $e';
  }

  @override
  String get bill => 'பில் #';

  @override
  String get approvedDate => 'அனுமதி தேதி';

  @override
  String get actions => 'செயல்கள்';

  @override
  String get exportAllBillsToPdf => 'எல்லா பில்களையும் PDF-ஆக ஏற்றுமதி செய்';

  @override
  String approveThisBillOfPointsWill(String amount, String amount2) {
    return '₹$amount பில்லை அனுமதிக்கவா?\n\nஉறுப்பினருக்கு $amount2 புள்ளிகள் சேர்க்கப்படும்.';
  }

  @override
  String get billApprovedAndPointsAddedSuccessfully =>
      'பில் அனுமதிக்கப்பட்டு புள்ளிகள் சேர்க்கப்பட்டன';

  @override
  String get failedToApproveBill2 => 'பில்லை அனுமதிக்க முடியவில்லை';

  @override
  String errorApprovingBill(String e) {
    return 'பில்லை அனுமதிப்பதில் பிழை: $e';
  }

  @override
  String get failedToRejectBill2 => 'பில்லை நிராகரிக்க முடியவில்லை';

  @override
  String errorRejectingBill(String e) {
    return 'பில்லை நிராகரிப்பதில் பிழை: $e';
  }

  @override
  String get dateFilters => 'தேதி வடிகட்டிகள்';

  @override
  String get clearFilters => 'வடிகட்டிகளை அழி';

  @override
  String pts4(String amount) {
    return '$amount புள்ளிகள்';
  }

  @override
  String get noHistoryAvailable => 'வரலாறு இல்லை';

  @override
  String get carpenterSummary => 'தச்சர் சுருக்கம்';

  @override
  String totalPts(String totalPoints) {
    return 'மொத்தம்: $totalPoints புள்ளிகள்';
  }

  @override
  String get totalBills => 'மொத்த பில்கள்';

  @override
  String get pointsBySite => 'தளவாரியான புள்ளிகள்';

  @override
  String pts5(String num) {
    return '$num புள்ளிகள்';
  }

  @override
  String get site2 => 'தளம்: ';

  @override
  String get billDate3 => 'பில் தேதி: ';

  @override
  String get approved2 => 'அனுமதி: ';

  @override
  String get submitted2 => 'சமர்ப்பிப்பு: ';

  @override
  String get allBillsHistory => 'அனைத்து பில் வரலாறு';

  @override
  String bills(String filtered, String billsList) {
    return '$filtered/$billsList பில்கள்';
  }

  @override
  String get filterBySite => 'தளத்தால் வடிகட்டு';

  @override
  String get allSites => 'அனைத்து தளங்கள்';

  @override
  String billId2(String index, String billNum) {
    return '#$index - பில் ஐடி: $billNum';
  }

  @override
  String pts6(String pts) {
    return '$pts புள்ளிகள்';
  }

  @override
  String get transactions => 'பரிவர்த்தனைகள்';

  @override
  String get rewards => 'வெகுமதிகள்';

  @override
  String get deleteAllNotifications2 => 'எல்லா அறிவிப்புகளையும் நீக்கு';

  @override
  String get areYouSureYouWantTo2 =>
      'எல்லா நிர்வாக அறிவிப்புகளையும் நீக்க வேண்டுமா?';

  @override
  String notificationSDeleted(String docs) {
    return '$docs அறிவிப்புகள் நீக்கப்பட்டன';
  }

  @override
  String deleteFailed(String e) {
    return 'நீக்குதல் தோல்வி: $e';
  }

  @override
  String get balajiPointsAdminPanel => 'Balaji Points - நிர்வாகப் பலகை';

  @override
  String get branchAdmin => 'கிளை நிர்வாகி';

  @override
  String get spin => 'சுழற்சி';

  @override
  String get pointsRepair => 'புள்ளி சரிசெய்தல்';

  @override
  String get duplicateAccounts => 'நகல் கணக்குகள்';

  @override
  String get exportUsers => 'பயனர்களை ஏற்றுமதி செய்';

  @override
  String get cleanUp => 'சுத்தம் செய்';

  @override
  String get backupDatabase => 'தரவுத்தள காப்புப்பிரதி';

  @override
  String get checkFirebaseDuplicates => 'தரவுத்தள நகல்களைச் சரிபார்';

  @override
  String get smartCleanup => 'ஸ்மார்ட் சுத்தம்';

  @override
  String get sendGreeting => 'வாழ்த்து அனுப்பு';

  @override
  String get users2 => 'பயனர்கள் - ...';

  @override
  String users3(String count) {
    return 'பயனர்கள் - $count';
  }

  @override
  String get pleaseEnterPinInBothFields => 'இரு புலங்களிலும் PIN-ஐ உள்ளிடவும்';

  @override
  String get pinMustBe46Digits => 'PIN 4-6 இலக்கங்களாக இருக்க வேண்டும்';

  @override
  String get pinMustContainOnlyNumbers =>
      'PIN-இல் எண்கள் மட்டுமே இருக்க வேண்டும்';

  @override
  String get pinResetSuccessfully => 'PIN மீட்டமைக்கப்பட்டது';

  @override
  String errorResettingPin(String e) {
    return 'PIN மீட்டமைப்பதில் பிழை: $e';
  }

  @override
  String resetPinFor(String carpenterName) {
    return 'இவரின் PIN-ஐ மீட்டமை: $carpenterName';
  }

  @override
  String phone2(String carpenterPhone) {
    return 'தொலைபேசி: $carpenterPhone';
  }

  @override
  String get carpenterWillNeedToUseThis =>
      'தச்சர் இந்தப் புதிய PIN மூலம் உள்நுழைய வேண்டும். அதைப் பாதுகாப்பாகத் தெரிவிக்கவும்.';

  @override
  String get newPin46Digits => 'புதிய PIN (4-6 இலக்கங்கள்)';

  @override
  String get carpenterDetails => 'தச்சர் விவரங்கள்';

  @override
  String get carpenterNotFound => 'தச்சர் கிடைக்கவில்லை';

  @override
  String get carpenterInformation => 'தச்சர் தகவல்';

  @override
  String get branch => 'கிளை';

  @override
  String get completeHistory => 'முழு வரலாறு';

  @override
  String get clearAll => 'அனைத்தையும் அழி';

  @override
  String get fromDate => 'தொடக்கத் தேதி';

  @override
  String get toDate => 'இறுதித் தேதி';

  @override
  String get editCarpenter => 'தச்சரைத் திருத்து';

  @override
  String get changingPhoneNumberWillUpdateLogin =>
      'தொலைபேசி எண்ணை மாற்றினால் உள்நுழைவு விவரம் மாறும்';

  @override
  String get branchId => 'கிளை ஐடி';

  @override
  String get phoneNumberCannotBeEmpty => 'தொலைபேசி எண் காலியாக இருக்கக்கூடாது';

  @override
  String get carpenterUpdatedSuccessfully => 'தச்சர் புதுப்பிக்கப்பட்டார்';

  @override
  String errorUpdatingCarpenter(String e) {
    return 'தச்சரைப் புதுப்பிப்பதில் பிழை: $e';
  }

  @override
  String get update => 'புதுப்பி';

  @override
  String get pendingBillRequests => 'நிலுவை பில் கோரிக்கைகள்';

  @override
  String get siteMaterialPurchase => 'தளப் பொருள் கொள்முதல்';

  @override
  String billNo2(String billNumber) {
    return 'பில் எண் $billNumber';
  }

  @override
  String site3(String siteName) {
    return 'தளம்: $siteName';
  }

  @override
  String pts7(String amount) {
    return '+$amount புள்ளிகள்';
  }

  @override
  String approveThisBillOfPointsWill2(String amount, String amount2) {
    return '₹$amount பில்லை அனுமதிக்கவா?\n\n$amount2 புள்ளிகள் சேர்க்கப்படும்.';
  }

  @override
  String get noHistoryFound => 'வரலாறு கிடைக்கவில்லை';

  @override
  String get pointsAwarded => 'புள்ளிகள் வழங்கப்பட்டன';

  @override
  String get pinMustBeAtLeast4 => 'PIN குறைந்தது 4 இலக்கங்கள் இருக்க வேண்டும்';

  @override
  String get carpenterCreatedSuccessfully => 'தச்சர் உருவாக்கப்பட்டார்!';

  @override
  String get failedToCreateCarpenter => 'தச்சரை உருவாக்க முடியவில்லை';

  @override
  String get pin46Digits => '4 இலக்க PIN';

  @override
  String get enterPin => 'PIN உள்ளிடவும்';

  @override
  String get firstNameOptional => 'முதல் பெயர் (விருப்பம்)';

  @override
  String get enterFirstName => 'முதல் பெயர் உள்ளிடவும்';

  @override
  String get lastNameOptional => 'குடும்பப் பெயர் (விருப்பம்)';

  @override
  String get enterLastName => 'கடைசி பெயர் உள்ளிடவும்';

  @override
  String get create => 'உருவாக்கு';

  @override
  String get preparingCarpenterListPdf => 'தச்சர் பட்டியல் PDF தயாராகிறது...';

  @override
  String get noCarpentersToExportForCurrent =>
      'தற்போதைய வடிகட்டியில் ஏற்றுமதிக்கு தச்சர்கள் இல்லை.';

  @override
  String get carpenterListExportedSuccessfully =>
      'தச்சர் பட்டியல் ஏற்றுமதி செய்யப்பட்டது!';

  @override
  String errorExportingPdf(String e) {
    return 'PDF ஏற்றுமதியில் பிழை: $e';
  }

  @override
  String get exportCarpenterListToPdf => 'தச்சர் பட்டியலை PDF-ஆக ஏற்றுமதி செய்';

  @override
  String get sortByPoints => 'புள்ளிகளால் வரிசைப்படுத்து';

  @override
  String get sortByName => 'பெயரால் வரிசைப்படுத்து';

  @override
  String get recentJoins => 'சமீபத்தில் சேர்ந்தவர்கள்';

  @override
  String tier(String tier) {
    return 'நிலை: $tier';
  }

  @override
  String phoneTierPoints(String phone, String tier, String totalPoints) {
    return 'தொலைபேசி: $phone\nநிலை: $tier\nபுள்ளிகள்: $totalPoints';
  }

  @override
  String points2(String num) {
    return '$num புள்ளிகள்';
  }

  @override
  String get deleteAll2 => 'அனைத்தையும் நீக்கு';

  @override
  String get unableToLoadAdminNotifications =>
      'நிர்வாக அறிவிப்புகளை ஏற்ற முடியவில்லை';

  @override
  String get noNotifications => 'அறிவிப்புகள் இல்லை';

  @override
  String get youDonTHaveAnyAdmin => 'இன்னும் நிர்வாக அறிவிப்புகள் இல்லை';

  @override
  String get deleteNotification2 => 'அறிவிப்பை நீக்கு';

  @override
  String get dailySpinHistory => 'தினசரி சுழற்சி வரலாறு';

  @override
  String text(String month, String year) {
    return '$month $year';
  }

  @override
  String get mon => 'திங்';

  @override
  String get tue => 'செவ்';

  @override
  String get wed => 'புத';

  @override
  String get thu => 'வியா';

  @override
  String get fri => 'வெள்';

  @override
  String get sat => 'சனி';

  @override
  String get spinned => 'சுழற்றப்பட்டது';

  @override
  String get noSpin => 'சுழற்சி இல்லை';

  @override
  String get unknown => 'தெரியவில்லை';

  @override
  String get spinWinner => 'சுழற்சி வெற்றியாளர்';

  @override
  String get winnerName => 'வெற்றியாளர் பெயர்';

  @override
  String failedToFetchCarpenters(String e) {
    return 'தச்சர்களைப் பெற முடியவில்லை: $e';
  }

  @override
  String failedToPickImage2(String e) {
    return 'படத்தைத் தேர்ந்தெடுக்க முடியவில்லை: $e';
  }

  @override
  String failedToCaptureImage(String e) {
    return 'படம் எடுக்க முடியவில்லை: $e';
  }

  @override
  String failedToUploadImage(String e) {
    return 'படத்தைப் பதிவேற்ற முடியவில்லை: $e';
  }

  @override
  String notificationSentToCarpenters(String notificationCount) {
    return '$notificationCount தச்சர்களுக்கு அறிவிப்பு அனுப்பப்பட்டது';
  }

  @override
  String failedToSendNotifications(String e) {
    return 'அறிவிப்புகளை அனுப்ப முடியவில்லை: $e';
  }

  @override
  String get pleaseEnterAMessage => 'தயவுசெய்து செய்தியை உள்ளிடவும்';

  @override
  String get pleaseSelectAtLeastOneChannel =>
      'குறைந்தது ஒரு வழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get notAuthenticated => 'அங்கீகரிக்கப்படவில்லை';

  @override
  String get showInApp => 'ஆப்பில் காட்டு';

  @override
  String get greetingSentSuccessfully => 'வாழ்த்து அனுப்பப்பட்டது!';

  @override
  String get sendingGreeting => 'வாழ்த்து அனுப்பப்படுகிறது...';

  @override
  String get composeMessage => 'செய்தியை எழுது';

  @override
  String get enterGreetingMessageForAllCarpenters => 'செய்தி உள்ளிடவும்';

  @override
  String get imageOptional => 'படம் (விருப்பம்)';

  @override
  String get pickFromGallery => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get orEnterImageUrl => 'அல்லது பட URL-ஐ உள்ளிடவும்:';

  @override
  String get enterImageUrlJpgPng => 'பட URL உள்ளிடவும்';

  @override
  String get invalidImageUrl => 'தவறான பட URL';

  @override
  String get selectChannels => 'வழிகளைத் தேர்ந்தெடு';

  @override
  String get showInAppHomeBanner => 'ஆப்பில் காட்டு (முகப்பு பேனர்)';

  @override
  String get bannerOnCarpenterHomeScreen => 'தச்சர் முகப்புத் திரையில் பேனர்';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get manualSendViaWhatsappApp => 'WhatsApp ஆப் மூலம் கைமுறையாக அனுப்பு';

  @override
  String get manualSendViaSmsApp => 'SMS ஆப் மூலம் கைமுறையாக அனுப்பு';

  @override
  String get noteWhatsappAndSmsUseDevice =>
      'குறிப்பு: WhatsApp மற்றும் SMS சாதன ஆப் மூலம் அனுப்பப்படும். ஒவ்வொரு செய்தியையும் நிர்வாகி அந்த ஆப்பில் உறுதிப்படுத்த வேண்டும்.';

  @override
  String whatsappNotAvailableFor(String name) {
    return '$name-க்கு WhatsApp கிடைக்கவில்லை';
  }

  @override
  String smsNotAvailableFor(String name) {
    return '$name-க்கு SMS கிடைக்கவில்லை';
  }

  @override
  String get sendToAll => 'அனைவருக்கும் அனுப்பவா?';

  @override
  String get continueLabel => 'தொடர்';

  @override
  String progress(String i, String carpenters) {
    return 'முன்னேற்றம்: $i/$carpenters';
  }

  @override
  String opened(String name, String phone) {
    return 'திறக்கப்பட்டது: $name\n$phone';
  }

  @override
  String get tapSendInTheAppThen =>
      'ஆப்பில் அனுப்பு தட்டி, தொடர இங்கே OK தட்டவும்.';

  @override
  String sentToAllCarpenters(String sentCount) {
    return 'அனைத்து $sentCount தச்சர்களுக்கும் அனுப்பப்பட்டது';
  }

  @override
  String get confirmSend => 'அனுப்புவதை உறுதிப்படுத்து';

  @override
  String get sendAll => 'அனைத்தையும் அனுப்பு';

  @override
  String get sendViaWhatsapp => 'WhatsApp மூலம் அனுப்பு';

  @override
  String get sendViaSms => 'SMS மூலம் அனுப்பு';

  @override
  String get pleaseWait24HoursFromThe =>
      'கடைசி சுழற்சியிலிருந்து 24 மணிநேரம் காத்திருக்கவும்';

  @override
  String get noCarpentersWithApprovedBillsToday =>
      'இன்று அனுமதிக்கப்பட்ட பில்களுடன் தச்சர்கள் இல்லை';

  @override
  String get noEligibleCarpentersFound => 'தகுதியான தச்சர்கள் இல்லை';

  @override
  String isTodaySWinner(String carpenterName) {
    return '$carpenterName இன்றைய வெற்றியாளர்!';
  }

  @override
  String get selectALuckyWinner => 'அதிர்ஷ்ட வெற்றியாளரைத் தேர்ந்தெடு';

  @override
  String get viewSpinHistory => 'சுழற்சி வரலாற்றைப் பார்';

  @override
  String winner2(String winnerName) {
    return 'வெற்றியாளர்: $winnerName';
  }

  @override
  String get noPreviousSpins => 'முந்தைய சுழற்சிகள் இல்லை';

  @override
  String get readyToSpin => 'சுழற்றத் தயார்!';

  @override
  String nextSpinInHM(String hoursRemaining, String minutesRemaining) {
    return 'அடுத்த சுழற்சி: $hoursRemainingம $minutesRemainingநி-இல்';
  }

  @override
  String get todaySWinners => 'இன்றைய வெற்றியாளர்கள்';

  @override
  String get noWinnersYetToday => 'இன்று இன்னும் வெற்றியாளர்கள் இல்லை';

  @override
  String get monthlyWinners => 'மாதாந்திர வெற்றியாளர்கள்';

  @override
  String get fullHistory => 'முழு வரலாறு';

  @override
  String get noWinnersThisMonthYet => 'இந்த மாதம் இன்னும் வெற்றியாளர்கள் இல்லை';

  @override
  String get untitled => 'தலைப்பில்லை';

  @override
  String get pleaseEnterAValidNumberFor =>
      'புள்ளிகளுக்குச் சரியான எண்ணை உள்ளிடவும்';

  @override
  String get pleaseUploadABannerImage => 'பேனர் படத்தைப் பதிவேற்றவும்';

  @override
  String get failedToUploadBannerImage => 'பேனர் படத்தைப் பதிவேற்ற முடியவில்லை';

  @override
  String get loadingEligibleCarpenters =>
      'தகுதியான தச்சர்கள் ஏற்றப்படுகின்றனர்...';

  @override
  String get errorLoadingData => 'தரவை ஏற்றுவதில் பிழை';

  @override
  String get noEligibleCarpentersToday => 'இன்று தகுதியான தச்சர்கள் இல்லை';

  @override
  String get noCarpentersHaveApprovedBillsToday =>
      'இன்று எந்தத் தச்சருக்கும் பில் அனுமதிக்கப்படவில்லை.\nதினசரி சுழற்சிக்குத் தகுதிபெற பில்களை அனுமதிக்கவும்!';

  @override
  String get todaySEligibleCarpenters => 'இன்றைய தகுதியான தச்சர்கள்';

  @override
  String eligible(String todayStr, String carpenters) {
    return '$todayStr • $carpenters தகுதியானவர்கள்';
  }

  @override
  String get branchAdminAccounts => 'கிளை நிர்வாகி கணக்குகள்';

  @override
  String get reviewEachAdminAndTheBranch =>
      'ஒவ்வொரு நிர்வாகியையும் அவரது கிளையையும் பாருங்கள். கடவுச்சொல்லை மாற்றலாம் அல்லது கணக்கை நீக்கலாம்.';

  @override
  String get searchByNameEmailOrBranch => 'நிர்வாகிகளைத் தேடு';

  @override
  String get clearSearch => 'தேடலை அழி';

  @override
  String get loadingBranchAdminAccounts =>
      'கிளை நிர்வாகி கணக்குகள் ஏற்றப்படுகின்றன…';

  @override
  String get noBranchAdminAccountsYet =>
      'இன்னும் கிளை நிர்வாகி கணக்குகள் இல்லை.';

  @override
  String get loadingBranchNames => 'கிளைப் பெயர்கள் ஏற்றப்படுகின்றன…';

  @override
  String get noEmail => 'மின்னஞ்சல் இல்லை';

  @override
  String noAdminAccountsMatch(String search) {
    return '“$search”-க்குப் பொருந்தும் நிர்வாகக் கணக்குகள் இல்லை.';
  }

  @override
  String get adminAccounts => 'நிர்வாகக் கணக்குகள்';

  @override
  String passwordUpdatedFor(String email) {
    return '$email-இன் கடவுச்சொல் புதுப்பிக்கப்பட்டது.';
  }

  @override
  String get deleteBranchAdmin => 'கிளை நிர்வாகியை நீக்கவா?';

  @override
  String deleteForTheyWillLoseSign(String email, String branchName) {
    return '$branchName-க்கான $email-ஐ நீக்கவா? அவர் உள்நுழைய முடியாது. கிளை உறுப்பினர்களும் அவர்களின் புள்ளிகளும் இருக்கும்.';
  }

  @override
  String get deleteAdmin => 'நிர்வாகியை நீக்கு';

  @override
  String get adminAccountDeleted => 'நிர்வாகக் கணக்கு நீக்கப்பட்டது.';

  @override
  String get changePassword => 'கடவுச்சொல்லை மாற்று';

  @override
  String get deleteAccount => 'கணக்கை நீக்கு';

  @override
  String get changeAdminPassword => 'நிர்வாகி கடவுச்சொல்லை மாற்று';

  @override
  String get newPassword => 'புதிய கடவுச்சொல்';

  @override
  String get useAtLeast8Characters => 'குறைந்தது 8 எழுத்துகள் பயன்படுத்தவும்';

  @override
  String get confirmNewPassword => 'புதிய கடவுச்சொல்லை உறுதிப்படுத்து';

  @override
  String get updatePassword => 'கடவுச்சொல்லைப் புதுப்பி';

  @override
  String get tryAgain => 'மீண்டும் முயற்சி';

  @override
  String get branchManagement => 'கிளை மேலாண்மை';

  @override
  String branchesManageBranchAccessAndStatus(String docs) {
    return '$docs கிளைகள் · கிளை அணுகல் மற்றும் நிலையை நிர்வகி';
  }

  @override
  String get addBranch => 'கிளையைச் சேர்';

  @override
  String get noBranchesYet => 'இன்னும் கிளைகள் இல்லை.';

  @override
  String get branchesCouldNotBeLoaded => 'கிளைகளை ஏற்ற முடியவில்லை.';

  @override
  String get diwaliCelebrationEnabledAddBillIs =>
      'தீபாவளி கொண்டாட்டம் இயக்கப்பட்டது. இந்தக் கிளையில் பில் சேர் மறைக்கப்பட்டது.';

  @override
  String get diwaliCelebrationDisabledAddBillIs =>
      'தீபாவளி கொண்டாட்டம் முடக்கப்பட்டது. இந்தக் கிளையில் பில் சேர் கிடைக்கிறது.';

  @override
  String get unableToUpdateTheBranchCelebration =>
      'கிளை கொண்டாட்ட அமைப்பைப் புதுப்பிக்க முடியவில்லை.';

  @override
  String codeId(String branchCode, String branchId) {
    return 'குறியீடு: $branchCode  ·  ஐடி: $branchId';
  }

  @override
  String get diwaliCelebrationOnHome => 'முகப்பில் தீபாவளி கொண்டாட்டம்';

  @override
  String get showsTheBranchPrizeListAnd =>
      'கிளைப் பரிசுப் பட்டியலைக் காட்டி பில் சேர்-ஐ மறைக்கும்.';

  @override
  String get offNoPopupAddBillRemains =>
      'முடக்கம்: பாப்அப் இல்லை; பில் சேர் கிடைக்கும்.';

  @override
  String get branchDeactivated => 'கிளை செயலிழக்கப்பட்டது.';

  @override
  String get branchActivated => 'கிளை செயல்படுத்தப்பட்டது.';

  @override
  String get unableToUpdateTheBranch => 'கிளையைப் புதுப்பிக்க முடியவில்லை.';

  @override
  String get deactivate => 'செயலிழக்கச் செய்';

  @override
  String get activate => 'செயல்படுத்து';

  @override
  String branchCreated(String id) {
    return 'கிளை உருவாக்கப்பட்டது ($id)';
  }

  @override
  String get failedToCreateBranch => 'கிளையை உருவாக்க முடியவில்லை';

  @override
  String get newBranch => 'புதிய கிளை';

  @override
  String get branchFullName => 'கிளையின் முழுப் பெயர் *';

  @override
  String get shortName => 'சுருக்கப் பெயர் *';

  @override
  String get enterAShortBranchName => 'கிளையின் சுருக்கப் பெயரை உள்ளிடவும்';

  @override
  String get branchCode => 'கிளைக் குறியீடு *';

  @override
  String get use216LettersNumbersOr =>
      '2–16 எழுத்துகள், எண்கள் அல்லது இடைக்கோடுகள்';

  @override
  String get address => 'முகவரி';

  @override
  String get shareTheTemporaryPasswordSecurelyThe =>
      'தற்காலிக கடவுச்சொல்லைப் பாதுகாப்பாகப் பகிருங்கள். முதல் உள்நுழைவுக்குப் பின் நிர்வாகி அதை மாற்றலாம்.';

  @override
  String adminCreatedForTheyCanSign(String email, String branchName) {
    return '$branchName-க்கு நிர்வாகி $email உருவாக்கப்பட்டார். மின்னஞ்சல், கடவுச்சொல் மூலம் உள்நுழையலாம்.';
  }

  @override
  String get selectABranchFirst => 'முதலில் கிளையைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get adminDetails => 'நிர்வாகி விவரங்கள்';

  @override
  String get mobileNumber10Digits => 'மொபைல் எண் * (10 இலக்கங்கள்)';

  @override
  String get enterValid10DigitPhone => 'சரியான 10 இலக்க தொலைபேசி எண்';

  @override
  String get emailAndPasswordLogin => 'மின்னஞ்சல், கடவுச்சொல் உள்நுழைவு';

  @override
  String get emailAddress => 'மின்னஞ்சல் முகவரி *';

  @override
  String get temporaryPassword8CharactersMinimum =>
      'தற்காலிக கடவுச்சொல் * (குறைந்தது 8 எழுத்துகள்)';

  @override
  String get confirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்து *';

  @override
  String get assignBranch => 'கிளையை ஒதுக்கு';

  @override
  String get loadingActiveBranches => 'செயலில் உள்ள கிளைகள் ஏற்றப்படுகின்றன…';

  @override
  String get noActiveBranchesFoundCreateOr =>
      'செயலில் உள்ள கிளைகள் இல்லை. நிர்வாகியைச் சேர்க்கும் முன் கிளையை உருவாக்கவும் அல்லது செயல்படுத்தவும்.';

  @override
  String get selectBranch => 'கிளையைத் தேர்ந்தெடு';

  @override
  String get creatingAccount => 'கணக்கு உருவாக்கப்படுகிறது…';

  @override
  String get createAdminAccount => 'நிர்வாகக் கணக்கை உருவாக்கு';

  @override
  String get signOutOfSuperAdmin => 'சூப்பர் நிர்வாகியிலிருந்து வெளியேறவா?';

  @override
  String get superAdmin => 'சூப்பர் நிர்வாகி';

  @override
  String get superAdminConsole => 'சூப்பர் நிர்வாகக் கன்சோல்';

  @override
  String get branchesAdministratorsAndPoints =>
      'கிளைகள், நிர்வாகிகள், புள்ளிகள்';

  @override
  String get branches => 'கிளைகள்';

  @override
  String get createAdmin => 'நிர்வாகியை உருவாக்கு';

  @override
  String get roles => 'பங்குகள்';

  @override
  String get superAdmin2 => 'சூப்பர் நிர்வாகி';

  @override
  String get createAdmin2 => 'நிர்வாகியை உருவாக்கு';

  @override
  String get pointsReset => 'புள்ளி மீட்டமைப்பு';

  @override
  String get onlyPointsTiersAndPointsHistory =>
      'தச்சர்கள், கட்டடக் கலைஞர்கள், பொறியாளர்கள், உள்ளக வடிவமைப்பாளர்களின் புள்ளிகள், நிலைகள், வரலாறு மட்டுமே அழிக்கப்படும். கணக்குகள், உள்நுழைவு, கிளை நிர்வாகிகள், பில்கள் மாறாது.';

  @override
  String get afterPrizeDistributionStartAFresh =>
      'பரிசு வழங்கிய பின் ஒரு கிளைக்குப் புதிய புள்ளிப் பருவத்தைத் தொடங்குங்கள்.';

  @override
  String resetUsersAndDeletedHistoryRecords(
    String branchName,
    String usersReset,
    String historyDocumentsDeleted,
  ) {
    return '$branchName: $usersReset பயனர்கள் மீட்டமைக்கப்பட்டு $historyDocumentsDeleted வரலாற்றுப் பதிவுகள் நீக்கப்பட்டன. கணக்குகளும் பில்களும் உள்ளன.';
  }

  @override
  String get thisPermanentlyClearsPointsAndPoints =>
      'இது இந்தக் கிளையின் தச்சர்கள், கட்டடக் கலைஞர்கள், பொறியாளர்கள், உள்ளக வடிவமைப்பாளர்களின் புள்ளிகளையும் வரலாற்றையும் நிரந்தரமாக அழிக்கும். பயனர் கணக்குகள், கிளை நிர்வாகிகள், பில்கள் இருக்கும்.';

  @override
  String hasEligibleUsersPointsAndHistory(
    String branchName,
    String eligibleUsers,
    String currentPoints,
    String historyDocuments,
  ) {
    return '$branchName-இல் $eligibleUsers தகுதியான பயனர்கள், $currentPoints புள்ளிகள், $historyDocuments வரலாற்றுப் பதிவுகள் உள்ளன.';
  }

  @override
  String get resetBranchPoints => 'கிளைப் புள்ளிகளை மீட்டமைக்கவா?';

  @override
  String typeToConfirm(String branchId) {
    return 'உறுதிப்படுத்த $branchId என தட்டச்சு செய்யவும்';
  }

  @override
  String get resetPointsAndHistory => 'புள்ளிகளையும் வரலாற்றையும் மீட்டமை';

  @override
  String get couldNotLoadBranchesForPoints =>
      'புள்ளி சுத்தத்திற்கான கிளைகளை ஏற்ற முடியவில்லை.';

  @override
  String get annualPointsReset => 'வருடாந்திர புள்ளி மீட்டமைப்பு';

  @override
  String get branchToReset => 'மீட்டமைக்க வேண்டிய கிளை';

  @override
  String get checkingBranch => 'கிளை சரிபார்க்கப்படுகிறது…';

  @override
  String get previewReset => 'மீட்டமைப்பு முன்னோட்டம்';

  @override
  String get createABranchBeforeResettingPoints =>
      'புள்ளிகளை மீட்டமைக்கும் முன் கிளையை உருவாக்கவும்.';

  @override
  String cleanupPreview(String branchName) {
    return 'சுத்த முன்னோட்டம் · $branchName';
  }

  @override
  String get eligibleUsers => 'தகுதியான பயனர்கள்';

  @override
  String get currentPoints => 'தற்போதைய புள்ளிகள்';

  @override
  String get historyItems => 'வரலாற்றுப் பதிவுகள்';

  @override
  String get resettingBranchPoints => 'கிளைப் புள்ளிகள் மீட்டமைக்கப்படுகின்றன…';

  @override
  String couldNotLoadSavedRolesShowing(String loadError) {
    return 'சேமித்த பங்குகளை ஏற்ற முடியவில்லை. நான்கு இயல்பு பங்குகள் காட்டப்படுகின்றன. $loadError';
  }

  @override
  String get roleIdsAreStoredWithUser =>
      'பங்கு ஐடிகள் பயனர் கணக்குகளுடன் சேமிக்கப்படும். பங்கை நீக்கினால் புதிய பதிவுகளிலிருந்து நீங்கும்; தற்போதைய கணக்குகள் இருக்கும்.';

  @override
  String willBeRemovedFromNewRegistration(String name) {
    return '$name புதிய பதிவிலிருந்து நீக்கப்படும். தற்போதைய பயனர்களின் பங்கும் தரவும் இருக்கும்.';
  }

  @override
  String roleCreated(String name, String id) {
    return 'பங்கு உருவாக்கப்பட்டது: $name ($id).';
  }

  @override
  String get restoreRole => 'பங்கை மீட்டெடுக்கவா?';

  @override
  String get deleteRole => 'பங்கை நீக்கவா?';

  @override
  String willBeAvailableForNewAccount(String name) {
    return '$name புதிய கணக்குப் பதிவுக்குக் கிடைக்கும்.';
  }

  @override
  String get restoreRole2 => 'பங்கை மீட்டெடு';

  @override
  String get deleteRole2 => 'பங்கை நீக்கு';

  @override
  String get accountRoles => 'கணக்குப் பங்குகள்';

  @override
  String get manageTheRolesShownInCreate =>
      'கணக்கு உருவாக்கத்தில் காட்டப்படும் பங்குகளை நிர்வகி.';

  @override
  String get addRole => 'பங்கைச் சேர்';

  @override
  String get loadingAccountRoles => 'கணக்குப் பங்குகள் ஏற்றப்படுகின்றன…';

  @override
  String get noRolesFound => 'பங்குகள் இல்லை.';

  @override
  String roleId(String id) {
    return 'பங்கு ஐடி: $id';
  }

  @override
  String get restore => 'மீட்டெடு';

  @override
  String get deleted => 'நீக்கப்பட்டது';

  @override
  String get addAccountRole => 'கணக்குப் பங்கைச் சேர்';

  @override
  String get roleName => 'பங்கின் பெயர் *';

  @override
  String get enterAtLeast2Characters => 'குறைந்தது 2 எழுத்துகள் உள்ளிடவும்';

  @override
  String get shortFormOptional => 'சுருக்க வடிவம் (விருப்பம்)';

  @override
  String get exampleAr => 'குறுக்கம் உள்ளிடவும்';

  @override
  String get use10CharactersOrLess => '10 அல்லது குறைவான எழுத்துகள்';

  @override
  String get saving => 'சேமிக்கப்படுகிறது…';

  @override
  String get saveRole => 'பங்கைச் சேமி';

  @override
  String get cleanUpDuplicates => 'நகல்களைச் சுத்தம் செய்';

  @override
  String error3(String error) {
    return 'பிழை: $error';
  }

  @override
  String get duplicatesFound => 'நகல்கள் கண்டறியப்பட்டன';

  @override
  String accountsAcrossPhoneNumbers(String duplicateCount, String duplicates) {
    return '$duplicates தொலைபேசி எண்களில் $duplicateCount கணக்குகள்';
  }

  @override
  String get noDuplicatesFound => 'நகல்கள் இல்லை!';

  @override
  String get allCarpenterAccountsAreUnique =>
      'எல்லா தச்சர் கணக்குகளும் தனித்துவமானவை.';

  @override
  String get duplicateGroups => 'நகல் குழுக்கள்';

  @override
  String phoneAccounts(String groupIndex, String phone, String users) {
    return '$groupIndex. தொலைபேசி: $phone ($users கணக்குகள்)';
  }

  @override
  String get keep => 'வைத்திரு';

  @override
  String get reviewOnly => 'சரிபார்ப்பு மட்டும்';

  @override
  String diagnosticUser(String phoneNumber) {
    return 'சோதனை: பயனர் $phoneNumber';
  }

  @override
  String get noData => 'தரவு இல்லை';

  @override
  String get phoneNumberInformation => 'தொலைபேசி எண் தகவல்';

  @override
  String get originalPhone => 'அசல் தொலைபேசி';

  @override
  String get normalizedPhone => 'தரப்படுத்திய தொலைபேசி';

  @override
  String get match => 'பொருத்தம்';

  @override
  String get userDocumentStatus => 'பயனர் ஆவண நிலை';

  @override
  String get existsByDocumentId => 'உள்ளது (ஆவண ஐடி மூலம்)';

  @override
  String get documentId => 'ஆவண ஐடி';

  @override
  String get phoneFieldInData => 'தொலைபேசி புலம் (தரவில்)';

  @override
  String get existsByPhoneFieldQuery => 'உள்ளது (தொலைபேசி தேடல் மூலம்)';

  @override
  String get documentIdFromQuery => 'ஆவண ஐடி (தேடலிலிருந்து)';

  @override
  String get issueDetected => 'சிக்கல் கண்டறியப்பட்டது';

  @override
  String get documentIdMismatch => 'ஆவண ஐடி பொருந்தவில்லை!';

  @override
  String get userDocumentFound => 'பயனர் ஆவணம் கிடைத்தது';

  @override
  String get userDocumentNotFound => 'பயனர் ஆவணம் கிடைக்கவில்லை';

  @override
  String get billsCollectionStatus => 'பில் தொகுப்பு நிலை';

  @override
  String get phoneFormatMismatchInBills =>
      'பில்களில் தொலைபேசி வடிவம் பொருந்தவில்லை!';

  @override
  String get phoneFormatConsistent => 'தொலைபேசி வடிவம் சரியாக உள்ளது';

  @override
  String get pendingBillsStatus => 'நிலுவை பில்களின் நிலை';

  @override
  String get totalPendingBills => 'மொத்த நிலுவை பில்கள்';

  @override
  String get matchingBillsFound => 'பொருந்தும் பில்கள்';

  @override
  String get noPendingBillsFoundForThis =>
      'இந்தப் பயனருக்கு நிலுவை பில்கள் இல்லை!';

  @override
  String get carpenterId => 'தச்சர் ஐடி';

  @override
  String get carpenterPhone => 'தச்சர் தொலைபேசி';

  @override
  String get isToday => 'இன்றையதா';

  @override
  String get createdAt => 'உருவாக்கியது';

  @override
  String get thisBillWonTShowIn =>
      'இந்த பில் இயல்பு நிர்வாகப் பார்வையில் தெரியாது (இன்றையது அல்ல)';

  @override
  String get totalAccounts => 'மொத்த கணக்குகள்';

  @override
  String get duplicatePhones => 'நகல் தொலைபேசிகள்';

  @override
  String get affectedAccounts => 'பாதிக்கப்பட்ட கணக்குகள்';

  @override
  String get noDuplicateAccountsFound => 'நகல் கணக்குகள் இல்லை!';

  @override
  String get duplicatePhoneNumbers => 'நகல் தொலைபேசி எண்கள்';

  @override
  String account(String idx) {
    return 'கணக்கு $idx';
  }

  @override
  String get review => 'சரிபார்';

  @override
  String get preparingUserBackupPdf => 'பயனர் காப்புப்பிரதி PDF தயாராகிறது...';

  @override
  String get noCarpentersFound2 => 'தச்சர்கள் இல்லை.';

  @override
  String userBackupExportedSuccessfullyCarpenters(String users) {
    return 'பயனர் காப்புப்பிரதி ஏற்றுமதி செய்யப்பட்டது! ($users தச்சர்கள்)';
  }

  @override
  String get exportUsersBackup => 'பயனர் காப்புப்பிரதி ஏற்றுமதி';

  @override
  String get createUserBackup => 'பயனர் காப்புப்பிரதியை உருவாக்கு';

  @override
  String get exportAllCarpentersWithTheirPoints =>
      'சுத்தத்திற்கு முன் எல்லா தச்சர்களையும் புள்ளிகள், தொலைபேசி எண்களுடன் ஏற்றுமதி செய்.';

  @override
  String get exporting => 'ஏற்றுமதி செய்யப்படுகிறது...';

  @override
  String get exportToPdf => 'PDF-ஆக ஏற்றுமதி செய்';

  @override
  String get pdfWillInclude => 'PDF-இல் இருக்கும்:';

  @override
  String get carpenterNameAndPhoneNumberTotal =>
      '• தச்சர் பெயர், தொலைபேசி எண்\n• மொத்த மற்றும் பெற்ற புள்ளிகள்\n• கணக்கு உருவாக்கிய தேதி\n• மொத்த தச்சர்கள், மொத்தப் புள்ளிகள் சுருக்கம்';

  @override
  String get firebaseDuplicateCheck => 'தரவுத்தள நகல் சோதனை';

  @override
  String get firebaseDatabaseSummary => 'தரவுத்தள சுருக்கம்';

  @override
  String get totalCarpenters2 => 'மொத்த தச்சர்கள்:';

  @override
  String get uniquePhoneNumbers => 'தனித்துவமான தொலைபேசி எண்கள்:';

  @override
  String get duplicatePhoneNumbers2 => 'நகல் தொலைபேசி எண்கள்:';

  @override
  String get totalDuplicateAccounts => 'மொத்த நகல் கணக்குகள்:';

  @override
  String get allPhoneNumbersAreUnique =>
      'எல்லா தொலைபேசி எண்களும் தனித்துவமானவை.';

  @override
  String get duplicateMobileNumbers => 'நகல் மொபைல் எண்கள்';

  @override
  String mobile2(String groupIndex, String totalGroups, String phone) {
    return '$groupIndex/$totalGroups - மொபைல்: $phone';
  }

  @override
  String accountsWithSamePhoneNumber(String users) {
    return 'ஒரே தொலைபேசி எண்ணுடன் $users கணக்குகள்';
  }

  @override
  String get main => 'முதன்மை';

  @override
  String get duplicate => 'நகல்';

  @override
  String get startingBackup => 'காப்புப்பிரதி தொடங்குகிறது...';

  @override
  String backupExportedUsersBills(String users, String bills) {
    return 'காப்புப்பிரதி ஏற்றுமதி: $users பயனர்கள், $bills பில்கள்';
  }

  @override
  String backupFailed(String e) {
    return 'காப்புப்பிரதி தோல்வி: $e';
  }

  @override
  String get backupData => 'காப்புப்பிரதி தரவு';

  @override
  String totalSizeKb(String backupJson) {
    return 'மொத்த அளவு: $backupJson KB';
  }

  @override
  String get firebaseBackup => 'தரவுத்தள காப்புப்பிரதி';

  @override
  String get databaseBackup => 'தரவுத்தள காப்புப்பிரதி';

  @override
  String get createACompleteBackupOfAll =>
      'எல்லா பயனர்கள் மற்றும் பில் தரவின் முழு காப்புப்பிரதியை உருவாக்கவும்.';

  @override
  String get whatWillBeBackedUp => 'காப்புப்பிரதியில் இருப்பவை:';

  @override
  String get allUserAccountsCarpentersAdminsAll =>
      '• எல்லா பயனர் கணக்குகளும் (தச்சர்கள் & நிர்வாகிகள்)\n• எல்லா பில் பதிவுகளும்\n• நேரத்துடன் முழு பயனர் தரவு\n• தரவுத்தள மெட்டாடேட்டா';

  @override
  String get backingUp => 'காப்புப்பிரதி எடுக்கப்படுகிறது...';

  @override
  String get startBackup => 'காப்புப்பிரதியைத் தொடங்கு';

  @override
  String get backupIsStoredInFirebaseNo =>
      'காப்புப்பிரதி சர்வரில் சேமிக்கப்படும். சாதனத்தில் கோப்புகள் சேமிக்கப்படாது.';

  @override
  String get repairDetails => 'சரிசெய்தல் விவரம்';

  @override
  String get verificationComplete => 'சரிபார்ப்பு முடிந்தது';

  @override
  String get noPointsLostAllUsersVerified =>
      'புள்ளிகள் இழக்கப்படவில்லை\nஎல்லா பயனர்களும் சரிபார்க்கப்பட்டனர்\nதரவு சரியாக உள்ளது';

  @override
  String get userWiseRepairResults => 'பயனர்வாரி சரிசெய்தல் முடிவுகள்';

  @override
  String get noRepairsCompleted => 'சரிசெய்தல்கள் இல்லை';

  @override
  String get repairComplete => 'சரிசெய்தல் முடிந்தது';

  @override
  String get successfullyRepaired => 'வெற்றிகரமாகச் சரிசெய்யப்பட்டது';

  @override
  String get failed => 'தோல்வி';

  @override
  String get duplicatesRemoved => 'நகல்கள் நீக்கப்பட்டன';

  @override
  String get pointsAdjusted => 'புள்ளிகள் சரிசெய்யப்பட்டன';

  @override
  String get before => 'முன்';

  @override
  String get after => 'பின்';

  @override
  String get repairFailed => 'சரிசெய்தல் தோல்வி';

  @override
  String get thisToolScansUserPointsData =>
      'இந்தக் கருவி புள்ளித் தரவைச் சரிபார்த்துச் சரிசெய்யும்:\n• நகல் வரலாற்றுப் பதிவுகள்\n• பொருந்தாத மொத்தப் புள்ளிகள்\n• தவறான நிலைகள்';

  @override
  String get pointsRepairTool => 'புள்ளி சரிசெய்தல் கருவி';

  @override
  String get pointsDataRepair => 'புள்ளித் தரவு சரிசெய்தல்';

  @override
  String get scanReport => 'ஸ்கேன் அறிக்கை';

  @override
  String get totalUsersScanned => 'ஸ்கேன் செய்த மொத்த பயனர்கள்';

  @override
  String get usersWithIssues => 'சிக்கல் உள்ள பயனர்கள்';

  @override
  String get usersWithDuplicates => 'நகல் உள்ள பயனர்கள்';

  @override
  String get totalDuplicateEntries => 'மொத்த நகல் பதிவுகள்';

  @override
  String get pointsMismatches => 'புள்ளி பொருத்தமின்மைகள்';

  @override
  String get viewFullScanDetails => 'முழு ஸ்கேன் விவரம் பார்';

  @override
  String get viewDetailedResults => 'விரிவான முடிவுகளைப் பார்';

  @override
  String get scanForIssues => 'சிக்கல்களை ஸ்கேன் செய்';

  @override
  String get scanAgain => 'மீண்டும் ஸ்கேன் செய்';

  @override
  String get repairAllUsers => 'எல்லா பயனர்களையும் சரிசெய்';

  @override
  String get noIssuesFoundAllUserData =>
      'சிக்கல்கள் இல்லை! எல்லாத் தரவும் சரியாக உள்ளது.';

  @override
  String scanFailed(String e) {
    return 'ஸ்கேன் தோல்வி: $e';
  }

  @override
  String get repairAllUsers2 => 'எல்லா பயனர்களையும் சரிசெய்யவா?';

  @override
  String get repair => 'சரிசெய்';

  @override
  String repairFailed2(String e) {
    return 'சரிசெய்தல் தோல்வி: $e';
  }

  @override
  String get scanningForIssues => 'சிக்கல்கள் ஸ்கேன் செய்யப்படுகின்றன...';

  @override
  String get analyzingAllUserPointsData =>
      'எல்லா பயனர் புள்ளித் தரவும் பகுப்பாய்வு செய்யப்படுகிறது';

  @override
  String get scanResultsFullDetails => 'ஸ்கேன் முடிவுகள் - முழு விவரம்';

  @override
  String get usersWithIssues2 => 'சிக்கல் உள்ள பயனர்கள்';

  @override
  String get noUsersWithIssuesFound => 'சிக்கல் உள்ள பயனர்கள் இல்லை';

  @override
  String get scanSummary => 'ஸ்கேன் சுருக்கம்';

  @override
  String get totalUsersScanned2 => 'ஸ்கேன் செய்த மொத்த பயனர்கள்';

  @override
  String get totalDuplicateEntries2 => 'மொத்த நகல் பதிவுகள்';

  @override
  String get totalPointsDifference => 'மொத்தப் புள்ளி வேறுபாடு';

  @override
  String duplicates(String duplicateCount) {
    return '$duplicateCount நகல்கள்';
  }

  @override
  String get historySum => 'வரலாற்றுக் கூட்டுத்தொகை';

  @override
  String get difference => 'வேறுபாடு';

  @override
  String get totalEntries => 'மொத்த பதிவுகள்';

  @override
  String get uniqueBills => 'தனித்துவமான பில்கள்';

  @override
  String get duplicateBills => 'நகல் பில்கள்:';

  @override
  String get smartDuplicateCleanup => 'ஸ்மார்ட் நகல் சுத்தம்';

  @override
  String get allCarpentersHaveUniquePhoneNumbers =>
      'எல்லா தச்சர்களுக்கும் தனித்துவமான தொலைபேசி எண்கள் உள்ளன.';

  @override
  String get potentialDuplicateAccountsReviewRequired =>
      'சாத்தியமான நகல் கணக்குகள் — சரிபார்ப்பு தேவை';

  @override
  String foundDuplicateMobileNumbers(String duplicateGroups) {
    return '$duplicateGroups நகல் மொபைல் எண்கள் கண்டறியப்பட்டன';
  }

  @override
  String accountsToReview(String totalForReview) {
    return 'சரிபார்க்க வேண்டிய கணக்குகள்: $totalForReview';
  }

  @override
  String get allRecordsAreRetainedTheHighest =>
      'எல்லாப் பதிவுகளும் வைக்கப்படும். அதிகப் புள்ளிகள் உள்ள சுயவிவரம் பரிந்துரைக்கப்பட்ட முதன்மைக் கணக்கு மட்டுமே.';

  @override
  String potentialDuplicateGroups(String duplicateGroups) {
    return 'சாத்தியமான நகல் குழுக்கள் ($duplicateGroups)';
  }

  @override
  String mobile3(String groupIndex, String phone) {
    return '$groupIndex. மொபைல்: $phone';
  }

  @override
  String similarAccountsPointsDiff(String reviewUsers, String pointsDiff) {
    return '$reviewUsers ஒத்த கணக்குகள் | புள்ளி வேறுபாடு: $pointsDiff';
  }

  @override
  String get suggestedPrimaryAccountHighestPoints =>
      'பரிந்துரைக்கப்பட்ட முதன்மைக் கணக்கு (அதிகப் புள்ளிகள்)';

  @override
  String get otherMatchingAccountsManualReviewRequired =>
      'பிற பொருந்தும் கணக்குகள் — கைமுறைச் சரிபார்ப்பு தேவை';

  @override
  String repairConfirmBody(String count) {
    return 'இது $count பயனர்களைச் சரிசெய்யும்:\n\n• நகல் வரலாற்றுப் பதிவுகள் நீக்கப்படும்\n• சரியான மொத்தம் மீண்டும் கணக்கிடப்படும்\n• நிலைகள் புதுப்பிக்கப்படும்\n\nஇதை எளிதில் திரும்பப் பெற முடியாது.';
  }

  @override
  String repairSuccess(String repaired, String total) {
    return '$repaired/$total பயனர்கள் வெற்றிகரமாகச் சரிசெய்யப்பட்டனர்!\nசரிபார்க்கப்பட்டது: புள்ளிகள் இழக்கப்படவில்லை';
  }

  @override
  String repairPartial(String repaired, String total) {
    return '$repaired/$total பயனர்கள் சரிசெய்யப்பட்டனர்.\nசில சரிபார்ப்புச் சிக்கல்கள் - பதிவுகளைப் பாருங்கள்';
  }

  @override
  String backupUsersCount(String count) {
    return 'பயனர்கள் ($count)';
  }

  @override
  String backupBillsCount(String count) {
    return 'பில்கள் ($count)';
  }

  @override
  String openAppForEachCarpenter(String app) {
    return 'இது ஒவ்வொரு தச்சருக்கும் $app-ஐத் திறக்கும்.\n\nஒவ்வொரு ஆப்பிலும் அனுப்பு என்பதைத் தட்ட வேண்டும்.\n\nதொடரவா?';
  }

  @override
  String roleIdPreview(String id) {
    return 'பங்கு ஐடி: $id';
  }

  @override
  String winnersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count வெற்றியாளர்கள்',
      one: '1 வெற்றியாளர்',
    );
    return '$_temp0';
  }

  @override
  String roleRestored(String name) {
    return 'பங்கு $name மீட்டெடுக்கப்பட்டது.';
  }

  @override
  String roleDeleted(String name) {
    return 'பங்கு $name நீக்கப்பட்டது.';
  }

  @override
  String get permissionDeniedSuperAdmin =>
      'அனுமதி மறுக்கப்பட்டது. தரவுத்தள விதிகள் வெளியிடப்பட்டுள்ளனவா, சரியான சூப்பர் நிர்வாகிக் கணக்கில் உள்நுழைந்துள்ளீர்களா எனச் சரிபார்க்கவும்.';

  @override
  String get roleEngineer => 'பொறியாளர்';

  @override
  String get roleBuiltInBadge => 'இயல்பு';

  @override
  String get roleCustomBadge => 'தனிப்பயன்';

  @override
  String get roleProtectedTooltip => 'தச்சர் முதன்மைப் பங்கு, நீக்க முடியாது';

  @override
  String rolesSummary(int active, int deleted) {
    return '$active செயலில் · $deleted நீக்கப்பட்டவை';
  }

  @override
  String get rolesLiveSync =>
      'மாற்றங்கள் எல்லா சாதனங்களின் பதிவிலும் உடனே தெரியும்.';

  @override
  String get roleIdHelp => 'பெயரிலிருந்து உருவாகும். பின்னர் மாற்ற முடியாது.';

  @override
  String get roleErrInvalidName =>
      '2–40 எழுத்துகள், குறைந்தது இரண்டு ஆங்கில எழுத்து அல்லது எண்கள் இருக்க வேண்டும்.';

  @override
  String get roleErrReserved =>
      'இந்தப் பெயர் நிர்வாகக் கணக்குகளுக்கு ஒதுக்கப்பட்டது.';

  @override
  String get roleErrBuiltIn =>
      'இது இயல்பு பங்குடன் பொருந்துகிறது. பட்டியலிலிருந்து மீட்டெடுக்கவும்.';

  @override
  String get roleErrDuplicate => 'இந்த ஐடியுடன் ஒரு பங்கு ஏற்கனவே உள்ளது.';

  @override
  String get roleErrProtected => 'தச்சர் முதன்மைப் பங்கு, நீக்க முடியாது.';

  @override
  String get roleShowAll => 'அனைத்தும்';

  @override
  String get roleShowActive => 'செயலில்';

  @override
  String get roleShowDeleted => 'நீக்கப்பட்டவை';

  @override
  String get noRolesInFilter => 'இந்தப் பார்வையில் பங்குகள் இல்லை.';

  @override
  String deactivateBranchTitle(String name) {
    return '$name-ஐ செயலிழக்கச் செய்யவா?';
  }

  @override
  String get deactivateBranchBody =>
      'மீண்டும் செயல்படுத்தும் வரை புதிய பயனர்கள் இந்தக் கிளையைத் தேர்வு செய்ய முடியாது, உறுப்பினர்கள் உள்நுழைய முடியாது. எந்தத் தரவும் நீக்கப்படாது.';

  @override
  String activateBranchTitle(String name) {
    return '$name-ஐ செயல்படுத்தவா?';
  }

  @override
  String get activateBranchBody =>
      'கிளை மீண்டும் பதிவுக்கும் உள்நுழைவுக்கும் கிடைக்கும்.';

  @override
  String get branchActions => 'கிளைச் செயல்கள்';

  @override
  String get copyBranchId => 'கிளை ஐடியை நகலெடு';

  @override
  String get branchIdCopied => 'கிளை ஐடி நகலெடுக்கப்பட்டது';

  @override
  String get celebrationOn => 'இயக்கம்';

  @override
  String get celebrationOff => 'முடக்கம்';

  @override
  String get createAdminSubtitle =>
      'ஒரு கிளையின் பில்களையும் தச்சர்களையும் நிர்வகிக்கும் கிளை நிர்வாகியைச் சேர்க்கவும்.';

  @override
  String get selectBranchRequired => 'கிளையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get addAdmin => 'நிர்வாகியைச் சேர்';

  @override
  String get branchAdminsTitle => 'கிளை நிர்வாகிகள்';

  @override
  String get adminsNav => 'நிர்வாகிகள்';

  @override
  String adminsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count நிர்வாகிகள்',
      one: '1 நிர்வாகி',
    );
    return '$_temp0';
  }

  @override
  String get adminActions => 'நிர்வாகிச் செயல்கள்';

  @override
  String get editBranch => 'கிளையைத் திருத்து';

  @override
  String get branchUpdated => 'கிளை புதுப்பிக்கப்பட்டது';

  @override
  String get branchCodeLocked =>
      'குறியீட்டை மாற்ற முடியாது — தற்போதைய உறுப்பினர்கள் இதனுடன் பதிவுசெய்துள்ளனர்.';

  @override
  String get editLabel => 'திருத்து';

  @override
  String get editRole => 'பங்கைத் திருத்து';

  @override
  String roleUpdated(String name) {
    return 'பங்கு $name புதுப்பிக்கப்பட்டது.';
  }

  @override
  String get roleIdLocked =>
      'பங்கு ஐடியை மாற்ற முடியாது — இது பயனர் கணக்குகளில் சேமிக்கப்பட்டுள்ளது.';

  @override
  String get roleActions => 'பங்குச் செயல்கள்';

  @override
  String get editAdmin => 'நிர்வாகியைத் திருத்து';

  @override
  String get editDetails => 'விவரங்களைத் திருத்து';

  @override
  String adminUpdated(String email) {
    return 'நிர்வாகி $email புதுப்பிக்கப்பட்டார்.';
  }

  @override
  String get adminBranchChangeNote =>
      'நிர்வாகியை வேறு கிளைக்கு மாற்றினால் தற்போதைய கிளையின் அணுகல் நீங்கும். ஒரு கிளைக்கு ஒரு நிர்வாகி மட்டுமே.';

  @override
  String get editsSyncNote =>
      'பெயர் மாற்றங்கள் ஒவ்வொரு உறுப்பினரின் சுயவிவரத்திலும் தானாக நகலெடுக்கப்படும்.';

  @override
  String get noBranchAssigned =>
      'உங்கள் கணக்கு இன்னும் எந்தக் கிளையுடனும் இணைக்கப்படவில்லை. சூப்பர் நிர்வாகியிடம் கிளையை ஒதுக்கச் சொல்லுங்கள்.';

  @override
  String get loadingBranch => 'உங்கள் கிளை ஏற்றப்படுகிறது…';

  @override
  String get offerPointsTarget => 'புள்ளி இலக்கு';

  @override
  String get offerDetails => 'சலுகை விவரங்கள்';

  @override
  String get offerInfo => 'சலுகை விவரங்கள்';

  @override
  String offerProgress(String have, String target) {
    return 'உங்களிடம் $target இல் $have புள்ளிகள் உள்ளன';
  }

  @override
  String offerPointsToGo(String points) {
    return 'இந்த சலுகைக்கு இன்னும் $points புள்ளிகள் தேவை';
  }

  @override
  String get offerTargetReached => 'இலக்கை அடைந்தீர்கள்!';

  @override
  String get offerTermsApply => '*விதிமுறைகள் மற்றும் நிபந்தனைகள் பொருந்தும்.';

  @override
  String get offerViewBanner => 'முழு பேனரைப் பார்';

  @override
  String get homeAnnouncements => 'அறிவிப்புகள்';

  @override
  String get legalTermsTitle => 'விதிமுறைகள் மற்றும் நிபந்தனைகள்';

  @override
  String get legalPrivacyTitle => 'தனியுரிமைக் கொள்கை';

  @override
  String legalLastUpdated(String date) {
    return 'கடைசியாகப் புதுப்பிக்கப்பட்டது: $date';
  }

  @override
  String get legalAgreePrefix => 'நான் ';

  @override
  String get legalAgreeAnd => ' மற்றும் ';

  @override
  String get legalAgreeSuffix => ' ஆகியவற்றைப் படித்து ஒப்புக்கொள்கிறேன்.';

  @override
  String get legalAcceptToContinue =>
      'தொடர, விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கவும்.';

  @override
  String get legalEnglishOnly => 'இந்த ஆவணம் ஆங்கிலத்தில் வழங்கப்படுகிறது.';

  @override
  String get profileSectionLegal => 'சட்டம்';

  @override
  String get myBranch => 'எனது கிளை';

  @override
  String get myBranchSubtitle => 'உங்கள் கடைக் கிளை மற்றும் தொடர்பு';

  @override
  String get branchDetails => 'கிளை விவரங்கள்';

  @override
  String get branchPhone => 'கிளை தொலைபேசி';

  @override
  String get yourBranchSupport => 'உங்கள் கிளை';

  @override
  String get appSupport => 'ஆப் உதவி';

  @override
  String get openInMaps => 'மேப்பில் திற';

  @override
  String get notAvailable => 'கிடைக்கவில்லை';

  @override
  String get supportHint =>
      'பில், புள்ளிகள், சலுகைகளுக்கு உங்கள் கிளையைத் தொடர்பு கொள்ளவும். ஆப் பிரச்சனைகளுக்கு ஆப் உதவியைத் தொடர்பு கொள்ளவும்.';

  @override
  String get directions => 'வழிகாட்டல்';

  @override
  String get openInGoogleMaps => 'Google மேப்பில் திற';

  @override
  String get profileStatus => 'சுயவிவர நிலை';

  @override
  String get profileReadyForBills =>
      'உங்கள் சுயவிவரம் முழுமையானது. பில் சமர்ப்பிக்கலாம்.';

  @override
  String get profileMissingForBills =>
      'பில் சமர்ப்பிக்க விடுபட்டவற்றைச் சேர்க்கவும்.';

  @override
  String get requiredForBills => 'பில்லுக்கு அவசியம்';

  @override
  String get added => 'சேர்க்கப்பட்டது';

  @override
  String get missing => 'விடுபட்டது';

  @override
  String get notAdded => 'சேர்க்கப்படவில்லை';

  @override
  String get emailOptional => 'மின்னஞ்சல் (விருப்பம்)';

  @override
  String get profilePhoto => 'சுயவிவரப் படம்';

  @override
  String get addPhotoRequired =>
      'சுயவிவரப் படத்தைச் சேர்க்கவும். பில் சமர்ப்பிக்க இது அவசியம்.';

  @override
  String itemsMissing(String items) {
    return 'விடுபட்டவை: $items';
  }

  @override
  String get rupeesPerPoint => 'ஒரு புள்ளிக்கு ரூபாய்';

  @override
  String get rupeesPerPointHint =>
      'எ.கா. 1000 என்றால் ஒவ்வொரு ₹1,000க்கும் 1 புள்ளி';

  @override
  String get enterValidRate => '1 முதல் 10,00,000 வரை எண்ணை உள்ளிடவும்';

  @override
  String ptPerRupees(String rupees) {
    return '1 புள்ளி / ₹$rupees';
  }

  @override
  String yourPointsRate(String rupees) {
    return 'உங்கள் விகிதம்: ஒவ்வொரு ₹$rupeesக்கும் 1 புள்ளி';
  }

  @override
  String get pointsRateByRole => 'புள்ளி விகிதம்';

  @override
  String get enterRupeesPerPoint => 'ஒரு புள்ளிக்கு ரூபாயை உள்ளிடவும்';

  @override
  String get catalogs => 'கேட்லாக்';

  @override
  String get catalogsSubtitle => 'வகை வாரியாக தயாரிப்பு கேட்லாக்குகள்';

  @override
  String catalogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count கேட்லாக்குகள்',
      one: '1 கேட்லாக்',
    );
    return '$_temp0';
  }

  @override
  String catalogPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பக்கங்கள்',
      one: '1 பக்கம்',
    );
    return '$_temp0';
  }

  @override
  String get catalogView => 'பார்க்க';

  @override
  String get catalogShare => 'பகிர்';

  @override
  String get catalogZoomIn => 'பெரிதாக்கு';

  @override
  String get catalogZoomOut => 'சிறிதாக்கு';

  @override
  String get catalogZoomFit => 'திரைக்குப் பொருத்து';

  @override
  String get catalogDownload => 'பதிவிறக்கு';

  @override
  String get catalogsEmpty => 'இன்னும் கேட்லாக் இல்லை';

  @override
  String get catalogsEmptyMessage =>
      'Balaji Points சேர்த்தவுடன் கேட்லாக்குகள் இங்கே தெரியும்.';

  @override
  String get catalogLoadError =>
      'கேட்லாக்குகளை ஏற்ற முடியவில்லை. இணையத்தை சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get catalogOpenError =>
      'இந்த கேட்லாக்கை திறக்க முடியவில்லை. இணையத்தை சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String catalogShareText(String title, String url) {
    return '$title – Balaji Points கேட்லாக்\n$url';
  }

  @override
  String get catalogOnlineHint =>
      'ஆன்லைனில் திறக்கும். பதிவிறக்கு அழுத்தாமல் போனில் எதுவும் சேமிக்கப்படாது.';

  @override
  String catalogPageOf(int page, int total) {
    return 'பக்கம் $page / $total';
  }

  @override
  String get catalogAdminAddCategory => 'வகையைச் சேர்';

  @override
  String get catalogAdminEditCategory => 'வகையைத் திருத்து';

  @override
  String get catalogAdminCategoryName => 'வகையின் பெயர்';

  @override
  String get catalogAdminDescription => 'விளக்கம் (விருப்பம்)';

  @override
  String get catalogAdminAddCatalog => 'கேட்லாக் சேர்';

  @override
  String get catalogAdminEditCatalog => 'கேட்லாக்கைத் திருத்து';

  @override
  String get catalogAdminCategory => 'வகை';

  @override
  String get catalogAdminTitle => 'கேட்லாக் பெயர்';

  @override
  String get catalogAdminBrand => 'பிராண்ட் (விருப்பம்)';

  @override
  String get catalogAdminYear => 'ஆண்டு';

  @override
  String get catalogAdminOrder => 'காட்டும் வரிசை';

  @override
  String get catalogAdminPickPdf => 'PDF தேர்வு செய்';

  @override
  String get catalogAdminReplacePdf => 'PDF மாற்று';

  @override
  String get catalogAdminPickCover => 'அட்டைப் படம் தேர்வு செய்';

  @override
  String get catalogAdminCoverAuto =>
      'அட்டை தேர்வு செய்யாவிட்டால், PDF-இன் முதல் பக்கம் பயன்படுத்தப்படும்.';

  @override
  String catalogAdminPdfTooLarge(String size) {
    return 'இந்த PDF $size. வரம்பு 25 MB. சுருக்கி மீண்டும் முயலவும்.';
  }

  @override
  String get catalogAdminNotPdf => 'இந்தக் கோப்பு PDF அல்ல.';

  @override
  String catalogAdminUploading(int percent) {
    return 'பதிவேற்றுகிறது… $percent%';
  }

  @override
  String get catalogAdminSaved => 'கேட்லாக் சேமிக்கப்பட்டது';

  @override
  String get catalogAdminHide => 'உறுப்பினர்களிடம் மறை';

  @override
  String get catalogAdminShow => 'உறுப்பினர்களுக்குக் காட்டு';

  @override
  String get catalogAdminHidden => 'மறைக்கப்பட்டது';

  @override
  String catalogAdminDeleteCatalogConfirm(String title) {
    return '\"$title\" நீக்கவா? உறுப்பினர்கள் இனி பார்க்க முடியாது.';
  }

  @override
  String catalogAdminDeleteCategoryConfirm(String name) {
    return '\"$name\" வகையை நீக்கவா?';
  }

  @override
  String get catalogAdminCategoryNotEmpty =>
      'முதலில் இந்த வகையில் உள்ள கேட்லாக்குகளை நீக்கவும் அல்லது மாற்றவும்.';

  @override
  String get catalogAdminEmpty =>
      'இன்னும் கேட்லாக் இல்லை. ஒரு வகையைச் சேர்த்து, PDF பதிவேற்றவும்.';

  @override
  String get catalogAdminNeedCategory => 'முதலில் ஒரு வகையைச் சேர்க்கவும்.';

  @override
  String get catalogAdminRequired => 'தேவை';

  @override
  String catalogAdminSaveFailed(String details) {
    return 'சேமிக்க முடியவில்லை: $details';
  }

  @override
  String get catalogAdminPermission =>
      'மின்னஞ்சல் மூலம் உள்நுழைந்த நிர்வாகிகள் மட்டுமே கேட்லாக்கை மாற்ற முடியும்.';

  @override
  String get catalogAdminPdfRequired => 'PDF கோப்பைத் தேர்வு செய்யவும்.';

  @override
  String get catalogAdminHintCategoryName => 'வகையின் பெயரை உள்ளிடவும்';

  @override
  String get catalogAdminHintDescription => 'விளக்கத்தை உள்ளிடவும்';

  @override
  String get catalogAdminHintTitle => 'கேட்லாக் பெயரை உள்ளிடவும்';

  @override
  String get catalogAdminHintBrand => 'பிராண்ட் பெயரை உள்ளிடவும்';

  @override
  String get catalogAdminHintYear => 'ஆண்டை உள்ளிடவும்';

  @override
  String get catalogAdminHintOrder => 'வரிசை எண்ணை உள்ளிடவும்';

  @override
  String get enquiryHeroTitle => 'நாங்கள் எப்படி உதவலாம்?';

  @override
  String get enquiryHeroSubtitle =>
      'உங்கள் கேள்வியை அனுப்புங்கள். பொதுவாக ஒரு வேலை நாளுக்குள் பதில் அளிப்போம்.';

  @override
  String enquiryGoesToBranch(String branch) {
    return '$branch கிளைக்குச் செல்லும்';
  }

  @override
  String get enquiryGoesToTeam => 'பாலாஜி பாயின்ட்ஸ் குழுவுக்குச் செல்லும்';

  @override
  String get enquiryTypeLabel => 'எதைப் பற்றியது?';

  @override
  String get enquiryTypeProduct => 'தயாரிப்பு விசாரணை';

  @override
  String get enquiryTypeQuotation => 'மொத்த ஆர்டர் / விலைப்புள்ளி';

  @override
  String get enquiryTypePointsBills => 'புள்ளிகள் & பில்கள்';

  @override
  String get enquiryTypeAppHelp => 'ஆப் உதவி';

  @override
  String get enquiryTypeMembership => 'உறுப்பினராகுங்கள்';

  @override
  String get enquiryTypeOther => 'மற்றவை';

  @override
  String get enquiryNameLabel => 'உங்கள் பெயர்';

  @override
  String get enquiryNameHint => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get enquiryPhoneLabel => 'மொபைல் எண்';

  @override
  String get enquiryPhoneHint => 'மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get enquiryCityLabel => 'நகரம் (விருப்பம்)';

  @override
  String get enquiryCityHint => 'நகரத்தை உள்ளிடவும்';

  @override
  String get enquiryMessageLabel => 'செய்தி';

  @override
  String get enquiryMessageHint => 'உங்கள் செய்தியை உள்ளிடவும்';

  @override
  String get enquiryNameRequired => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get enquiryPhoneInvalid => 'சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get enquiryMessageTooShort => 'குறைந்தது 10 எழுத்துகள் எழுதவும்';

  @override
  String get enquirySend => 'விசாரணையை அனுப்பு';

  @override
  String get enquirySentTitle => 'விசாரணை அனுப்பப்பட்டது';

  @override
  String enquirySentBranch(String branch) {
    return 'நன்றி. $branch விரைவில் உங்களைத் தொடர்பு கொள்ளும்.';
  }

  @override
  String get enquirySentTeam =>
      'நன்றி. எங்கள் குழு விரைவில் உங்களைத் தொடர்பு கொள்ளும்.';

  @override
  String get enquirySendAnother => 'மற்றொன்றை அனுப்பு';

  @override
  String enquiryTooSoon(int minutes) {
    return 'மற்றொரு விசாரணையை அனுப்பும் முன் $minutes நிமிடம் காத்திருக்கவும்.';
  }

  @override
  String get enquiryFailed =>
      'அனுப்ப முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get enquiryReachDirectly => 'அல்லது நேரடியாகத் தொடர்பு கொள்ளுங்கள்';

  @override
  String get enquiryCall => 'அழை';

  @override
  String get enquiries => 'விசாரணைகள்';

  @override
  String get enquiriesEmpty => 'இதுவரை விசாரணைகள் இல்லை';

  @override
  String get enquiriesOpen => 'திறந்தவை';

  @override
  String get enquiriesResolved => 'தீர்க்கப்பட்டவை';

  @override
  String get enquiryMarkResolved => 'தீர்க்கப்பட்டதாகக் குறி';

  @override
  String get enquiryReopen => 'மீண்டும் திற';

  @override
  String get enquiryGuest => 'விருந்தினர்';

  @override
  String get enquiriesNoAccess =>
      'விசாரணைகளைப் பார்க்க உங்கள் நிர்வாக மின்னஞ்சல் மூலம் உள்நுழையவும்.';

  @override
  String get contactYourBranch => 'உங்கள் கிளை';

  @override
  String get contactSendMessage => 'எங்களுக்குச் செய்தி அனுப்புங்கள்';

  @override
  String contactSendingAs(String name) {
    return '$name ஆக அனுப்புகிறீர்கள்';
  }

  @override
  String get guestEnquiries => 'விருந்தினர் விசாரணைகள்';

  @override
  String get navMore => 'மேலும்';

  @override
  String get billRejectedAt => 'நிராகரிக்கப்பட்டது: ';

  @override
  String get memberDetailsTitle => 'உறுப்பினர் விவரங்கள்';

  @override
  String get memberApprovedAmount => 'அங்கீகரிக்கப்பட்ட கொள்முதல்';

  @override
  String get memberDateRange => 'தேதி வரம்பு';

  @override
  String get memberHistory => 'வரலாறு';

  @override
  String get memberCall => 'அழை';

  @override
  String get billPointsCredited => 'வரவு வைக்கப்பட்ட புள்ளிகள்';

  @override
  String get billMember => 'உறுப்பினர்';

  @override
  String get billDetailsSection => 'விவரங்கள்';

  @override
  String get guestContinue => 'விருந்தினராகத் தொடரவும்';

  @override
  String get guestHomeTitle => 'பாலாஜி பாயின்ட்ஸுக்கு வரவேற்கிறோம்';

  @override
  String get guestHomeSubtitle =>
      'பட்டியல்களைப் பாருங்கள், கிளையைக் கண்டறியுங்கள் அல்லது எங்களுடன் பேசுங்கள்.';

  @override
  String get guestJoinTitle => 'பாலாஜி பாயின்ட்ஸில் சேருங்கள்';

  @override
  String get guestJoinBody =>
      'தச்சர்கள், கட்டடக் கலைஞர்கள், பொறியாளர்கள் மற்றும் உள்ளக வடிவமைப்பாளர்கள் ஒவ்வொரு வாங்குதலிலும் புள்ளிகள் பெற்று பரிசுகளை வெல்கிறார்கள்.';

  @override
  String get guestRegister => 'இப்போது பதிவு செய்யுங்கள்';

  @override
  String get guestLogin => 'உள்நுழை';

  @override
  String get guestCatalogsSub => 'லேமினேட், ப்ளைவுட், கதவுகள் மற்றும் பல';

  @override
  String get guestBranches => 'எங்கள் கிளைகள்';

  @override
  String get guestBranchesSub => 'முகவரி, தொலைபேசி மற்றும் வழி';

  @override
  String get guestService => 'சேவை கோரிக்கை';

  @override
  String get guestServiceSub => 'கிளையிடம் உதவி கேளுங்கள்';

  @override
  String get guestCareers => 'வேலைவாய்ப்புகள்';

  @override
  String get guestCareersSub => 'எங்களுடன் பணியாற்ற விண்ணப்பிக்கவும்';

  @override
  String get guestContactSub => 'தயாரிப்புகள் அல்லது விலைகள் பற்றிய கேள்விகள்';

  @override
  String get branchDirections => 'வழி';

  @override
  String get branchesEmpty => 'இதுவரை கிளைகள் இல்லை';

  @override
  String get enquiryBranchLabel => 'கிளை';

  @override
  String get enquiryBranchHint => 'கிளையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get enquiryBranchRequired => 'ஒரு கிளையைத் தேர்ந்தெடுக்கவும்';

  @override
  String get enquiryTypeService => 'சேவை கோரிக்கை';

  @override
  String get enquiryTypeCareer => 'வேலைவாய்ப்பு';

  @override
  String get careerIntro =>
      'உங்கள் விவரங்களை அனுப்புங்கள். கிளை உங்களை அழைக்கும்.';

  @override
  String get careerPosition => 'பதவி';

  @override
  String get careerPositionHint => 'பதவியை உள்ளிடவும்';

  @override
  String get careerExperience => 'அனுபவம்';

  @override
  String get careerExperienceHint => 'அனுபவத்தை உள்ளிடவும்';

  @override
  String get careerAbout => 'உங்களைப் பற்றி';

  @override
  String get careerAboutHint => 'உங்கள் வேலையைப் பற்றி சில வரிகள் உள்ளிடவும்';

  @override
  String get careerSubmit => 'விண்ணப்பத்தை அனுப்பு';

  @override
  String get careerSentTitle => 'விண்ணப்பம் அனுப்பப்பட்டது';

  @override
  String get careerPositionRequired => 'பதவியை உள்ளிடவும்';

  @override
  String get branchMapsLink => 'கூகுள் மேப்ஸ் இணைப்பு';

  @override
  String get branchMapsLinkHint => 'கூகுள் மேப்ஸ் இணைப்பை உள்ளிடவும்';

  @override
  String get branchMapsLinkHelp =>
      'கூகுள் மேப்ஸில் கடையைத் திறந்து, பகிர் என்பதைத் தட்டி, இணைப்பை நகலெடுத்து இங்கே ஒட்டவும்.';

  @override
  String get branchMapsLinkInvalid => 'https:// என தொடங்கும் இணைப்பை ஒட்டவும்';

  @override
  String get guestLoginMember => 'உறுப்பினரா? உள்நுழையவும்';

  @override
  String get guestTabHome => 'முகப்பு';

  @override
  String get guestTabCatalogs => 'பட்டியல்கள்';

  @override
  String get guestTabBranches => 'கிளைகள்';

  @override
  String get guestTabContact => 'தொடர்பு';

  @override
  String get guestTagline => 'உள்ளக அலங்காரத்திற்கான உங்கள் ஒரே கடை';

  @override
  String get guestHeroTitle =>
      'ப்ளைவுட், ஹார்டுவேர் & ஃபிட்டிங்ஸ் — அனைத்தும் ஒரே இடத்தில்';

  @override
  String get guestHeroBody =>
      'புதிய பட்டியல்களைப் பாருங்கள், அருகிலுள்ள கிளையைக் கண்டறிந்து நிபுணர் உதவி பெறுங்கள்.';

  @override
  String get guestExploreCatalogs => 'பட்டியல்களைப் பாருங்கள்';

  @override
  String get guestWeOffer => 'நாங்கள் வழங்குவது';

  @override
  String get guestOfferPlywood => 'ப்ளைவுட்';

  @override
  String get guestOfferLaminates => 'லேமினேட்';

  @override
  String get guestOfferDoors => 'கதவுகள்';

  @override
  String get guestOfferHardware => 'ஹார்டுவேர்';

  @override
  String get guestOfferFittings => 'ஃபிட்டிங்ஸ்';

  @override
  String get guestOfferService => 'சேவை & ஆதரவு';

  @override
  String get guestStatBranches => 'கிளைகள்';

  @override
  String get guestStatCatalogs => 'பட்டியல்கள்';

  @override
  String get guestStatRoles => 'உறுப்பினர் பங்குகள்';

  @override
  String get guestQuickLinks => 'விரைவு இணைப்புகள்';

  @override
  String get guestJoinPoint1 => 'ஒவ்வொரு வாங்குதலிலும் புள்ளிகள் பெறுங்கள்';

  @override
  String get guestJoinPoint2 => 'பயணங்கள், கேஜெட்கள் மற்றும் பல வெல்லுங்கள்';

  @override
  String get guestJoinPoint3 => 'தினசரி சுழற்சி மற்றும் கிளை சலுகைகள்';

  @override
  String get guestGrowTitle =>
      'பாலாஜி பாயின்ட்ஸுடன் உங்கள் வணிகத்தை வளர்த்திடுங்கள்';

  @override
  String get guestGrowBody =>
      'கடை வைத்திருக்கிறீர்களா? உங்கள் கடை அல்லது கிளையை பாலாஜி பாயின்ட்ஸில் பதிவு செய்து வாடிக்கையாளர்களுக்கு வெகுமதி அளியுங்கள்.';

  @override
  String get guestGrowPoint1 => 'உங்கள் உறுப்பினர்களுக்கான தனிப்பயன் பங்குகள்';

  @override
  String get guestGrowPoint2 =>
      'உங்கள் சொந்த புள்ளிகள் மற்றும் வெகுமதி அமைப்பு';

  @override
  String get guestGrowPoint3 => 'உங்கள் குழுவுக்கு முழு நிர்வாகப் பலகம்';

  @override
  String get guestGrowCta => 'எங்களுடன் கூட்டுசேருங்கள்';

  @override
  String get enquiryTypePartner => 'என் கடையைப் பதிவு செய்';

  @override
  String get guestStatCategories => 'வகைகள்';

  @override
  String get enquiryBranchOptional => 'கிளை (விருப்பம்)';

  @override
  String get enquiryBranchAny => 'எந்தக் கிளையும் — பாலாஜி பாயின்ட்ஸ் குழு';

  @override
  String get guestTabGuest => 'விருந்தினர்';

  @override
  String get offersArrange => 'வரிசையை மாற்று';

  @override
  String get offersArrangeHint =>
      'உறுப்பினர்கள் பார்க்க வேண்டிய வரிசையில் சலுகைகளை இழுக்கவும்.';

  @override
  String get offersOrderSaved => 'சலுகை வரிசை சேமிக்கப்பட்டது';

  @override
  String get offersOrderFailed =>
      'வரிசையைச் சேமிக்க முடியவில்லை. மீண்டும் முயலவும்.';

  @override
  String get drawerSectionExplore => 'ஆராயுங்கள்';

  @override
  String get drawerSectionSupport => 'உதவி & ஆதரவு';

  @override
  String get offerBannerChange => 'மாற்று';

  @override
  String get loggingOut => 'வெளியேறுகிறது…';

  @override
  String get groupTradeTitle =>
      'சிறந்த தச்சர்கள் & உள் அலங்கார வடிவமைப்பாளர்கள்';

  @override
  String get groupProfessionalTitle =>
      'சிறந்த கட்டிடக் கலைஞர்கள் & பொறியாளர்கள்';

  @override
  String get groupTradeShort => 'தச்சர் & உள் அலங்காரம்';

  @override
  String get groupProfessionalShort => 'கட்டிடக் கலைஞர் & பொறியாளர்';

  @override
  String rankOfTotal(String rank, String total) {
    return '$total இல் தரவரிசை $rank';
  }

  @override
  String membersInYourGroup(String count) {
    return 'உங்கள் குழுவில் $count உறுப்பினர்கள் · உங்கள் கிளை';
  }

  @override
  String get spinGroupDoneToday => 'இந்தக் குழுவின் இன்றைய குலுக்கல் முடிந்தது';

  @override
  String get spinGroupHint =>
      'ஒவ்வொரு குழுவிற்கும் தனி குலுக்கல், நாளுக்கு ஒரு முறை';

  @override
  String get spinNoQualifiedToday =>
      'இன்று தகுதியான உறுப்பினர்கள் இல்லை. இன்று குறைந்தது ஒரு பில் அங்கீகரிக்கப்பட வேண்டும்.';

  @override
  String todaySalesValue(String amount) {
    return 'இன்றைய விற்பனை $amount';
  }

  @override
  String groupSalesToday(String count, String amount) {
    return '$count தகுதி · இன்று $amount விற்பனை';
  }

  @override
  String todaysWinnerYourGroup(String group) {
    return 'இன்றைய வெற்றியாளர் · $group';
  }

  @override
  String get drawNotHappenedYet => 'இன்றைய குலுக்கல் இன்னும் நடக்கவில்லை';

  @override
  String get allRolesBeforeSplit => 'அனைத்து பணிகள்';

  @override
  String get allGroups => 'அனைத்தும்';

  @override
  String get allMembers => 'அனைத்து உறுப்பினர்கள்';

  @override
  String filteredMemberCount(String shown, String total) {
    return '$total இல் $shown உறுப்பினர்கள்';
  }

  @override
  String get accountRequestSentTitle => 'கோரிக்கை அனுப்பப்பட்டது';

  @override
  String accountRequestSentBody(String branch) {
    return 'உங்கள் கணக்கு கோரிக்கை $branch க்கு அனுப்பப்பட்டது. கிளை அங்கீகரித்த பிறகு நீங்கள் உள்நுழையலாம்.';
  }

  @override
  String get accountPendingTitle => 'அங்கீகாரத்திற்காகக் காத்திருக்கிறது';

  @override
  String accountPendingBody(String branch) {
    return 'உங்கள் கணக்கு $branch இன் அங்கீகாரத்திற்காகக் காத்திருக்கிறது. பின்னர் உள்நுழைய முயற்சிக்கவும்.';
  }

  @override
  String get accountRejectedTitle => 'கணக்கு அங்கீகரிக்கப்படவில்லை';

  @override
  String accountRejectedBody(String branch) {
    return 'உங்கள் கணக்கு கோரிக்கை $branch ஆல் அங்கீகரிக்கப்படவில்லை. கிளையைத் தொடர்பு கொள்ளவும்.';
  }

  @override
  String rejectReasonValue(String reason) {
    return 'காரணம்: $reason';
  }

  @override
  String callBranchPhone(String phone) {
    return 'கிளையை அழைக்கவும் · $phone';
  }

  @override
  String get yourBranchFallback => 'உங்கள் கிளை';

  @override
  String phoneTakenPending(String branch) {
    return 'இந்த எண்ணிற்கான கணக்கு கோரிக்கை ஏற்கனவே $branch இல் அங்கீகாரத்திற்காகக் காத்திருக்கிறது.';
  }

  @override
  String phoneTakenRejected(String branch) {
    return 'இந்த எண்ணிற்கு ஏற்கனவே $branch இல் கணக்கு உள்ளது. கிளையைத் தொடர்பு கொள்ளவும்.';
  }

  @override
  String get phoneTakenApproved =>
      'இந்த எண்ணிற்கு ஏற்கனவே கணக்கு உள்ளது. உள்நுழையவும்.';

  @override
  String get phoneTakenOtherBranch =>
      'இந்த எண் ஏற்கனவே மற்றொரு பாலாஜி பாயிண்ட்ஸ் கிளையில் பதிவு செய்யப்பட்டுள்ளது. ஆதரவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get numberAlreadyRegistered => 'எண் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது';

  @override
  String get accountRequests => 'கணக்கு கோரிக்கைகள்';

  @override
  String accountRequestsPendingTab(String count) {
    return 'நிலுவையில் ($count)';
  }

  @override
  String accountRequestsRejectedTab(String count) {
    return 'நிராகரிக்கப்பட்டது ($count)';
  }

  @override
  String get noPendingRequests => 'காத்திருக்கும் கணக்கு கோரிக்கைகள் இல்லை';

  @override
  String get noPendingRequestsHint =>
      'உங்கள் கிளையின் புதிய பதிவுகள் அங்கீகாரத்திற்காக இங்கே தோன்றும்.';

  @override
  String get noRejectedRequests => 'நிராகரிக்கப்பட்ட கணக்குகள் இல்லை';

  @override
  String approveAccountConfirm(String name) {
    return '$name ஐ அங்கீகரிக்கவா? அவர்கள் உடனே உள்நுழையலாம்.';
  }

  @override
  String rejectAccountTitle(String name) {
    return '$name ஐ நிராகரிக்கவா?';
  }

  @override
  String get rejectReasonOptional => 'காரணம் (விருப்பம்)';

  @override
  String get rejectReasonNotCustomer => 'வாடிக்கையாளர் அல்ல';

  @override
  String get rejectReasonWrongBranch => 'தவறான கிளை';

  @override
  String get rejectReasonDuplicate => 'நகல் கணக்கு';

  @override
  String accountApprovedToast(String name) {
    return '$name அங்கீகரிக்கப்பட்டார்';
  }

  @override
  String accountRejectedToast(String name) {
    return '$name நிராகரிக்கப்பட்டார்';
  }

  @override
  String possibleDuplicate(String name) {
    return 'நகலாக இருக்கலாம்: $name அதே பெயர்';
  }

  @override
  String requestedOn(String date) {
    return 'கோரப்பட்டது $date';
  }

  @override
  String get memberAddedApproveLater =>
      'உறுப்பினர் சேர்க்கப்பட்டார். கணக்கு கோரிக்கைகளில் அங்கீகரிக்கவும்.';

  @override
  String get enterRejectReason => 'காரணத்தை உள்ளிடவும்';

  @override
  String waApprovedMessage(String name, String branch) {
    return 'வணக்கம் $name, $branch இல் உங்கள் பாலாஜி பாயிண்ட்ஸ் கணக்கு அங்கீகரிக்கப்பட்டது. இப்போது ஆப்பில் உள்நுழைந்து உங்கள் பில்களைச் சேர்க்கலாம். நன்றி!';
  }

  @override
  String waRejectedMessage(String name, String branch, String reason) {
    return 'வணக்கம் $name, $branch இல் உங்கள் பாலாஜி பாயிண்ட்ஸ் கணக்கு கோரிக்கை அங்கீகரிக்கப்படவில்லை.$reason உதவிக்கு கடையைத் தொடர்பு கொள்ளவும். நன்றி!';
  }

  @override
  String waReasonPart(String reason) {
    return ' காரணம்: $reason.';
  }

  @override
  String letMemberKnowTitle(String name) {
    return '$name க்குத் தெரிவிக்கவும்';
  }

  @override
  String get letMemberKnowApproved =>
      'ஆப் அறிவிப்பு அனுப்பப்பட்டது. உங்கள் ஃபோனிலிருந்து WhatsApp செய்தியும் அனுப்பவா?';

  @override
  String get letMemberKnowRejected =>
      'உங்கள் ஃபோனிலிருந்து ஒரு மரியாதையான WhatsApp செய்தி அனுப்பவா?';

  @override
  String get sendWhatsApp => 'WhatsApp அனுப்பு';

  @override
  String get notNow => 'இப்போது வேண்டாம்';

  @override
  String get whatsAppNotAvailable =>
      'இந்த சாதனத்தில் WhatsApp ஐத் திறக்க முடியவில்லை.';
}
