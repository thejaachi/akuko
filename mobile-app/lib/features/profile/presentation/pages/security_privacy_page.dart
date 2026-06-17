import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/utils/extensions.dart';

class SecurityPrivacyPage extends ConsumerWidget {
  const SecurityPrivacyPage({super.key});

  Future<void> _changePassword(BuildContext context) async {
    if (context.mounted) {
      context.showSnack(
        'Use Forgot Password on the login screen to reset via email.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Privacy')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            subtitle: const Text('Reset via email (Forgot Password)'),
            onTap: () => _changePassword(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of service'),
            onTap: () => context.push(AppRoutes.termsOfService),
          ),
        ],
      ),
    );
  }
}
