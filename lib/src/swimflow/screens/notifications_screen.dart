import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/swimmer_notifications_providers.dart';
import '../theme/tokens.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

class StitchNotificationsScreen extends ConsumerStatefulWidget {
  const StitchNotificationsScreen({super.key});

  @override
  ConsumerState<StitchNotificationsScreen> createState() => _StitchNotificationsScreenState();
}

class _StitchNotificationsScreenState extends ConsumerState<StitchNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = ref.read(swimmerCoachNotificationsProvider);
      ref.read(seenNotificationIdsProvider.notifier).markAllSeen(
            items.map((n) => n.workoutId),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(swimmerCoachNotificationsProvider);
    final seen = ref.watch(seenNotificationIdsProvider).valueOrNull ?? {};

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StitchSubpageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Уведомления',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Записи тренировок от тренера',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: StitchColors.onSurfaceVariant,
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
                          style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant),
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
                        final unread = !seen.contains(n.workoutId);
                        return Material(
                          color: StitchColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () {
                              ref.read(seenNotificationIdsProvider.notifier).markSeen(n.workoutId);
                              context.push('/workout/${n.workoutId}');
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: unread
                                      ? StitchColors.primary.withValues(alpha: 0.25)
                                      : StitchColors.primary.withValues(alpha: 0.08),
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
                                      color: StitchColors.primaryFixed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.pool_rounded, color: StitchColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Новая тренировка',
                                          style: GoogleFonts.lexend(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: StitchColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          n.title,
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${n.distanceMeters.round()} м · ${DateFormat('d MMMM, HH:mm', 'ru').format(n.scheduledAt)}',
                                          style: Theme.of(context).textTheme.bodySmall,
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
                                        color: StitchColors.secondary,
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
    );
  }
}
