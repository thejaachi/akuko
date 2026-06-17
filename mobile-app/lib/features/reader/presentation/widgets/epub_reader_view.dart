import 'dart:async';
import 'dart:typed_data';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:akuko/core/theme/reader_theme.dart';

/// EPUB rendering surface backed by `epub_view`.
class EpubReaderView extends StatefulWidget {
  const EpubReaderView({
    required this.fileUrl,
    required this.settings,
    this.initialLocation,
    this.touchTurnEnabled = true,
    this.onLocationChanged,
    this.onDictionaryTap,
    super.key,
  });

  final String? fileUrl;
  final ReaderSettings settings;
  final String? initialLocation;
  final bool touchTurnEnabled;
  final VoidCallback? onDictionaryTap;

  /// Reports (location = EPUB CFI, progressPercent 0..100).
  final void Function(String location, double progressPercent)?
      onLocationChanged;

  @override
  State<EpubReaderView> createState() => EpubReaderViewState();
}

class EpubReaderViewState extends State<EpubReaderView> {
  EpubController? _controller;
  Timer? _debounce;
  int? _lastChapter;
  int _currentChapterIndex = 0;
  String? _error;

  static const _debounceDelay = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final url = widget.fileUrl;
    if (url == null || url.isEmpty) {
      setState(() => _error = 'This book has no file to display.');
      return;
    }
    try {
      final bytes = await _download(url);
      if (!mounted) return;
      setState(() {
        _controller = EpubController(
          document: EpubDocument.openData(bytes),
          epubCfi: widget.initialLocation,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to download EPUB.');
    }
  }

  Future<Uint8List> _download(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to download EPUB (HTTP ${res.statusCode})');
    }
    return res.bodyBytes;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // NB: `EpubChapterViewValue` is not re-exported by the `epub_view` barrel, so
  // the `onChapterChanged` value is consumed via an inferred closure and only
  // its primitive fields are forwarded here.
  void _onChapterPosition(double chapterProgress, int chapterNumber) {
    if (widget.onLocationChanged == null) return;
    final percent = _wholeBookPercent(chapterProgress, chapterNumber);

    // Persist immediately when the chapter changes; otherwise debounce so we
    // don't write on every scroll tick.
    final chapterChanged = chapterNumber != _lastChapter;
    _lastChapter = chapterNumber;

    if (chapterChanged) {
      _debounce?.cancel();
      _emit(percent);
    } else {
      _debounce?.cancel();
      _debounce = Timer(_debounceDelay, () => _emit(percent));
    }
  }

  void _emit(double percent) {
    final cfi = _controller?.generateEpubCfi();
    if (cfi == null) return;
    widget.onLocationChanged?.call(cfi, percent);
  }

  /// Estimates whole-book progress from the current chapter index plus the
  /// in-chapter scroll fraction.
  // TODO(reader-api): epub_view exposes only per-chapter progress; verify this
  // whole-book estimate against real books after `flutter pub get`.
  double _wholeBookPercent(double chapterProgress, int chapterNumber) {
    final withinChapter = (chapterProgress / 100).clamp(0.0, 1.0);
    final totalChapters = _controller?.tableOfContents().length ?? 0;
    if (totalChapters <= 0) {
      return (withinChapter * 100).clamp(0.0, 100.0).toDouble();
    }
    final chapterIdx = (chapterNumber - 1).clamp(0, totalChapters - 1);
    return (((chapterIdx + withinChapter) / totalChapters) * 100)
        .clamp(0.0, 100.0)
        .toDouble();
  }

  void _openTableOfContents() {
    final controller = _controller;
    if (controller == null) return;
    final chapters = controller.tableOfContents();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        if (chapters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No table of contents available.'),
          );
        }
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: chapters.length,
              itemBuilder: (_, i) {
                final chapter = chapters[i];
                final isSub = chapter.type == 'subchapter';
                final title = chapter.title?.trim();
                return ListTile(
                  contentPadding:
                      EdgeInsets.only(left: isSub ? 36 : 16, right: 16),
                  leading: isSub
                      ? null
                      : const Icon(Icons.menu_book_outlined, size: 20),
                  title: Text(
                    title == null || title.isEmpty ? 'Untitled' : title,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    controller.scrollTo(index: chapter.startIndex);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void goNext() {
    final controller = _controller;
    if (controller == null) return;
    final chapters = controller.tableOfContents();
    if (_currentChapterIndex >= chapters.length - 1) return;
    _currentChapterIndex += 1;
    controller.scrollTo(index: chapters[_currentChapterIndex].startIndex);
  }

  void goPrevious() {
    final controller = _controller;
    if (controller == null) return;
    if (_currentChapterIndex <= 0) return;
    _currentChapterIndex -= 1;
    final chapters = controller.tableOfContents();
    controller.scrollTo(index: chapters[_currentChapterIndex].startIndex);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.settings.themeMode;
    final controller = _controller;

        if (_error != null) {
      return _CenteredMessage(
        mode: mode,
        icon: Icons.menu_book_outlined,
        text: _error!,
      );
    }
    if (controller == null) {
      return ColoredBox(
        color: mode.background,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: mode.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: EpubView(
              controller: controller,
              onChapterChanged: (value) {
                if (value == null) return;
                _currentChapterIndex = (value.chapterNumber - 1).clamp(0, 9999);
                _onChapterPosition(value.progress, value.chapterNumber);
              },
              onDocumentError: (_) =>
                  setState(() => _error = 'Failed to render this EPUB.'),
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: DefaultBuilderOptions(
                  textStyle: TextStyle(
                    color: mode.foreground,
                    fontSize: widget.settings.fontSize,
                    height: widget.settings.lineSpacing,
                    fontFamily: widget.settings.fontFamily,
                  ),
                ),
                loaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                chapterDividerBuilder: (chapter) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    chapter.Title?.trim() ?? '',
                    style: TextStyle(
                      color: mode.foreground,
                      fontSize: widget.settings.fontSize + 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.touchTurnEnabled) ...[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 72,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: goPrevious,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 72,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: goNext,
              ),
            ),
          ],
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onDictionaryTap != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OverlayButton(
                      mode: mode,
                      icon: Icons.menu_book_outlined,
                      tooltip: 'Look up word',
                      onPressed: widget.onDictionaryTap!,
                    ),
                  ),
                _OverlayButton(
                  mode: mode,
                  icon: Icons.toc,
                  tooltip: 'Table of contents',
                  onPressed: _openTableOfContents,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small translucent circular action button overlaid on the reading surface.
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.mode,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final ReaderThemeMode mode;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mode.background.withOpacity(0.85),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(icon, color: mode.foreground),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.mode,
    required this.icon,
    required this.text,
  });

  final ReaderThemeMode mode;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: mode.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: mode.foreground),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: mode.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
