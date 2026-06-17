import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akuko/core/config/env.dart';
import 'package:akuko/core/constants/wallet_constants.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/profile/presentation/controllers/currency_controller.dart';
import 'package:akuko/features/profile/presentation/controllers/transaction_providers.dart';
import 'package:akuko/features/subscriptions/presentation/pages/paystack_checkout_page.dart';
import 'package:akuko/features/wallet/presentation/controllers/wallet_providers.dart';

/// Top-up cowries wallet via Paystack or dev credit.
class TopUpWalletPage extends ConsumerStatefulWidget {
  const TopUpWalletPage({super.key});

  @override
  ConsumerState<TopUpWalletPage> createState() => _TopUpWalletPageState();
}

class _TopUpWalletPageState extends ConsumerState<TopUpWalletPage> {
  final _amountController = TextEditingController(text: '1000');
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amountNgn {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  bool get _isValidAmount {
    final amount = _amountNgn;
    if (amount == null || amount <= 0) return false;
    return WalletConstants.isValidTopUpNgn(amount);
  }

  String? get _amountError {
    final amount = _amountNgn;
    if (amount == null || amount <= 0) return null;
    if (!WalletConstants.isValidTopUpNgn(amount)) {
      return 'Minimum top-up is ₦1,000 (50 Cowries).';
    }
    return null;
  }

  int get _cowriesPreview =>
      WalletConstants.ngnToCowries(_amountNgn ?? 0);

  Future<void> _topUpPaystack() async {
    if (!Env.isPaystackConfigured) {
      context.showSnack('Payment processing is not configured yet');
      return;
    }

    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    final fiat = _amountNgn;
    if (fiat == null || !_isValidAmount) {
      context.showSnack('Enter a valid amount (minimum ₦1,000)');
      return;
    }

    final currency = ref.read(currencyControllerProvider);
    final cowries = WalletConstants.ngnToCowries(fiat);

    setState(() => _busy = true);
    try {
      final initResult = await ref.read(walletRepositoryProvider).initializeWalletTopUp(
            fiatAmount: fiat,
            currency: currency,
            cowries: cowries,
          );

      await initResult.fold(
        (f) async {
          if (mounted) context.showSnack(f.message);
        },
        (init) async {
          if (!mounted) return;

          final reachedCallback = await Navigator.of(context, rootNavigator: true)
              .push<bool>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) =>
                  PaystackCheckoutPage(authorizationUrl: init.authorizationUrl),
            ),
          );

          if (reachedCallback != true) {
            if (mounted) context.showSnack('Payment cancelled');
            return;
          }

          final credit = await ref
              .read(walletRepositoryProvider)
              .creditFromPaystackReference(init.reference);

          credit.fold(
            (f) {
              if (mounted) context.showSnack(f.message);
            },
            (_) {
              ref.invalidate(cowriesBalanceProvider);
              ref.invalidate(walletTransactionsProvider);
              ref.invalidate(unifiedTransactionsProvider);
              if (mounted) {
                context.showSnack('Added $cowries cowries to your wallet');
                Navigator.pop(context);
              }
            },
          );
        },
      );
    } catch (e) {
      if (mounted) context.showSnack('Could not complete top-up');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _topUpDev() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    final fiat = _amountNgn;
    if (fiat == null || !_isValidAmount) {
      context.showSnack('Enter a valid amount (minimum ₦1,000)');
      return;
    }

    final cowries = WalletConstants.ngnToCowries(fiat);

    setState(() => _busy = true);
    try {
      final currency = ref.read(currencyControllerProvider);
      final result = await ref.read(walletRepositoryProvider).topUp(
            userId: userId,
            cowries: cowries,
            fiatAmount: fiat,
            currency: currency,
          );
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(cowriesBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
          ref.invalidate(unifiedTransactionsProvider);
          if (mounted) {
            context.showSnack('Added $cowries cowries (dev credit)');
            Navigator.pop(context);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(cowriesBalanceProvider);
    final cowriesPreview = _cowriesPreview;
    final amountError = _amountError;
    final canPay = _isValidAmount && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.surfaceElevated,
              child: ListTile(
                leading: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.warmGold,
                ),
                title: const Text('Current balance'),
                subtitle: balance.when(
                  loading: () => const Text('Loading…'),
                  error: (_, __) => const Text('—'),
                  data: (b) => Text(
                    '$b cowries',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: AppColors.warmGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Amount (NGN)',
                hintText: '1000',
                prefixText: '₦ ',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText: amountError,
                helperText: _isValidAmount
                    ? 'You will receive $cowriesPreview Cowries'
                    : '50 Cowries = ₦1,000 NGN (minimum top-up)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canPay && Env.isPaystackConfigured ? _topUpPaystack : null,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue to Payment'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: canPay ? _topUpDev : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.burntSienna,
                side: const BorderSide(color: AppColors.burntSienna),
              ),
              child: const Text('Add test cowries (dev)'),
            ),
            const SizedBox(height: 16),
            Text(
              Env.isPaystackConfigured
                  ? 'Payments are processed securely. Cowries are credited after server confirmation.'
                  : 'Set PAYSTACK_PUBLIC_KEY to enable live top-ups. Use dev credit during testing.',
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
