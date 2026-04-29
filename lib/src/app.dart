import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_providers.dart';

class SwimApp extends ConsumerWidget {
  const SwimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('=== SwimApp.build START ===');
    final router = ref.watch(appRouterProvider);
    print('Router obtained');
    print('=== SwimApp.build END ===');
    return MaterialApp.router(
      title: 'Swim Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
