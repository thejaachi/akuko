import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:akuko/features/profile/data/repositories/supabase_profile_repository.dart';
import 'package:akuko/features/profile/domain/repositories/profile_repository.dart';
import 'package:akuko/shared/domain/entities/profile.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(userApiProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(ref.watch(profileRemoteDataSourceProvider));
});

/// The signed-in user's profile. Resolves the current user id from the auth
/// repository, then loads the matching `profiles` row.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  // Recompute whenever auth state changes.
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return null;
  return (await ref.watch(profileRepositoryProvider).getProfile(userId))
      .getOrThrow();
});
