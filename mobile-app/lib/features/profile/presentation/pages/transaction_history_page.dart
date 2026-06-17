import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/empty_view.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/profile/presentation/controllers/transaction_providers.dart';

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  String _badgeLabel(UnifiedTransactionKind kind) => switch (kind) {
        UnifiedTransactionKind.walletTopUp => 'Wallet Top-up',
        UnifiedTransactionKind.bookPurchase => 'Book Purchase',
        UnifiedTransactionKind.subscription => 'Subscription',
        UnifiedTransactionKind.payment => 'Payment',
      };

  Color _badgeColor(UnifiedTransactionKind kind) => switch (kind) {
        UnifiedTransactionKind.walletTopUp => AppColors.forestGreen,
        UnifiedTransactionKind.bookPurchase => AppColors.burntSienna,
        UnifiedTransactionKind.subscription => AppColors.warmGold,
        UnifiedTransactionKind.payment => AppColors.cobaltBlue,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(unifiedTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: transactions.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: describeError(e, 'Could not load transactions'),
          onRetry: () => ref.invalidate(unifiedTransactionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message:
                  'Wallet top-ups, book purchases, and subscriptions will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final tx = items[i];
              return ListTile(
                leading: Icon(
                  tx.isCredit
                      ? Icons.add_circle_outline
                      : Icons.receipt_long_outlined,
                  color: AppColors.burntSienna,
                ),
                title: Text(tx.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tx.createdAt != null)
                      Text(
                        DateFormat.yMMMd().add_jm().format(tx.createdAt!),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeColor(tx.kind).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _badgeLabel(tx.kind),
                        style: context.textTheme.labelSmall?.copyWith(
                          color: _badgeColor(tx.kind),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  tx.amountLabel,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: AppColors.warmGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
