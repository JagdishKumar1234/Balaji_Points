import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_theme_palette.dart';

/// Professional auth screen background with curved design
/// Matches premium business design with navy and gold accents
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F7FA), // Very light gray-blue
            const Color(0xFFFFFFFF), // White
            const Color(0xFFF0F4F8), // Light blue-gray
          ],
        ),
      ),
      child: Stack(
        children: [
          // Bottom-left curved design (light mode)
          if (!isDarkMode)
            Positioned(
              bottom: 0,
              left: 0,
              child: ClipPath(
                clipper: BottomCurveClipper(),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF001F4D), // Deep navy
                        const Color(0xFF0D47A1), // Dark blue
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top-right curved design (light mode)
          if (!isDarkMode)
            Positioned(
              top: 0,
              right: 0,
              child: ClipPath(
                clipper: TopRightCurveClipper(),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082).withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),

          // Gold accent line top-right
          if (!isDarkMode)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 3,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFD4AF37),
                      const Color(0xFFD4AF37).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

          // Gold accent line bottom-left
          if (!isDarkMode)
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: 3,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFD4AF37),
                      const Color(0xFFD4AF37).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

          // Subtle dotted pattern (light mode)
          if (!isDarkMode)
            Positioned(
              right: 20,
              top: 150,
              child: Opacity(
                opacity: 0.06,
                child: Column(
                  children: List.generate(
                    8,
                    (i) => Row(
                      children: List.generate(
                        3,
                        (j) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Clips bottom of container with smooth curve
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.6);

    // Smooth curve from bottom-left to bottom-right
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Clips top-right corner with curve
class TopRightCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.7, 0);
    path.quadraticBezierTo(
      size.width,
      size.height * 0.3,
      size.width,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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
