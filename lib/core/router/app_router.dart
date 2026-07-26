import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/admin/presentation/admin_broadcast_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_promocodes_screen.dart';
import '../../features/admin/presentation/admin_redemptions_screen.dart';
import '../../features/admin/presentation/admin_reports_screen.dart';
import '../../features/admin/presentation/admin_rewards_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/admin/presentation/widgets/admin_gate.dart';
import '../../features/auth/presentation/email_auth_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/earn/presentation/earn_screen.dart';
import '../../features/earn/presentation/offerwall_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_shell.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/redemption/presentation/redemptions_screen.dart';
import '../../features/redemption/presentation/rewards_screen.dart';
import '../../features/referrals/presentation/referrals_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/vip/presentation/vip_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../config/providers.dart';
import '../services/preferences_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/premium_loader.dart';
import 'routes.dart';

part 'splash_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Builds the app's [GoRouter]. Redirects gate the app behind onboarding and
/// authentication; the five primary tabs live in a [StatefulShellRoute] so each
/// keeps its own stack.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      // While auth is resolving, stay on splash.
      if (authState.isLoading) return null;

      final loggedIn = authState.valueOrNull != null;
      final onboardingSeen = ref.read(preferencesProvider).onboardingSeen;
      final loc = state.matchedLocation;

      final onSplash = loc == AppRoutes.splash;
      final inAuthFlow = loc.startsWith('/auth') ||
          loc == AppRoutes.welcome ||
          loc == AppRoutes.onboarding;

      if (!onboardingSeen && !loggedIn) {
        return onSplash || inAuthFlow ? null : AppRoutes.onboarding;
      }

      if (!loggedIn) {
        return inAuthFlow ? null : AppRoutes.welcome;
      }

      // Logged in but sitting on an auth/splash route → go home.
      if (onSplash || inAuthFlow) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(
          path: AppRoutes.welcome,
          pageBuilder: (c, s) => _fadePage(s, const WelcomeScreen())),
      GoRoute(
          path: AppRoutes.emailAuth,
          pageBuilder: (c, s) => _fadePage(s, const EmailAuthScreen())),
      GoRoute(
          path: AppRoutes.phoneAuth,
          pageBuilder: (c, s) => _fadePage(s, const PhoneAuthScreen())),

      // Detail routes (pushed over the shell) — fade+slide transitions.
      GoRoute(
          path: AppRoutes.offerwall,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const OfferwallScreen())),
      GoRoute(
          path: AppRoutes.wallet,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const WalletScreen())),
      GoRoute(
          path: AppRoutes.redemptions,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const RedemptionsScreen())),
      GoRoute(
          path: AppRoutes.referrals,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const ReferralsScreen())),
      GoRoute(
          path: AppRoutes.vip,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const VipScreen())),
      GoRoute(
          path: AppRoutes.achievements,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const AchievementsScreen())),
      GoRoute(
          path: AppRoutes.notifications,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const NotificationsScreen())),
      GoRoute(
          path: AppRoutes.settings,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const SettingsScreen())),
      GoRoute(
          path: AppRoutes.leaderboard,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) => _fadePage(s, const LeaderboardScreen())),

      // Admin dashboard — every screen wrapped in AdminGate (claim check).
      GoRoute(
          path: AppRoutes.admin,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminDashboardScreen()))),
      GoRoute(
          path: AppRoutes.adminRedemptions,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminRedemptionsScreen()))),
      GoRoute(
          path: AppRoutes.adminUsers,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminUsersScreen()))),
      GoRoute(
          path: AppRoutes.adminPromocodes,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminPromocodesScreen()))),
      GoRoute(
          path: AppRoutes.adminBroadcast,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminBroadcastScreen()))),
      GoRoute(
          path: AppRoutes.adminRewards,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminRewardsScreen()))),
      GoRoute(
          path: AppRoutes.adminReports,
          parentNavigatorKey: _rootKey,
          pageBuilder: (c, s) =>
              _fadePage(s, const AdminGate(child: AdminReportsScreen()))),

      // Bottom-nav shell: Home · Earn · Redeem · Tasks · Profile.
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(navigatorKey: _shellKey, routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.earn, builder: (_, __) => const EarnScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.rewards,
                builder: (_, __) => const RewardsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.tasks, builder: (_, __) => const TasksScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => AppScaffold(
      title: 'Not found',
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

/// Wraps [child] in a premium fade-through page transition (fade + subtle
/// upward slide), used for all pushed detail and auth routes. Honours the
/// platform "reduce motion" accessibility setting by dropping the slide.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final fade = FadeTransition(opacity: curved, child: child);
      if (reduceMotion) return fade;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: fade,
      );
    },
  );
}

/// Bridges Riverpod auth changes to go_router's [Listenable] refresh.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
