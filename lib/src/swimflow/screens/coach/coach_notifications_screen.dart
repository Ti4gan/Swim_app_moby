import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/coach_notification.dart';
import '../../providers/coach_notifications_providers.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';

class CoachNotificationsScreen extends ConsumerStatefulWidget {
  const CoachNotificationsScreen({super.key});

  @override
  ConsumerState<CoachNotificationsScreen> createState() => _CoachNotificationsScreenState();
}

class _CoachNotificationsScreenState extends ConsumerState<CoachNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = ref.read(coachNotificationsProvider);
      ref.read(seenCoachNotificationIdsProvider.notifier).markAllSeen(
            items.map((n) => n.id),
          );
    });
  }

  void _openNotification(CoachNotification n) {
    ref.read(seenCoachNotificationIdsProvider.notifier).markSeen(n.id);
    switch (n.type) {
      case CoachNotificationType.wellbeing:
        if (n.workoutId != null && n.workoutId!.isNotEmpty) {
          context.push('/workout/${n.workoutId}?athleteId=${n.athleteUid}');
        }
      case CoachNotificationType.competition:
        context.push('/coach/swimmers/${n.athleteUid}?tab=2');
    }
  }

  IconData _iconFor(CoachNotificationType type) {
    return switch (type) {
      CoachNotificationType.wellbeing => Icons.sentiment_satisfied_alt_rounded,
      CoachNotificationType.competition => Icons.emoji_events_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(coachNotificationsProvider);
    final seen = ref.watch(seenCoachNotificationIdsProvider).valueOrNull ?? {};

    return Theme(
      data: CoachAppTheme.light,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: CoachPageBackground(
          bottomInset: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CoachSubpageHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Уведомления',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CoachColors.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Настроение после тренировок и результаты соревнований',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CoachColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Пока нет уведомлений',
                            style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = items[i];
                          final unread = !seen.contains(n.id);
                          return Material(
                            color: CoachColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _openNotification(n),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: unread
                                        ? CoachColors.primaryContainer.withValues(alpha: 0.25)
                                        : CoachColors.outlineVariant.withValues(alpha: 0.35),
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CoachColors.secondaryContainer.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_iconFor(n.type), color: CoachColors.primaryContainer),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: CoachColors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            n.detail,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: CoachColors.onBackground,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n.subtitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: CoachColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (unread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: const BoxDecoration(
                                          color: CoachColors.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
