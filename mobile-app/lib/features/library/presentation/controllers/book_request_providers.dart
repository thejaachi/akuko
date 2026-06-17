import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/library/data/repositories/book_request_repository.dart';
import 'package:akuko/features/library/domain/entities/book_request.dart';

final bookRequestRepositoryProvider = Provider<BookRequestRepository>((ref) {
  return BookRequestRepository();
});

final bookRequestsProvider = FutureProvider<List<BookRequest>>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const [];
  return (await ref.watch(bookRequestRepositoryProvider).listForUser(userId))
      .getOrThrow();
});
