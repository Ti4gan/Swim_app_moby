import '../models/competition_swim.dart';
import '../models/performance_goal.dart';

class PerformanceGoalProgress {
  const PerformanceGoalProgress({
    required this.goal,
    required this.points,
    required this.bestTimeCentiseconds,
    required this.gapCentiseconds,
    required this.achieved,
  });

  final PerformanceGoal goal;
  final List<PerformanceGoalChartPoint> points;
  final int? bestTimeCentiseconds;
  final int gapCentiseconds;
  final bool achieved;
}

class PerformanceGoalChartPoint {
  const PerformanceGoalChartPoint({
    required this.date,
    required this.timeCentiseconds,
  });

  final DateTime date;
  final int timeCentiseconds;
}

PerformanceGoalProgress buildPerformanceGoalProgress({
  required PerformanceGoal goal,
  required List<CompetitionSwim> swims,
}) {
  final matched = swims
      .where(
        (s) => goal.matchesSwim(
          strokeKey: s.strokeKey,
          distanceMeters: s.distanceMeters,
          poolLengthMeters: s.poolLengthMeters,
        ),
      )
      .where((s) => s.timeCentiseconds > 0)
      .toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  final points = matched
      .map((s) => PerformanceGoalChartPoint(date: s.eventDate, timeCentiseconds: s.timeCentiseconds))
      .toList();

  int? best;
  for (final s in matched) {
    if (best == null || s.timeCentiseconds < best) best = s.timeCentiseconds;
  }

  final achieved = best != null && best <= goal.targetTimeCentiseconds;
  final gap = best == null
      ? goal.targetTimeCentiseconds
      : (best - goal.targetTimeCentiseconds).clamp(0, 99999999);

  return PerformanceGoalProgress(
    goal: goal,
    points: points,
    bestTimeCentiseconds: best,
    gapCentiseconds: gap,
    achieved: achieved,
  );
}

enum PerformanceGoalStatusKind {
  achieved,
  latestIsBestNotMet,
  latestWorseThanBest,
  noResults,
}

PerformanceGoalStatusKind performanceGoalStatusKind({
  required PerformanceGoalProgress progress,
  required List<CompetitionSwim> swims,
}) {
  if (progress.achieved) return PerformanceGoalStatusKind.achieved;
  final matched = swims
      .where(
        (s) => progress.goal.matchesSwim(
          strokeKey: s.strokeKey,
          distanceMeters: s.distanceMeters,
          poolLengthMeters: s.poolLengthMeters,
        ),
      )
      .where((s) => s.timeCentiseconds > 0)
      .toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  if (matched.isEmpty || progress.bestTimeCentiseconds == null) {
    return PerformanceGoalStatusKind.noResults;
  }
  final latest = matched.last.timeCentiseconds;
  final best = progress.bestTimeCentiseconds!;
  if (latest <= best) return PerformanceGoalStatusKind.latestIsBestNotMet;
  return PerformanceGoalStatusKind.latestWorseThanBest;
}

String formatTimeCentiseconds(int cs) {
  if (cs <= 0) return '—';
  final totalSec = cs ~/ 100;
  final hundredths = cs % 100;
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  if (m > 0) {
    return '$m:${s.toString().padLeft(2, '0')},${hundredths.toString().padLeft(2, '0')}';
  }
  return '$s,${hundredths.toString().padLeft(2, '0')}';
}

int? parseTimeCentisecondsInput(String raw) {
  final t = raw.trim();
  final m = RegExp(r'^(\d{1,2}):(\d{2})[.,](\d{2})$').firstMatch(t);
  if (m == null) return null;
  final min = int.tryParse(m.group(1)!);
  final sec = int.tryParse(m.group(2)!);
  final cs = int.tryParse(m.group(3)!);
  if (min == null || sec == null || cs == null) return null;
  if (sec >= 60 || cs >= 100) return null;
  return min * 6000 + sec * 100 + cs;
}

double centisecondsToChartY(int cs) => cs / 100.0;

class GoalChartYRange {
  const GoalChartYRange({
    required this.minY,
    required this.maxY,
    required this.tickInterval,
  });

  final double minY;
  final double maxY;
  final double tickInterval;
}

double _niceTickIntervalSeconds(double span, {int maxTicks = 4}) {
  if (span <= 0) return 1;
  final raw = span / maxTicks;
  const steps = [0.5, 1.0, 2.0, 5.0, 10.0, 15.0, 30.0, 60.0];
  for (final s in steps) {
    if (raw <= s) return s;
  }
  return (raw / 60).ceil() * 60.0;
}

double _chartPaddingFraction(int distanceMeters) {
  if (distanceMeters <= 50) return 0.14;
  if (distanceMeters <= 100) return 0.11;
  if (distanceMeters <= 200) return 0.09;
  if (distanceMeters <= 400) return 0.08;
  return 0.07;
}

double _chartMinSpanShareOfGoal(int distanceMeters) {
  if (distanceMeters <= 50) return 0.045;
  if (distanceMeters <= 100) return 0.055;
  if (distanceMeters <= 200) return 0.065;
  if (distanceMeters <= 400) return 0.075;
  return 0.085;
}

GoalChartYRange goalChartYRange(PerformanceGoalProgress progress) {
  final goalCs = progress.goal.targetTimeCentiseconds;
  final ys = <double>[
    centisecondsToChartY(goalCs),
    for (final p in progress.points) centisecondsToChartY(p.timeCentiseconds),
  ];

  var dataMin = ys.reduce((a, b) => a < b ? a : b);
  var dataMax = ys.reduce((a, b) => a > b ? a : b);
  var span = dataMax - dataMin;

  final goalY = centisecondsToChartY(goalCs);
  final minSpan = goalY * _chartMinSpanShareOfGoal(progress.goal.distanceMeters);
  if (span < minSpan) {
    final mid = (dataMin + dataMax) / 2;
    dataMin = mid - minSpan / 2;
    dataMax = mid + minSpan / 2;
    span = minSpan;
  }

  final pad = span * _chartPaddingFraction(progress.goal.distanceMeters);
  final rawMin = dataMin - pad;
  final rawMax = dataMax + pad;
  final paddedSpan = rawMax - rawMin;
  final tick = _niceTickIntervalSeconds(paddedSpan);
  final minY = (rawMin / tick).floor() * tick;
  final maxY = (rawMax / tick).ceil() * tick;
  return GoalChartYRange(minY: minY, maxY: maxY, tickInterval: tick);
}
