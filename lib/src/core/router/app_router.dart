import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/user_role.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/screens/admin/admin_coach_approval_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/coach/coach_athletes_screen.dart';
import '../../presentation/screens/coach/create_plan_screen.dart';
import '../../presentation/screens/common/analytics_screen.dart';
import '../../presentation/screens/common/dashboard_screen.dart';
import '../../presentation/screens/common/diary_screen.dart';
import '../../presentation/screens/common/profile_screen.dart';
import '../../presentation/screens/common/reports_screen.dart';
import '../../presentation/screens/common/splash_screen.dart';
import '../../presentation/screens/common/training_details_screen.dart';
import '../../presentation/screens/common/trainings_list_screen.dart';
import '../../presentation/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.watch(authSessionProvider);
      final isAuthRoute = state.fullPath == '/login' || state.fullPath == '/register';
      final isSplash = state.fullPath == '/splash';

      if (auth.isLoading) return isSplash ? null : '/splash';
      final user = auth.valueOrNull;
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }
      if (isAuthRoute || isSplash) return '/dashboard';

      if (state.fullPath == '/admin/coach-approval' && user.role != UserRole.admin) {
        return '/dashboard';
      }
      if ((state.fullPath == '/coach/athletes' || state.fullPath == '/coach/create-plan') &&
          (user.role != UserRole.coach || !user.approved)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/trainings', builder: (context, state) => const TrainingsListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/diary', builder: (context, state) => const DiaryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/training/:id',
        builder: (context, state) => TrainingDetailsScreen(trainingId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/coach/athletes', builder: (context, state) => const CoachAthletesScreen()),
      GoRoute(path: '/coach/create-plan', builder: (context, state) => const CreatePlanScreen()),
      GoRoute(
        path: '/admin/coach-approval',
        builder: (context, state) => const AdminCoachApprovalScreen(),
      ),
    ],
  );
});
