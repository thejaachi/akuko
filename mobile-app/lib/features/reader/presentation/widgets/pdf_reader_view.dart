import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import 'package:akuko/core/theme/reader_theme.dart';

/// PDF rendering surface backed by `pdfx` (`PdfViewPinch` — pinch-zoom, native
/// pdfium/PDF.js rendering).
///
/// Responsibilities:
///   * download the PDF bytes from the signed [fileUrl] and render them,
///   * restore the saved page from [initialLocation] (a stringified 1-based
///     page number) and emit `(pageNumber, percent)` via [onLocationChanged],
///   * provide page navigation (prev / next / jump-to-page) and pinch zoom,
///   * honor the reader theme background, inverting page colors for night mode.
///
/// PDFs paint their own page surface, so the reader `fontSize` / `lineSpacing`
/// do not apply — only theme background + night-mode invert are relevant.
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({
    required this.fileUrl,
    required this.settings,
    this.initialLocation,
    this.onLocationChanged,
    super.key,
  });

  final String? fileUrl;
  final ReaderSettings settings;
  final String? initialLocation;

  /// Reports (location = 1-based page number as string, progressPercent 0..100).
  final void Function(String location, double progressPercent)?
      onLocationChanged;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  PdfControllerPinch? _controller;
  String? _error;
  int _page = 1;
  int _pageCount = 0;

  // Inverts page colors for a usable dark/night reading mode.
  static const ColorFilter _invertFilter = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255, //
    0, 0, -1, 0, 255, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final url = widget.fileUrl;
    if (url == null || url.isEmpty) {
      _error = 'This book has no file to display.';
      return;
    }
    _page = _parsePage(widget.initialLocation);
    _controller = PdfControllerPinch(
      document: PdfDocument.openData(_download(url)),
      initialPage: _page, // 1-based
    );
  }

  int _parsePage(String? location) {
    final parsed = int.tryParse(location?.trim() ?? '');
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  Future<Uint8List> _download(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to download PDF (HTTP ${res.statusCode})');
    }
    return res.bodyBytes;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocument document) {
    setState(() => _pageCount = document.pagesCount);
  }

  void _onPageChanged(int page) {
    _page = page;
    // Page changes are discrete events (not per-scroll-tick), so emitting here
    // already satisfies the "debounce to page change" requirement.
    final percent = _pageCount > 0
        ? ((page / _pageCount) * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    widget.onLocationChanged?.call(page.toString(), percent);
    if (mounted) setState(() {});
  }

  void _goToPrevious() {
    _controller?.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNext() {
    _controller?.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeIn,
    );
  }

  Future<void> _promptJumpToPage() async {
    final controller = _controller;
    if (controller == null || _pageCount <= 0) return;

    final textController = TextEditingController(text: '$_page');
    final target = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Go to page'),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page (1–$_pageCount)',
            ),
            onSubmitted: (v) =>
                Navigator.of(dialogContext).pop(int.tryParse(v.trim())),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(int.tryParse(textController.text.trim())),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );

    textController.dispose();
    if (target == null) return;
    final clamped = target.clamp(1, _pageCount).toInt();
    controller.animateToPage(
      pageNumber: clamped,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.settings.themeMode;
    final controller = _controller;

    if (_error != null || controller == null) {
      return _CenteredMessage(
        mode: mode,
        text: _error ?? 'Unable to open this book.',
      );
    }

    Widget viewer = PdfViewPinch(
      controller: controller,
      onDocumentLoaded: _onDocumentLoaded,
      onPageChanged: _onPageChanged,
      onDocumentError: (_) =>
          setState(() => _error = 'Failed to render this PDF.'),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) =>
            Center(child: Text('Failed to render this PDF.\n$error')),
      ),
    );

    if (mode == ReaderThemeMode.dark) {
      viewer = ColorFiltered(colorFilter: _invertFilter, child: viewer);
    }

    return ColoredBox(
      color: mode.background,
      child: Stack(
        children: [
          Positioned.fill(child: viewer),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PageControlBar(
              mode: mode,
              page: _page,
              pageCount: _pageCount,
              onPrevious: _page > 1 ? _goToPrevious : null,
              onNext:
                  _pageCount > 0 && _page < _pageCount ? _goToNext : null,
              onJump: _pageCount > 0 ? _promptJumpToPage : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation bar: previous / page indicator (tap to jump) / next.
class _PageControlBar extends StatelessWidget {
  const _PageControlBar({
    required this.mode,
    required this.page,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onJump,
  });

  final ReaderThemeMode mode;
  final int page;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onJump;

  @override
  Widget build(BuildContext context) {
    final label = pageCount > 0 ? 'Page $page of $pageCount' : 'Page $page';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: mode.background.withOpacity(0.9),
          shape: const StadiumBorder(),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: mode.foreground,
                  tooltip: 'Previous page',
                  onPressed: onPrevious,
                ),
                TextButton(
                  onPressed: onJump,
                  child: Text(
                    label,
                    style: TextStyle(color: mode.foreground),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: mode.foreground,
                  tooltip: 'Next page',
                  onPressed: onNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.mode, required this.text});

  final ReaderThemeMode mode;
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
              Icon(Icons.picture_as_pdf, size: 56, color: mode.foreground),
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
