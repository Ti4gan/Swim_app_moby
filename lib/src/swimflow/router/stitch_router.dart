import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import '../auth/go_router_refresh.dart';
import '../models/app_user_role.dart';
import '../providers/swimflow_providers.dart';
import '../screens/calendar_screen.dart';
import '../screens/coach/coach_analytics_screen.dart';
import '../screens/coach/coach_athlete_detail_screen.dart';
import '../screens/coach/coach_athletes_screen.dart';
import '../screens/coach/coach_calendar_screen.dart';
import '../screens/coach/coach_dashboard_screen.dart';
import '../screens/coach/coach_notifications_screen.dart';
import '../screens/coach/coach_profile_screen.dart';
import '../screens/coach/coach_verification_screen.dart';
import '../screens/competition_swim_form_screen.dart';
import '../screens/competition_swims_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/record_training_screen.dart';
import '../screens/register_screen.dart';
import '../screens/session_loading_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/trainings_screen.dart';
import '../screens/workout_detail_screen.dart';
import 'coach_shell.dart';
import 'stitch_shell.dart';

final GlobalKey<NavigatorState> swimRootNavigatorKey = GlobalKey<NavigatorState>();

bool _swimmerTabPath(String loc) {
  return loc == '/home' ||
      loc == '/trainings' ||
      loc == '/competitions' ||
      loc == '/calendar' ||
      loc == '/profile';
}

String? _sessionLoadingRedirect(String loc) {
  if (loc == '/session-loading') return null;
  return '/session-loading';
}

final stitchRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshListenableProvider);

  ref.listen(authStateProvider, (prev, next) {
    if (prev?.valueOrNull?.uid != next.valueOrNull?.uid) {
      ref.invalidate(swimflowProfileProvider);
    }
    refresh.notifyRouter();
  });
  ref.listen(swimflowProfileProvider, (_, __) => refresh.notifyRouter());

  return GoRouter(
    navigatorKey: swimRootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading) return null;
      final user = authAsync.valueOrNull;
      if (user == null) {
        if (loc == '/login' || loc == '/register') return null;
        return '/login';
      }

      final profAsync = ref.read(swimflowProfileProvider);
      if (profAsync.isLoading || profAsync.hasError) {
        return _sessionLoadingRedirect(loc);
      }
      final p = profAsync.valueOrNull;
      if (p == null) {
        return _sessionLoadingRedirect(loc);
      }

      final isCoach = p.role == AppUserRole.coach;

      if (isCoach) {
        final gate = p.coachMustPassVerification;
        if (gate) {
          if (loc == '/login' ||
            loc == '/register' ||
            loc == '/session-loading') {
          return '/coach/verification';
        }
          if (loc != '/coach/verification') return '/coach/verification';
          return null;
        }
        if (loc == '/coach/verification') return '/coach/dashboard';
        if (loc == '/login' ||
            loc == '/register' ||
            loc == '/session-loading') {
          return '/coach/dashboard';
        }
        if (loc == '/coach/notifications') return null;
        if (loc.startsWith('/coach/')) return null;
        if (loc.startsWith('/workout/')) {
          final athleteId = state.uri.queryParameters['athleteId'];
          if (athleteId != null && athleteId.isNotEmpty) return null;
          return '/coach/dashboard';
        }
        if (_swimmerTabPath(loc) ||
            loc == '/record' ||
            loc == '/settings' ||
            loc.startsWith('/competitions')) {
          return '/coach/dashboard';
        }
        return null;
      }

      if (loc.startsWith('/coach/')) return '/home';
      if (loc == '/login' ||
          loc == '/register' ||
          loc == '/session-loading') {
        return '/home';
      }
      if (loc == '/record') return '/home';
      if (loc == '/notifications') return null;
      return null;
    },
    routes: [
      GoRoute(
        path: '/session-loading',
        builder: (context, state) => const SessionLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const StitchLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const StitchRegisterScreen(),
      ),
      GoRoute(
        path: '/coach/verification',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => const CoachVerificationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StitchShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const StitchDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/trainings',
              builder: (context, state) => const StitchTrainingsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/competitions',
              builder: (context, state) => const StitchCompetitionSwimsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const StitchCalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const StitchProfileScreen(),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CoachShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/dashboard',
              builder: (context, state) => const CoachDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/swimmers',
              builder: (context, state) => const CoachAthletesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/calendar',
              builder: (context, state) => const CoachCalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/analytics',
              builder: (context, state) => const CoachAnalyticsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach/profile',
              builder: (context, state) => const CoachProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/coach/notifications',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => const CoachNotificationsScreen(),
      ),
      GoRoute(
        path: '/coach/record',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) {
          final athleteId = state.uri.queryParameters['athleteId'];
          final dateRaw = state.uri.queryParameters['date'];
          DateTime? initialDate;
          if (dateRaw != null && dateRaw.isNotEmpty) {
            final parsed = DateTime.tryParse(dateRaw);
            if (parsed != null) {
              initialDate = DateTime(parsed.year, parsed.month, parsed.day);
            }
          }
          return StitchRecordTrainingScreen(
            initialAthleteUid: athleteId?.isNotEmpty == true ? athleteId : null,
            initialScheduledDate: initialDate,
          );
        },
      ),
      GoRoute(
        path: '/coach/swimmers/:athleteId',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return CoachAthleteDetailScreen(
            athleteId: state.pathParameters['athleteId']!,
            initialView: tab.clamp(0, 4),
          );
        },
      ),
      GoRoute(
        path: '/workout/:id',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => StitchWorkoutDetailScreen(
          workoutId: state.pathParameters['id']!,
          athleteUid: state.uri.queryParameters['athleteId'],
        ),
      ),
      GoRoute(
        path: '/competitions/new',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => const StitchCompetitionSwimFormScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => const StitchSettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: swimRootNavigatorKey,
        builder: (context, state) => const StitchNotificationsScreen(),
      ),
    ],
  );
});
