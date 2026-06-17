import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a book cover image with graceful loading and fallback states.
class BookCover extends StatelessWidget {
  const BookCover({
    required this.coverUrl,
    this.title,
    this.aspectRatio = 2 / 3,
    super.key,
  });

  final String? coverUrl;
  final String? title;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (coverUrl == null || coverUrl!.isEmpty)
            ? _placeholder(theme)
            : CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(theme),
                errorWidget: (_, __, ___) => _placeholder(theme),
              ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title ?? 'Akuko',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
