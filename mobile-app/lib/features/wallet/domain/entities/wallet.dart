import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  const Wallet({
    required this.userId,
    required this.balanceCowries,
    this.currency = 'NGN',
    this.updatedAt,
  });

  final String userId;
  final int balanceCowries;
  final String currency;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [userId, balanceCowries, currency, updatedAt];
}

enum WalletTransactionType { topUp, purchase, refund }

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountCowries,
    this.fiatAmount,
    this.currency = 'NGN',
    this.reference,
    this.createdAt,
  });

  final String id;
  final String userId;
  final WalletTransactionType type;
  final int amountCowries;
  final double? fiatAmount;
  final String currency;
  final String? reference;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        amountCowries,
        fiatAmount,
        currency,
        reference,
        createdAt,
      ];
}
