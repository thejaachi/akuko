import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile does not host full admin tooling. Ops use the web admin app.
///
/// Deep link: `/admin` when [AppFeatures.adminMobile] is enabled.
class AdminDeepLinkPage extends StatelessWidget {
  const AdminDeepLinkPage({super.key});

  /// Configure per deployment (web admin base URL).
  static const String webAdminUrl = 'https://admin.akuko.app';

  static const String setupHint =
      'Full catalogue, moderation, feature flags, and payouts are managed in '
      'the web admin. See akuko/admin/.env.example for server configuration.';

  Future<void> _openWebAdmin(BuildContext context) async {
    final uri = Uri.parse(webAdminUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open admin URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Use web admin',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(setupHint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            SelectableText(
              webAdminUrl,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openWebAdmin(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open web admin'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: webAdminUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin URL copied')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy URL'),
            ),
          ],
        ),
      ),
    );
  }
}
