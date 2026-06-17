import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/subscription_providers.dart';
import 'package:akuko/features/wallet/data/repositories/api_wallet_repository.dart';
import 'package:akuko/features/wallet/domain/entities/wallet.dart';
import 'package:akuko/features/wallet/domain/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return ApiWalletRepository(ref.watch(paystackServiceProvider));
});

final cowriesBalanceProvider = FutureProvider<int>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return 0;
  final wallet =
      (await ref.watch(walletRepositoryProvider).getWallet(userId)).getOrThrow();
  return wallet.balanceCowries;
});

final walletTransactionsProvider =
    FutureProvider<List<WalletTransaction>>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const [];
  return (await ref.watch(walletRepositoryProvider).listTransactions(userId))
      .getOrThrow();
});
