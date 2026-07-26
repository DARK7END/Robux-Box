import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/services/offerwall_service.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';

/// Hosts the third-party offerwall inside a hardened in-app WebView.
///
/// Before loading, it transparently requests usage-tracking consent (needed to
/// verify engagement offers) and fetches a server-signed wall URL so postbacks
/// are attributable. Coin credits arrive asynchronously via the provider's
/// server-to-server postback → Cloud Function → wallet, never from the WebView
/// itself, so a manipulated page cannot mint coins.
class OfferwallScreen extends ConsumerStatefulWidget {
  const OfferwallScreen({super.key});

  @override
  ConsumerState<OfferwallScreen> createState() => _OfferwallScreenState();
}

class _OfferwallScreenState extends ConsumerState<OfferwallScreen> {
  WebViewController? _webController;
  bool _loading = true;
  int _progress = 0;
  Failure? _error;
  bool _needsConsent = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final offerwall = ref.read(offerwallServiceProvider);

    // 1) Ask for usage-tracking consent up front (transparent to the user).
    final consented = await offerwall.requestTrackingConsent();
    if (!consented && mounted) {
      setState(() => _needsConsent = true);
    }

    // 2) Fetch a signed wall URL for this session.
    final result = await offerwall.getWallUrl();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _initWebView(value);
      case Err(:final Failure failure):
        setState(() {
          _error = failure;
          _loading = false;
        });
    }
  }

  void _initWebView(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(context.surfaces.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (e) => setState(() {
            _error = ServerFailure('Failed to load offers: ${e.description}');
            _loading = false;
          }),
        ),
      )
      ..loadRequest(Uri.parse(url));
    setState(() {
      _webController = controller;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.earnOfferwall,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _webController?.reload(),
        ),
      ],
      padded: false,
      body: Padding(
        padding: EdgeInsets.only(top: kToolbarHeight + context.padding.top),
        child: Column(
          children: [
            if (_needsConsent) _ConsentBanner(onGrant: _bootstrap),
            if (_loading && _webController != null)
              LinearProgressIndicator(value: _progress / 100, minHeight: 2),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return ErrorStateView(message: _error!.message, onRetry: _bootstrap);
    }
    if (_webController == null) {
      return const PremiumLoadingView(label: 'Loading offers…');
    }
    return WebViewWidget(controller: _webController!);
  }
}

class _ConsentBanner extends StatelessWidget {
  const _ConsentBanner({required this.onGrant});
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.primary.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.privacy_tip_rounded, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(context.l10n.earnTrackingRequired,
                style: context.text.bodySmall),
          ),
          TextButton(
            onPressed: onGrant,
            child: Text(context.l10n.earnGrantPermission),
          ),
        ],
      ),
    );
  }
}
