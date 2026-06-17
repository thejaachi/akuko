import 'package:akuko/core/error/failures.dart';
import 'package:akuko/core/utils/result.dart';
import 'package:akuko/features/subscriptions/data/services/paystack_service.dart';
import 'package:akuko/features/subscriptions/domain/entities/paystack_transaction.dart';
import 'package:akuko/features/wallet/domain/entities/wallet.dart';
import 'package:akuko/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:akuko/core/constants/app_constants.dart';

/// Wallet with local prefs fallback — no WordPress wallet endpoint yet.
class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(this._paystack);

  final PaystackService _paystack;

  Future<int> _localBalance(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${AppConstants.prefsCowriesBalance}.$userId') ?? 0;
  }

  Future<void> _setLocalBalance(String userId, int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${AppConstants.prefsCowriesBalance}.$userId', balance);
  }

  @override
  Future<Result<Wallet>> getWallet(String userId) async {
    final local = await _localBalance(userId);
    return Ok(Wallet(userId: userId, balanceCowries: local));
  }

  @override
  Future<Result<List<WalletTransaction>>> listTransactions(String userId) async {
    return const Ok([]);
  }

  @override
  Future<Result<Wallet>> topUp({
    required String userId,
    required int cowries,
    required double fiatAmount,
    required String currency,
  }) async {
    final balance = await _localBalance(userId) + cowries;
    await _setLocalBalance(userId, balance);
    return Ok(Wallet(userId: userId, balanceCowries: balance, currency: currency));
  }

  @override
  Future<Result<void>> purchaseWithCowries({
    required String userId,
    required String bookId,
    required int amountCowries,
  }) async {
    final local = await _localBalance(userId);
    if (local < amountCowries) {
      return const Err(ValidationFailure('Insufficient cowries balance'));
    }
    await _setLocalBalance(userId, local - amountCowries);
    return const Ok(null);
  }

  @override
  Future<Result<PaystackInit>> initializeWalletTopUp({
    required double fiatAmount,
    required String currency,
    required int cowries,
  }) async {
    try {
      final amountKobo = (fiatAmount * 100).round();
      final init = await _paystack.initializeTransaction(
        amount: amountKobo,
        currency: currency,
        metadata: {
          'type': 'wallet_top_up',
          'cowries': cowries,
          'amount_ngn': fiatAmount,
        },
      );
      return Ok(init);
    } catch (e) {
      return Err(ServerFailure('Could not start payment', e));
    }
  }

  @override
  Future<Result<void>> creditFromPaystackReference(String reference) async {
    try {
      final verification = await _paystack.verifyTransaction(reference);
      if (!verification.isSuccess) {
        return const Err(ValidationFailure('Payment was not completed'));
      }
      return const Ok(null);
    } catch (e) {
      return Err(ServerFailure('Could not verify payment', e));
    }
  }

  @override
  Future<Result<void>> purchaseSubscriptionWithCowries(int amountCowries) async {
    // TODO(wallet): server-side cowrie subscription purchase not in API.md.
    return const Err(ValidationFailure('Cowrie subscription purchase unavailable'));
  }
}
