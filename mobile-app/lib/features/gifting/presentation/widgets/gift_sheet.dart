import 'package:flutter/material.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';

enum GiftType { book, subscription }

/// Stub gift flow — email capture + Paystack gift TODO.
class GiftSheet extends StatefulWidget {
  const GiftSheet({
    required this.type,
    this.bookTitle,
    super.key,
  });

  final GiftType type;
  final String? bookTitle;

  static Future<void> show(
    BuildContext context, {
    required GiftType type,
    String? bookTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.warmSurface,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: GiftSheet(type: type, bookTitle: bookTitle),
      ),
    );
  }

  @override
  State<GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<GiftSheet> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _title => switch (widget.type) {
        GiftType.book => 'Gift this Book',
        GiftType.subscription => 'Gift a Subscription',
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textWarm,
              ),
            ),
            if (widget.bookTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.bookTitle!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.warmGold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recipient email',
                hintText: 'friend@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Personal message (optional)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final email = _emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  context.showSnack('Enter a valid email');
                  return;
                }
                Navigator.pop(context);
                // TODO(paystack): gift checkout flow.
                context.showSnack(
                  'Gift queued for $email — payment flow coming soon',
                );
              },
              child: const Text('Continue to payment'),
            ),
          ],
        ),
      ),
    );
  }
}
