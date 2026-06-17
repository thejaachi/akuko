import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';

/// User library contract. For the MVP this surfaces "continue reading"
/// (books the user has progress on). Saved/wishlist lists are Phase 2.
abstract interface class LibraryRepository {
  /// Books the user has started, most-recently-read first.
  Future<Result<List<LibraryEntry>>> getContinueReading({int limit = 30});
}
