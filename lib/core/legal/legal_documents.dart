import 'package:balaji_points/core/constants/app_constants.dart';

/// The app's Terms and Conditions and Privacy Policy.
///
/// When either text changes in a way members must agree to again, raise
/// [LegalDocuments.version]; new registrations store the version they
/// accepted (`termsVersion` on the user record).
class LegalDocuments {
  LegalDocuments._();

  static const String version = '2026-11-11';
  static const String effectiveDate = '11 November 2026';

  static const String company = AppConstants.companyName;
  static const String supportEmail = AppConstants.supportEmail;
  static const String supportPhone = '+91 ${AppConstants.supportPhoneDisplay}';

  static const List<LegalSection> terms = [
    LegalSection(
      'About these terms',
      '$company ("the app", "we", "us") is a loyalty and rewards '
          'programme for members who buy from its partner stores and their '
          'branches in Tamil Nadu ("your branch"). '
          'By creating an account or using the app you agree to these Terms '
          'and Conditions and to our Privacy Policy. If you do not agree, '
          'please do not use the app.',
    ),
    LegalSection(
      'Who can join',
      'The programme is open to carpenters, architects, engineers and '
          'interior designers who buy from a partner branch, are at least 18 years '
          'old and live in India. Each person may have one account, linked '
          'to one branch. Branch staff accounts are created only by us.',
    ),
    LegalSection(
      'Your account',
      '• Give your real name, mobile number and correct details.\n'
          '• Keep your PIN and password secret. Do not share your account.\n'
          '• You are responsible for everything done with your account.\n'
          '• Tell us at once if you think someone else is using it.',
    ),
    LegalSection(
      'Submitting bills',
      '• Submit only genuine purchase bills from your branch, in your own '
          'name or for your own site work.\n'
          '• Each bill can earn points only once. Duplicate, altered, '
          'returned or cancelled bills are not accepted.\n'
          '• Every bill is checked and approved or rejected by the branch. '
          'The branch\'s decision is final.\n'
          '• Bill photos and details you submit may be kept as a record.',
    ),
    LegalSection(
      'Balaji Points',
      '• Points are earned at the rate set for your role and shown in the '
          'app (for example 1 point for every ₹1,000 of approved purchases '
          'for carpenters and interior designers, and 1 point for every '
          '₹5,000 for architects and engineers).\n'
          '• Points have no cash value, cannot be sold or transferred, and '
          'cannot be exchanged for money.\n'
          '• Points may be reversed if a bill is returned, cancelled, found '
          'to be wrong, or approved by mistake.\n'
          '• Points may be reset at the end of a programme season (for '
          'example, after rewards are given). Members are told in advance.',
    ),
    LegalSection(
      'Offers and rewards',
      '• Each offer shows its points target and any extra conditions. '
          'Reaching a target makes you eligible; the reward is confirmed and '
          'given by your branch.\n'
          '• Rewards are subject to availability. A similar item or trip of '
          'equal value may be given, and travel dates are arranged with '
          'your branch.\n'
          '• Offers are for a branch\'s members, may have an end date, and may '
          'be changed or withdrawn.\n'
          '• Any taxes, travel documents or costs not stated in the offer are '
          'the member\'s responsibility.\n'
          '• Product names and images in offers belong to their owners and '
          'are shown only to describe the reward.',
    ),
    LegalSection(
      'Daily spin and winners',
      'The daily spin picks a winner at random from members whose bills '
          'were approved that day in the same branch. Winners are shown to '
          'members of that branch. Prizes, if any, are as announced by the '
          'branch.',
    ),
    LegalSection(
      'Notifications',
      'We send notifications about your bills, points, offers and store '
          'announcements. You can turn notifications off in your phone\'s '
          'settings; important account messages also appear inside the app.',
    ),
    LegalSection(
      'Fair use',
      'Do not misuse the app: no false bills, fake accounts, attempts to '
          'access other members\' data, or interfering with the app. We may '
          'suspend or close accounts that break these terms, and cancel '
          'points earned through misuse.',
    ),
    LegalSection(
      'Changes and ending the programme',
      'We may update the app, these terms, the points rate or the '
          'programme. We will show important changes in the app. Continuing '
          'to use the app after a change means you accept it. We may end the '
          'programme with reasonable notice to members.',
    ),
    LegalSection(
      'Our responsibility',
      'The app is provided "as is". We work to keep it available and '
          'correct, but cannot promise it will always be error-free. To the '
          'extent the law allows, we are not liable for indirect losses '
          'from using the app. Nothing in these terms limits rights you have '
          'under Indian consumer law.',
    ),
    LegalSection(
      'Law and disputes',
      'These terms are governed by the laws of India. Disputes will first '
          'be settled by talking with us; if that fails, the courts '
          'of Erode, Tamil Nadu, will have jurisdiction.',
    ),
    LegalSection(
      'Contact',
      'Email: $supportEmail\n'
          'Phone: $supportPhone',
    ),
  ];

  static const List<LegalSection> privacy = [
    LegalSection(
      'Who we are',
      '$company runs this app. This policy explains what '
          'personal data we collect, why, and the choices you have. It '
          'follows India\'s Digital Personal Data Protection Act, 2023 and '
          'the Information Technology Act, 2000.',
    ),
    LegalSection(
      'What we collect',
      '• Account details: name, mobile number, email (if you use one), '
          'role (carpenter, architect, engineer or interior designer) and '
          'branch.\n'
          '• Profile photo, if you add one.\n'
          '• Your PIN or password, stored only in a protected, one-way '
          'scrambled form that cannot be read back.\n'
          '• Bills you submit: photo, amount, date, site name and vendor.\n'
          '• Programme records: points, tier, rank, bill history, daily spin '
          'results and notifications sent to you.\n'
          '• Device data: a push-notification token, app version, device '
          'model and operating system.\n'
          '• Usage and crash data: which screens are opened and crash '
          'reports, linked to a random ID, not to your name or number.',
    ),
    LegalSection(
      'Phone permissions',
      '• Camera and photos: only when you choose to add a bill photo or '
          'profile photo.\n'
          '• Notifications: to tell you about bills, points and offers.\n'
          '• Fingerprint or face unlock (optional): checked by your phone '
          'itself; we never receive your fingerprint or face data.',
    ),
    LegalSection(
      'Why we use it',
      '• To create and secure your account and let you sign in.\n'
          '• To check bills, credit points, run offers and the daily spin.\n'
          '• To show branch rankings: your name, photo and points are shown '
          'to other members of your branch.\n'
          '• To send you notifications about your account and offers.\n'
          '• To keep the app working, fix crashes and prevent fraud.\n'
          'We do not sell your data and do not use it for outside '
          'advertising.',
    ),
    LegalSection(
      'Who can see it',
      '• Your branch\'s staff: your profile, bills and points, to run the '
          'programme.\n'
          '• Other members of your branch: your name, photo, points and rank '
          'on the leaderboard, and daily winner names.\n'
          '• Service providers who host the app for us: Google Firebase '
          '(sign-in, database, file storage, notifications, analytics and '
          'crash reports). Data may be stored on Google\'s servers inside or '
          'outside India, under Google\'s security and privacy terms.\n'
          '• Authorities, only when the law requires it.',
    ),
    LegalSection(
      'How long we keep it',
      'We keep your data while your account is active and for as long as '
          'needed for the programme, accounting and legal requirements. When '
          'a season ends, points and bill history may be cleared. If your '
          'account is deleted, your profile, points and bills are removed, '
          'except records we must keep by law.',
    ),
    LegalSection(
      'Security',
      'Data is sent over encrypted connections and protected by access '
          'rules so members see only what they should. PINs and passwords '
          'are never stored in readable form. No system is perfectly secure; '
          'keep your PIN private and tell us if you notice anything wrong.',
    ),
    LegalSection(
      'Your rights and choices',
      '• See and correct your details in Profile › Edit Profile.\n'
          '• Ask us for a copy of your data, to correct it, or to delete your '
          'account, by contacting us below.\n'
          '• Withdraw consent at any time by asking us to delete your '
          'account. You will then no longer be able to take part in the '
          'programme.\n'
          '• Turn notifications off in your phone\'s settings.',
    ),
    LegalSection(
      'Children',
      'The app is for working professionals aged 18 and over. We do not '
          'knowingly collect data from children.',
    ),
    LegalSection(
      'Changes to this policy',
      'We may update this policy. The date at the top shows the latest '
          'version, and important changes will be shown in the app.',
    ),
    LegalSection(
      'Contact and grievances',
      'For privacy questions, data requests or complaints, contact our '
          'grievance contact:\n'
          'Email: $supportEmail\n'
          'Phone: $supportPhone\n'
          'We reply within 30 days.',
    ),
  ];
}

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}
