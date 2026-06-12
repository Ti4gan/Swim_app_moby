import '../models/coach_training_plan.dart';

const List<double> _tierScores = [2, 5, 8, 10];

double coachWeightedIntensity01(List<CoachPlanInterval> intervals) {
  var vol = 0.0;
  var sum = 0.0;
  for (final i in intervals) {
    final v = i.volumeMeters.toDouble();
    if (v <= 0) continue;
    final tier = i.intensityTier.clamp(0, 3);
    vol += v;
    sum += v * _tierScores[tier];
  }
  if (vol <= 0) return 0;
  return (sum / vol).clamp(0.0, 10.0);
}

String coachIntensityLabelRu(double score01) {
  if (score01 <= 0) return '—';
  final s = score01.round().clamp(1, 10);
  String short;
  if (score01 < 3.5) {
    short = 'Низ';
  } else if (score01 < 6) {
    short = 'Сред';
  } else if (score01 < 8.5) {
    short = 'Выс';
  } else {
    short = 'MAX';
  }
  return '$short $s/10';
}
