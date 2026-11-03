# UI Spec Conformance Audit — Flutter app vs "Carpenter Rewards App – UI Design"

**Date:** 3 November 2026 · **Branch:** `latest_code` (includes uncommitted theme changes)
**Spec source:** `docs/Carpenter Rewards App – UI Design.html` (23 screens, unpacked and CSS extracted; the PDF is the same board rendered)
**Companion doc:** `docs/design_system_audit.md` (code-only audit + first remediation pass)

This audit compares the code's design tokens, theme, and shared components with the spec's real values. It also reviews responsiveness and ease of use. It is a source and spec review. No screenshots or on-device runs were made.

---

## 1. Verdict at a glance

| Area | Status | One-line reason |
|---|---|---|
| Brand colors | ❌ Off-spec | Navy, gold, borders and text colors all differ from the spec. Two values came from the design *board's* page background, not from the app screens |
| Dark theme | ❌ Off-spec + a11y bug | Neutral grey-black instead of the spec's navy-black. Primary stays dark navy in dark mode, giving 1.4:1 contrast on 374 call sites |
| Buttons | ⚠️ Off-spec | Spec: pill (radius 24), gold fill with navy text for main CTAs. Code: radius 16, navy fill |
| Inputs | ⚠️ Off-spec | Spec: 48 high, radius 12, border `#CBD1DB`. Code: 56 high, radius 16, border `#E1E4E9` |
| Cards | ✅ Close | Radius 16 and a 1px border match. Shadow and border color differ slightly |
| Status chips | ⚠️ Off-spec | Spec uses tinted pairs (bg + dark text). Code uses saturated fills like `warning #F59E0B`, which has 2.1:1 contrast on white |
| Typography | ⚠️ Partial | Inter matches. Heading weights and sizes differ (spec headings 700, code 600; spec hero 40, code 32) |
| Navigation | ⚠️ Off-spec | Spec desktop sidebar is navy with a gold active bar. Code rail is white |
| Responsive | ❌ Weak | Responsive helpers appear only 16 times in 81 presentation files, and `LayoutBuilder` only twice. Admin desktop layout rules are not implemented |
| Accessibility | ❌ Fails | Muted text is 2.6:1. There are 73 font sizes under 12px. Text scaling is not handled. One wrong tooltip |
| Ease of use | ⚠️ | 194 hard-coded strings. 34 gradients (both the spec and `AppColors` say "no gradients"). 2,000-line screens with local styling |

---

## 2. Color tokens — spec vs code

Colors were extracted from all 23 screen stylesheets. The number in brackets is how often the spec uses the color.

### 2.1 Light theme

| Role | **Spec** | **Code (`AppColors`)** | Action |
|---|---|---|---|
| Primary / navy (header, sidebar, headings, icon tiles) | `#0B1F3A` (129) | `primary #082D6B` | **Change** to `#0B1F3A` |
| Navy hover / active nav item | `#16325C` (13) | `primaryLight #174A91` | **Change** |
| Navy line / progress track on navy | `#2B4570` | — | Add `primaryLine` |
| Accent gold (main CTA, icons, progress) | `#C9A24B` (70) | `gold #C49143` | **Change** |
| Gold soft (nav pill, chip bg) | `#FBF0D3` (26) | `goldSoft #FAF1E3` | **Change** |
| Page background | `#F4F5F7` (22) | `background #F5F4EF` ⚠️ | **Change**. `#F5F4EF` is the design *board's* canvas (`html{background:#f5f4ef}`), not an app color |
| Surface | `#FFFFFF` | `#FFFFFF` | ✅ |
| Card border / divider | `#E3E6EB` (48) | `border #E1E4E9` | Change (near-match) |
| Input / outline-button border | `#CBD1DB` (46) | *(uses `border`)* | **Add** `borderStrong` |
| Table row divider | `#EEF0F3` (30) | `softSurface #F1F2F4` | Add `divider` |
| Text primary (body ink) | `#1B2433` (44) | `textPrimary #1F1E1D` ⚠️ | **Change**. `#1F1E1D` is also the board's ink, not the app's |
| Text secondary / labels / meta | `#5B6577` (85) | `textSecondary #5F6672` | Change (near-match) |
| Text on navy | `#C9D3E3` (34) | — | **Add** `onPrimaryMuted` |
| Text muted | *(spec never goes lighter than `#5B6577` on white)* | `textMuted #98A2B3` → **2.6:1, fails** | Raise to ≥ 4.5:1 or restrict to disabled states |
| Success chip bg / text | `#E6F2EA` / `#1C5B34` | `success #15803D` (fill only) | **Add** tinted pair |
| Pending chip bg / text | `#FBF0D3` / `#6B4D08` | `warning #F59E0B` (fill) | **Add** tinted pair. Stop using `warning` for text or icons on white |
| Rejected chip bg / text | `#F6DCDA` / `#8C1D18` | `error #B3261E` | **Add** tinted pair |
| Destructive button outline | `#B3261E` | `error #B3261E` | ✅ |
| Crimson "action" | *not in spec* | `action #C82043` (0 uses in `presentation/`, but wired to `colorScheme.tertiary`) | Remove |

### 2.2 Dark theme (spec screen "Wallet dark")

| Role | **Spec** | **Code** | Action |
|---|---|---|---|
| Background | `#0B1220` | `darkBackground #0F1115` | **Change**. The spec is navy-tinted, the code is neutral |
| App bar / bottom nav | `#121B2D` | *(uses surface)* | Add `darkChrome` |
| Card surface | `#162033` | `darkSurface #171A22` | **Change** |
| Raised chip / points pill | `#1F2A40` | `darkSoftSurface #1E2430` | Change |
| Border | `#26324A` | `darkBorder #2B313D` | Change |
| Text primary | `#E8ECF3` | `#FFFFFF` | Change (softer white reduces glare) |
| Text muted / labels | `#9AA6BA` | `#9CA3AF` | Change (near-match) |
| Status chips | ok `#14301F`/`#7FD39B` · pending `#3A2E0F`/`#E9C46A` · rejected `#3B1816`/`#F2A19B` | none | **Add** |
| Brand card | Navy `#0B1F3A` with gold accents | — | Keep navy as a *surface* only |

**Critical dark-mode bug:** `ColorScheme.dark(primary: colors.primary)` keeps navy `#082D6B` as primary. Every `context.themePrimary` used as a text, icon or selected-nav color (**374 call sites**) renders navy on near-black, at **1.44:1** contrast. The carpenter bottom nav's selected state is affected ([carpenter_bottom_nav_bar.dart:138](lib/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart#L138)). The spec uses `#E8ECF3` for active text and gold for accents in dark mode. Fix it at the theme level: in dark mode, map `primary` to a light tone (for example `#E8ECF3` or gold `#C9A24B`) and keep navy only as a container color (`primaryContainer`).

**Spec defects in the dark mockup itself (do not copy them):** the dark-mode inputs and the "Filter" outline button still have a **white background with light text**, and the navy FAB sits on a navy-black bar. Use dark surface `#162033` with border `#26324A` for those.

---

## 3. Component specs — spec vs code

| Component | **Spec** | **Code** | Gap |
|---|---|---|---|
| **Primary CTA** | Gold `#C9A24B`, navy text, 15/600, **height 48 (hero CTA 52), pill radius 24** | `ElevatedButton` navy fill, white text, radius 16, min height 48, `AppButton` 54 | Shape and color hierarchy differ. Main CTAs should be the gold variant |
| Secondary button | White, 1px `#CBD1DB`, navy text, pill | Outlined: 1.5px **primary** border, radius 16 | Border too heavy and wrong color |
| Destructive | White, 1px `#B3261E` border and text, pill | `AppButton.danger` red fill | Spec uses outline for destructive actions (calmer, needs deliberate intent) |
| Compact table button | 36 high, radius 18, 13/600 | none | Add `AppButton.small`. Note 36 < 48 touch target; fine on desktop tables only |
| Text input | **48 high**, radius **12**, 1px `#CBD1DB`, 15px text, label above (12/600 `#5B6577`) | 56 min height, radius 16, `#E1E4E9`, floating label 14/500 | Labels-above is the spec pattern. Inputs too tall and too round |
| Card | White, 1px `#E3E6EB`, radius 16, padding 16–18, shadow `0 1 2 rgba(11,31,58,.06)` | Radius 16, 1px border, shadow `0 8 24 black/.05` | Spec shadow is tighter and navy-tinted |
| Points / hero card | Radius 20, padding 20, value 40/700 navy, shadow `0 2 6 rgba(11,31,58,.10)` | hero 32/700 | Number too small for the most important figure |
| Status chip | 11–12/600, padding 3–4 × 8–10, **radius 8–10**, tinted pair | `ChipTheme` StadiumBorder, soft-surface bg | Shape and color semantics differ |
| Quick-action tile | 88 high, radius 16, 32×32 navy icon tile (radius 10) with gold glyph, 13/600 label, 3-column grid, gap 10 | varies per screen | Make a shared `QuickActionTile` |
| Empty state | White, **1px dashed `#CBD1DB`**, radius 16, 13px `#5B6577`, centered, says what will appear | per screen | Make a shared `EmptyState` |
| Mobile header | Navy `#0B1F3A`, 28/24 padding, bottom radius 24–28, title 22–26/700 white, subtitle 14 `#C9D3E3` | AppBar uses the light background | Spec headers are navy for auth, home and register |
| Bottom nav | White, top border `#E3E6EB`, **68 high**, 11/600 labels, active = navy text on `#FBF0D3` pill | `NavigationBarTheme` 72, `bottomNavHeight` 64, active primary-soft | Three different heights in code (64/68/72). Pick 68 |
| Desktop sidebar | **232 wide, navy `#0B1F3A`**, items 14/500 `#C9D3E3`, radius 12, active `#16325C` + **3px gold inset bar** | `NavigationRail` white surface, 264 / 80 wide, primary-soft indicator | Not the spec look |
| Data table | 14px rows, header 12/600 `#5B6577`, `#E3E6EB` header line, `#EEF0F3` row lines, 12/6 cell padding, horizontal scroll with `min-width:520`, "Page 1 · 20 per page" + Prev/Next | `DataTable` in 2 admin lists. Pagination deferred | Pagination is part of the spec |

---

## 4. Typography — spec vs code

Both use **Inter** ✅. Sizes and weights differ:

| Use | **Spec** | **Code (`AppTypography`)** |
|---|---|---|
| Points hero number | 40 / 700 | `pointsHero` 32 / 700 |
| Auth page title | 26 / 700 | `hero` 32 / 700 or `title` 20 / 600 |
| Screen title (mobile header) | 22–24 / 700 | `title` 20 / **600** |
| Desktop page H1 | 24 / 700 navy | — |
| Stat value (dashboard) | 30 / 700 navy | — |
| Section heading | 16 / **700** | `section` 16 / **600** |
| Input text / button | 15 / 400, 15 / 600 | body 14 / 500, button 14–16 / 600 |
| Body / description | 13–14 / 400, line height 1.4–1.45 | `body` 14 / **500**, line height 1.5 |
| Field label, meta, chip | 12 / 600 `#5B6577` | `caption` 12 / 500 |
| Nav label | 11 / 600 | caption 12 |
| Overline ("NEW REGISTRATION") | 12 / 600 gold, uppercase | `overline` 10 / 600 |

**Rules to adopt:** headings 700, labels 600, body 400. Never go below 11px; the spec's smallest text is 11px, only for nav labels and chips. The code has **73 font sizes under 12**, with **9–10px** in [wallet_page.dart:1268](lib/presentation/screens/carpenter/wallet/wallet_page.dart#L1268) and [carpenter_profile_detail_screen.dart:1331](lib/presentation/screens/admin/carpenter_profile_detail_screen.dart#L1331).

---

## 5. Contrast check (WCAG 2.1, calculated)

| Pair | Ratio | Result |
|---|---|---|
| Code `textMuted #98A2B3` on white (hint, `bodySmall`, `labelSmall`) | 2.58 | ❌ FAIL |
| Code `textMuted` on background | 2.34 | ❌ FAIL |
| Code `warning #F59E0B` as icon or text on white | 2.15 | ❌ FAIL |
| Code gold `#C49143` as text on white, or white text on gold | 2.81 | ❌ FAIL |
| Code dark mode: navy primary on dark background | 1.44 | ❌ FAIL |
| Spec `#5B6577` on white / on `#F4F5F7` | 5.88 / 5.39 | ✅ |
| Spec navy text on gold CTA | 6.89 | ✅ |
| Spec `#C9D3E3` on navy | 10.94 | ✅ |
| Spec pending `#6B4D08` on `#FBF0D3` | 6.88 | ✅ |
| Spec dark muted `#9AA6BA` on `#162033` | 6.63 | ✅ |

Every spec pair passes. Every failure comes from code tokens that are not in the spec. **Adopting the spec palette fixes all of these.**

---

## 6. Responsive audit

### What the spec defines
- **Mobile frame: 390 × 844.** 16px side gutter, 3-column action grid, single column.
- **Desktop admin frame: 1280 × 860.** Fixed 232px navy sidebar. Main area padding 24/32. Stat cards in `repeat(auto-fit, minmax(200px, 1fr))`. Content grid `2fr / minmax(260px, 1fr)`. Tables scroll horizontally inside their card (`min-width: 520`). The header wraps (`flex-wrap`).

### What the code does
| Finding | Evidence | Impact |
|---|---|---|
| Responsive logic is rare | 16 helper references and 2 `LayoutBuilder`s across 81 presentation files. Most screens are single-column phone layouts at any width | On tablet and web, content stretches edge to edge |
| Breakpoint definitions overlap | `isTablet` = 600–1200, but rail navigation switches on at `isWideScreen` ≥ 840 ([responsive.dart](lib/core/layout/responsive.dart)) | 600–840px windows get a stretched phone layout plus bottom nav |
| Rebuild-heavy queries | `context.screenWidth` uses `MediaQuery.of(this).size` | Rebuilds on every inset or keyboard change. Use `MediaQuery.sizeOf` |
| Screen size instead of parent size | Layout decisions use window width, not available width | Wrong inside the rail layout: the content area is 264px narrower than the window |
| No stat-grid or 2-column admin layout | Admin dashboard doesn't follow `auto-fit minmax(200)` and `2fr/1fr` | Desktop admin doesn't match the spec |
| Pagination missing | Phase 4 was deferred | Spec shows 20 per page with Prev/Next |
| Text scaling untested | 0 `textScaler` references. Many fixed `height:` values (430 matches of `height: NN`) | At 1.3× system text, fixed-height tiles and chips clip |
| Fixed dialog widths | `SizedBox(width: 420–460)` in 3 super-admin dialogs | Clamped by `AlertDialog`, so no overflow, but wasted space on phones. Use `ConstrainedBox(maxWidth:)` |

### Recommended responsive contract
```
compact  < 600   : phone layout, bottom nav (68), 16px gutter, 1 column
medium   600–839 : bottom nav, content max-width 640 centered, 2-col cards
expanded 840–1199: navy rail 80 (icons + labels), 24px gutter, 2-col grids
large    ≥ 1200  : navy sidebar 232 extended, main padding 24/32,
                   stats auto-fit min 200, content 2fr/1fr, tables + pagination
```
Implement it with **one** `AppBreakpoints` + `LayoutBuilder`-based `ResponsiveLayout(compact:, medium:, expanded:)` widget. Make layout decisions with `constraints.maxWidth`.

---

## 7. Ease-of-use findings

1. **Main action is not visually clear.** The spec makes the main CTA gold and every secondary action white-outline. The code makes nearly every button navy, so primary and secondary actions look alike. Rule: one gold CTA per screen.
2. **Labels above fields.** The spec puts a 12/600 label above each field with a placeholder hint. That is easier for first-time and low-literacy users than floating labels, which disappear into the border.
3. **Large touch targets on mobile:** inputs 48, CTAs 48–52, action tiles 88. The code meets 48 in themes, but bespoke `InkWell`/`Container` buttons in large screens bypass this.
4. **Empty and pending states explain what happens next.** For example: "Your branch admin is reviewing your registration. Bills and rewards unlock once approved." Adopt one shared `EmptyState` / `InfoBanner`.
5. **Gradients (34 usages)** contradict the spec and the `AppColors` header ("No gradients"). Keep them only for celebrations (Diwali, spin) as a documented exception.
6. **Localization:** 194 literal `Text('…')` strings, including the new shared rail's "Sign out" and "Balaji Hardware". Hindi and Tamil labels will be longer; the spec's compact 11px nav labels need `maxLines: 1` + ellipsis.
7. **Wrong accessibility label:** the collapsed rail's logout button uses `l10n.closeButtonTooltip` ("Close") ([responsive_role_navigation.dart](lib/presentation/widgets/shared/responsive_role_navigation.dart)). Screen readers announce the wrong action.
8. **Six color palettes** (emerald, indigo, crimson, …) aren't in the spec and fight the navy and gold brand. Gold on crimson or orange looks off. **Your decision:** drop them, or keep only navy (default) and treat the others as experimental.
9. **Large screen files with local styling:** for example [carpenter_profile_detail_screen.dart](lib/presentation/screens/admin/carpenter_profile_detail_screen.dart) (2,050 lines, 95 hard-coded style values) and [pending_bills_list.dart](lib/presentation/widgets/admin/pending_bills_list.dart) (2,397 lines, 53). Once tokens change, these files will drift unless moved to shared components.

---

## 8. Remediation plan (in order)

**Phase A — Tokens (small change, big impact; fixes all contrast failures)**
1. Replace the `AppColors` values with the spec palette from §2. Add `borderStrong`, `divider`, `onPrimaryMuted`, `primaryLine`, `darkChrome`, and the 3 status pairs × 2 themes.
2. Dark theme: `primary` becomes a light tone, navy becomes `primaryContainer`, and backgrounds use the navy-black ramp.
3. Remove `action` / `tertiary`. Restrict `warning` to icons on tinted backgrounds.
4. Fix the `textMuted` contrast.

**Phase B — Component themes**
5. Buttons: pill shape (`StadiumBorder`), 48 high (52 hero). Gold = primary CTA, outline `#CBD1DB` = secondary, red outline = destructive, plus a 36 compact variant for tables.
6. Inputs: 48 high, radius 12, `#CBD1DB` border, navy 2px focus border, labels above.
7. Chips: radius 8, tinted status pairs. Card shadow per spec. Bottom nav at 68 with a gold-soft pill.
8. Typography table from §4. Minimum size 11.

**Phase C — Layout and navigation**
9. One breakpoint contract with `ResponsiveLayout`, plus a navy sidebar (232) or rail (80) styled per the spec.
10. Admin dashboard: stat auto-fit grid, 2fr/1fr layout, paginated tables (20 per page).
11. Shared `AppHeader` (navy curved), `QuickActionTile`, `EmptyState`, `StatusChip`, `StatCard`.

**Phase D — Migration and QA**
12. Migrate the top 10 hard-coded files (§7.9). Localize visible strings.
13. Visual QA at 360, 390, 600, 840, 1280, and 1600 widths, in light and dark, at 1.0× and 1.3× text, and with the keyboard open.

### Phase A reference values (drop-in)
```dart
// Light
primary         = Color(0xFF0B1F3A); primaryHover   = Color(0xFF16325C);
primaryLine     = Color(0xFF2B4570); onPrimaryMuted = Color(0xFFC9D3E3);
gold            = Color(0xFFC9A24B); goldSoft       = Color(0xFFFBF0D3);
background      = Color(0xFFF4F5F7); surface        = Color(0xFFFFFFFF);
border          = Color(0xFFE3E6EB); borderStrong   = Color(0xFFCBD1DB);
divider         = Color(0xFFEEF0F3);
textPrimary     = Color(0xFF1B2433); textSecondary  = Color(0xFF5B6577);
successBg = Color(0xFFE6F2EA); successFg = Color(0xFF1C5B34);
pendingBg = Color(0xFFFBF0D3); pendingFg = Color(0xFF6B4D08);
errorBg   = Color(0xFFF6DCDA); errorFg   = Color(0xFF8C1D18); error = Color(0xFFB3261E);
// Dark
darkBackground = Color(0xFF0B1220); darkChrome = Color(0xFF121B2D);
darkSurface    = Color(0xFF162033); darkRaised = Color(0xFF1F2A40);
darkBorder     = Color(0xFF26324A);
darkTextPrimary = Color(0xFFE8ECF3); darkTextMuted = Color(0xFF9AA6BA);
darkSuccessBg = Color(0xFF14301F); darkSuccessFg = Color(0xFF7FD39B);
darkPendingBg = Color(0xFF3A2E0F); darkPendingFg = Color(0xFFE9C46A);
darkErrorBg   = Color(0xFF3B1816); darkErrorFg   = Color(0xFFF2A19B);
```

---

### Method and limits
The spec HTML is a bundle of 23 nested pages. Each page was unpacked and its CSS extracted, and color frequency was counted across all screens. Code metrics are `grep` counts over `lib/presentation/` (81 Dart files). They are indicators, not exact component coverage. Contrast ratios were calculated with the WCAG 2.1 relative-luminance formula. Nothing was run on a device, and no code was changed by this audit.

---

## 9. Remediation log — 3 November 2026

**Direction from product owner:** "use less color". The app now uses one brand (navy + gold), one neutral ramp, and three status pairs.

### Done
| Step | Change | Files |
|---|---|---|
| A1 | Spec palette in `AppColors`: navy `#0B1F3A`, gold `#C9A24B`, canvas `#F4F5F7`, ink `#1B2433`, borders `#E3E6EB`/`#CBD1DB`, tinted status pairs (light + dark), navy-black dark ramp | `core/design/app_colors.dart` |
| A2 | **Removed the 6 selectable palettes** (enum, provider, profile picker, prefs key) | `app_colors.dart`, `theme_provider.dart`, `app.dart`, `profile_page.dart`, `app_constants.dart` |
| A3 | Dark mode: `primary` = `#4A74B0` (readable on dark, and under white text). Navy kept as `primaryContainer` and brand surfaces. Error in dark = `#F2A19B` | `app_theme.dart` |
| A4 | Contrast fixes: muted `#667085` (5.0:1), warning `#A87F1E`, success `#2F855A`. Removed the unused crimson `action` / tertiary | `app_colors.dart` |
| A5 | **31 automated WCAG contrast tests** guard every token pair | `test/design_contrast_test.dart` |
| B1 | Single light/dark theme builder. Gold pill main action, outline secondary, 48 px inputs with radius 12 and label above, radius-8 chips, 68 px bottom nav with gold-soft active pill, navy sidebar/rail with gold accent, data-table, tab, checkbox, switch and tooltip themes | `app_theme.dart` |
| B2 | Typography: headings 700, labels 600, body 400. New `label`, `input`, `button`, `navLabel` styles. Points hero 40 | `app_typography.dart` |
| B3 | Tokens: button radius pill, input radius 12, button 48 / hero 52 / compact 36, input 48, bottom nav 68, gutter 16 | `app_radius.dart`, `app_spacing.dart`, `carpenter_shell_layout.dart` |
| B4 | `AppButton` (gold / outline / red-outline danger), `AppCard` (navy brand card in both themes), `StatusChip` (tinted pairs, radius 8) | `widgets/shared/` |
| B5 | Bottom nav per spec. Rail is now a 232 px navy sidebar; the "Close" tooltip on logout is fixed to "Sign out" | `carpenter_bottom_nav_bar.dart`, `responsive_role_navigation.dart` |
| D1 | 80 Material `Colors.red/green/orange/blue/grey` replaced by tokens → **0 remain** | 10 admin/auth screens |
| D2 | Hex literals outside celebration and Google branding replaced by tokens → **0 remain** (33 left, all in Diwali, spin, or the Google logo) | 14 files |
| D3 | Admin dashboard: 12-colour tile rainbow and dot pattern replaced with one spec quick-action tile. Grid is width-driven (`maxCrossAxisExtent: 200`) | `admin_dashboard.dart` |
| D4 | 25 brand gradients flattened to solid colours. **6 remain:** 2 celebration, shimmer, 3 photo overlays for text legibility | 20 files |
| D5 | 43 font sizes under 11 px raised to 11 → **0 remain** | screens |
| C1 | `WindowSize` classes, `ResponsiveLayout` (constraint-based), `ReadableWidth`. `ResponsiveContainer` now uses parent constraints (and the double-padding bug is fixed). `MediaQuery.sizeOf`/`paddingOf` | `core/layout/responsive.dart` |
| C2 | Carpenter screens centred at 720 px on tablet and web. Removed the shell's surface override that hid white cards | `dashboard_page.dart` |
| C3 | Shared `AppTableCard`: spec table card, 20 per page, Previous/Next, horizontal scroll. Used by Pending Bills and Bill History on desktop | `app_table_card.dart`, `pending_bills_list.dart`, `bill_history_list.dart` |

**Verification:** `flutter analyze` reports 0 errors (the one warning, `_resolveRoleForUser`, predates this work). `flutter test`: 37 pass, 1 fails. The failure is `login_auth_ui_test` "login screen exposes clear email, Google and PIN actions": it looks for the text "For existing users with a mobile number and PIN", which the uncommitted login redesign removed. The test needs updating to match the new login screen. **No on-device visual check has been done yet.**

### Still open
- Localize roughly 194 literal strings (Hindi/Tamil) and check long labels at 360 px.
- Visual QA at 360 / 390 / 600 / 840 / 1280 / 1600 px, light and dark, text scale 1.3×.
- Shared `EmptyState`, `QuickActionTile`, and navy `AppHeader` widgets, then migrate the large screens (`carpenter_profile_detail_screen`, `pending_bills_list`) to them.
- Admin dashboard stat-card row (Users / Pending / Bills / Points) from the spec.
- The spec's own dark mockup has white inputs and buttons with light text. Ignore that; the theme uses dark surfaces.

## 10. Remediation log — round 2 (3 November 2026)

| Step | Change |
|---|---|
| Font | Inter replaced by **Nunito** in all styles, and `ThemeData.fontFamily` set so raw `TextStyle`s inherit it. The 6 weights (400–900) are **bundled** in `assets/google_fonts/` (checksums match google_fonts 6.3.2), with `allowRuntimeFetching = false` and the OFL licence registered in `main.dart`. Text renders offline on first launch with no font swap. |
| Type scale | Larger for Nunito's smaller x-height: body 15/500, input 16, label 13/700, caption 13, title 22/800, section 18/700, button 16/700, nav 12/700. **Minimum size is 12**: all sizes under 12 raised (0 remain). |
| Icons | **406 filled icons → Material 3 rounded twins** (all had one in the SDK). Outlined icons are kept for inactive states. **0 legacy filled icons remain.** On-screen emoji status prefixes (❌ ✅ ⚠️ 📢 ⭐ …) removed from 47 visible strings; emoji remain only in debug logs and the Diwali celebration. |
| Translations | **~110 new keys** with Hindi and Tamil. Tamil was missing 26 keys and is now filled: en/hi/ta all have **579 keys**. All carpenter-facing, auth, shell and shared-widget strings are localized (home, wallet, bills, spin, notifications, profile, register/PIN/forgot-password, navigation, update dialog, table). English is sentence case (M3). |
| Empty states | Shared `EmptyState` (spec dashed card, icon, title, "what appears here" line, optional action) replaces 6 hand-made versions: wallet ×3, pending bills, bill history, users. |
| Admin stats | Spec stat row above the tiles: Carpenters, Pending bills, Bills this month (with approved count), Points issued this month. Shared `StatCard`, width-driven 2–4 columns, cards link to sections. The month figures use one range query on `createdAt` (no new index). |
| Responsiveness | `test/responsive_layout_test.dart`: **360 cases**. 6 targets (onboarding, about, PIN entry, forgot password, component gallery, role-navigation shell) × 320/390/600/840/1280 px × 1.0/1.3× text × en/hi/ta × light/dark, using the real Nunito metrics. It found and fixed a 14 px table-footer overflow (Tamil, 320 px, 1.3×). **All 360 pass.** |

**Verification:** `flutter analyze`: 0 errors. `flutter test`: 397 pass, 1 fails. The failure is the stale `login_auth_ui_test` case, which expects text the uncommitted login redesign removed.

### Still open after round 2
- **Admin / super-admin / maintenance tools** (duplicate cleanup, diagnostics, backup, points repair, roles, branches; about 370 strings) are still English. This is deliberate for this round: they are staff tools.
- `login_page.dart` and `diwali_celebration_dialog.dart` were not localized, to avoid clashing with the uncommitted redesign of those files.
- Screens that need Firebase (home, wallet, admin lists) are not in the automated layout test. They need an on-device or web pass with a signed-in account.

## 11. Remediation log — round 3: full localization (4 November 2026)

Every screen under `lib/presentation/` is now localized in English, Hindi and Tamil. That includes the login and Diwali screens that round 2 skipped, and all admin, super-admin and maintenance tools.

| Batch | Screens | Replaced |
|---|---|---|
| 1 | Carpenter leftovers: wallet, add bill, edit profile, notifications, profile, home, spin | 81 |
| 2 | Auth (login, register, forgot password, PIN), splash, update dialog, status chip, Diwali celebration | 120 + update-dialog sentence |
| 3 | Admin bills: pending, history, bill details, admin add bill, duplicate bill details | 187 |
| 4 | Admin carpenters/users, admin home and rail, dashboard tiles, add-carpenter dialog, user list/search | 147 + tile labels |
| 5 | Offers, daily spin and history, eligible carpenters, admin notifications, send greeting | 145 |
| 6 | Super admin: branches, roles, admin accounts, create admin, points cleanup, console | 158 |
| 7 | Maintenance: diagnostics, points repair/scan, duplicate checker/cleanup, user export, backup | ~160 |
| Manual | ICU plurals (`winnersCount`, `hoursAgo`, `daysAgo`), repair confirm/results, backup counts, greeting confirm, role restored/deleted, super-admin permission errors | 16 |

- **ARB parity:** en / hi / ta each have **1,212 keys** (up from 465/465/439). No unused keys.
- **Plurals** use ICU `{count, plural, …}`, not `'s'` suffix tricks.
- `const` lists that held visible labels became getters or `final` lists. The admin rail is a getter, and dashboard tiles resolve their label from the section id.

**Deliberately left in English:**
- **PDF report content** (bill history, carpenter list, user backup). The PDF library's built-in font has no Devanagari or Tamil glyphs, so translated text would print as boxes. Translating PDFs needs a bundled Noto font in `pdf` first.
- Data, not text: tier values (`Bronze`/`Silver`/…), Firestore field names, the stored notification title `New Announcement`, date-format patterns, the `sms:` URI.
- Brand names (`Balaji Hardware`, `Aajii Tech Studio`) and technical field labels in the diagnostics page (`Bills (carpenterPhone=normalized)`).
- Exception text thrown inside services or validation helpers (shown only after a translated prefix such as "Failed to update profile:").

**Verification:** `flutter analyze`: 0 errors. `flutter test`: **398 / 398 pass**, including the 360-case layout test in en/hi/ta. `login_auth_ui_test` was updated with localization delegates, and its stale expectation was removed.

**Translation quality:** Hindi and Tamil were machine-written in plain, everyday wording. A native speaker should review them before release.

## 12. Super Admin panel and role sync (4 November 2026)

**Root cause of "roles not syncing":** production Firestore rules have **no `/roles` block**. A public read returns `403`, while `branches` and `app_config` return `200`. The Roles tab therefore can't read or create roles, and registration silently falls back to the 4 built-in roles. The local `firestore.rules` already had a roles block but was never deployed.

| Area | Change |
|---|---|
| `RoleService` | `watchRoles()` live stream. Create and soft-delete/restore run in **transactions**. Typed `RoleException` codes (invalid name, reserved, built-in, duplicate, protected) replace English-only errors. Limits: name 2–40, short form ≤ 10, id ≤ 40. **Carpenter is protected** (can't be deleted). Deactivation updates only `isActive` + `updatedAt`. |
| `firestore.rules` `/roles` | Field allow-list. Length limits. `isBuiltIn` must match the 4 built-in IDs. `roleId`/`createdAt` immutable. Timestamps must be server time. New custom roles start active. Carpenter can't be deactivated. Still public read (registration needs it before sign-in) and no hard delete. |
| Rules tests | `firestore-tests/` (emulator, `npm test`): **20 tests** covering reads, every super-admin write path, rejected shapes, non-admin denial, and registration with an active, deleted, built-in or admin role. All pass. |
| Roles tab | Live list. All/Active/Deleted filter with counts. Cards show the role initial, Active/Deleted and Built-in/Custom tags, and the ID. Carpenter shows a lock. Per-row progress while saving. Error banner with Retry. Add role dialog: live ID preview, length counters, instant duplicate/reserved/built-in checks, server errors shown inline. Theme buttons; the red confirm uses on-error text. |
| Translations | Built-in role names are shown translated (`roleDisplayName`), also on the registration screen. Stored `roleName` on users stays canonical English. |
| Shell | Brand-navy app bar in both themes, with the title truncating instead of overflowing. Phones get a Material 3 `NavigationBar` instead of the hand-made `GestureDetector` tab row. Themed logout dialog. |
| Other tabs | Shared `SuperAdminSectionHeader` (the action wraps below on narrow screens). Removed navy/white button overrides, so the main action is gold. Red buttons use `themeOnError` (white on pink failed contrast in dark). Spinners are navy so they show on gold. Branches empty state uses `EmptyState`. |
| Tests | `test/role_service_test.dart`: 13 tests (service sync, tab add/duplicate flow, Tamil 320px 1.3× light/dark). Full suite **411 / 411 pass**. |

**Pending (needs owner approval):** `firebase deploy --only firestore:rules --project balajipoints`. This replaces production rules for all collections.

**Noted, not changed:** `users` documents are publicly readable (`allow read: if true`, for PIN login), including PIN hashes, phone numbers and emails. `pin_setup_page.dart` is unreferenced dead code with a hard-coded role list.

## 13. Super Admin round 2 (4 November 2026)

- **Rules deployed** to `balajipoints` (`firebase deploy --only firestore:rules`). Production `/roles` now returns 200 (was 403).
- **Branch card** (`super_admin_branch_card.dart`):
  - Was tall because a right-side "Deactivate" button squeezed the content column, and a full `SwitchListTile` sat inside it.
  - The content now uses the full width, with actions in a ⋮ menu (Deactivate/Activate **with confirmation**, Copy ID).
  - Every line is capped, and the Diwali toggle is one compact row.
  - Two columns on wide screens.
- **Admins tab** (was "Create admin"):
  - Opens on the **list of branch admins**, with search, a count, and a ⋮ menu per admin (Change password, Delete).
  - An **Add admin** button opens the form: full screen on phones, a 520 px dialog on wider screens, with inline errors.
  - The new admin appears live in the list. Two columns on wide screens.
- **Consistency:**
  - One 16 px page margin owned by the shell, and tabs start at the top.
  - `ResponsiveRoleNavigation` Row now stretches, which fixes vertically centred pages beside the rail in all role shells.
  - The rail label is "Points" (it used to truncate).
- **Theme:** floating field labels are now 12 px; they rendered at ~10 px because M3 scales them to 75 %. Search fields use a themed `TextField`.
- **Points reset:** the warning uses the tinted error pair, and the branch picker shows a "Select branch" hint.
- **Visual QA:** `tool/screenshots/super_admin_screens_test.dart` renders 30 PNGs (phone/tablet/desktop × light/dark × every tab + Add admin dialog) with real Nunito and Material Icons. All were reviewed, with no layout errors.
- **Tests:** 413 Flutter tests + 20 rules tests pass.
