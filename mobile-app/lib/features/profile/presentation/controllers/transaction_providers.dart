import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/network/api_client_provider.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/wallet/domain/entities/wallet.dart';
import 'package:akuko/features/wallet/presentation/controllers/wallet_providers.dart';

enum UnifiedTransactionKind {
  walletTopUp,
  bookPurchase,
  subscription,
  payment,
}

class UnifiedTransaction {
  const UnifiedTransaction({
    required this.id,
    required this.kind,
    required this.title,
    required this.amountLabel,
    required this.createdAt,
    this.isCredit = false,
  });

  final String id;
  final UnifiedTransactionKind kind;
  final String title;
  final String amountLabel;
  final DateTime? createdAt;
  final bool isCredit;
}

final unifiedTransactionsProvider =
    FutureProvider<List<UnifiedTransaction>>((ref) async {
  ref.watch(currentUserProvider);
  final userId = ref.watch(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const [];

  final walletTx = await ref.watch(walletTransactionsProvider.future);
  final paymentRows = await _fetchPaymentTransactions(ref);
  final subscriptionRows = await _fetchSubscriptionStatus(ref);

  final items = <UnifiedTransaction>[
    ...walletTx.map(_fromWallet),
    ...paymentRows,
    ...subscriptionRows,
  ]..sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

  return items;
});

String _formatNgn(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(2);
}

UnifiedTransaction _fromWallet(WalletTransaction tx) {
  final kind = switch (tx.type) {
    WalletTransactionType.topUp => UnifiedTransactionKind.walletTopUp,
    WalletTransactionType.refund => UnifiedTransactionKind.walletTopUp,
    WalletTransactionType.purchase => tx.reference == 'subscription_premium'
        ? UnifiedTransactionKind.subscription
        : UnifiedTransactionKind.bookPurchase,
  };

  final title = switch (kind) {
    UnifiedTransactionKind.walletTopUp => tx.fiatAmount != null
        ? 'Wallet Top-up — ₦${_formatNgn(tx.fiatAmount!)} → ${tx.amountCowries} Cowries'
        : 'Wallet Top-up — ${tx.amountCowries} Cowries',
    UnifiedTransactionKind.bookPurchase => 'Book Purchase',
    UnifiedTransactionKind.subscription => 'Subscription',
    UnifiedTransactionKind.payment => 'Payment',
  };

  final sign = tx.type == WalletTransactionType.purchase ? '-' : '+';
  return UnifiedTransaction(
    id: 'wallet-${tx.id}',
    kind: kind,
    title: title,
    amountLabel: '$sign${tx.amountCowries} 🐚',
    createdAt: tx.createdAt,
    isCredit: tx.type != WalletTransactionType.purchase,
  );
}

Future<List<UnifiedTransaction>> _fetchPaymentTransactions(Ref ref) async {
  try {
    final rows = await ref.read(paymentsApiProvider).history();
    return rows.map((map) {
      final amount = map['amount'];
      final currency = map['currency'] as String? ?? 'NGN';
      return UnifiedTransaction(
        id: 'pay-${map['id']}',
        kind: UnifiedTransactionKind.payment,
        title: 'Subscription Payment',
        amountLabel: '₦$amount $currency',
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString())
            : null,
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}

Future<List<UnifiedTransaction>> _fetchSubscriptionStatus(Ref ref) async {
  try {
    final row = await ref.read(premiumApiProvider).status();
    if (row == null) return const [];
    if (row['plan'] != 'premium' && row['is_premium'] != true) return const [];
    return [
      UnifiedTransaction(
        id: 'sub-${row['user_id'] ?? 'current'}',
        kind: UnifiedTransactionKind.subscription,
        title: 'Premium Subscription Active',
        amountLabel: row['status'] as String? ?? 'active',
        createdAt: row['current_period_start'] != null
            ? DateTime.tryParse(row['current_period_start'].toString())
            : null,
      ),
    ];
  } catch (_) {
    return const [];
  }
}
