import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/router/routes.dart';
import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/theme/theme_controller.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/widgets/error_view.dart';
import 'package:akuko/core/widgets/loading_view.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/gifting/presentation/widgets/gift_sheet.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';
import 'package:akuko/features/subscriptions/presentation/controllers/subscription_providers.dart';
import 'package:akuko/features/wallet/presentation/controllers/wallet_providers.dart';
import 'package:akuko/shared/domain/entities/profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(authControllerProvider.notifier).signOut();
    if (context.mounted && ok) context.go(AppRoutes.login);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // TODO(auth): wire Supabase admin delete-user edge function.
    context.showSnack(
      'Account deletion requested — our team will process this shortly.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final email = ref.watch(authRepositoryProvider).currentUser?.email;
    final themeMode = ref.watch(themeModeControllerProvider);
    final subscription = ref.watch(mySubscriptionProvider);
    final balance = ref.watch(cowriesBalanceProvider);

    return Scaffold(
      body: SafeArea(
        child: profile.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: describeError(e, 'Could not load your profile'),
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (p) {
            if (p == null) {
              return const Center(child: Text('No profile found'));
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _IdentityHeader(profile: p, email: email),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SubscriptionCard(subscription: subscription),
                ),
                const SizedBox(height: 8),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Wallet Balance',
                  subtitle: balance.when(
                    loading: () => 'Loading…',
                    error: (_, __) => '—',
                    data: (b) => '$b cowries',
                  ),
                  trailingText: 'Top Up',
                  onTap: () => context.push(AppRoutes.walletTopUp),
                ),
                const Divider(height: 24),
                _MenuTile(
                  icon: Icons.person_outline,
                  title: 'View Profile',
                  onTap: () => context.push(AppRoutes.profileEdit, extra: p),
                ),
                _MenuTile(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Gift Subscription',
                  onTap: () =>
                      GiftSheet.show(context, type: GiftType.subscription),
                ),
                _MenuTile(
                  icon: Icons.text_fields,
                  title: 'Reading Preferences',
                  subtitle: 'Font, theme, and spacing',
                  onTap: () => context.push(AppRoutes.readingPreferences),
                ),
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Manage Address',
                  onTap: () => context.push(AppRoutes.manageAddress),
                ),
                _MenuTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Plans & Subscription',
                  onTap: () => context.go(AppRoutes.subscription),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transaction History',
                  onTap: () => context.push(AppRoutes.transactionHistory),
                ),
                _MenuTile(
                  icon: Icons.lock_outline,
                  title: 'Security & Privacy',
                  onTap: () => context.push(AppRoutes.securityPrivacy),
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: 'Support & Help',
                  onTap: () => context.push(AppRoutes.supportHelp),
                ),
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  title: const Text('Dark Mode'),
                  subtitle: Text(themeMode == ThemeMode.dark ? 'On' : 'Off'),
                  value: themeMode == ThemeMode.dark,
                  activeColor: AppColors.burntSienna,
                  onChanged: (_) =>
                      ref.read(themeModeControllerProvider.notifier).toggle(),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => _signOut(context, ref),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: const Icon(Icons.delete_forever_outlined,
                      color: AppColors.error),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () => _deleteAccount(context, ref),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Akuko Reader · v0.1.0',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.profile, required this.email});

  final Profile profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName ?? 'Reader';
    final avatarUrl = profile.avatarUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.burntSienna.withOpacity(0.25),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? CachedNetworkImageProvider(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: context.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textWarm,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email != null)
                  Text(
                    email!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({required this.subscription});

  final AsyncValue<Subscription> subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return subscription.when(
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Subscription'),
        ),
      ),
      error: (_, __) => Card(
        color: AppColors.surfaceElevated,
        child: ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: const Text('Subscription'),
          subtitle: const Text('Could not load status'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.subscription),
        ),
      ),
      data: (sub) {
        final isPremium = sub.isPremiumActive;
        return Card(
          color: isPremium
              ? AppColors.warmGold.withOpacity(0.12)
              : AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isPremium ? AppColors.warmGold : AppColors.cardBorder,
            ),
          ),
          child: ListTile(
            leading: Icon(
              isPremium ? Icons.workspace_premium : Icons.lock_outline,
              color: isPremium ? AppColors.warmGold : AppColors.textMuted,
            ),
            title: Text(
              isPremium ? 'Premium Active' : 'Free Plan',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isPremium ? 'Manage your subscription' : 'Upgrade for full access',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.subscription),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AppColors.burntSienna),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: context.textTheme.labelMedium?.copyWith(
                color: AppColors.warmGold,
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
