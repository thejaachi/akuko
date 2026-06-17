import 'package:akuko/core/api/api_client.dart';
import 'package:akuko/core/error/exceptions.dart';

class DownloadsApi {
  DownloadsApi(this._client);

  final AkukoApiClient _client;

  Future<String> requestDownload(
    String bookId, {
    String format = 'epub',
  }) async {
    try {
      final data = await _client.post(
        'downloads/$bookId/request',
        auth: true,
        body: {'format': format},
      ) as Map<String, dynamic>;

      final url = (data['url'] ?? data['signedUrl']) as String?;
      if (url == null || url.isEmpty) {
        throw const ServerException('Download URL missing from response');
      }
      return url;
    } on AccessDeniedException catch (e) {
      throw PremiumRequiredException(e.message);
    }
  }
}

/// Thrown when download is refused due to missing purchase/premium.
class PremiumRequiredException implements Exception {
  const PremiumRequiredException([
    this.message = 'A subscription is required to read this book.',
  ]);

  final String message;

  @override
  String toString() => 'PremiumRequiredException: $message';
}
