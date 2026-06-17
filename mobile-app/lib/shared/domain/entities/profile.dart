import 'package:equatable/equatable.dart';

import 'package:akuko/shared/domain/entities/shipping_address.dart';

/// Mirrors the `profiles` table (1:1 with `auth.users`).
///
/// `reading_preferences` is kept as a raw map at the domain level; the reader
/// feature parses it into a typed `ReaderSettings`.
class Profile extends Equatable {
  const Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.isAdmin = false,
    this.readingPreferences,
    this.shippingAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final bool isAdmin;
  final Map<String, dynamic>? readingPreferences;
  final ShippingAddress? shippingAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? readingPreferences,
    ShippingAddress? shippingAddress,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isAdmin: isAdmin,
      readingPreferences: readingPreferences ?? this.readingPreferences,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        avatarUrl,
        bio,
        isAdmin,
        readingPreferences,
        shippingAddress,
        createdAt,
        updatedAt,
      ];
}
