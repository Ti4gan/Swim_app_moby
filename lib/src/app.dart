import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'swimflow/providers/push_notification_providers.dart';
import 'swimflow/router/stitch_router.dart';
import 'swimflow/theme/app_theme.dart';

class SwimApp extends ConsumerStatefulWidget {
  const SwimApp({super.key});

  @override
  ConsumerState<SwimApp> createState() => _SwimAppState();
}

class _SwimAppState extends ConsumerState<SwimApp> {
  @override
  void initState() {
    super.initState();
    unawaited(initializeDateFormatting('ru'));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushNotificationsBindingProvider);
    final router = ref.watch(stitchRouterProvider);
    return MaterialApp.router(
      title: 'SwimFlow',
      debugShowCheckedModeBanner: false,
      theme: StitchAppTheme.light,
      themeMode: ThemeMode.light,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
