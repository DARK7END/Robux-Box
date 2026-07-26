part of 'app_router.dart';

/// Branded splash shown while Firebase auth state resolves. The router's
/// redirect moves the user on to onboarding, welcome or home once known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      showAppBar: false,
      body: Center(child: _SplashLogo()),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4DFF91), Color(0xFF00E65C), Color(0xFF00A344)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E65C).withValues(alpha: 0.55),
                blurRadius: 34,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.inventory_2_rounded,
              size: 46, color: Color(0xFF0D0D0D)),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineMedium,
            children: const [
              TextSpan(text: 'Robux '),
              TextSpan(text: 'Box', style: TextStyle(color: Color(0xFF00E65C))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('Play. Earn. Redeem.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 28),
        const PremiumLoader(size: 30),
      ],
    );
  }
}
