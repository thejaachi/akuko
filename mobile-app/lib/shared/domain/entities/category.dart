import 'package:equatable/equatable.dart';

/// Mirrors the `categories` table in the canonical spec.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final int sortOrder;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, name, slug, description, icon, sortOrder, createdAt];
}
