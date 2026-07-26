import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admin_repository.dart';

/// Sends a push notification to a topic (all users, or a reminder segment).
class AdminBroadcastScreen extends ConsumerStatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  ConsumerState<AdminBroadcastScreen> createState() =>
      _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends ConsumerState<AdminBroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _deeplink = TextEditingController();
  String _topic = 'all';
  bool _busy = false;

  static const _topics = {
    'all': 'Everyone',
    'reminder_daily': 'Daily reminder segment',
    'reminder_rewards': 'Rewards segment',
    'reminder_vip': 'VIP segment',
    'reminder_referral': 'Referral segment',
  };

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _deeplink.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      AppToast.error(context, 'Title and message are required.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send broadcast?'),
        content: Text('This pushes to "${_topics[_topic]}".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final r = await ref.read(adminRepositoryProvider).broadcast(
          title: _title.text.trim(),
          body: _body.text.trim(),
          topic: _topic,
          deeplink: _deeplink.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Success():
        _title.clear();
        _body.clear();
        _deeplink.clear();
        AppToast.success(context, 'Broadcast sent');
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Broadcast',
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          TextField(
            controller: _title,
            maxLength: 60,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _body,
            maxLines: 3,
            maxLength: 180,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _deeplink,
            decoration: const InputDecoration(
                labelText: 'Deep link (optional)', hintText: '/rewards'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Audience', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          ..._topics.entries.map((e) => RadioListTile<String>(
                value: e.key,
                groupValue: _topic,
                onChanged: (v) => setState(() => _topic = v!),
                title: Text(e.value),
                activeColor: AppColors.brand,
                contentPadding: EdgeInsets.zero,
              )),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: 'Send broadcast',
            icon: Icons.campaign_rounded,
            loading: _busy,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
