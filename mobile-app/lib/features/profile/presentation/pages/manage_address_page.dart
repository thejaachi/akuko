import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akuko/core/theme/app_colors.dart';
import 'package:akuko/core/utils/extensions.dart';
import 'package:akuko/features/auth/presentation/controllers/auth_controller.dart';
import 'package:akuko/features/profile/presentation/controllers/profile_providers.dart';
import 'package:akuko/shared/domain/entities/profile.dart';
import 'package:akuko/shared/domain/entities/shipping_address.dart';

class ManageAddressPage extends ConsumerStatefulWidget {
  const ManageAddressPage({super.key});

  @override
  ConsumerState<ManageAddressPage> createState() => _ManageAddressPageState();
}

class _ManageAddressPageState extends ConsumerState<ManageAddressPage> {
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _addressLoaded = false;

  void _loadFromProfile(Profile? profile) {
    if (_addressLoaded || profile?.shippingAddress == null) return;
    final addr = profile!.shippingAddress!;
    _streetController.text = addr.street ?? '';
    _cityController.text = addr.city ?? '';
    _stateController.text = addr.state ?? '';
    _postalController.text = addr.postalCode ?? '';
    _phoneController.text = addr.phone ?? '';
    _addressLoaded = true;
  }

  Future<void> _save() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (userId == null || profile == null) return;

    final address = ShippingAddress(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (address.isEmpty) {
      context.showSnack('Enter at least one address field');
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = profile.copyWith(shippingAddress: address);
      final result =
          await ref.read(profileRepositoryProvider).updateProfile(updated);
      result.fold(
        (f) {
          if (mounted) context.showSnack(f.message);
        },
        (_) {
          ref.invalidate(currentProfileProvider);
          if (mounted) {
            context.showSnack('Address saved');
            Navigator.pop(context);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentProfileProvider, (prev, next) {
      next.whenData(_loadFromProfile);
    });
    final profile = ref.watch(currentProfileProvider);
    profile.whenData(_loadFromProfile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Address'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Shipping details for hardcopy orders',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Street address / house number',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City / town'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stateController,
            decoration: const InputDecoration(labelText: 'State / region'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postalController,
            decoration: const InputDecoration(labelText: 'Postal / ZIP code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact phone'),
          ),
        ],
      ),
    );
  }
}
