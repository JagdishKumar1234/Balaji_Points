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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hi'),
    Locale('ta'),
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
  /// **'Mobile number'**
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
  /// **'Top 3 Members'**
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
  /// **'Enter offer title'**
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
  /// **'Enter description'**
  String get descriptionHint;

  /// No description provided for @pointsRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Points Required *'**
  String get pointsRequiredLabel;

  /// No description provided for @pointsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter points'**
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
  /// **'Search name or phone'**
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
  /// **'Enter phone number'**
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
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

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
  /// **'Rewards & loyalty for members'**
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

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @siteNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Site name is required'**
  String get siteNameRequired;

  /// No description provided for @billDateFuture.
  ///
  /// In en, this message translates to:
  /// **'Bill date cannot be in the future'**
  String get billDateFuture;

  /// No description provided for @duplicateBillDetected.
  ///
  /// In en, this message translates to:
  /// **'Duplicate bill detected'**
  String get duplicateBillDetected;

  /// No description provided for @duplicateBillIntro.
  ///
  /// In en, this message translates to:
  /// **'A bill with the same site, amount and date already exists:'**
  String get duplicateBillIntro;

  /// No description provided for @siteNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Site name'**
  String get siteNameLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @ptsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String ptsValue(String points);

  /// No description provided for @duplicateBillVerify.
  ///
  /// In en, this message translates to:
  /// **'This might be a duplicate entry. Please check before adding.'**
  String get duplicateBillVerify;

  /// No description provided for @addBillAnywayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add this bill anyway?'**
  String get addBillAnywayQuestion;

  /// No description provided for @addAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get addAnyway;

  /// No description provided for @billsPausedDiwali.
  ///
  /// In en, this message translates to:
  /// **'Bill submissions are paused for the Diwali celebration.'**
  String get billsPausedDiwali;

  /// No description provided for @earnPointsWhenApproved.
  ///
  /// In en, this message translates to:
  /// **'You will earn {points} points when approved'**
  String earnPointsWhenApproved(String points);

  /// No description provided for @vendorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor name'**
  String get vendorNameLabel;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get hintPassword;

  /// No description provided for @hintPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get hintPasswordMin;

  /// No description provided for @hintConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get hintConfirmPassword;

  /// No description provided for @hintFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get hintFullName;

  /// No description provided for @hintAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get hintAmount;

  /// No description provided for @hintBranchFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter branch name'**
  String get hintBranchFullName;

  /// No description provided for @hintShortName.
  ///
  /// In en, this message translates to:
  /// **'Enter short name'**
  String get hintShortName;

  /// No description provided for @hintBranchCode.
  ///
  /// In en, this message translates to:
  /// **'Enter branch code'**
  String get hintBranchCode;

  /// No description provided for @hintAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get hintAddress;

  /// No description provided for @hintRoleName.
  ///
  /// In en, this message translates to:
  /// **'Enter role name'**
  String get hintRoleName;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get hintEmail;

  /// No description provided for @hintPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get hintPhone;

  /// No description provided for @hintPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get hintPin;

  /// No description provided for @hintConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter PIN'**
  String get hintConfirmPin;

  /// No description provided for @hintBranchId.
  ///
  /// In en, this message translates to:
  /// **'Enter branch ID'**
  String get hintBranchId;

  /// No description provided for @diwaliYourPrize.
  ///
  /// In en, this message translates to:
  /// **'Your Diwali prize'**
  String get diwaliYourPrize;

  /// No description provided for @diwaliYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get diwaliYou;

  /// No description provided for @diwaliPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get diwaliPosition;

  /// No description provided for @navAddBill.
  ///
  /// In en, this message translates to:
  /// **'Add Bill'**
  String get navAddBill;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @diwaliPrizeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the Diwali prize list. Please try again.'**
  String get diwaliPrizeLoadFailed;

  /// No description provided for @featureEarnMore.
  ///
  /// In en, this message translates to:
  /// **'EARN MORE'**
  String get featureEarnMore;

  /// No description provided for @featureEarnBody.
  ///
  /// In en, this message translates to:
  /// **'Upload Bills\nEarn Points'**
  String get featureEarnBody;

  /// No description provided for @featureRedeemMore.
  ///
  /// In en, this message translates to:
  /// **'REDEEM MORE'**
  String get featureRedeemMore;

  /// No description provided for @featureRedeemBody.
  ///
  /// In en, this message translates to:
  /// **'Exciting Rewards\n& Gifts'**
  String get featureRedeemBody;

  /// No description provided for @featureGrowMore.
  ///
  /// In en, this message translates to:
  /// **'GROW MORE'**
  String get featureGrowMore;

  /// No description provided for @featureGrowBody.
  ///
  /// In en, this message translates to:
  /// **'Climb Leaderboard\nBe a Top Member'**
  String get featureGrowBody;

  /// No description provided for @featureExclusive.
  ///
  /// In en, this message translates to:
  /// **'EXCLUSIVE'**
  String get featureExclusive;

  /// No description provided for @featureExclusiveBody.
  ///
  /// In en, this message translates to:
  /// **'Special Benefits\nJust for You'**
  String get featureExclusiveBody;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get newAnnouncement;

  /// No description provided for @ptsToNextLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts to {tier}'**
  String ptsToNextLabel(String points, String tier);

  /// No description provided for @platinumHighestTier.
  ///
  /// In en, this message translates to:
  /// **'Platinum — highest tier!'**
  String get platinumHighestTier;

  /// No description provided for @topCarpentersTitle.
  ///
  /// In en, this message translates to:
  /// **'Top members'**
  String get topCarpentersTitle;

  /// No description provided for @noRankingYet.
  ///
  /// In en, this message translates to:
  /// **'No ranking data yet'**
  String get noRankingYet;

  /// No description provided for @noWinnerToday.
  ///
  /// In en, this message translates to:
  /// **'No winner today'**
  String get noWinnerToday;

  /// No description provided for @spinNotDoneYet.
  ///
  /// In en, this message translates to:
  /// **'Spin not done yet · {date}'**
  String spinNotDoneYet(String date);

  /// No description provided for @todaysLuckyWinner.
  ///
  /// In en, this message translates to:
  /// **'Today\'s lucky winner'**
  String get todaysLuckyWinner;

  /// No description provided for @selectedViaDailySpin.
  ///
  /// In en, this message translates to:
  /// **'Selected via daily spin · {date}'**
  String selectedViaDailySpin(String date);

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Delete all notifications'**
  String get deleteAllNotifications;

  /// No description provided for @deleteAllNotificationsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This cannot be undone.'**
  String get deleteAllNotificationsConfirm;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @notificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications deleted'**
  String notificationsDeleted(String count);

  /// No description provided for @unableToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications'**
  String get unableToLoadNotifications;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get deleteNotification;

  /// No description provided for @deleteNotificationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get deleteNotificationConfirm;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please add a profile photo'**
  String get addProfilePhoto;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last Name *'**
  String get lastNameRequired;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @completeProfileToContinue.
  ///
  /// In en, this message translates to:
  /// **'You need to complete your profile to continue'**
  String get completeProfileToContinue;

  /// No description provided for @couldNotMakeCall.
  ///
  /// In en, this message translates to:
  /// **'Could not make call'**
  String get couldNotMakeCall;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @youWonLabel.
  ///
  /// In en, this message translates to:
  /// **'You won'**
  String get youWonLabel;

  /// No description provided for @pointsWon.
  ///
  /// In en, this message translates to:
  /// **'{points} points!'**
  String pointsWon(String points);

  /// No description provided for @pointsAddedToAccount.
  ///
  /// In en, this message translates to:
  /// **'Points have been added to your account.'**
  String get pointsAddedToAccount;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get great;

  /// No description provided for @spinAndWin.
  ///
  /// In en, this message translates to:
  /// **'Spin & win points!'**
  String get spinAndWin;

  /// No description provided for @spinAndWinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get your daily spin and win exciting points'**
  String get spinAndWinSubtitle;

  /// No description provided for @alreadySpunToday.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already spun today!\nCome back tomorrow for another chance.'**
  String get alreadySpunToday;

  /// No description provided for @nextTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Next tier: {tier}'**
  String nextTierLabel(String tier);

  /// No description provided for @ptsToNextTier.
  ///
  /// In en, this message translates to:
  /// **'{points} pts to next tier'**
  String ptsToNextTier(String points);

  /// No description provided for @platinumMaxLevel.
  ///
  /// In en, this message translates to:
  /// **'Platinum tier — maximum level'**
  String get platinumMaxLevel;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @totalApprovedPoints.
  ///
  /// In en, this message translates to:
  /// **'Total approved points'**
  String get totalApprovedPoints;

  /// No description provided for @billsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bills'**
  String billsCount(String count);

  /// No description provided for @billAttachment.
  ///
  /// In en, this message translates to:
  /// **'Bill attachment'**
  String get billAttachment;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get pendingApproval;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @noPinAccount.
  ///
  /// In en, this message translates to:
  /// **'No PIN account was found for this number. Sign in with email and password or Google.'**
  String get noPinAccount;

  /// No description provided for @signInWithMobile.
  ///
  /// In en, this message translates to:
  /// **'Sign in with mobile number'**
  String get signInWithMobile;

  /// No description provided for @continueToPin.
  ///
  /// In en, this message translates to:
  /// **'Continue to PIN'**
  String get continueToPin;

  /// No description provided for @backToOtherSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to other sign-in options'**
  String get backToOtherSignIn;

  /// No description provided for @branchHasAdminDefaulted.
  ///
  /// In en, this message translates to:
  /// **'Selected branch already has an Admin. Role set to Carpenter.'**
  String get branchHasAdminDefaulted;

  /// No description provided for @selectBranchToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please select a branch to continue.'**
  String get selectBranchToContinue;

  /// No description provided for @oneAdminPerBranch.
  ///
  /// In en, this message translates to:
  /// **'This branch already has an Admin. Only one Admin is allowed per branch.'**
  String get oneAdminPerBranch;

  /// No description provided for @branchRequired.
  ///
  /// In en, this message translates to:
  /// **'Branch *'**
  String get branchRequired;

  /// No description provided for @selectYourBranch.
  ///
  /// In en, this message translates to:
  /// **'Select your branch'**
  String get selectYourBranch;

  /// No description provided for @userRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'User role *'**
  String get userRoleRequired;

  /// No description provided for @roleCarpenterWoodworker.
  ///
  /// In en, this message translates to:
  /// **'Carpenter / Woodworker'**
  String get roleCarpenterWoodworker;

  /// No description provided for @roleArchitect.
  ///
  /// In en, this message translates to:
  /// **'Architect'**
  String get roleArchitect;

  /// No description provided for @roleInteriorDesigner.
  ///
  /// In en, this message translates to:
  /// **'Interior designer'**
  String get roleInteriorDesigner;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @noActiveRoles.
  ///
  /// In en, this message translates to:
  /// **'No active roles are available. Contact the Super Admin.'**
  String get noActiveRoles;

  /// No description provided for @noActiveBranches.
  ///
  /// In en, this message translates to:
  /// **'No active branches are available. Contact your administrator.'**
  String get noActiveBranches;

  /// No description provided for @cancelReturnToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Cancel and return to sign in'**
  String get cancelReturnToSignIn;

  /// No description provided for @selectRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'Select role *'**
  String get selectRoleRequired;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousPage;

  /// No description provided for @tablePageInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages} · {from}–{to} of {total}'**
  String tablePageInfo(
    String page,
    String pages,
    String from,
    String to,
    String total,
  );

  /// No description provided for @noRows.
  ///
  /// In en, this message translates to:
  /// **'No rows'**
  String get noRows;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredLabel;

  /// No description provided for @installedLabel.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installedLabel;

  /// No description provided for @updateMandatory.
  ///
  /// In en, this message translates to:
  /// **'This update is required to keep using the app.'**
  String get updateMandatory;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @billsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Bills you submit will appear here.'**
  String get billsAppearHere;

  /// No description provided for @pendingBillsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New bills from carpenters will appear here for approval.'**
  String get pendingBillsAppearHere;

  /// No description provided for @tryChangingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try changing or clearing the filters.'**
  String get tryChangingFilters;

  /// No description provided for @carpentersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Registered carpenters will appear here.'**
  String get carpentersAppearHere;

  /// No description provided for @statCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Carpenters'**
  String get statCarpenters;

  /// No description provided for @statPendingBills.
  ///
  /// In en, this message translates to:
  /// **'Pending bills'**
  String get statPendingBills;

  /// No description provided for @statAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get statAwaitingReview;

  /// No description provided for @statBillsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Bills this month'**
  String get statBillsThisMonth;

  /// No description provided for @statApprovedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} approved'**
  String statApprovedThisMonth(String count);

  /// No description provided for @statPointsIssued.
  ///
  /// In en, this message translates to:
  /// **'Points issued'**
  String get statPointsIssued;

  /// No description provided for @statThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statThisMonth;

  /// No description provided for @statRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get statRegistered;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String version(String version, String buildNumber);

  /// No description provided for @switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to Light'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to Dark'**
  String get switchToDark;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @to2.
  ///
  /// In en, this message translates to:
  /// **'To {nextLabel}'**
  String to2(String nextLabel);

  /// No description provided for @spinNow2.
  ///
  /// In en, this message translates to:
  /// **'Spin Now!'**
  String get spinNow2;

  /// No description provided for @pleaseCompleteYourProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please complete your profile (first name, last name, and profile picture) to add bills and earn points.'**
  String get pleaseCompleteYourProfileFirstName;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @pleaseLoginToSubmitBills.
  ///
  /// In en, this message translates to:
  /// **'Please login to submit bills'**
  String get pleaseLoginToSubmitBills;

  /// No description provided for @billSubmittedSuccessfullyAdminWillReview.
  ///
  /// In en, this message translates to:
  /// **'Bill submitted successfully! Admin will review it.'**
  String get billSubmittedSuccessfullyAdminWillReview;

  /// No description provided for @failedToSubmitBillPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit bill. Please try again.'**
  String get failedToSubmitBillPleaseTry;

  /// No description provided for @pleaseEnterBillAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter bill amount'**
  String get pleaseEnterBillAmount;

  /// No description provided for @billDate2.
  ///
  /// In en, this message translates to:
  /// **'Bill Date *'**
  String get billDate2;

  /// No description provided for @selectBillDate2.
  ///
  /// In en, this message translates to:
  /// **'Select bill date'**
  String get selectBillDate2;

  /// No description provided for @siteName.
  ///
  /// In en, this message translates to:
  /// **'Site Name *'**
  String get siteName;

  /// No description provided for @enterSiteLocationName.
  ///
  /// In en, this message translates to:
  /// **'Enter site name'**
  String get enterSiteLocationName;

  /// No description provided for @vendorNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name (Optional)'**
  String get vendorNameOptional;

  /// No description provided for @enterVendorStoreNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter vendor name'**
  String get enterVendorStoreNameOptional;

  /// No description provided for @noUserLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No user logged in'**
  String get noUserLoggedIn;

  /// No description provided for @firstNameMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'First name must be at least 2 characters'**
  String get firstNameMustBeAtLeast;

  /// No description provided for @firstNameIsTooLongMax.
  ///
  /// In en, this message translates to:
  /// **'First name is too long (max 50 characters)'**
  String get firstNameIsTooLongMax;

  /// No description provided for @lastNameMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Last name must be at least 2 characters'**
  String get lastNameMustBeAtLeast;

  /// No description provided for @lastNameIsTooLongMax.
  ///
  /// In en, this message translates to:
  /// **'Last name is too long (max 50 characters)'**
  String get lastNameIsTooLongMax;

  /// No description provided for @failedToUploadProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile image'**
  String get failedToUploadProfileImage;

  /// No description provided for @failedToUploadProfileImage2.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload profile image: {e}'**
  String failedToUploadProfileImage2(String e);

  /// No description provided for @enterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enterYourFirstName;

  /// No description provided for @pleaseEnterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterYourFirstName;

  /// No description provided for @enterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enterYourLastName;

  /// No description provided for @pleaseEnterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterYourLastName;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @trackYourPointsAndManageYour.
  ///
  /// In en, this message translates to:
  /// **'Track your points and manage your bills'**
  String get trackYourPointsAndManageYour;

  /// No description provided for @mAgo.
  ///
  /// In en, this message translates to:
  /// **'{inMinutes}m ago'**
  String mAgo(String inMinutes);

  /// No description provided for @hAgo.
  ///
  /// In en, this message translates to:
  /// **'{inHours}h ago'**
  String hAgo(String inHours);

  /// No description provided for @dAgo.
  ///
  /// In en, this message translates to:
  /// **'{inDays}d ago'**
  String dAgo(String inDays);

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @noCarpenterAccountsAreListedFor.
  ///
  /// In en, this message translates to:
  /// **'No member accounts are listed for this branch yet.'**
  String get noCarpenterAccountsAreListedFor;

  /// No description provided for @continueToHome.
  ///
  /// In en, this message translates to:
  /// **'Continue to Home'**
  String get continueToHome;

  /// No description provided for @shubhDeepawali.
  ///
  /// In en, this message translates to:
  /// **'Shubh Deepawali!'**
  String get shubhDeepawali;

  /// No description provided for @carpenters.
  ///
  /// In en, this message translates to:
  /// **'{branchName}  ·  {carpenterCount} carpenters'**
  String carpenters(String branchName, String carpenterCount);

  /// No description provided for @carpenterRewardBonusReport.
  ///
  /// In en, this message translates to:
  /// **'CARPENTER REWARD & BONUS REPORT  ·  {dateFormat}'**
  String carpenterRewardBonusReport(String dateFormat);

  /// No description provided for @closeCelebration.
  ///
  /// In en, this message translates to:
  /// **'Close celebration'**
  String get closeCelebration;

  /// No description provided for @deepawaliPrizeNight.
  ///
  /// In en, this message translates to:
  /// **'✦  DEEPAWALI PRIZE NIGHT  ✦'**
  String get deepawaliPrizeNight;

  /// No description provided for @topPerformersGoldTier.
  ///
  /// In en, this message translates to:
  /// **'Top Performers - Gold Tier'**
  String get topPerformersGoldTier;

  /// No description provided for @ranks110.
  ///
  /// In en, this message translates to:
  /// **'Ranks 1-10'**
  String get ranks110;

  /// No description provided for @highPerformersSilverTier.
  ///
  /// In en, this message translates to:
  /// **'High Performers - Silver Tier'**
  String get highPerformersSilverTier;

  /// No description provided for @ranks1130.
  ///
  /// In en, this message translates to:
  /// **'Ranks 11-30'**
  String get ranks1130;

  /// No description provided for @activePerformersBronzeTier.
  ///
  /// In en, this message translates to:
  /// **'Active Performers - Bronze Tier'**
  String get activePerformersBronzeTier;

  /// No description provided for @ranks31Onwards.
  ///
  /// In en, this message translates to:
  /// **'Ranks 31 onwards'**
  String get ranks31Onwards;

  /// No description provided for @totalCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Total carpenters: {entries}'**
  String totalCarpenters(String entries);

  /// No description provided for @totalPoints2.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get totalPoints2;

  /// No description provided for @totalReward.
  ///
  /// In en, this message translates to:
  /// **'Total reward'**
  String get totalReward;

  /// No description provided for @totalBonus.
  ///
  /// In en, this message translates to:
  /// **'Total bonus'**
  String get totalBonus;

  /// No description provided for @carpentersPointsRewardBonus.
  ///
  /// In en, this message translates to:
  /// **'{entries} carpenters  ·  {totalPoints} points  ·  {totalReward} reward  ·  {totalBonus} bonus'**
  String carpentersPointsRewardBonus(
    String entries,
    String totalPoints,
    String totalReward,
    String totalBonus,
  );

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'{bonusAmount} bonus  ·  {giftDetails}'**
  String bonus(String bonusAmount, String giftDetails);

  /// No description provided for @mobileNumberUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Mobile number unavailable'**
  String get mobileNumberUnavailable;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @bonus2.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus2;

  /// No description provided for @nil.
  ///
  /// In en, this message translates to:
  /// **'Nil'**
  String get nil;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @reward2.
  ///
  /// In en, this message translates to:
  /// **'Reward ₹'**
  String get reward2;

  /// No description provided for @bonus3.
  ///
  /// In en, this message translates to:
  /// **'Bonus ₹'**
  String get bonus3;

  /// No description provided for @giftDetails.
  ///
  /// In en, this message translates to:
  /// **'Gift details'**
  String get giftDetails;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @verifyYourIdentityToOpenBalaji.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to open Balaji Points'**
  String get verifyYourIdentityToOpenBalaji;

  /// No description provided for @passwordResetLinksAreSentSecurely.
  ///
  /// In en, this message translates to:
  /// **'Password reset links are sent securely by Firebase.'**
  String get passwordResetLinksAreSentSecurely;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @ifAnAccountExistsForThis.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this address, Firebase has sent password reset instructions. Check your inbox and spam folder.'**
  String get ifAnAccountExistsForThis;

  /// No description provided for @enterTheEmailAddressLinkedTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address linked to your account. We’ll send you a secure link to choose a new password.'**
  String get enterTheEmailAddressLinkedTo;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterAValidEmailAddress;

  /// No description provided for @sendAnotherResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send another reset link'**
  String get sendAnotherResetLink;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @welcomeBack2.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack2;

  /// No description provided for @signInToContinueTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to {appName}'**
  String signInToContinueTo(String appName);

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @useYourEmailAndPasswordOr.
  ///
  /// In en, this message translates to:
  /// **'Use your email and password, or sign in with your PIN.'**
  String get useYourEmailAndPasswordOr;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @passwordMustBeAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6;

  /// No description provided for @loginWithPin.
  ///
  /// In en, this message translates to:
  /// **'Login with PIN'**
  String get loginWithPin;

  /// No description provided for @newToBalajiPoints.
  ///
  /// In en, this message translates to:
  /// **'New to Balaji Points? '**
  String get newToBalajiPoints;

  /// No description provided for @createAccount2.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount2;

  /// No description provided for @designedAndDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Designed and developed by {companyName}'**
  String designedAndDevelopedBy(String companyName);

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @forCurrentMobilePinAccounts.
  ///
  /// In en, this message translates to:
  /// **'For current mobile + PIN accounts'**
  String get forCurrentMobilePinAccounts;

  /// No description provided for @enterAValid10DigitMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get enterAValid10DigitMobile;

  /// No description provided for @yourDataIs100SecureWith.
  ///
  /// In en, this message translates to:
  /// **'Your data is 100% secure with us'**
  String get yourDataIs100SecureWith;

  /// No description provided for @userAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'User already exists'**
  String get userAlreadyExists;

  /// No description provided for @permissionDeniedPleaseCheckFirebaseConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please check Firebase configuration.'**
  String get permissionDeniedPleaseCheckFirebaseConfiguration;

  /// No description provided for @branchAdminAlreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Branch Admin (Already Assigned)'**
  String get branchAdminAlreadyAssigned;

  /// No description provided for @branchAdmin1PerBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch Admin (1 per branch)'**
  String get branchAdmin1PerBranch;

  /// No description provided for @selectABranchToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a branch to continue.'**
  String get selectABranchToContinue;

  /// No description provided for @selectARoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a role to continue.'**
  String get selectARoleToContinue;

  /// No description provided for @selectAnActiveRoleToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select an active role to continue.'**
  String get selectAnActiveRoleToContinue;

  /// No description provided for @yourInformationIsProtected.
  ///
  /// In en, this message translates to:
  /// **'Your information is protected'**
  String get yourInformationIsProtected;

  /// No description provided for @completeYourGoogleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete your Google registration'**
  String get completeYourGoogleRegistration;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createYourAccount;

  /// No description provided for @addYourMobileNumberAndChoose.
  ///
  /// In en, this message translates to:
  /// **'Add your mobile number and choose your branch and role to finish setting up your account.'**
  String get addYourMobileNumberAndChoose;

  /// No description provided for @chooseYourRoleAndTheBranch.
  ///
  /// In en, this message translates to:
  /// **'Choose your role and the branch you belong to.'**
  String get chooseYourRoleAndTheBranch;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @useAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get useAtLeast6Characters;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @yourAccountAlreadyHasAnAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your account already has an Admin role. Ask the Super Admin to assign your branch before continuing.'**
  String get yourAccountAlreadyHasAnAdmin;

  /// No description provided for @branchAdminAccessIsAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Branch Admin access is assigned by a Super Admin.'**
  String get branchAdminAccessIsAssignedBy;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete registration'**
  String get completeRegistration;

  /// No description provided for @loadingRoles.
  ///
  /// In en, this message translates to:
  /// **'Loading roles…'**
  String get loadingRoles;

  /// No description provided for @chooseOneRole.
  ///
  /// In en, this message translates to:
  /// **'Choose one role'**
  String get chooseOneRole;

  /// No description provided for @selectARoleToContinue2.
  ///
  /// In en, this message translates to:
  /// **'Select a role to continue'**
  String get selectARoleToContinue2;

  /// No description provided for @loadingBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading branches…'**
  String get loadingBranches;

  /// No description provided for @selectABranch.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get selectABranch;

  /// No description provided for @cannotMakePhoneCallTo.
  ///
  /// In en, this message translates to:
  /// **'Cannot make phone call to {phoneNumber}'**
  String cannotMakePhoneCallTo(String phoneNumber);

  /// No description provided for @errorMakingPhoneCall.
  ///
  /// In en, this message translates to:
  /// **'Error making phone call: {e}'**
  String errorMakingPhoneCall(String e);

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @installLatestToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please install the latest version of {appName} to continue.'**
  String installLatestToContinue(String appName);

  /// No description provided for @newerVersionReady.
  ///
  /// In en, this message translates to:
  /// **'A newer version is ready with improvements and fixes.'**
  String get newerVersionReady;

  /// No description provided for @pleaseSelectACarpenter.
  ///
  /// In en, this message translates to:
  /// **'Please select a carpenter'**
  String get pleaseSelectACarpenter;

  /// No description provided for @billSubmittedSuccessfullyItWillBe.
  ///
  /// In en, this message translates to:
  /// **'Bill submitted successfully! It will be reviewed.'**
  String get billSubmittedSuccessfullyItWillBe;

  /// No description provided for @duplicateBill.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Bill'**
  String get duplicateBill;

  /// No description provided for @aBillWithTheSameSite.
  ///
  /// In en, this message translates to:
  /// **'A bill with the SAME site, amount, and date already exists for this carpenter:'**
  String get aBillWithTheSameSite;

  /// No description provided for @site.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get site;

  /// No description provided for @pts2.
  ///
  /// In en, this message translates to:
  /// **'{duplicatePoints} pts'**
  String pts2(String duplicatePoints);

  /// No description provided for @pleaseVerifyThisIsNotA.
  ///
  /// In en, this message translates to:
  /// **'Please verify this is not a duplicate entry.'**
  String get pleaseVerifyThisIsNotA;

  /// No description provided for @error2.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String error2(String e);

  /// No description provided for @addAnyway2.
  ///
  /// In en, this message translates to:
  /// **'Add Anyway'**
  String get addAnyway2;

  /// No description provided for @addBillForCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Add Bill for Carpenter'**
  String get addBillForCarpenter;

  /// No description provided for @carpenter2.
  ///
  /// In en, this message translates to:
  /// **'Carpenter *'**
  String get carpenter2;

  /// No description provided for @billAmount2.
  ///
  /// In en, this message translates to:
  /// **'Bill Amount (₹) *'**
  String get billAmount2;

  /// No description provided for @billImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Bill Image (Optional)'**
  String get billImageOptional;

  /// No description provided for @siteName2.
  ///
  /// In en, this message translates to:
  /// **'Site Name'**
  String get siteName2;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor Name'**
  String get vendorName;

  /// No description provided for @pendingApproval2.
  ///
  /// In en, this message translates to:
  /// **'PENDING APPROVAL'**
  String get pendingApproval2;

  /// No description provided for @areYouSureYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this bill?\n\n₹{billData} will be processed.'**
  String areYouSureYouWantTo(String billData);

  /// No description provided for @billRejected2.
  ///
  /// In en, this message translates to:
  /// **'Bill rejected'**
  String get billRejected2;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @billNotFound.
  ///
  /// In en, this message translates to:
  /// **'Bill not found'**
  String get billNotFound;

  /// No description provided for @billId.
  ///
  /// In en, this message translates to:
  /// **'Bill ID'**
  String get billId;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {createdAt}'**
  String submitted(String createdAt);

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted On'**
  String get submittedOn;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @carpenterInfo.
  ///
  /// In en, this message translates to:
  /// **'Carpenter Info'**
  String get carpenterInfo;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @pts3.
  ///
  /// In en, this message translates to:
  /// **'{totalPoints} pts'**
  String pts3(String totalPoints);

  /// No description provided for @billSummary.
  ///
  /// In en, this message translates to:
  /// **'Bill Summary'**
  String get billSummary;

  /// No description provided for @billAmount3.
  ///
  /// In en, this message translates to:
  /// **'Bill Amount'**
  String get billAmount3;

  /// No description provided for @pointsToCredit.
  ///
  /// In en, this message translates to:
  /// **'Points to Credit'**
  String get pointsToCredit;

  /// No description provided for @billNo.
  ///
  /// In en, this message translates to:
  /// **'Bill No.'**
  String get billNo;

  /// No description provided for @pointsRate.
  ///
  /// In en, this message translates to:
  /// **'Points Rate'**
  String get pointsRate;

  /// No description provided for @t1Pt1000.
  ///
  /// In en, this message translates to:
  /// **'1 pt / ₹1000'**
  String get t1Pt1000;

  /// No description provided for @billType.
  ///
  /// In en, this message translates to:
  /// **'Bill Type'**
  String get billType;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @billAttachment2.
  ///
  /// In en, this message translates to:
  /// **'Bill Attachment'**
  String get billAttachment2;

  /// No description provided for @viewFullSize.
  ///
  /// In en, this message translates to:
  /// **'View Full Size'**
  String get viewFullSize;

  /// No description provided for @downloadImage.
  ///
  /// In en, this message translates to:
  /// **'Download Image'**
  String get downloadImage;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill Created'**
  String get billCreated;

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Approval'**
  String get waitingForApproval;

  /// No description provided for @pendingActionFromAdmin.
  ///
  /// In en, this message translates to:
  /// **'Pending action from admin'**
  String get pendingActionFromAdmin;

  /// No description provided for @justNow2.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow2;

  /// No description provided for @minAgo.
  ///
  /// In en, this message translates to:
  /// **'{inMinutes} min ago'**
  String minAgo(String inMinutes);

  /// No description provided for @billDetails2.
  ///
  /// In en, this message translates to:
  /// **'Bill Details - {billId}'**
  String billDetails2(String billId);

  /// No description provided for @errorLoadingBillDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading bill details'**
  String get errorLoadingBillDetails;

  /// No description provided for @noBillFound.
  ///
  /// In en, this message translates to:
  /// **'No bill found'**
  String get noBillFound;

  /// No description provided for @totalInstances.
  ///
  /// In en, this message translates to:
  /// **'Total Instances'**
  String get totalInstances;

  /// No description provided for @billEntries.
  ///
  /// In en, this message translates to:
  /// **'Bill Entries'**
  String get billEntries;

  /// No description provided for @instance.
  ///
  /// In en, this message translates to:
  /// **'Instance {index}'**
  String instance(String index);

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noBillsToExportApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'No bills to export. Apply filters or wait for data.'**
  String get noBillsToExportApplyFilters;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF...'**
  String get preparingPdf;

  /// No description provided for @noBillsMatchCurrentFiltersFor.
  ///
  /// In en, this message translates to:
  /// **'No bills match current filters for export.'**
  String get noBillsMatchCurrentFiltersFor;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {e}'**
  String exportFailed(String e);

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill #'**
  String get bill;

  /// No description provided for @approvedDate.
  ///
  /// In en, this message translates to:
  /// **'Approved Date'**
  String get approvedDate;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @exportAllBillsToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export all bills to PDF'**
  String get exportAllBillsToPdf;

  /// No description provided for @approveThisBillOfPointsWill.
  ///
  /// In en, this message translates to:
  /// **'Approve this bill of ₹{amount}?\n\n{amount2} points will be added to the carpenter.'**
  String approveThisBillOfPointsWill(String amount, String amount2);

  /// No description provided for @billApprovedAndPointsAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bill approved and points added successfully'**
  String get billApprovedAndPointsAddedSuccessfully;

  /// No description provided for @failedToApproveBill2.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve bill'**
  String get failedToApproveBill2;

  /// No description provided for @errorApprovingBill.
  ///
  /// In en, this message translates to:
  /// **'Error approving bill: {e}'**
  String errorApprovingBill(String e);

  /// No description provided for @failedToRejectBill2.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject bill'**
  String get failedToRejectBill2;

  /// No description provided for @errorRejectingBill.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting bill: {e}'**
  String errorRejectingBill(String e);

  /// No description provided for @dateFilters.
  ///
  /// In en, this message translates to:
  /// **'Date Filters'**
  String get dateFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @pts4.
  ///
  /// In en, this message translates to:
  /// **'{amount} pts'**
  String pts4(String amount);

  /// No description provided for @noHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get noHistoryAvailable;

  /// No description provided for @carpenterSummary.
  ///
  /// In en, this message translates to:
  /// **'Carpenter Summary'**
  String get carpenterSummary;

  /// No description provided for @totalPts.
  ///
  /// In en, this message translates to:
  /// **'Total: {totalPoints} pts'**
  String totalPts(String totalPoints);

  /// No description provided for @totalBills.
  ///
  /// In en, this message translates to:
  /// **'Total Bills'**
  String get totalBills;

  /// No description provided for @pointsBySite.
  ///
  /// In en, this message translates to:
  /// **'Points by Site'**
  String get pointsBySite;

  /// No description provided for @pts5.
  ///
  /// In en, this message translates to:
  /// **'{num} pts'**
  String pts5(String num);

  /// No description provided for @site2.
  ///
  /// In en, this message translates to:
  /// **'Site: '**
  String get site2;

  /// No description provided for @billDate3.
  ///
  /// In en, this message translates to:
  /// **'Bill Date: '**
  String get billDate3;

  /// No description provided for @approved2.
  ///
  /// In en, this message translates to:
  /// **'Approved: '**
  String get approved2;

  /// No description provided for @submitted2.
  ///
  /// In en, this message translates to:
  /// **'Submitted: '**
  String get submitted2;

  /// No description provided for @allBillsHistory.
  ///
  /// In en, this message translates to:
  /// **'All Bills History'**
  String get allBillsHistory;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'{filtered}/{billsList} bills'**
  String bills(String filtered, String billsList);

  /// No description provided for @filterBySite.
  ///
  /// In en, this message translates to:
  /// **'Filter by Site'**
  String get filterBySite;

  /// No description provided for @allSites.
  ///
  /// In en, this message translates to:
  /// **'All Sites'**
  String get allSites;

  /// No description provided for @billId2.
  ///
  /// In en, this message translates to:
  /// **'#{index} - Bill ID: {billNum}'**
  String billId2(String index, String billNum);

  /// No description provided for @pts6.
  ///
  /// In en, this message translates to:
  /// **'{pts} pts'**
  String pts6(String pts);

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @deleteAllNotifications2.
  ///
  /// In en, this message translates to:
  /// **'Delete All Notifications'**
  String get deleteAllNotifications2;

  /// No description provided for @areYouSureYouWantTo2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all admin notifications?'**
  String get areYouSureYouWantTo2;

  /// No description provided for @notificationSDeleted.
  ///
  /// In en, this message translates to:
  /// **'{docs} notification(s) deleted'**
  String notificationSDeleted(String docs);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {e}'**
  String deleteFailed(String e);

  /// No description provided for @balajiPointsAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Balaji Points - Admin Panel'**
  String get balajiPointsAdminPanel;

  /// No description provided for @branchAdmin.
  ///
  /// In en, this message translates to:
  /// **'Branch admin'**
  String get branchAdmin;

  /// No description provided for @spin.
  ///
  /// In en, this message translates to:
  /// **'Spin'**
  String get spin;

  /// No description provided for @pointsRepair.
  ///
  /// In en, this message translates to:
  /// **'Points Repair'**
  String get pointsRepair;

  /// No description provided for @duplicateAccounts.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Accounts'**
  String get duplicateAccounts;

  /// No description provided for @exportUsers.
  ///
  /// In en, this message translates to:
  /// **'Export Users'**
  String get exportUsers;

  /// No description provided for @cleanUp.
  ///
  /// In en, this message translates to:
  /// **'Clean Up'**
  String get cleanUp;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup Database'**
  String get backupDatabase;

  /// No description provided for @checkFirebaseDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Check Firebase Duplicates'**
  String get checkFirebaseDuplicates;

  /// No description provided for @smartCleanup.
  ///
  /// In en, this message translates to:
  /// **'Smart Cleanup'**
  String get smartCleanup;

  /// No description provided for @sendGreeting.
  ///
  /// In en, this message translates to:
  /// **'Send Greeting'**
  String get sendGreeting;

  /// No description provided for @users2.
  ///
  /// In en, this message translates to:
  /// **'Users - ...'**
  String get users2;

  /// No description provided for @users3.
  ///
  /// In en, this message translates to:
  /// **'Users - {count}'**
  String users3(String count);

  /// No description provided for @pleaseEnterPinInBothFields.
  ///
  /// In en, this message translates to:
  /// **'Please enter PIN in both fields'**
  String get pleaseEnterPinInBothFields;

  /// No description provided for @pinMustBe46Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4-6 digits'**
  String get pinMustBe46Digits;

  /// No description provided for @pinMustContainOnlyNumbers.
  ///
  /// In en, this message translates to:
  /// **'PIN must contain only numbers'**
  String get pinMustContainOnlyNumbers;

  /// No description provided for @pinResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN reset successfully'**
  String get pinResetSuccessfully;

  /// No description provided for @errorResettingPin.
  ///
  /// In en, this message translates to:
  /// **'Error resetting PIN: {e}'**
  String errorResettingPin(String e);

  /// No description provided for @resetPinFor.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN for: {carpenterName}'**
  String resetPinFor(String carpenterName);

  /// No description provided for @phone2.
  ///
  /// In en, this message translates to:
  /// **'Phone: {carpenterPhone}'**
  String phone2(String carpenterPhone);

  /// No description provided for @carpenterWillNeedToUseThis.
  ///
  /// In en, this message translates to:
  /// **'Carpenter will need to use this new PIN to login. Make sure to communicate it securely.'**
  String get carpenterWillNeedToUseThis;

  /// No description provided for @newPin46Digits.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4-6 digits)'**
  String get newPin46Digits;

  /// No description provided for @carpenterDetails.
  ///
  /// In en, this message translates to:
  /// **'Carpenter Details'**
  String get carpenterDetails;

  /// No description provided for @carpenterNotFound.
  ///
  /// In en, this message translates to:
  /// **'Carpenter not found'**
  String get carpenterNotFound;

  /// No description provided for @carpenterInformation.
  ///
  /// In en, this message translates to:
  /// **'Carpenter Information'**
  String get carpenterInformation;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @completeHistory.
  ///
  /// In en, this message translates to:
  /// **'Complete History'**
  String get completeHistory;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @editCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Edit Carpenter'**
  String get editCarpenter;

  /// No description provided for @changingPhoneNumberWillUpdateLogin.
  ///
  /// In en, this message translates to:
  /// **'Changing phone number will update login credentials'**
  String get changingPhoneNumberWillUpdateLogin;

  /// No description provided for @branchId.
  ///
  /// In en, this message translates to:
  /// **'Branch ID'**
  String get branchId;

  /// No description provided for @phoneNumberCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be empty'**
  String get phoneNumberCannotBeEmpty;

  /// No description provided for @carpenterUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Carpenter updated successfully'**
  String get carpenterUpdatedSuccessfully;

  /// No description provided for @errorUpdatingCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Error updating carpenter: {e}'**
  String errorUpdatingCarpenter(String e);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @pendingBillRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Bill Requests'**
  String get pendingBillRequests;

  /// No description provided for @siteMaterialPurchase.
  ///
  /// In en, this message translates to:
  /// **'Site Material Purchase'**
  String get siteMaterialPurchase;

  /// No description provided for @billNo2.
  ///
  /// In en, this message translates to:
  /// **'Bill No. {billNumber}'**
  String billNo2(String billNumber);

  /// No description provided for @site3.
  ///
  /// In en, this message translates to:
  /// **'Site: {siteName}'**
  String site3(String siteName);

  /// No description provided for @pts7.
  ///
  /// In en, this message translates to:
  /// **'+{amount} pts'**
  String pts7(String amount);

  /// No description provided for @approveThisBillOfPointsWill2.
  ///
  /// In en, this message translates to:
  /// **'Approve this bill of ₹{amount}?\n\n{amount2} points will be added.'**
  String approveThisBillOfPointsWill2(String amount, String amount2);

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistoryFound;

  /// No description provided for @pointsAwarded.
  ///
  /// In en, this message translates to:
  /// **'Points awarded'**
  String get pointsAwarded;

  /// No description provided for @pinMustBeAtLeast4.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 4 digits'**
  String get pinMustBeAtLeast4;

  /// No description provided for @carpenterCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Carpenter created successfully!'**
  String get carpenterCreatedSuccessfully;

  /// No description provided for @failedToCreateCarpenter.
  ///
  /// In en, this message translates to:
  /// **'Failed to create carpenter'**
  String get failedToCreateCarpenter;

  /// No description provided for @pin46Digits.
  ///
  /// In en, this message translates to:
  /// **'4-digit PIN'**
  String get pin46Digits;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @firstNameOptional.
  ///
  /// In en, this message translates to:
  /// **'First Name (Optional)'**
  String get firstNameOptional;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enterFirstName;

  /// No description provided for @lastNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Last Name (Optional)'**
  String get lastNameOptional;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enterLastName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @preparingCarpenterListPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing carpenter list PDF...'**
  String get preparingCarpenterListPdf;

  /// No description provided for @noCarpentersToExportForCurrent.
  ///
  /// In en, this message translates to:
  /// **'No carpenters to export for current filters.'**
  String get noCarpentersToExportForCurrent;

  /// No description provided for @carpenterListExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Carpenter list exported successfully!'**
  String get carpenterListExportedSuccessfully;

  /// No description provided for @errorExportingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error exporting PDF: {e}'**
  String errorExportingPdf(String e);

  /// No description provided for @exportCarpenterListToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export carpenter list to PDF'**
  String get exportCarpenterListToPdf;

  /// No description provided for @sortByPoints.
  ///
  /// In en, this message translates to:
  /// **'Sort by Points'**
  String get sortByPoints;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @recentJoins.
  ///
  /// In en, this message translates to:
  /// **'Recent Joins'**
  String get recentJoins;

  /// No description provided for @tier.
  ///
  /// In en, this message translates to:
  /// **'Tier: {tier}'**
  String tier(String tier);

  /// No description provided for @phoneTierPoints.
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}\nTier: {tier}\nPoints: {totalPoints}'**
  String phoneTierPoints(String phone, String tier, String totalPoints);

  /// No description provided for @points2.
  ///
  /// In en, this message translates to:
  /// **'{num} Points'**
  String points2(String num);

  /// No description provided for @deleteAll2.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll2;

  /// No description provided for @unableToLoadAdminNotifications.
  ///
  /// In en, this message translates to:
  /// **'Unable to load admin notifications'**
  String get unableToLoadAdminNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// No description provided for @youDonTHaveAnyAdmin.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any admin notifications yet'**
  String get youDonTHaveAnyAdmin;

  /// No description provided for @deleteNotification2.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotification2;

  /// No description provided for @dailySpinHistory.
  ///
  /// In en, this message translates to:
  /// **'Daily Spin History'**
  String get dailySpinHistory;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String text(String month, String year);

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @spinned.
  ///
  /// In en, this message translates to:
  /// **'Spinned'**
  String get spinned;

  /// No description provided for @noSpin.
  ///
  /// In en, this message translates to:
  /// **'No Spin'**
  String get noSpin;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @spinWinner.
  ///
  /// In en, this message translates to:
  /// **'Spin Winner'**
  String get spinWinner;

  /// No description provided for @winnerName.
  ///
  /// In en, this message translates to:
  /// **'Winner Name'**
  String get winnerName;

  /// No description provided for @failedToFetchCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch carpenters: {e}'**
  String failedToFetchCarpenters(String e);

  /// No description provided for @failedToPickImage2.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {e}'**
  String failedToPickImage2(String e);

  /// No description provided for @failedToCaptureImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture image: {e}'**
  String failedToCaptureImage(String e);

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {e}'**
  String failedToUploadImage(String e);

  /// No description provided for @notificationSentToCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to {notificationCount} carpenters'**
  String notificationSentToCarpenters(String notificationCount);

  /// No description provided for @failedToSendNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to send notifications: {e}'**
  String failedToSendNotifications(String e);

  /// No description provided for @pleaseEnterAMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get pleaseEnterAMessage;

  /// No description provided for @pleaseSelectAtLeastOneChannel.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one channel'**
  String get pleaseSelectAtLeastOneChannel;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @showInApp.
  ///
  /// In en, this message translates to:
  /// **'Show in App'**
  String get showInApp;

  /// No description provided for @greetingSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Greeting sent successfully!'**
  String get greetingSentSuccessfully;

  /// No description provided for @sendingGreeting.
  ///
  /// In en, this message translates to:
  /// **'Sending greeting...'**
  String get sendingGreeting;

  /// No description provided for @composeMessage.
  ///
  /// In en, this message translates to:
  /// **'Compose Message'**
  String get composeMessage;

  /// No description provided for @enterGreetingMessageForAllCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Enter greeting'**
  String get enterGreetingMessageForAllCarpenters;

  /// No description provided for @imageOptional.
  ///
  /// In en, this message translates to:
  /// **'Image (Optional)'**
  String get imageOptional;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @orEnterImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Or enter image URL:'**
  String get orEnterImageUrl;

  /// No description provided for @enterImageUrlJpgPng.
  ///
  /// In en, this message translates to:
  /// **'Enter image URL'**
  String get enterImageUrlJpgPng;

  /// No description provided for @invalidImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid image URL'**
  String get invalidImageUrl;

  /// No description provided for @selectChannels.
  ///
  /// In en, this message translates to:
  /// **'Select Channels'**
  String get selectChannels;

  /// No description provided for @showInAppHomeBanner.
  ///
  /// In en, this message translates to:
  /// **'Show in App (Home Banner)'**
  String get showInAppHomeBanner;

  /// No description provided for @bannerOnCarpenterHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Banner on carpenter home screen'**
  String get bannerOnCarpenterHomeScreen;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @manualSendViaWhatsappApp.
  ///
  /// In en, this message translates to:
  /// **'Manual send via WhatsApp app'**
  String get manualSendViaWhatsappApp;

  /// No description provided for @manualSendViaSmsApp.
  ///
  /// In en, this message translates to:
  /// **'Manual send via SMS app'**
  String get manualSendViaSmsApp;

  /// No description provided for @noteWhatsappAndSmsUseDevice.
  ///
  /// In en, this message translates to:
  /// **'Note: WhatsApp and SMS use device-assisted flow. Admin must confirm each message in the native app.'**
  String get noteWhatsappAndSmsUseDevice;

  /// No description provided for @whatsappNotAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp not available for {name}'**
  String whatsappNotAvailableFor(String name);

  /// No description provided for @smsNotAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'SMS not available for {name}'**
  String smsNotAvailableFor(String name);

  /// No description provided for @sendToAll.
  ///
  /// In en, this message translates to:
  /// **'Send to All?'**
  String get sendToAll;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {i}/{carpenters}'**
  String progress(String i, String carpenters);

  /// No description provided for @opened.
  ///
  /// In en, this message translates to:
  /// **'Opened: {name}\n{phone}'**
  String opened(String name, String phone);

  /// No description provided for @tapSendInTheAppThen.
  ///
  /// In en, this message translates to:
  /// **'Tap Send in the app, then tap OK here to continue.'**
  String get tapSendInTheAppThen;

  /// No description provided for @sentToAllCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Sent to all {sentCount} carpenters'**
  String sentToAllCarpenters(String sentCount);

  /// No description provided for @confirmSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm Send'**
  String get confirmSend;

  /// No description provided for @sendAll.
  ///
  /// In en, this message translates to:
  /// **'Send All'**
  String get sendAll;

  /// No description provided for @sendViaWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get sendViaWhatsapp;

  /// No description provided for @sendViaSms.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get sendViaSms;

  /// No description provided for @pleaseWait24HoursFromThe.
  ///
  /// In en, this message translates to:
  /// **'Please wait 24 hours from the last spin'**
  String get pleaseWait24HoursFromThe;

  /// No description provided for @noCarpentersWithApprovedBillsToday.
  ///
  /// In en, this message translates to:
  /// **'No carpenters with approved bills today'**
  String get noCarpentersWithApprovedBillsToday;

  /// No description provided for @noEligibleCarpentersFound.
  ///
  /// In en, this message translates to:
  /// **'No eligible carpenters found'**
  String get noEligibleCarpentersFound;

  /// No description provided for @isTodaySWinner.
  ///
  /// In en, this message translates to:
  /// **'{carpenterName} is today\'s winner!'**
  String isTodaySWinner(String carpenterName);

  /// No description provided for @selectALuckyWinner.
  ///
  /// In en, this message translates to:
  /// **'Select a lucky winner'**
  String get selectALuckyWinner;

  /// No description provided for @viewSpinHistory.
  ///
  /// In en, this message translates to:
  /// **'View Spin History'**
  String get viewSpinHistory;

  /// No description provided for @winner2.
  ///
  /// In en, this message translates to:
  /// **'Winner: {winnerName}'**
  String winner2(String winnerName);

  /// No description provided for @noPreviousSpins.
  ///
  /// In en, this message translates to:
  /// **'No previous spins'**
  String get noPreviousSpins;

  /// No description provided for @readyToSpin.
  ///
  /// In en, this message translates to:
  /// **'Ready to spin!'**
  String get readyToSpin;

  /// No description provided for @nextSpinInHM.
  ///
  /// In en, this message translates to:
  /// **'Next spin in: {hoursRemaining}h {minutesRemaining}m'**
  String nextSpinInHM(String hoursRemaining, String minutesRemaining);

  /// No description provided for @todaySWinners.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Winners'**
  String get todaySWinners;

  /// No description provided for @noWinnersYetToday.
  ///
  /// In en, this message translates to:
  /// **'No winners yet today'**
  String get noWinnersYetToday;

  /// No description provided for @monthlyWinners.
  ///
  /// In en, this message translates to:
  /// **'Monthly Winners'**
  String get monthlyWinners;

  /// No description provided for @fullHistory.
  ///
  /// In en, this message translates to:
  /// **'Full History'**
  String get fullHistory;

  /// No description provided for @noWinnersThisMonthYet.
  ///
  /// In en, this message translates to:
  /// **'No winners this month yet'**
  String get noWinnersThisMonthYet;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @pleaseEnterAValidNumberFor.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number for points'**
  String get pleaseEnterAValidNumberFor;

  /// No description provided for @pleaseUploadABannerImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload a banner image'**
  String get pleaseUploadABannerImage;

  /// No description provided for @failedToUploadBannerImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload banner image'**
  String get failedToUploadBannerImage;

  /// No description provided for @loadingEligibleCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Loading eligible carpenters...'**
  String get loadingEligibleCarpenters;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noEligibleCarpentersToday.
  ///
  /// In en, this message translates to:
  /// **'No Eligible Carpenters Today'**
  String get noEligibleCarpentersToday;

  /// No description provided for @noCarpentersHaveApprovedBillsToday.
  ///
  /// In en, this message translates to:
  /// **'No carpenters have approved bills today.\nApprove bills to make them eligible for the daily spin!'**
  String get noCarpentersHaveApprovedBillsToday;

  /// No description provided for @todaySEligibleCarpenters.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Eligible Carpenters'**
  String get todaySEligibleCarpenters;

  /// No description provided for @eligible.
  ///
  /// In en, this message translates to:
  /// **'{todayStr} • {carpenters} eligible'**
  String eligible(String todayStr, String carpenters);

  /// No description provided for @branchAdminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Branch admin accounts'**
  String get branchAdminAccounts;

  /// No description provided for @reviewEachAdminAndTheBranch.
  ///
  /// In en, this message translates to:
  /// **'Review each admin and the branch they manage. Reset passwords or remove an account.'**
  String get reviewEachAdminAndTheBranch;

  /// No description provided for @searchByNameEmailOrBranch.
  ///
  /// In en, this message translates to:
  /// **'Search admins'**
  String get searchByNameEmailOrBranch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @loadingBranchAdminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Loading branch admin accounts…'**
  String get loadingBranchAdminAccounts;

  /// No description provided for @noBranchAdminAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No branch admin accounts yet.'**
  String get noBranchAdminAccountsYet;

  /// No description provided for @loadingBranchNames.
  ///
  /// In en, this message translates to:
  /// **'Loading branch names…'**
  String get loadingBranchNames;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @noAdminAccountsMatch.
  ///
  /// In en, this message translates to:
  /// **'No admin accounts match “{search}”.'**
  String noAdminAccountsMatch(String search);

  /// No description provided for @adminAccounts.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts'**
  String get adminAccounts;

  /// No description provided for @passwordUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Password updated for {email}.'**
  String passwordUpdatedFor(String email);

  /// No description provided for @deleteBranchAdmin.
  ///
  /// In en, this message translates to:
  /// **'Delete branch admin?'**
  String get deleteBranchAdmin;

  /// No description provided for @deleteForTheyWillLoseSign.
  ///
  /// In en, this message translates to:
  /// **'Delete {email} for {branchName}? They will lose sign-in access. Branch members and their points will be kept.'**
  String deleteForTheyWillLoseSign(String email, String branchName);

  /// No description provided for @deleteAdmin.
  ///
  /// In en, this message translates to:
  /// **'Delete admin'**
  String get deleteAdmin;

  /// No description provided for @adminAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Admin account deleted.'**
  String get adminAccountDeleted;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @changeAdminPassword.
  ///
  /// In en, this message translates to:
  /// **'Change admin password'**
  String get changeAdminPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @useAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get useAtLeast8Characters;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @branchManagement.
  ///
  /// In en, this message translates to:
  /// **'Branch management'**
  String get branchManagement;

  /// No description provided for @branchesManageBranchAccessAndStatus.
  ///
  /// In en, this message translates to:
  /// **'{docs} branches · manage branch access and status'**
  String branchesManageBranchAccessAndStatus(String docs);

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add branch'**
  String get addBranch;

  /// No description provided for @noBranchesYet.
  ///
  /// In en, this message translates to:
  /// **'No branches yet.'**
  String get noBranchesYet;

  /// No description provided for @branchesCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Branches could not be loaded.'**
  String get branchesCouldNotBeLoaded;

  /// No description provided for @diwaliCelebrationEnabledAddBillIs.
  ///
  /// In en, this message translates to:
  /// **'Diwali celebration enabled. Add Bill is hidden for this branch.'**
  String get diwaliCelebrationEnabledAddBillIs;

  /// No description provided for @diwaliCelebrationDisabledAddBillIs.
  ///
  /// In en, this message translates to:
  /// **'Diwali celebration disabled. Add Bill is available for this branch.'**
  String get diwaliCelebrationDisabledAddBillIs;

  /// No description provided for @unableToUpdateTheBranchCelebration.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the branch celebration setting.'**
  String get unableToUpdateTheBranchCelebration;

  /// No description provided for @codeId.
  ///
  /// In en, this message translates to:
  /// **'Code: {branchCode}  ·  ID: {branchId}'**
  String codeId(String branchCode, String branchId);

  /// No description provided for @diwaliCelebrationOnHome.
  ///
  /// In en, this message translates to:
  /// **'Diwali celebration on Home'**
  String get diwaliCelebrationOnHome;

  /// No description provided for @showsTheBranchPrizeListAnd.
  ///
  /// In en, this message translates to:
  /// **'Shows the branch prize list and hides Add Bill.'**
  String get showsTheBranchPrizeListAnd;

  /// No description provided for @offNoPopupAddBillRemains.
  ///
  /// In en, this message translates to:
  /// **'Off: no popup; Add Bill remains available.'**
  String get offNoPopupAddBillRemains;

  /// No description provided for @branchDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Branch deactivated.'**
  String get branchDeactivated;

  /// No description provided for @branchActivated.
  ///
  /// In en, this message translates to:
  /// **'Branch activated.'**
  String get branchActivated;

  /// No description provided for @unableToUpdateTheBranch.
  ///
  /// In en, this message translates to:
  /// **'Unable to update the branch.'**
  String get unableToUpdateTheBranch;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @branchCreated.
  ///
  /// In en, this message translates to:
  /// **'Branch created ({id})'**
  String branchCreated(String id);

  /// No description provided for @failedToCreateBranch.
  ///
  /// In en, this message translates to:
  /// **'Failed to create branch'**
  String get failedToCreateBranch;

  /// No description provided for @newBranch.
  ///
  /// In en, this message translates to:
  /// **'New Branch'**
  String get newBranch;

  /// No description provided for @branchFullName.
  ///
  /// In en, this message translates to:
  /// **'Branch Full Name *'**
  String get branchFullName;

  /// No description provided for @shortName.
  ///
  /// In en, this message translates to:
  /// **'Short Name *'**
  String get shortName;

  /// No description provided for @enterAShortBranchName.
  ///
  /// In en, this message translates to:
  /// **'Enter a short branch name'**
  String get enterAShortBranchName;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Branch Code *'**
  String get branchCode;

  /// No description provided for @use216LettersNumbersOr.
  ///
  /// In en, this message translates to:
  /// **'Use 2–16 letters, numbers or hyphens'**
  String get use216LettersNumbersOr;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @shareTheTemporaryPasswordSecurelyThe.
  ///
  /// In en, this message translates to:
  /// **'Share the temporary password securely. The admin can change it after their first sign-in.'**
  String get shareTheTemporaryPasswordSecurelyThe;

  /// No description provided for @adminCreatedForTheyCanSign.
  ///
  /// In en, this message translates to:
  /// **'Admin {email} created for {branchName}. They can sign in with email and password.'**
  String adminCreatedForTheyCanSign(String email, String branchName);

  /// No description provided for @selectABranchFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a branch first.'**
  String get selectABranchFirst;

  /// No description provided for @adminDetails.
  ///
  /// In en, this message translates to:
  /// **'Admin Details'**
  String get adminDetails;

  /// No description provided for @mobileNumber10Digits.
  ///
  /// In en, this message translates to:
  /// **'Mobile number * (10 digits)'**
  String get mobileNumber10Digits;

  /// No description provided for @enterValid10DigitPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit phone'**
  String get enterValid10DigitPhone;

  /// No description provided for @emailAndPasswordLogin.
  ///
  /// In en, this message translates to:
  /// **'Email and password login'**
  String get emailAndPasswordLogin;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address *'**
  String get emailAddress;

  /// No description provided for @temporaryPassword8CharactersMinimum.
  ///
  /// In en, this message translates to:
  /// **'Temporary password * (8 characters minimum)'**
  String get temporaryPassword8CharactersMinimum;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password *'**
  String get confirmPassword;

  /// No description provided for @assignBranch.
  ///
  /// In en, this message translates to:
  /// **'Assign Branch'**
  String get assignBranch;

  /// No description provided for @loadingActiveBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading active branches…'**
  String get loadingActiveBranches;

  /// No description provided for @noActiveBranchesFoundCreateOr.
  ///
  /// In en, this message translates to:
  /// **'No active branches found. Create or activate a branch before adding an admin.'**
  String get noActiveBranchesFoundCreateOr;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select branch'**
  String get selectBranch;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @createAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Create admin account'**
  String get createAdminAccount;

  /// No description provided for @signOutOfSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sign out of super admin?'**
  String get signOutOfSuperAdmin;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @superAdminConsole.
  ///
  /// In en, this message translates to:
  /// **'Super Admin Console'**
  String get superAdminConsole;

  /// No description provided for @branchesAdministratorsAndPoints.
  ///
  /// In en, this message translates to:
  /// **'Branches, administrators and points'**
  String get branchesAdministratorsAndPoints;

  /// No description provided for @branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branches;

  /// No description provided for @createAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create Admin'**
  String get createAdmin;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @superAdmin2.
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get superAdmin2;

  /// No description provided for @createAdmin2.
  ///
  /// In en, this message translates to:
  /// **'Create admin'**
  String get createAdmin2;

  /// No description provided for @pointsReset.
  ///
  /// In en, this message translates to:
  /// **'Points reset'**
  String get pointsReset;

  /// No description provided for @onlyPointsTiersAndPointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Only points, tiers and points history for carpenters, architects, engineers and interior designers are cleared. User accounts, login access, branch admins and bills stay unchanged.'**
  String get onlyPointsTiersAndPointsHistory;

  /// No description provided for @afterPrizeDistributionStartAFresh.
  ///
  /// In en, this message translates to:
  /// **'After prize distribution, start a fresh points season for one branch.'**
  String get afterPrizeDistributionStartAFresh;

  /// No description provided for @resetUsersAndDeletedHistoryRecords.
  ///
  /// In en, this message translates to:
  /// **'{branchName}: reset {usersReset} users and deleted {historyDocumentsDeleted} history records. Accounts and bills were kept.'**
  String resetUsersAndDeletedHistoryRecords(
    String branchName,
    String usersReset,
    String historyDocumentsDeleted,
  );

  /// No description provided for @thisPermanentlyClearsPointsAndPoints.
  ///
  /// In en, this message translates to:
  /// **'This permanently clears points and points history for carpenters, architects, engineers and interior designers in this branch. User accounts, branch admins and bills are kept.'**
  String get thisPermanentlyClearsPointsAndPoints;

  /// No description provided for @hasEligibleUsersPointsAndHistory.
  ///
  /// In en, this message translates to:
  /// **'{branchName} has {eligibleUsers} eligible users, {currentPoints} points and {historyDocuments} history items.'**
  String hasEligibleUsersPointsAndHistory(
    String branchName,
    String eligibleUsers,
    String currentPoints,
    String historyDocuments,
  );

  /// No description provided for @resetBranchPoints.
  ///
  /// In en, this message translates to:
  /// **'Reset branch points?'**
  String get resetBranchPoints;

  /// No description provided for @typeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {branchId} to confirm'**
  String typeToConfirm(String branchId);

  /// No description provided for @resetPointsAndHistory.
  ///
  /// In en, this message translates to:
  /// **'Reset points and history'**
  String get resetPointsAndHistory;

  /// No description provided for @couldNotLoadBranchesForPoints.
  ///
  /// In en, this message translates to:
  /// **'Could not load branches for points cleanup.'**
  String get couldNotLoadBranchesForPoints;

  /// No description provided for @annualPointsReset.
  ///
  /// In en, this message translates to:
  /// **'Annual points reset'**
  String get annualPointsReset;

  /// No description provided for @branchToReset.
  ///
  /// In en, this message translates to:
  /// **'Branch to reset'**
  String get branchToReset;

  /// No description provided for @checkingBranch.
  ///
  /// In en, this message translates to:
  /// **'Checking branch…'**
  String get checkingBranch;

  /// No description provided for @previewReset.
  ///
  /// In en, this message translates to:
  /// **'Preview reset'**
  String get previewReset;

  /// No description provided for @createABranchBeforeResettingPoints.
  ///
  /// In en, this message translates to:
  /// **'Create a branch before resetting points.'**
  String get createABranchBeforeResettingPoints;

  /// No description provided for @cleanupPreview.
  ///
  /// In en, this message translates to:
  /// **'Cleanup preview · {branchName}'**
  String cleanupPreview(String branchName);

  /// No description provided for @eligibleUsers.
  ///
  /// In en, this message translates to:
  /// **'Eligible users'**
  String get eligibleUsers;

  /// No description provided for @currentPoints.
  ///
  /// In en, this message translates to:
  /// **'Current points'**
  String get currentPoints;

  /// No description provided for @historyItems.
  ///
  /// In en, this message translates to:
  /// **'History items'**
  String get historyItems;

  /// No description provided for @resettingBranchPoints.
  ///
  /// In en, this message translates to:
  /// **'Resetting branch points…'**
  String get resettingBranchPoints;

  /// No description provided for @couldNotLoadSavedRolesShowing.
  ///
  /// In en, this message translates to:
  /// **'Could not load saved roles. Showing the four built-in roles. {loadError}'**
  String couldNotLoadSavedRolesShowing(String loadError);

  /// No description provided for @roleIdsAreStoredWithUser.
  ///
  /// In en, this message translates to:
  /// **'Role IDs are stored with user accounts. Deleting a role removes it from new registrations and preserves existing accounts.'**
  String get roleIdsAreStoredWithUser;

  /// No description provided for @willBeRemovedFromNewRegistration.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from new registration. Existing users keep their role and account data.'**
  String willBeRemovedFromNewRegistration(String name);

  /// No description provided for @roleCreated.
  ///
  /// In en, this message translates to:
  /// **'Role created: {name} ({id}).'**
  String roleCreated(String name, String id);

  /// No description provided for @restoreRole.
  ///
  /// In en, this message translates to:
  /// **'Restore role?'**
  String get restoreRole;

  /// No description provided for @deleteRole.
  ///
  /// In en, this message translates to:
  /// **'Delete role?'**
  String get deleteRole;

  /// No description provided for @willBeAvailableForNewAccount.
  ///
  /// In en, this message translates to:
  /// **'{name} will be available for new account registration.'**
  String willBeAvailableForNewAccount(String name);

  /// No description provided for @restoreRole2.
  ///
  /// In en, this message translates to:
  /// **'Restore role'**
  String get restoreRole2;

  /// No description provided for @deleteRole2.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get deleteRole2;

  /// No description provided for @accountRoles.
  ///
  /// In en, this message translates to:
  /// **'Account roles'**
  String get accountRoles;

  /// No description provided for @manageTheRolesShownInCreate.
  ///
  /// In en, this message translates to:
  /// **'Manage the roles shown in create account.'**
  String get manageTheRolesShownInCreate;

  /// No description provided for @addRole.
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get addRole;

  /// No description provided for @loadingAccountRoles.
  ///
  /// In en, this message translates to:
  /// **'Loading account roles…'**
  String get loadingAccountRoles;

  /// No description provided for @noRolesFound.
  ///
  /// In en, this message translates to:
  /// **'No roles found.'**
  String get noRolesFound;

  /// No description provided for @roleId.
  ///
  /// In en, this message translates to:
  /// **'Role ID: {id}'**
  String roleId(String id);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @addAccountRole.
  ///
  /// In en, this message translates to:
  /// **'Add account role'**
  String get addAccountRole;

  /// No description provided for @roleName.
  ///
  /// In en, this message translates to:
  /// **'Role name *'**
  String get roleName;

  /// No description provided for @enterAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters'**
  String get enterAtLeast2Characters;

  /// No description provided for @shortFormOptional.
  ///
  /// In en, this message translates to:
  /// **'Short form (optional)'**
  String get shortFormOptional;

  /// No description provided for @exampleAr.
  ///
  /// In en, this message translates to:
  /// **'Enter short form'**
  String get exampleAr;

  /// No description provided for @use10CharactersOrLess.
  ///
  /// In en, this message translates to:
  /// **'Use 10 characters or less'**
  String get use10CharactersOrLess;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveRole.
  ///
  /// In en, this message translates to:
  /// **'Save role'**
  String get saveRole;

  /// No description provided for @cleanUpDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Clean Up Duplicates'**
  String get cleanUpDuplicates;

  /// No description provided for @error3.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error3(String error);

  /// No description provided for @duplicatesFound.
  ///
  /// In en, this message translates to:
  /// **'Duplicates Found'**
  String get duplicatesFound;

  /// No description provided for @accountsAcrossPhoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'{duplicateCount} accounts across {duplicates} phone numbers'**
  String accountsAcrossPhoneNumbers(String duplicateCount, String duplicates);

  /// No description provided for @noDuplicatesFound.
  ///
  /// In en, this message translates to:
  /// **'No Duplicates Found!'**
  String get noDuplicatesFound;

  /// No description provided for @allCarpenterAccountsAreUnique.
  ///
  /// In en, this message translates to:
  /// **'All carpenter accounts are unique.'**
  String get allCarpenterAccountsAreUnique;

  /// No description provided for @duplicateGroups.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Groups'**
  String get duplicateGroups;

  /// No description provided for @phoneAccounts.
  ///
  /// In en, this message translates to:
  /// **'{groupIndex}. Phone: {phone} ({users} accounts)'**
  String phoneAccounts(String groupIndex, String phone, String users);

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @reviewOnly.
  ///
  /// In en, this message translates to:
  /// **'Review only'**
  String get reviewOnly;

  /// No description provided for @diagnosticUser.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic: User {phoneNumber}'**
  String diagnosticUser(String phoneNumber);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @phoneNumberInformation.
  ///
  /// In en, this message translates to:
  /// **'Phone Number Information'**
  String get phoneNumberInformation;

  /// No description provided for @originalPhone.
  ///
  /// In en, this message translates to:
  /// **'Original Phone'**
  String get originalPhone;

  /// No description provided for @normalizedPhone.
  ///
  /// In en, this message translates to:
  /// **'Normalized Phone'**
  String get normalizedPhone;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// No description provided for @userDocumentStatus.
  ///
  /// In en, this message translates to:
  /// **'User Document Status'**
  String get userDocumentStatus;

  /// No description provided for @existsByDocumentId.
  ///
  /// In en, this message translates to:
  /// **'Exists (by Document ID)'**
  String get existsByDocumentId;

  /// No description provided for @documentId.
  ///
  /// In en, this message translates to:
  /// **'Document ID'**
  String get documentId;

  /// No description provided for @phoneFieldInData.
  ///
  /// In en, this message translates to:
  /// **'Phone Field (in data)'**
  String get phoneFieldInData;

  /// No description provided for @existsByPhoneFieldQuery.
  ///
  /// In en, this message translates to:
  /// **'Exists (by Phone Field Query)'**
  String get existsByPhoneFieldQuery;

  /// No description provided for @documentIdFromQuery.
  ///
  /// In en, this message translates to:
  /// **'Document ID (from query)'**
  String get documentIdFromQuery;

  /// No description provided for @issueDetected.
  ///
  /// In en, this message translates to:
  /// **'ISSUE DETECTED'**
  String get issueDetected;

  /// No description provided for @documentIdMismatch.
  ///
  /// In en, this message translates to:
  /// **'Document ID mismatch!'**
  String get documentIdMismatch;

  /// No description provided for @userDocumentFound.
  ///
  /// In en, this message translates to:
  /// **'User document found'**
  String get userDocumentFound;

  /// No description provided for @userDocumentNotFound.
  ///
  /// In en, this message translates to:
  /// **'User document NOT FOUND'**
  String get userDocumentNotFound;

  /// No description provided for @billsCollectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Bills Collection Status'**
  String get billsCollectionStatus;

  /// No description provided for @phoneFormatMismatchInBills.
  ///
  /// In en, this message translates to:
  /// **'Phone format mismatch in bills!'**
  String get phoneFormatMismatchInBills;

  /// No description provided for @phoneFormatConsistent.
  ///
  /// In en, this message translates to:
  /// **'Phone format consistent'**
  String get phoneFormatConsistent;

  /// No description provided for @pendingBillsStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending Bills Status'**
  String get pendingBillsStatus;

  /// No description provided for @totalPendingBills.
  ///
  /// In en, this message translates to:
  /// **'Total Pending Bills'**
  String get totalPendingBills;

  /// No description provided for @matchingBillsFound.
  ///
  /// In en, this message translates to:
  /// **'Matching Bills Found'**
  String get matchingBillsFound;

  /// No description provided for @noPendingBillsFoundForThis.
  ///
  /// In en, this message translates to:
  /// **'No pending bills found for this user!'**
  String get noPendingBillsFoundForThis;

  /// No description provided for @carpenterId.
  ///
  /// In en, this message translates to:
  /// **'Carpenter ID'**
  String get carpenterId;

  /// No description provided for @carpenterPhone.
  ///
  /// In en, this message translates to:
  /// **'Carpenter Phone'**
  String get carpenterPhone;

  /// No description provided for @isToday.
  ///
  /// In en, this message translates to:
  /// **'Is Today'**
  String get isToday;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @thisBillWonTShowIn.
  ///
  /// In en, this message translates to:
  /// **'This bill won\'t show in default admin view (not today)'**
  String get thisBillWonTShowIn;

  /// No description provided for @totalAccounts.
  ///
  /// In en, this message translates to:
  /// **'Total Accounts'**
  String get totalAccounts;

  /// No description provided for @duplicatePhones.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phones'**
  String get duplicatePhones;

  /// No description provided for @affectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Affected Accounts'**
  String get affectedAccounts;

  /// No description provided for @noDuplicateAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No duplicate accounts found!'**
  String get noDuplicateAccountsFound;

  /// No description provided for @duplicatePhoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phone Numbers'**
  String get duplicatePhoneNumbers;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account {idx}'**
  String account(String idx);

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @preparingUserBackupPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing user backup PDF...'**
  String get preparingUserBackupPdf;

  /// No description provided for @noCarpentersFound2.
  ///
  /// In en, this message translates to:
  /// **'No carpenters found.'**
  String get noCarpentersFound2;

  /// No description provided for @userBackupExportedSuccessfullyCarpenters.
  ///
  /// In en, this message translates to:
  /// **'User backup exported successfully! ({users} carpenters)'**
  String userBackupExportedSuccessfullyCarpenters(String users);

  /// No description provided for @exportUsersBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Users Backup'**
  String get exportUsersBackup;

  /// No description provided for @createUserBackup.
  ///
  /// In en, this message translates to:
  /// **'Create User Backup'**
  String get createUserBackup;

  /// No description provided for @exportAllCarpentersWithTheirPoints.
  ///
  /// In en, this message translates to:
  /// **'Export all carpenters with their points and phone numbers before cleanup.'**
  String get exportAllCarpentersWithTheirPoints;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @exportToPdf.
  ///
  /// In en, this message translates to:
  /// **'Export to PDF'**
  String get exportToPdf;

  /// No description provided for @pdfWillInclude.
  ///
  /// In en, this message translates to:
  /// **'PDF will include:'**
  String get pdfWillInclude;

  /// No description provided for @carpenterNameAndPhoneNumberTotal.
  ///
  /// In en, this message translates to:
  /// **'• Carpenter name and phone number\n• Total points and earned points\n• Account creation date\n• Summary with total carpenters and gross points'**
  String get carpenterNameAndPhoneNumberTotal;

  /// No description provided for @firebaseDuplicateCheck.
  ///
  /// In en, this message translates to:
  /// **'Firebase Duplicate Check'**
  String get firebaseDuplicateCheck;

  /// No description provided for @firebaseDatabaseSummary.
  ///
  /// In en, this message translates to:
  /// **'Firebase Database Summary'**
  String get firebaseDatabaseSummary;

  /// No description provided for @totalCarpenters2.
  ///
  /// In en, this message translates to:
  /// **'Total Carpenters:'**
  String get totalCarpenters2;

  /// No description provided for @uniquePhoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'Unique Phone Numbers:'**
  String get uniquePhoneNumbers;

  /// No description provided for @duplicatePhoneNumbers2.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phone Numbers:'**
  String get duplicatePhoneNumbers2;

  /// No description provided for @totalDuplicateAccounts.
  ///
  /// In en, this message translates to:
  /// **'Total Duplicate Accounts:'**
  String get totalDuplicateAccounts;

  /// No description provided for @allPhoneNumbersAreUnique.
  ///
  /// In en, this message translates to:
  /// **'All phone numbers are unique.'**
  String get allPhoneNumbersAreUnique;

  /// No description provided for @duplicateMobileNumbers.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Mobile Numbers'**
  String get duplicateMobileNumbers;

  /// No description provided for @mobile2.
  ///
  /// In en, this message translates to:
  /// **'{groupIndex}/{totalGroups} - Mobile: {phone}'**
  String mobile2(String groupIndex, String totalGroups, String phone);

  /// No description provided for @accountsWithSamePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'{users} accounts with same phone number'**
  String accountsWithSamePhoneNumber(String users);

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @startingBackup.
  ///
  /// In en, this message translates to:
  /// **'Starting backup...'**
  String get startingBackup;

  /// No description provided for @backupExportedUsersBills.
  ///
  /// In en, this message translates to:
  /// **'Backup exported: {users} users, {bills} bills'**
  String backupExportedUsersBills(String users, String bills);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {e}'**
  String backupFailed(String e);

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @totalSizeKb.
  ///
  /// In en, this message translates to:
  /// **'Total Size: {backupJson} KB'**
  String totalSizeKb(String backupJson);

  /// No description provided for @firebaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Firebase Backup'**
  String get firebaseBackup;

  /// No description provided for @databaseBackup.
  ///
  /// In en, this message translates to:
  /// **'Database Backup'**
  String get databaseBackup;

  /// No description provided for @createACompleteBackupOfAll.
  ///
  /// In en, this message translates to:
  /// **'Create a complete backup of all users and bills data from Firebase Firestore.'**
  String get createACompleteBackupOfAll;

  /// No description provided for @whatWillBeBackedUp.
  ///
  /// In en, this message translates to:
  /// **'What will be backed up:'**
  String get whatWillBeBackedUp;

  /// No description provided for @allUserAccountsCarpentersAdminsAll.
  ///
  /// In en, this message translates to:
  /// **'• All user accounts (carpenters & admins)\n• All bill records\n• Complete user data with timestamps\n• Firestore metadata'**
  String get allUserAccountsCarpentersAdminsAll;

  /// No description provided for @backingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up...'**
  String get backingUp;

  /// No description provided for @startBackup.
  ///
  /// In en, this message translates to:
  /// **'Start Backup'**
  String get startBackup;

  /// No description provided for @backupIsStoredInFirebaseNo.
  ///
  /// In en, this message translates to:
  /// **'Backup is stored in Firebase. No files are saved locally.'**
  String get backupIsStoredInFirebaseNo;

  /// No description provided for @repairDetails.
  ///
  /// In en, this message translates to:
  /// **'Repair Details'**
  String get repairDetails;

  /// No description provided for @verificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get verificationComplete;

  /// No description provided for @noPointsLostAllUsersVerified.
  ///
  /// In en, this message translates to:
  /// **'NO POINTS LOST\nAll users verified\nData consistent'**
  String get noPointsLostAllUsersVerified;

  /// No description provided for @userWiseRepairResults.
  ///
  /// In en, this message translates to:
  /// **'User-wise Repair Results'**
  String get userWiseRepairResults;

  /// No description provided for @noRepairsCompleted.
  ///
  /// In en, this message translates to:
  /// **'No repairs completed'**
  String get noRepairsCompleted;

  /// No description provided for @repairComplete.
  ///
  /// In en, this message translates to:
  /// **'Repair Complete'**
  String get repairComplete;

  /// No description provided for @successfullyRepaired.
  ///
  /// In en, this message translates to:
  /// **'Successfully Repaired'**
  String get successfullyRepaired;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @duplicatesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Duplicates Removed'**
  String get duplicatesRemoved;

  /// No description provided for @pointsAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Points Adjusted'**
  String get pointsAdjusted;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @repairFailed.
  ///
  /// In en, this message translates to:
  /// **'Repair failed'**
  String get repairFailed;

  /// No description provided for @thisToolScansUserPointsData.
  ///
  /// In en, this message translates to:
  /// **'This tool scans user points data and fixes:\n• Duplicate history entries\n• Inconsistent totalPoints\n• Mismatched tiers'**
  String get thisToolScansUserPointsData;

  /// No description provided for @pointsRepairTool.
  ///
  /// In en, this message translates to:
  /// **'Points Repair Tool'**
  String get pointsRepairTool;

  /// No description provided for @pointsDataRepair.
  ///
  /// In en, this message translates to:
  /// **'Points Data Repair'**
  String get pointsDataRepair;

  /// No description provided for @scanReport.
  ///
  /// In en, this message translates to:
  /// **'Scan Report'**
  String get scanReport;

  /// No description provided for @totalUsersScanned.
  ///
  /// In en, this message translates to:
  /// **'Total users scanned'**
  String get totalUsersScanned;

  /// No description provided for @usersWithIssues.
  ///
  /// In en, this message translates to:
  /// **'Users with issues'**
  String get usersWithIssues;

  /// No description provided for @usersWithDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Users with duplicates'**
  String get usersWithDuplicates;

  /// No description provided for @totalDuplicateEntries.
  ///
  /// In en, this message translates to:
  /// **'Total duplicate entries'**
  String get totalDuplicateEntries;

  /// No description provided for @pointsMismatches.
  ///
  /// In en, this message translates to:
  /// **'Points mismatches'**
  String get pointsMismatches;

  /// No description provided for @viewFullScanDetails.
  ///
  /// In en, this message translates to:
  /// **'View Full Scan Details'**
  String get viewFullScanDetails;

  /// No description provided for @viewDetailedResults.
  ///
  /// In en, this message translates to:
  /// **'View Detailed Results'**
  String get viewDetailedResults;

  /// No description provided for @scanForIssues.
  ///
  /// In en, this message translates to:
  /// **'Scan for Issues'**
  String get scanForIssues;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @repairAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Repair All Users'**
  String get repairAllUsers;

  /// No description provided for @noIssuesFoundAllUserData.
  ///
  /// In en, this message translates to:
  /// **'No issues found! All user data is consistent.'**
  String get noIssuesFoundAllUserData;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {e}'**
  String scanFailed(String e);

  /// No description provided for @repairAllUsers2.
  ///
  /// In en, this message translates to:
  /// **'Repair All Users?'**
  String get repairAllUsers2;

  /// No description provided for @repair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repair;

  /// No description provided for @repairFailed2.
  ///
  /// In en, this message translates to:
  /// **'Repair failed: {e}'**
  String repairFailed2(String e);

  /// No description provided for @scanningForIssues.
  ///
  /// In en, this message translates to:
  /// **'Scanning for Issues...'**
  String get scanningForIssues;

  /// No description provided for @analyzingAllUserPointsData.
  ///
  /// In en, this message translates to:
  /// **'Analyzing all user points data'**
  String get analyzingAllUserPointsData;

  /// No description provided for @scanResultsFullDetails.
  ///
  /// In en, this message translates to:
  /// **'Scan Results - Full Details'**
  String get scanResultsFullDetails;

  /// No description provided for @usersWithIssues2.
  ///
  /// In en, this message translates to:
  /// **'Users with Issues'**
  String get usersWithIssues2;

  /// No description provided for @noUsersWithIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'No users with issues found'**
  String get noUsersWithIssuesFound;

  /// No description provided for @scanSummary.
  ///
  /// In en, this message translates to:
  /// **'Scan Summary'**
  String get scanSummary;

  /// No description provided for @totalUsersScanned2.
  ///
  /// In en, this message translates to:
  /// **'Total Users Scanned'**
  String get totalUsersScanned2;

  /// No description provided for @totalDuplicateEntries2.
  ///
  /// In en, this message translates to:
  /// **'Total Duplicate Entries'**
  String get totalDuplicateEntries2;

  /// No description provided for @totalPointsDifference.
  ///
  /// In en, this message translates to:
  /// **'Total Points Difference'**
  String get totalPointsDifference;

  /// No description provided for @duplicates.
  ///
  /// In en, this message translates to:
  /// **'{duplicateCount} duplicates'**
  String duplicates(String duplicateCount);

  /// No description provided for @historySum.
  ///
  /// In en, this message translates to:
  /// **'History Sum'**
  String get historySum;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// No description provided for @uniqueBills.
  ///
  /// In en, this message translates to:
  /// **'Unique Bills'**
  String get uniqueBills;

  /// No description provided for @duplicateBills.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Bills:'**
  String get duplicateBills;

  /// No description provided for @smartDuplicateCleanup.
  ///
  /// In en, this message translates to:
  /// **'Smart Duplicate Cleanup'**
  String get smartDuplicateCleanup;

  /// No description provided for @allCarpentersHaveUniquePhoneNumbers.
  ///
  /// In en, this message translates to:
  /// **'All carpenters have unique phone numbers.'**
  String get allCarpentersHaveUniquePhoneNumbers;

  /// No description provided for @potentialDuplicateAccountsReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Potential duplicate accounts — review required'**
  String get potentialDuplicateAccountsReviewRequired;

  /// No description provided for @foundDuplicateMobileNumbers.
  ///
  /// In en, this message translates to:
  /// **'Found {duplicateGroups} duplicate mobile numbers'**
  String foundDuplicateMobileNumbers(String duplicateGroups);

  /// No description provided for @accountsToReview.
  ///
  /// In en, this message translates to:
  /// **'Accounts to review: {totalForReview}'**
  String accountsToReview(String totalForReview);

  /// No description provided for @allRecordsAreRetainedTheHighest.
  ///
  /// In en, this message translates to:
  /// **'All records are retained. The highest-points profile is only a suggested primary account.'**
  String get allRecordsAreRetainedTheHighest;

  /// No description provided for @potentialDuplicateGroups.
  ///
  /// In en, this message translates to:
  /// **'Potential duplicate groups ({duplicateGroups})'**
  String potentialDuplicateGroups(String duplicateGroups);

  /// No description provided for @mobile3.
  ///
  /// In en, this message translates to:
  /// **'{groupIndex}. Mobile: {phone}'**
  String mobile3(String groupIndex, String phone);

  /// No description provided for @similarAccountsPointsDiff.
  ///
  /// In en, this message translates to:
  /// **'{reviewUsers} similar accounts | Points diff: {pointsDiff}'**
  String similarAccountsPointsDiff(String reviewUsers, String pointsDiff);

  /// No description provided for @suggestedPrimaryAccountHighestPoints.
  ///
  /// In en, this message translates to:
  /// **'Suggested primary account (highest points)'**
  String get suggestedPrimaryAccountHighestPoints;

  /// No description provided for @otherMatchingAccountsManualReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Other matching accounts — manual review required'**
  String get otherMatchingAccountsManualReviewRequired;

  /// No description provided for @repairConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will repair {count} users by:\n\n• Removing duplicate history entries\n• Recalculating correct totals\n• Updating tier assignments\n\nThis action cannot be undone easily.'**
  String repairConfirmBody(String count);

  /// No description provided for @repairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Repaired {repaired}/{total} users successfully!\nVerified: no points lost'**
  String repairSuccess(String repaired, String total);

  /// No description provided for @repairPartial.
  ///
  /// In en, this message translates to:
  /// **'Repaired {repaired}/{total} users.\nSome verification issues - check logs'**
  String repairPartial(String repaired, String total);

  /// No description provided for @backupUsersCount.
  ///
  /// In en, this message translates to:
  /// **'Users ({count})'**
  String backupUsersCount(String count);

  /// No description provided for @backupBillsCount.
  ///
  /// In en, this message translates to:
  /// **'Bills ({count})'**
  String backupBillsCount(String count);

  /// No description provided for @openAppForEachCarpenter.
  ///
  /// In en, this message translates to:
  /// **'This will open {app} for each carpenter.\n\nYou must manually tap Send in each app.\n\nContinue?'**
  String openAppForEachCarpenter(String app);

  /// No description provided for @roleIdPreview.
  ///
  /// In en, this message translates to:
  /// **'Role ID: {id}'**
  String roleIdPreview(String id);

  /// No description provided for @winnersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 winner} other{{count} winners}}'**
  String winnersCount(int count);

  /// No description provided for @roleRestored.
  ///
  /// In en, this message translates to:
  /// **'Role {name} restored.'**
  String roleRestored(String name);

  /// No description provided for @roleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role {name} deleted.'**
  String roleDeleted(String name);

  /// No description provided for @permissionDeniedSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Check that Firestore rules are published and the signed-in account is the configured super admin.'**
  String get permissionDeniedSuperAdmin;

  /// No description provided for @roleEngineer.
  ///
  /// In en, this message translates to:
  /// **'Engineer'**
  String get roleEngineer;

  /// No description provided for @roleBuiltInBadge.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get roleBuiltInBadge;

  /// No description provided for @roleCustomBadge.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get roleCustomBadge;

  /// No description provided for @roleProtectedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Carpenter is the main role and can’t be deleted'**
  String get roleProtectedTooltip;

  /// No description provided for @rolesSummary.
  ///
  /// In en, this message translates to:
  /// **'{active, plural, other{{active} active}} · {deleted, plural, other{{deleted} deleted}}'**
  String rolesSummary(int active, int deleted);

  /// No description provided for @rolesLiveSync.
  ///
  /// In en, this message translates to:
  /// **'Changes sync instantly to registration on every device.'**
  String get rolesLiveSync;

  /// No description provided for @roleIdHelp.
  ///
  /// In en, this message translates to:
  /// **'Created from the name. It can’t be changed later.'**
  String get roleIdHelp;

  /// No description provided for @roleErrInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Use 2–40 characters with at least two English letters or numbers.'**
  String get roleErrInvalidName;

  /// No description provided for @roleErrReserved.
  ///
  /// In en, this message translates to:
  /// **'This name is reserved for administrator accounts.'**
  String get roleErrReserved;

  /// No description provided for @roleErrBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'This matches a built-in role. Restore it from the list instead.'**
  String get roleErrBuiltIn;

  /// No description provided for @roleErrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A role with this ID already exists.'**
  String get roleErrDuplicate;

  /// No description provided for @roleErrProtected.
  ///
  /// In en, this message translates to:
  /// **'Carpenter is the main role and can’t be deleted.'**
  String get roleErrProtected;

  /// No description provided for @roleShowAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get roleShowAll;

  /// No description provided for @roleShowActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get roleShowActive;

  /// No description provided for @roleShowDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get roleShowDeleted;

  /// No description provided for @noRolesInFilter.
  ///
  /// In en, this message translates to:
  /// **'No roles in this view.'**
  String get noRolesInFilter;

  /// No description provided for @deactivateBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateBranchTitle(String name);

  /// No description provided for @deactivateBranchBody.
  ///
  /// In en, this message translates to:
  /// **'New users can’t pick this branch and its members can’t sign in until you activate it again. No data is deleted.'**
  String get deactivateBranchBody;

  /// No description provided for @activateBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {name}?'**
  String activateBranchTitle(String name);

  /// No description provided for @activateBranchBody.
  ///
  /// In en, this message translates to:
  /// **'The branch will be available for registration and sign-in again.'**
  String get activateBranchBody;

  /// No description provided for @branchActions.
  ///
  /// In en, this message translates to:
  /// **'Branch actions'**
  String get branchActions;

  /// No description provided for @copyBranchId.
  ///
  /// In en, this message translates to:
  /// **'Copy branch ID'**
  String get copyBranchId;

  /// No description provided for @branchIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Branch ID copied'**
  String get branchIdCopied;

  /// No description provided for @celebrationOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get celebrationOn;

  /// No description provided for @celebrationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get celebrationOff;

  /// No description provided for @createAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a branch admin who reviews bills and carpenters for one branch.'**
  String get createAdminSubtitle;

  /// No description provided for @selectBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a branch'**
  String get selectBranchRequired;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add admin'**
  String get addAdmin;

  /// No description provided for @branchAdminsTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch admins'**
  String get branchAdminsTitle;

  /// No description provided for @adminsNav.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminsNav;

  /// No description provided for @adminsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 admin} other{{count} admins}}'**
  String adminsCount(int count);

  /// No description provided for @adminActions.
  ///
  /// In en, this message translates to:
  /// **'Admin actions'**
  String get adminActions;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit branch'**
  String get editBranch;

  /// No description provided for @branchUpdated.
  ///
  /// In en, this message translates to:
  /// **'Branch updated'**
  String get branchUpdated;

  /// No description provided for @branchCodeLocked.
  ///
  /// In en, this message translates to:
  /// **'The code can’t change — existing members are registered with it.'**
  String get branchCodeLocked;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @editRole.
  ///
  /// In en, this message translates to:
  /// **'Edit role'**
  String get editRole;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role {name} updated.'**
  String roleUpdated(String name);

  /// No description provided for @roleIdLocked.
  ///
  /// In en, this message translates to:
  /// **'The role ID can’t change — it is stored with user accounts.'**
  String get roleIdLocked;

  /// No description provided for @roleActions.
  ///
  /// In en, this message translates to:
  /// **'Role actions'**
  String get roleActions;

  /// No description provided for @editAdmin.
  ///
  /// In en, this message translates to:
  /// **'Edit admin'**
  String get editAdmin;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @adminUpdated.
  ///
  /// In en, this message translates to:
  /// **'Admin {email} updated.'**
  String adminUpdated(String email);

  /// No description provided for @adminBranchChangeNote.
  ///
  /// In en, this message translates to:
  /// **'Moving an admin to another branch removes their access to the current one. A branch can have only one admin.'**
  String get adminBranchChangeNote;

  /// No description provided for @editsSyncNote.
  ///
  /// In en, this message translates to:
  /// **'Name changes are copied to every member’s profile automatically.'**
  String get editsSyncNote;

  /// No description provided for @noBranchAssigned.
  ///
  /// In en, this message translates to:
  /// **'Your account is not linked to a branch yet. Ask the super admin to assign your branch.'**
  String get noBranchAssigned;

  /// No description provided for @loadingBranch.
  ///
  /// In en, this message translates to:
  /// **'Loading your branch…'**
  String get loadingBranch;
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
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
