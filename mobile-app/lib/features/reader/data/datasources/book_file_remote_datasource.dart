import 'package:akuko/core/api/downloads_api.dart';
import 'package:akuko/core/error/exceptions.dart';

export 'package:akuko/core/api/downloads_api.dart' show PremiumRequiredException;

/// Resolves a short-lived download URL for a book file.
class BookFileRemoteDataSource {
  BookFileRemoteDataSource(this._api);

  final DownloadsApi _api;

  Future<String> fetchSignedUrl(String bookId, {int expiresIn = 3600}) async {
    try {
      // Format inferred by caller context; default epub for reader MVP.
      return await _api.requestDownload(bookId, format: 'epub');
    } on PremiumRequiredException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } on AccessDeniedException catch (e) {
      throw PremiumRequiredException(e.message);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Could not load this book.', e);
    }
  }
}
