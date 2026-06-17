import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/shared/domain/entities/profile.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({required this.profile, super.key});

  final Profile profile;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late final TextEditingController _nameController;
  bool _saving = false;
  bool _linkingGoogle = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _linkGoogleAccount() async {
    if (mounted) {
      context.showSnack('Google account linking is not available yet.');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showSnack('Username cannot be empty');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = widget.profile.copyWith(fullName: name);
      final result =
          await ref.read(profileRepositoryProvider).updateProfile(updated);
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(currentProfileProvider);
          if (mounted) {
            context.showSnack('Profile updated');
            Navigator.pop(context);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.profile.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.burntSienna.withOpacity(0.2),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 48, color: AppColors.textMuted)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _linkingGoogle ? null : _linkGoogleAccount,
            icon: _linkingGoogle
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: const Text('Link Google Account'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Your display name',
            ),
          ),
        ],
      ),
    );
  }
}
