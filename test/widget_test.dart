import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:swim_app/firebase_options.dart';
import 'package:swim_app/src/app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    await initializeDateFormatting('ru');
  });

  testWidgets('SwimApp строится без падения', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SwimApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
