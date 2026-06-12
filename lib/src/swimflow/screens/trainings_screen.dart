import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_refresh.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/swimflow_refresh.dart';
import '../widgets/swimflow_workout_list_card.dart';

class StitchTrainingsScreen extends ConsumerWidget {
  const StitchTrainingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(swimflowWorkoutsProvider);
    final list = workouts.valueOrNull ?? [];
    final weekM = weekTotalMeters(list);
    final cardTheme = WorkoutListCardTheme.stitch(context);

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 96,
        child: Column(
          children: [
            const StitchMainShellHeader(),
            Expanded(
              child: SwimflowRefreshableScroll(
                onRefresh: () => refreshSwimmerWorkouts(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                  Text('Мои тренировки', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  SwimflowWorkoutListWeekSummary(weekMeters: weekM, theme: cardTheme),
                  const SizedBox(height: 24),
                  workouts.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Тренировки появятся после записи тренером.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: StitchColors.onSurfaceVariant,
                                ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final w in list)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SwimflowWorkoutListCard(
                                workout: w,
                                theme: cardTheme,
                                onTap: () => context.push('/workout/${w.id}'),
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('$e'),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
