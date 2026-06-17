import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/books/data/curated_home_content.dart';
import 'package:akuko/features/library/presentation/controllers/book_request_providers.dart';

class RequestBookPage extends ConsumerStatefulWidget {
  const RequestBookPage({super.key});

  @override
  ConsumerState<RequestBookPage> createState() => _RequestBookPageState();
}

class _RequestBookPageState extends ConsumerState<RequestBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _notesController = TextEditingController();
  String? _genre;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(bookRequestRepositoryProvider).submit(
            userId: userId,
            title: _titleController.text.trim(),
            author: _authorController.text.trim().isEmpty
                ? null
                : _authorController.text.trim(),
            genre: _genre,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(bookRequestsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Book request submitted'),
                backgroundColor: AppColors.burntSienna,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          }
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = CuratedHomeContent.curatedGenres.map((g) => g.name).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Request a Book')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book title',
                hintText: 'Enter the book title',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author name',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _genre,
              decoration: const InputDecoration(labelText: 'Genre'),
              items: genres
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _genre = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Why do you want this book?',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
