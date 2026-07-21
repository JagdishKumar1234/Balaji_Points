import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_theme_palette.dart';

/// Attractive, modern auth screen background
/// No images - pure gradient design that works on all platforms
class AuthBackground extends StatelessWidget {
  final bool isDark;

  const AuthBackground({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isDark || Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? ThemePalette.darkAuthBackgroundGradient
            : ThemePalette.lightAuthBackgroundGradient,
      ),
      child: Stack(
        children: [
          // Animated blurred circles for depth (light mode)
          if (!isDarkMode) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemePalette.lightPrimaryGradient[0].withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemePalette.accentGold.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
          // Subtle decoration for dark mode
          if (isDarkMode) ...[
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemePalette.darkPrimaryGradient[0].withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemePalette.accentGoldLight.withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Splash screen with modern gradient
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        AuthBackground(isDark: isDark),

        // Animated logo and text
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? ThemePalette.darkPrimaryGradient
                            : ThemePalette.lightPrimaryGradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? ThemePalette.darkPrimaryGradient[0]
                              : ThemePalette.lightPrimaryGradient[0],
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App name
                  Text(
                    'Balaji Points',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? ThemePalette.darkTextPrimary
                          : ThemePalette.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  Text(
                    'Loyalty Rewards Program',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? ThemePalette.darkTextSecondary
                          : ThemePalette.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Loading indicator
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? ThemePalette.darkPrimaryGradient[0]
                            : ThemePalette.lightPrimaryGradient[0],
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
