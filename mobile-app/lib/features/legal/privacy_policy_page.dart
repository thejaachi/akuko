import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _body = '''
PRIVACY POLICY
Last Updated: June 2026

Akuko ("we," "our," or "us") is dedicated to protecting your privacy. This Privacy Policy outlines how your personal data, language settings, and geolocation details are gathered, processed, and secured to offer tailored reading atmospheres and localized greetings.

1. Information We Collect
- Profile Data: Username, email addresses, and imported social profile images via Google sign-in integrations.
- Transaction Logs: Records of Paystack purchases, subscription layers, and wallet-based Cowrie distributions.
- Preferences: Bookmarked items, font spacing variations, and designated favorite genres.

2. How We Use Data
To process doorstep hardcopy publication deliveries, regulate tiered access points for social reading circles, and deliver contextual definitions powered by external AI dictionary nodes. We do not sell user data structures to third-party advertising brokers.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          _body.trim(),
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textWarm,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}
