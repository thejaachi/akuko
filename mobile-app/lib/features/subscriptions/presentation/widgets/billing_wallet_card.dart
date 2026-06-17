import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

class BillingWalletCard extends StatelessWidget {
  const BillingWalletCard({
    required this.name,
    required this.email,
    super.key,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cobaltBlue, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.burntSienna.withOpacity(0.35),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.textWarm,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing Wallet',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  name,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.textWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.warmGold,
          ),
        ],
      ),
    );
  }
}
