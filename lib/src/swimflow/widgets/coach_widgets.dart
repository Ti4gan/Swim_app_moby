import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/coach_notifications_providers.dart';
import '../theme/coach_theme.dart';

class CoachPageBackground extends StatelessWidget {
  const CoachPageBackground({
    required this.child,
    super.key,
    this.bottomInset = 0,
  });

  final Widget child;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CoachColors.background, Color(0xFFE8EEF5)],
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class CoachGlassCard extends StatelessWidget {
  const CoachGlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: coachCardShadow(),
          ),
          child: child,
        ),
      ),
    );
  }
}

class CoachNotificationsHeaderButton extends ConsumerWidget {
  const CoachNotificationsHeaderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCoachNotificationsCountProvider);
    return IconButton(
      onPressed: () => context.push('/coach/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        child: const Icon(Icons.notifications_outlined, color: CoachColors.primary),
      ),
    );
  }
}

class CoachSubpageHeader extends StatelessWidget {
  const CoachSubpageHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return CoachBlurAppBar(
      title: 'CoachFlow',
      leading: IconButton(
        onPressed: onBack ?? () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: CoachColors.onBackground),
      ),
    );
  }
}

class CoachFlowHeader extends StatelessWidget {
  const CoachFlowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM', 'ru').format(DateTime.now());
    return CoachBlurAppBar(
      title: 'CoachFlow',
      subtitle: dateLabel,
      trailing: const CoachNotificationsHeaderButton(),
    );
  }
}

class CoachBlurAppBar extends StatelessWidget {
  const CoachBlurAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(color: CoachColors.outlineVariant.withValues(alpha: 0.35)),
            ),
            boxShadow: [
              BoxShadow(
                color: CoachColors.primaryContainer.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: CoachColors.onBackground,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: CoachColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class CoachCapsLabel extends StatelessWidget {
  const CoachCapsLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color ?? CoachColors.secondary,
      ),
    );
  }
}

class CoachBottomNav extends StatelessWidget {
  const CoachBottomNav({
    required this.index,
    required this.onChanged,
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, IconData, String)>[
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Обзор'),
      (Icons.pool_outlined, Icons.pool_rounded, 'Пловцы'),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Календарь'),
      (Icons.analytics_outlined, Icons.analytics_rounded, 'Аналитика'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Профиль'),
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: CoachColors.outlineVariant, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final sel = i == index;
              final ic = sel ? items[i].$2 : items[i].$1;
              final fg = sel ? CoachColors.primaryContainer : CoachColors.onSurfaceVariant;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: sel ? CoachColors.secondaryContainer.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ic, size: 22, color: fg),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
