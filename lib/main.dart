import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'src/app.dart';

Future<void> main() async {
  print('=== MAIN START ===');
  WidgetsFlutterBinding.ensureInitialized();
  print('Binding initialized');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized');

  runApp(const ProviderScope(child: SwimApp()));
  print('RunApp called');
}
