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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B7CFF), Color(0xFF6C5CE7)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.card_giftcard_rounded,
              size: 46, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text('Robux Box', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ],
    );
  }
}
