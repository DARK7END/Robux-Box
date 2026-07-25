import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/achievements_screen.dart';
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
import '../../features/vip/presentation/vip_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../config/providers.dart';
import '../services/preferences_service.dart';
import '../widgets/app_scaffold.dart';
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
          path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
          path: AppRoutes.emailAuth,
          builder: (_, __) => const EmailAuthScreen()),
      GoRoute(
          path: AppRoutes.phoneAuth,
          builder: (_, __) => const PhoneAuthScreen()),

      // Detail routes (pushed over the shell).
      GoRoute(
          path: AppRoutes.offerwall,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const OfferwallScreen()),
      GoRoute(
          path: AppRoutes.wallet,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const WalletScreen()),
      GoRoute(
          path: AppRoutes.redemptions,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const RedemptionsScreen()),
      GoRoute(
          path: AppRoutes.referrals,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const ReferralsScreen()),
      GoRoute(
          path: AppRoutes.vip,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const VipScreen()),
      GoRoute(
          path: AppRoutes.achievements,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const AchievementsScreen()),
      GoRoute(
          path: AppRoutes.notifications,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: AppRoutes.settings,
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const SettingsScreen()),

      // Bottom-nav shell.
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
                path: AppRoutes.leaderboard,
                builder: (_, __) => const LeaderboardScreen()),
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

/// Bridges Riverpod auth changes to go_router's [Listenable] refresh.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
