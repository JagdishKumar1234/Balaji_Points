import 'package:flutter/material.dart';

/// Balaji Points Design System v2.0 — Border radius tokens.
///
/// Single universal radius: 16.
/// Exceptions: small chips (8), bottom sheets / dialogs (24), pills (999).
class AppRadius {
  AppRadius._();

  // ── Raw values ──────────────────────────────────────────────────────────────

  static const double xs         = 4.0;
  static const double sm         = 8.0;   // small chips, icon containers
  static const double md         = 12.0;  // compact elements
  static const double r16        = 16.0;  // universal — cards, buttons, inputs, wallet
  static const double lg         = 24.0;  // bottom sheets, dialogs
  static const double full       = 999.0; // pill / circle

  // Legacy named aliases (kept so existing code compiles)
  static const double button     = r16;
  static const double input      = r16;
  static const double card       = r16;
  static const double walletCard = r16;
  static const double bottomNav  = lg;

  // ── BorderRadius presets ────────────────────────────────────────────────────

  static const BorderRadius xs4       = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius sm8       = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius md12      = BorderRadius.all(Radius.circular(md));
  static const BorderRadius all16     = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius all24     = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pill      = BorderRadius.all(Radius.circular(full));

  // Legacy aliases
  static const BorderRadius forButton     = all16;
  static const BorderRadius forInput      = all16;
  static const BorderRadius forCard       = all16;
  static const BorderRadius forWalletCard = all16;
  static const BorderRadius forBottomNav  = all24;

  // ── RoundedRectangleBorder presets ──────────────────────────────────────────

  static const RoundedRectangleBorder buttonShape =
      RoundedRectangleBorder(borderRadius: all16);
  static const RoundedRectangleBorder cardShape =
      RoundedRectangleBorder(borderRadius: all16);
  static const RoundedRectangleBorder inputShape =
      RoundedRectangleBorder(borderRadius: all16);
  static const RoundedRectangleBorder pillShape =
      RoundedRectangleBorder(borderRadius: pill);
  static const RoundedRectangleBorder sheetShape =
      RoundedRectangleBorder(borderRadius: topLarge);

  // ── Top-only (for bottom sheets, modals) ────────────────────────────────────

  static const BorderRadius topCard = BorderRadius.only(
    topLeft:  Radius.circular(r16),
    topRight: Radius.circular(r16),
  );

  static const BorderRadius topLarge = BorderRadius.only(
    topLeft:  Radius.circular(lg),
    topRight: Radius.circular(lg),
  );
}
