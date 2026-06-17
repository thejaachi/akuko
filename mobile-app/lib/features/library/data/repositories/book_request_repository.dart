import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/library/domain/entities/book_request.dart';

/// Local queue for book requests until a WordPress endpoint exists.
class BookRequestRepository {
  Future<Result<List<BookRequest>>> listForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('akuko.book_requests.$userId') ?? const [];
    final items = raw.map((line) {
      final parts = line.split('|');
      return BookRequest(
        id: parts[0],
        userId: userId,
        title: parts[1],
        author: parts.length > 2 ? parts[2] : null,
        notes: parts.length > 3 ? parts[3] : null,
        status: parts.length > 4 ? parts[4] : 'pending',
        createdAt: parts.length > 5 ? DateTime.tryParse(parts[5]) : null,
      );
    }).toList();
    return Ok(items);
  }

  Future<Result<BookRequest>> submit({
    required String userId,
    required String title,
    String? author,
    String? genre,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'akuko.book_requests.$userId';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final request = BookRequest(
      id: id,
      userId: userId,
      title: title,
      author: author,
      notes: notes,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    final list = prefs.getStringList(key) ?? [];
    list.insert(
      0,
      '$id|$title|${author ?? ''}|${notes ?? ''}|pending|${request.createdAt!.toIso8601String()}',
    );
    await prefs.setStringList(key, list);
    return Ok(request);
  }
}
