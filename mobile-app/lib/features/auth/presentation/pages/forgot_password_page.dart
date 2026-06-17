import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/error/failures.dart' show describeError;
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/core/utils/validators.dart';
import 'package:akuko/core/widgets/app_button.dart';
import 'package:akuko/core/widgets/app_text_field.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      final failure = ref.read(authControllerProvider).asError?.error;
      context.showSnack(
        failure == null
            ? 'Could not send reset email'
            : describeError(failure, 'Could not send reset email'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _confirmation(context) : _form(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form() {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your email and we will send you a link to reset your '
            'password.',
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            hintText: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send reset link',
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _confirmation(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 64, color: context.colors.primary),
        const SizedBox(height: 16),
        Text(
          'Check your inbox',
          style: context.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists for ${_emailController.text.trim()}, you will '
          'receive a password reset link shortly.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Back to sign in',
          variant: AppButtonVariant.outlined,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
