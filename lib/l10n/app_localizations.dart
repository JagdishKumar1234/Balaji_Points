import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Balaji Points'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

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

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Login with Phone Number'**
  String get loginWithPhone;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered phone number'**
  String get enterPhoneNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 digit phone number'**
  String get enterPhoneHint;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @enterOTPCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get enterOTPCode;

  /// No description provided for @didntReceiveOTP.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive OTP? '**
  String get didntReceiveOTP;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get invalidPhone;

  /// No description provided for @invalidPhoneLength.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get invalidPhoneLength;

  /// No description provided for @invalidPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain only digits'**
  String get invalidPhoneFormat;

  /// No description provided for @invalidOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get invalidOTP;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectRole;

  /// No description provided for @carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get carpenter;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// No description provided for @continueWithPin.
  ///
  /// In en, this message translates to:
  /// **'Continue with PIN'**
  String get continueWithPin;

  /// No description provided for @loginInfo.
  ///
  /// In en, this message translates to:
  /// **'Login using your registered phone number. You will receive an OTP to verify.'**
  String get loginInfo;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get poweredBy;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Sri Balaji Plywood & Hardware'**
  String get companyName;

  /// No description provided for @enterPinPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get enterPinPageTitle;

  /// No description provided for @enter4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get enter4DigitPin;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @fourDigitPin.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get fourDigitPin;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @newUserSetPin.
  ///
  /// In en, this message translates to:
  /// **'New user? Set PIN'**
  String get newUserSetPin;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN'**
  String get invalidPin;

  /// No description provided for @createPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your 4-digit PIN'**
  String get createPinTitle;

  /// No description provided for @createPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This PIN will be used for login'**
  String get createPinSubtitle;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First Name *'**
  String get firstNameRequired;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @savePin.
  ///
  /// In en, this message translates to:
  /// **'Save PIN'**
  String get savePin;

  /// No description provided for @pinCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN created successfully'**
  String get pinCreatedSuccess;

  /// No description provided for @failedToSavePin.
  ///
  /// In en, this message translates to:
  /// **'Failed to save PIN'**
  String get failedToSavePin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PIN and Confirm PIN do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @resetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPinTitle;

  /// No description provided for @resetPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number to reset your PIN.'**
  String get resetPinSubtitle;

  /// No description provided for @mustBeLoggedInToResetPin.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to reset your PIN. Please login first.'**
  String get mustBeLoggedInToResetPin;

  /// No description provided for @canOnlyResetOwnPin.
  ///
  /// In en, this message translates to:
  /// **'You can only reset your own PIN. Phone number must match your logged-in account.'**
  String get canOnlyResetOwnPin;

  /// No description provided for @enterCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current PIN to verify ownership.'**
  String get enterCurrentPin;

  /// No description provided for @currentPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPinLabel;

  /// No description provided for @newPinMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New PIN must be different from your current PIN.'**
  String get newPinMustBeDifferent;

  /// No description provided for @contactAdminForPinReset.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to reset your PIN. If you forgot your PIN, please contact admin for assistance.'**
  String get contactAdminForPinReset;

  /// No description provided for @forgotCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot your current PIN?'**
  String get forgotCurrentPin;

  /// No description provided for @forgotPinHelp.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t remember your current PIN, please contact our support team for assistance.'**
  String get forgotPinHelp;

  /// No description provided for @adminSupportInfo.
  ///
  /// In en, this message translates to:
  /// **'Admin Support'**
  String get adminSupportInfo;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @adminResetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get adminResetPin;

  /// No description provided for @adminResetPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN for {carpenterName}'**
  String adminResetPinTitle(String carpenterName);

  /// No description provided for @adminResetPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new 4-digit PIN for this carpenter.'**
  String get adminResetPinSubtitle;

  /// No description provided for @adminResetPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the PIN for {carpenterName}?'**
  String adminResetPinConfirm(String carpenterName);

  /// No description provided for @adminResetPinSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN reset successfully for {carpenterName}'**
  String adminResetPinSuccess(String carpenterName);

  /// No description provided for @adminResetPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset PIN. Please try again.'**
  String get adminResetPinFailed;

  /// No description provided for @adminNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this action.'**
  String get adminNotAuthorized;

  /// No description provided for @enterNewPinForCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Enter new 4-digit PIN'**
  String get enterNewPinForCarpenter;

  /// No description provided for @confirmNewPinForCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Confirm new 4-digit PIN'**
  String get confirmNewPinForCarpenter;

  /// No description provided for @newPinLabel.
  ///
  /// In en, this message translates to:
  /// **'New 4-digit PIN'**
  String get newPinLabel;

  /// No description provided for @checkNumber.
  ///
  /// In en, this message translates to:
  /// **'Check Number'**
  String get checkNumber;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pleaseVerifyMobile.
  ///
  /// In en, this message translates to:
  /// **'Please verify mobile number first'**
  String get pleaseVerifyMobile;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this number'**
  String get noAccountFound;

  /// No description provided for @pinResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN reset successfully. Please login again.'**
  String get pinResetSuccess;

  /// No description provided for @failedToResetPin.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset PIN. Try again.'**
  String get failedToResetPin;

  /// No description provided for @enterValidTenDigit.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit number'**
  String get enterValidTenDigit;

  /// No description provided for @enter4Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 digits'**
  String get enter4Digits;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinMismatch;

  /// No description provided for @enterValidFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter valid first name'**
  String get enterValidFirstName;

  /// No description provided for @imageError.
  ///
  /// In en, this message translates to:
  /// **'Image error'**
  String get imageError;

  /// No description provided for @resetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @accountExistsUseReset.
  ///
  /// In en, this message translates to:
  /// **'Account already exists. Please use Reset PIN to change your PIN.'**
  String get accountExistsUseReset;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @addPoints.
  ///
  /// In en, this message translates to:
  /// **'Add Points'**
  String get addPoints;

  /// No description provided for @latestOffers.
  ///
  /// In en, this message translates to:
  /// **'Latest Offers'**
  String get latestOffers;

  /// No description provided for @goodMorningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorningGreeting;

  /// No description provided for @goodAfternoonGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoonGreeting;

  /// No description provided for @goodEveningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEveningGreeting;

  /// No description provided for @homeBrowseProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wood & Plywood'**
  String get homeBrowseProductsTitle;

  /// No description provided for @homeBrowseProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium laminates & surfaces'**
  String get homeBrowseProductsSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @homeStoreBranch.
  ///
  /// In en, this message translates to:
  /// **'E road'**
  String get homeStoreBranch;

  /// No description provided for @homeTierSuffix.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get homeTierSuffix;

  /// No description provided for @homeRankingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rankings & daily winner'**
  String get homeRankingsSectionTitle;

  /// No description provided for @homeRankingsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard, your rank, and today’s prize'**
  String get homeRankingsSectionSubtitle;

  /// No description provided for @drawerProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get drawerProductsTitle;

  /// No description provided for @drawerProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse categories and catalog'**
  String get drawerProductsSubtitle;

  /// No description provided for @drawerCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get drawerCart;

  /// No description provided for @drawerSectionMainNav.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get drawerSectionMainNav;

  /// No description provided for @drawerSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get drawerSectionMore;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSectionSupport;

  /// No description provided for @profileAboutLink.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get profileAboutLink;

  /// No description provided for @routeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeErrorTitle;

  /// No description provided for @routeErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This link is invalid or the page was removed.'**
  String get routeErrorNotFound;

  /// No description provided for @routeErrorGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get routeErrorGoHome;

  /// No description provided for @routeErrorDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get routeErrorDetailsLabel;

  /// No description provided for @topCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Top 3 Carpenters'**
  String get topCarpenters;

  /// No description provided for @todaysWinner.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Winner'**
  String get todaysWinner;

  /// No description provided for @yourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get yourPosition;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank #{rank}'**
  String rank(int rank);

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{points} Points'**
  String points(int points);

  /// No description provided for @noOffersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No offers available at the moment'**
  String get noOffersAvailable;

  /// No description provided for @dailySpinWinner.
  ///
  /// In en, this message translates to:
  /// **'🎉 Daily Spin Winner'**
  String get dailySpinWinner;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Won {points} points!'**
  String won(int points);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Profile Incomplete'**
  String get profileIncomplete;

  /// No description provided for @completeProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile to start adding bills and earning points'**
  String get completeProfileMessage;

  /// No description provided for @completeProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Add your first name, last name, and profile picture to continue'**
  String get completeProfileDetails;

  /// No description provided for @completeNow.
  ///
  /// In en, this message translates to:
  /// **'Complete Now'**
  String get completeNow;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPoints;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team for any queries or issues.'**
  String get contactSupport;

  /// No description provided for @supportPhone1.
  ///
  /// In en, this message translates to:
  /// **'96006 - 09121'**
  String get supportPhone1;

  /// No description provided for @supportPhone2.
  ///
  /// In en, this message translates to:
  /// **'0424 - 3557187'**
  String get supportPhone2;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with us'**
  String get getInTouch;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @landline.
  ///
  /// In en, this message translates to:
  /// **'Landline'**
  String get landline;

  /// No description provided for @addBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get addBill;

  /// No description provided for @billDetails.
  ///
  /// In en, this message translates to:
  /// **'Bill Details'**
  String get billDetails;

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill Number'**
  String get billNumber;

  /// No description provided for @billAmount.
  ///
  /// In en, this message translates to:
  /// **'Bill Amount (₹)'**
  String get billAmount;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Bill Date'**
  String get billDate;

  /// No description provided for @uploadBillImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Bill Image'**
  String get uploadBillImage;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @pointsConversion.
  ///
  /// In en, this message translates to:
  /// **'1000 ₹ = 1 Point'**
  String get pointsConversion;

  /// No description provided for @estimatedPoints.
  ///
  /// In en, this message translates to:
  /// **'Estimated Points'**
  String get estimatedPoints;

  /// No description provided for @youWillEarn.
  ///
  /// In en, this message translates to:
  /// **'You will earn approximately {points} points'**
  String youWillEarn(int points);

  /// No description provided for @enterBillNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter bill number'**
  String get enterBillNumber;

  /// No description provided for @enterBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter bill amount'**
  String get enterBillAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @selectBillDate.
  ///
  /// In en, this message translates to:
  /// **'Please select bill date'**
  String get selectBillDate;

  /// No description provided for @uploadBillPhoto.
  ///
  /// In en, this message translates to:
  /// **'Please upload bill photo'**
  String get uploadBillPhoto;

  /// No description provided for @billSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Bill submitted successfully'**
  String get billSubmitted;

  /// No description provided for @billSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit bill'**
  String get billSubmitError;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @availablePoints.
  ///
  /// In en, this message translates to:
  /// **'Available Points'**
  String get availablePoints;

  /// No description provided for @redeemPoints.
  ///
  /// In en, this message translates to:
  /// **'Redeem Points'**
  String get redeemPoints;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @redeemNow.
  ///
  /// In en, this message translates to:
  /// **'Redeem Now'**
  String get redeemNow;

  /// No description provided for @pointsRequired.
  ///
  /// In en, this message translates to:
  /// **'{points} Points Required'**
  String pointsRequired(int points);

  /// No description provided for @offerRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Offer redeemed successfully'**
  String get offerRedeemed;

  /// No description provided for @insufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'Insufficient points'**
  String get insufficientPoints;

  /// No description provided for @offerExpired.
  ///
  /// In en, this message translates to:
  /// **'This offer has expired'**
  String get offerExpired;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(String date);

  /// No description provided for @dailySpin.
  ///
  /// In en, this message translates to:
  /// **'Daily Spin'**
  String get dailySpin;

  /// No description provided for @spinNow.
  ///
  /// In en, this message translates to:
  /// **'SPIN NOW'**
  String get spinNow;

  /// No description provided for @spinning.
  ///
  /// In en, this message translates to:
  /// **'Spinning...'**
  String get spinning;

  /// No description provided for @spinWheel.
  ///
  /// In en, this message translates to:
  /// **'Spin the Wheel'**
  String get spinWheel;

  /// No description provided for @dailySpinCompleted.
  ///
  /// In en, this message translates to:
  /// **'You have already spun today'**
  String get dailySpinCompleted;

  /// No description provided for @comeBackTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for another chance to win!'**
  String get comeBackTomorrow;

  /// No description provided for @nextSpinIn.
  ///
  /// In en, this message translates to:
  /// **'Next spin in: {hours}h {minutes}m'**
  String nextSpinIn(int hours, int minutes);

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name}'**
  String winner(String name);

  /// No description provided for @prizePoints.
  ///
  /// In en, this message translates to:
  /// **'🎁 {points} Points'**
  String prizePoints(int points);

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Bills, Offers, Users & Daily Spin'**
  String get adminSubtitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @manageBills.
  ///
  /// In en, this message translates to:
  /// **'Manage Bills'**
  String get manageBills;

  /// No description provided for @manageOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage Offers'**
  String get manageOffers;

  /// No description provided for @manageDailySpin.
  ///
  /// In en, this message translates to:
  /// **'Manage Daily Spin'**
  String get manageDailySpin;

  /// No description provided for @pendingBills.
  ///
  /// In en, this message translates to:
  /// **'Pending Bills'**
  String get pendingBills;

  /// No description provided for @approvedBills.
  ///
  /// In en, this message translates to:
  /// **'Approved Bills'**
  String get approvedBills;

  /// No description provided for @rejectedBills.
  ///
  /// In en, this message translates to:
  /// **'Rejected Bills'**
  String get rejectedBills;

  /// No description provided for @pendingUsers.
  ///
  /// In en, this message translates to:
  /// **'Pending Users'**
  String get pendingUsers;

  /// No description provided for @verifiedUsers.
  ///
  /// In en, this message translates to:
  /// **'Verified Users'**
  String get verifiedUsers;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @userApproved.
  ///
  /// In en, this message translates to:
  /// **'User approved successfully'**
  String get userApproved;

  /// No description provided for @userRejected.
  ///
  /// In en, this message translates to:
  /// **'User rejected successfully'**
  String get userRejected;

  /// No description provided for @billApproved.
  ///
  /// In en, this message translates to:
  /// **'Bill approved successfully'**
  String get billApproved;

  /// No description provided for @billRejected.
  ///
  /// In en, this message translates to:
  /// **'Bill rejected successfully'**
  String get billRejected;

  /// No description provided for @createOffer.
  ///
  /// In en, this message translates to:
  /// **'Create Offer'**
  String get createOffer;

  /// No description provided for @offerTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer Title'**
  String get offerTitle;

  /// No description provided for @offerDescription.
  ///
  /// In en, this message translates to:
  /// **'Offer Description'**
  String get offerDescription;

  /// No description provided for @offerCreated.
  ///
  /// In en, this message translates to:
  /// **'Offer created successfully'**
  String get offerCreated;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @phoneAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Phone authentication failed'**
  String get phoneAuthFailed;

  /// No description provided for @configError.
  ///
  /// In en, this message translates to:
  /// **'Configuration error'**
  String get configError;

  /// No description provided for @missingClientId.
  ///
  /// In en, this message translates to:
  /// **'SHA-1 fingerprint missing in Firebase. Please run: scripts/get_sha1.sh'**
  String get missingClientId;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a few minutes.'**
  String get tooManyRequests;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code. Please check and try again.'**
  String get invalidVerificationCode;

  /// No description provided for @verificationExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification expired. Please request a new OTP.'**
  String get verificationExpired;

  /// No description provided for @userDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Please contact support.'**
  String get userDisabled;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid name'**
  String get invalidName;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @amountTooLow.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountTooLow;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @releaseToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Release to refresh'**
  String get releaseToRefresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @approveBill.
  ///
  /// In en, this message translates to:
  /// **'Approve Bill'**
  String get approveBill;

  /// No description provided for @approveBillConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Approve bill of ₹{amount} for {phone}?'**
  String approveBillConfirmation(String amount, String phone);

  /// No description provided for @approvingBill.
  ///
  /// In en, this message translates to:
  /// **'Approving bill...'**
  String get approvingBill;

  /// No description provided for @billApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bill approved!'**
  String get billApprovedSuccess;

  /// No description provided for @failedToApproveBill.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve bill. Try again.'**
  String get failedToApproveBill;

  /// No description provided for @rejectBill.
  ///
  /// In en, this message translates to:
  /// **'Reject Bill'**
  String get rejectBill;

  /// No description provided for @rejectBillConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this bill?'**
  String get rejectBillConfirmation;

  /// No description provided for @billRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bill Rejected'**
  String get billRejectedSuccess;

  /// No description provided for @failedToRejectBill.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject'**
  String get failedToRejectBill;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No image available'**
  String get noImageAvailable;

  /// No description provided for @errorLoadingBills.
  ///
  /// In en, this message translates to:
  /// **'Error loading bills'**
  String get errorLoadingBills;

  /// No description provided for @noPendingBills.
  ///
  /// In en, this message translates to:
  /// **'No Pending Bills'**
  String get noPendingBills;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @deleteOffer.
  ///
  /// In en, this message translates to:
  /// **'Delete Offer'**
  String get deleteOffer;

  /// No description provided for @deleteOfferConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this offer? This action cannot be undone.'**
  String get deleteOfferConfirmation;

  /// No description provided for @offerDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer deleted successfully'**
  String get offerDeletedSuccess;

  /// No description provided for @failedToDeleteOffer.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete offer'**
  String get failedToDeleteOffer;

  /// No description provided for @errorLoadingOffers.
  ///
  /// In en, this message translates to:
  /// **'Error loading offers'**
  String get errorLoadingOffers;

  /// No description provided for @noOffersCreated.
  ///
  /// In en, this message translates to:
  /// **'No Offers Created'**
  String get noOffersCreated;

  /// No description provided for @createFirstOffer.
  ///
  /// In en, this message translates to:
  /// **'Create your first offer with points and banner'**
  String get createFirstOffer;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @editOffer.
  ///
  /// In en, this message translates to:
  /// **'Edit Offer'**
  String get editOffer;

  /// No description provided for @createNewOffer.
  ///
  /// In en, this message translates to:
  /// **'Create New Offer'**
  String get createNewOffer;

  /// No description provided for @tapToUploadBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload banner'**
  String get tapToUploadBanner;

  /// No description provided for @offerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Offer Title *'**
  String get offerTitleLabel;

  /// No description provided for @offerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Diwali Special Offer'**
  String get offerTitleHint;

  /// No description provided for @enterOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter offer title'**
  String get enterOfferTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the offer'**
  String get descriptionHint;

  /// No description provided for @pointsRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Points Required *'**
  String get pointsRequiredLabel;

  /// No description provided for @pointsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 100'**
  String get pointsHint;

  /// No description provided for @enterPointsError.
  ///
  /// In en, this message translates to:
  /// **'Please enter points'**
  String get enterPointsError;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @setValidUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Set valid until date (optional)'**
  String get setValidUntilDate;

  /// No description provided for @validUntilDisplay.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntilDisplay(String date);

  /// No description provided for @offerStatus.
  ///
  /// In en, this message translates to:
  /// **'Offer Status'**
  String get offerStatus;

  /// No description provided for @uploadingBanner.
  ///
  /// In en, this message translates to:
  /// **'Uploading banner...'**
  String get uploadingBanner;

  /// No description provided for @updateOffer.
  ///
  /// In en, this message translates to:
  /// **'Update Offer'**
  String get updateOffer;

  /// No description provided for @offerUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer updated successfully'**
  String get offerUpdatedSuccess;

  /// No description provided for @offerCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer created successfully'**
  String get offerCreatedSuccess;

  /// No description provided for @failedToSaveOffer.
  ///
  /// In en, this message translates to:
  /// **'Failed to save offer'**
  String get failedToSaveOffer;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchByNameOrPhone;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @platinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get platinum;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get errorLoadingUsers;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No Users Found'**
  String get noUsersFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @noCarpentersYet.
  ///
  /// In en, this message translates to:
  /// **'No carpenters registered yet'**
  String get noCarpentersYet;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedLabel(String date);

  /// No description provided for @addCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Add Carpenter'**
  String get addCarpenter;

  /// No description provided for @deleteCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Delete Carpenter'**
  String get deleteCarpenter;

  /// No description provided for @deleteCarpenterConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this carpenter? This will permanently delete:\n\n• User account\n• All points and transaction history\n• All submitted bills\n• All offer redemptions\n\nThis action cannot be undone.'**
  String get deleteCarpenterConfirmation;

  /// No description provided for @deleteCarpenterWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting a carpenter will permanently remove all their data from the system. This action cannot be undone.'**
  String get deleteCarpenterWarning;

  /// No description provided for @carpenterDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Carpenter deleted successfully'**
  String get carpenterDeletedSuccess;

  /// No description provided for @failedToDeleteCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete carpenter'**
  String get failedToDeleteCarpenter;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 9876543210 (no +91)'**
  String get phoneNumberHint;

  /// No description provided for @enterOTP.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOTP;

  /// No description provided for @verifyAndCreate.
  ///
  /// In en, this message translates to:
  /// **'Verify & Create'**
  String get verifyAndCreate;

  /// No description provided for @adminSignOutNote.
  ///
  /// In en, this message translates to:
  /// **'Note: The app will sign in as the verified carpenter temporarily during OTP verification and then sign out. The admin must sign in again.'**
  String get adminSignOutNote;

  /// No description provided for @carpenterCreated.
  ///
  /// In en, this message translates to:
  /// **'Carpenter created'**
  String get carpenterCreated;

  /// No description provided for @carpenterCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Carpenter account created successfully. The app has signed in as that carpenter during verification and has now signed out. You will need to sign in again as admin.'**
  String get carpenterCreatedMessage;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @phoneAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Phone number already exists'**
  String get phoneAlreadyExists;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @otpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent'**
  String get otpSent;

  /// No description provided for @failedToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with OTP'**
  String get failedToSignIn;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Auth error'**
  String get authError;

  /// No description provided for @totalPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Points'**
  String get totalPointsLabel;

  /// No description provided for @tierLabel.
  ///
  /// In en, this message translates to:
  /// **'{tier} Tier'**
  String tierLabel(String tier);

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @noWinnerYetToday.
  ///
  /// In en, this message translates to:
  /// **'No winner yet today'**
  String get noWinnerYetToday;

  /// No description provided for @youWonPrize.
  ///
  /// In en, this message translates to:
  /// **'🎉 You Won!'**
  String get youWonPrize;

  /// No description provided for @todaysWinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'🏆 Today\'s Winner'**
  String get todaysWinnerLabel;

  /// No description provided for @myPoints.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get myPoints;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @rankShort.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rankShort;

  /// No description provided for @earn.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get earn;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @addNewBill.
  ///
  /// In en, this message translates to:
  /// **'Add New Bill'**
  String get addNewBill;

  /// No description provided for @recentBills.
  ///
  /// In en, this message translates to:
  /// **'Recent Bills'**
  String get recentBills;

  /// No description provided for @noBillsYet.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get noBillsYet;

  /// No description provided for @submitFirstBill.
  ///
  /// In en, this message translates to:
  /// **'Submit your first bill to earn points'**
  String get submitFirstBill;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
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

  /// No description provided for @billLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get billLabel;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get statusApproved;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get statusRejected;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App?'**
  String get exitApp;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit the app?'**
  String get exitAppMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @pleaseWaitForSpin.
  ///
  /// In en, this message translates to:
  /// **'Please wait for spin to complete'**
  String get pleaseWaitForSpin;

  /// No description provided for @discardBill.
  ///
  /// In en, this message translates to:
  /// **'Discard Bill?'**
  String get discardBill;

  /// No description provided for @discardBillMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved bill data. Do you want to discard it?'**
  String get discardBillMessage;

  /// No description provided for @pleaseCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile'**
  String get pleaseCompleteProfile;

  /// No description provided for @rewardsLoyaltyProgram.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Loyalty Program'**
  String get rewardsLoyaltyProgram;

  /// No description provided for @billImage.
  ///
  /// In en, this message translates to:
  /// **'Bill Image'**
  String get billImage;

  /// No description provided for @billDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Bill Date (Optional)'**
  String get billDateOptional;

  /// No description provided for @storeVendorNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Store/Vendor Name (Optional)'**
  String get storeVendorNameOptional;

  /// No description provided for @billInvoiceNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Bill/Invoice Number (Optional)'**
  String get billInvoiceNumberOptional;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @tapToAddBillImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add bill image'**
  String get tapToAddBillImage;

  /// No description provided for @selectBillDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Select bill date (optional)'**
  String get selectBillDateOptional;

  /// No description provided for @enterStoreOrVendorNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter store or vendor name (optional)'**
  String get enterStoreOrVendorNameOptional;

  /// No description provided for @enterBillOrInvoiceNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter bill or invoice number (optional)'**
  String get enterBillOrInvoiceNumberOptional;

  /// No description provided for @addAnyAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Add any additional notes...'**
  String get addAnyAdditionalNotes;

  /// No description provided for @submitBill.
  ///
  /// In en, this message translates to:
  /// **'Submit Bill'**
  String get submitBill;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @withdrawBill.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Bill'**
  String get withdrawBill;

  /// No description provided for @withdrawBillConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw this approved bill? This will reverse the points awarded to the carpenter.'**
  String get withdrawBillConfirmation;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @billWithdrawnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bill withdrawn successfully. Points have been reversed.'**
  String get billWithdrawnSuccess;

  /// No description provided for @failedToWithdrawBill.
  ///
  /// In en, this message translates to:
  /// **'Failed to withdraw bill'**
  String get failedToWithdrawBill;

  /// No description provided for @withdrawApproval.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Approval'**
  String get withdrawApproval;

  /// No description provided for @reversePointsAndUndoApproval.
  ///
  /// In en, this message translates to:
  /// **'Reverse points & undo approval'**
  String get reversePointsAndUndoApproval;

  /// No description provided for @approveBillAction.
  ///
  /// In en, this message translates to:
  /// **'Approve Bill'**
  String get approveBillAction;

  /// No description provided for @awardPointsAndMarkAsApproved.
  ///
  /// In en, this message translates to:
  /// **'Award points & mark as approved'**
  String get awardPointsAndMarkAsApproved;

  /// No description provided for @selectCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Select Carpenter'**
  String get selectCarpenter;

  /// No description provided for @errorLoadingCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Error loading carpenters'**
  String get errorLoadingCarpenters;

  /// No description provided for @noCarpentersFound.
  ///
  /// In en, this message translates to:
  /// **'No carpenters found'**
  String get noCarpentersFound;

  /// No description provided for @noCarpentersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No carpenters available'**
  String get noCarpentersAvailable;

  /// No description provided for @billHistory.
  ///
  /// In en, this message translates to:
  /// **'Bill History'**
  String get billHistory;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @searchCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Search carpenter...'**
  String get searchCarpenter;

  /// No description provided for @errorLoadingBillHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading bills'**
  String get errorLoadingBillHistory;

  /// No description provided for @noBillsFoundMatchingFilters.
  ///
  /// In en, this message translates to:
  /// **'No bills found matching filters'**
  String get noBillsFoundMatchingFilters;

  /// No description provided for @noBillsFoundHistory.
  ///
  /// In en, this message translates to:
  /// **'No bills found'**
  String get noBillsFoundHistory;

  /// No description provided for @billDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill Date'**
  String get billDateLabel;

  /// No description provided for @submittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedLabel;

  /// No description provided for @approvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedLabel;

  /// No description provided for @rejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedLabel;

  /// No description provided for @pts.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pts;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get languageHindi;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @aboutUsMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards & loyalty for carpenters'**
  String get aboutUsMenuSubtitle;

  /// No description provided for @aboutUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your hardware rewards partner'**
  String get aboutUsSubtitle;

  /// No description provided for @aboutUsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Balaji Points?'**
  String get aboutUsOverviewTitle;

  /// No description provided for @aboutUsOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Balaji Points is a digital loyalty platform for carpenters and hardware stores. It helps you turn eligible material purchases into points, rewards, and recognition. You use the app to submit bills; the hardware store you are enrolled with reviews and approves them; your wallet and history update automatically so you always know where you stand.'**
  String get aboutUsOverviewBody;

  /// No description provided for @aboutUsEarningTitle.
  ///
  /// In en, this message translates to:
  /// **'How you earn points'**
  String get aboutUsEarningTitle;

  /// No description provided for @aboutUsEarningBody.
  ///
  /// In en, this message translates to:
  /// **'Upload purchase bills with clear photos, correct amounts, and any details your store asks for. Store admins review submissions to keep the program fair and prevent errors or misuse. After approval, points are credited using that store’s rules (for example, how rupees convert to points). You can track your balance, transaction history, and tier progress anytime in the app.'**
  String get aboutUsEarningBody;

  /// No description provided for @aboutUsOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards, offers, and updates'**
  String get aboutUsOffersTitle;

  /// No description provided for @aboutUsOffersBody.
  ///
  /// In en, this message translates to:
  /// **'Many stores run a leaderboard so you can see how you rank among carpenters in their program. You will also see offers, banners, and announcements—seasonal deals, bonus point events, or special promotions—so you do not miss opportunities that your store enables for you.'**
  String get aboutUsOffersBody;

  /// No description provided for @aboutUsFairnessTitle.
  ///
  /// In en, this message translates to:
  /// **'Approvals, transparency, and support'**
  String get aboutUsFairnessTitle;

  /// No description provided for @aboutUsFairnessBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews can take a short time because each bill is checked carefully. If something is rejected, you should see a reason or get guidance from your store’s team. For login, PIN, profile, or notification issues, use the options inside the app and contact your store when needed. We focus on clear rules and visible status for pending, approved, and rejected bills.'**
  String get aboutUsFairnessBody;

  /// No description provided for @aboutUsStoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Your store, your program'**
  String get aboutUsStoresTitle;

  /// No description provided for @aboutUsStoresBody.
  ///
  /// In en, this message translates to:
  /// **'Points, tiers, and offers are tied to the hardware store you joined in this app. Different stores may use different rules, conversion rates, and benefits. If you buy from more than one participating store, each relationship is usually separate unless the stores tell you otherwise—always confirm details with the store that enrolled you.'**
  String get aboutUsStoresBody;

  /// No description provided for @aboutUsClosing.
  ///
  /// In en, this message translates to:
  /// **'Thank you for using Balaji Points—we are proud to support carpenters and the stores that partner with you.'**
  String get aboutUsClosing;

  /// No description provided for @aboutUsCreditsHeading.
  ///
  /// In en, this message translates to:
  /// **'Designed and developed by'**
  String get aboutUsCreditsHeading;

  /// No description provided for @aboutUsCreditsStudio.
  ///
  /// In en, this message translates to:
  /// **'Aaiji Tech Studio — Vadodara, Gujarat'**
  String get aboutUsCreditsStudio;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Submit bills, earn points'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Upload your hardware purchase bills. When your store approves them, points are added to your wallet.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Track your rewards'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'See your balance, tier, and leaderboard rank. Browse offers made for carpenters like you.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Get notified when bills are approved or rejected. Manage your profile and preferences anytime.'**
  String get onboardingSlide3Body;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
