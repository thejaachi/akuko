import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/guards/subscription_guard.dart';
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/reader/data/dictionary_usage_repository.dart';
import 'package:akuko/features/reader/data/word_definition_service.dart';

/// Overlay / bottom sheet for contextual word lookup in the reader.
class ReaderContextMenu {
  ReaderContextMenu._();

  /// Show definition bottom sheet for a selected word.
  static Future<void> showDefinition({
    required BuildContext context,
    required WidgetRef ref,
    required String word,
    required String contextSentence,
  }) async {
    final usage = ref.read(dictionaryUsageRepositoryProvider);
    final canLookup = await usage.canLookup();

    if (!canLookup) {
      if (!context.mounted) return;
      _showUpgradePrompt(context, ref);
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DefinitionSheet(
        word: word,
        contextSentence: contextSentence,
        onLookupComplete: () => usage.recordLookup(word),
      ),
    );
  }

  /// MVP stub: long-press word picker when EPUB selection is unavailable.
  static Future<void> showWordPicker({
    required BuildContext context,
    required WidgetRef ref,
    required String sampleText,
  }) async {
    final words = sampleText
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .take(12)
        .toList();

    if (words.isEmpty) {
      context.showSnack('Select a word to look up');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Look up a word',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: AppColors.textWarm,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap a word from the current passage',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words
                  .map(
                    (w) => ActionChip(
                      label: Text(w),
                      backgroundColor: AppColors.warmSurface,
                      labelStyle: const TextStyle(color: AppColors.textWarm),
                      side: const BorderSide(color: AppColors.cardBorder),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDefinition(
                          context: context,
                          ref: ref,
                          word: w,
                          contextSentence: sampleText,
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void _showUpgradePrompt(BuildContext context, WidgetRef ref) {
    final limit = ref.read(subscriptionGuardProvider).dictionaryDailyLimit;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          'Daily limit reached',
          style: TextStyle(color: AppColors.textWarm),
        ),
        content: Text(
          'Free readers get $limit dictionary lookups per day. '
          'Upgrade for unlimited contextual definitions.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.subscription);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.burntSienna,
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _DefinitionSheet extends ConsumerStatefulWidget {
  const _DefinitionSheet({
    required this.word,
    required this.contextSentence,
    required this.onLookupComplete,
  });

  final String word;
  final String contextSentence;
  final Future<void> Function() onLookupComplete;

  @override
  ConsumerState<_DefinitionSheet> createState() => _DefinitionSheetState();
}

class _DefinitionSheetState extends ConsumerState<_DefinitionSheet> {
  String? _definition;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final service = ref.read(wordDefinitionServiceProvider);
    try {
      final def = await service.defineWord(
        word: widget.word,
        contextSentence: widget.contextSentence,
      );
      await widget.onLookupComplete();
      if (mounted) {
        setState(() {
          _definition = def;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not fetch definition. Check your connection.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.burntSienna.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.burntSienna,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: AppColors.warmGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Contextual definition',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warmSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                '"${widget.contextSentence}"',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: AppColors.burntSienna,
                  ),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              )
            else
              Text(
                _definition!,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textWarm,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
