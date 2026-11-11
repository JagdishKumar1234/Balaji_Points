import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/auth/forgot_password_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/phone_pin_entry_page.dart';
import 'package:balaji_points/presentation/screens/common/info/about_us_page.dart';
import 'package:balaji_points/presentation/screens/common/info/legal_document_page.dart';
import 'package:balaji_points/presentation/widgets/shared/legal_consent_checkbox.dart';
import 'package:balaji_points/presentation/screens/common/onboarding/onboarding_page.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_table_card.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/presentation/widgets/shared/responsive_role_navigation.dart';
import 'package:balaji_points/presentation/widgets/shared/stat_card.dart';
import 'package:balaji_points/presentation/widgets/shared/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Renders screens and shared components across phone → desktop widths, both
/// themes, 1.0× / 1.3× text and all three languages (Tamil strings are the
/// longest) and fails on any RenderFlex overflow or layout exception.
///
/// Uses the bundled Nunito files (assets/google_fonts), so text metrics match
/// the real app.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const widths = [320.0, 390.0, 600.0, 840.0, 1280.0];
  const scales = [1.0, 1.3];
  const locales = [Locale('en'), Locale('hi'), Locale('ta')];

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required double width,
    required double scale,
    required Locale locale,
    required bool dark,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemeData.light(),
          darkTheme: AppThemeData.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          supportedLocales: locales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, w) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: w!,
          ),
          home: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  final cases = <String, Widget Function()>{
    'onboarding': () => const OnboardingPage(),
    'about us': () => const AboutUsPage(),
    'terms': () => const LegalDocumentPage(document: LegalDocument.terms),
    'privacy': () => const LegalDocumentPage(document: LegalDocument.privacy),
    'legal consent': () => Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LegalConsentCheckbox(
          value: false,
          showError: true,
          onChanged: (_) {},
        ),
      ),
    ),
    'phone PIN entry': () => const PhonePinEntryPage(),
    'forgot password': () => const ForgotPasswordPage(),
    'components': () => const _ComponentGallery(),
    'role navigation shell': () => ResponsiveRoleNavigation(
      roleLabel: 'Branch admin',
      selectedIndex: 0,
      onSelected: (_) {},
      onLogout: () {},
      items: const [
        RoleNavigationItem(
          label: 'Dashboard',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        RoleNavigationItem(
          label: 'Pending bills',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
      ],
      child: const Scaffold(body: _ComponentGallery()),
    ),
  };

  for (final entry in cases.entries) {
    group(entry.key, () {
      for (final width in widths) {
        for (final scale in scales) {
          for (final locale in locales) {
            for (final dark in [false, true]) {
              final name =
                  '${width.toInt()}px · ${scale}x · ${locale.languageCode} · '
                  '${dark ? 'dark' : 'light'}';
              testWidgets(name, (tester) async {
                await pumpAt(
                  tester,
                  entry.value(),
                  width: width,
                  scale: scale,
                  locale: locale,
                  dark: dark,
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${entry.key} has a layout error at $name',
                );
              });
            }
          }
        }
      }
    });
  }
}

/// Every shared component the screens are built from, in one scroll view.
class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      bottomNavigationBar: CarpenterBottomNavBar(
        currentIndex: 1,
        onTabSelected: (_) {},
        onAddBillTap: () {},
        bottomInset: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (label, value) in [
                  (l10n.statCarpenters, '1,000'),
                  (l10n.statPendingBills, '12'),
                  (l10n.statBillsThisMonth, '348'),
                  (l10n.statPointsIssued, '12,450.75'),
                ])
                  SizedBox(
                    width: 160,
                    child: StatCard(
                      label: label,
                      value: value,
                      caption: l10n.statThisMonth,
                      icon: Icons.groups_rounded,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.noBillsYet,
              message: l10n.submitFirstBill,
              actionLabel: l10n.addBill,
              onAction: () {},
            ),
            const SizedBox(height: 16),
            AppButton.primary(label: l10n.submitBill, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.secondary(label: l10n.cancel, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.danger(label: l10n.deleteAll, onPressed: () {}),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(status: 'approved', showIcon: true),
                StatusChip(status: 'pending', showIcon: true),
                StatusChip(status: 'rejected', showIcon: true),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: l10n.siteNameLabel,
                hintText: l10n.siteNameLabel,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 420,
              child: AppTableCard(
                columns: [
                  DataColumn(label: Text(l10n.siteNameLabel)),
                  DataColumn(label: Text(l10n.amountLabel), numeric: true),
                  DataColumn(label: Text(l10n.pointsLabel), numeric: true),
                ],
                rows: [
                  for (var i = 0; i < 25; i++)
                    DataRow(
                      cells: [
                        DataCell(Text('Site $i')),
                        DataCell(Text('${i * 1000}')),
                        DataCell(Text('${i.toDouble()}')),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
