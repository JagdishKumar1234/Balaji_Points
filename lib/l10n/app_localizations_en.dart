// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Balaji Points';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get submit => 'Submit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get loginWithPhone => 'Login with Phone Number';

  @override
  String get enterPhoneNumber => 'Enter your registered phone number';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get enterPhoneHint => 'Enter 10 digit phone number';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get enterOTPCode => 'Enter the 6-digit code sent to';

  @override
  String get didntReceiveOTP => 'Didn\'t receive OTP? ';

  @override
  String get resend => 'Resend';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get invalidPhone => 'Please enter your phone number';

  @override
  String get invalidPhoneLength => 'Phone number must be 10 digits';

  @override
  String get invalidPhoneFormat => 'Phone number must contain only digits';

  @override
  String get invalidOTP => 'Please enter a valid 6-digit OTP';

  @override
  String get selectRole => 'Select Your Role';

  @override
  String get carpenter => 'Carpenter';

  @override
  String get admin => 'Admin';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get createAccount => 'Create Account';

  @override
  String get continueWithPhone => 'Continue with Phone';

  @override
  String get continueWithPin => 'Continue with PIN';

  @override
  String get loginInfo =>
      'Login using your registered phone number. You will receive an OTP to verify.';

  @override
  String get poweredBy => 'Powered by';

  @override
  String get companyName => 'Balaji Points';

  @override
  String get enterPinPageTitle => 'Enter your 4-digit PIN';

  @override
  String get enter4DigitPin => 'Enter your 4-digit PIN';

  @override
  String get pinLabel => 'PIN';

  @override
  String get fourDigitPin => '4-digit PIN';

  @override
  String get login => 'Login';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get newUserSetPin => 'New user? Set PIN';

  @override
  String get invalidPin => 'Invalid PIN';

  @override
  String get createPinTitle => 'Create your 4-digit PIN';

  @override
  String get createPinSubtitle => 'This PIN will be used for login';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameRequired => 'First Name *';

  @override
  String get lastName => 'Last Name';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get savePin => 'Save PIN';

  @override
  String get pinCreatedSuccess => 'PIN created successfully';

  @override
  String get failedToSavePin => 'Failed to save PIN';

  @override
  String get pinsDoNotMatch => 'PIN and Confirm PIN do not match';

  @override
  String get resetPinTitle => 'Reset PIN';

  @override
  String get resetPinSubtitle =>
      'Enter your registered mobile number to reset your PIN.';

  @override
  String get mustBeLoggedInToResetPin =>
      'You must be logged in to reset your PIN. Please login first.';

  @override
  String get canOnlyResetOwnPin =>
      'You can only reset your own PIN. Phone number must match your logged-in account.';

  @override
  String get enterCurrentPin =>
      'Please enter your current PIN to verify ownership.';

  @override
  String get currentPinLabel => 'Current PIN';

  @override
  String get newPinMustBeDifferent =>
      'New PIN must be different from your current PIN.';

  @override
  String get contactAdminForPinReset =>
      'You must be logged in to reset your PIN. If you forgot your PIN, please contact admin for assistance.';

  @override
  String get forgotCurrentPin => 'Forgot your current PIN?';

  @override
  String get forgotPinHelp =>
      'If you don\'t remember your current PIN, please contact our support team for assistance.';

  @override
  String get adminSupportInfo => 'Admin Support';

  @override
  String get callSupport => 'Call Support';

  @override
  String get adminResetPin => 'Reset PIN';

  @override
  String adminResetPinTitle(String carpenterName) {
    return 'Reset PIN for $carpenterName';
  }

  @override
  String get adminResetPinSubtitle =>
      'Enter a new 4-digit PIN for this carpenter.';

  @override
  String adminResetPinConfirm(String carpenterName) {
    return 'Are you sure you want to reset the PIN for $carpenterName?';
  }

  @override
  String adminResetPinSuccess(String carpenterName) {
    return 'PIN reset successfully for $carpenterName';
  }

  @override
  String get adminResetPinFailed => 'Failed to reset PIN. Please try again.';

  @override
  String get adminNotAuthorized =>
      'You are not authorized to perform this action.';

  @override
  String get enterNewPinForCarpenter => 'Enter new 4-digit PIN';

  @override
  String get confirmNewPinForCarpenter => 'Confirm new 4-digit PIN';

  @override
  String get newPinLabel => 'New 4-digit PIN';

  @override
  String get checkNumber => 'Check Number';

  @override
  String get verified => 'Verified';

  @override
  String get pleaseVerifyMobile => 'Please verify mobile number first';

  @override
  String get noAccountFound => 'No account found for this number';

  @override
  String get pinResetSuccess => 'PIN reset successfully. Please login again.';

  @override
  String get failedToResetPin => 'Failed to reset PIN. Try again.';

  @override
  String get enterValidTenDigit => 'Enter valid 10-digit number';

  @override
  String get enter4Digits => 'Enter 4 digits';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get enterValidFirstName => 'Enter valid first name';

  @override
  String get imageError => 'Image error';

  @override
  String get resetPin => 'Reset PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get accountExistsUseReset =>
      'Account already exists. Please use Reset PIN to change your PIN.';

  @override
  String get home => 'Home';

  @override
  String get addPoints => 'Add Points';

  @override
  String get latestOffers => 'Latest Offers';

  @override
  String get goodMorningGreeting => 'Good morning,';

  @override
  String get goodAfternoonGreeting => 'Good afternoon,';

  @override
  String get goodEveningGreeting => 'Good evening,';

  @override
  String get homeBrowseProductsTitle => 'Wood & Plywood';

  @override
  String get homeBrowseProductsSubtitle => 'Premium laminates & surfaces';

  @override
  String get viewAll => 'View all';

  @override
  String get homeStoreBranch => 'E road';

  @override
  String get homeTierSuffix => 'Tier';

  @override
  String get homeRankingsSectionTitle => 'Rankings & daily winner';

  @override
  String get homeRankingsSectionSubtitle =>
      'Leaderboard, your rank, and today’s prize';

  @override
  String get drawerProductsTitle => 'Products';

  @override
  String get drawerProductsSubtitle => 'Browse categories and catalog';

  @override
  String get drawerCart => 'Cart';

  @override
  String get drawerSectionMainNav => 'Main navigation';

  @override
  String get drawerSectionMore => 'More';

  @override
  String get myOrders => 'My orders';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionPreferences => 'Preferences';

  @override
  String get profileSectionSupport => 'Support';

  @override
  String get profileAboutLink => 'About this app';

  @override
  String get routeErrorTitle => 'Page not found';

  @override
  String get routeErrorNotFound =>
      'This link is invalid or the page was removed.';

  @override
  String get routeErrorGoHome => 'Go home';

  @override
  String get routeErrorDetailsLabel => 'Technical details';

  @override
  String get topCarpenters => 'Top 3 Members';

  @override
  String get todaysWinner => 'Today\'s Winner';

  @override
  String get yourPosition => 'Your Position';

  @override
  String rank(int rank) {
    return 'Rank #$rank';
  }

  @override
  String points(int points) {
    return '$points Points';
  }

  @override
  String get noOffersAvailable => 'No offers available at the moment';

  @override
  String get dailySpinWinner => '🎉 Daily Spin Winner';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String won(int points) {
    return 'Won $points points!';
  }

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get profileIncomplete => 'Profile Incomplete';

  @override
  String get completeProfileMessage =>
      'Please complete your profile to start adding bills and earning points';

  @override
  String get completeProfileDetails =>
      'Add your first name, last name, and profile picture to continue';

  @override
  String get completeNow => 'Complete Now';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get role => 'Role';

  @override
  String get memberSince => 'Member Since';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get notVerified => 'Not Verified';

  @override
  String get needHelp => 'Need Help?';

  @override
  String get contactSupport =>
      'Contact our support team for any queries or issues.';

  @override
  String get callNow => 'Call Now';

  @override
  String get getInTouch => 'Get in touch with us';

  @override
  String get mobile => 'Mobile';

  @override
  String get landline => 'Landline';

  @override
  String get addBill => 'Add Bill';

  @override
  String get billDetails => 'Bill Details';

  @override
  String get billNumber => 'Bill Number';

  @override
  String get billAmount => 'Bill Amount (₹)';

  @override
  String get billDate => 'Bill Date';

  @override
  String get uploadBillImage => 'Upload Bill Image';

  @override
  String get selectImage => 'Select Image';

  @override
  String get changeImage => 'Change Image';

  @override
  String get pointsConversion => '1000 ₹ = 1 Point';

  @override
  String get estimatedPoints => 'Estimated Points';

  @override
  String youWillEarn(int points) {
    return 'You will earn approximately $points points';
  }

  @override
  String get enterBillNumber => 'Please enter bill number';

  @override
  String get enterBillAmount => 'Enter bill amount';

  @override
  String get enterValidAmount => 'Please enter a valid amount';

  @override
  String get selectBillDate => 'Please select bill date';

  @override
  String get uploadBillPhoto => 'Please upload bill photo';

  @override
  String get billSubmitted => 'Bill submitted successfully';

  @override
  String get billSubmitError => 'Failed to submit bill';

  @override
  String get wallet => 'Wallet';

  @override
  String get availablePoints => 'Available Points';

  @override
  String get redeemPoints => 'Redeem Points';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get earned => 'Earned';

  @override
  String get spent => 'Spent';

  @override
  String get pending => 'Pending';

  @override
  String get offers => 'Offers';

  @override
  String get viewDetails => 'View Details';

  @override
  String get redeemNow => 'Redeem Now';

  @override
  String pointsRequired(int points) {
    return '$points Points Required';
  }

  @override
  String get offerRedeemed => 'Offer redeemed successfully';

  @override
  String get insufficientPoints => 'Insufficient points';

  @override
  String get offerExpired => 'This offer has expired';

  @override
  String validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get dailySpin => 'Daily Spin';

  @override
  String get spinNow => 'SPIN NOW';

  @override
  String get spinning => 'Spinning...';

  @override
  String get spinWheel => 'Spin the Wheel';

  @override
  String get dailySpinCompleted => 'You have already spun today';

  @override
  String get comeBackTomorrow =>
      'Come back tomorrow for another chance to win!';

  @override
  String nextSpinIn(int hours, int minutes) {
    return 'Next spin in: ${hours}h ${minutes}m';
  }

  @override
  String winner(String name) {
    return 'Winner: $name';
  }

  @override
  String prizePoints(int points) {
    return '🎁 $points Points';
  }

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get adminSubtitle => 'Manage Bills, Offers, Users & Daily Spin';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get users => 'Users';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get manageBills => 'Manage Bills';

  @override
  String get manageOffers => 'Manage Offers';

  @override
  String get manageDailySpin => 'Manage Daily Spin';

  @override
  String get pendingBills => 'Pending Bills';

  @override
  String get approvedBills => 'Approved Bills';

  @override
  String get rejectedBills => 'Rejected Bills';

  @override
  String get pendingUsers => 'Pending Users';

  @override
  String get verifiedUsers => 'Verified Users';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get userApproved => 'User approved successfully';

  @override
  String get userRejected => 'User rejected successfully';

  @override
  String get billApproved => 'Bill approved successfully';

  @override
  String get billRejected => 'Bill rejected successfully';

  @override
  String get createOffer => 'Create Offer';

  @override
  String get offerTitle => 'Offer Title';

  @override
  String get offerDescription => 'Offer Description';

  @override
  String get offerCreated => 'Offer created successfully';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get networkError =>
      'Network error. Please check your internet connection.';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get sessionExpired => 'Session expired. Please login again.';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get userNotFound => 'User not found';

  @override
  String get phoneAuthFailed => 'Phone authentication failed';

  @override
  String get configError => 'Configuration error';

  @override
  String get missingClientId =>
      'SHA-1 fingerprint missing in Firebase. Please run: scripts/get_sha1.sh';

  @override
  String get tooManyRequests => 'Too many requests. Please wait a few minutes.';

  @override
  String get invalidVerificationCode =>
      'Invalid OTP code. Please check and try again.';

  @override
  String get verificationExpired =>
      'Verification expired. Please request a new OTP.';

  @override
  String get userDisabled =>
      'This account has been disabled. Please contact support.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get invalidName => 'Please enter a valid name';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get invalidAmount => 'Please enter a valid amount';

  @override
  String get amountTooLow => 'Amount must be greater than 0';

  @override
  String get searchHint => 'Search...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get releaseToRefresh => 'Release to refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get loadMore => 'Load more';

  @override
  String get seeAll => 'See All';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get approveBill => 'Approve Bill';

  @override
  String approveBillConfirmation(String amount, String phone) {
    return 'Approve bill of ₹$amount for $phone?';
  }

  @override
  String get approvingBill => 'Approving bill...';

  @override
  String get billApprovedSuccess => 'Bill approved!';

  @override
  String get failedToApproveBill => 'Failed to approve bill. Try again.';

  @override
  String get rejectBill => 'Reject Bill';

  @override
  String get rejectBillConfirmation =>
      'Are you sure you want to reject this bill?';

  @override
  String get billRejectedSuccess => 'Bill Rejected';

  @override
  String get failedToRejectBill => 'Failed to reject';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get noImageAvailable => 'No image available';

  @override
  String get errorLoadingBills => 'Error loading bills';

  @override
  String get noPendingBills => 'No Pending Bills';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get noDate => 'No date';

  @override
  String get deleteOffer => 'Delete Offer';

  @override
  String get deleteOfferConfirmation =>
      'Are you sure you want to delete this offer? This action cannot be undone.';

  @override
  String get offerDeletedSuccess => 'Offer deleted successfully';

  @override
  String get failedToDeleteOffer => 'Failed to delete offer';

  @override
  String get errorLoadingOffers => 'Error loading offers';

  @override
  String get noOffersCreated => 'No Offers Created';

  @override
  String get createFirstOffer =>
      'Create your first offer with points and banner';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get createdLabel => 'Created';

  @override
  String get editOffer => 'Edit Offer';

  @override
  String get createNewOffer => 'Create New Offer';

  @override
  String get tapToUploadBanner => 'Tap to upload banner';

  @override
  String get offerTitleLabel => 'Offer Title *';

  @override
  String get offerTitleHint => 'Enter offer title';

  @override
  String get enterOfferTitle => 'Please enter offer title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Enter description';

  @override
  String get pointsRequiredLabel => 'Points Required *';

  @override
  String get pointsHint => 'Enter points';

  @override
  String get enterPointsError => 'Please enter points';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get setValidUntilDate => 'Set valid until date (optional)';

  @override
  String validUntilDisplay(String date) {
    return 'Valid until: $date';
  }

  @override
  String get offerStatus => 'Offer Status';

  @override
  String get uploadingBanner => 'Uploading banner...';

  @override
  String get updateOffer => 'Update Offer';

  @override
  String get offerUpdatedSuccess => 'Offer updated successfully';

  @override
  String get offerCreatedSuccess => 'Offer created successfully';

  @override
  String get failedToSaveOffer => 'Failed to save offer';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get searchByNameOrPhone => 'Search name or phone';

  @override
  String get add => 'Add';

  @override
  String get all => 'All';

  @override
  String get platinum => 'Platinum';

  @override
  String get gold => 'Gold';

  @override
  String get silver => 'Silver';

  @override
  String get bronze => 'Bronze';

  @override
  String get errorLoadingUsers => 'Error loading users';

  @override
  String get noUsersFound => 'No Users Found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get noCarpentersYet => 'No carpenters registered yet';

  @override
  String joinedLabel(String date) {
    return 'Joined $date';
  }

  @override
  String get addCarpenter => 'Add Carpenter';

  @override
  String get deleteCarpenter => 'Delete Carpenter';

  @override
  String get deleteCarpenterConfirmation =>
      'Are you sure you want to delete this carpenter? This will permanently delete:\n\n• User account\n• All points and transaction history\n• All submitted bills\n• All offer redemptions\n\nThis action cannot be undone.';

  @override
  String get deleteCarpenterWarning =>
      'Deleting a carpenter will permanently remove all their data from the system. This action cannot be undone.';

  @override
  String get carpenterDeletedSuccess => 'Carpenter deleted successfully';

  @override
  String get failedToDeleteCarpenter => 'Failed to delete carpenter';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => 'Enter phone number';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get verifyAndCreate => 'Verify & Create';

  @override
  String get adminSignOutNote =>
      'Note: The app will sign in as the verified carpenter temporarily during OTP verification and then sign out. The admin must sign in again.';

  @override
  String get carpenterCreated => 'Carpenter created';

  @override
  String get carpenterCreatedMessage =>
      'Carpenter account created successfully. The app has signed in as that carpenter during verification and has now signed out. You will need to sign in again as admin.';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get phoneAlreadyExists => 'Phone number already exists';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get otpSent => 'OTP sent';

  @override
  String get failedToSignIn => 'Failed to sign in with OTP';

  @override
  String get authError => 'Auth error';

  @override
  String get totalPointsLabel => 'Total Points';

  @override
  String tierLabel(String tier) {
    return '$tier Tier';
  }

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get noWinnerYetToday => 'No winner yet today';

  @override
  String get youWonPrize => '🎉 You Won!';

  @override
  String get todaysWinnerLabel => '🏆 Today\'s Winner';

  @override
  String get myPoints => 'My Points';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get settings => 'Settings';

  @override
  String get rankShort => 'Rank';

  @override
  String get earn => 'Wallet';

  @override
  String get approved => 'Approved';

  @override
  String get addNewBill => 'Add New Bill';

  @override
  String get recentBills => 'Recent Bills';

  @override
  String get noBillsYet => 'No bills yet';

  @override
  String get submitFirstBill => 'Submit your first bill to earn points';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get billLabel => 'Bill';

  @override
  String get statusApproved => 'APPROVED';

  @override
  String get statusPending => 'PENDING';

  @override
  String get statusRejected => 'REJECTED';

  @override
  String get exitApp => 'Exit App?';

  @override
  String get exitAppMessage => 'Do you want to exit the app?';

  @override
  String get exit => 'Exit';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get pleaseWaitForSpin => 'Please wait for spin to complete';

  @override
  String get discardBill => 'Discard Bill?';

  @override
  String get discardBillMessage =>
      'You have unsaved bill data. Do you want to discard it?';

  @override
  String get pleaseCompleteProfile => 'Please complete your profile';

  @override
  String get rewardsLoyaltyProgram => 'Rewards & Loyalty Program';

  @override
  String get billImage => 'Bill Image';

  @override
  String get billDateOptional => 'Bill Date (Optional)';

  @override
  String get storeVendorNameOptional => 'Store/Vendor Name (Optional)';

  @override
  String get billInvoiceNumberOptional => 'Bill/Invoice Number (Optional)';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get tapToAddBillImage => 'Tap to add bill image';

  @override
  String get selectBillDateOptional => 'Select bill date (optional)';

  @override
  String get enterStoreOrVendorNameOptional =>
      'Enter store or vendor name (optional)';

  @override
  String get enterBillOrInvoiceNumberOptional =>
      'Enter bill or invoice number (optional)';

  @override
  String get addAnyAdditionalNotes => 'Add any additional notes...';

  @override
  String get submitBill => 'Submit Bill';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get withdrawBill => 'Withdraw Bill';

  @override
  String get withdrawBillConfirmation =>
      'Are you sure you want to withdraw this approved bill? This will reverse the points awarded to the carpenter.';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get billWithdrawnSuccess =>
      'Bill withdrawn successfully. Points have been reversed.';

  @override
  String get failedToWithdrawBill => 'Failed to withdraw bill';

  @override
  String get withdrawApproval => 'Withdraw Approval';

  @override
  String get reversePointsAndUndoApproval => 'Reverse points & undo approval';

  @override
  String get approveBillAction => 'Approve Bill';

  @override
  String get awardPointsAndMarkAsApproved => 'Award points & mark as approved';

  @override
  String get selectCarpenter => 'Select Carpenter';

  @override
  String get errorLoadingCarpenters => 'Error loading carpenters';

  @override
  String get noCarpentersFound => 'No carpenters found';

  @override
  String get noCarpentersAvailable => 'No carpenters available';

  @override
  String get billHistory => 'Bill History';

  @override
  String get filters => 'Filters';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get searchCarpenter => 'Search carpenter...';

  @override
  String get errorLoadingBillHistory => 'Error loading bills';

  @override
  String get noBillsFoundMatchingFilters => 'No bills found matching filters';

  @override
  String get noBillsFoundHistory => 'No bills found';

  @override
  String get billDateLabel => 'Bill Date';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get approvedLabel => 'Approved';

  @override
  String get rejectedLabel => 'Rejected';

  @override
  String get pts => 'pts';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get aboutUs => 'About Us';

  @override
  String get aboutUsMenuSubtitle => 'Rewards & loyalty for members';

  @override
  String get aboutUsSubtitle => 'Your hardware rewards partner';

  @override
  String get aboutUsOverviewTitle => 'What is Balaji Points?';

  @override
  String get aboutUsOverviewBody =>
      'Balaji Points is a digital loyalty platform for carpenters and hardware stores. It helps you turn eligible material purchases into points, rewards, and recognition. You use the app to submit bills; the hardware store you are enrolled with reviews and approves them; your wallet and history update automatically so you always know where you stand.';

  @override
  String get aboutUsEarningTitle => 'How you earn points';

  @override
  String get aboutUsEarningBody =>
      'Upload purchase bills with clear photos, correct amounts, and any details your store asks for. Store admins review submissions to keep the program fair and prevent errors or misuse. After approval, points are credited using that store’s rules (for example, how rupees convert to points). You can track your balance, transaction history, and tier progress anytime in the app.';

  @override
  String get aboutUsOffersTitle => 'Leaderboards, offers, and updates';

  @override
  String get aboutUsOffersBody =>
      'Many stores run a leaderboard so you can see how you rank among carpenters in their program. You will also see offers, banners, and announcements—seasonal deals, bonus point events, or special promotions—so you do not miss opportunities that your store enables for you.';

  @override
  String get aboutUsFairnessTitle => 'Approvals, transparency, and support';

  @override
  String get aboutUsFairnessBody =>
      'Reviews can take a short time because each bill is checked carefully. If something is rejected, you should see a reason or get guidance from your store’s team. For login, PIN, profile, or notification issues, use the options inside the app and contact your store when needed. We focus on clear rules and visible status for pending, approved, and rejected bills.';

  @override
  String get aboutUsStoresTitle => 'Your store, your program';

  @override
  String get aboutUsStoresBody =>
      'Points, tiers, and offers are tied to the hardware store you joined in this app. Different stores may use different rules, conversion rates, and benefits. If you buy from more than one participating store, each relationship is usually separate unless the stores tell you otherwise—always confirm details with the store that enrolled you.';

  @override
  String get aboutUsClosing =>
      'Thank you for using Balaji Points—we are proud to support carpenters and the stores that partner with you.';

  @override
  String get aboutUsCreditsHeading => 'Designed and developed by';

  @override
  String get aboutUsCreditsStudio => 'Aaiji Tech Studio — Vadodara, Gujarat';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingSlide1Title => 'Submit bills, earn points';

  @override
  String get onboardingSlide1Body =>
      'Upload your hardware purchase bills. When your store approves them, points are added to your wallet.';

  @override
  String get onboardingSlide2Title => 'Track your rewards';

  @override
  String get onboardingSlide2Body =>
      'See your balance, tier, and leaderboard rank. Browse offers made for carpenters like you.';

  @override
  String get onboardingSlide3Title => 'Stay in the loop';

  @override
  String get onboardingSlide3Body =>
      'Get notified when bills are approved or rejected. Manage your profile and preferences anytime.';

  @override
  String errorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get siteNameRequired => 'Site name is required';

  @override
  String get billDateFuture => 'Bill date cannot be in the future';

  @override
  String get duplicateBillDetected => 'Duplicate bill detected';

  @override
  String get duplicateBillIntro =>
      'A bill with the same site, amount and date already exists:';

  @override
  String get siteNameLabel => 'Site name';

  @override
  String get amountLabel => 'Amount';

  @override
  String get pointsLabel => 'Points';

  @override
  String get dateLabel => 'Date';

  @override
  String ptsValue(String points) {
    return '$points pts';
  }

  @override
  String get duplicateBillVerify =>
      'This might be a duplicate entry. Please check before adding.';

  @override
  String get addBillAnywayQuestion => 'Do you want to add this bill anyway?';

  @override
  String get addAnyway => 'Add anyway';

  @override
  String get billsPausedDiwali =>
      'Bill submissions are paused for the Diwali celebration.';

  @override
  String earnPointsWhenApproved(String points) {
    return 'You will earn $points points when approved';
  }

  @override
  String get vendorNameLabel => 'Vendor name';

  @override
  String get menu => 'Menu';

  @override
  String get hintPassword => 'Enter password';

  @override
  String get hintPasswordMin => 'Enter password';

  @override
  String get hintConfirmPassword => 'Re-enter password';

  @override
  String get hintFullName => 'Enter full name';

  @override
  String get hintAmount => 'Enter amount';

  @override
  String get hintBranchFullName => 'Enter branch name';

  @override
  String get hintShortName => 'Enter short name';

  @override
  String get hintBranchCode => 'Enter branch code';

  @override
  String get hintAddress => 'Enter address';

  @override
  String get hintRoleName => 'Enter role name';

  @override
  String get hintEmail => 'Enter email';

  @override
  String get hintPhone => 'Enter phone number';

  @override
  String get hintPin => 'Enter PIN';

  @override
  String get hintConfirmPin => 'Re-enter PIN';

  @override
  String get hintBranchId => 'Enter branch ID';

  @override
  String get diwaliYourPrize => 'Your Diwali prize';

  @override
  String get diwaliYou => 'You';

  @override
  String get diwaliPosition => 'Position';

  @override
  String get navAddBill => 'Add Bill';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String get diwaliPrizeLoadFailed =>
      'Could not load the Diwali prize list. Please try again.';

  @override
  String get featureEarnMore => 'EARN MORE';

  @override
  String get featureEarnBody => 'Upload Bills\nEarn Points';

  @override
  String get featureRedeemMore => 'REDEEM MORE';

  @override
  String get featureRedeemBody => 'Exciting Rewards\n& Gifts';

  @override
  String get featureGrowMore => 'GROW MORE';

  @override
  String get featureGrowBody => 'Climb Leaderboard\nBe a Top Member';

  @override
  String get featureExclusive => 'EXCLUSIVE';

  @override
  String get featureExclusiveBody => 'Special Benefits\nJust for You';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String ptsToNextLabel(String points, String tier) {
    return '$points pts to $tier';
  }

  @override
  String get platinumHighestTier => 'Platinum — highest tier!';

  @override
  String get topCarpentersTitle => 'Top members';

  @override
  String get noRankingYet => 'No ranking data yet';

  @override
  String get noWinnerToday => 'No winner today';

  @override
  String spinNotDoneYet(String date) {
    return 'Spin not done yet · $date';
  }

  @override
  String get todaysLuckyWinner => 'Today\'s lucky winner';

  @override
  String selectedViaDailySpin(String date) {
    return 'Selected via daily spin · $date';
  }

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get deleteAllNotifications => 'Delete all notifications';

  @override
  String get deleteAllNotificationsConfirm =>
      'Are you sure you want to delete all notifications? This cannot be undone.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String notificationsDeleted(String count) {
    return '$count notifications deleted';
  }

  @override
  String get unableToLoadNotifications => 'Unable to load notifications';

  @override
  String get errorLoadingNotifications => 'Error loading notifications';

  @override
  String get noNotificationsTitle => 'No notifications';

  @override
  String get noNotificationsYet => 'You don\'t have any notifications yet';

  @override
  String get deleteNotification => 'Delete notification';

  @override
  String get deleteNotificationConfirm =>
      'Are you sure you want to delete this notification?';

  @override
  String get addProfilePhoto => 'Please add a profile photo';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get tapToChangePhoto => 'Tap to change photo';

  @override
  String get lastNameRequired => 'Last Name *';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get completeProfileToContinue =>
      'You need to complete your profile to continue';

  @override
  String get couldNotMakeCall => 'Could not make call';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get youWonLabel => 'You won';

  @override
  String pointsWon(String points) {
    return '$points points!';
  }

  @override
  String get pointsAddedToAccount => 'Points have been added to your account.';

  @override
  String get great => 'Great!';

  @override
  String get spinAndWin => 'Spin & win points!';

  @override
  String get spinAndWinSubtitle =>
      'Get your daily spin and win exciting points';

  @override
  String get alreadySpunToday =>
      'You\'ve already spun today!\nCome back tomorrow for another chance.';

  @override
  String nextTierLabel(String tier) {
    return 'Next tier: $tier';
  }

  @override
  String ptsToNextTier(String points) {
    return '$points pts to next tier';
  }

  @override
  String get platinumMaxLevel => 'Platinum tier — maximum level';

  @override
  String get filterLabel => 'Filter';

  @override
  String get totalApprovedPoints => 'Total approved points';

  @override
  String billsCount(String count) {
    return '$count bills';
  }

  @override
  String get billAttachment => 'Bill attachment';

  @override
  String get pendingApproval => 'Pending approval';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get noPinAccount =>
      'No PIN account was found for this number. Sign in with email and password or Google.';

  @override
  String get signInWithMobile => 'Sign in with mobile number';

  @override
  String get continueToPin => 'Continue to PIN';

  @override
  String get backToOtherSignIn => 'Back to other sign-in options';

  @override
  String get branchHasAdminDefaulted =>
      'Selected branch already has an Admin. Role set to Carpenter.';

  @override
  String get selectBranchToContinue => 'Please select a branch to continue.';

  @override
  String get oneAdminPerBranch =>
      'This branch already has an Admin. Only one Admin is allowed per branch.';

  @override
  String get branchRequired => 'Branch *';

  @override
  String get selectYourBranch => 'Select your branch';

  @override
  String get userRoleRequired => 'User role *';

  @override
  String get roleCarpenterWoodworker => 'Carpenter / Woodworker';

  @override
  String get roleArchitect => 'Architect';

  @override
  String get roleInteriorDesigner => 'Interior designer';

  @override
  String get fullName => 'Full name';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get noActiveRoles =>
      'No active roles are available. Contact the Super Admin.';

  @override
  String get noActiveBranches =>
      'No active branches are available. Contact your administrator.';

  @override
  String get cancelReturnToSignIn => 'Cancel and return to sign in';

  @override
  String get selectRoleRequired => 'Select role *';

  @override
  String get previousPage => 'Previous';

  @override
  String tablePageInfo(
    String page,
    String pages,
    String from,
    String to,
    String total,
  ) {
    return 'Page $page of $pages · $from–$to of $total';
  }

  @override
  String get noRows => 'No rows';

  @override
  String get updateNow => 'Update now';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get requiredLabel => 'Required';

  @override
  String get installedLabel => 'Installed';

  @override
  String get updateMandatory =>
      'This update is required to keep using the app.';

  @override
  String get signOut => 'Sign out';

  @override
  String get billsAppearHere => 'Bills you submit will appear here.';

  @override
  String get pendingBillsAppearHere =>
      'New bills from carpenters will appear here for approval.';

  @override
  String get tryChangingFilters => 'Try changing or clearing the filters.';

  @override
  String get carpentersAppearHere => 'Registered carpenters will appear here.';

  @override
  String get statCarpenters => 'Carpenters';

  @override
  String get statPendingBills => 'Pending bills';

  @override
  String get statAwaitingReview => 'Awaiting review';

  @override
  String get statBillsThisMonth => 'Bills this month';

  @override
  String statApprovedThisMonth(String count) {
    return '$count approved';
  }

  @override
  String get statPointsIssued => 'Points issued';

  @override
  String get statThisMonth => 'This month';

  @override
  String get statRegistered => 'Registered';

  @override
  String version(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get switchToLight => 'Switch to Light';

  @override
  String get switchToDark => 'Switch to Dark';

  @override
  String get max => 'Max';

  @override
  String get status => 'Status';

  @override
  String to2(String nextLabel) {
    return 'To $nextLabel';
  }

  @override
  String get spinNow2 => 'Spin Now!';

  @override
  String get pleaseCompleteYourProfileFirstName =>
      'Please complete your profile (first name, last name, and profile picture) to add bills and earn points.';

  @override
  String get goBack => 'Go Back';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get pleaseLoginToSubmitBills => 'Please login to submit bills';

  @override
  String get billSubmittedSuccessfullyAdminWillReview =>
      'Bill submitted successfully! Admin will review it.';

  @override
  String get failedToSubmitBillPleaseTry =>
      'Failed to submit bill. Please try again.';

  @override
  String get pleaseEnterBillAmount => 'Please enter bill amount';

  @override
  String get billDate2 => 'Bill Date *';

  @override
  String get selectBillDate2 => 'Select bill date';

  @override
  String get siteName => 'Site Name *';

  @override
  String get enterSiteLocationName => 'Enter site name';

  @override
  String get vendorNameOptional => 'Vendor Name (Optional)';

  @override
  String get enterVendorStoreNameOptional => 'Enter vendor name';

  @override
  String get noUserLoggedIn => 'No user logged in';

  @override
  String get firstNameMustBeAtLeast =>
      'First name must be at least 2 characters';

  @override
  String get firstNameIsTooLongMax =>
      'First name is too long (max 50 characters)';

  @override
  String get lastNameMustBeAtLeast => 'Last name must be at least 2 characters';

  @override
  String get lastNameIsTooLongMax =>
      'Last name is too long (max 50 characters)';

  @override
  String get failedToUploadProfileImage => 'Failed to upload profile image';

  @override
  String failedToUploadProfileImage2(String e) {
    return 'Failed to upload profile image: $e';
  }

  @override
  String get enterYourFirstName => 'Enter first name';

  @override
  String get pleaseEnterYourFirstName => 'Please enter your first name';

  @override
  String get enterYourLastName => 'Enter last name';

  @override
  String get pleaseEnterYourLastName => 'Please enter your last name';

  @override
  String get user => 'User';

  @override
  String get language => 'Language';

  @override
  String get trackYourPointsAndManageYour =>
      'Track your points and manage your bills';

  @override
  String mAgo(String inMinutes) {
    return '${inMinutes}m ago';
  }

  @override
  String hAgo(String inHours) {
    return '${inHours}h ago';
  }

  @override
  String dAgo(String inDays) {
    return '${inDays}d ago';
  }

  @override
  String get notification => 'Notification';

  @override
  String get noCarpenterAccountsAreListedFor =>
      'No member accounts are listed for this branch yet.';

  @override
  String get continueToHome => 'Continue to Home';

  @override
  String get shubhDeepawali => 'Shubh Deepawali!';

  @override
  String carpenters(String branchName, String carpenterCount) {
    return '$branchName  ·  $carpenterCount carpenters';
  }

  @override
  String carpenterRewardBonusReport(String dateFormat) {
    return 'CARPENTER REWARD & BONUS REPORT  ·  $dateFormat';
  }

  @override
  String get closeCelebration => 'Close celebration';

  @override
  String get deepawaliPrizeNight => '✦  DEEPAWALI PRIZE NIGHT  ✦';

  @override
  String get topPerformersGoldTier => 'Top Performers - Gold Tier';

  @override
  String get ranks110 => 'Ranks 1-10';

  @override
  String get highPerformersSilverTier => 'High Performers - Silver Tier';

  @override
  String get ranks1130 => 'Ranks 11-30';

  @override
  String get activePerformersBronzeTier => 'Active Performers - Bronze Tier';

  @override
  String get ranks31Onwards => 'Ranks 31 onwards';

  @override
  String totalCarpenters(String entries) {
    return 'Total carpenters: $entries';
  }

  @override
  String get totalPoints2 => 'Total points';

  @override
  String get totalReward => 'Total reward';

  @override
  String get totalBonus => 'Total bonus';

  @override
  String carpentersPointsRewardBonus(
    String entries,
    String totalPoints,
    String totalReward,
    String totalBonus,
  ) {
    return '$entries carpenters  ·  $totalPoints points  ·  $totalReward reward  ·  $totalBonus bonus';
  }

  @override
  String bonus(String bonusAmount, String giftDetails) {
    return '$bonusAmount bonus  ·  $giftDetails';
  }

  @override
  String get mobileNumberUnavailable => 'Mobile number unavailable';

  @override
  String get reward => 'Reward';

  @override
  String get bonus2 => 'Bonus';

  @override
  String get nil => 'Nil';

  @override
  String get gift => 'Gift';

  @override
  String get reward2 => 'Reward ₹';

  @override
  String get bonus3 => 'Bonus ₹';

  @override
  String get giftDetails => 'Gift details';

  @override
  String get remarks => 'Remarks';

  @override
  String get verifyYourIdentityToOpenBalaji =>
      'Verify your identity to open Balaji Points';

  @override
  String get passwordResetLinksAreSentSecurely =>
      'Password reset links are sent securely by Firebase.';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get ifAnAccountExistsForThis =>
      'If an account exists for this address, Firebase has sent password reset instructions. Check your inbox and spam folder.';

  @override
  String get enterTheEmailAddressLinkedTo =>
      'Enter the email address linked to your account. We’ll send you a secure link to choose a new password.';

  @override
  String get enterAValidEmailAddress => 'Enter a valid email address';

  @override
  String get sendAnotherResetLink => 'Send another reset link';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get welcomeBack2 => 'Welcome back';

  @override
  String signInToContinueTo(String appName) {
    return 'Sign in to continue to $appName';
  }

  @override
  String get signIn => 'Sign in';

  @override
  String get useYourEmailAndPasswordOr =>
      'Use your email and password, or sign in with your PIN.';

  @override
  String get pleaseEnterAValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get passwordMustBeAtLeast6 => 'Password must be at least 6 characters';

  @override
  String get loginWithPin => 'Login with PIN';

  @override
  String get newToBalajiPoints => 'New to Balaji Points? ';

  @override
  String get createAccount2 => 'Create account';

  @override
  String designedAndDevelopedBy(String companyName) {
    return 'Designed and developed by $companyName';
  }

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get hindi => 'Hindi';

  @override
  String get tamil => 'Tamil';

  @override
  String get forCurrentMobilePinAccounts => 'For current mobile + PIN accounts';

  @override
  String get enterAValid10DigitMobile => 'Enter a valid 10-digit mobile number';

  @override
  String get yourDataIs100SecureWith => 'Your data is 100% secure with us';

  @override
  String get userAlreadyExists => 'User already exists';

  @override
  String get permissionDeniedPleaseCheckFirebaseConfiguration =>
      'Permission denied. Please check Firebase configuration.';

  @override
  String get branchAdminAlreadyAssigned => 'Branch Admin (Already Assigned)';

  @override
  String get branchAdmin1PerBranch => 'Branch Admin (1 per branch)';

  @override
  String get selectABranchToContinue => 'Select a branch to continue.';

  @override
  String get selectARoleToContinue => 'Select a role to continue.';

  @override
  String get selectAnActiveRoleToContinue =>
      'Select an active role to continue.';

  @override
  String get yourInformationIsProtected => 'Your information is protected';

  @override
  String get completeYourGoogleRegistration =>
      'Complete your Google registration';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get addYourMobileNumberAndChoose =>
      'Add your mobile number and choose your branch and role to finish setting up your account.';

  @override
  String get chooseYourRoleAndTheBranch =>
      'Choose your role and the branch you belong to.';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get showPassword => 'Show password';

  @override
  String get useAtLeast6Characters => 'Use at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get yourAccountAlreadyHasAnAdmin =>
      'Your account already has an Admin role. Ask the Super Admin to assign your branch before continuing.';

  @override
  String get branchAdminAccessIsAssignedBy =>
      'Branch Admin access is assigned by a Super Admin.';

  @override
  String get completeRegistration => 'Complete registration';

  @override
  String get loadingRoles => 'Loading roles…';

  @override
  String get chooseOneRole => 'Choose one role';

  @override
  String get selectARoleToContinue2 => 'Select a role to continue';

  @override
  String get loadingBranches => 'Loading branches…';

  @override
  String get selectABranch => 'Select a branch';

  @override
  String cannotMakePhoneCallTo(String phoneNumber) {
    return 'Cannot make phone call to $phoneNumber';
  }

  @override
  String errorMakingPhoneCall(String e) {
    return 'Error making phone call: $e';
  }

  @override
  String get member => 'Member';

  @override
  String get updateRequired => 'Update required';

  @override
  String get newVersionAvailable => 'New version available';

  @override
  String get latest => 'Latest';

  @override
  String get completed => 'Completed';

  @override
  String get processing => 'Processing';

  @override
  String installLatestToContinue(String appName) {
    return 'Please install the latest version of $appName to continue.';
  }

  @override
  String get newerVersionReady =>
      'A newer version is ready with improvements and fixes.';

  @override
  String get pleaseSelectACarpenter => 'Please select a carpenter';

  @override
  String get billSubmittedSuccessfullyItWillBe =>
      'Bill submitted successfully! It will be reviewed.';

  @override
  String get duplicateBill => 'Duplicate Bill';

  @override
  String get aBillWithTheSameSite =>
      'A bill with the SAME site, amount, and date already exists for this carpenter:';

  @override
  String get site => 'Site';

  @override
  String pts2(String duplicatePoints) {
    return '$duplicatePoints pts';
  }

  @override
  String get pleaseVerifyThisIsNotA =>
      'Please verify this is not a duplicate entry.';

  @override
  String error2(String e) {
    return 'Error: $e';
  }

  @override
  String get addAnyway2 => 'Add Anyway';

  @override
  String get addBillForCarpenter => 'Add Bill for Carpenter';

  @override
  String get carpenter2 => 'Carpenter *';

  @override
  String get billAmount2 => 'Bill Amount (₹) *';

  @override
  String get billImageOptional => 'Bill Image (Optional)';

  @override
  String get siteName2 => 'Site Name';

  @override
  String get vendorName => 'Vendor Name';

  @override
  String get pendingApproval2 => 'PENDING APPROVAL';

  @override
  String areYouSureYouWantTo(String billData) {
    return 'Are you sure you want to approve this bill?\n\n₹$billData will be processed.';
  }

  @override
  String get billRejected2 => 'Bill rejected';

  @override
  String get share => 'Share';

  @override
  String get billNotFound => 'Bill not found';

  @override
  String get billId => 'Bill ID';

  @override
  String submitted(String createdAt) {
    return 'Submitted $createdAt';
  }

  @override
  String get submittedOn => 'Submitted On';

  @override
  String get store => 'Store';

  @override
  String get carpenterInfo => 'Carpenter Info';

  @override
  String get viewProfile => 'View Profile';

  @override
  String pts3(String totalPoints) {
    return '$totalPoints pts';
  }

  @override
  String get billSummary => 'Bill Summary';

  @override
  String get billAmount3 => 'Bill Amount';

  @override
  String get pointsToCredit => 'Points to Credit';

  @override
  String get billNo => 'Bill No.';

  @override
  String get pointsRate => 'Points Rate';

  @override
  String get t1Pt1000 => '1 pt / ₹1000';

  @override
  String get billType => 'Bill Type';

  @override
  String get purchase => 'Purchase';

  @override
  String get billAttachment2 => 'Bill Attachment';

  @override
  String get viewFullSize => 'View Full Size';

  @override
  String get downloadImage => 'Download Image';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get timeline => 'Timeline';

  @override
  String get billCreated => 'Bill Created';

  @override
  String get waitingForApproval => 'Waiting for Approval';

  @override
  String get pendingActionFromAdmin => 'Pending action from admin';

  @override
  String get justNow2 => 'just now';

  @override
  String minAgo(String inMinutes) {
    return '$inMinutes min ago';
  }

  @override
  String billDetails2(String billId) {
    return 'Bill Details - $billId';
  }

  @override
  String get errorLoadingBillDetails => 'Error loading bill details';

  @override
  String get noBillFound => 'No bill found';

  @override
  String get totalInstances => 'Total Instances';

  @override
  String get billEntries => 'Bill Entries';

  @override
  String instance(String index) {
    return 'Instance $index';
  }

  @override
  String get time => 'Time';

  @override
  String get noBillsToExportApplyFilters =>
      'No bills to export. Apply filters or wait for data.';

  @override
  String get preparingPdf => 'Preparing PDF...';

  @override
  String get noBillsMatchCurrentFiltersFor =>
      'No bills match current filters for export.';

  @override
  String exportFailed(String e) {
    return 'Export failed: $e';
  }

  @override
  String get bill => 'Bill #';

  @override
  String get approvedDate => 'Approved Date';

  @override
  String get actions => 'Actions';

  @override
  String get exportAllBillsToPdf => 'Export all bills to PDF';

  @override
  String approveThisBillOfPointsWill(String amount, String amount2) {
    return 'Approve this bill of ₹$amount?\n\n$amount2 points will be added to the member.';
  }

  @override
  String get billApprovedAndPointsAddedSuccessfully =>
      'Bill approved and points added successfully';

  @override
  String get failedToApproveBill2 => 'Failed to approve bill';

  @override
  String errorApprovingBill(String e) {
    return 'Error approving bill: $e';
  }

  @override
  String get failedToRejectBill2 => 'Failed to reject bill';

  @override
  String errorRejectingBill(String e) {
    return 'Error rejecting bill: $e';
  }

  @override
  String get dateFilters => 'Date Filters';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String pts4(String amount) {
    return '$amount pts';
  }

  @override
  String get noHistoryAvailable => 'No history available';

  @override
  String get carpenterSummary => 'Carpenter Summary';

  @override
  String totalPts(String totalPoints) {
    return 'Total: $totalPoints pts';
  }

  @override
  String get totalBills => 'Total Bills';

  @override
  String get pointsBySite => 'Points by Site';

  @override
  String pts5(String num) {
    return '$num pts';
  }

  @override
  String get site2 => 'Site: ';

  @override
  String get billDate3 => 'Bill Date: ';

  @override
  String get approved2 => 'Approved: ';

  @override
  String get submitted2 => 'Submitted: ';

  @override
  String get allBillsHistory => 'All Bills History';

  @override
  String bills(String filtered, String billsList) {
    return '$filtered/$billsList bills';
  }

  @override
  String get filterBySite => 'Filter by Site';

  @override
  String get allSites => 'All Sites';

  @override
  String billId2(String index, String billNum) {
    return '#$index - Bill ID: $billNum';
  }

  @override
  String pts6(String pts) {
    return '$pts pts';
  }

  @override
  String get transactions => 'Transactions';

  @override
  String get rewards => 'Rewards';

  @override
  String get deleteAllNotifications2 => 'Delete All Notifications';

  @override
  String get areYouSureYouWantTo2 =>
      'Are you sure you want to delete all admin notifications?';

  @override
  String notificationSDeleted(String docs) {
    return '$docs notification(s) deleted';
  }

  @override
  String deleteFailed(String e) {
    return 'Delete failed: $e';
  }

  @override
  String get balajiPointsAdminPanel => 'Balaji Points - Admin Panel';

  @override
  String get branchAdmin => 'Branch admin';

  @override
  String get spin => 'Spin';

  @override
  String get pointsRepair => 'Points Repair';

  @override
  String get duplicateAccounts => 'Duplicate Accounts';

  @override
  String get exportUsers => 'Export Users';

  @override
  String get cleanUp => 'Clean Up';

  @override
  String get backupDatabase => 'Backup Database';

  @override
  String get checkFirebaseDuplicates => 'Check Firebase Duplicates';

  @override
  String get smartCleanup => 'Smart Cleanup';

  @override
  String get sendGreeting => 'Send Greeting';

  @override
  String get users2 => 'Users - ...';

  @override
  String users3(String count) {
    return 'Users - $count';
  }

  @override
  String get pleaseEnterPinInBothFields => 'Please enter PIN in both fields';

  @override
  String get pinMustBe46Digits => 'PIN must be 4-6 digits';

  @override
  String get pinMustContainOnlyNumbers => 'PIN must contain only numbers';

  @override
  String get pinResetSuccessfully => 'PIN reset successfully';

  @override
  String errorResettingPin(String e) {
    return 'Error resetting PIN: $e';
  }

  @override
  String resetPinFor(String carpenterName) {
    return 'Reset PIN for: $carpenterName';
  }

  @override
  String phone2(String carpenterPhone) {
    return 'Phone: $carpenterPhone';
  }

  @override
  String get carpenterWillNeedToUseThis =>
      'Carpenter will need to use this new PIN to login. Make sure to communicate it securely.';

  @override
  String get newPin46Digits => 'New PIN (4-6 digits)';

  @override
  String get carpenterDetails => 'Carpenter Details';

  @override
  String get carpenterNotFound => 'Carpenter not found';

  @override
  String get carpenterInformation => 'Carpenter Information';

  @override
  String get branch => 'Branch';

  @override
  String get completeHistory => 'Complete History';

  @override
  String get clearAll => 'Clear All';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get editCarpenter => 'Edit Carpenter';

  @override
  String get changingPhoneNumberWillUpdateLogin =>
      'Changing phone number will update login credentials';

  @override
  String get branchId => 'Branch ID';

  @override
  String get phoneNumberCannotBeEmpty => 'Phone number cannot be empty';

  @override
  String get carpenterUpdatedSuccessfully => 'Carpenter updated successfully';

  @override
  String errorUpdatingCarpenter(String e) {
    return 'Error updating carpenter: $e';
  }

  @override
  String get update => 'Update';

  @override
  String get pendingBillRequests => 'Pending Bill Requests';

  @override
  String get siteMaterialPurchase => 'Site Material Purchase';

  @override
  String billNo2(String billNumber) {
    return 'Bill No. $billNumber';
  }

  @override
  String site3(String siteName) {
    return 'Site: $siteName';
  }

  @override
  String pts7(String amount) {
    return '+$amount pts';
  }

  @override
  String approveThisBillOfPointsWill2(String amount, String amount2) {
    return 'Approve this bill of ₹$amount?\n\n$amount2 points will be added.';
  }

  @override
  String get noHistoryFound => 'No history found';

  @override
  String get pointsAwarded => 'Points awarded';

  @override
  String get pinMustBeAtLeast4 => 'PIN must be at least 4 digits';

  @override
  String get carpenterCreatedSuccessfully => 'Carpenter created successfully!';

  @override
  String get failedToCreateCarpenter => 'Failed to create carpenter';

  @override
  String get pin46Digits => '4-digit PIN';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get firstNameOptional => 'First Name (Optional)';

  @override
  String get enterFirstName => 'Enter first name';

  @override
  String get lastNameOptional => 'Last Name (Optional)';

  @override
  String get enterLastName => 'Enter last name';

  @override
  String get create => 'Create';

  @override
  String get preparingCarpenterListPdf => 'Preparing carpenter list PDF...';

  @override
  String get noCarpentersToExportForCurrent =>
      'No carpenters to export for current filters.';

  @override
  String get carpenterListExportedSuccessfully =>
      'Carpenter list exported successfully!';

  @override
  String errorExportingPdf(String e) {
    return 'Error exporting PDF: $e';
  }

  @override
  String get exportCarpenterListToPdf => 'Export carpenter list to PDF';

  @override
  String get sortByPoints => 'Sort by Points';

  @override
  String get sortByName => 'Sort by Name';

  @override
  String get recentJoins => 'Recent Joins';

  @override
  String tier(String tier) {
    return 'Tier: $tier';
  }

  @override
  String phoneTierPoints(String phone, String tier, String totalPoints) {
    return 'Phone: $phone\nTier: $tier\nPoints: $totalPoints';
  }

  @override
  String points2(String num) {
    return '$num Points';
  }

  @override
  String get deleteAll2 => 'Delete All';

  @override
  String get unableToLoadAdminNotifications =>
      'Unable to load admin notifications';

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get youDonTHaveAnyAdmin =>
      'You don\'t have any admin notifications yet';

  @override
  String get deleteNotification2 => 'Delete Notification';

  @override
  String get dailySpinHistory => 'Daily Spin History';

  @override
  String text(String month, String year) {
    return '$month $year';
  }

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get spinned => 'Spinned';

  @override
  String get noSpin => 'No Spin';

  @override
  String get unknown => 'Unknown';

  @override
  String get spinWinner => 'Spin Winner';

  @override
  String get winnerName => 'Winner Name';

  @override
  String failedToFetchCarpenters(String e) {
    return 'Failed to fetch carpenters: $e';
  }

  @override
  String failedToPickImage2(String e) {
    return 'Failed to pick image: $e';
  }

  @override
  String failedToCaptureImage(String e) {
    return 'Failed to capture image: $e';
  }

  @override
  String failedToUploadImage(String e) {
    return 'Failed to upload image: $e';
  }

  @override
  String notificationSentToCarpenters(String notificationCount) {
    return 'Notification sent to $notificationCount carpenters';
  }

  @override
  String failedToSendNotifications(String e) {
    return 'Failed to send notifications: $e';
  }

  @override
  String get pleaseEnterAMessage => 'Please enter a message';

  @override
  String get pleaseSelectAtLeastOneChannel =>
      'Please select at least one channel';

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get showInApp => 'Show in App';

  @override
  String get greetingSentSuccessfully => 'Greeting sent successfully!';

  @override
  String get sendingGreeting => 'Sending greeting...';

  @override
  String get composeMessage => 'Compose Message';

  @override
  String get enterGreetingMessageForAllCarpenters => 'Enter greeting';

  @override
  String get imageOptional => 'Image (Optional)';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get orEnterImageUrl => 'Or enter image URL:';

  @override
  String get enterImageUrlJpgPng => 'Enter image URL';

  @override
  String get invalidImageUrl => 'Invalid image URL';

  @override
  String get selectChannels => 'Select Channels';

  @override
  String get showInAppHomeBanner => 'Show in App (Home Banner)';

  @override
  String get bannerOnCarpenterHomeScreen => 'Banner on carpenter home screen';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get manualSendViaWhatsappApp => 'Manual send via WhatsApp app';

  @override
  String get manualSendViaSmsApp => 'Manual send via SMS app';

  @override
  String get noteWhatsappAndSmsUseDevice =>
      'Note: WhatsApp and SMS use device-assisted flow. Admin must confirm each message in the native app.';

  @override
  String whatsappNotAvailableFor(String name) {
    return 'WhatsApp not available for $name';
  }

  @override
  String smsNotAvailableFor(String name) {
    return 'SMS not available for $name';
  }

  @override
  String get sendToAll => 'Send to All?';

  @override
  String get continueLabel => 'Continue';

  @override
  String progress(String i, String carpenters) {
    return 'Progress: $i/$carpenters';
  }

  @override
  String opened(String name, String phone) {
    return 'Opened: $name\n$phone';
  }

  @override
  String get tapSendInTheAppThen =>
      'Tap Send in the app, then tap OK here to continue.';

  @override
  String sentToAllCarpenters(String sentCount) {
    return 'Sent to all $sentCount carpenters';
  }

  @override
  String get confirmSend => 'Confirm Send';

  @override
  String get sendAll => 'Send All';

  @override
  String get sendViaWhatsapp => 'Send via WhatsApp';

  @override
  String get sendViaSms => 'Send via SMS';

  @override
  String get pleaseWait24HoursFromThe =>
      'Please wait 24 hours from the last spin';

  @override
  String get noCarpentersWithApprovedBillsToday =>
      'No carpenters with approved bills today';

  @override
  String get noEligibleCarpentersFound => 'No eligible carpenters found';

  @override
  String isTodaySWinner(String carpenterName) {
    return '$carpenterName is today\'s winner!';
  }

  @override
  String get selectALuckyWinner => 'Select a lucky winner';

  @override
  String get viewSpinHistory => 'View Spin History';

  @override
  String winner2(String winnerName) {
    return 'Winner: $winnerName';
  }

  @override
  String get noPreviousSpins => 'No previous spins';

  @override
  String get readyToSpin => 'Ready to spin!';

  @override
  String nextSpinInHM(String hoursRemaining, String minutesRemaining) {
    return 'Next spin in: ${hoursRemaining}h ${minutesRemaining}m';
  }

  @override
  String get todaySWinners => 'Today\'s Winners';

  @override
  String get noWinnersYetToday => 'No winners yet today';

  @override
  String get monthlyWinners => 'Monthly Winners';

  @override
  String get fullHistory => 'Full History';

  @override
  String get noWinnersThisMonthYet => 'No winners this month yet';

  @override
  String get untitled => 'Untitled';

  @override
  String get pleaseEnterAValidNumberFor =>
      'Please enter a valid number for points';

  @override
  String get pleaseUploadABannerImage => 'Please upload a banner image';

  @override
  String get failedToUploadBannerImage => 'Failed to upload banner image';

  @override
  String get loadingEligibleCarpenters => 'Loading eligible carpenters...';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get noEligibleCarpentersToday => 'No Eligible Carpenters Today';

  @override
  String get noCarpentersHaveApprovedBillsToday =>
      'No carpenters have approved bills today.\nApprove bills to make them eligible for the daily spin!';

  @override
  String get todaySEligibleCarpenters => 'Today\'s Eligible Carpenters';

  @override
  String eligible(String todayStr, String carpenters) {
    return '$todayStr • $carpenters eligible';
  }

  @override
  String get branchAdminAccounts => 'Branch admin accounts';

  @override
  String get reviewEachAdminAndTheBranch =>
      'Review each admin and the branch they manage. Reset passwords or remove an account.';

  @override
  String get searchByNameEmailOrBranch => 'Search admins';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get loadingBranchAdminAccounts => 'Loading branch admin accounts…';

  @override
  String get noBranchAdminAccountsYet => 'No branch admin accounts yet.';

  @override
  String get loadingBranchNames => 'Loading branch names…';

  @override
  String get noEmail => 'No email';

  @override
  String noAdminAccountsMatch(String search) {
    return 'No admin accounts match “$search”.';
  }

  @override
  String get adminAccounts => 'Admin accounts';

  @override
  String passwordUpdatedFor(String email) {
    return 'Password updated for $email.';
  }

  @override
  String get deleteBranchAdmin => 'Delete branch admin?';

  @override
  String deleteForTheyWillLoseSign(String email, String branchName) {
    return 'Delete $email for $branchName? They will lose sign-in access. Branch members and their points will be kept.';
  }

  @override
  String get deleteAdmin => 'Delete admin';

  @override
  String get adminAccountDeleted => 'Admin account deleted.';

  @override
  String get changePassword => 'Change password';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get changeAdminPassword => 'Change admin password';

  @override
  String get newPassword => 'New password';

  @override
  String get useAtLeast8Characters => 'Use at least 8 characters';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get tryAgain => 'Try again';

  @override
  String get branchManagement => 'Branch management';

  @override
  String branchesManageBranchAccessAndStatus(String docs) {
    return '$docs branches · manage branch access and status';
  }

  @override
  String get addBranch => 'Add branch';

  @override
  String get noBranchesYet => 'No branches yet.';

  @override
  String get branchesCouldNotBeLoaded => 'Branches could not be loaded.';

  @override
  String get diwaliCelebrationEnabledAddBillIs =>
      'Diwali celebration enabled. Add Bill is hidden for this branch.';

  @override
  String get diwaliCelebrationDisabledAddBillIs =>
      'Diwali celebration disabled. Add Bill is available for this branch.';

  @override
  String get unableToUpdateTheBranchCelebration =>
      'Unable to update the branch celebration setting.';

  @override
  String codeId(String branchCode, String branchId) {
    return 'Code: $branchCode  ·  ID: $branchId';
  }

  @override
  String get diwaliCelebrationOnHome => 'Diwali celebration on Home';

  @override
  String get showsTheBranchPrizeListAnd =>
      'Shows the branch prize list and hides Add Bill.';

  @override
  String get offNoPopupAddBillRemains =>
      'Off: no popup; Add Bill remains available.';

  @override
  String get branchDeactivated => 'Branch deactivated.';

  @override
  String get branchActivated => 'Branch activated.';

  @override
  String get unableToUpdateTheBranch => 'Unable to update the branch.';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get activate => 'Activate';

  @override
  String branchCreated(String id) {
    return 'Branch created ($id)';
  }

  @override
  String get failedToCreateBranch => 'Failed to create branch';

  @override
  String get newBranch => 'New Branch';

  @override
  String get branchFullName => 'Branch Full Name *';

  @override
  String get shortName => 'Short Name *';

  @override
  String get enterAShortBranchName => 'Enter a short branch name';

  @override
  String get branchCode => 'Branch Code *';

  @override
  String get use216LettersNumbersOr => 'Use 2–16 letters, numbers or hyphens';

  @override
  String get address => 'Address';

  @override
  String get shareTheTemporaryPasswordSecurelyThe =>
      'Share the temporary password securely. The admin can change it after their first sign-in.';

  @override
  String adminCreatedForTheyCanSign(String email, String branchName) {
    return 'Admin $email created for $branchName. They can sign in with email and password.';
  }

  @override
  String get selectABranchFirst => 'Select a branch first.';

  @override
  String get adminDetails => 'Admin Details';

  @override
  String get mobileNumber10Digits => 'Mobile number * (10 digits)';

  @override
  String get enterValid10DigitPhone => 'Enter valid 10-digit phone';

  @override
  String get emailAndPasswordLogin => 'Email and password login';

  @override
  String get emailAddress => 'Email address *';

  @override
  String get temporaryPassword8CharactersMinimum =>
      'Temporary password * (8 characters minimum)';

  @override
  String get confirmPassword => 'Confirm password *';

  @override
  String get assignBranch => 'Assign Branch';

  @override
  String get loadingActiveBranches => 'Loading active branches…';

  @override
  String get noActiveBranchesFoundCreateOr =>
      'No active branches found. Create or activate a branch before adding an admin.';

  @override
  String get selectBranch => 'Select branch';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get createAdminAccount => 'Create admin account';

  @override
  String get signOutOfSuperAdmin => 'Sign out of super admin?';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get superAdminConsole => 'Super Admin Console';

  @override
  String get branchesAdministratorsAndPoints =>
      'Branches, administrators and points';

  @override
  String get branches => 'Branches';

  @override
  String get createAdmin => 'Create Admin';

  @override
  String get roles => 'Roles';

  @override
  String get superAdmin2 => 'Super admin';

  @override
  String get createAdmin2 => 'Create admin';

  @override
  String get pointsReset => 'Points reset';

  @override
  String get onlyPointsTiersAndPointsHistory =>
      'Only points, tiers and points history for carpenters, architects, engineers and interior designers are cleared. User accounts, login access, branch admins and bills stay unchanged.';

  @override
  String get afterPrizeDistributionStartAFresh =>
      'After prize distribution, start a fresh points season for one branch.';

  @override
  String resetUsersAndDeletedHistoryRecords(
    String branchName,
    String usersReset,
    String historyDocumentsDeleted,
  ) {
    return '$branchName: reset $usersReset users and deleted $historyDocumentsDeleted history records. Accounts and bills were kept.';
  }

  @override
  String get thisPermanentlyClearsPointsAndPoints =>
      'This permanently clears points and points history for carpenters, architects, engineers and interior designers in this branch. User accounts, branch admins and bills are kept.';

  @override
  String hasEligibleUsersPointsAndHistory(
    String branchName,
    String eligibleUsers,
    String currentPoints,
    String historyDocuments,
  ) {
    return '$branchName has $eligibleUsers eligible users, $currentPoints points and $historyDocuments history items.';
  }

  @override
  String get resetBranchPoints => 'Reset branch points?';

  @override
  String typeToConfirm(String branchId) {
    return 'Type $branchId to confirm';
  }

  @override
  String get resetPointsAndHistory => 'Reset points and history';

  @override
  String get couldNotLoadBranchesForPoints =>
      'Could not load branches for points cleanup.';

  @override
  String get annualPointsReset => 'Annual points reset';

  @override
  String get branchToReset => 'Branch to reset';

  @override
  String get checkingBranch => 'Checking branch…';

  @override
  String get previewReset => 'Preview reset';

  @override
  String get createABranchBeforeResettingPoints =>
      'Create a branch before resetting points.';

  @override
  String cleanupPreview(String branchName) {
    return 'Cleanup preview · $branchName';
  }

  @override
  String get eligibleUsers => 'Eligible users';

  @override
  String get currentPoints => 'Current points';

  @override
  String get historyItems => 'History items';

  @override
  String get resettingBranchPoints => 'Resetting branch points…';

  @override
  String couldNotLoadSavedRolesShowing(String loadError) {
    return 'Could not load saved roles. Showing the four built-in roles. $loadError';
  }

  @override
  String get roleIdsAreStoredWithUser =>
      'Role IDs are stored with user accounts. Deleting a role removes it from new registrations and preserves existing accounts.';

  @override
  String willBeRemovedFromNewRegistration(String name) {
    return '$name will be removed from new registration. Existing users keep their role and account data.';
  }

  @override
  String roleCreated(String name, String id) {
    return 'Role created: $name ($id).';
  }

  @override
  String get restoreRole => 'Restore role?';

  @override
  String get deleteRole => 'Delete role?';

  @override
  String willBeAvailableForNewAccount(String name) {
    return '$name will be available for new account registration.';
  }

  @override
  String get restoreRole2 => 'Restore role';

  @override
  String get deleteRole2 => 'Delete role';

  @override
  String get accountRoles => 'Account roles';

  @override
  String get manageTheRolesShownInCreate =>
      'Manage the roles shown in create account.';

  @override
  String get addRole => 'Add role';

  @override
  String get loadingAccountRoles => 'Loading account roles…';

  @override
  String get noRolesFound => 'No roles found.';

  @override
  String roleId(String id) {
    return 'Role ID: $id';
  }

  @override
  String get restore => 'Restore';

  @override
  String get deleted => 'Deleted';

  @override
  String get addAccountRole => 'Add account role';

  @override
  String get roleName => 'Role name *';

  @override
  String get enterAtLeast2Characters => 'Enter at least 2 characters';

  @override
  String get shortFormOptional => 'Short form (optional)';

  @override
  String get exampleAr => 'Enter short form';

  @override
  String get use10CharactersOrLess => 'Use 10 characters or less';

  @override
  String get saving => 'Saving…';

  @override
  String get saveRole => 'Save role';

  @override
  String get cleanUpDuplicates => 'Clean Up Duplicates';

  @override
  String error3(String error) {
    return 'Error: $error';
  }

  @override
  String get duplicatesFound => 'Duplicates Found';

  @override
  String accountsAcrossPhoneNumbers(String duplicateCount, String duplicates) {
    return '$duplicateCount accounts across $duplicates phone numbers';
  }

  @override
  String get noDuplicatesFound => 'No Duplicates Found!';

  @override
  String get allCarpenterAccountsAreUnique =>
      'All carpenter accounts are unique.';

  @override
  String get duplicateGroups => 'Duplicate Groups';

  @override
  String phoneAccounts(String groupIndex, String phone, String users) {
    return '$groupIndex. Phone: $phone ($users accounts)';
  }

  @override
  String get keep => 'Keep';

  @override
  String get reviewOnly => 'Review only';

  @override
  String diagnosticUser(String phoneNumber) {
    return 'Diagnostic: User $phoneNumber';
  }

  @override
  String get noData => 'No data';

  @override
  String get phoneNumberInformation => 'Phone Number Information';

  @override
  String get originalPhone => 'Original Phone';

  @override
  String get normalizedPhone => 'Normalized Phone';

  @override
  String get match => 'Match';

  @override
  String get userDocumentStatus => 'User Document Status';

  @override
  String get existsByDocumentId => 'Exists (by Document ID)';

  @override
  String get documentId => 'Document ID';

  @override
  String get phoneFieldInData => 'Phone Field (in data)';

  @override
  String get existsByPhoneFieldQuery => 'Exists (by Phone Field Query)';

  @override
  String get documentIdFromQuery => 'Document ID (from query)';

  @override
  String get issueDetected => 'ISSUE DETECTED';

  @override
  String get documentIdMismatch => 'Document ID mismatch!';

  @override
  String get userDocumentFound => 'User document found';

  @override
  String get userDocumentNotFound => 'User document NOT FOUND';

  @override
  String get billsCollectionStatus => 'Bills Collection Status';

  @override
  String get phoneFormatMismatchInBills => 'Phone format mismatch in bills!';

  @override
  String get phoneFormatConsistent => 'Phone format consistent';

  @override
  String get pendingBillsStatus => 'Pending Bills Status';

  @override
  String get totalPendingBills => 'Total Pending Bills';

  @override
  String get matchingBillsFound => 'Matching Bills Found';

  @override
  String get noPendingBillsFoundForThis =>
      'No pending bills found for this user!';

  @override
  String get carpenterId => 'Carpenter ID';

  @override
  String get carpenterPhone => 'Carpenter Phone';

  @override
  String get isToday => 'Is Today';

  @override
  String get createdAt => 'Created At';

  @override
  String get thisBillWonTShowIn =>
      'This bill won\'t show in default admin view (not today)';

  @override
  String get totalAccounts => 'Total Accounts';

  @override
  String get duplicatePhones => 'Duplicate Phones';

  @override
  String get affectedAccounts => 'Affected Accounts';

  @override
  String get noDuplicateAccountsFound => 'No duplicate accounts found!';

  @override
  String get duplicatePhoneNumbers => 'Duplicate Phone Numbers';

  @override
  String account(String idx) {
    return 'Account $idx';
  }

  @override
  String get review => 'Review';

  @override
  String get preparingUserBackupPdf => 'Preparing user backup PDF...';

  @override
  String get noCarpentersFound2 => 'No carpenters found.';

  @override
  String userBackupExportedSuccessfullyCarpenters(String users) {
    return 'User backup exported successfully! ($users carpenters)';
  }

  @override
  String get exportUsersBackup => 'Export Users Backup';

  @override
  String get createUserBackup => 'Create User Backup';

  @override
  String get exportAllCarpentersWithTheirPoints =>
      'Export all carpenters with their points and phone numbers before cleanup.';

  @override
  String get exporting => 'Exporting...';

  @override
  String get exportToPdf => 'Export to PDF';

  @override
  String get pdfWillInclude => 'PDF will include:';

  @override
  String get carpenterNameAndPhoneNumberTotal =>
      '• Carpenter name and phone number\n• Total points and earned points\n• Account creation date\n• Summary with total carpenters and gross points';

  @override
  String get firebaseDuplicateCheck => 'Firebase Duplicate Check';

  @override
  String get firebaseDatabaseSummary => 'Firebase Database Summary';

  @override
  String get totalCarpenters2 => 'Total Carpenters:';

  @override
  String get uniquePhoneNumbers => 'Unique Phone Numbers:';

  @override
  String get duplicatePhoneNumbers2 => 'Duplicate Phone Numbers:';

  @override
  String get totalDuplicateAccounts => 'Total Duplicate Accounts:';

  @override
  String get allPhoneNumbersAreUnique => 'All phone numbers are unique.';

  @override
  String get duplicateMobileNumbers => 'Duplicate Mobile Numbers';

  @override
  String mobile2(String groupIndex, String totalGroups, String phone) {
    return '$groupIndex/$totalGroups - Mobile: $phone';
  }

  @override
  String accountsWithSamePhoneNumber(String users) {
    return '$users accounts with same phone number';
  }

  @override
  String get main => 'Main';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get startingBackup => 'Starting backup...';

  @override
  String backupExportedUsersBills(String users, String bills) {
    return 'Backup exported: $users users, $bills bills';
  }

  @override
  String backupFailed(String e) {
    return 'Backup failed: $e';
  }

  @override
  String get backupData => 'Backup Data';

  @override
  String totalSizeKb(String backupJson) {
    return 'Total Size: $backupJson KB';
  }

  @override
  String get firebaseBackup => 'Firebase Backup';

  @override
  String get databaseBackup => 'Database Backup';

  @override
  String get createACompleteBackupOfAll =>
      'Create a complete backup of all users and bills data from Firebase Firestore.';

  @override
  String get whatWillBeBackedUp => 'What will be backed up:';

  @override
  String get allUserAccountsCarpentersAdminsAll =>
      '• All user accounts (carpenters & admins)\n• All bill records\n• Complete user data with timestamps\n• Firestore metadata';

  @override
  String get backingUp => 'Backing up...';

  @override
  String get startBackup => 'Start Backup';

  @override
  String get backupIsStoredInFirebaseNo =>
      'Backup is stored in Firebase. No files are saved locally.';

  @override
  String get repairDetails => 'Repair Details';

  @override
  String get verificationComplete => 'Verification Complete';

  @override
  String get noPointsLostAllUsersVerified =>
      'NO POINTS LOST\nAll users verified\nData consistent';

  @override
  String get userWiseRepairResults => 'User-wise Repair Results';

  @override
  String get noRepairsCompleted => 'No repairs completed';

  @override
  String get repairComplete => 'Repair Complete';

  @override
  String get successfullyRepaired => 'Successfully Repaired';

  @override
  String get failed => 'Failed';

  @override
  String get duplicatesRemoved => 'Duplicates Removed';

  @override
  String get pointsAdjusted => 'Points Adjusted';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get repairFailed => 'Repair failed';

  @override
  String get thisToolScansUserPointsData =>
      'This tool scans user points data and fixes:\n• Duplicate history entries\n• Inconsistent totalPoints\n• Mismatched tiers';

  @override
  String get pointsRepairTool => 'Points Repair Tool';

  @override
  String get pointsDataRepair => 'Points Data Repair';

  @override
  String get scanReport => 'Scan Report';

  @override
  String get totalUsersScanned => 'Total users scanned';

  @override
  String get usersWithIssues => 'Users with issues';

  @override
  String get usersWithDuplicates => 'Users with duplicates';

  @override
  String get totalDuplicateEntries => 'Total duplicate entries';

  @override
  String get pointsMismatches => 'Points mismatches';

  @override
  String get viewFullScanDetails => 'View Full Scan Details';

  @override
  String get viewDetailedResults => 'View Detailed Results';

  @override
  String get scanForIssues => 'Scan for Issues';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get repairAllUsers => 'Repair All Users';

  @override
  String get noIssuesFoundAllUserData =>
      'No issues found! All user data is consistent.';

  @override
  String scanFailed(String e) {
    return 'Scan failed: $e';
  }

  @override
  String get repairAllUsers2 => 'Repair All Users?';

  @override
  String get repair => 'Repair';

  @override
  String repairFailed2(String e) {
    return 'Repair failed: $e';
  }

  @override
  String get scanningForIssues => 'Scanning for Issues...';

  @override
  String get analyzingAllUserPointsData => 'Analyzing all user points data';

  @override
  String get scanResultsFullDetails => 'Scan Results - Full Details';

  @override
  String get usersWithIssues2 => 'Users with Issues';

  @override
  String get noUsersWithIssuesFound => 'No users with issues found';

  @override
  String get scanSummary => 'Scan Summary';

  @override
  String get totalUsersScanned2 => 'Total Users Scanned';

  @override
  String get totalDuplicateEntries2 => 'Total Duplicate Entries';

  @override
  String get totalPointsDifference => 'Total Points Difference';

  @override
  String duplicates(String duplicateCount) {
    return '$duplicateCount duplicates';
  }

  @override
  String get historySum => 'History Sum';

  @override
  String get difference => 'Difference';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get uniqueBills => 'Unique Bills';

  @override
  String get duplicateBills => 'Duplicate Bills:';

  @override
  String get smartDuplicateCleanup => 'Smart Duplicate Cleanup';

  @override
  String get allCarpentersHaveUniquePhoneNumbers =>
      'All carpenters have unique phone numbers.';

  @override
  String get potentialDuplicateAccountsReviewRequired =>
      'Potential duplicate accounts — review required';

  @override
  String foundDuplicateMobileNumbers(String duplicateGroups) {
    return 'Found $duplicateGroups duplicate mobile numbers';
  }

  @override
  String accountsToReview(String totalForReview) {
    return 'Accounts to review: $totalForReview';
  }

  @override
  String get allRecordsAreRetainedTheHighest =>
      'All records are retained. The highest-points profile is only a suggested primary account.';

  @override
  String potentialDuplicateGroups(String duplicateGroups) {
    return 'Potential duplicate groups ($duplicateGroups)';
  }

  @override
  String mobile3(String groupIndex, String phone) {
    return '$groupIndex. Mobile: $phone';
  }

  @override
  String similarAccountsPointsDiff(String reviewUsers, String pointsDiff) {
    return '$reviewUsers similar accounts | Points diff: $pointsDiff';
  }

  @override
  String get suggestedPrimaryAccountHighestPoints =>
      'Suggested primary account (highest points)';

  @override
  String get otherMatchingAccountsManualReviewRequired =>
      'Other matching accounts — manual review required';

  @override
  String repairConfirmBody(String count) {
    return 'This will repair $count users by:\n\n• Removing duplicate history entries\n• Recalculating correct totals\n• Updating tier assignments\n\nThis action cannot be undone easily.';
  }

  @override
  String repairSuccess(String repaired, String total) {
    return 'Repaired $repaired/$total users successfully!\nVerified: no points lost';
  }

  @override
  String repairPartial(String repaired, String total) {
    return 'Repaired $repaired/$total users.\nSome verification issues - check logs';
  }

  @override
  String backupUsersCount(String count) {
    return 'Users ($count)';
  }

  @override
  String backupBillsCount(String count) {
    return 'Bills ($count)';
  }

  @override
  String openAppForEachCarpenter(String app) {
    return 'This will open $app for each carpenter.\n\nYou must manually tap Send in each app.\n\nContinue?';
  }

  @override
  String roleIdPreview(String id) {
    return 'Role ID: $id';
  }

  @override
  String winnersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count winners',
      one: '1 winner',
    );
    return '$_temp0';
  }

  @override
  String roleRestored(String name) {
    return 'Role $name restored.';
  }

  @override
  String roleDeleted(String name) {
    return 'Role $name deleted.';
  }

  @override
  String get permissionDeniedSuperAdmin =>
      'Permission denied. Check that Firestore rules are published and the signed-in account is the configured super admin.';

  @override
  String get roleEngineer => 'Engineer';

  @override
  String get roleBuiltInBadge => 'Built-in';

  @override
  String get roleCustomBadge => 'Custom';

  @override
  String get roleProtectedTooltip =>
      'Carpenter is the main role and can’t be deleted';

  @override
  String rolesSummary(int active, int deleted) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active active',
    );
    String _temp1 = intl.Intl.pluralLogic(
      deleted,
      locale: localeName,
      other: '$deleted deleted',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get rolesLiveSync =>
      'Changes sync instantly to registration on every device.';

  @override
  String get roleIdHelp => 'Created from the name. It can’t be changed later.';

  @override
  String get roleErrInvalidName =>
      'Use 2–40 characters with at least two English letters or numbers.';

  @override
  String get roleErrReserved =>
      'This name is reserved for administrator accounts.';

  @override
  String get roleErrBuiltIn =>
      'This matches a built-in role. Restore it from the list instead.';

  @override
  String get roleErrDuplicate => 'A role with this ID already exists.';

  @override
  String get roleErrProtected =>
      'Carpenter is the main role and can’t be deleted.';

  @override
  String get roleShowAll => 'All';

  @override
  String get roleShowActive => 'Active';

  @override
  String get roleShowDeleted => 'Deleted';

  @override
  String get noRolesInFilter => 'No roles in this view.';

  @override
  String deactivateBranchTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get deactivateBranchBody =>
      'New users can’t pick this branch and its members can’t sign in until you activate it again. No data is deleted.';

  @override
  String activateBranchTitle(String name) {
    return 'Activate $name?';
  }

  @override
  String get activateBranchBody =>
      'The branch will be available for registration and sign-in again.';

  @override
  String get branchActions => 'Branch actions';

  @override
  String get copyBranchId => 'Copy branch ID';

  @override
  String get branchIdCopied => 'Branch ID copied';

  @override
  String get celebrationOn => 'On';

  @override
  String get celebrationOff => 'Off';

  @override
  String get createAdminSubtitle =>
      'Add a branch admin who reviews bills and carpenters for one branch.';

  @override
  String get selectBranchRequired => 'Select a branch';

  @override
  String get addAdmin => 'Add admin';

  @override
  String get branchAdminsTitle => 'Branch admins';

  @override
  String get adminsNav => 'Admins';

  @override
  String adminsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count admins',
      one: '1 admin',
    );
    return '$_temp0';
  }

  @override
  String get adminActions => 'Admin actions';

  @override
  String get editBranch => 'Edit branch';

  @override
  String get branchUpdated => 'Branch updated';

  @override
  String get branchCodeLocked =>
      'The code can’t change — existing members are registered with it.';

  @override
  String get editLabel => 'Edit';

  @override
  String get editRole => 'Edit role';

  @override
  String roleUpdated(String name) {
    return 'Role $name updated.';
  }

  @override
  String get roleIdLocked =>
      'The role ID can’t change — it is stored with user accounts.';

  @override
  String get roleActions => 'Role actions';

  @override
  String get editAdmin => 'Edit admin';

  @override
  String get editDetails => 'Edit details';

  @override
  String adminUpdated(String email) {
    return 'Admin $email updated.';
  }

  @override
  String get adminBranchChangeNote =>
      'Moving an admin to another branch removes their access to the current one. A branch can have only one admin.';

  @override
  String get editsSyncNote =>
      'Name changes are copied to every member’s profile automatically.';

  @override
  String get noBranchAssigned =>
      'Your account is not linked to a branch yet. Ask the super admin to assign your branch.';

  @override
  String get loadingBranch => 'Loading your branch…';

  @override
  String get offerPointsTarget => 'Points target';

  @override
  String get offerDetails => 'Offer details';

  @override
  String get offerInfo => 'Offer details';

  @override
  String offerProgress(String have, String target) {
    return 'You have $have of $target points';
  }

  @override
  String offerPointsToGo(String points) {
    return '$points more points to reach this offer';
  }

  @override
  String get offerTargetReached => 'Target reached!';

  @override
  String get offerTermsApply => '*Terms and conditions apply.';

  @override
  String get offerViewBanner => 'View full banner';

  @override
  String get homeAnnouncements => 'Announcements';

  @override
  String get legalTermsTitle => 'Terms & Conditions';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get legalAgreePrefix => 'I have read and agree to the ';

  @override
  String get legalAgreeAnd => ' and the ';

  @override
  String get legalAgreeSuffix => '.';

  @override
  String get legalAcceptToContinue =>
      'Please accept the Terms & Conditions and Privacy Policy to continue.';

  @override
  String get legalEnglishOnly => 'This document is provided in English.';

  @override
  String get profileSectionLegal => 'Legal';

  @override
  String get myBranch => 'My Branch';

  @override
  String get myBranchSubtitle => 'Your store branch and who to contact';

  @override
  String get branchDetails => 'Branch details';

  @override
  String get branchPhone => 'Branch phone';

  @override
  String get yourBranchSupport => 'Your branch';

  @override
  String get appSupport => 'App support';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get notAvailable => 'Not available';

  @override
  String get supportHint =>
      'For bills, points and offers, contact your branch. For app problems, contact app support.';

  @override
  String get directions => 'Directions';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get profileStatus => 'Profile status';

  @override
  String get profileReadyForBills =>
      'Your profile is complete. You can submit bills.';

  @override
  String get profileMissingForBills => 'Add the missing items to submit bills.';

  @override
  String get requiredForBills => 'Required for bills';

  @override
  String get added => 'Added';

  @override
  String get missing => 'Missing';

  @override
  String get notAdded => 'Not added';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get addPhotoRequired =>
      'Add a profile photo. It is required to submit bills.';

  @override
  String itemsMissing(String items) {
    return 'Missing: $items';
  }

  @override
  String get rupeesPerPoint => 'Rupees per point';

  @override
  String get rupeesPerPointHint => 'e.g. 1000 means 1 point for every ₹1,000';

  @override
  String get enterValidRate => 'Enter a number from 1 to 10,00,000';

  @override
  String ptPerRupees(String rupees) {
    return '1 pt / ₹$rupees';
  }

  @override
  String yourPointsRate(String rupees) {
    return 'Your rate: 1 point for every ₹$rupees';
  }

  @override
  String get pointsRateByRole => 'Points rate';

  @override
  String get enterRupeesPerPoint => 'Enter rupees per point';

  @override
  String get catalogs => 'Catalogs';

  @override
  String get catalogsSubtitle => 'Product catalogs by category';

  @override
  String catalogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catalogs',
      one: '1 catalog',
    );
    return '$_temp0';
  }

  @override
  String catalogPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get catalogView => 'View';

  @override
  String get catalogShare => 'Share';

  @override
  String get catalogZoomIn => 'Zoom in';

  @override
  String get catalogZoomOut => 'Zoom out';

  @override
  String get catalogZoomFit => 'Fit to screen';

  @override
  String get catalogDownload => 'Download';

  @override
  String get catalogsEmpty => 'No catalogs yet';

  @override
  String get catalogsEmptyMessage =>
      'Catalogs will appear here once Balaji Points adds them.';

  @override
  String get catalogLoadError =>
      'Could not load catalogs. Check your internet and try again.';

  @override
  String get catalogOpenError =>
      'Could not open this catalog. Check your internet and try again.';

  @override
  String catalogShareText(String title, String url) {
    return '$title – Balaji Points catalog\n$url';
  }

  @override
  String get catalogOnlineHint =>
      'Opens online. Nothing is saved on your phone unless you tap Download.';

  @override
  String catalogPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get catalogAdminAddCategory => 'Add category';

  @override
  String get catalogAdminEditCategory => 'Edit category';

  @override
  String get catalogAdminCategoryName => 'Category name';

  @override
  String get catalogAdminDescription => 'Description (optional)';

  @override
  String get catalogAdminAddCatalog => 'Add catalog';

  @override
  String get catalogAdminEditCatalog => 'Edit catalog';

  @override
  String get catalogAdminCategory => 'Category';

  @override
  String get catalogAdminTitle => 'Catalog title';

  @override
  String get catalogAdminBrand => 'Brand (optional)';

  @override
  String get catalogAdminYear => 'Year';

  @override
  String get catalogAdminOrder => 'Display order';

  @override
  String get catalogAdminPickPdf => 'Choose PDF';

  @override
  String get catalogAdminReplacePdf => 'Replace PDF';

  @override
  String get catalogAdminPickCover => 'Choose cover image';

  @override
  String get catalogAdminCoverAuto =>
      'If you don\'t choose a cover, the first page of the PDF is used.';

  @override
  String catalogAdminPdfTooLarge(String size) {
    return 'This PDF is $size. The limit is 25 MB. Compress it and try again.';
  }

  @override
  String get catalogAdminNotPdf => 'That file is not a PDF.';

  @override
  String catalogAdminUploading(int percent) {
    return 'Uploading… $percent%';
  }

  @override
  String get catalogAdminSaved => 'Catalog saved';

  @override
  String get catalogAdminHide => 'Hide from members';

  @override
  String get catalogAdminShow => 'Show to members';

  @override
  String get catalogAdminHidden => 'Hidden';

  @override
  String catalogAdminDeleteCatalogConfirm(String title) {
    return 'Delete \"$title\"? Members will no longer see it.';
  }

  @override
  String catalogAdminDeleteCategoryConfirm(String name) {
    return 'Delete the category \"$name\"?';
  }

  @override
  String get catalogAdminCategoryNotEmpty =>
      'Delete or move the catalogs in this category first.';

  @override
  String get catalogAdminEmpty =>
      'No catalogs yet. Add a category, then upload a PDF.';

  @override
  String get catalogAdminNeedCategory => 'Add a category first.';

  @override
  String get catalogAdminRequired => 'Required';

  @override
  String catalogAdminSaveFailed(String details) {
    return 'Could not save: $details';
  }

  @override
  String get catalogAdminPermission =>
      'Only admins signed in with email can change catalogs.';

  @override
  String get catalogAdminPdfRequired => 'Choose a PDF file.';

  @override
  String get catalogAdminHintCategoryName => 'Enter category name';

  @override
  String get catalogAdminHintDescription => 'Enter description';

  @override
  String get catalogAdminHintTitle => 'Enter catalog title';

  @override
  String get catalogAdminHintBrand => 'Enter brand name';

  @override
  String get catalogAdminHintYear => 'Enter year';

  @override
  String get catalogAdminHintOrder => 'Enter display order';

  @override
  String get enquiryHeroTitle => 'How can we help?';

  @override
  String get enquiryHeroSubtitle =>
      'Send your question. We usually reply within one working day.';

  @override
  String enquiryGoesToBranch(String branch) {
    return 'Goes to $branch';
  }

  @override
  String get enquiryGoesToTeam => 'Goes to the Balaji Points team';

  @override
  String get enquiryTypeLabel => 'What is it about?';

  @override
  String get enquiryTypeProduct => 'Product enquiry';

  @override
  String get enquiryTypeQuotation => 'Bulk order / quote';

  @override
  String get enquiryTypePointsBills => 'Points & bills';

  @override
  String get enquiryTypeAppHelp => 'App help';

  @override
  String get enquiryTypeMembership => 'Become a member';

  @override
  String get enquiryTypeOther => 'Other';

  @override
  String get enquiryNameLabel => 'Your name';

  @override
  String get enquiryNameHint => 'Enter your name';

  @override
  String get enquiryPhoneLabel => 'Mobile number';

  @override
  String get enquiryPhoneHint => 'Enter mobile number';

  @override
  String get enquiryCityLabel => 'City (optional)';

  @override
  String get enquiryCityHint => 'Enter city';

  @override
  String get enquiryMessageLabel => 'Message';

  @override
  String get enquiryMessageHint => 'Enter your message';

  @override
  String get enquiryNameRequired => 'Enter your name';

  @override
  String get enquiryPhoneInvalid => 'Enter a valid 10-digit mobile number';

  @override
  String get enquiryMessageTooShort => 'Write at least 10 characters';

  @override
  String get enquirySend => 'Send enquiry';

  @override
  String get enquirySentTitle => 'Enquiry sent';

  @override
  String enquirySentBranch(String branch) {
    return 'Thank you. $branch will contact you soon.';
  }

  @override
  String get enquirySentTeam => 'Thank you. Our team will contact you soon.';

  @override
  String get enquirySendAnother => 'Send another';

  @override
  String enquiryTooSoon(int minutes) {
    return 'Please wait $minutes min before sending another enquiry.';
  }

  @override
  String get enquiryFailed =>
      'Could not send. Check your internet and try again.';

  @override
  String get enquiryReachDirectly => 'Or reach us directly';

  @override
  String get enquiryCall => 'Call';

  @override
  String get enquiries => 'Enquiries';

  @override
  String get enquiriesEmpty => 'No enquiries yet';

  @override
  String get enquiriesOpen => 'Open';

  @override
  String get enquiriesResolved => 'Resolved';

  @override
  String get enquiryMarkResolved => 'Mark resolved';

  @override
  String get enquiryReopen => 'Reopen';

  @override
  String get enquiryGuest => 'Guest';

  @override
  String get enquiriesNoAccess =>
      'Sign in with your admin email to see enquiries.';

  @override
  String get contactYourBranch => 'Your branch';

  @override
  String get contactSendMessage => 'Send us a message';

  @override
  String contactSendingAs(String name) {
    return 'Sending as $name';
  }

  @override
  String get guestEnquiries => 'Guest enquiries';

  @override
  String get navMore => 'More';

  @override
  String get billRejectedAt => 'Rejected: ';

  @override
  String get memberDetailsTitle => 'Member details';

  @override
  String get memberApprovedAmount => 'Approved purchases';

  @override
  String get memberDateRange => 'Date range';

  @override
  String get memberHistory => 'History';

  @override
  String get memberCall => 'Call';

  @override
  String get billPointsCredited => 'Points credited';

  @override
  String get billMember => 'Member';

  @override
  String get billDetailsSection => 'Details';

  @override
  String get guestContinue => 'Continue as guest';

  @override
  String get guestHomeTitle => 'Welcome to Balaji Points';

  @override
  String get guestHomeSubtitle =>
      'Browse catalogs, find a branch or talk to us.';

  @override
  String get guestJoinTitle => 'Join Balaji Points';

  @override
  String get guestJoinBody =>
      'Carpenters, architects, engineers and interior designers earn points on every purchase and win rewards.';

  @override
  String get guestRegister => 'Register now';

  @override
  String get guestLogin => 'Log in';

  @override
  String get guestCatalogsSub => 'Laminates, plywood, doors and more';

  @override
  String get guestBranches => 'Our branches';

  @override
  String get guestBranchesSub => 'Address, phone and directions';

  @override
  String get guestService => 'Service request';

  @override
  String get guestServiceSub => 'Ask a branch for help';

  @override
  String get guestCareers => 'Careers';

  @override
  String get guestCareersSub => 'Apply to work with us';

  @override
  String get guestContactSub => 'Questions about products or prices';

  @override
  String get branchDirections => 'Directions';

  @override
  String get branchesEmpty => 'No branches yet';

  @override
  String get enquiryBranchLabel => 'Branch';

  @override
  String get enquiryBranchHint => 'Select branch';

  @override
  String get enquiryBranchRequired => 'Select a branch';

  @override
  String get enquiryTypeService => 'Service request';

  @override
  String get enquiryTypeCareer => 'Career';

  @override
  String get careerIntro => 'Send your details. The branch will call you.';

  @override
  String get careerPosition => 'Position';

  @override
  String get careerPositionHint => 'Enter position';

  @override
  String get careerExperience => 'Experience';

  @override
  String get careerExperienceHint => 'Enter experience';

  @override
  String get careerAbout => 'About you';

  @override
  String get careerAboutHint => 'Enter a few lines about your work';

  @override
  String get careerSubmit => 'Send application';

  @override
  String get careerSentTitle => 'Application sent';

  @override
  String get careerPositionRequired => 'Enter the position';

  @override
  String get branchMapsLink => 'Google Maps link';

  @override
  String get branchMapsLinkHint => 'Enter Google Maps link';

  @override
  String get branchMapsLinkHelp =>
      'Open the store in Google Maps, tap Share, copy the link and paste it here.';

  @override
  String get branchMapsLinkInvalid => 'Paste a link that starts with https://';

  @override
  String get guestLoginMember => 'Member? Log in';

  @override
  String get guestTabHome => 'Home';

  @override
  String get guestTabCatalogs => 'Catalogs';

  @override
  String get guestTabBranches => 'Branches';

  @override
  String get guestTabContact => 'Contact';

  @override
  String get guestTagline => 'Your one-stop shop for interiors';

  @override
  String get guestHeroTitle =>
      'Plywood, hardware & fittings — all under one roof';

  @override
  String get guestHeroBody =>
      'Browse the latest catalogs, find your nearest branch and get expert help.';

  @override
  String get guestExploreCatalogs => 'Explore catalogs';

  @override
  String get guestWeOffer => 'Everything we offer';

  @override
  String get guestOfferPlywood => 'Plywood';

  @override
  String get guestOfferLaminates => 'Laminates';

  @override
  String get guestOfferDoors => 'Doors';

  @override
  String get guestOfferHardware => 'Hardware';

  @override
  String get guestOfferFittings => 'Fittings';

  @override
  String get guestOfferService => 'Service & support';

  @override
  String get guestStatBranches => 'Branches';

  @override
  String get guestStatCatalogs => 'Catalogs';

  @override
  String get guestStatRoles => 'Member roles';

  @override
  String get guestQuickLinks => 'Quick links';

  @override
  String get guestJoinPoint1 => 'Earn points on every purchase';

  @override
  String get guestJoinPoint2 => 'Win trips, gadgets and more';

  @override
  String get guestJoinPoint3 => 'Daily spin and branch offers';

  @override
  String get guestGrowTitle => 'Grow your business with Balaji Points';

  @override
  String get guestGrowBody =>
      'Own a store? Register your store or branch on Balaji Points and reward your customers.';

  @override
  String get guestGrowPoint1 => 'Customized roles for your members';

  @override
  String get guestGrowPoint2 => 'Your own points and rewards system';

  @override
  String get guestGrowPoint3 => 'Full admin panel for your team';

  @override
  String get guestGrowCta => 'Partner with us';

  @override
  String get enquiryTypePartner => 'Register my store';

  @override
  String get guestStatCategories => 'Categories';

  @override
  String get enquiryBranchOptional => 'Branch (optional)';

  @override
  String get enquiryBranchAny => 'Any branch — Balaji Points team';

  @override
  String get guestTabGuest => 'Guest';

  @override
  String get offersArrange => 'Arrange order';

  @override
  String get offersArrangeHint =>
      'Drag offers into the order members should see them.';

  @override
  String get offersOrderSaved => 'Offer order saved';

  @override
  String get offersOrderFailed => 'Could not save the order. Try again.';

  @override
  String get drawerSectionExplore => 'Explore';

  @override
  String get drawerSectionSupport => 'Help & support';

  @override
  String get offerBannerChange => 'Change';

  @override
  String get loggingOut => 'Logging out…';
}
