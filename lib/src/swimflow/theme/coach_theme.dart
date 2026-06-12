import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class CoachColors {
  static const background = Color(0xFFF7F9FC);
  static const onBackground = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF434653);
  static const primary = Color(0xFF00327D);
  static const primaryContainer = Color(0xFF0047AB);
  static const secondary = Color(0xFF00677F);
  static const secondaryContainer = Color(0xFF00D2FF);
  static const outlineVariant = Color(0xFFC3C6D5);
  static const surfaceContainerLow = Color(0xFFF2F4F7);
  static const surfaceContainerHighest = Color(0xFFE0E3E6);
}

List<BoxShadow> coachCardShadow() => [
      BoxShadow(
        color: const Color(0xFF0047AB).withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];

class CoachAppTheme {
  static ThemeData get light {
    final inter = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CoachColors.background,
      colorScheme: ColorScheme.light(
        primary: CoachColors.primary,
        onPrimary: Colors.white,
        primaryContainer: CoachColors.primaryContainer,
        secondary: CoachColors.secondary,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: CoachColors.onBackground,
        surfaceContainerLow: CoachColors.surfaceContainerLow,
        surfaceContainerHighest: CoachColors.surfaceContainerHighest,
        outline: const Color(0xFF737784),
        outlineVariant: CoachColors.outlineVariant,
        error: const Color(0xFFBA1A1A),
      ),
      textTheme: inter.copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 28 / 22,
          color: CoachColors.onBackground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: CoachColors.onBackground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: CoachColors.onBackground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: CoachColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          color: CoachColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
