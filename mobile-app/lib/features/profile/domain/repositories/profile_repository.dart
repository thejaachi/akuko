import 'package:akuko/core/utils/result.dart';
import 'package:akuko/shared/domain/entities/profile.dart';

/// Profile contract. Implemented by `SupabaseProfileRepository`.
abstract interface class ProfileRepository {
  /// Fetches the profile row for [userId].
  Future<Result<Profile>> getProfile(String userId);

  /// Updates editable profile fields (full name, bio, avatar).
  Future<Result<Profile>> updateProfile(Profile profile);

  /// Persists the reading-preferences JSON for [userId].
  Future<Result<void>> updateReadingPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
}
