import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/firestore_collections.dart';
import '../../data/services/report_service.dart';
import '../../domain/models/coach_athlete_report.dart';
import '../../domain/models/performance_report.dart';
import '../../domain/models/report_period.dart';
import '../../domain/models/training_result.dart';
import '../../domain/models/user_role.dart';
import 'admin_coach_providers.dart';
import 'athlete_providers.dart';
import 'auth_providers.dart';
import 'firebase_providers.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService();
});

final reportPeriodProvider = StateProvider<ReportPeriod>((ref) => ReportPeriod.week);

final selectedAthleteIdProvider = StateProvider<String?>((ref) => null);

final allResultsProvider = StreamProvider<List<TrainingResult>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.results)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => TrainingResult.fromMap(doc.id, doc.data())).toList());
});

final performanceReportProvider = Provider<PerformanceReport>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  final period = ref.watch(reportPeriodProvider);
  if (user == null) {
    return const PerformanceReport(totalPlans: 0, totalResults: 0, completionPercent: 0);
  }

  final periodStart = _startDateForPeriod(period);

  if (user.role == UserRole.coach) {
    final plans = ref.watch(coachPlansProvider).valueOrNull ?? const [];
    final allResults = ref.watch(allResultsProvider).valueOrNull ?? const [];
    final selectedAthleteId = ref.watch(selectedAthleteIdProvider);

    final filteredPlans = plans.where((plan) {
      final inPeriod = plan.createdAt == null || !plan.createdAt!.isBefore(periodStart);
      final byAthlete = selectedAthleteId == null || selectedAthleteId == plan.athleteId;
      return inPeriod && byAthlete;
    }).toList();

    final planIds = filteredPlans.map((p) => p.id).toSet();
    final filteredResults = allResults.where((result) {
      final inPeriod = result.createdAt == null || !result.createdAt!.isBefore(periodStart);
      return planIds.contains(result.trainingPlanId) && inPeriod;
    }).toList();

    final totalPlans = filteredPlans.length;
    final totalResults = filteredResults.length;
    final completion = totalPlans == 0 ? 0.0 : (totalResults / totalPlans) * 100;

    return PerformanceReport(
      totalPlans: totalPlans,
      totalResults: totalResults,
      completionPercent: completion,
    );
  }

  final plans = ref.watch(athletePlansProvider).valueOrNull ?? const [];
  final results = ref.watch(athleteResultsProvider).valueOrNull ?? const [];

  final filteredPlans = plans.where((plan) {
    return plan.createdAt == null || !plan.createdAt!.isBefore(periodStart);
  }).toList();
  final filteredResults = results.where((result) {
    return result.createdAt == null || !result.createdAt!.isBefore(periodStart);
  }).toList();

  final totalPlans = filteredPlans.length;
  final totalResults = filteredResults.length;
  final completion = totalPlans == 0 ? 0.0 : (totalResults / totalPlans) * 100;

  return PerformanceReport(
    totalPlans: totalPlans,
    totalResults: totalResults,
    completionPercent: completion,
  );
});

final coachAthleteReportsProvider = Provider<List<CoachAthleteReport>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null || user.role != UserRole.coach) {
    return const [];
  }

  final period = ref.watch(reportPeriodProvider);
  final periodStart = _startDateForPeriod(period);
  final athletes = ref.watch(coachAthletesProvider).valueOrNull ?? const [];
  final plans = ref.watch(coachPlansProvider).valueOrNull ?? const [];
  final allResults = ref.watch(allResultsProvider).valueOrNull ?? const [];

  final rows = <CoachAthleteReport>[];
  for (final athlete in athletes) {
    final athletePlans = plans.where((plan) {
      final byAthlete = plan.athleteId == athlete.id;
      final inPeriod = plan.createdAt == null || !plan.createdAt!.isBefore(periodStart);
      return byAthlete && inPeriod;
    }).toList();

    final planIds = athletePlans.map((p) => p.id).toSet();
    final athleteResults = allResults.where((result) {
      final inPeriod = result.createdAt == null || !result.createdAt!.isBefore(periodStart);
      return planIds.contains(result.trainingPlanId) && inPeriod;
    }).toList();

    final plannedCount = athletePlans.length;
    final completedCount = athleteResults.length;
    final completionPercent = plannedCount == 0 ? 0.0 : (completedCount / plannedCount) * 100;
    final plannedDistanceMeters = athletePlans.fold<double>(0, (sum, item) => sum + item.distanceMeters);
    final completedDistanceMeters = athleteResults.fold<double>(0, (sum, item) => sum + item.distanceMeters);

    rows.add(
      CoachAthleteReport(
        athleteId: athlete.id,
        athleteName: athlete.fullName,
        plannedCount: plannedCount,
        completedCount: completedCount,
        completionPercent: completionPercent,
        plannedDistanceMeters: plannedDistanceMeters,
        completedDistanceMeters: completedDistanceMeters,
      ),
    );
  }

  rows.sort((a, b) => b.completionPercent.compareTo(a.completionPercent));
  return rows;
});

DateTime _startDateForPeriod(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.day:
      return DateTime(now.year, now.month, now.day);
    case ReportPeriod.week:
      return now.subtract(Duration(days: now.weekday - 1));
    case ReportPeriod.month:
      return DateTime(now.year, now.month, 1);
  }
}
