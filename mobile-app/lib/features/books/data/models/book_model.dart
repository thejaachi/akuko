import 'package:akuko/shared/domain/entities/book.dart';
import 'package:akuko/shared/domain/entities/book_delivery_format.dart';

/// Maps the `books` table rows (snake_case JSON) to the [Book] entity.
class BookModel {
  const BookModel._();

  static Book fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      fileUrl: json['file_url'] as String?,
      fileType: BookFileType.fromString(json['file_type'] as String?),
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt(),
      categoryId: json['category_id'] as String?,
      isbn: json['isbn'] as String?,
      language: json['language'] as String? ?? 'en',
      pageCount: (json['page_count'] as num?)?.toInt(),
      publisher: json['publisher'] as String?,
      publishedDate: _parseDate(json['published_date']),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isTrending: json['is_trending'] as bool? ?? false,
      isNewRelease: json['is_new_release'] as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      status: BookStatus.fromString(json['status'] as String?),
      pricingModel:
          BookPricingModel.fromString(json['pricing_model'] as String?),
      deliveryFormat: BookDeliveryFormat.fromString(
            json['delivery_format'] as String?,
          ) ??
          _inferDeliveryFormat(json['file_type'] as String?),
      genreName: _genreFromJoin(json),
      isChristian: json['is_christian'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static Map<String, dynamic> toJson(Book book) {
    return {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'description': book.description,
      'cover_url': book.coverUrl,
      'file_url': book.fileUrl,
      'file_type': book.fileType.wireValue,
      'file_size_bytes': book.fileSizeBytes,
      'category_id': book.categoryId,
      'isbn': book.isbn,
      'language': book.language,
      'page_count': book.pageCount,
      'publisher': book.publisher,
      'published_date': book.publishedDate?.toIso8601String(),
      'price': book.price,
      'is_premium': book.isPremium,
      'is_featured': book.isFeatured,
      'is_trending': book.isTrending,
      'is_new_release': book.isNewRelease,
      'rating_avg': book.ratingAvg,
      'rating_count': book.ratingCount,
      'download_count': book.downloadCount,
      if (book.status != null) 'status': book.status!.wireValue,
      if (book.pricingModel != null)
        'pricing_model': book.pricingModel!.wireValue,
    };
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static BookDeliveryFormat _inferDeliveryFormat(String? fileType) =>
      fileType == null ? BookDeliveryFormat.ebook : BookDeliveryFormat.ebook;

  static String? _genreFromJoin(Map<String, dynamic> json) {
    final categories = json['categories'];
    if (categories is Map) {
      return categories['name'] as String?;
    }
    return null;
  }
}
