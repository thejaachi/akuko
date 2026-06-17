import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/reader/presentation/controllers/reading_providers.dart';
import 'package:akuko/shared/domain/entities/bookmark.dart';

/// Lists, adds, and removes bookmarks for the current book.
class BookmarksSheet extends ConsumerWidget {
  const BookmarksSheet({
    required this.bookId,
    required this.userId,
    required this.currentLocation,
    super.key,
  });

  final String bookId;
  final String userId;
  final String? currentLocation;

  static Future<void> show(
    BuildContext context, {
    required String bookId,
    required String userId,
    required String? currentLocation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BookmarksSheet(
        bookId: bookId,
        userId: userId,
        currentLocation: currentLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider(bookId));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Row(
                children: [
                  Text('Bookmarks', style: context.textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: currentLocation == null
                        ? null
                        : () => _addCurrent(ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add here'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: bookmarks.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: describeError(e, 'Could not load bookmarks'),
                  onRetry: () =>
                      ref.read(bookmarksProvider(bookId).notifier).refreshList(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyView(
                      icon: Icons.bookmark_border,
                      title: 'No bookmarks',
                      message: 'Tap "Add here" to bookmark your spot.',
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) => _BookmarkTile(
                      bookmark: items[i],
                      onDelete: () => ref
                          .read(bookmarksProvider(bookId).notifier)
                          .remove(items[i].id!),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCurrent(WidgetRef ref) {
    final bookmark = Bookmark(
      userId: userId,
      bookId: bookId,
      location: currentLocation!,
      label: 'Bookmark',
    );
    ref.read(bookmarksProvider(bookId).notifier).add(bookmark);
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark, required this.onDelete});

  final Bookmark bookmark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bookmark),
      title: Text(bookmark.label ?? 'Bookmark'),
      subtitle: Text(
        bookmark.location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: bookmark.id == null ? null : onDelete,
      ),
    );
  }
}
