import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/african_pattern_painter.dart';

class TierPlanCard extends StatelessWidget {
  const TierPlanCard({
    required this.name,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.isActive,
    required this.tier,
    this.onSubscribe,
    this.busy = false,
    super.key,
  });

  final String name;
  final String priceLabel;
  final String description;
  final List<String> features;
  final bool isActive;
  final PatternTier tier;
  final VoidCallback? onSubscribe;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForTier(tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.warmSurface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? accent : AppColors.cardBorder,
          width: isActive ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: PatternBackground(
        tier: tier,
        patternColor: accent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive ? accent : AppColors.textWarm,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                priceLabel,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWarm,
                ),
              ),
              Text(
                description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isActive ? accent : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.textWarm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (onSubscribe != null && !isActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : onSubscribe,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                    ),
                    child: Text(busy ? 'Processing…' : 'Subscribe'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _accentForTier(PatternTier tier) => switch (tier) {
        PatternTier.free => AppColors.textMuted,
        PatternTier.standard => AppColors.forestGreen,
        PatternTier.premium => AppColors.burntSienna,
        PatternTier.vip => AppColors.warmGold,
      };
}
