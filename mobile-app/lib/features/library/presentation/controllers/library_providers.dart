import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/library/data/datasources/library_remote_datasource.dart';
import 'package:akuko/features/library/data/repositories/supabase_library_repository.dart';
import 'package:akuko/features/library/domain/entities/library_entry.dart';
import 'package:akuko/features/library/domain/repositories/library_repository.dart';

final libraryRemoteDataSourceProvider =
    Provider<LibraryRemoteDataSource>((ref) {
  return LibraryRemoteDataSource(ref.watch(userApiProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return SupabaseLibraryRepository(ref.watch(libraryRemoteDataSourceProvider));
});

final continueReadingProvider =
    FutureProvider<List<LibraryEntry>>((ref) async {
  ref.watch(currentUserProvider);
  return (await ref.watch(libraryRepositoryProvider).getContinueReading())
      .getOrThrow();
});
