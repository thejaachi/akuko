import 'package:akuko/shared/domain/entities/profile.dart';
import 'package:akuko/shared/domain/entities/shipping_address.dart';

/// Maps `profiles` rows to/from the [Profile] entity.
class ProfileModel {
  const ProfileModel._();

  static Profile fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      readingPreferences:
          (json['reading_preferences'] as Map?)?.cast<String, dynamic>(),
      shippingAddress: ShippingAddress.fromJson(
        (json['shipping_address'] as Map?)?.cast<String, dynamic>(),
      ),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  /// Update payload for editable fields only.
  static Map<String, dynamic> toUpdateJson(Profile profile) {
    return {
      'full_name': profile.fullName,
      'avatar_url': profile.avatarUrl,
      'bio': profile.bio,
      if (profile.shippingAddress != null)
        'shipping_address': profile.shippingAddress!.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
