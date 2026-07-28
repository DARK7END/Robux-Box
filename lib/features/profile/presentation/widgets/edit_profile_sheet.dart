import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/format_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/app_user.dart';
import '../../../earn/data/earn_repository.dart';
import '../../data/user_repository.dart';

/// Bottom sheet to edit the profile photo, display name and (via a server-
/// validated re-resolve, never a free-text field) the account's region.
Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EditProfileSheet(hostContext: context),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.hostContext});
  final BuildContext hostContext;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  XFile? _pickedImage;
  bool _busy = false;
  bool _refreshingRegion = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _name = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file != null && mounted) setState(() => _pickedImage = file);
  }

  Future<void> _refreshRegion() async {
    setState(() => _refreshingRegion = true);
    final result = await ref.read(earnRepositoryProvider).reportTier();
    if (!mounted) return;
    setState(() => _refreshingRegion = false);
    switch (result) {
      case Success():
        AppToast.success(context, context.l10n.profileRegionUpdated);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _busy = true);

    String? photoUrl;
    if (_pickedImage != null) {
      try {
        final storageRef =
            ref.read(storageProvider).ref('avatars/$uid/avatar.jpg');
        await storageRef.putFile(
          File(_pickedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        photoUrl = await storageRef.getDownloadURL();
      } on FirebaseException catch (e, s) {
        log.e('Avatar upload failed', e, s);
        setState(() => _busy = false);
        if (mounted) {
          AppToast.error(context, e.message ?? context.l10n.errorGeneric);
        }
        return;
      }
    }

    final name = _name.text.trim();
    final result = await ref.read(userRepositoryProvider).updateProfile(
          uid: uid,
          displayName: name.isEmpty ? null : name,
          photoUrl: photoUrl,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        if (widget.hostContext.mounted) {
          AppToast.success(widget.hostContext, context.l10n.profileUpdated);
        }
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: context.viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.profileEditTitle, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Pressable(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.surfaces.border, width: 2),
                    ),
                    child: ClipOval(child: _avatarPreview(user)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(context.l10n.profileDisplayName, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _name,
            maxLength: 24,
            decoration: InputDecoration(hintText: context.l10n.profileDisplayName),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.profileRegion, style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Text((user?.countryCode ?? 'US').flagEmoji,
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.countryCode ?? '—',
                          style: context.text.titleSmall),
                      Text(
                        context.l10n.profileRegionHint,
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshingRegion ? null : _refreshRegion,
                  icon: _refreshingRegion
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(context.l10n.profileRefreshRegion),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            label: context.l10n.commonSave,
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _avatarPreview(AppUser? user) {
    if (_pickedImage != null) {
      return Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
    }
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final px = (96 * MediaQuery.of(context).devicePixelRatio).round();
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        memCacheWidth: px,
        memCacheHeight: px,
      );
    }
    final name = user?.displayName;
    return ColoredBox(
      color: AppColors.brand.withOpacity(0.18),
      child: Center(
        child: Text(
          name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
