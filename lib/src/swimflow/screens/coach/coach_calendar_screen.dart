import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/linked_athlete.dart';
import '../../models/swimflow_workout.dart';
import '../../providers/data_refresh.dart';
import '../../providers/swimflow_providers.dart';
import '../../widgets/swimflow_refresh.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_athlete_detail_widgets.dart';
import '../../widgets/coach_widgets.dart';

class CoachCalendarScreen extends ConsumerStatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  ConsumerState<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends ConsumerState<CoachCalendarScreen> {
  DateTime _selected = DateTime.now();

  List<SwimflowWorkout> _workoutsForDay(List<SwimflowWorkout> list, DateTime day) {
    final out = <SwimflowWorkout>[];
    for (final w in list) {
      if (w.scheduledAt.year == day.year &&
          w.scheduledAt.month == day.month &&
          w.scheduledAt.day == day.day) {
        out.add(w);
      }
    }
    out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final teamW = ref.watch(coachTeamWorkoutsProvider);
    final athletes = ref.watch(coachAthletesProvider).valueOrNull ?? const <LinkedAthlete>[];
    final athleteNames = {for (final a in athletes) a.uid: a.displayName};

    return Scaffold(
      body: CoachPageBackground(
        child: Column(
          children: [
            const CoachFlowHeader(),
            Expanded(
              child: SwimflowRefreshableScroll(
                color: CoachColors.primaryContainer,
                onRefresh: () => refreshCoachTeamData(ref),
                child: teamW.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (list) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        CoachMonthCalendarCard(
                          workouts: list,
                          onSelectedDayChanged: (d) => setState(() => _selected = d),
                        ),
                        const SizedBox(height: 16),
                        CoachAthleteDayPreview(
                          day: _selected,
                          workouts: _workoutsForDay(list, _selected),
                          athleteNames: athleteNames,
                          onWorkoutTap: (w) {
                            final uid = w.athleteUid;
                            if (uid == null || uid.isEmpty) return;
                            context.push('/workout/${w.id}?athleteId=$uid');
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
