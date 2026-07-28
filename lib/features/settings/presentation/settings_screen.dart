import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../admin/domain/admin_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/presentation/widgets/profile_menu_tile.dart';
import 'report_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final config = ref.watch(appConfigProvider);
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return AppScaffold(
      title: context.l10n.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          if (isAdmin) ...[
            ProfileMenuTile(
              icon: Icons.shield_rounded,
              label: context.l10n.settingsAdminDashboard,
              color: AppColors.brand,
              subtitle: context.l10n.settingsAdminDashboardDesc,
              onTap: () => context.push(AppRoutes.admin),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SectionLabel(label: context.l10n.settingsTitle),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) => ref
                      .read(themeControllerProvider.notifier)
                      .setMode(v ? ThemeMode.dark : ThemeMode.light),
                  title: Text(context.l10n.settingsDarkMode),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  activeColor: AppColors.brand,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(context.l10n.settingsLanguage),
                  trailing: Text(
                    _localeLabel(context, locale),
                    style: context.text.bodyMedium,
                  ),
                  onTap: () => _pickLanguage(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(label: context.l10n.settingsLegalSupport),
          ProfileMenuTile(
            icon: Icons.notifications_rounded,
            label: context.l10n.settingsNotifications,
            color: AppColors.info,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          ProfileMenuTile(
            icon: Icons.privacy_tip_rounded,
            label: context.l10n.settingsPrivacy,
            color: AppColors.secondary,
            onTap: () => _open(config.privacyUrl),
          ),
          ProfileMenuTile(
            icon: Icons.description_rounded,
            label: context.l10n.settingsTerms,
            color: AppColors.brand,
            onTap: () => _open(config.termsUrl),
          ),
          ProfileMenuTile(
            icon: Icons.support_agent_rounded,
            label: context.l10n.settingsSupport,
            color: AppColors.success,
            onTap: () => _open('mailto:${config.supportEmail}'),
          ),
          ProfileMenuTile(
            icon: Icons.bug_report_rounded,
            label: context.l10n.settingsReport,
            color: AppColors.warning,
            onTap: () => showReportSheet(context),
          ),
          ProfileMenuTile(
            icon: Icons.info_rounded,
            label: context.l10n.settingsAbout,
            color: AppColors.coin,
            subtitle: 'Robux Box',
            onTap: () => _showAbout(context, config),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(label: context.l10n.settingsDeleteAccount),
          ProfileMenuTile(
            icon: Icons.delete_forever_rounded,
            label: context.l10n.settingsDeleteAccount,
            color: AppColors.danger,
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _localeLabel(BuildContext context, Locale? locale) {
    if (locale == null) return context.l10n.settingsSystemDefault;
    return switch (locale.languageCode) {
      'ar' => 'العربية',
      'en' => 'English',
      _ => locale.languageCode.toUpperCase(),
    };
  }

  void _pickLanguage(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(context.l10n.settingsSystemDefault),
              onTap: () {
                ref.read(localeControllerProvider.notifier).setLocale(null);
                Navigator.pop(context);
              },
            ),
            for (final l in kSupportedLocales)
              ListTile(
                title: Text(_localeLabel(context, l)),
                onTap: () {
                  ref.read(localeControllerProvider.notifier).setLocale(l);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, AppConfig config) {
    showAboutDialog(
      context: context,
      applicationName: 'Robux Box',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Robux Box',
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.settingsDeleteAccount),
        content: Text(context.l10n.settingsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.settingsDeleteAccount,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    if (!context.mounted) return;
    switch (result) {
      case Success():
        context.go(AppRoutes.welcome);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(label.toUpperCase(),
          style: context.text.labelSmall
              ?.copyWith(color: context.surfaces.textTertiary, letterSpacing: 1)),
    );
  }
}
