import 'package:akuko/features/subscriptions/domain/entities/subscription.dart';

/// Maps `subscriptions` rows to the [Subscription] entity.
class SubscriptionModel {
  const SubscriptionModel._();

  static Subscription fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return Subscription(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String,
      plan: SubscriptionPlan.fromWire(json['plan'] as String?),
      status: SubscriptionStatus.fromWire(json['status'] as String?),
      paystackCustomerCode: json['paystack_customer_code'] as String?,
      paystackSubscriptionCode: json['paystack_subscription_code'] as String?,
      currentPeriodStart: parse(json['current_period_start']),
      currentPeriodEnd: parse(json['current_period_end']),
      createdAt: parse(json['created_at']),
      updatedAt: parse(json['updated_at']),
    );
  }
}
