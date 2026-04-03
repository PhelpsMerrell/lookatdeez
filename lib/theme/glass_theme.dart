import 'dart:ui';
import 'package:flutter/material.dart';

/// Concentric-inspired design tokens for the app.
/// Mirrors the iOS Concentricity system's liquid glass aesthetic.
class AppTheme {
  // Corner radii (matching iOS ConcentricRadii)
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  // Colors
  static const Color bgDark = Color(0xFF0F0F14);
  static const Color bgGradientStart = Color(0xFF0F172A);
  static const Color bgGradientMid = Color(0xFF1E293B);
  static const Color bgGradientEnd = Color(0xFF0F172A);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A24),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        useMaterial3: true,
      );

  /// Standard background gradient used behind glass elements.
  static BoxDecoration get scaffoldGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgGradientStart, bgGradientMid, bgGradientEnd],
        ),
      );
}

/// Liquid glass container — translucent frosted material with
/// inner highlights and edge stroke, matching iOS `.liquidGlass()`.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final Color tint;
  final double prominence;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = AppTheme.radiusMd,
    this.blur = 24,
    this.tint = Colors.white,
    this.prominence = 0.12,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: ShapeDecoration(
              shape: shape,
              color: Colors.white.withOpacity(0.06),
            ),
            foregroundDecoration: ShapeDecoration(
              shape: shape.copyWith(
                side: BorderSide.none,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.35, 0.6],
                colors: [
                  Colors.white.withOpacity(prominence * 2.2),
                  Colors.white.withOpacity(prominence * 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simpler glass card that wraps content with the liquid glass effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = AppTheme.radiusMd,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white.withOpacity(0.07),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.4, 1.0],
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass bar for bottom toolbars / safe-area insets.
/// Matches iOS `.glassBar()`.
class GlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassBar({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass pill button matching iOS ConcentricPillButton.
class GlassPillButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final double radius;

  const GlassPillButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isDestructive = false,
    this.radius = AppTheme.radiusSm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassCard(
        radius: radius,
        padding: const EdgeInsets.all(14),
        child: Icon(
          icon,
          color: isDestructive
              ? Colors.red
              : Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }
}
