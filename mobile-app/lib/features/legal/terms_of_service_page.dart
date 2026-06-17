import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const _body = '''
TERMS OF SERVICE
Last Updated: June 2026

Welcome to Akuko. By accessing our mobile application services, you agree to comply with and be bound by the following contractual terms.

1. Account Tiers & Virtual Cowries
- Free accounts gain entry to basic reading catalogs with restricted AI helper lookups and 140-character community posting profiles.
- Paid subscription tiers scale limits up to 500 characters and open automated reading group setups.
- Cowries represent digital currency credits locked to the Akuko ecosystem. Cowries are non-refundable and hold zero cash exchange value outside app borders.

2. Physical Deliveries
Users are entirely responsible for providing accurate destination vectors inside the Manage Address form to complete hardcopy distributions. Shipping timelines may shift based on regional logistics variables.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
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
