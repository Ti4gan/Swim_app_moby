import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user_role.dart';
import '../providers/swimflow_providers.dart';
import '../screens/session_loading_screen.dart';
import '../theme/coach_theme.dart';
import '../widgets/coach_widgets.dart';

class CoachShell extends ConsumerWidget {
  const CoachShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prof = ref.watch(swimflowProfileProvider);
    if (prof.isLoading || prof.hasError) {
      return const SessionLoadingScreen();
    }
    final role = prof.valueOrNull?.role;
    if (role != null && role != AppUserRole.coach) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go('/home');
      });
      return const SessionLoadingScreen();
    }

    return Theme(
      data: CoachAppTheme.light,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        extendBody: false,
        body: navigationShell,
        bottomNavigationBar: CoachBottomNav(
          index: navigationShell.currentIndex,
          onChanged: navigationShell.goBranch,
        ),
      ),
    );
  }
}
