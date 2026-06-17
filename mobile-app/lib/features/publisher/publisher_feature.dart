import 'package:flutter/material.dart';

/// Placeholder publisher portal (Phase 3–4). Gated by
/// [AppFeatures.publisherDashboard].
class PublisherDashboardPage extends StatelessWidget {
  const PublisherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publisher')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Publisher dashboard — catalogue, imprints, and payout workflows '
            'will appear here when the publisher_dashboard flag is on.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
