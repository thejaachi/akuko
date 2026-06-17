import 'package:akuko/core/error/exceptions.dart';
import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:akuko/features/profile/data/models/profile_model.dart';
import 'package:akuko/features/profile/domain/repositories/profile_repository.dart';
import 'package:akuko/shared/domain/entities/profile.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._remote);

  final ProfileRemoteDataSource _remote;

  Failure _mapError(Object error) => switch (error) {
        NotFoundException(:final message) => NotFoundFailure(message),
        NetworkException(:final message) => NetworkFailure(message),
        ServerException(:final message) => ServerFailure(message, error),
        _ => UnknownFailure('Profile error', error),
      };

  @override
  Future<Result<Profile>> getProfile(String userId) {
    return guardAsync(
      () async => ProfileModel.fromJson(await _remote.getProfile(userId)),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<Profile>> updateProfile(Profile profile) {
    return guardAsync(
      () async => ProfileModel.fromJson(
        await _remote.updateProfile(
          profile.id,
          ProfileModel.toUpdateJson(profile),
        ),
      ),
      onError: (e, _) => _mapError(e),
    );
  }

  @override
  Future<Result<void>> updateReadingPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) {
    return guardAsync(
      () => _remote.updateReadingPreferences(userId, preferences),
      onError: (e, _) => _mapError(e),
    );
  }
}
