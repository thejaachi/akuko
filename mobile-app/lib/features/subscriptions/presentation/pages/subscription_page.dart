import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/config/env.dart';
import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/features/profile/presentation/controllers/transaction_providers.dart';
import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/subscription_providers.dart';
import 'package:akuko/features/subscriptions/presentation/pages/paystack_checkout_page.dart';
import 'package:akuko/core/widgets/african_pattern_painter.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/gifting/presentation/widgets/gift_sheet.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/author_support_fund_provider.dart';
import 'package:akuko/features/subscriptions/presentation/widgets/billing_wallet_card.dart';
import 'package:akuko/features/subscriptions/presentation/widgets/tier_plan_card.dart';
import 'package:akuko/features/wallet/presentation/controllers/wallet_providers.dart';

/// Subscription tier matrix + Paystack checkout. Presentation-only redesign;
/// checkout flow unchanged ([SubscriptionController]).
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(mySubscriptionProvider);
    final profile = ref.watch(currentProfileProvider);
    final email = ref.watch(authRepositoryProvider).currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: subAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: describeError(e, 'Could not load your subscription'),
          onRetry: () => ref.invalidate(mySubscriptionProvider),
        ),
        data: (sub) => _Body(
          subscription: sub,
          name: profile.valueOrNull?.fullName ?? 'Reader',
          email: email,
        ),
      ),
    );
  }
}

class _TierDefinition {
  const _TierDefinition({
    required this.id,
    required this.name,
    required this.priceNgn,
    required this.description,
    required this.features,
    required this.patternTier,
    this.isPremiumTier = false,
  });

  final String id;
  final String name;
  final int priceNgn;
  final String description;
  final List<String> features;
  final PatternTier patternTier;
  final bool isPremiumTier;
}

const _tiers = [
  _TierDefinition(
    id: 'free',
    name: 'Free',
    priceNgn: 0,
    description: 'Browse free catalogue',
    patternTier: PatternTier.free,
    features: [
      'Browse & read free books',
      'Basic reading progress',
      'Community reviews',
    ],
  ),
  _TierDefinition(
    id: 'standard',
    name: 'Standard',
    priceNgn: 14985,
    description: 'Ad-free reading experience',
    patternTier: PatternTier.standard,
    features: [
      'Everything in Free',
      'Ad-free experience',
      'Cloud sync',
      'Offline downloads (5 books)',
    ],
  ),
  _TierDefinition(
    id: 'premium_audio',
    name: 'Premium Audio',
    priceNgn: 22485,
    description: 'Audiobook & TTS access',
    patternTier: PatternTier.premium,
    features: [
      'Everything in Standard',
      'Audiobook mode (TTS)',
      'AI chapter summaries',
      'Unlimited offline',
    ],
    isPremiumTier: true,
  ),
  _TierDefinition(
    id: 'vip',
    name: 'All-Access VIP',
    priceNgn: 37485,
    description: 'Full catalogue access',
    patternTier: PatternTier.vip,
    features: [
      'Everything in Premium Audio',
      'All premium titles',
      'Early access releases',
      'Priority support',
    ],
    isPremiumTier: true,
  ),
];

class _Body extends ConsumerWidget {
  const _Body({
    required this.subscription,
    required this.name,
    required this.email,
  });

  final Subscription subscription;
  final String name;
  final String email;

  String _activeTierId(Subscription sub) {
    if (!sub.isPremiumActive) return 'free';
    // Map existing premium plan to Premium Audio tier for highlight.
    return 'premium_audio';
  }

  String _formatNgn(int amount) {
    if (amount == 0) return '₦0/month';
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₦$formatted/month';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(subscriptionControllerProvider);
    final activeId = _activeTierId(subscription);
    final isPremium = subscription.isPremiumActive;
    final authorFund = ref.watch(authorSupportFundProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscriptions Tier Matrix',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          BillingWalletCard(name: name, email: email),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => GiftSheet.show(context, type: GiftType.subscription),
            icon: const Icon(Icons.card_giftcard_outlined),
            label: const Text('Gift a Subscription'),
          ),
          const SizedBox(height: 24),
          if (!isPremium)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Contribute 5% to Author Support Fund'),
              subtitle: const Text(
                'Optional donation to support African authors',
              ),
              value: authorFund,
              activeColor: AppColors.forestGreen,
              onChanged: (v) =>
                  ref.read(authorSupportFundProvider.notifier).setEnabled(v),
            ),
          for (final tier in _tiers)
            TierPlanCard(
              name: tier.name,
              priceLabel: _formatNgn(tier.priceNgn),
              description: tier.description,
              features: tier.features,
              tier: tier.patternTier,
              isActive: tier.id == activeId,
              busy: flow.isBusy,
              onSubscribe: tier.id == 'free' || isPremium
                  ? null
                  : tier.isPremiumTier
                      ? () => _subscribe(context, ref, tier)
                      : () => context.showSnack(
                            'Upgrade to ${tier.name} coming soon',
                          ),
            ),
          if (authorFund && !isPremium)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Checkout summary: +5% Author Support Fund contribution',
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.warmGold,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Payment Methods',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.surfaceElevated,
            child: const ListTile(
              leading: Icon(Icons.credit_card, color: AppColors.burntSienna),
              title: Text('Card · Bank · USSD · Transfer'),
              subtitle: Text('Processed securely'),
            ),
          ),
          if (!Env.isPaystackConfigured && !isPremium) ...[
            const SizedBox(height: 16),
            Card(
              color: context.colors.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Direct card checkout requires PAYSTACK_PUBLIC_KEY. '
                  'You can still pay with Cowries if your balance is sufficient.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          if (isPremium && !subscription.isCancelling) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _confirmCancel(context, ref),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel auto-renew'),
            ),
          ],
          if (flow.stage == SubscriptionFlowStage.failed &&
              flow.message != null) ...[
            const SizedBox(height: 16),
            Text(
              flow.message!,
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: context.colors.error),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    WidgetRef ref,
    _TierDefinition tier,
  ) async {
    final authorFund = ref.read(authorSupportFundProvider);
    var amountNgn = tier.priceNgn;
    if (authorFund) {
      amountNgn += (amountNgn * 0.05).round();
    }
    // Subscription cowrie price follows plan NGN price (not wallet top-up rate).
    final cowrieCost = amountNgn;

    final method = await showModalBottomSheet<_PaymentMethod>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose payment method',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.toll_outlined, color: AppColors.warmGold),
                title: const Text('Pay with Cowries'),
                subtitle: Text('$cowrieCost cowries required'),
                onTap: () => Navigator.pop(ctx, _PaymentMethod.cowries),
              ),
              if (Env.isPaystackConfigured)
                ListTile(
                  leading: const Icon(Icons.credit_card, color: AppColors.burntSienna),
                  title: const Text('Pay Directly'),
                  subtitle: const Text('Card · Bank · USSD · Transfer'),
                  onTap: () => Navigator.pop(ctx, _PaymentMethod.paystack),
                ),
            ],
          ),
        ),
      ),
    );

    if (method == null || !context.mounted) return;

    if (method == _PaymentMethod.cowries) {
      await _payWithCowries(context, ref, cowrieCost);
      return;
    }

    await _payWithPaystack(context, ref, tier, amountNgn);
  }

  Future<void> _payWithCowries(
    BuildContext context,
    WidgetRef ref,
    int cowrieCost,
  ) async {
    final result = await ref
        .read(walletRepositoryProvider)
        .purchaseSubscriptionWithCowries(cowrieCost);
    result.fold(
      (f) {
        if (context.mounted) context.showSnack(f.message);
      },
      (_) {
        ref.invalidate(cowriesBalanceProvider);
        ref.invalidate(mySubscriptionProvider);
        ref.invalidate(unifiedTransactionsProvider);
        if (context.mounted) {
          context.showSnack('Welcome to Premium!');
        }
      },
    );
  }

  Future<void> _payWithPaystack(
    BuildContext context,
    WidgetRef ref,
    _TierDefinition tier,
    int amountNgn,
  ) async {
    var amount = amountNgn * 100;
    final plan = _PlanOption(
      title: tier.name,
      amount: amount,
    );
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final planCode = Env.paystackPlanMonthly.isEmpty
        ? null
        : Env.paystackPlanMonthly;
    final init = await controller.startCheckout(
      planCode: planCode,
      amount: planCode == null ? plan.amount : null,
      currency: planCode == null ? Env.paystackCurrency : null,
      metadata: const {'type': 'subscription'},
    );

    if (init == null) {
      if (context.mounted) {
        context.showSnack(
          ref.read(subscriptionControllerProvider).message ??
              'Could not start checkout',
        );
      }
      return;
    }
    if (!context.mounted) return;

    final reachedCallback = await Navigator.of(context, rootNavigator: true)
        .push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            PaystackCheckoutPage(authorizationUrl: init.authorizationUrl),
      ),
    );

    if (reachedCallback != true) {
      controller.abortCheckout();
      return;
    }

    final ok = await controller.verify(init.reference);
    if (context.mounted) {
      context.showSnack(
        ok
            ? 'Welcome to Premium!'
            : (ref.read(subscriptionControllerProvider).message ??
                'Payment was not completed'),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel auto-renew?'),
        content: const Text(
          'Your Premium access continues until the end of the current billing '
          'period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Premium'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel auto-renew'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok =
        await ref.read(subscriptionControllerProvider.notifier).cancel();
    if (context.mounted) {
      context.showSnack(
        ok
            ? 'Auto-renew cancelled'
            : (ref.read(subscriptionControllerProvider).message ??
                'Could not cancel right now'),
      );
    }
  }
}

class _PlanOption {
  const _PlanOption({required this.title, required this.amount});

  final String title;
  final int amount;
}

enum _PaymentMethod { cowries, paystack }
