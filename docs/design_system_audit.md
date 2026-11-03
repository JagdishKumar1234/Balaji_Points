# Balaji Points Design System Audit

**Audit date:** 3 November 2026  
**Branch reviewed:** `latest_code`  
**Scope:** Flutter design tokens, theme configuration, shared UI primitives, responsive helpers, and representative authentication, role-navigation, and super-admin screens.

## Executive summary

The project has a substantial foundation for a reusable design system: Material 3 is enabled in both themes, the app defines color, spacing, radius, typography, and animation tokens, and shared button, card, text-field, text, loader, and status widgets exist. Responsive width and navigation helpers are also in place.

The main gap is **adoption and consistency**. The codebase contains parallel color systems and direct widget styling alongside the canonical tokens. Several shared components use fixed light/brand colors that do not follow the selected palette or dark theme. Typography and localization behavior are also inconsistent between token-based and raw Flutter widgets. As a result, a screen can look correct in one role or theme and diverge in another.

This is a source review, not a full visual QA pass. Counts below are broad source-search indicators, not AST-based component coverage measurements. No device screenshots, accessibility scanner, or automated UI tests were run for this audit.

## What is already working well

- `lib/core/design/app_theme.dart` configures light and dark `ThemeData` with `useMaterial3: true`, including surfaces, buttons, inputs, dialogs, chips, navigation, and app bars.
- `lib/core/design/app_colors.dart` contains named brand, status, surface, text, and palette values, with `BuildContext` helpers for theme-aware colors.
- `lib/core/design/app_spacing.dart` and `lib/core/design/app_radius.dart` give the app named spacing and shape scales. The documented common field and button targets are 56 and 54 dp.
- `lib/core/design/app_typography.dart` centralizes Inter styles and supplies a Material `TextTheme`. `ResponsiveTypography` and `ResponsiveContainer` provide responsive helpers.
- Shared primitives exist under `lib/presentation/widgets/shared/`, including `AppButton`, `AppCard`, `AppTextField`, `AppText`, `AppLoader`, and `StatusChip`.
- `ResponsiveRoleNavigation` uses Material 3 `NavigationRail` on wide layouts, and theme preferences support six named palettes.
- The project defines animation durations and common entrance/feedback effects in `lib/core/design/app_animations.dart`.

## Findings

### High priority: multiple competing color systems

`AppColors` is presented as the canonical color source, but `lib/core/design/app_theme_palette.dart` defines a second complete set of palette, text, surface, and gradient colors. The second file uses different navy/blue, gold, and background values. This makes it unclear which tokens new screens should use and creates the possibility of nearly-but-not-quite matching colors.

There are also **87** direct `Color(0x...)` matches and **393** `Colors.white/black/grey/blue/red/green` matches in `lib/presentation/`. These broad counts include legitimate branded or illustrative uses, but they show that color use is not fully routed through the theme. Not all direct colors should be eliminated: Google branding and celebration illustrations may need fixed brand colors. Such exceptions should be named and documented.

**Recommendation:** declare `AppColors` plus `ColorScheme` the single source of truth. Inventory references to `ThemePalette` and migrate or remove it; document explicit fixed-brand exceptions; use semantic `ColorScheme` colors for interactive states.

### High priority: selected palettes are not applied consistently

`AppThemeData.light/dark` receives the selected palette and changes `colorScheme.primary`, but some components bypass that value. Examples include:

- `AppCard.primary` paints `AppColors.primary` directly instead of the current `colorScheme.primary`.
- `ResponsiveRoleNavigation` uses the fixed `AppColors.navigation` rail and fixed navy selection colors.
- Some shimmer/loading placeholders use `AppColors.white`, which can appear as a light tile in dark mode.
- Status colors are fixed semantic constants, which is reasonable for meaning, but surrounding surface and text decisions should still follow the current theme.

Consequently palette selection is partial: controls that read `context.themePrimary` can change while other branded surfaces remain navy. Dark mode is similarly at risk wherever a shared widget hard-codes white or black.

**Recommendation:** audit shared widgets first and use `ColorScheme` or `context.theme*` values for theme-dependent colors. Reserve fixed colors for explicit status semantics and third-party brand marks.

### Medium priority: typography contract differs from implementation

`AppTypography` documents a five-style scale and says standard body copy is 14 px regular, but the `body()` factory uses `FontWeight.w500`. The Material `TextTheme` maps `bodyMedium` to secondary text and `bodySmall` to muted text, while `AppText.body` defaults to primary text and its caption defaults to secondary. This means equivalent text can change weight and contrast depending on whether it uses `Text`, `AppText`, or a helper style.

`ResponsiveTypography` defines device-scaled sizes, but much of the app uses fixed token sizes or local `TextStyle` values. That is not automatically wrong—fixed type scales often improve consistency—but the intended relationship between responsive type helpers and canonical text styles is unclear.

**Recommendation:** publish a small semantic type table (display/title/section/body/label/caption) with size, weight, line height, and default color. Align `AppTypography`, `TextTheme`, and `AppText` defaults. Define where text scaling is responsive and where platform accessibility scaling is expected to take precedence.

### Medium priority: shared widgets are optional in real screen code

The shared primitives are useful, but representative screens still construct `ElevatedButton`, `OutlinedButton`, `TextButton`, `Text`, `Container`, and inline decorations directly. In `lib/presentation/`, a broad search found **562** direct `TextStyle(...)`/common fixed-color patterns and many local shape and padding values. These are noisy indicators (not every instance is an issue), but screen authors can bypass shared behavior such as minimum touch sizes, disabled states, palette colors, and component typography.

Examples include the super-admin screen's locally styled logout dialog and tab/navigation controls, and the recent login page's bespoke Google button. Specialized controls are expected, but there is no short usage guide indicating when to use a core component and when to create an exception.

**Recommendation:** add contribution guidance and expand shared primitives only where repeated patterns exist. Set shared button/input states and minimum heights in theme or primitive APIs, and retain custom Material 3 widgets for clearly documented special cases.

### Medium priority: localization is not consistently part of the design workflow

The project has English, Hindi, and Tamil ARB files, but representative auth and super-admin screens include literal user-facing labels and validation messages. A source scan found **180** `Text('...')`/`Text("...")` matches in screens; the count includes non-user-facing and test-like strings, so it is a review queue rather than a definitive untranslated-string total. The recently updated login screen itself contains several literal labels.

This is both a localization and layout concern: translations can be longer than English, but fixed labels, max lines, and constrained controls are not consistently checked against translated copy.

**Recommendation:** require new visible strings to use generated `AppLocalizations`; migrate existing screens by user journey, starting with authentication and primary role navigation. Review long Hindi/Tamil labels at narrow widths and with large system text.

### Medium priority: responsive helpers need validation at real layout boundaries

`ResponsiveBreakpoints` has clear 600/840/1200/1600 logical-pixel thresholds and `ResponsiveContainer` can constrain wide content. `ResponsiveRoleNavigation` switches to a rail at tablet width. However, breakpoints are used alongside `MediaQuery` checks, local screen-specific thresholds, and fixed layout dimensions. That creates a risk of abrupt layout changes or overflow near the boundaries, particularly on landscape phones, split-screen windows, and larger text scales.

The recent login screen uses a height-dependent compact mode and keeps a scroll view available. This is a reasonable keyboard fallback, but source inspection alone cannot confirm that every supported phone height fits without scrolling.

**Recommendation:** standardize on width-based layout decisions, use `LayoutBuilder` where constraints differ from full-screen size, and visually verify representative screens just below/above each breakpoint, in landscape, with keyboard open, and with 1.3–1.5 text scaling.

### Low priority: animation and loading affordances are not uniform

The project has reusable animation tokens, shimmer placeholders, inline/full-screen loaders, and per-screen loading patterns. A broad screen search found **59** loader/shimmer references and **147** loading/state-related references. This indicates that loading UI exists, but not that all asynchronous sections use the same first-load, refresh, empty, and error treatment. Some shared shimmer placeholders are also fixed white, as noted above.

**Recommendation:** define a reusable screen/section state pattern (initial loading, refreshing, empty, recoverable error) and use skeletons only for content-shaped loading. Keep animations short and respect reduced-motion settings where available.

### Low priority: shape and spacing rules are not enforced

The canonical radius file documents 16 dp as the common radius, with small, sheet, and pill exceptions. Yet screen code contains many local `BorderRadius.circular(...)`, padding values, and raw `SizedBox` dimensions. This allows gradual drift, although local values are sometimes necessary for bespoke layout.

**Recommendation:** preserve the current token scale, replace repeated local values with tokens, and document the few approved exceptions rather than making every dimension a token.

## Prioritized follow-up plan

1. **Consolidate color ownership:** choose `AppColors`/`ColorScheme`, map or retire `ThemePalette`, and fix palette/dark-mode leakage in shared widgets.
2. **Set component contracts:** define button, field, card, chip, loading, and navigation behaviors, including touch-target and disabled/loading states.
3. **Align typography:** resolve the documented-vs-implemented weight/color differences and specify the canonical semantic scale.
4. **Localize primary flows:** auth, onboarding, role navigation, and high-frequency dashboard actions first; test longer translations.
5. **Run visual responsive QA:** test representative carpenter, branch admin, and super-admin screens across phone/tablet/desktop widths, light/dark modes, and larger text settings.
6. **Add guardrails:** contribution notes and lint/review checks for new raw palette colors and visible hard-coded strings, allowing documented brand exceptions.

## Review method and limitations

The audit inspected the design token and theme files, shared widgets, responsive helpers, and representative login and super-admin screens. Searches counted patterns under `lib/presentation/` to identify likely drift. These searches are deliberately described as indicators because they do not distinguish every intentional icon, status color, branding element, or non-visible string. No code was changed as part of the audit, and no test or build was run.

## Remediation progress — 3 November 2026

The first remediation pass has started on the shared theme and button layer:

- Removed the unused parallel `app_theme_palette.dart` color and gradient system. A repository search found no imports or consumers outside that file; `AppColors` and `ColorScheme` remain the app's palette source.
- Material button themes now define clear palette-aware enabled colors, explicit light/dark disabled colors, and 48 dp minimum targets for Elevated, Filled, Outlined, Text, and Icon buttons.
- `AppButton` now reads colors from `ColorScheme`, keeps disabled labels readable, and exposes the already-supported danger variant through a named constructor.
- Darkened action, error, success, and palette primary tokens to retain readable foreground contrast. Static WCAG contrast calculations for the resulting pairs are: action/white **5.61:1**, error/white **6.54:1**, success/white **5.02:1**, gold/navy **5.82:1**; all six palette primary colors exceed **5:1** with their selected on-primary color.
- Updated gold-background actions to use the dark on-secondary color, and fixed the warning-colored Reset PIN, discard, and status-filter buttons to choose a contrasting foreground.
- Primary cards, shimmer surfaces, and role navigation now use theme-aware colors rather than fixed navy/white values where the surface is theme-dependent.

**Validation:** `flutter analyze` completed with no errors. It still reports 54 existing info/warning diagnostics elsewhere in the project. `git diff --check` passes. No app screenshots or on-device visual checks have been run yet.

**Still pending:** typography and `TextTheme` alignment; migration of remaining raw color literals and visible strings; responsive checks at real device widths and larger system text; unified empty/error/loading states; and a screen-by-screen visual review of custom button styles that override the shared themes.
