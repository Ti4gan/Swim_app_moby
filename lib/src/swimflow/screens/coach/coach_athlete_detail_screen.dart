import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/coach_athlete_dossier.dart';
import '../../models/linked_athlete.dart';
import '../../models/swimflow_workout.dart';
import '../../providers/data_refresh.dart';
import '../../providers/swimflow_providers.dart';
import '../../widgets/swimflow_refresh.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_athlete_detail_widgets.dart';
import '../../widgets/coach_widgets.dart';
import '../../widgets/performance_goal_panel.dart';
import '../../widgets/swimflow_workout_list_card.dart';

class CoachAthleteDetailScreen extends ConsumerStatefulWidget {
  const CoachAthleteDetailScreen({
    super.key,
    required this.athleteId,
    this.initialView = 0,
  });

  final String athleteId;
  final int initialView;

  @override
  ConsumerState<CoachAthleteDetailScreen> createState() => _CoachAthleteDetailScreenState();
}

class _CoachAthleteDetailScreenState extends ConsumerState<CoachAthleteDetailScreen> {
  late int _view = widget.initialView.clamp(0, 4);
  DateTime _calendarSelectedDay = DateTime.now();
  bool _dossierSeeded = false;
  final _dFullName = TextEditingController();
  final _dBirth = TextEditingController();
  final _dPhone = TextEditingController();
  final _dCity = TextEditingController();
  final _dNotes = TextEditingController();
  final _dMedical = TextEditingController();
  final _dParent = TextEditingController();
  bool _dossierSaving = false;

  @override
  void dispose() {
    _dFullName.dispose();
    _dBirth.dispose();
    _dPhone.dispose();
    _dCity.dispose();
    _dNotes.dispose();
    _dMedical.dispose();
    _dParent.dispose();
    super.dispose();
  }

  void _seedDossier(CoachAthleteDossier d) {
    if (_dossierSeeded) return;
    _dFullName.text = d.fullName;
    _dBirth.text = d.birthYear?.toString() ?? '';
    _dPhone.text = d.phone;
    _dCity.text = d.city;
    _dNotes.text = d.notes;
    _dMedical.text = d.medicalNotes;
    _dParent.text = d.parentContact;
    _dossierSeeded = true;
  }

  Future<void> _saveDossier() async {
    final repo = ref.read(coachRepositoryProvider);
    if (repo == null) return;
    setState(() => _dossierSaving = true);
    try {
      await repo.upsertAthleteDossier(
        CoachAthleteDossier(
          athleteUid: widget.athleteId,
          fullName: _dFullName.text.trim(),
          birthYear: int.tryParse(_dBirth.text.trim()),
          phone: _dPhone.text.trim(),
          city: _dCity.text.trim(),
          notes: _dNotes.text.trim(),
          medicalNotes: _dMedical.text.trim(),
          parentContact: _dParent.text.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сохранено')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _dossierSaving = false);
    }
  }

  Widget _buildList(List<SwimflowWorkout> list, LinkedAthlete? athlete) {
    final theme = WorkoutListCardTheme.coach(context);
    final weekM = weekTotalMeters(list);
    if (list.isEmpty) {
      return SwimflowRefreshableScroll(
        color: CoachColors.primaryContainer,
        onRefresh: () => refreshCoachAthleteDetail(ref, widget.athleteId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
          SwimflowWorkoutListWeekSummary(weekMeters: weekM, theme: theme),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Пока нет тренировок',
              style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          ],
        ),
      );
    }

    return SwimflowRefreshableScroll(
      color: CoachColors.primaryContainer,
      onRefresh: () => refreshCoachAthleteDetail(ref, widget.athleteId),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        itemCount: list.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SwimflowWorkoutListWeekSummary(weekMeters: weekM, theme: theme),
          );
        }
        final w = list[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SwimflowWorkoutListCard(
            workout: w,
            theme: theme,
            coachView: true,
            onTap: () => context.push('/workout/${w.id}?athleteId=${widget.athleteId}'),
          ),
        );
      },
      ),
    );
  }

  Widget _buildAthleteInfoSection() {
    return CoachSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация о пловце',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ref.watch(coachAthleteDossierFamily(widget.athleteId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (d) {
                  if (!_dossierSeeded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _dossierSeeded) return;
                      _seedDossier(d);
                    });
                  }
                  return Column(
                    children: [
                      TextField(
                        controller: _dFullName,
                        decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dBirth,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(labelText: 'Год рождения', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dPhone,
                        decoration: const InputDecoration(labelText: 'Телефон', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dCity,
                        decoration: const InputDecoration(labelText: 'Город', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dParent,
                        decoration: const InputDecoration(labelText: 'Контакт родителя', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dMedical,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Медицинские пометки',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _dNotes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Рабочие заметки',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _dossierSaving ? null : _saveDossier,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: CoachColors.primaryContainer,
                        ),
                        child: _dossierSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Сохранить'),
                      ),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(coachAthleteWorkoutsFamily(widget.athleteId));
    final athletes = ref.watch(coachAthletesProvider);

    LinkedAthlete? resolvedAthlete;
    final athleteList = athletes.asData?.value;
    if (athleteList != null) {
      for (final a in athleteList) {
        if (a.uid == widget.athleteId) {
          resolvedAthlete = a;
          break;
        }
      }
    }

    final displayName =
        resolvedAthlete?.displayName.isNotEmpty == true ? resolvedAthlete!.displayName : 'Пловец';

    return Theme(
      data: CoachAppTheme.light,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: CoachPageBackground(
          bottomInset: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoachAthleteDetailHeader(
                displayName: displayName,
                athlete: resolvedAthlete,
                onBack: () => context.pop(),
              ),
              CoachAthleteViewTabs(
                selected: _view,
                onChanged: (i) => setState(() => _view = i),
              ),
              Expanded(
                child: workouts.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (list) {
                    if (_view == 0) return _buildList(list, resolvedAthlete);
                    if (_view == 1) {
                      return SwimflowRefreshableScroll(
                        color: CoachColors.primaryContainer,
                        onRefresh: () => refreshCoachAthleteDetail(ref, widget.athleteId),
                        child: CoachAthleteCalendarPanel(
                          workouts: list,
                          athleteId: widget.athleteId,
                          onSelectedDayChanged: (d) => setState(() => _calendarSelectedDay = d),
                        ),
                      );
                    }
                    if (_view == 2) {
                      return CoachAthleteCompetitionsPanel(athleteId: widget.athleteId);
                    }
                    if (_view == 3) {
                      return PerformanceGoalPanel(
                        athleteUid: widget.athleteId,
                        coachMode: true,
                        useCoachTheme: true,
                      );
                    }
                    return SwimflowRefreshableScroll(
                      color: CoachColors.primaryContainer,
                      onRefresh: () => refreshCoachAthleteDetail(ref, widget.athleteId),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        children: [_buildAthleteInfoSection()],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _view == 2 || _view == 3 || _view == 4
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  final date = DateFormat('yyyy-MM-dd').format(
                    _view == 1 ? _calendarSelectedDay : DateTime.now(),
                  );
                  context.push('/coach/record?athleteId=${widget.athleteId}&date=$date');
                },
                backgroundColor: CoachColors.primaryContainer,
                elevation: 4,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Запись',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }
}
