import 'package:flutter/material.dart';

import '../models/swimflow_profile.dart';
import '../theme/tokens.dart';

abstract final class ProfileAvatarPresets {
  static const List<String> ids = ['sw01', 'sw02', 'sw03', 'sw04', 'sw05', 'sw06', 'sw07'];

  static bool isValid(String? id) => id != null && id.isNotEmpty && ids.contains(id);

  static Widget tile(String id, double size) {
    final i = ids.indexOf(id);
    final spec = i >= 0 ? _specs[i] : _specs[0];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: spec.colors),
        boxShadow: [
          BoxShadow(
            color: spec.colors.last.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(spec.icon, color: Colors.white.withValues(alpha: 0.92), size: size * 0.44),
    );
  }

  static final List<({List<Color> colors, IconData icon})> _specs = [
    (colors: const [Color(0xFF0EA5E9), Color(0xFF0369A1)], icon: Icons.pool_rounded),
    (colors: const [Color(0xFF14B8A6), Color(0xFF0F766E)], icon: Icons.waves_rounded),
    (colors: const [Color(0xFF6366F1), Color(0xFF4338CA)], icon: Icons.water_rounded),
    (colors: const [Color(0xFFF59E0B), Color(0xFFD97706)], icon: Icons.wb_sunny_outlined),
    (colors: const [Color(0xFFEC4899), Color(0xFFBE185D)], icon: Icons.favorite_rounded),
    (colors: const [Color(0xFF22C55E), Color(0xFF15803D)], icon: Icons.spa_rounded),
    (colors: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)], icon: Icons.bubble_chart_rounded),
  ];
}

class SwimflowProfileAvatar extends StatelessWidget {
  const SwimflowProfileAvatar({
    super.key,
    required this.profile,
    this.size = 36,
    this.borderRadius,
  });

  final SwimflowProfile profile;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(999);
    if (ProfileAvatarPresets.isValid(profile.avatarPreset)) {
      return ClipRRect(
        borderRadius: br,
        child: ProfileAvatarPresets.tile(profile.avatarPreset, size),
      );
    }
    final url = profile.avatarUrl.trim();
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: br,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(br),
        ),
      );
    }
    return ClipRRect(
      borderRadius: br,
      child: Image.network(
        StitchImages.avatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(br),
      ),
    );
  }

  Widget _fallback(BorderRadius br) {
    return ClipRRect(
      borderRadius: br,
      child: Container(
        width: size,
        height: size,
        color: StitchColors.primaryFixed,
        alignment: Alignment.center,
        child: Icon(Icons.person_rounded, color: StitchColors.primary, size: size * 0.52),
      ),
    );
  }
}
