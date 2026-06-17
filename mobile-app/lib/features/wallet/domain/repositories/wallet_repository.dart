import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';
import 'package:akuko/features/wallet/domain/entities/wallet.dart';

abstract class WalletRepository {
  Future<Result<Wallet>> getWallet(String userId);
  Future<Result<List<WalletTransaction>>> listTransactions(String userId);
  Future<Result<Wallet>> topUp({
    required String userId,
    required int cowries,
    required double fiatAmount,
    required String currency,
  });
  Future<Result<void>> purchaseWithCowries({
    required String userId,
    required String bookId,
    required int amountCowries,
  });

  Future<Result<PaystackInit>> initializeWalletTopUp({
    required double fiatAmount,
    required String currency,
    required int cowries,
  });

  Future<Result<void>> creditFromPaystackReference(String reference);

  Future<Result<void>> purchaseSubscriptionWithCowries(int amountCowries);
}
