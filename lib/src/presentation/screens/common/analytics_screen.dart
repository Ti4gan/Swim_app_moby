import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/athlete_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(athleteResultsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: results.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Нет результатов для графика'));
          }
          final spots = <FlSpot>[];
          for (var i = 0; i < items.length; i++) {
            final value = items[i].distanceMeters;
            spots.add(FlSpot(i.toDouble(), value));
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: spots,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
