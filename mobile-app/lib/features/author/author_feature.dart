import 'package:flutter/material.dart';

/// Placeholder author portal (Phase 3). Gated by [AppFeatures.authorDashboard].
class AuthorDashboardPage extends StatelessWidget {
  const AuthorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Author')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Author dashboard — manuscript uploads, pricing, and royalty '
            'statements will appear here when the author_dashboard flag is on.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
