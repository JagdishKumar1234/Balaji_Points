import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enterprise design system — animation tokens.
///
/// PDF spec: 200–600 ms, fade + slide primarily, smooth easing, no heavy looping.
class AppAnimations {
  AppAnimations._();

  // --------------------------------------------------------------------------
  // Duration constants
  // --------------------------------------------------------------------------
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration xSlow = Duration(milliseconds: 600);

  // Stagger delay between list items
  static const Duration staggerStep = Duration(milliseconds: 60);

  // --------------------------------------------------------------------------
  // Easing curves
  // --------------------------------------------------------------------------
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
  // Premium spring feel for cards/modals
  static const Curve spring = Curves.elasticOut;
  static const Curve smooth = Curves.fastLinearToSlowEaseIn;

  // --------------------------------------------------------------------------
  // Slide offsets (used with Animate.slideY / slideX)
  // --------------------------------------------------------------------------
  static const double slideUpOffset = 0.18;   // subtle — cards, widgets
  static const double slideUpFarOffset = 0.35; // hero — full-screen elements
  static const double slideDownOffset = -0.18;

  // --------------------------------------------------------------------------
  // Shared effect lists — apply via widget.animate().custom(...)
  // or compose in screen-specific helpers below.
  // --------------------------------------------------------------------------

  /// Standard card fade-in + slide-up.
  static List<Effect> get cardEntrance => [
        FadeEffect(duration: normal, curve: easeOut),
        SlideEffect(
          begin: const Offset(0, slideUpOffset),
          end: Offset.zero,
          duration: normal,
          curve: easeOut,
        ),
      ];

  /// Hero element entrance (logo, full-screen titles).
  static List<Effect> get heroEntrance => [
        FadeEffect(duration: medium, curve: easeOut),
        SlideEffect(
          begin: const Offset(0, slideUpFarOffset),
          end: Offset.zero,
          duration: medium,
          curve: decelerate,
        ),
      ];

  /// Subtle fade only — for supporting text, labels.
  static List<Effect> get fadeIn => [
        FadeEffect(duration: normal, curve: easeOut),
      ];

  /// Scale + fade — for buttons, chips, badges.
  static List<Effect> get popIn => [
        FadeEffect(duration: fast, curve: easeOut),
        ScaleEffect(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: fast,
          curve: easeOut,
        ),
      ];

  /// Soft press down feedback — for tappable cards.
  static List<Effect> get pressDown => [
        ScaleEffect(
          begin: const Offset(1, 1),
          end: const Offset(0.97, 0.97),
          duration: instant,
          curve: easeIn,
        ),
      ];

  // --------------------------------------------------------------------------
  // Delay helpers — stagger n-th item in a list
  // --------------------------------------------------------------------------
  static Duration stagger(int index, {Duration step = staggerStep}) =>
      step * index;
}

// --------------------------------------------------------------------------
// Extension for convenience chaining on any Widget
// --------------------------------------------------------------------------
extension AppAnimateExtension on Widget {
  /// Card entrance: fade + slide up. Pass [delay] for staggered lists.
  Widget enterCard({Duration delay = Duration.zero}) => animate(delay: delay)
      .fade(duration: AppAnimations.normal, curve: AppAnimations.easeOut)
      .slideY(
        begin: AppAnimations.slideUpOffset,
        end: 0,
        duration: AppAnimations.normal,
        curve: AppAnimations.easeOut,
      );

  /// Hero entrance: deeper slide + fade (logo, page title).
  Widget enterHero({Duration delay = Duration.zero}) => animate(delay: delay)
      .fade(duration: AppAnimations.medium, curve: AppAnimations.easeOut)
      .slideY(
        begin: AppAnimations.slideUpFarOffset,
        end: 0,
        duration: AppAnimations.medium,
        curve: AppAnimations.decelerate,
      );

  /// Subtle fade-in only.
  Widget fadeIn({Duration delay = Duration.zero, Duration? duration}) =>
      animate(delay: delay)
          .fade(duration: duration ?? AppAnimations.normal, curve: AppAnimations.easeOut);

  /// Pop in: scale + fade.
  Widget popIn({Duration delay = Duration.zero}) => animate(delay: delay)
      .fade(duration: AppAnimations.fast, curve: AppAnimations.easeOut)
      .scale(
        begin: const Offset(0.92, 0.92),
        end: const Offset(1, 1),
        duration: AppAnimations.fast,
        curve: AppAnimations.easeOut,
      );
}
