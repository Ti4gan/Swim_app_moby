import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/performance_goal_logic.dart';

class PerformanceGoalChart extends StatelessWidget {
  const PerformanceGoalChart({
    required this.progress,
    required this.primary,
    this.height = 200,
    super.key,
  });

  final PerformanceGoalProgress progress;
  final Color primary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < progress.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), centisecondsToChartY(progress.points[i].timeCentiseconds)));
    }
    final targetY = centisecondsToChartY(progress.goal.targetTimeCentiseconds);
    final yRange = goalChartYRange(progress);
    final minY = yRange.minY;
    final maxY = yRange.maxY;
    final yTick = yRange.tickInterval;

    if (progress.points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Нужно минимум 2 результата\nна этой дистанции',
            textAlign: TextAlign.center,
            style: TextStyle(color: primary.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yTick,
            getDrawingHorizontalLine: (v) => FlLine(color: primary.withValues(alpha: 0.12), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: yTick,
                getTitlesWidget: (v, meta) {
                  final tickIndex = ((v - minY) / yTick).round();
                  final tickValue = minY + tickIndex * yTick;
                  if ((v - tickValue).abs() > yTick * 0.05) {
                    return const SizedBox.shrink();
                  }
                  if (tickValue < minY - 0.001 || tickValue > maxY + 0.001) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    formatTimeCentiseconds((tickValue * 100).round()),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= progress.points.length) return const SizedBox.shrink();
                  if ((v - i).abs() > 0.01) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d.MM', 'ru').format(progress.points[i].date),
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primary,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: primary.withValues(alpha: 0.12),
              ),
            ),
            LineChartBarData(
              spots: [FlSpot(0, targetY), FlSpot((spots.length - 1).toDouble(), targetY)],
              isCurved: false,
              color: const Color(0xFF2E7D32),
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
