import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';

/// Professional auth screen background with curved design
/// Matches chosen Material 3 Color Palette in both Light and Dark modes
class AuthBackground extends StatelessWidget {
  final bool isDark;

  const AuthBackground({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        isDark || Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(color: context.themeBackground),
      child: Stack(
        children: [
          // Bottom-left curved design
          Positioned(
            bottom: 0,
            left: 0,
            child: ClipPath(
              clipper: BottomCurveClipper(),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.primary,
                ),
              ),
            ),
          ),

          // Top-right curved accent
          Positioned(
            top: 0,
            right: 0,
            child: ClipPath(
              clipper: TopRightCurveClipper(),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: context.themeGold.withValues(
                    alpha: isDarkMode ? 0.08 : 0.15,
                  ),
                ),
              ),
            ),
          ),

          // Accent line top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 3,
              height: 150,
              decoration: BoxDecoration(color: context.themeGold),
            ),
          ),

          // Accent line bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 3,
              height: 150,
              decoration: BoxDecoration(color: context.themeGold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Clipper for bottom-left curve
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.4);

    // First curve control point and end point
    final firstControlPoint = Offset(size.width * 0.25, size.height * 0.1);
    final firstEndPoint = Offset(size.width * 0.6, size.height * 0.5);

    // Second curve control point and end point
    final secondControlPoint = Offset(size.width * 0.85, size.height * 0.8);
    final secondEndPoint = Offset(size.width, size.height * 0.7);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom Clipper for top-right curve
class TopRightCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width * 0.3, 0);

    final controlPoint = Offset(size.width * 0.6, size.height * 0.6);
    final endPoint = Offset(size.width, size.height * 0.8);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
