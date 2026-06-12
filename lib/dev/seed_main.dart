import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:swim_app/dev/seed_swimflow_demo.dart';
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
    setState(() => _line = 'Сидирование…');
    try {
      final r = await runSwimflowDemoSeed();
      setState(() => _line = r);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      exit(0);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      setState(() => _line = '$e');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      exit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(_line, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ),
    );
  }
}
