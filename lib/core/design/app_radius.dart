import 'package:flutter/material.dart';

/// Enterprise design system — border-radius tokens.
///
/// From PDF spec:
///   Buttons 14 · Cards 24 · Wallet cards 28 · Inputs 18 · Bottom nav 30
class AppRadius {
  AppRadius._();

  // --------------------------------------------------------------------------
  // Raw values
  // --------------------------------------------------------------------------
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double button = 14.0;
  static const double input = 18.0;
  static const double card = 24.0;
  static const double walletCard = 28.0;
  static const double bottomNav = 30.0;
  static const double full = 999.0; // pill / circle

  // --------------------------------------------------------------------------
  // BorderRadius presets
  // --------------------------------------------------------------------------
  static const BorderRadius xs4 = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius sm8 = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius md12 = BorderRadius.all(Radius.circular(md));
  static const BorderRadius forButton = BorderRadius.all(Radius.circular(button));
  static const BorderRadius forInput = BorderRadius.all(Radius.circular(input));
  static const BorderRadius forCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius forWalletCard = BorderRadius.all(Radius.circular(walletCard));
  static const BorderRadius forBottomNav = BorderRadius.all(Radius.circular(bottomNav));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));

  // --------------------------------------------------------------------------
  // RoundedRectangleBorder presets (for Material widgets)
  // --------------------------------------------------------------------------
  static const RoundedRectangleBorder buttonShape =
      RoundedRectangleBorder(borderRadius: forButton);
  static const RoundedRectangleBorder cardShape =
      RoundedRectangleBorder(borderRadius: forCard);
  static const RoundedRectangleBorder inputShape =
      RoundedRectangleBorder(borderRadius: forInput);
  static const RoundedRectangleBorder pillShape =
      RoundedRectangleBorder(borderRadius: pill);

  // --------------------------------------------------------------------------
  // Top-only (for bottom sheets, modals)
  // --------------------------------------------------------------------------
  static const BorderRadius topCard = BorderRadius.only(
    topLeft: Radius.circular(card),
    topRight: Radius.circular(card),
  );

  static const BorderRadius topLarge = BorderRadius.only(
    topLeft: Radius.circular(walletCard),
    topRight: Radius.circular(walletCard),
  );
}
