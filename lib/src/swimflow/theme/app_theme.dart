import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class StitchAppTheme {
  static ThemeData get light {
    final inter = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: StitchColors.background,
      colorScheme: ColorScheme.light(
        primary: StitchColors.primary,
        onPrimary: Colors.white,
        primaryContainer: StitchColors.primaryContainer,
        surface: StitchColors.surfaceContainerLowest,
        onSurface: StitchColors.onBackground,
        surfaceContainerLow: StitchColors.surfaceContainerLow,
        surfaceContainerHighest: StitchColors.surfaceContainerHighest,
        outline: StitchColors.outline,
        outlineVariant: StitchColors.outlineVariant,
        error: StitchColors.error,
      ),
      textTheme: inter.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 41 / 34,
          letterSpacing: -0.5,
          color: StitchColors.onBackground,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 28 / 22,
          letterSpacing: -0.2,
          color: StitchColors.onBackground,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 22 / 17,
          color: StitchColors.onBackground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 21 / 16,
          color: StitchColors.onBackground,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 18 / 14,
          color: StitchColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          letterSpacing: 0.5,
          color: StitchColors.outline,
        ),
      ),
    );
  }
}
