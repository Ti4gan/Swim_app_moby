import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:swim_app/dev/seed_full_reset.dart';
import 'package:swim_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _SeedApp());
}

class _SeedApp extends StatefulWidget {
  const _SeedApp();

  @override
  State<_SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<_SeedApp> {
  String _line = '…';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _line = 'Запуск полной перезагрузки БД…');
    try {
      final r = await runFullResetSeed();
      setState(() => _line = r);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      exit(0);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      setState(() => _line = 'ОШИБКА: $e');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SelectableText(_line, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
          ),
        ),
      ),
    );
  }
}
