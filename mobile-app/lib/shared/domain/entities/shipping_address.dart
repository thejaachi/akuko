import 'package:equatable/equatable.dart';

/// Shipping address stored in `profiles.shipping_address` jsonb.
class ShippingAddress extends Equatable {
  const ShippingAddress({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.phone,
  });

  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? phone;

  bool get isEmpty =>
      (street ?? '').isEmpty &&
      (city ?? '').isEmpty &&
      (state ?? '').isEmpty &&
      (postalCode ?? '').isEmpty &&
      (phone ?? '').isEmpty;

  ShippingAddress copyWith({
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
  }) {
    return ShippingAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'phone': phone,
      };

  factory ShippingAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShippingAddress();
    return ShippingAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      phone: json['phone'] as String?,
    );
  }

  @override
  List<Object?> get props => [street, city, state, postalCode, phone];
}
