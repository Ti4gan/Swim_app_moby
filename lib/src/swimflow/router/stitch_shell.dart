import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user_role.dart';
import '../providers/swimflow_providers.dart';
import '../screens/session_loading_screen.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/swimflow_notice_overlay.dart';

class StitchShell extends ConsumerWidget {
  const StitchShell({
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
    if (role == AppUserRole.coach) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final loc = GoRouterState.of(context).matchedLocation;
        if (!loc.startsWith('/coach/')) {
          context.go('/coach/dashboard');
        }
      });
      return const SessionLoadingScreen();
    }

    return Scaffold(
      extendBody: true,
      body: SwimflowNoticeHost(child: navigationShell),
      bottomNavigationBar: StitchBottomNav(
        index: navigationShell.currentIndex,
        onChanged: navigationShell.goBranch,
      ),
    );
  }
}
