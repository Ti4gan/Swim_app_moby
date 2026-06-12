import 'package:flutter/material.dart';

abstract final class StitchColors {
  static const background = Color(0xFFFAF9FE);
  static const onBackground = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const primary = Color(0xFF0058BC);
  static const secondary = Color(0xFF00696F);
  static const primaryContainer = Color(0xFF0070EB);
  static const secondaryFixed = Color(0xFF6FF6FF);
  static const secondaryFixedDim = Color(0xFF00DCE6);
  static const secondaryContainer = Color(0xFF00F1FD);
  static const onSecondaryContainer = Color(0xFF006A6F);
  static const surfaceContainerLow = Color(0xFFF4F3F8);
  static const surfaceContainer = Color(0xFFE8EDF3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHighest = Color(0xFFE3E2E7);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const primaryFixed = Color(0xFFD8E2FF);
  static const primaryFixedDim = Color(0xFFADC6FF);
  static const tertiaryContainer = Color(0xFF0079C3);
  static const onTertiaryContainer = Color(0xFFFDFCFF);
  static const error = Color(0xFFBA1A1A);
  static const onPrimaryFixedVariant = Color(0xFF004493);
}

LinearGradient get stitchAquaGradient => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0070EB), Color(0xFF00DCE6)],
    );

LinearGradient get stitchWaterGradient => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0070EB), Color(0xFF00F1FD)],
    );

InputDecoration stitchFieldDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    hintStyle: TextStyle(color: StitchColors.outline.withValues(alpha: 0.72)),
    prefixIcon: prefixIcon,
    border: const OutlineInputBorder(),
  );
}

List<BoxShadow> stitchCardShadow() => [
      BoxShadow(
        color: const Color(0xFF0058BC).withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];

abstract final class StitchImages {
  static const avatar =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80';
  static const poolHero =
      'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=900&q=85';
  static const poolMacro =
      'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800&q=85';
}
