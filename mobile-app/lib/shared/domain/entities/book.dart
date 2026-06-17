import 'package:equatable/equatable.dart';

import 'package:akuko/shared/domain/entities/book_delivery_format.dart';

/// Catalogue workflow status (future `books.status` column, migration 0008+).
enum BookStatus {
  draft,
  pendingReview,
  published,
  rejected,
  archived;

  static BookStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'draft' => BookStatus.draft,
      'pending_review' => BookStatus.pendingReview,
      'published' => BookStatus.published,
      'rejected' => BookStatus.rejected,
      'archived' => BookStatus.archived,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
        BookStatus.draft => 'draft',
        BookStatus.pendingReview => 'pending_review',
        BookStatus.published => 'published',
        BookStatus.rejected => 'rejected',
        BookStatus.archived => 'archived',
      };

  bool get isPendingReview => this == BookStatus.pendingReview;
}

/// How a book is monetized (future `books.pricing_model` column).
enum BookPricingModel {
  free,
  oneTime,
  premiumOnly,
  subscription;

  static BookPricingModel? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value) {
      'free' => BookPricingModel.free,
      'one_time' => BookPricingModel.oneTime,
      'premium_only' => BookPricingModel.premiumOnly,
      'subscription' => BookPricingModel.subscription,
      _ => null,
    };
  }

  String get wireValue => switch (this) {
        BookPricingModel.free => 'free',
        BookPricingModel.oneTime => 'one_time',
        BookPricingModel.premiumOnly => 'premium_only',
        BookPricingModel.subscription => 'subscription',
      };
}

/// File container for a book's content (matches `books.file_type` check).
enum BookFileType {
  epub,
  pdf;

  static BookFileType fromString(String? value) =>
      value == 'pdf' ? BookFileType.pdf : BookFileType.epub;

  String get wireValue => name;
}

/// Mirrors the `books` table in the canonical spec.
class Book extends Equatable {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    this.fileUrl,
    this.fileType = BookFileType.epub,
    this.fileSizeBytes,
    this.categoryId,
    this.isbn,
    this.language = 'en',
    this.pageCount,
    this.publisher,
    this.publishedDate,
    this.price = 0,
    this.isPremium = false,
    this.isFeatured = false,
    this.isTrending = false,
    this.isNewRelease = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.downloadCount = 0,
    this.status,
    this.pricingModel,
    this.deliveryFormat = BookDeliveryFormat.ebook,
    this.genreName,
    this.isChristian = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final String? fileUrl;
  final BookFileType fileType;
  final int? fileSizeBytes;
  final String? categoryId;
  final String? isbn;
  final String language;
  final int? pageCount;
  final String? publisher;
  final DateTime? publishedDate;
  final double price;
  final bool isPremium;
  final bool isFeatured;
  final bool isTrending;
  final bool isNewRelease;
  final double ratingAvg;
  final int ratingCount;
  final int downloadCount;

  /// Null when the column is absent (legacy rows / Phase 1 schema).
  final BookStatus? status;
  final BookPricingModel? pricingModel;
  final BookDeliveryFormat deliveryFormat;
  final String? genreName;
  final bool isChristian;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFree => price <= 0 && !isPremium;

  /// Treat missing status as published for reader catalogue compatibility.
  bool get isPublished =>
      status == null || status == BookStatus.published;

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        description,
        coverUrl,
        fileUrl,
        fileType,
        fileSizeBytes,
        categoryId,
        isbn,
        language,
        pageCount,
        publisher,
        publishedDate,
        price,
        isPremium,
        isFeatured,
        isTrending,
        isNewRelease,
        ratingAvg,
        ratingCount,
        downloadCount,
        status,
        pricingModel,
        deliveryFormat,
        genreName,
        isChristian,
        createdAt,
        updatedAt,
      ];
}
