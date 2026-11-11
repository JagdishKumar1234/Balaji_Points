// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'बालाजी पॉइंट्स';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफल';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'मिटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get submit => 'जमा करें';

  @override
  String get back => 'वापस';

  @override
  String get next => 'अगला';

  @override
  String get done => 'हो गया';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get refresh => 'ताज़ा करें';

  @override
  String get loginWithPhone => 'फोन नंबर से लॉगिन करें';

  @override
  String get enterPhoneNumber => 'अपना पंजीकृत फोन नंबर दर्ज करें';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get enterPhoneHint => '10 अंकों का फोन नंबर दर्ज करें';

  @override
  String get sendOTP => 'OTP भेजें';

  @override
  String get verifyOTP => 'OTP सत्यापित करें';

  @override
  String get enterOTPCode => '6 अंकों का कोड दर्ज करें';

  @override
  String get didntReceiveOTP => 'OTP नहीं मिला? ';

  @override
  String get resend => 'पुनः भेजें';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंड में पुनः भेजें';
  }

  @override
  String get invalidPhone => 'कृपया अपना फोन नंबर दर्ज करें';

  @override
  String get invalidPhoneLength => 'फोन नंबर 10 अंकों का होना चाहिए';

  @override
  String get invalidPhoneFormat => 'फोन नंबर में केवल अंक होने चाहिए';

  @override
  String get invalidOTP => 'कृपया 6 अंकों का वैध OTP दर्ज करें';

  @override
  String get selectRole => 'अपनी भूमिका चुनें';

  @override
  String get carpenter => 'बढ़ई';

  @override
  String get admin => 'व्यवस्थापक';

  @override
  String get welcomeBack => 'वापस स्वागत है';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get continueWithPhone => 'फोन से जारी रखें';

  @override
  String get continueWithPin => 'PIN के साथ जारी रखें';

  @override
  String get loginInfo =>
      'अपने पंजीकृत फोन नंबर का उपयोग करके लॉगिन करें। सत्यापन के लिए आपको एक OTP प्राप्त होगा।';

  @override
  String get poweredBy => 'द्वारा संचालित';

  @override
  String get companyName => 'बालाजी पॉइंट्स';

  @override
  String get enterPinPageTitle => 'अपना 4 अंकों का PIN दर्ज करें';

  @override
  String get enter4DigitPin => 'अपना 4 अंकों का PIN दर्ज करें';

  @override
  String get pinLabel => 'पिन';

  @override
  String get fourDigitPin => '4 अंकों का PIN';

  @override
  String get login => 'लॉगिन';

  @override
  String get forgotPin => 'PIN भूल गए?';

  @override
  String get newUserSetPin => 'नए उपयोगकर्ता? PIN सेट करें';

  @override
  String get invalidPin => 'अमान्य PIN';

  @override
  String get createPinTitle => 'अपना 4 अंकों का PIN बनाएं';

  @override
  String get createPinSubtitle => 'यह PIN लॉगिन के लिए उपयोग किया जाएगा';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get firstName => 'पहला नाम';

  @override
  String get firstNameRequired => 'पहला नाम *';

  @override
  String get lastName => 'अंतिम नाम';

  @override
  String get confirmPin => 'PIN की पुष्टि करें';

  @override
  String get savePin => 'PIN सहेजें';

  @override
  String get pinCreatedSuccess => 'PIN सफलतापूर्वक बनाया गया';

  @override
  String get failedToSavePin => 'PIN सहेजने में विफल';

  @override
  String get pinsDoNotMatch => 'PIN और पुष्टि PIN मेल नहीं खाते';

  @override
  String get resetPinTitle => 'PIN रीसेट करें';

  @override
  String get resetPinSubtitle =>
      'अपना PIN रीसेट करने के लिए अपना पंजीकृत मोबाइल नंबर दर्ज करें।';

  @override
  String get mustBeLoggedInToResetPin =>
      'आपको अपना PIN रीसेट करने के लिए लॉग इन होना चाहिए। कृपया पहले लॉगिन करें।';

  @override
  String get canOnlyResetOwnPin =>
      'आप केवल अपना PIN रीसेट कर सकते हैं। फोन नंबर आपके लॉग इन खाते से मेल खाना चाहिए।';

  @override
  String get enterCurrentPin =>
      'कृपया स्वामित्व सत्यापित करने के लिए अपना वर्तमान PIN दर्ज करें।';

  @override
  String get currentPinLabel => 'वर्तमान PIN';

  @override
  String get newPinMustBeDifferent =>
      'नया PIN आपके वर्तमान PIN से अलग होना चाहिए।';

  @override
  String get contactAdminForPinReset =>
      'आपको अपना PIN रीसेट करने के लिए लॉग इन होना चाहिए। यदि आप अपना PIN भूल गए हैं, तो कृपया सहायता के लिए व्यवस्थापक से संपर्क करें।';

  @override
  String get forgotCurrentPin => 'अपना वर्तमान PIN भूल गए?';

  @override
  String get forgotPinHelp =>
      'यदि आपको अपना वर्तमान PIN याद नहीं है, तो कृपया सहायता के लिए हमारी सहायता टीम से संपर्क करें।';

  @override
  String get adminSupportInfo => 'व्यवस्थापक सहायता';

  @override
  String get callSupport => 'सहायता को कॉल करें';

  @override
  String get adminResetPin => 'PIN रीसेट करें';

  @override
  String adminResetPinTitle(String carpenterName) {
    return '$carpenterName के लिए PIN रीसेट करें';
  }

  @override
  String get adminResetPinSubtitle =>
      'इस बढ़ई के लिए एक नया 4 अंकों का PIN दर्ज करें।';

  @override
  String adminResetPinConfirm(String carpenterName) {
    return 'क्या आप $carpenterName के लिए PIN रीसेट करना चाहते हैं?';
  }

  @override
  String adminResetPinSuccess(String carpenterName) {
    return '$carpenterName के लिए PIN सफलतापूर्वक रीसेट किया गया';
  }

  @override
  String get adminResetPinFailed =>
      'PIN रीसेट करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get adminNotAuthorized =>
      'आप इस क्रिया को करने के लिए अधिकृत नहीं हैं।';

  @override
  String get enterNewPinForCarpenter => 'नया 4 अंकों का PIN दर्ज करें';

  @override
  String get confirmNewPinForCarpenter => 'नया 4 अंकों का PIN की पुष्टि करें';

  @override
  String get newPinLabel => 'नया 4 अंकों का PIN';

  @override
  String get checkNumber => 'नंबर जांचें';

  @override
  String get verified => 'सत्यापित';

  @override
  String get pleaseVerifyMobile => 'कृपया पहले मोबाइल नंबर सत्यापित करें';

  @override
  String get noAccountFound => 'इस नंबर के लिए कोई खाता नहीं मिला';

  @override
  String get pinResetSuccess =>
      'PIN सफलतापूर्वक रीसेट किया गया। कृपया फिर से लॉगिन करें।';

  @override
  String get failedToResetPin => 'PIN रीसेट करने में विफल। पुनः प्रयास करें।';

  @override
  String get enterValidTenDigit => 'मान्य 10 अंकों का नंबर दर्ज करें';

  @override
  String get enter4Digits => '4 अंक दर्ज करें';

  @override
  String get pinMismatch => 'PIN मेल नहीं खाते';

  @override
  String get enterValidFirstName => 'मान्य पहला नाम दर्ज करें';

  @override
  String get imageError => 'छवि त्रुटि';

  @override
  String get resetPin => 'PIN रीसेट करें';

  @override
  String get changePin => 'PIN बदलें';

  @override
  String get rememberMe => 'मुझे याद रखें';

  @override
  String get accountExistsUseReset =>
      'खाता पहले से मौजूद है। कृपया अपना PIN बदलने के लिए Reset PIN का उपयोग करें।';

  @override
  String get home => 'होम';

  @override
  String get addPoints => 'पॉइंट जोड़ें';

  @override
  String get latestOffers => 'नवीनतम ऑफर्स';

  @override
  String get goodMorningGreeting => 'सुप्रभात,';

  @override
  String get goodAfternoonGreeting => 'नमस्कार,';

  @override
  String get goodEveningGreeting => 'शुभ संध्या,';

  @override
  String get homeBrowseProductsTitle => 'लकड़ी और प्लाईवुड';

  @override
  String get homeBrowseProductsSubtitle => 'प्रीमियम लैमिनेट और सतहें';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get homeStoreBranch => 'ई रोड';

  @override
  String get homeTierSuffix => 'टियर';

  @override
  String get homeRankingsSectionTitle => 'रैंकिंग और आज का विजेता';

  @override
  String get homeRankingsSectionSubtitle =>
      'लीडरबोर्ड, आपकी रैंक और आज का इनाम';

  @override
  String get drawerProductsTitle => 'उत्पाद';

  @override
  String get drawerProductsSubtitle => 'श्रेणियाँ और कैटलॉग देखें';

  @override
  String get drawerCart => 'कार्ट';

  @override
  String get drawerSectionMainNav => 'मुख्य नेविगेशन';

  @override
  String get drawerSectionMore => 'और विकल्प';

  @override
  String get myOrders => 'मेरे ऑर्डर';

  @override
  String get profileSectionAccount => 'खाता';

  @override
  String get profileSectionPreferences => 'प्राथमिकताएँ';

  @override
  String get profileSectionSupport => 'सहायता';

  @override
  String get profileAboutLink => 'ऐप के बारे में';

  @override
  String get routeErrorTitle => 'पेज नहीं मिला';

  @override
  String get routeErrorNotFound => 'यह लिंक गलत है या पेज हटा दिया गया।';

  @override
  String get routeErrorGoHome => 'होम पर जाएं';

  @override
  String get routeErrorDetailsLabel => 'तकनीकी विवरण';

  @override
  String get topCarpenters => 'शीर्ष 3 सदस्य';

  @override
  String get todaysWinner => 'आज के विजेता';

  @override
  String get yourPosition => 'आपकी स्थिति';

  @override
  String rank(int rank) {
    return 'रैंक #$rank';
  }

  @override
  String points(int points) {
    return '$points पॉइंट्स';
  }

  @override
  String get noOffersAvailable => 'इस समय कोई ऑफर उपलब्ध नहीं है';

  @override
  String get dailySpinWinner => '🎉 दैनिक स्पिन विजेता';

  @override
  String get congratulations => 'बधाई हो!';

  @override
  String won(int points) {
    return '$points पॉइंट्स जीते!';
  }

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get editProfile => 'प्रोफाइल संपादित करें';

  @override
  String get completeProfile => 'अपना प्रोफाइल पूरा करें';

  @override
  String get profileIncomplete => 'प्रोफाइल अधूरा';

  @override
  String get completeProfileMessage =>
      'बिल जोड़ना और पॉइंट्स अर्जित करना शुरू करने के लिए कृपया अपना प्रोफाइल पूरा करें';

  @override
  String get completeProfileDetails =>
      'जारी रखने के लिए अपना पहला नाम, अंतिम नाम और प्रोफाइल फोटो जोड़ें';

  @override
  String get completeNow => 'अभी पूरा करें';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get contactUs => 'संपर्क करें';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get logoutConfirmation => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get name => 'नाम';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फोन';

  @override
  String get role => 'भूमिका';

  @override
  String get memberSince => 'सदस्य बने';

  @override
  String get totalPoints => 'कुल पॉइंट्स';

  @override
  String get notVerified => 'असत्यापित';

  @override
  String get needHelp => 'मदद चाहिए?';

  @override
  String get contactSupport =>
      'किसी भी प्रश्न या समस्या के लिए हमारी सहायता टीम से संपर्क करें।';

  @override
  String get callNow => 'अभी कॉल करें';

  @override
  String get getInTouch => 'हमसे संपर्क करें';

  @override
  String get mobile => 'मोबाइल';

  @override
  String get landline => 'लैंडलाइन';

  @override
  String get addBill => 'बिल जोड़ें';

  @override
  String get billDetails => 'बिल विवरण';

  @override
  String get billNumber => 'बिल नंबर';

  @override
  String get billAmount => 'बिल राशि';

  @override
  String get billDate => 'बिल तारीख';

  @override
  String get uploadBillImage => 'बिल फोटो अपलोड करें';

  @override
  String get selectImage => 'फोटो चुनें';

  @override
  String get changeImage => 'फोटो बदलें';

  @override
  String get pointsConversion => '1000 ₹ = 1 पॉइंट';

  @override
  String get estimatedPoints => 'अनुमानित पॉइंट्स';

  @override
  String youWillEarn(int points) {
    return 'आप लगभग $points पॉइंट्स अर्जित करेंगे';
  }

  @override
  String get enterBillNumber => 'कृपया बिल नंबर दर्ज करें';

  @override
  String get enterBillAmount => 'कृपया बिल राशि दर्ज करें';

  @override
  String get enterValidAmount => 'कृपया वैध राशि दर्ज करें';

  @override
  String get selectBillDate => 'कृपया बिल तारीख चुनें';

  @override
  String get uploadBillPhoto => 'कृपया बिल फोटो अपलोड करें';

  @override
  String get billSubmitted => 'बिल सफलतापूर्वक जमा किया गया';

  @override
  String get billSubmitError => 'बिल जमा करने में विफल';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get availablePoints => 'उपलब्ध पॉइंट्स';

  @override
  String get redeemPoints => 'पॉइंट्स भुनाएं';

  @override
  String get transactionHistory => 'लेनदेन इतिहास';

  @override
  String get earned => 'अर्जित';

  @override
  String get spent => 'खर्च किया';

  @override
  String get pending => 'लंबित';

  @override
  String get offers => 'ऑफर्स';

  @override
  String get viewDetails => 'विवरण देखें';

  @override
  String get redeemNow => 'अभी भुनाएं';

  @override
  String pointsRequired(int points) {
    return '$points पॉइंट्स आवश्यक';
  }

  @override
  String get offerRedeemed => 'ऑफर सफलतापूर्वक भुनाया गया';

  @override
  String get insufficientPoints => 'अपर्याप्त पॉइंट्स';

  @override
  String get offerExpired => 'यह ऑफर समाप्त हो गया है';

  @override
  String validUntil(String date) {
    return '$date तक वैध';
  }

  @override
  String get dailySpin => 'दैनिक स्पिन';

  @override
  String get spinNow => 'अभी घुमाएं';

  @override
  String get spinning => 'घूम रहा है...';

  @override
  String get spinWheel => 'पहिया घुमाएं';

  @override
  String get dailySpinCompleted => 'आप आज पहले ही घुमा चुके हैं';

  @override
  String get comeBackTomorrow => 'जीतने का एक और मौका पाने के लिए कल वापस आएं!';

  @override
  String nextSpinIn(int hours, int minutes) {
    return 'अगला स्पिन: $hoursघंटे $minutesमिनट में';
  }

  @override
  String winner(String name) {
    return 'विजेता: $name';
  }

  @override
  String prizePoints(int points) {
    return '🎁 $points पॉइंट्स';
  }

  @override
  String get adminPanel => 'व्यवस्थापक पैनल';

  @override
  String get adminSubtitle =>
      'बिल, ऑफर्स, उपयोगकर्ता और दैनिक स्पिन प्रबंधित करें';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get users => 'उपयोगकर्ता';

  @override
  String get manageUsers => 'उपयोगकर्ता प्रबंधित करें';

  @override
  String get manageBills => 'बिल प्रबंधित करें';

  @override
  String get manageOffers => 'ऑफर्स प्रबंधित करें';

  @override
  String get manageDailySpin => 'दैनिक स्पिन प्रबंधित करें';

  @override
  String get pendingBills => 'लंबित बिल';

  @override
  String get approvedBills => 'स्वीकृत बिल';

  @override
  String get rejectedBills => 'अस्वीकृत बिल';

  @override
  String get pendingUsers => 'लंबित उपयोगकर्ता';

  @override
  String get verifiedUsers => 'सत्यापित उपयोगकर्ता';

  @override
  String get approve => 'स्वीकृत करें';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String get userApproved => 'उपयोगकर्ता सफलतापूर्वक स्वीकृत';

  @override
  String get userRejected => 'उपयोगकर्ता अस्वीकृत';

  @override
  String get billApproved => 'बिल सफलतापूर्वक स्वीकृत';

  @override
  String get billRejected => 'बिल अस्वीकृत';

  @override
  String get createOffer => 'ऑफर बनाएं';

  @override
  String get offerTitle => 'ऑफर शीर्षक';

  @override
  String get offerDescription => 'ऑफर विवरण';

  @override
  String get offerCreated => 'ऑफर सफलतापूर्वक बनाया गया';

  @override
  String get logoutFailed => 'लॉगआउट विफल';

  @override
  String get errorOccurred => 'एक त्रुटि हुई';

  @override
  String get networkError =>
      'नेटवर्क त्रुटि। कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String get permissionDenied => 'अनुमति अस्वीकृत';

  @override
  String get sessionExpired => 'सत्र समाप्त। कृपया फिर से लॉगिन करें।';

  @override
  String get invalidCredentials => 'अमान्य प्रमाण पत्र';

  @override
  String get userNotFound => 'उपयोगकर्ता नहीं मिला';

  @override
  String get phoneAuthFailed => 'फोन प्रमाणीकरण विफल';

  @override
  String get configError => 'कॉन्फ़िगरेशन त्रुटि';

  @override
  String get missingClientId =>
      'Firebase में SHA-1 फ़िंगरप्रिंट गुम है। कृपया चलाएं: scripts/get_sha1.sh';

  @override
  String get tooManyRequests =>
      'बहुत सारे अनुरोध। कृपया कुछ मिनट प्रतीक्षा करें।';

  @override
  String get invalidVerificationCode =>
      'अमान्य OTP कोड। कृपया जांचें और पुनः प्रयास करें।';

  @override
  String get verificationExpired =>
      'सत्यापन समाप्त। कृपया नया OTP अनुरोध करें।';

  @override
  String get userDisabled =>
      'यह खाता अक्षम कर दिया गया है। कृपया समर्थन से संपर्क करें।';

  @override
  String get fieldRequired => 'यह फ़ील्ड आवश्यक है';

  @override
  String get invalidEmail => 'कृपया वैध ईमेल दर्ज करें';

  @override
  String get invalidName => 'कृपया वैध नाम दर्ज करें';

  @override
  String get nameTooShort => 'नाम कम से कम 2 अक्षर का होना चाहिए';

  @override
  String get invalidAmount => 'कृपया वैध राशि दर्ज करें';

  @override
  String get amountTooLow => 'राशि 0 से अधिक होनी चाहिए';

  @override
  String get searchHint => 'खोजें...';

  @override
  String get noResultsFound => 'कोई परिणाम नहीं मिला';

  @override
  String get noDataAvailable => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get pullToRefresh => 'ताज़ा करने के लिए खींचें';

  @override
  String get releaseToRefresh => 'ताज़ा करने के लिए छोड़ें';

  @override
  String get refreshing => 'ताज़ा हो रहा है...';

  @override
  String get loadMore => 'और लोड करें';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get close => 'बंद करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get areYouSure => 'क्या आप सुनिश्चित हैं?';

  @override
  String get cannotUndo => 'इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get tomorrow => 'आने वाला कल';

  @override
  String get january => 'जनवरी';

  @override
  String get february => 'फरवरी';

  @override
  String get march => 'मार्च';

  @override
  String get april => 'अप्रैल';

  @override
  String get may => 'मई';

  @override
  String get june => 'जून';

  @override
  String get july => 'जुलाई';

  @override
  String get august => 'अगस्त';

  @override
  String get september => 'सितंबर';

  @override
  String get october => 'अक्टूबर';

  @override
  String get november => 'नवंबर';

  @override
  String get december => 'दिसंबर';

  @override
  String get jan => 'जन';

  @override
  String get feb => 'फर';

  @override
  String get mar => 'मार';

  @override
  String get apr => 'अप्र';

  @override
  String get jun => 'जून';

  @override
  String get jul => 'जुला';

  @override
  String get aug => 'अग';

  @override
  String get sep => 'सित';

  @override
  String get oct => 'अक्ट';

  @override
  String get nov => 'नव';

  @override
  String get dec => 'दिस';

  @override
  String get approveBill => 'बिल स्वीकृत करें';

  @override
  String approveBillConfirmation(String amount, String phone) {
    return '$phone के लिए ₹$amount का बिल स्वीकृत करें?';
  }

  @override
  String get approvingBill => 'बिल स्वीकृत किया जा रहा है...';

  @override
  String get billApprovedSuccess => 'बिल स्वीकृत हो गया!';

  @override
  String get failedToApproveBill =>
      'बिल स्वीकृत करने में विफल। पुनः प्रयास करें।';

  @override
  String get rejectBill => 'बिल अस्वीकार करें';

  @override
  String get rejectBillConfirmation =>
      'क्या आप वाकई इस बिल को अस्वीकार करना चाहते हैं?';

  @override
  String get billRejectedSuccess => 'बिल अस्वीकृत';

  @override
  String get failedToRejectBill => 'अस्वीकार करने में विफल';

  @override
  String get failedToLoadImage => 'छवि लोड करने में विफल';

  @override
  String get noImageAvailable => 'कोई छवि उपलब्ध नहीं';

  @override
  String get errorLoadingBills => 'बिल लोड करने में त्रुटि';

  @override
  String get noPendingBills => 'कोई लंबित बिल नहीं';

  @override
  String get pendingStatus => 'लंबित';

  @override
  String get noDate => 'कोई तारीख नहीं';

  @override
  String get deleteOffer => 'ऑफर मिटाएं';

  @override
  String get deleteOfferConfirmation =>
      'क्या आप वाकई इस ऑफर को मिटाना चाहते हैं? इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get offerDeletedSuccess => 'ऑफर सफलतापूर्वक मिटाया गया';

  @override
  String get failedToDeleteOffer => 'ऑफर मिटाने में विफल';

  @override
  String get errorLoadingOffers => 'ऑफर लोड करने में त्रुटि';

  @override
  String get noOffersCreated => 'कोई ऑफर नहीं बनाए गए';

  @override
  String get createFirstOffer => 'पॉइंट्स और बैनर के साथ अपना पहला ऑफर बनाएं';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get createdLabel => 'बनाया गया';

  @override
  String get editOffer => 'ऑफर संपादित करें';

  @override
  String get createNewOffer => 'नया ऑफर बनाएं';

  @override
  String get tapToUploadBanner => 'बैनर अपलोड करने के लिए टैप करें';

  @override
  String get offerTitleLabel => 'ऑफर शीर्षक *';

  @override
  String get offerTitleHint => 'ऑफर का शीर्षक दर्ज करें';

  @override
  String get enterOfferTitle => 'कृपया ऑफर शीर्षक दर्ज करें';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get descriptionHint => 'विवरण दर्ज करें';

  @override
  String get pointsRequiredLabel => 'आवश्यक पॉइंट्स *';

  @override
  String get pointsHint => 'पॉइंट्स दर्ज करें';

  @override
  String get enterPointsError => 'कृपया पॉइंट्स दर्ज करें';

  @override
  String get enterValidNumber => 'कृपया एक वैध संख्या दर्ज करें';

  @override
  String get setValidUntilDate => 'वैधता तिथि निर्धारित करें (वैकल्पिक)';

  @override
  String validUntilDisplay(String date) {
    return '$date तक वैध';
  }

  @override
  String get offerStatus => 'ऑफर स्थिति';

  @override
  String get uploadingBanner => 'बैनर अपलोड हो रहा है...';

  @override
  String get updateOffer => 'ऑफर अपडेट करें';

  @override
  String get offerUpdatedSuccess => 'ऑफर सफलतापूर्वक अपडेट किया गया';

  @override
  String get offerCreatedSuccess => 'ऑफर सफलतापूर्वक बनाया गया';

  @override
  String get failedToSaveOffer => 'ऑफर सहेजने में विफल';

  @override
  String get failedToPickImage => 'छवि चुनने में विफल';

  @override
  String get searchByNameOrPhone => 'नाम या फ़ोन खोजें';

  @override
  String get add => 'जोड़ें';

  @override
  String get all => 'सभी';

  @override
  String get platinum => 'प्लेटिनम';

  @override
  String get gold => 'गोल्ड';

  @override
  String get silver => 'सिल्वर';

  @override
  String get bronze => 'ब्रॉन्ज';

  @override
  String get errorLoadingUsers => 'उपयोगकर्ता लोड करने में त्रुटि';

  @override
  String get noUsersFound => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get tryDifferentSearch => 'अलग खोज शब्द का प्रयास करें';

  @override
  String get noCarpentersYet => 'अभी तक कोई बढ़ई पंजीकृत नहीं';

  @override
  String joinedLabel(String date) {
    return '$date को शामिल हुए';
  }

  @override
  String get addCarpenter => 'बढ़ई जोड़ें';

  @override
  String get deleteCarpenter => 'बढ़ई हटाएं';

  @override
  String get deleteCarpenterConfirmation =>
      'क्या आप वाकई इस बढ़ई को हटाना चाहते हैं? यह स्थायी रूप से हटा देगा:\n\n• उपयोगकर्ता खाता\n• सभी पॉइंट्स और लेनदेन इतिहास\n• सभी जमा किए गए बिल\n• सभी ऑफर रिडेम्प्शन\n\nइस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get deleteCarpenterWarning =>
      'बढ़ई को हटाना सिस्टम से उनके सभी डेटा को स्थायी रूप से हटा देगा। इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get carpenterDeletedSuccess => 'बढ़ई सफलतापूर्वक हटाया गया';

  @override
  String get failedToDeleteCarpenter => 'बढ़ई हटाने में विफल';

  @override
  String get dangerZone => 'खतरनाक क्षेत्र';

  @override
  String get phoneNumberLabel => 'फोन नंबर';

  @override
  String get phoneNumberHint => 'फ़ोन नंबर दर्ज करें';

  @override
  String get enterOTP => 'OTP दर्ज करें';

  @override
  String get verifyAndCreate => 'सत्यापित करें और बनाएं';

  @override
  String get adminSignOutNote =>
      'नोट: OTP सत्यापन के दौरान ऐप अस्थायी रूप से सत्यापित बढ़ई के रूप में साइन इन करेगा और फिर साइन आउट करेगा। व्यवस्थापक को फिर से साइन इन करना होगा।';

  @override
  String get carpenterCreated => 'बढ़ई बनाया गया';

  @override
  String get carpenterCreatedMessage =>
      'बढ़ई खाता सफलतापूर्वक बनाया गया। सत्यापन के दौरान ऐप उस बढ़ई के रूप में साइन इन हो गया है और अब साइन आउट हो गया है। आपको व्यवस्थापक के रूप में फिर से साइन इन करना होगा।';

  @override
  String get enterValidPhone => 'एक वैध फोन नंबर दर्ज करें';

  @override
  String get phoneAlreadyExists => 'फोन नंबर पहले से मौजूद है';

  @override
  String get verificationFailed => 'सत्यापन विफल';

  @override
  String get otpSent => 'OTP भेजा गया';

  @override
  String get failedToSignIn => 'OTP से साइन इन करने में विफल';

  @override
  String get authError => 'प्रमाणीकरण त्रुटि';

  @override
  String get totalPointsLabel => 'कुल पॉइंट्स';

  @override
  String tierLabel(String tier) {
    return '$tier स्तर';
  }

  @override
  String get recentActivity => 'हालिया गतिविधि';

  @override
  String get noActivityYet => 'अभी तक कोई गतिविधि नहीं';

  @override
  String get noWinnerYetToday => 'आज अभी तक कोई विजेता नहीं';

  @override
  String get youWonPrize => '🎉 आपने जीत लिया!';

  @override
  String get todaysWinnerLabel => '🏆 आज के विजेता';

  @override
  String get myPoints => 'मेरे पॉइंट्स';

  @override
  String get leaderboard => 'लीडरबोर्ड';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get rankShort => 'रैंक';

  @override
  String get earn => 'वॉलेट';

  @override
  String get approved => 'स्वीकृत';

  @override
  String get addNewBill => 'नया बिल जोड़ें';

  @override
  String get recentBills => 'हाल के बिल';

  @override
  String get noBillsYet => 'अभी तक कोई बिल नहीं';

  @override
  String get submitFirstBill =>
      'पॉइंट्स अर्जित करने के लिए अपना पहला बिल जमा करें';

  @override
  String get justNow => 'अभी-अभी';

  @override
  String minutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String get billLabel => 'बिल';

  @override
  String get statusApproved => 'स्वीकृत';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get exitApp => 'ऐप से बाहर निकलें?';

  @override
  String get exitAppMessage => 'क्या आप ऐप से बाहर निकलना चाहते हैं?';

  @override
  String get exit => 'बाहर निकलें';

  @override
  String get discardChanges => 'परिवर्तन छोड़ें?';

  @override
  String get discardChangesMessage =>
      'आपके पास असहेजित परिवर्तन हैं। क्या आप उन्हें छोड़ना चाहते हैं?';

  @override
  String get discard => 'छोड़ें';

  @override
  String get pressBackAgainToExit => 'बाहर निकलने के लिए फिर से बैक दबाएं';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get pleaseWaitForSpin => 'कृपया स्पिन पूरा होने तक प्रतीक्षा करें';

  @override
  String get discardBill => 'बिल छोड़ें?';

  @override
  String get discardBillMessage =>
      'आपके पास असहेजित बिल डेटा है। क्या आप इसे छोड़ना चाहते हैं?';

  @override
  String get pleaseCompleteProfile => 'कृपया अपना प्रोफाइल पूरा करें';

  @override
  String get rewardsLoyaltyProgram => 'पुरस्कार और वफादारी कार्यक्रम';

  @override
  String get billImage => 'बिल छवि';

  @override
  String get billDateOptional => 'बिल तारीख (वैकल्पिक)';

  @override
  String get storeVendorNameOptional => 'स्टोर/विक्रेता नाम (वैकल्पिक)';

  @override
  String get billInvoiceNumberOptional => 'बिल/चालान नंबर (वैकल्पिक)';

  @override
  String get notesOptional => 'नोट्स (वैकल्पिक)';

  @override
  String get tapToAddBillImage => 'बिल छवि जोड़ने के लिए टैप करें';

  @override
  String get selectBillDateOptional => 'बिल तारीख चुनें (वैकल्पिक)';

  @override
  String get enterStoreOrVendorNameOptional =>
      'स्टोर या विक्रेता नाम दर्ज करें (वैकल्पिक)';

  @override
  String get enterBillOrInvoiceNumberOptional =>
      'बिल या चालान नंबर दर्ज करें (वैकल्पिक)';

  @override
  String get addAnyAdditionalNotes => 'कोई अतिरिक्त नोट्स जोड़ें...';

  @override
  String get submitBill => 'बिल जमा करें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get withdrawBill => 'बिल वापस लें';

  @override
  String get withdrawBillConfirmation =>
      'क्या आप वाकई इस स्वीकृत बिल को वापस लेना चाहते हैं? इससे बढ़ई को दिए गए अंक वापस हो जाएंगे।';

  @override
  String get withdraw => 'वापस लें';

  @override
  String get billWithdrawnSuccess =>
      'बिल सफलतापूर्वक वापस लिया गया। अंक वापस कर दिए गए हैं।';

  @override
  String get failedToWithdrawBill => 'बिल वापस लेने में विफल';

  @override
  String get withdrawApproval => 'स्वीकृति वापस लें';

  @override
  String get reversePointsAndUndoApproval =>
      'अंक वापस करें और स्वीकृति रद्द करें';

  @override
  String get approveBillAction => 'बिल स्वीकृत करें';

  @override
  String get awardPointsAndMarkAsApproved =>
      'अंक दें और स्वीकृत के रूप में चिह्नित करें';

  @override
  String get selectCarpenter => 'बढ़ई चुनें';

  @override
  String get errorLoadingCarpenters => 'बढ़ई लोड करने में त्रुटि';

  @override
  String get noCarpentersFound => 'कोई बढ़ई नहीं मिला';

  @override
  String get noCarpentersAvailable => 'कोई बढ़ई उपलब्ध नहीं';

  @override
  String get billHistory => 'बिल इतिहास';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get from => 'से';

  @override
  String get to => 'तक';

  @override
  String get searchCarpenter => 'बढ़ई खोजें...';

  @override
  String get errorLoadingBillHistory => 'बिल लोड करने में त्रुटि';

  @override
  String get noBillsFoundMatchingFilters =>
      'फ़िल्टर से मेल खाने वाले कोई बिल नहीं मिले';

  @override
  String get noBillsFoundHistory => 'कोई बिल नहीं मिला';

  @override
  String get billDateLabel => 'बिल तारीख';

  @override
  String get submittedLabel => 'जमा किया गया';

  @override
  String get approvedLabel => 'स्वीकृत';

  @override
  String get rejectedLabel => 'अस्वीकृत';

  @override
  String get pts => 'अंक';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get aboutUs => 'हमारे बारे में';

  @override
  String get aboutUsMenuSubtitle => 'सदस्यों के लिए पुरस्कार और लॉयल्टी';

  @override
  String get aboutUsSubtitle => 'आपका हार्डवेयर पुरस्कार साथी';

  @override
  String get aboutUsOverviewTitle => 'बालाजी पॉइंट्स क्या है?';

  @override
  String get aboutUsOverviewBody =>
      'बालाजी पॉइंट्स बढ़ई और हार्डवेयर स्टोर्स के लिए एक डिजिटल लॉयल्टी प्लेटफ़ॉर्म है। यह योग्य सामग्री खरीद को अंक, पुरस्कार और पहचान में बदलने में मदद करता है। आप ऐप से बिल जमा करते हैं; जिस स्टोर में आप जुड़े हैं वह उन्हें जाँचकर स्वीकार करता है; आपका वॉलेट और इतिहास अपडेट होता रहता है ताकि आप हमेशा अपनी स्थिति जान सकें।';

  @override
  String get aboutUsEarningTitle => 'अंक कैसे कमाएँ';

  @override
  String get aboutUsEarningBody =>
      'साफ़ फ़ोटो, सही राशि और जो विवरण स्टोर माँगे उसके साथ खरीद के बिल अपलोड करें। स्टोर एडमिन जमा की जाँच करता है ताकि प्रोग्राम निष्पक्ष रहे और गलती या दुरुपयोग कम हो। स्वीकृति के बाद अंक उसी स्टोर के नियमों से जुड़ते हैं (जैसे रुपये से अंक)। ऐप में कभी भी बैलेंस, लेन-देन इतिहास और टियर प्रगति देख सकते हैं।';

  @override
  String get aboutUsOffersTitle => 'लीडरबोर्ड, ऑफ़र और अपडेट';

  @override
  String get aboutUsOffersBody =>
      'कई स्टोर लीडरबोर्ड चलाते हैं ताकि आप अपने प्रोग्राम में दूसरे बढ़ई के बीच अपनी रैंक देख सकें। आपको बैनर, ऑफ़र और घोषणाएँ भी मिलेंगी—मौसमी डील, बोनस अंक या विशेष प्रचार—ताकि स्टोर जो सुविधाएँ देता है वे छूटें नहीं।';

  @override
  String get aboutUsFairnessTitle => 'स्वीकृति, पारदर्शिता और सहायता';

  @override
  String get aboutUsFairnessBody =>
      'हर बिल की जाँच होती है इसलिए समय लग सकता है। अस्वीकृति पर ऐप में कारण दिखना चाहिए या स्टोर टीम मार्गदर्शन देगी। लॉगिन, पिन, प्रोफ़ाइल या सूचना की समस्या हो तो ऐप के विकल्प और ज़रूरत पड़ने पर स्टोर से संपर्क करें। हम स्पष्ट नियम और लंबित, स्वीकृत व अस्वीकृत बिलों की स्पष्ट स्थिति पर ध्यान देते हैं।';

  @override
  String get aboutUsStoresTitle => 'आपका स्टोर, आपका प्रोग्राम';

  @override
  String get aboutUsStoresBody =>
      'अंक, टियर और ऑफ़र उस हार्डवेयर स्टोर से जुड़े होते हैं जिसमें आप इस ऐप से जुड़े हैं। अलग-अलग स्टोर अलग नियम, रूपांतरण दर और लाभ रख सकते हैं। यदि आप एक से ज़्यादा स्टोर से खरीदते हैं तो हर संबंध आमतौर पर अलग होता है जब तक स्टोर अन्यथा न बताए—विवरण के लिए जिस स्टोर ने आपको जोड़ा है उससे पुष्टि करें।';

  @override
  String get aboutUsClosing =>
      'बालाजी पॉइंट्स उपयोग करने के लिए धन्यवाद—हमें बढ़ई और उन स्टोर्स का साथ देने पर गर्व है जो आपके साथ भागीदार हैं।';

  @override
  String get aboutUsCreditsHeading => 'डिज़ाइन और विकास';

  @override
  String get aboutUsCreditsStudio => 'Aaiji Tech Studio — Vadodara, Gujarat';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get onboardingSlide1Title => 'बिल जमा करें, अंक कमाएँ';

  @override
  String get onboardingSlide1Body =>
      'अपने हार्डवेयर खरीद के बिल अपलोड करें। जब आपका स्टोर उन्हें स्वीकार करता है, अंक आपके वॉलेट में जुड़ जाते हैं।';

  @override
  String get onboardingSlide2Title => 'अपने पुरस्कार देखें';

  @override
  String get onboardingSlide2Body =>
      'अपना बैलेंस, टियर और लीडरबोर्ड रैंक देखें। आप जैसे बढ़ई के लिए बनाए गए ऑफ़र देखें।';

  @override
  String get onboardingSlide3Title => 'अपडेट रहें';

  @override
  String get onboardingSlide3Body =>
      'बिल स्वीकृत या अस्वीकृत होने पर सूचना पाएं। कभी भी प्रोफ़ाइल और पसंद प्रबंधित करें।';

  @override
  String errorWithDetails(String details) {
    return 'त्रुटि: $details';
  }

  @override
  String get siteNameRequired => 'साइट का नाम ज़रूरी है';

  @override
  String get billDateFuture => 'बिल की तारीख भविष्य की नहीं हो सकती';

  @override
  String get duplicateBillDetected => 'डुप्लिकेट बिल मिला';

  @override
  String get duplicateBillIntro =>
      'इसी साइट, राशि और तारीख वाला बिल पहले से मौजूद है:';

  @override
  String get siteNameLabel => 'साइट का नाम';

  @override
  String get amountLabel => 'राशि';

  @override
  String get pointsLabel => 'पॉइंट्स';

  @override
  String get dateLabel => 'तारीख';

  @override
  String ptsValue(String points) {
    return '$points पॉइंट्स';
  }

  @override
  String get duplicateBillVerify =>
      'यह डुप्लिकेट एंट्री हो सकती है। जोड़ने से पहले जाँच लें।';

  @override
  String get addBillAnywayQuestion => 'क्या आप फिर भी यह बिल जोड़ना चाहते हैं?';

  @override
  String get addAnyway => 'फिर भी जोड़ें';

  @override
  String get billsPausedDiwali =>
      'दिवाली उत्सव के लिए बिल जमा करना अभी रोका गया है।';

  @override
  String earnPointsWhenApproved(String points) {
    return 'मंज़ूरी मिलने पर आपको $points पॉइंट्स मिलेंगे';
  }

  @override
  String get vendorNameLabel => 'विक्रेता का नाम';

  @override
  String get menu => 'मेनू';

  @override
  String get hintPassword => 'पासवर्ड दर्ज करें';

  @override
  String get hintPasswordMin => 'पासवर्ड दर्ज करें';

  @override
  String get hintConfirmPassword => 'पासवर्ड दोबारा दर्ज करें';

  @override
  String get hintFullName => 'पूरा नाम दर्ज करें';

  @override
  String get hintAmount => 'राशि दर्ज करें';

  @override
  String get hintBranchFullName => 'ब्रांच का नाम दर्ज करें';

  @override
  String get hintShortName => 'छोटा नाम दर्ज करें';

  @override
  String get hintBranchCode => 'ब्रांच कोड दर्ज करें';

  @override
  String get hintAddress => 'पता दर्ज करें';

  @override
  String get hintRoleName => 'भूमिका का नाम दर्ज करें';

  @override
  String get hintEmail => 'ईमेल दर्ज करें';

  @override
  String get hintPhone => 'फ़ोन नंबर दर्ज करें';

  @override
  String get hintPin => 'PIN दर्ज करें';

  @override
  String get hintConfirmPin => 'PIN दोबारा दर्ज करें';

  @override
  String get hintBranchId => 'ब्रांच ID दर्ज करें';

  @override
  String get diwaliYourPrize => 'आपका दिवाली पुरस्कार';

  @override
  String get diwaliYou => 'आप';

  @override
  String get diwaliPosition => 'स्थान';

  @override
  String get navAddBill => 'बिल जोड़ें';

  @override
  String get navAlerts => 'सूचनाएं';

  @override
  String get readMore => 'और पढ़ें';

  @override
  String get showLess => 'कम दिखाएं';

  @override
  String get diwaliPrizeLoadFailed =>
      'दिवाली इनाम सूची लोड नहीं हो सकी। कृपया फिर से कोशिश करें।';

  @override
  String get featureEarnMore => 'ज़्यादा कमाएँ';

  @override
  String get featureEarnBody => 'बिल अपलोड करें\nपॉइंट्स कमाएँ';

  @override
  String get featureRedeemMore => 'ज़्यादा पाएँ';

  @override
  String get featureRedeemBody => 'शानदार इनाम\nऔर उपहार';

  @override
  String get featureGrowMore => 'आगे बढ़ें';

  @override
  String get featureGrowBody => 'लीडरबोर्ड में ऊपर जाएँ\nटॉप सदस्य बनें';

  @override
  String get featureExclusive => 'खास';

  @override
  String get featureExclusiveBody => 'खास फ़ायदे\nसिर्फ़ आपके लिए';

  @override
  String get newAnnouncement => 'नई घोषणा';

  @override
  String ptsToNextLabel(String points, String tier) {
    return '$tier तक $points पॉइंट्स';
  }

  @override
  String get platinumHighestTier => 'प्लैटिनम — सबसे ऊँचा टियर!';

  @override
  String get topCarpentersTitle => 'टॉप सदस्य';

  @override
  String get noRankingYet => 'अभी रैंकिंग डेटा नहीं है';

  @override
  String get noWinnerToday => 'आज कोई विजेता नहीं';

  @override
  String spinNotDoneYet(String date) {
    return 'अभी स्पिन नहीं हुआ · $date';
  }

  @override
  String get todaysLuckyWinner => 'आज का भाग्यशाली विजेता';

  @override
  String selectedViaDailySpin(String date) {
    return 'डेली स्पिन से चुना गया · $date';
  }

  @override
  String get notificationDeleted => 'सूचना हटा दी गई';

  @override
  String get deleteAllNotifications => 'सभी सूचनाएँ हटाएँ';

  @override
  String get deleteAllNotificationsConfirm =>
      'क्या आप सभी सूचनाएँ हटाना चाहते हैं? इसे वापस नहीं किया जा सकता।';

  @override
  String get deleteAll => 'सभी हटाएँ';

  @override
  String notificationsDeleted(String count) {
    return '$count सूचनाएँ हटाई गईं';
  }

  @override
  String get unableToLoadNotifications => 'सूचनाएँ लोड नहीं हो सकीं';

  @override
  String get errorLoadingNotifications => 'सूचनाएँ लोड करने में त्रुटि';

  @override
  String get noNotificationsTitle => 'कोई सूचना नहीं';

  @override
  String get noNotificationsYet => 'अभी आपके लिए कोई सूचना नहीं है';

  @override
  String get deleteNotification => 'सूचना हटाएँ';

  @override
  String get deleteNotificationConfirm => 'क्या आप यह सूचना हटाना चाहते हैं?';

  @override
  String get addProfilePhoto => 'कृपया प्रोफ़ाइल फ़ोटो जोड़ें';

  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल अपडेट हो गई';

  @override
  String get failedToUpdateProfile => 'प्रोफ़ाइल अपडेट नहीं हो सकी';

  @override
  String get tapToChangePhoto => 'फ़ोटो बदलने के लिए टैप करें';

  @override
  String get lastNameRequired => 'उपनाम *';

  @override
  String get uploadingImage => 'फ़ोटो अपलोड हो रही है...';

  @override
  String get completeProfileToContinue =>
      'आगे बढ़ने के लिए अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get couldNotMakeCall => 'कॉल नहीं हो सकी';

  @override
  String get themeLabel => 'थीम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get youWonLabel => 'आपने जीते';

  @override
  String pointsWon(String points) {
    return '$points पॉइंट्स!';
  }

  @override
  String get pointsAddedToAccount => 'पॉइंट्स आपके खाते में जोड़ दिए गए हैं।';

  @override
  String get great => 'बढ़िया!';

  @override
  String get spinAndWin => 'स्पिन करें और पॉइंट्स जीतें!';

  @override
  String get spinAndWinSubtitle => 'रोज़ स्पिन करें और शानदार पॉइंट्स जीतें';

  @override
  String get alreadySpunToday =>
      'आज आप स्पिन कर चुके हैं!\nकल फिर मौका मिलेगा।';

  @override
  String nextTierLabel(String tier) {
    return 'अगला टियर: $tier';
  }

  @override
  String ptsToNextTier(String points) {
    return 'अगले टियर तक $points पॉइंट्स';
  }

  @override
  String get platinumMaxLevel => 'प्लैटिनम टियर — सबसे ऊँचा स्तर';

  @override
  String get filterLabel => 'फ़िल्टर';

  @override
  String get totalApprovedPoints => 'कुल स्वीकृत पॉइंट्स';

  @override
  String billsCount(String count) {
    return '$count बिल';
  }

  @override
  String get billAttachment => 'बिल की फ़ोटो';

  @override
  String get pendingApproval => 'मंज़ूरी बाकी';

  @override
  String get backToSignIn => 'साइन इन पर वापस जाएँ';

  @override
  String get noPinAccount =>
      'इस नंबर के लिए कोई PIN खाता नहीं मिला। ईमेल और पासवर्ड या Google से साइन इन करें।';

  @override
  String get signInWithMobile => 'मोबाइल नंबर से साइन इन करें';

  @override
  String get continueToPin => 'PIN पर आगे बढ़ें';

  @override
  String get backToOtherSignIn => 'दूसरे साइन-इन विकल्पों पर वापस';

  @override
  String get branchHasAdminDefaulted =>
      'चुनी गई शाखा में पहले से एडमिन है। भूमिका कारपेंटर रखी गई है।';

  @override
  String get selectBranchToContinue => 'आगे बढ़ने के लिए शाखा चुनें।';

  @override
  String get oneAdminPerBranch =>
      'इस शाखा में पहले से एडमिन है। हर शाखा में एक ही एडमिन हो सकता है।';

  @override
  String get branchRequired => 'शाखा *';

  @override
  String get selectYourBranch => 'अपनी शाखा चुनें';

  @override
  String get userRoleRequired => 'उपयोगकर्ता भूमिका *';

  @override
  String get roleCarpenterWoodworker => 'कारपेंटर / लकड़ी कारीगर';

  @override
  String get roleArchitect => 'आर्किटेक्ट';

  @override
  String get roleInteriorDesigner => 'इंटीरियर डिज़ाइनर';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड दोबारा डालें';

  @override
  String get noActiveRoles =>
      'कोई सक्रिय भूमिका उपलब्ध नहीं है। सुपर एडमिन से संपर्क करें।';

  @override
  String get noActiveBranches =>
      'कोई सक्रिय शाखा उपलब्ध नहीं है। अपने एडमिन से संपर्क करें।';

  @override
  String get cancelReturnToSignIn => 'रद्द करें और साइन इन पर लौटें';

  @override
  String get selectRoleRequired => 'भूमिका चुनें *';

  @override
  String get previousPage => 'पिछला';

  @override
  String tablePageInfo(
    String page,
    String pages,
    String from,
    String to,
    String total,
  ) {
    return 'पेज $page/$pages · $total में से $from–$to';
  }

  @override
  String get noRows => 'कोई पंक्ति नहीं';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get maybeLater => 'बाद में';

  @override
  String get requiredLabel => 'ज़रूरी';

  @override
  String get installedLabel => 'इंस्टॉल है';

  @override
  String get updateMandatory =>
      'ऐप इस्तेमाल करते रहने के लिए यह अपडेट ज़रूरी है।';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get billsAppearHere => 'आपके जमा किए गए बिल यहाँ दिखेंगे।';

  @override
  String get pendingBillsAppearHere =>
      'कारपेंटर के नए बिल मंज़ूरी के लिए यहाँ दिखेंगे।';

  @override
  String get tryChangingFilters => 'फ़िल्टर बदलें या हटाकर देखें।';

  @override
  String get carpentersAppearHere => 'पंजीकृत कारपेंटर यहाँ दिखेंगे।';

  @override
  String get statCarpenters => 'कारपेंटर';

  @override
  String get statPendingBills => 'बाकी बिल';

  @override
  String get statAwaitingReview => 'जाँच बाकी';

  @override
  String get statBillsThisMonth => 'इस महीने के बिल';

  @override
  String statApprovedThisMonth(String count) {
    return '$count स्वीकृत';
  }

  @override
  String get statPointsIssued => 'दिए गए पॉइंट्स';

  @override
  String get statThisMonth => 'इस महीने';

  @override
  String get statRegistered => 'पंजीकृत';

  @override
  String version(String version, String buildNumber) {
    return 'संस्करण $version ($buildNumber)';
  }

  @override
  String get switchToLight => 'लाइट मोड चालू करें';

  @override
  String get switchToDark => 'डार्क मोड चालू करें';

  @override
  String get max => 'अधिकतम';

  @override
  String get status => 'स्थिति';

  @override
  String to2(String nextLabel) {
    return '$nextLabel तक';
  }

  @override
  String get spinNow2 => 'अभी स्पिन करें!';

  @override
  String get pleaseCompleteYourProfileFirstName =>
      'बिल जोड़ने और पॉइंट्स कमाने के लिए अपनी प्रोफ़ाइल (पहला नाम, उपनाम और प्रोफ़ाइल फ़ोटो) पूरी करें।';

  @override
  String get goBack => 'वापस जाएँ';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get pleaseLoginToSubmitBills => 'बिल जमा करने के लिए लॉगिन करें';

  @override
  String get billSubmittedSuccessfullyAdminWillReview =>
      'बिल जमा हो गया! एडमिन इसकी जाँच करेंगे।';

  @override
  String get failedToSubmitBillPleaseTry =>
      'बिल जमा नहीं हो सका। कृपया फिर से कोशिश करें।';

  @override
  String get pleaseEnterBillAmount => 'कृपया बिल की राशि डालें';

  @override
  String get billDate2 => 'बिल की तारीख *';

  @override
  String get selectBillDate2 => 'बिल की तारीख चुनें';

  @override
  String get siteName => 'साइट का नाम *';

  @override
  String get enterSiteLocationName => 'साइट का नाम दर्ज करें';

  @override
  String get vendorNameOptional => 'विक्रेता का नाम (वैकल्पिक)';

  @override
  String get enterVendorStoreNameOptional => 'विक्रेता का नाम दर्ज करें';

  @override
  String get noUserLoggedIn => 'कोई उपयोगकर्ता लॉगिन नहीं है';

  @override
  String get firstNameMustBeAtLeast => 'पहला नाम कम से कम 2 अक्षर का हो';

  @override
  String get firstNameIsTooLongMax => 'पहला नाम बहुत लंबा है (अधिकतम 50 अक्षर)';

  @override
  String get lastNameMustBeAtLeast => 'उपनाम कम से कम 2 अक्षर का हो';

  @override
  String get lastNameIsTooLongMax => 'उपनाम बहुत लंबा है (अधिकतम 50 अक्षर)';

  @override
  String get failedToUploadProfileImage => 'प्रोफ़ाइल फ़ोटो अपलोड नहीं हो सकी';

  @override
  String failedToUploadProfileImage2(String e) {
    return 'प्रोफ़ाइल फ़ोटो अपलोड नहीं हो सकी: $e';
  }

  @override
  String get enterYourFirstName => 'पहला नाम दर्ज करें';

  @override
  String get pleaseEnterYourFirstName => 'कृपया अपना पहला नाम डालें';

  @override
  String get enterYourLastName => 'अंतिम नाम दर्ज करें';

  @override
  String get pleaseEnterYourLastName => 'कृपया अपना उपनाम डालें';

  @override
  String get user => 'उपयोगकर्ता';

  @override
  String get language => 'भाषा';

  @override
  String get trackYourPointsAndManageYour =>
      'अपने पॉइंट्स देखें और बिल संभालें';

  @override
  String mAgo(String inMinutes) {
    return '$inMinutes मिनट पहले';
  }

  @override
  String hAgo(String inHours) {
    return '$inHours घंटे पहले';
  }

  @override
  String dAgo(String inDays) {
    return '$inDays दिन पहले';
  }

  @override
  String get notification => 'सूचना';

  @override
  String get noCarpenterAccountsAreListedFor =>
      'इस शाखा में अभी कोई सदस्य खाता नहीं है।';

  @override
  String get continueToHome => 'होम पर जाएँ';

  @override
  String get shubhDeepawali => 'शुभ दीपावली!';

  @override
  String carpenters(String branchName, String carpenterCount) {
    return '$branchName  ·  $carpenterCount कारपेंटर';
  }

  @override
  String carpenterRewardBonusReport(String dateFormat) {
    return 'कारपेंटर इनाम और बोनस रिपोर्ट  ·  $dateFormat';
  }

  @override
  String get closeCelebration => 'उत्सव बंद करें';

  @override
  String get deepawaliPrizeNight => '✦  दीपावली पुरस्कार रात्रि  ✦';

  @override
  String get topPerformersGoldTier => 'टॉप परफ़ॉर्मर — गोल्ड टियर';

  @override
  String get ranks110 => 'रैंक 1-10';

  @override
  String get highPerformersSilverTier => 'बेहतरीन परफ़ॉर्मर — सिल्वर टियर';

  @override
  String get ranks1130 => 'रैंक 11-30';

  @override
  String get activePerformersBronzeTier => 'सक्रिय परफ़ॉर्मर — ब्रॉन्ज़ टियर';

  @override
  String get ranks31Onwards => 'रैंक 31 से आगे';

  @override
  String totalCarpenters(String entries) {
    return 'कुल कारपेंटर: $entries';
  }

  @override
  String get totalPoints2 => 'कुल पॉइंट्स';

  @override
  String get totalReward => 'कुल इनाम';

  @override
  String get totalBonus => 'कुल बोनस';

  @override
  String carpentersPointsRewardBonus(
    String entries,
    String totalPoints,
    String totalReward,
    String totalBonus,
  ) {
    return '$entries कारपेंटर  ·  $totalPoints पॉइंट्स  ·  $totalReward इनाम  ·  $totalBonus बोनस';
  }

  @override
  String bonus(String bonusAmount, String giftDetails) {
    return '$bonusAmount बोनस  ·  $giftDetails';
  }

  @override
  String get mobileNumberUnavailable => 'मोबाइल नंबर उपलब्ध नहीं';

  @override
  String get reward => 'इनाम';

  @override
  String get bonus2 => 'बोनस';

  @override
  String get nil => 'कुछ नहीं';

  @override
  String get gift => 'उपहार';

  @override
  String get reward2 => 'इनाम ₹';

  @override
  String get bonus3 => 'बोनस ₹';

  @override
  String get giftDetails => 'उपहार विवरण';

  @override
  String get remarks => 'टिप्पणी';

  @override
  String get verifyYourIdentityToOpenBalaji =>
      'Balaji Points खोलने के लिए अपनी पहचान सत्यापित करें';

  @override
  String get passwordResetLinksAreSentSecurely =>
      'पासवर्ड रीसेट लिंक सुरक्षित रूप से भेजे जाते हैं।';

  @override
  String get checkYourEmail => 'अपना ईमेल देखें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get ifAnAccountExistsForThis =>
      'अगर इस पते का खाता है, तो पासवर्ड रीसेट निर्देश भेज दिए गए हैं। इनबॉक्स और स्पैम फ़ोल्डर देखें।';

  @override
  String get enterTheEmailAddressLinkedTo =>
      'अपने खाते से जुड़ा ईमेल डालें। नया पासवर्ड चुनने के लिए हम सुरक्षित लिंक भेजेंगे।';

  @override
  String get enterAValidEmailAddress => 'सही ईमेल पता डालें';

  @override
  String get sendAnotherResetLink => 'दूसरा रीसेट लिंक भेजें';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get welcomeBack2 => 'फिर से स्वागत है';

  @override
  String signInToContinueTo(String appName) {
    return '$appName पर आगे बढ़ने के लिए साइन इन करें';
  }

  @override
  String get signIn => 'साइन इन';

  @override
  String get useYourEmailAndPasswordOr =>
      'ईमेल और पासवर्ड से या अपने PIN से साइन इन करें।';

  @override
  String get pleaseEnterAValidEmailAddress => 'कृपया सही ईमेल पता डालें';

  @override
  String get passwordMustBeAtLeast6 => 'पासवर्ड कम से कम 6 अक्षर का हो';

  @override
  String get loginWithPin => 'PIN से लॉगिन करें';

  @override
  String get newToBalajiPoints => 'Balaji Points पर नए हैं? ';

  @override
  String get createAccount2 => 'खाता बनाएँ';

  @override
  String designedAndDevelopedBy(String companyName) {
    return '$companyName द्वारा डिज़ाइन और विकसित';
  }

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get hindi => 'हिंदी';

  @override
  String get tamil => 'तमिल';

  @override
  String get forCurrentMobilePinAccounts => 'मौजूदा मोबाइल + PIN खातों के लिए';

  @override
  String get enterAValid10DigitMobile => 'सही 10 अंकों का मोबाइल नंबर डालें';

  @override
  String get yourDataIs100SecureWith => 'आपका डेटा हमारे पास 100% सुरक्षित है';

  @override
  String get userAlreadyExists => 'उपयोगकर्ता पहले से मौजूद है';

  @override
  String get permissionDeniedPleaseCheckFirebaseConfiguration =>
      'अनुमति नहीं मिली। कृपया एडमिन से संपर्क करें।';

  @override
  String get branchAdminAlreadyAssigned => 'शाखा एडमिन (पहले से तय)';

  @override
  String get branchAdmin1PerBranch => 'शाखा एडमिन (हर शाखा में 1)';

  @override
  String get selectABranchToContinue => 'आगे बढ़ने के लिए शाखा चुनें।';

  @override
  String get selectARoleToContinue => 'आगे बढ़ने के लिए भूमिका चुनें।';

  @override
  String get selectAnActiveRoleToContinue =>
      'आगे बढ़ने के लिए सक्रिय भूमिका चुनें।';

  @override
  String get yourInformationIsProtected => 'आपकी जानकारी सुरक्षित है';

  @override
  String get completeYourGoogleRegistration => 'अपना Google पंजीकरण पूरा करें';

  @override
  String get createYourAccount => 'अपना खाता बनाएँ';

  @override
  String get addYourMobileNumberAndChoose =>
      'खाता सेटअप पूरा करने के लिए मोबाइल नंबर डालें और अपनी शाखा व भूमिका चुनें।';

  @override
  String get chooseYourRoleAndTheBranch => 'अपनी भूमिका और शाखा चुनें।';

  @override
  String get enterYourFullName => 'अपना पूरा नाम डालें';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get useAtLeast6Characters => 'कम से कम 6 अक्षर रखें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get yourAccountAlreadyHasAnAdmin =>
      'आपके खाते में पहले से एडमिन भूमिका है। आगे बढ़ने से पहले सुपर एडमिन से अपनी शाखा तय करवाएँ।';

  @override
  String get branchAdminAccessIsAssignedBy =>
      'शाखा एडमिन की अनुमति सुपर एडमिन देते हैं।';

  @override
  String get completeRegistration => 'पंजीकरण पूरा करें';

  @override
  String get loadingRoles => 'भूमिकाएँ लोड हो रही हैं…';

  @override
  String get chooseOneRole => 'एक भूमिका चुनें';

  @override
  String get selectARoleToContinue2 => 'आगे बढ़ने के लिए भूमिका चुनें';

  @override
  String get loadingBranches => 'शाखाएँ लोड हो रही हैं…';

  @override
  String get selectABranch => 'शाखा चुनें';

  @override
  String cannotMakePhoneCallTo(String phoneNumber) {
    return '$phoneNumber पर कॉल नहीं हो सकती';
  }

  @override
  String errorMakingPhoneCall(String e) {
    return 'कॉल करने में त्रुटि: $e';
  }

  @override
  String get member => 'सदस्य';

  @override
  String get updateRequired => 'अपडेट ज़रूरी';

  @override
  String get newVersionAvailable => 'नया संस्करण उपलब्ध';

  @override
  String get latest => 'नवीनतम';

  @override
  String get completed => 'पूरा';

  @override
  String get processing => 'प्रक्रिया में';

  @override
  String installLatestToContinue(String appName) {
    return 'आगे बढ़ने के लिए $appName का नया संस्करण इंस्टॉल करें।';
  }

  @override
  String get newerVersionReady =>
      'सुधार और बेहतरियों के साथ नया संस्करण तैयार है।';

  @override
  String get pleaseSelectACarpenter => 'कृपया कारपेंटर चुनें';

  @override
  String get billSubmittedSuccessfullyItWillBe =>
      'बिल जमा हो गया! इसकी जाँच की जाएगी।';

  @override
  String get duplicateBill => 'डुप्लिकेट बिल';

  @override
  String get aBillWithTheSameSite =>
      'इस कारपेंटर के लिए इसी साइट, राशि और तारीख वाला बिल पहले से है:';

  @override
  String get site => 'साइट';

  @override
  String pts2(String duplicatePoints) {
    return '$duplicatePoints पॉइंट्स';
  }

  @override
  String get pleaseVerifyThisIsNotA =>
      'कृपया जाँच लें कि यह डुप्लिकेट एंट्री नहीं है।';

  @override
  String error2(String e) {
    return 'त्रुटि: $e';
  }

  @override
  String get addAnyway2 => 'फिर भी जोड़ें';

  @override
  String get addBillForCarpenter => 'कारपेंटर के लिए बिल जोड़ें';

  @override
  String get carpenter2 => 'कारपेंटर *';

  @override
  String get billAmount2 => 'बिल राशि (₹) *';

  @override
  String get billImageOptional => 'बिल की फ़ोटो (वैकल्पिक)';

  @override
  String get siteName2 => 'साइट का नाम';

  @override
  String get vendorName => 'विक्रेता का नाम';

  @override
  String get pendingApproval2 => 'मंज़ूरी बाकी';

  @override
  String areYouSureYouWantTo(String billData) {
    return 'क्या आप यह बिल मंज़ूर करना चाहते हैं?\n\n₹$billData प्रोसेस होंगे।';
  }

  @override
  String get billRejected2 => 'बिल अस्वीकार किया गया';

  @override
  String get share => 'शेयर करें';

  @override
  String get billNotFound => 'बिल नहीं मिला';

  @override
  String get billId => 'बिल आईडी';

  @override
  String submitted(String createdAt) {
    return 'जमा किया $createdAt';
  }

  @override
  String get submittedOn => 'जमा करने की तारीख';

  @override
  String get store => 'दुकान';

  @override
  String get carpenterInfo => 'कारपेंटर की जानकारी';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String pts3(String totalPoints) {
    return '$totalPoints पॉइंट्स';
  }

  @override
  String get billSummary => 'बिल सारांश';

  @override
  String get billAmount3 => 'बिल राशि';

  @override
  String get pointsToCredit => 'जोड़े जाने वाले पॉइंट्स';

  @override
  String get billNo => 'बिल नं.';

  @override
  String get pointsRate => 'पॉइंट दर';

  @override
  String get t1Pt1000 => '1 पॉइंट / ₹1000';

  @override
  String get billType => 'बिल का प्रकार';

  @override
  String get purchase => 'खरीद';

  @override
  String get billAttachment2 => 'बिल की फ़ोटो';

  @override
  String get viewFullSize => 'पूरा आकार देखें';

  @override
  String get downloadImage => 'फ़ोटो डाउनलोड करें';

  @override
  String get generatePdf => 'PDF बनाएँ';

  @override
  String get timeline => 'समयरेखा';

  @override
  String get billCreated => 'बिल बना';

  @override
  String get waitingForApproval => 'मंज़ूरी का इंतज़ार';

  @override
  String get pendingActionFromAdmin => 'एडमिन की कार्रवाई बाकी';

  @override
  String get justNow2 => 'अभी-अभी';

  @override
  String minAgo(String inMinutes) {
    return '$inMinutes मिनट पहले';
  }

  @override
  String billDetails2(String billId) {
    return 'बिल विवरण - $billId';
  }

  @override
  String get errorLoadingBillDetails => 'बिल विवरण लोड करने में त्रुटि';

  @override
  String get noBillFound => 'कोई बिल नहीं मिला';

  @override
  String get totalInstances => 'कुल प्रविष्टियाँ';

  @override
  String get billEntries => 'बिल प्रविष्टियाँ';

  @override
  String instance(String index) {
    return 'प्रविष्टि $index';
  }

  @override
  String get time => 'समय';

  @override
  String get noBillsToExportApplyFilters =>
      'निर्यात के लिए कोई बिल नहीं। फ़िल्टर लगाएँ या डेटा का इंतज़ार करें।';

  @override
  String get preparingPdf => 'PDF तैयार हो रहा है...';

  @override
  String get noBillsMatchCurrentFiltersFor =>
      'मौजूदा फ़िल्टर से कोई बिल मेल नहीं खाता।';

  @override
  String exportFailed(String e) {
    return 'निर्यात विफल: $e';
  }

  @override
  String get bill => 'बिल #';

  @override
  String get approvedDate => 'मंज़ूरी की तारीख';

  @override
  String get actions => 'कार्रवाई';

  @override
  String get exportAllBillsToPdf => 'सभी बिल PDF में निर्यात करें';

  @override
  String approveThisBillOfPointsWill(String amount, String amount2) {
    return '₹$amount का यह बिल मंज़ूर करें?\n\nकारपेंटर को $amount2 पॉइंट्स मिलेंगे।';
  }

  @override
  String get billApprovedAndPointsAddedSuccessfully =>
      'बिल मंज़ूर हुआ और पॉइंट्स जोड़ दिए गए';

  @override
  String get failedToApproveBill2 => 'बिल मंज़ूर नहीं हो सका';

  @override
  String errorApprovingBill(String e) {
    return 'बिल मंज़ूर करने में त्रुटि: $e';
  }

  @override
  String get failedToRejectBill2 => 'बिल अस्वीकार नहीं हो सका';

  @override
  String errorRejectingBill(String e) {
    return 'बिल अस्वीकार करने में त्रुटि: $e';
  }

  @override
  String get dateFilters => 'तारीख फ़िल्टर';

  @override
  String get clearFilters => 'फ़िल्टर हटाएँ';

  @override
  String pts4(String amount) {
    return '$amount पॉइंट्स';
  }

  @override
  String get noHistoryAvailable => 'कोई इतिहास नहीं';

  @override
  String get carpenterSummary => 'कारपेंटर सारांश';

  @override
  String totalPts(String totalPoints) {
    return 'कुल: $totalPoints पॉइंट्स';
  }

  @override
  String get totalBills => 'कुल बिल';

  @override
  String get pointsBySite => 'साइट के अनुसार पॉइंट्स';

  @override
  String pts5(String num) {
    return '$num पॉइंट्स';
  }

  @override
  String get site2 => 'साइट: ';

  @override
  String get billDate3 => 'बिल की तारीख: ';

  @override
  String get approved2 => 'मंज़ूर: ';

  @override
  String get submitted2 => 'जमा: ';

  @override
  String get allBillsHistory => 'सभी बिलों का इतिहास';

  @override
  String bills(String filtered, String billsList) {
    return '$filtered/$billsList बिल';
  }

  @override
  String get filterBySite => 'साइट से फ़िल्टर करें';

  @override
  String get allSites => 'सभी साइटें';

  @override
  String billId2(String index, String billNum) {
    return '#$index - बिल आईडी: $billNum';
  }

  @override
  String pts6(String pts) {
    return '$pts पॉइंट्स';
  }

  @override
  String get transactions => 'लेनदेन';

  @override
  String get rewards => 'इनाम';

  @override
  String get deleteAllNotifications2 => 'सभी सूचनाएँ हटाएँ';

  @override
  String get areYouSureYouWantTo2 =>
      'क्या आप सभी एडमिन सूचनाएँ हटाना चाहते हैं?';

  @override
  String notificationSDeleted(String docs) {
    return '$docs सूचनाएँ हटाई गईं';
  }

  @override
  String deleteFailed(String e) {
    return 'हटाना विफल: $e';
  }

  @override
  String get balajiPointsAdminPanel => 'Balaji Points - एडमिन पैनल';

  @override
  String get branchAdmin => 'शाखा एडमिन';

  @override
  String get spin => 'स्पिन';

  @override
  String get pointsRepair => 'पॉइंट्स सुधार';

  @override
  String get duplicateAccounts => 'डुप्लिकेट खाते';

  @override
  String get exportUsers => 'उपयोगकर्ता निर्यात';

  @override
  String get cleanUp => 'साफ़ करें';

  @override
  String get backupDatabase => 'डेटाबेस बैकअप';

  @override
  String get checkFirebaseDuplicates => 'डेटाबेस डुप्लिकेट जाँचें';

  @override
  String get smartCleanup => 'स्मार्ट सफ़ाई';

  @override
  String get sendGreeting => 'शुभकामना भेजें';

  @override
  String get users2 => 'उपयोगकर्ता - ...';

  @override
  String users3(String count) {
    return 'उपयोगकर्ता - $count';
  }

  @override
  String get pleaseEnterPinInBothFields => 'दोनों जगह PIN डालें';

  @override
  String get pinMustBe46Digits => 'PIN 4-6 अंकों का हो';

  @override
  String get pinMustContainOnlyNumbers => 'PIN में सिर्फ़ अंक हों';

  @override
  String get pinResetSuccessfully => 'PIN रीसेट हो गया';

  @override
  String errorResettingPin(String e) {
    return 'PIN रीसेट करने में त्रुटि: $e';
  }

  @override
  String resetPinFor(String carpenterName) {
    return 'इनका PIN रीसेट करें: $carpenterName';
  }

  @override
  String phone2(String carpenterPhone) {
    return 'फ़ोन: $carpenterPhone';
  }

  @override
  String get carpenterWillNeedToUseThis =>
      'कारपेंटर को इस नए PIN से लॉगिन करना होगा। इसे सुरक्षित तरीके से बताएँ।';

  @override
  String get newPin46Digits => 'नया PIN (4-6 अंक)';

  @override
  String get carpenterDetails => 'कारपेंटर विवरण';

  @override
  String get carpenterNotFound => 'कारपेंटर नहीं मिला';

  @override
  String get carpenterInformation => 'कारपेंटर की जानकारी';

  @override
  String get branch => 'शाखा';

  @override
  String get completeHistory => 'पूरा इतिहास';

  @override
  String get clearAll => 'सब हटाएँ';

  @override
  String get fromDate => 'शुरू की तारीख';

  @override
  String get toDate => 'अंतिम तारीख';

  @override
  String get editCarpenter => 'कारपेंटर बदलें';

  @override
  String get changingPhoneNumberWillUpdateLogin =>
      'फ़ोन नंबर बदलने से लॉगिन जानकारी बदल जाएगी';

  @override
  String get branchId => 'शाखा आईडी';

  @override
  String get phoneNumberCannotBeEmpty => 'फ़ोन नंबर खाली नहीं हो सकता';

  @override
  String get carpenterUpdatedSuccessfully => 'कारपेंटर अपडेट हो गया';

  @override
  String errorUpdatingCarpenter(String e) {
    return 'कारपेंटर अपडेट करने में त्रुटि: $e';
  }

  @override
  String get update => 'अपडेट करें';

  @override
  String get pendingBillRequests => 'बाकी बिल अनुरोध';

  @override
  String get siteMaterialPurchase => 'साइट सामग्री खरीद';

  @override
  String billNo2(String billNumber) {
    return 'बिल नं. $billNumber';
  }

  @override
  String site3(String siteName) {
    return 'साइट: $siteName';
  }

  @override
  String pts7(String amount) {
    return '+$amount पॉइंट्स';
  }

  @override
  String approveThisBillOfPointsWill2(String amount, String amount2) {
    return '₹$amount का यह बिल मंज़ूर करें?\n\n$amount2 पॉइंट्स जोड़े जाएँगे।';
  }

  @override
  String get noHistoryFound => 'कोई इतिहास नहीं मिला';

  @override
  String get pointsAwarded => 'पॉइंट्स दिए गए';

  @override
  String get pinMustBeAtLeast4 => 'PIN कम से कम 4 अंकों का हो';

  @override
  String get carpenterCreatedSuccessfully => 'कारपेंटर बन गया!';

  @override
  String get failedToCreateCarpenter => 'कारपेंटर नहीं बन सका';

  @override
  String get pin46Digits => '4 अंकों का PIN';

  @override
  String get enterPin => 'PIN दर्ज करें';

  @override
  String get firstNameOptional => 'पहला नाम (वैकल्पिक)';

  @override
  String get enterFirstName => 'पहला नाम दर्ज करें';

  @override
  String get lastNameOptional => 'उपनाम (वैकल्पिक)';

  @override
  String get enterLastName => 'अंतिम नाम दर्ज करें';

  @override
  String get create => 'बनाएँ';

  @override
  String get preparingCarpenterListPdf =>
      'कारपेंटर सूची PDF तैयार हो रही है...';

  @override
  String get noCarpentersToExportForCurrent =>
      'मौजूदा फ़िल्टर में निर्यात के लिए कोई कारपेंटर नहीं।';

  @override
  String get carpenterListExportedSuccessfully =>
      'कारपेंटर सूची निर्यात हो गई!';

  @override
  String errorExportingPdf(String e) {
    return 'PDF निर्यात में त्रुटि: $e';
  }

  @override
  String get exportCarpenterListToPdf => 'कारपेंटर सूची PDF में निर्यात करें';

  @override
  String get sortByPoints => 'पॉइंट्स से क्रम';

  @override
  String get sortByName => 'नाम से क्रम';

  @override
  String get recentJoins => 'हाल में जुड़े';

  @override
  String tier(String tier) {
    return 'टियर: $tier';
  }

  @override
  String phoneTierPoints(String phone, String tier, String totalPoints) {
    return 'फ़ोन: $phone\nटियर: $tier\nपॉइंट्स: $totalPoints';
  }

  @override
  String points2(String num) {
    return '$num पॉइंट्स';
  }

  @override
  String get deleteAll2 => 'सभी हटाएँ';

  @override
  String get unableToLoadAdminNotifications => 'एडमिन सूचनाएँ लोड नहीं हो सकीं';

  @override
  String get noNotifications => 'कोई सूचना नहीं';

  @override
  String get youDonTHaveAnyAdmin => 'अभी कोई एडमिन सूचना नहीं है';

  @override
  String get deleteNotification2 => 'सूचना हटाएँ';

  @override
  String get dailySpinHistory => 'डेली स्पिन इतिहास';

  @override
  String text(String month, String year) {
    return '$month $year';
  }

  @override
  String get mon => 'सोम';

  @override
  String get tue => 'मंगल';

  @override
  String get wed => 'बुध';

  @override
  String get thu => 'गुरु';

  @override
  String get fri => 'शुक्र';

  @override
  String get sat => 'शनि';

  @override
  String get spinned => 'स्पिन हुआ';

  @override
  String get noSpin => 'स्पिन नहीं';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get spinWinner => 'स्पिन विजेता';

  @override
  String get winnerName => 'विजेता का नाम';

  @override
  String failedToFetchCarpenters(String e) {
    return 'कारपेंटर नहीं मिल सके: $e';
  }

  @override
  String failedToPickImage2(String e) {
    return 'फ़ोटो नहीं चुनी जा सकी: $e';
  }

  @override
  String failedToCaptureImage(String e) {
    return 'फ़ोटो नहीं ली जा सकी: $e';
  }

  @override
  String failedToUploadImage(String e) {
    return 'फ़ोटो अपलोड नहीं हो सकी: $e';
  }

  @override
  String notificationSentToCarpenters(String notificationCount) {
    return '$notificationCount कारपेंटर को सूचना भेजी गई';
  }

  @override
  String failedToSendNotifications(String e) {
    return 'सूचनाएँ नहीं भेजी जा सकीं: $e';
  }

  @override
  String get pleaseEnterAMessage => 'कृपया संदेश लिखें';

  @override
  String get pleaseSelectAtLeastOneChannel => 'कम से कम एक माध्यम चुनें';

  @override
  String get notAuthenticated => 'लॉगिन नहीं है';

  @override
  String get showInApp => 'ऐप में दिखाएँ';

  @override
  String get greetingSentSuccessfully => 'शुभकामना भेज दी गई!';

  @override
  String get sendingGreeting => 'शुभकामना भेजी जा रही है...';

  @override
  String get composeMessage => 'संदेश लिखें';

  @override
  String get enterGreetingMessageForAllCarpenters => 'संदेश दर्ज करें';

  @override
  String get imageOptional => 'फ़ोटो (वैकल्पिक)';

  @override
  String get pickFromGallery => 'गैलरी से चुनें';

  @override
  String get orEnterImageUrl => 'या फ़ोटो का URL डालें:';

  @override
  String get enterImageUrlJpgPng => 'इमेज URL दर्ज करें';

  @override
  String get invalidImageUrl => 'गलत फ़ोटो URL';

  @override
  String get selectChannels => 'माध्यम चुनें';

  @override
  String get showInAppHomeBanner => 'ऐप में दिखाएँ (होम बैनर)';

  @override
  String get bannerOnCarpenterHomeScreen => 'कारपेंटर होम स्क्रीन पर बैनर';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get manualSendViaWhatsappApp => 'WhatsApp ऐप से खुद भेजें';

  @override
  String get manualSendViaSmsApp => 'SMS ऐप से खुद भेजें';

  @override
  String get noteWhatsappAndSmsUseDevice =>
      'नोट: WhatsApp और SMS फ़ोन के ऐप से भेजे जाते हैं। एडमिन को हर संदेश उस ऐप में पुष्टि करना होगा।';

  @override
  String whatsappNotAvailableFor(String name) {
    return '$name के लिए WhatsApp उपलब्ध नहीं';
  }

  @override
  String smsNotAvailableFor(String name) {
    return '$name के लिए SMS उपलब्ध नहीं';
  }

  @override
  String get sendToAll => 'सभी को भेजें?';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String progress(String i, String carpenters) {
    return 'प्रगति: $i/$carpenters';
  }

  @override
  String opened(String name, String phone) {
    return 'खोला गया: $name\n$phone';
  }

  @override
  String get tapSendInTheAppThen =>
      'ऐप में भेजें दबाएँ, फिर आगे बढ़ने के लिए यहाँ OK दबाएँ।';

  @override
  String sentToAllCarpenters(String sentCount) {
    return 'सभी $sentCount कारपेंटर को भेजा गया';
  }

  @override
  String get confirmSend => 'भेजने की पुष्टि करें';

  @override
  String get sendAll => 'सभी को भेजें';

  @override
  String get sendViaWhatsapp => 'WhatsApp से भेजें';

  @override
  String get sendViaSms => 'SMS से भेजें';

  @override
  String get pleaseWait24HoursFromThe =>
      'पिछले स्पिन के बाद 24 घंटे इंतज़ार करें';

  @override
  String get noCarpentersWithApprovedBillsToday =>
      'आज किसी कारपेंटर का बिल मंज़ूर नहीं हुआ';

  @override
  String get noEligibleCarpentersFound => 'कोई योग्य कारपेंटर नहीं मिला';

  @override
  String isTodaySWinner(String carpenterName) {
    return '$carpenterName आज के विजेता हैं!';
  }

  @override
  String get selectALuckyWinner => 'भाग्यशाली विजेता चुनें';

  @override
  String get viewSpinHistory => 'स्पिन इतिहास देखें';

  @override
  String winner2(String winnerName) {
    return 'विजेता: $winnerName';
  }

  @override
  String get noPreviousSpins => 'पहले कोई स्पिन नहीं';

  @override
  String get readyToSpin => 'स्पिन के लिए तैयार!';

  @override
  String nextSpinInHM(String hoursRemaining, String minutesRemaining) {
    return 'अगला स्पिन: $hoursRemaining घं $minutesRemaining मि में';
  }

  @override
  String get todaySWinners => 'आज के विजेता';

  @override
  String get noWinnersYetToday => 'आज अभी कोई विजेता नहीं';

  @override
  String get monthlyWinners => 'मासिक विजेता';

  @override
  String get fullHistory => 'पूरा इतिहास';

  @override
  String get noWinnersThisMonthYet => 'इस महीने अभी कोई विजेता नहीं';

  @override
  String get untitled => 'बिना शीर्षक';

  @override
  String get pleaseEnterAValidNumberFor => 'पॉइंट्स के लिए सही संख्या डालें';

  @override
  String get pleaseUploadABannerImage => 'कृपया बैनर फ़ोटो अपलोड करें';

  @override
  String get failedToUploadBannerImage => 'बैनर फ़ोटो अपलोड नहीं हो सकी';

  @override
  String get loadingEligibleCarpenters => 'योग्य कारपेंटर लोड हो रहे हैं...';

  @override
  String get errorLoadingData => 'डेटा लोड करने में त्रुटि';

  @override
  String get noEligibleCarpentersToday => 'आज कोई योग्य कारपेंटर नहीं';

  @override
  String get noCarpentersHaveApprovedBillsToday =>
      'आज किसी कारपेंटर का बिल मंज़ूर नहीं हुआ।\nडेली स्पिन के लिए बिल मंज़ूर करें!';

  @override
  String get todaySEligibleCarpenters => 'आज के योग्य कारपेंटर';

  @override
  String eligible(String todayStr, String carpenters) {
    return '$todayStr • $carpenters योग्य';
  }

  @override
  String get branchAdminAccounts => 'शाखा एडमिन खाते';

  @override
  String get reviewEachAdminAndTheBranch =>
      'हर एडमिन और उनकी शाखा देखें। पासवर्ड बदलें या खाता हटाएँ।';

  @override
  String get searchByNameEmailOrBranch => 'एडमिन खोजें';

  @override
  String get clearSearch => 'खोज साफ़ करें';

  @override
  String get loadingBranchAdminAccounts => 'शाखा एडमिन खाते लोड हो रहे हैं…';

  @override
  String get noBranchAdminAccountsYet => 'अभी कोई शाखा एडमिन खाता नहीं।';

  @override
  String get loadingBranchNames => 'शाखाओं के नाम लोड हो रहे हैं…';

  @override
  String get noEmail => 'ईमेल नहीं';

  @override
  String noAdminAccountsMatch(String search) {
    return '“$search” से कोई एडमिन खाता मेल नहीं खाता।';
  }

  @override
  String get adminAccounts => 'एडमिन खाते';

  @override
  String passwordUpdatedFor(String email) {
    return '$email का पासवर्ड बदल दिया गया।';
  }

  @override
  String get deleteBranchAdmin => 'शाखा एडमिन हटाएँ?';

  @override
  String deleteForTheyWillLoseSign(String email, String branchName) {
    return '$branchName के लिए $email हटाएँ? वे साइन इन नहीं कर पाएँगे। शाखा के सदस्य और उनके पॉइंट्स बने रहेंगे।';
  }

  @override
  String get deleteAdmin => 'एडमिन हटाएँ';

  @override
  String get adminAccountDeleted => 'एडमिन खाता हटा दिया गया।';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get changeAdminPassword => 'एडमिन पासवर्ड बदलें';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get useAtLeast8Characters => 'कम से कम 8 अक्षर रखें';

  @override
  String get confirmNewPassword => 'नया पासवर्ड दोबारा डालें';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get branchManagement => 'शाखा प्रबंधन';

  @override
  String branchesManageBranchAccessAndStatus(String docs) {
    return '$docs शाखाएँ · शाखा की पहुँच और स्थिति संभालें';
  }

  @override
  String get addBranch => 'शाखा जोड़ें';

  @override
  String get noBranchesYet => 'अभी कोई शाखा नहीं।';

  @override
  String get branchesCouldNotBeLoaded => 'शाखाएँ लोड नहीं हो सकीं।';

  @override
  String get diwaliCelebrationEnabledAddBillIs =>
      'दिवाली उत्सव चालू। इस शाखा में बिल जोड़ना छिपा है।';

  @override
  String get diwaliCelebrationDisabledAddBillIs =>
      'दिवाली उत्सव बंद। इस शाखा में बिल जोड़ना उपलब्ध है।';

  @override
  String get unableToUpdateTheBranchCelebration =>
      'शाखा उत्सव सेटिंग अपडेट नहीं हो सकी।';

  @override
  String codeId(String branchCode, String branchId) {
    return 'कोड: $branchCode  ·  आईडी: $branchId';
  }

  @override
  String get diwaliCelebrationOnHome => 'होम पर दिवाली उत्सव';

  @override
  String get showsTheBranchPrizeListAnd =>
      'शाखा की इनाम सूची दिखाता है और बिल जोड़ना छिपाता है।';

  @override
  String get offNoPopupAddBillRemains =>
      'बंद: कोई पॉपअप नहीं; बिल जोड़ना उपलब्ध रहेगा।';

  @override
  String get branchDeactivated => 'शाखा निष्क्रिय की गई।';

  @override
  String get branchActivated => 'शाखा सक्रिय की गई।';

  @override
  String get unableToUpdateTheBranch => 'शाखा अपडेट नहीं हो सकी।';

  @override
  String get deactivate => 'निष्क्रिय करें';

  @override
  String get activate => 'सक्रिय करें';

  @override
  String branchCreated(String id) {
    return 'शाखा बनाई गई ($id)';
  }

  @override
  String get failedToCreateBranch => 'शाखा नहीं बन सकी';

  @override
  String get newBranch => 'नई शाखा';

  @override
  String get branchFullName => 'शाखा का पूरा नाम *';

  @override
  String get shortName => 'छोटा नाम *';

  @override
  String get enterAShortBranchName => 'शाखा का छोटा नाम डालें';

  @override
  String get branchCode => 'शाखा कोड *';

  @override
  String get use216LettersNumbersOr => '2–16 अक्षर, अंक या हाइफ़न रखें';

  @override
  String get address => 'पता';

  @override
  String get shareTheTemporaryPasswordSecurelyThe =>
      'अस्थायी पासवर्ड सुरक्षित तरीके से बताएँ। एडमिन पहली बार साइन इन के बाद इसे बदल सकते हैं।';

  @override
  String adminCreatedForTheyCanSign(String email, String branchName) {
    return '$branchName के लिए एडमिन $email बनाया गया। वे ईमेल और पासवर्ड से साइन इन कर सकते हैं।';
  }

  @override
  String get selectABranchFirst => 'पहले शाखा चुनें।';

  @override
  String get adminDetails => 'एडमिन विवरण';

  @override
  String get mobileNumber10Digits => 'मोबाइल नंबर * (10 अंक)';

  @override
  String get enterValid10DigitPhone => 'सही 10 अंकों का फ़ोन नंबर डालें';

  @override
  String get emailAndPasswordLogin => 'ईमेल और पासवर्ड लॉगिन';

  @override
  String get emailAddress => 'ईमेल पता *';

  @override
  String get temporaryPassword8CharactersMinimum =>
      'अस्थायी पासवर्ड * (कम से कम 8 अक्षर)';

  @override
  String get confirmPassword => 'पासवर्ड दोबारा डालें *';

  @override
  String get assignBranch => 'शाखा तय करें';

  @override
  String get loadingActiveBranches => 'सक्रिय शाखाएँ लोड हो रही हैं…';

  @override
  String get noActiveBranchesFoundCreateOr =>
      'कोई सक्रिय शाखा नहीं। एडमिन जोड़ने से पहले शाखा बनाएँ या सक्रिय करें।';

  @override
  String get selectBranch => 'शाखा चुनें';

  @override
  String get creatingAccount => 'खाता बन रहा है…';

  @override
  String get createAdminAccount => 'एडमिन खाता बनाएँ';

  @override
  String get signOutOfSuperAdmin => 'सुपर एडमिन से साइन आउट करें?';

  @override
  String get superAdmin => 'सुपर एडमिन';

  @override
  String get superAdminConsole => 'सुपर एडमिन कंसोल';

  @override
  String get branchesAdministratorsAndPoints => 'शाखाएँ, एडमिन और पॉइंट्स';

  @override
  String get branches => 'शाखाएँ';

  @override
  String get createAdmin => 'एडमिन बनाएँ';

  @override
  String get roles => 'भूमिकाएँ';

  @override
  String get superAdmin2 => 'सुपर एडमिन';

  @override
  String get createAdmin2 => 'एडमिन बनाएँ';

  @override
  String get pointsReset => 'पॉइंट्स रीसेट';

  @override
  String get onlyPointsTiersAndPointsHistory =>
      'सिर्फ़ कारपेंटर, आर्किटेक्ट, इंजीनियर और इंटीरियर डिज़ाइनर के पॉइंट्स, टियर और इतिहास मिटेंगे। खाते, लॉगिन, शाखा एडमिन और बिल वैसे ही रहेंगे।';

  @override
  String get afterPrizeDistributionStartAFresh =>
      'इनाम बाँटने के बाद एक शाखा के लिए नया पॉइंट्स सीज़न शुरू करें।';

  @override
  String resetUsersAndDeletedHistoryRecords(
    String branchName,
    String usersReset,
    String historyDocumentsDeleted,
  ) {
    return '$branchName: $usersReset उपयोगकर्ता रीसेट हुए और $historyDocumentsDeleted इतिहास रिकॉर्ड हटाए गए। खाते और बिल बने रहे।';
  }

  @override
  String get thisPermanentlyClearsPointsAndPoints =>
      'इससे इस शाखा के कारपेंटर, आर्किटेक्ट, इंजीनियर और इंटीरियर डिज़ाइनर के पॉइंट्स और इतिहास हमेशा के लिए मिट जाएँगे। उपयोगकर्ता खाते, शाखा एडमिन और बिल बने रहेंगे।';

  @override
  String hasEligibleUsersPointsAndHistory(
    String branchName,
    String eligibleUsers,
    String currentPoints,
    String historyDocuments,
  ) {
    return '$branchName में $eligibleUsers योग्य उपयोगकर्ता, $currentPoints पॉइंट्स और $historyDocuments इतिहास रिकॉर्ड हैं।';
  }

  @override
  String get resetBranchPoints => 'शाखा के पॉइंट्स रीसेट करें?';

  @override
  String typeToConfirm(String branchId) {
    return 'पुष्टि के लिए $branchId लिखें';
  }

  @override
  String get resetPointsAndHistory => 'पॉइंट्स और इतिहास रीसेट करें';

  @override
  String get couldNotLoadBranchesForPoints =>
      'पॉइंट्स सफ़ाई के लिए शाखाएँ लोड नहीं हो सकीं।';

  @override
  String get annualPointsReset => 'सालाना पॉइंट्स रीसेट';

  @override
  String get branchToReset => 'रीसेट करने वाली शाखा';

  @override
  String get checkingBranch => 'शाखा जाँची जा रही है…';

  @override
  String get previewReset => 'रीसेट का पूर्वावलोकन';

  @override
  String get createABranchBeforeResettingPoints =>
      'पॉइंट्स रीसेट से पहले शाखा बनाएँ।';

  @override
  String cleanupPreview(String branchName) {
    return 'सफ़ाई पूर्वावलोकन · $branchName';
  }

  @override
  String get eligibleUsers => 'योग्य उपयोगकर्ता';

  @override
  String get currentPoints => 'मौजूदा पॉइंट्स';

  @override
  String get historyItems => 'इतिहास रिकॉर्ड';

  @override
  String get resettingBranchPoints => 'शाखा के पॉइंट्स रीसेट हो रहे हैं…';

  @override
  String couldNotLoadSavedRolesShowing(String loadError) {
    return 'सहेजी गई भूमिकाएँ लोड नहीं हुईं। चार मूल भूमिकाएँ दिखाई जा रही हैं। $loadError';
  }

  @override
  String get roleIdsAreStoredWithUser =>
      'भूमिका आईडी उपयोगकर्ता खातों के साथ सहेजी जाती है। भूमिका हटाने पर वह नए पंजीकरण से हटती है, मौजूदा खाते बने रहते हैं।';

  @override
  String willBeRemovedFromNewRegistration(String name) {
    return '$name नए पंजीकरण से हट जाएगी। मौजूदा उपयोगकर्ताओं की भूमिका और डेटा बना रहेगा।';
  }

  @override
  String roleCreated(String name, String id) {
    return 'भूमिका बनाई गई: $name ($id)।';
  }

  @override
  String get restoreRole => 'भूमिका वापस लाएँ?';

  @override
  String get deleteRole => 'भूमिका हटाएँ?';

  @override
  String willBeAvailableForNewAccount(String name) {
    return '$name नए खाता पंजीकरण में उपलब्ध होगी।';
  }

  @override
  String get restoreRole2 => 'भूमिका वापस लाएँ';

  @override
  String get deleteRole2 => 'भूमिका हटाएँ';

  @override
  String get accountRoles => 'खाता भूमिकाएँ';

  @override
  String get manageTheRolesShownInCreate =>
      'खाता बनाते समय दिखने वाली भूमिकाएँ संभालें।';

  @override
  String get addRole => 'भूमिका जोड़ें';

  @override
  String get loadingAccountRoles => 'खाता भूमिकाएँ लोड हो रही हैं…';

  @override
  String get noRolesFound => 'कोई भूमिका नहीं मिली।';

  @override
  String roleId(String id) {
    return 'भूमिका आईडी: $id';
  }

  @override
  String get restore => 'वापस लाएँ';

  @override
  String get deleted => 'हटाई गई';

  @override
  String get addAccountRole => 'खाता भूमिका जोड़ें';

  @override
  String get roleName => 'भूमिका का नाम *';

  @override
  String get enterAtLeast2Characters => 'कम से कम 2 अक्षर डालें';

  @override
  String get shortFormOptional => 'छोटा रूप (वैकल्पिक)';

  @override
  String get exampleAr => 'छोटा रूप दर्ज करें';

  @override
  String get use10CharactersOrLess => '10 या कम अक्षर रखें';

  @override
  String get saving => 'सहेजा जा रहा है…';

  @override
  String get saveRole => 'भूमिका सहेजें';

  @override
  String get cleanUpDuplicates => 'डुप्लिकेट साफ़ करें';

  @override
  String error3(String error) {
    return 'त्रुटि: $error';
  }

  @override
  String get duplicatesFound => 'डुप्लिकेट मिले';

  @override
  String accountsAcrossPhoneNumbers(String duplicateCount, String duplicates) {
    return '$duplicates फ़ोन नंबरों पर $duplicateCount खाते';
  }

  @override
  String get noDuplicatesFound => 'कोई डुप्लिकेट नहीं मिला!';

  @override
  String get allCarpenterAccountsAreUnique => 'सभी कारपेंटर खाते अलग हैं।';

  @override
  String get duplicateGroups => 'डुप्लिकेट समूह';

  @override
  String phoneAccounts(String groupIndex, String phone, String users) {
    return '$groupIndex. फ़ोन: $phone ($users खाते)';
  }

  @override
  String get keep => 'रखें';

  @override
  String get reviewOnly => 'सिर्फ़ जाँचें';

  @override
  String diagnosticUser(String phoneNumber) {
    return 'जाँच: उपयोगकर्ता $phoneNumber';
  }

  @override
  String get noData => 'कोई डेटा नहीं';

  @override
  String get phoneNumberInformation => 'फ़ोन नंबर जानकारी';

  @override
  String get originalPhone => 'मूल फ़ोन';

  @override
  String get normalizedPhone => 'मानक फ़ोन';

  @override
  String get match => 'मेल';

  @override
  String get userDocumentStatus => 'उपयोगकर्ता रिकॉर्ड स्थिति';

  @override
  String get existsByDocumentId => 'मौजूद (रिकॉर्ड आईडी से)';

  @override
  String get documentId => 'रिकॉर्ड आईडी';

  @override
  String get phoneFieldInData => 'फ़ोन फ़ील्ड (डेटा में)';

  @override
  String get existsByPhoneFieldQuery => 'मौजूद (फ़ोन से खोज)';

  @override
  String get documentIdFromQuery => 'रिकॉर्ड आईडी (खोज से)';

  @override
  String get issueDetected => 'समस्या मिली';

  @override
  String get documentIdMismatch => 'रिकॉर्ड आईडी मेल नहीं खाती!';

  @override
  String get userDocumentFound => 'उपयोगकर्ता रिकॉर्ड मिला';

  @override
  String get userDocumentNotFound => 'उपयोगकर्ता रिकॉर्ड नहीं मिला';

  @override
  String get billsCollectionStatus => 'बिल रिकॉर्ड स्थिति';

  @override
  String get phoneFormatMismatchInBills =>
      'बिलों में फ़ोन फ़ॉर्मेट मेल नहीं खाता!';

  @override
  String get phoneFormatConsistent => 'फ़ोन फ़ॉर्मेट सही है';

  @override
  String get pendingBillsStatus => 'बाकी बिलों की स्थिति';

  @override
  String get totalPendingBills => 'कुल बाकी बिल';

  @override
  String get matchingBillsFound => 'मेल खाते बिल';

  @override
  String get noPendingBillsFoundForThis =>
      'इस उपयोगकर्ता का कोई बाकी बिल नहीं!';

  @override
  String get carpenterId => 'कारपेंटर आईडी';

  @override
  String get carpenterPhone => 'कारपेंटर फ़ोन';

  @override
  String get isToday => 'आज का है';

  @override
  String get createdAt => 'बनाया गया';

  @override
  String get thisBillWonTShowIn =>
      'यह बिल सामान्य एडमिन दृश्य में नहीं दिखेगा (आज का नहीं)';

  @override
  String get totalAccounts => 'कुल खाते';

  @override
  String get duplicatePhones => 'डुप्लिकेट फ़ोन';

  @override
  String get affectedAccounts => 'प्रभावित खाते';

  @override
  String get noDuplicateAccountsFound => 'कोई डुप्लिकेट खाता नहीं मिला!';

  @override
  String get duplicatePhoneNumbers => 'डुप्लिकेट फ़ोन नंबर';

  @override
  String account(String idx) {
    return 'खाता $idx';
  }

  @override
  String get review => 'जाँचें';

  @override
  String get preparingUserBackupPdf =>
      'उपयोगकर्ता बैकअप PDF तैयार हो रही है...';

  @override
  String get noCarpentersFound2 => 'कोई कारपेंटर नहीं मिला।';

  @override
  String userBackupExportedSuccessfullyCarpenters(String users) {
    return 'उपयोगकर्ता बैकअप निर्यात हो गया! ($users कारपेंटर)';
  }

  @override
  String get exportUsersBackup => 'उपयोगकर्ता बैकअप निर्यात';

  @override
  String get createUserBackup => 'उपयोगकर्ता बैकअप बनाएँ';

  @override
  String get exportAllCarpentersWithTheirPoints =>
      'सफ़ाई से पहले सभी कारपेंटर को उनके पॉइंट्स और फ़ोन नंबर के साथ निर्यात करें।';

  @override
  String get exporting => 'निर्यात हो रहा है...';

  @override
  String get exportToPdf => 'PDF में निर्यात करें';

  @override
  String get pdfWillInclude => 'PDF में होगा:';

  @override
  String get carpenterNameAndPhoneNumberTotal =>
      '• कारपेंटर का नाम और फ़ोन नंबर\n• कुल और कमाए गए पॉइंट्स\n• खाता बनने की तारीख\n• कुल कारपेंटर और कुल पॉइंट्स का सारांश';

  @override
  String get firebaseDuplicateCheck => 'डेटाबेस डुप्लिकेट जाँच';

  @override
  String get firebaseDatabaseSummary => 'डेटाबेस सारांश';

  @override
  String get totalCarpenters2 => 'कुल कारपेंटर:';

  @override
  String get uniquePhoneNumbers => 'अलग फ़ोन नंबर:';

  @override
  String get duplicatePhoneNumbers2 => 'डुप्लिकेट फ़ोन नंबर:';

  @override
  String get totalDuplicateAccounts => 'कुल डुप्लिकेट खाते:';

  @override
  String get allPhoneNumbersAreUnique => 'सभी फ़ोन नंबर अलग हैं।';

  @override
  String get duplicateMobileNumbers => 'डुप्लिकेट मोबाइल नंबर';

  @override
  String mobile2(String groupIndex, String totalGroups, String phone) {
    return '$groupIndex/$totalGroups - मोबाइल: $phone';
  }

  @override
  String accountsWithSamePhoneNumber(String users) {
    return 'एक ही फ़ोन नंबर वाले $users खाते';
  }

  @override
  String get main => 'मुख्य';

  @override
  String get duplicate => 'डुप्लिकेट';

  @override
  String get startingBackup => 'बैकअप शुरू हो रहा है...';

  @override
  String backupExportedUsersBills(String users, String bills) {
    return 'बैकअप निर्यात हुआ: $users उपयोगकर्ता, $bills बिल';
  }

  @override
  String backupFailed(String e) {
    return 'बैकअप विफल: $e';
  }

  @override
  String get backupData => 'बैकअप डेटा';

  @override
  String totalSizeKb(String backupJson) {
    return 'कुल आकार: $backupJson KB';
  }

  @override
  String get firebaseBackup => 'डेटाबेस बैकअप';

  @override
  String get databaseBackup => 'डेटाबेस बैकअप';

  @override
  String get createACompleteBackupOfAll =>
      'सभी उपयोगकर्ताओं और बिलों के डेटा का पूरा बैकअप बनाएँ।';

  @override
  String get whatWillBeBackedUp => 'किसका बैकअप होगा:';

  @override
  String get allUserAccountsCarpentersAdminsAll =>
      '• सभी उपयोगकर्ता खाते (कारपेंटर और एडमिन)\n• सभी बिल रिकॉर्ड\n• समय के साथ पूरा उपयोगकर्ता डेटा\n• डेटाबेस मेटाडेटा';

  @override
  String get backingUp => 'बैकअप हो रहा है...';

  @override
  String get startBackup => 'बैकअप शुरू करें';

  @override
  String get backupIsStoredInFirebaseNo =>
      'बैकअप सर्वर पर रखा जाता है। फ़ोन में कोई फ़ाइल नहीं सहेजी जाती।';

  @override
  String get repairDetails => 'सुधार विवरण';

  @override
  String get verificationComplete => 'जाँच पूरी';

  @override
  String get noPointsLostAllUsersVerified =>
      'कोई पॉइंट नहीं गया\nसभी उपयोगकर्ता जाँचे गए\nडेटा सही है';

  @override
  String get userWiseRepairResults => 'उपयोगकर्ता अनुसार सुधार परिणाम';

  @override
  String get noRepairsCompleted => 'कोई सुधार नहीं हुआ';

  @override
  String get repairComplete => 'सुधार पूरा';

  @override
  String get successfullyRepaired => 'सफलतापूर्वक सुधारे गए';

  @override
  String get failed => 'विफल';

  @override
  String get duplicatesRemoved => 'डुप्लिकेट हटाए गए';

  @override
  String get pointsAdjusted => 'पॉइंट्स समायोजित';

  @override
  String get before => 'पहले';

  @override
  String get after => 'बाद में';

  @override
  String get repairFailed => 'सुधार विफल';

  @override
  String get thisToolScansUserPointsData =>
      'यह टूल पॉइंट्स डेटा जाँचकर ठीक करता है:\n• डुप्लिकेट इतिहास प्रविष्टियाँ\n• गलत कुल पॉइंट्स\n• गलत टियर';

  @override
  String get pointsRepairTool => 'पॉइंट्स सुधार टूल';

  @override
  String get pointsDataRepair => 'पॉइंट्स डेटा सुधार';

  @override
  String get scanReport => 'स्कैन रिपोर्ट';

  @override
  String get totalUsersScanned => 'कुल जाँचे गए उपयोगकर्ता';

  @override
  String get usersWithIssues => 'समस्या वाले उपयोगकर्ता';

  @override
  String get usersWithDuplicates => 'डुप्लिकेट वाले उपयोगकर्ता';

  @override
  String get totalDuplicateEntries => 'कुल डुप्लिकेट प्रविष्टियाँ';

  @override
  String get pointsMismatches => 'पॉइंट्स अंतर';

  @override
  String get viewFullScanDetails => 'पूरा स्कैन विवरण देखें';

  @override
  String get viewDetailedResults => 'विस्तृत परिणाम देखें';

  @override
  String get scanForIssues => 'समस्याएँ जाँचें';

  @override
  String get scanAgain => 'फिर से जाँचें';

  @override
  String get repairAllUsers => 'सभी उपयोगकर्ता सुधारें';

  @override
  String get noIssuesFoundAllUserData => 'कोई समस्या नहीं! सारा डेटा सही है।';

  @override
  String scanFailed(String e) {
    return 'स्कैन विफल: $e';
  }

  @override
  String get repairAllUsers2 => 'सभी उपयोगकर्ता सुधारें?';

  @override
  String get repair => 'सुधारें';

  @override
  String repairFailed2(String e) {
    return 'सुधार विफल: $e';
  }

  @override
  String get scanningForIssues => 'समस्याएँ जाँची जा रही हैं...';

  @override
  String get analyzingAllUserPointsData =>
      'सभी उपयोगकर्ताओं का पॉइंट्स डेटा जाँचा जा रहा है';

  @override
  String get scanResultsFullDetails => 'स्कैन परिणाम - पूरा विवरण';

  @override
  String get usersWithIssues2 => 'समस्या वाले उपयोगकर्ता';

  @override
  String get noUsersWithIssuesFound => 'कोई समस्या वाला उपयोगकर्ता नहीं';

  @override
  String get scanSummary => 'स्कैन सारांश';

  @override
  String get totalUsersScanned2 => 'कुल जाँचे गए उपयोगकर्ता';

  @override
  String get totalDuplicateEntries2 => 'कुल डुप्लिकेट प्रविष्टियाँ';

  @override
  String get totalPointsDifference => 'कुल पॉइंट्स अंतर';

  @override
  String duplicates(String duplicateCount) {
    return '$duplicateCount डुप्लिकेट';
  }

  @override
  String get historySum => 'इतिहास का योग';

  @override
  String get difference => 'अंतर';

  @override
  String get totalEntries => 'कुल प्रविष्टियाँ';

  @override
  String get uniqueBills => 'अलग बिल';

  @override
  String get duplicateBills => 'डुप्लिकेट बिल:';

  @override
  String get smartDuplicateCleanup => 'स्मार्ट डुप्लिकेट सफ़ाई';

  @override
  String get allCarpentersHaveUniquePhoneNumbers =>
      'सभी कारपेंटर के फ़ोन नंबर अलग हैं।';

  @override
  String get potentialDuplicateAccountsReviewRequired =>
      'संभावित डुप्लिकेट खाते — जाँच ज़रूरी';

  @override
  String foundDuplicateMobileNumbers(String duplicateGroups) {
    return '$duplicateGroups डुप्लिकेट मोबाइल नंबर मिले';
  }

  @override
  String accountsToReview(String totalForReview) {
    return 'जाँच के लिए खाते: $totalForReview';
  }

  @override
  String get allRecordsAreRetainedTheHighest =>
      'सभी रिकॉर्ड बने रहते हैं। सबसे ज़्यादा पॉइंट्स वाला खाता सिर्फ़ सुझाया गया मुख्य खाता है।';

  @override
  String potentialDuplicateGroups(String duplicateGroups) {
    return 'संभावित डुप्लिकेट समूह ($duplicateGroups)';
  }

  @override
  String mobile3(String groupIndex, String phone) {
    return '$groupIndex. मोबाइल: $phone';
  }

  @override
  String similarAccountsPointsDiff(String reviewUsers, String pointsDiff) {
    return '$reviewUsers मिलते-जुलते खाते | पॉइंट्स अंतर: $pointsDiff';
  }

  @override
  String get suggestedPrimaryAccountHighestPoints =>
      'सुझाया गया मुख्य खाता (सबसे ज़्यादा पॉइंट्स)';

  @override
  String get otherMatchingAccountsManualReviewRequired =>
      'अन्य मिलते खाते — हाथ से जाँच ज़रूरी';

  @override
  String repairConfirmBody(String count) {
    return 'इससे $count उपयोगकर्ताओं का सुधार होगा:\n\n• डुप्लिकेट इतिहास प्रविष्टियाँ हटेंगी\n• सही कुल फिर से गिना जाएगा\n• टियर अपडेट होंगे\n\nइसे आसानी से वापस नहीं किया जा सकता।';
  }

  @override
  String repairSuccess(String repaired, String total) {
    return '$repaired/$total उपयोगकर्ता सफलतापूर्वक सुधारे गए!\nजाँचा गया: कोई पॉइंट नहीं गया';
  }

  @override
  String repairPartial(String repaired, String total) {
    return '$repaired/$total उपयोगकर्ता सुधारे गए।\nकुछ जाँच समस्याएँ हैं - लॉग देखें';
  }

  @override
  String backupUsersCount(String count) {
    return 'उपयोगकर्ता ($count)';
  }

  @override
  String backupBillsCount(String count) {
    return 'बिल ($count)';
  }

  @override
  String openAppForEachCarpenter(String app) {
    return 'इससे हर कारपेंटर के लिए $app खुलेगा।\n\nहर ऐप में आपको खुद भेजें दबाना होगा।\n\nआगे बढ़ें?';
  }

  @override
  String roleIdPreview(String id) {
    return 'भूमिका आईडी: $id';
  }

  @override
  String winnersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count विजेता',
      one: '1 विजेता',
    );
    return '$_temp0';
  }

  @override
  String roleRestored(String name) {
    return 'भूमिका $name वापस लाई गई।';
  }

  @override
  String roleDeleted(String name) {
    return 'भूमिका $name हटाई गई।';
  }

  @override
  String get permissionDeniedSuperAdmin =>
      'अनुमति नहीं मिली। जाँचें कि डेटाबेस नियम प्रकाशित हैं और आप सही सुपर एडमिन खाते से साइन इन हैं।';

  @override
  String get roleEngineer => 'इंजीनियर';

  @override
  String get roleBuiltInBadge => 'मूल';

  @override
  String get roleCustomBadge => 'कस्टम';

  @override
  String get roleProtectedTooltip =>
      'कारपेंटर मुख्य भूमिका है, इसे हटाया नहीं जा सकता';

  @override
  String rolesSummary(int active, int deleted) {
    return '$active सक्रिय · $deleted हटाई गईं';
  }

  @override
  String get rolesLiveSync => 'बदलाव हर डिवाइस के पंजीकरण में तुरंत दिखते हैं।';

  @override
  String get roleIdHelp => 'नाम से बनती है। बाद में बदली नहीं जा सकती।';

  @override
  String get roleErrInvalidName =>
      '2–40 अक्षर रखें, जिनमें कम से कम दो अंग्रेज़ी अक्षर या अंक हों।';

  @override
  String get roleErrReserved => 'यह नाम एडमिन खातों के लिए आरक्षित है।';

  @override
  String get roleErrBuiltIn => 'यह मूल भूमिका जैसी है। सूची से उसे वापस लाएँ।';

  @override
  String get roleErrDuplicate => 'इस आईडी की भूमिका पहले से है।';

  @override
  String get roleErrProtected =>
      'कारपेंटर मुख्य भूमिका है, इसे हटाया नहीं जा सकता।';

  @override
  String get roleShowAll => 'सभी';

  @override
  String get roleShowActive => 'सक्रिय';

  @override
  String get roleShowDeleted => 'हटाई गईं';

  @override
  String get noRolesInFilter => 'इस दृश्य में कोई भूमिका नहीं।';

  @override
  String deactivateBranchTitle(String name) {
    return '$name निष्क्रिय करें?';
  }

  @override
  String get deactivateBranchBody =>
      'जब तक आप इसे फिर सक्रिय नहीं करते, नए उपयोगकर्ता यह शाखा नहीं चुन पाएँगे और इसके सदस्य साइन इन नहीं कर पाएँगे। कोई डेटा नहीं हटेगा।';

  @override
  String activateBranchTitle(String name) {
    return '$name सक्रिय करें?';
  }

  @override
  String get activateBranchBody =>
      'शाखा फिर से पंजीकरण और साइन इन के लिए उपलब्ध होगी।';

  @override
  String get branchActions => 'शाखा कार्रवाइयाँ';

  @override
  String get copyBranchId => 'शाखा आईडी कॉपी करें';

  @override
  String get branchIdCopied => 'शाखा आईडी कॉपी हो गई';

  @override
  String get celebrationOn => 'चालू';

  @override
  String get celebrationOff => 'बंद';

  @override
  String get createAdminSubtitle =>
      'एक शाखा एडमिन जोड़ें जो एक शाखा के बिल और कारपेंटर संभालेगा।';

  @override
  String get selectBranchRequired => 'शाखा चुनें';

  @override
  String get addAdmin => 'एडमिन जोड़ें';

  @override
  String get branchAdminsTitle => 'शाखा एडमिन';

  @override
  String get adminsNav => 'एडमिन';

  @override
  String adminsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count एडमिन',
    );
    return '$_temp0';
  }

  @override
  String get adminActions => 'एडमिन कार्रवाइयाँ';

  @override
  String get editBranch => 'शाखा बदलें';

  @override
  String get branchUpdated => 'शाखा अपडेट हो गई';

  @override
  String get branchCodeLocked =>
      'कोड नहीं बदल सकता — मौजूदा सदस्य इसी से पंजीकृत हैं।';

  @override
  String get editLabel => 'बदलें';

  @override
  String get editRole => 'भूमिका बदलें';

  @override
  String roleUpdated(String name) {
    return 'भूमिका $name अपडेट हुई।';
  }

  @override
  String get roleIdLocked =>
      'भूमिका आईडी नहीं बदल सकती — यह उपयोगकर्ता खातों में सहेजी है।';

  @override
  String get roleActions => 'भूमिका कार्रवाइयाँ';

  @override
  String get editAdmin => 'एडमिन बदलें';

  @override
  String get editDetails => 'विवरण बदलें';

  @override
  String adminUpdated(String email) {
    return 'एडमिन $email अपडेट हुआ।';
  }

  @override
  String get adminBranchChangeNote =>
      'एडमिन को दूसरी शाखा में ले जाने से मौजूदा शाखा की पहुँच हट जाएगी। एक शाखा में एक ही एडमिन हो सकता है।';

  @override
  String get editsSyncNote =>
      'नाम बदलाव हर सदस्य की प्रोफ़ाइल में अपने-आप कॉपी हो जाते हैं।';

  @override
  String get noBranchAssigned =>
      'आपका खाता अभी किसी शाखा से नहीं जुड़ा है। सुपर एडमिन से अपनी शाखा तय करवाएँ।';

  @override
  String get loadingBranch => 'आपकी शाखा लोड हो रही है…';

  @override
  String get offerPointsTarget => 'पॉइंट्स लक्ष्य';

  @override
  String get offerDetails => 'ऑफ़र विवरण';

  @override
  String get offerInfo => 'ऑफ़र विवरण';

  @override
  String offerProgress(String have, String target) {
    return 'आपके पास $target में से $have पॉइंट्स हैं';
  }

  @override
  String offerPointsToGo(String points) {
    return 'इस ऑफ़र के लिए $points पॉइंट्स और चाहिए';
  }

  @override
  String get offerTargetReached => 'लक्ष्य पूरा!';

  @override
  String get offerTermsApply => '*नियम और शर्तें लागू।';

  @override
  String get offerViewBanner => 'पूरा बैनर देखें';

  @override
  String get homeAnnouncements => 'घोषणाएँ';

  @override
  String get legalTermsTitle => 'नियम और शर्तें';

  @override
  String get legalPrivacyTitle => 'गोपनीयता नीति';

  @override
  String legalLastUpdated(String date) {
    return 'अंतिम अपडेट: $date';
  }

  @override
  String get legalAgreePrefix => 'मैंने ';

  @override
  String get legalAgreeAnd => ' और ';

  @override
  String get legalAgreeSuffix => ' पढ़ ली हैं और मैं सहमत हूँ।';

  @override
  String get legalAcceptToContinue =>
      'आगे बढ़ने के लिए कृपया नियम और शर्तें तथा गोपनीयता नीति स्वीकार करें।';

  @override
  String get legalEnglishOnly => 'यह दस्तावेज़ अंग्रेज़ी में उपलब्ध है।';

  @override
  String get profileSectionLegal => 'कानूनी';

  @override
  String get myBranch => 'मेरी शाखा';

  @override
  String get myBranchSubtitle => 'आपकी स्टोर शाखा और संपर्क';

  @override
  String get branchDetails => 'शाखा विवरण';

  @override
  String get branchPhone => 'शाखा फ़ोन';

  @override
  String get yourBranchSupport => 'आपकी शाखा';

  @override
  String get appSupport => 'ऐप सहायता';

  @override
  String get openInMaps => 'मैप में खोलें';

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String get supportHint =>
      'बिल, पॉइंट्स और ऑफ़र के लिए अपनी शाखा से संपर्क करें। ऐप की समस्या के लिए ऐप सहायता से संपर्क करें।';

  @override
  String get directions => 'रास्ता दिखाएँ';

  @override
  String get openInGoogleMaps => 'Google मैप में खोलें';

  @override
  String get profileStatus => 'प्रोफ़ाइल स्थिति';

  @override
  String get profileReadyForBills =>
      'आपकी प्रोफ़ाइल पूरी है। आप बिल जमा कर सकते हैं।';

  @override
  String get profileMissingForBills =>
      'बिल जमा करने के लिए बाकी जानकारी जोड़ें।';

  @override
  String get requiredForBills => 'बिल के लिए ज़रूरी';

  @override
  String get added => 'जोड़ा गया';

  @override
  String get missing => 'बाकी है';

  @override
  String get notAdded => 'नहीं जोड़ा';

  @override
  String get emailOptional => 'ईमेल (वैकल्पिक)';

  @override
  String get profilePhoto => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get addPhotoRequired =>
      'प्रोफ़ाइल फ़ोटो जोड़ें। बिल जमा करने के लिए यह ज़रूरी है।';

  @override
  String itemsMissing(String items) {
    return 'बाकी: $items';
  }
}
