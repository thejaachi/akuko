import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/theme/reader_theme.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/books/presentation/controllers/book_providers.dart';
import 'package:akuko/features/reader/data/datasources/book_file_remote_datasource.dart';
import 'package:akuko/features/reader/presentation/controllers/book_file_providers.dart';
import 'package:akuko/features/reader/presentation/controllers/reader_interaction_preferences.dart';
import 'package:akuko/features/reader/presentation/controllers/reader_settings_controller.dart';
import 'package:akuko/features/reader/presentation/controllers/reading_providers.dart';
import 'package:akuko/features/reader/presentation/widgets/bookmarks_sheet.dart';
import 'package:akuko/features/reader/presentation/widgets/epub_reader_view.dart';
import 'package:akuko/features/reader/presentation/widgets/pdf_reader_view.dart';
import 'package:akuko/features/reader/presentation/widgets/reader_context_menu.dart';
import 'package:akuko/features/reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/reading_progress.dart';

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({required this.bookId, super.key});

  final String bookId;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  String? _currentLocation;
  double _progressPercent = 0;
  bool _seededFromSaved = false;
  final _epubKey = GlobalKey<EpubReaderViewState>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final prefs = ref.read(readerInteractionPreferencesProvider);
    if (!prefs.volumeKeysEnabled) return false;

    if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
      _epubKey.currentState?.goNext();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
      _epubKey.currentState?.goPrevious();
      return true;
    }
    return false;
  }

  void _onLocationChanged(String location, double percent) {
    setState(() {
      _currentLocation = location;
      _progressPercent = percent;
    });
    _persistProgress();
  }

  void _persistProgress() {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null || _currentLocation == null) return;
    // Fire-and-forget; failures are non-fatal to the reading session.
    unawaited(
      ref.read(readingRepositoryProvider).saveProgress(
            ReadingProgress(
              userId: userId,
              bookId: widget.bookId,
              location: _currentLocation,
              progressPercent: _progressPercent,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));
    final savedProgress = ref.watch(readingProgressProvider(widget.bookId));

    // Seed the in-memory location from saved progress once it resolves.
    savedProgress.whenData((p) {
      if (!_seededFromSaved && p != null) {
        _seededFromSaved = true;
        _currentLocation = p.location;
        _progressPercent = p.progressPercent;
      }
    });

    return bookAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: describeError(e, 'Could not open this book'),
          onRetry: () => ref.invalidate(bookByIdProvider(widget.bookId)),
        ),
      ),
      data: (book) => _buildReader(context, book),
    );
  }

  Widget _buildReader(BuildContext context, Book book) {
    final settings = ref.watch(readerSettingsProvider);
    final userId = ref.read(authRepositoryProvider).currentUser?.id;

    return Scaffold(
      backgroundColor: settings.themeMode.background,
      appBar: AppBar(
        backgroundColor: settings.themeMode.background,
        foregroundColor: settings.themeMode.foreground,
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_outlined),
            tooltip: 'Dictionary',
            onPressed: () => ReaderContextMenu.showWordPicker(
              context: context,
              ref: ref,
              sampleText: book.description ?? book.title,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: userId == null || _currentLocation == null
                ? null
                : () => BookmarksSheet.show(
                      context,
                      bookId: book.id,
                      userId: userId,
                      currentLocation: _currentLocation,
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => ReaderSettingsSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progressPercent > 0)
            LinearProgressIndicator(
              value: (_progressPercent / 100).clamp(0, 1),
              minHeight: 2,
            ),
          Expanded(child: _buildContent(book, settings)),
        ],
      ),
    );
  }

  /// Resolves the signed file URL (and seeds the saved reading position) before
  /// handing off to the EPUB/PDF renderer. Premium denials (`402`) surface as a
  /// clear "premium required" message — the paywall lives upstream of here.
  Widget _buildContent(Book book, ReaderSettings settings) {
    final savedProgress = ref.watch(readingProgressProvider(widget.bookId));
    final signedUrl = ref.watch(signedBookUrlProvider(widget.bookId));
    final interaction = ref.watch(readerInteractionPreferencesProvider);

    // Block rendering until the saved position resolves so the renderer is
    // constructed with the correct [initialLocation]. A progress lookup failure
    // is non-fatal — fall back to opening from the start.
    if (savedProgress.isLoading) return const LoadingView();

    return signedUrl.when(
      loading: () => const LoadingView(),
      error: (e, _) {
        if (e is PremiumRequiredException) {
          return ErrorView(
            icon: Icons.workspace_premium_outlined,
            message: e.message,
          );
        }
        return ErrorView(
          message: describeError(e, 'Could not load this book'),
          onRetry: () =>
              ref.invalidate(signedBookUrlProvider(widget.bookId)),
        );
      },
      data: (url) => switch (book.fileType) {
        BookFileType.pdf => PdfReaderView(
            fileUrl: url,
            settings: settings,
            initialLocation: _currentLocation,
            onLocationChanged: _onLocationChanged,
          ),
        BookFileType.epub => EpubReaderView(
            key: _epubKey,
            fileUrl: url,
            settings: settings,
            initialLocation: _currentLocation,
            touchTurnEnabled: interaction.touchTurnEnabled,
            onLocationChanged: _onLocationChanged,
            onDictionaryTap: () => ReaderContextMenu.showWordPicker(
              context: context,
              ref: ref,
              sampleText: book.description ?? book.title,
            ),
          ),
      },
    );
  }
}
