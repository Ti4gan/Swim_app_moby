import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/performance_report.dart';

class ReportService {
  Future<String> exportPerformanceReport(PerformanceReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/performance_report.json');
    final payload = {
      'totalPlans': report.totalPlans,
      'totalResults': report.totalResults,
      'completionPercent': report.completionPercent,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  Future<String> exportPerformanceReportCsv(PerformanceReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/performance_report.csv');
    final rows = <String>[
      'metric,value',
      'totalPlans,${report.totalPlans}',
      'totalResults,${report.totalResults}',
      'completionPercent,${report.completionPercent.toStringAsFixed(2)}',
    ];
    await file.writeAsString(rows.join('\n'));
    return file.path;
  }

  Future<String> exportPerformanceReportPdfStub(PerformanceReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/performance_report.pdf.txt');
    final content = [
      'Performance Report',
      'totalPlans: ${report.totalPlans}',
      'totalResults: ${report.totalResults}',
      'completionPercent: ${report.completionPercent.toStringAsFixed(2)}',
    ].join('\n');
    await file.writeAsString(content);
    return file.path;
  }
}
