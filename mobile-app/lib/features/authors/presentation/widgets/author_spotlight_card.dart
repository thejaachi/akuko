import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/authors/domain/entities/author.dart';

class AuthorSpotlightCard extends StatelessWidget {
  const AuthorSpotlightCard({required this.author, super.key});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cobaltBlue, AppColors.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.burntSienna.withOpacity(0.4),
                child: Text(
                  author.name.isNotEmpty ? author.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.textWarm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  author.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: AppColors.textWarm,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (author.bio != null) ...[
            const SizedBox(height: 10),
            Text(
              author.bio!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${author.bookCount > 0 ? author.bookCount : '—'} titles',
            style: context.textTheme.labelSmall?.copyWith(
              color: AppColors.warmGold,
            ),
          ),
        ],
      ),
    );
  }
}
