import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/swimflow_providers.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';
import '../../widgets/performance_goal_panel.dart';

class CoachAnalyticsScreen extends ConsumerStatefulWidget {
  const CoachAnalyticsScreen({super.key});

  @override
  ConsumerState<CoachAnalyticsScreen> createState() => _CoachAnalyticsScreenState();
}

class _CoachAnalyticsScreenState extends ConsumerState<CoachAnalyticsScreen> {
  String? _athleteId;

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(coachAthletesProvider);

    return Scaffold(
      body: CoachPageBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CoachFlowHeader(),
            Expanded(
              child: athletesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет пловцов в группе',
                        style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                      ),
                    );
                  }
                  final sorted = [...list]..sort((a, b) => a.displayName.compareTo(b.displayName));
                  final selectedId = _athleteId ?? sorted.first.uid;
                  if (_athleteId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _athleteId = sorted.first.uid);
                    });
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: CoachGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedId,
                              isExpanded: true,
                              items: [
                                for (final a in sorted)
                                  DropdownMenuItem(
                                    value: a.uid,
                                    child: Text(a.displayName),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _athleteId = v),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PerformanceGoalPanel(
                          athleteUid: selectedId,
                          coachMode: true,
                          useCoachTheme: true,
                        ),
                      ),
                    ],
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
