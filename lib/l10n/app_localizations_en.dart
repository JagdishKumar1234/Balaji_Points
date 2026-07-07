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
  String get loginInfo => 'Login using your registered phone number. You will receive an OTP to verify.';

  @override
  String get poweredBy => 'Powered by';

  @override
  String get companyName => 'Sri Balaji Plywood & Hardware';

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
  String get mobileNumber => 'Mobile Number';

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
  String get resetPinSubtitle => 'Enter your registered mobile number to reset your PIN.';

  @override
  String get mustBeLoggedInToResetPin => 'You must be logged in to reset your PIN. Please login first.';

  @override
  String get canOnlyResetOwnPin => 'You can only reset your own PIN. Phone number must match your logged-in account.';

  @override
  String get enterCurrentPin => 'Please enter your current PIN to verify ownership.';

  @override
  String get currentPinLabel => 'Current PIN';

  @override
  String get newPinMustBeDifferent => 'New PIN must be different from your current PIN.';

  @override
  String get contactAdminForPinReset => 'You must be logged in to reset your PIN. If you forgot your PIN, please contact admin for assistance.';

  @override
  String get forgotCurrentPin => 'Forgot your current PIN?';

  @override
  String get forgotPinHelp => 'If you don\'t remember your current PIN, please contact our support team for assistance.';

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
  String get adminResetPinSubtitle => 'Enter a new 4-digit PIN for this carpenter.';

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
  String get adminNotAuthorized => 'You are not authorized to perform this action.';

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
  String get accountExistsUseReset => 'Account already exists. Please use Reset PIN to change your PIN.';

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
  String get homeRankingsSectionSubtitle => 'Leaderboard, your rank, and today’s prize';

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
  String get routeErrorNotFound => 'This link is invalid or the page was removed.';

  @override
  String get routeErrorGoHome => 'Go home';

  @override
  String get routeErrorDetailsLabel => 'Technical details';

  @override
  String get topCarpenters => 'Top 3 Carpenters';

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
  String get completeProfileMessage => 'Please complete your profile to start adding bills and earning points';

  @override
  String get completeProfileDetails => 'Add your first name, last name, and profile picture to continue';

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
  String get contactSupport => 'Contact our support team for any queries or issues.';

  @override
  String get supportPhone1 => '96006 - 09121';

  @override
  String get supportPhone2 => '0424 - 3557187';

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
  String get comeBackTomorrow => 'Come back tomorrow for another chance to win!';

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
  String get networkError => 'Network error. Please check your internet connection.';

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
  String get missingClientId => 'SHA-1 fingerprint missing in Firebase. Please run: scripts/get_sha1.sh';

  @override
  String get tooManyRequests => 'Too many requests. Please wait a few minutes.';

  @override
  String get invalidVerificationCode => 'Invalid OTP code. Please check and try again.';

  @override
  String get verificationExpired => 'Verification expired. Please request a new OTP.';

  @override
  String get userDisabled => 'This account has been disabled. Please contact support.';

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
  String get rejectBillConfirmation => 'Are you sure you want to reject this bill?';

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
  String get deleteOfferConfirmation => 'Are you sure you want to delete this offer? This action cannot be undone.';

  @override
  String get offerDeletedSuccess => 'Offer deleted successfully';

  @override
  String get failedToDeleteOffer => 'Failed to delete offer';

  @override
  String get errorLoadingOffers => 'Error loading offers';

  @override
  String get noOffersCreated => 'No Offers Created';

  @override
  String get createFirstOffer => 'Create your first offer with points and banner';

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
  String get offerTitleHint => 'e.g., Diwali Special Offer';

  @override
  String get enterOfferTitle => 'Please enter offer title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Brief description of the offer';

  @override
  String get pointsRequiredLabel => 'Points Required *';

  @override
  String get pointsHint => 'e.g., 100';

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
  String get searchByNameOrPhone => 'Search by name or phone';

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
  String get deleteCarpenterConfirmation => 'Are you sure you want to delete this carpenter? This will permanently delete:\n\n• User account\n• All points and transaction history\n• All submitted bills\n• All offer redemptions\n\nThis action cannot be undone.';

  @override
  String get deleteCarpenterWarning => 'Deleting a carpenter will permanently remove all their data from the system. This action cannot be undone.';

  @override
  String get carpenterDeletedSuccess => 'Carpenter deleted successfully';

  @override
  String get failedToDeleteCarpenter => 'Failed to delete carpenter';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => 'e.g. 9876543210 (no +91)';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get verifyAndCreate => 'Verify & Create';

  @override
  String get adminSignOutNote => 'Note: The app will sign in as the verified carpenter temporarily during OTP verification and then sign out. The admin must sign in again.';

  @override
  String get carpenterCreated => 'Carpenter created';

  @override
  String get carpenterCreatedMessage => 'Carpenter account created successfully. The app has signed in as that carpenter during verification and has now signed out. You will need to sign in again as admin.';

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
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
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
  String get discardChangesMessage => 'You have unsaved changes. Do you want to discard them?';

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
  String get discardBillMessage => 'You have unsaved bill data. Do you want to discard it?';

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
  String get enterStoreOrVendorNameOptional => 'Enter store or vendor name (optional)';

  @override
  String get enterBillOrInvoiceNumberOptional => 'Enter bill or invoice number (optional)';

  @override
  String get addAnyAdditionalNotes => 'Add any additional notes...';

  @override
  String get submitBill => 'Submit Bill';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get withdrawBill => 'Withdraw Bill';

  @override
  String get withdrawBillConfirmation => 'Are you sure you want to withdraw this approved bill? This will reverse the points awarded to the carpenter.';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get billWithdrawnSuccess => 'Bill withdrawn successfully. Points have been reversed.';

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
  String get aboutUsMenuSubtitle => 'Rewards & loyalty for carpenters';

  @override
  String get aboutUsSubtitle => 'Your hardware rewards partner';

  @override
  String get aboutUsOverviewTitle => 'What is Balaji Points?';

  @override
  String get aboutUsOverviewBody => 'Balaji Points is a digital loyalty platform for carpenters and hardware stores. It helps you turn eligible material purchases into points, rewards, and recognition. You use the app to submit bills; the hardware store you are enrolled with reviews and approves them; your wallet and history update automatically so you always know where you stand.';

  @override
  String get aboutUsEarningTitle => 'How you earn points';

  @override
  String get aboutUsEarningBody => 'Upload purchase bills with clear photos, correct amounts, and any details your store asks for. Store admins review submissions to keep the program fair and prevent errors or misuse. After approval, points are credited using that store’s rules (for example, how rupees convert to points). You can track your balance, transaction history, and tier progress anytime in the app.';

  @override
  String get aboutUsOffersTitle => 'Leaderboards, offers, and updates';

  @override
  String get aboutUsOffersBody => 'Many stores run a leaderboard so you can see how you rank among carpenters in their program. You will also see offers, banners, and announcements—seasonal deals, bonus point events, or special promotions—so you do not miss opportunities that your store enables for you.';

  @override
  String get aboutUsFairnessTitle => 'Approvals, transparency, and support';

  @override
  String get aboutUsFairnessBody => 'Reviews can take a short time because each bill is checked carefully. If something is rejected, you should see a reason or get guidance from your store’s team. For login, PIN, profile, or notification issues, use the options inside the app and contact your store when needed. We focus on clear rules and visible status for pending, approved, and rejected bills.';

  @override
  String get aboutUsStoresTitle => 'Your store, your program';

  @override
  String get aboutUsStoresBody => 'Points, tiers, and offers are tied to the hardware store you joined in this app. Different stores may use different rules, conversion rates, and benefits. If you buy from more than one participating store, each relationship is usually separate unless the stores tell you otherwise—always confirm details with the store that enrolled you.';

  @override
  String get aboutUsClosing => 'Thank you for using Balaji Points—we are proud to support carpenters and the stores that partner with you.';

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
  String get onboardingSlide1Body => 'Upload your hardware purchase bills. When your store approves them, points are added to your wallet.';

  @override
  String get onboardingSlide2Title => 'Track your rewards';

  @override
  String get onboardingSlide2Body => 'See your balance, tier, and leaderboard rank. Browse offers made for carpenters like you.';

  @override
  String get onboardingSlide3Title => 'Stay in the loop';

  @override
  String get onboardingSlide3Body => 'Get notified when bills are approved or rejected. Manage your profile and preferences anytime.';
}
