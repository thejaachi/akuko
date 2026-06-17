import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:akuko/core/router/routes.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

class SupportHelpPage extends StatelessWidget {
  const SupportHelpPage({super.key});

  static const _supportEmail = 'support@akuko.app';

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: 'subject=Akuko Support Request',
    );
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        context.showSnack('Could not open email client');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Help')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.burntSienna),
            title: const Text('Email support'),
            subtitle: Text(_supportEmail),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _emailSupport(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.burntSienna),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AppColors.burntSienna),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.termsOfService),
          ),
          const SizedBox(height: 16),
          Text(
            'We typically respond within 24 hours on business days.',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
