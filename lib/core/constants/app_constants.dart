/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Balaji Points';
  static const String appVersion = '1.0.0';
  static const String appConfigCollection = 'app_config';
  static const String appConfigDocument = 'version';

  // Points Conversion
  static const int pointsPerThousandRupees = 1;
  static const String pointsConversionText = '1000 ₹ = 1 Point';

  // Contact Information
  static const String supportPhone1 = '96006-09121';
  static const String supportPhone2 = '0424-3557187';
  static const String supportEmail = 'support@balajipoints.com';

  // Validation Limits
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int phoneNumberLength = 10;
  static const int otpLength = 6;
  static const int minBillAmount = 1;
  static const int maxBillAmount = 1000000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int topCarpenterLimit = 3;
  static const int offerCarouselAutoPlayDelay = 5; // seconds

  // Timeouts
  static const int otpResendTimeout = 60; // seconds
  static const int phoneAuthTimeout = 60; // seconds
  static const int dailySpinCooldown = 24; // hours
  static const int networkTimeout = 30; // seconds

  // Animation Durations
  static const int shortAnimationMs = 300;
  static const int mediumAnimationMs = 500;
  static const int longAnimationMs = 1000;
  static const int spinAnimationSeconds = 3;

  // UI Dimensions
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Image Constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85; // 0-100
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;

  // Firebase Collection Names
  static const String usersCollection = 'users';
  static const String billsCollection = 'bills';
  static const String offersCollection = 'offers';
  static const String transactionsCollection = 'transactions';
  static const String dailyPrizeWinnersCollection = 'daily_prize_winners';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleCarpenter = 'carpenter';

  // Bill Status
  static const String billStatusPending = 'pending';
  static const String billStatusApproved = 'approved';
  static const String billStatusRejected = 'rejected';

  // Transaction Types
  static const String transactionTypeEarned = 'earned';
  static const String transactionTypeSpent = 'spent';
  static const String transactionTypePending = 'pending';

  // Offer Types
  static const String offerTypeBanner = 'banner';
  static const String offerTypeBasic = 'basic';
  static const String offerTypeFullWidth = 'full_width';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String billImagesPath = 'bill_images';
  static const String offerImagesPath = 'offer_images';

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'hh:mm a';

  // Regex Patterns
  static const String phoneRegex = r'^[0-9]+$';
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String nameRegex = r'^[a-zA-Z ]+$';

  // Error Messages (for fallback when localization fails)
  static const String defaultError = 'An error occurred';
  static const String networkError =
      'Network error. Please check your internet connection.';
  static const String permissionDenied = 'Permission denied';
  static const String sessionExpired = 'Session expired. Please login again.';

  // Shop / App bar display
  static const String shopNameShort = 'Sri Balaji Plywood & Hardware';
  static const String shopAddressShort = '150 VCTV Main Road, Erode';

  // Assets Paths
  static const String logoPath = 'assets/images/balaji_point_logo.png';
  static const String placeholderImagePath = 'assets/images/placeholder.png';

  // Shared Preferences Keys
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserId = 'userId';
  static const String keyUserRole = 'userRole';
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguage = 'language';

  // Deep Link Routes
  static const String deepLinkOffer = 'offer';
  static const String deepLinkSpin = 'spin';
  static const String deepLinkProfile = 'profile';

  // Feature Flags
  static const bool enableDailySpin = true;
  static const bool enableOffers = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
}
