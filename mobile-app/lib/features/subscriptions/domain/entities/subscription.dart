import 'package:equatable/equatable.dart';

/// Subscription tier. Mirrors `subscriptions.plan` (`free` | `premium`).
enum SubscriptionPlan {
  free,
  premium;

  static SubscriptionPlan fromWire(String? value) =>
      value == 'premium' ? SubscriptionPlan.premium : SubscriptionPlan.free;

  String get wireValue => name;
}

/// Lifecycle status. Mirrors `subscriptions.status` and Paystack's subscription
/// states (with `past_due` for failed renewals).
enum SubscriptionStatus {
  active,
  nonRenewing,
  attention,
  completed,
  cancelled,
  pastDue,
  incomplete;

  static SubscriptionStatus fromWire(String? value) => switch (value) {
        'active' => SubscriptionStatus.active,
        'non-renewing' => SubscriptionStatus.nonRenewing,
        'attention' => SubscriptionStatus.attention,
        'completed' => SubscriptionStatus.completed,
        'cancelled' => SubscriptionStatus.cancelled,
        'past_due' => SubscriptionStatus.pastDue,
        _ => SubscriptionStatus.incomplete,
      };

  String get wireValue => switch (this) {
        SubscriptionStatus.active => 'active',
        SubscriptionStatus.nonRenewing => 'non-renewing',
        SubscriptionStatus.attention => 'attention',
        SubscriptionStatus.completed => 'completed',
        SubscriptionStatus.cancelled => 'cancelled',
        SubscriptionStatus.pastDue => 'past_due',
        SubscriptionStatus.incomplete => 'incomplete',
      };

  /// Statuses under which a premium plan still grants access. Mirrors the
  /// server-side `is_premium()` SQL helper (`active` + `non-renewing`).
  bool get grantsAccessWhenPremium =>
      this == SubscriptionStatus.active ||
      this == SubscriptionStatus.nonRenewing;
}

/// The current user's subscription record. Backed by one `subscriptions` row.
///
/// Writes are never performed by the client — the Paystack edge functions
/// (service role) own all state transitions. The client only reads this.
class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    this.paystackCustomerCode,
    this.paystackSubscriptionCode,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.createdAt,
    this.updatedAt,
  });

  /// A safe local default used before any row has loaded (treated as free).
  factory Subscription.freeFor(String userId) => Subscription(
        id: '',
        userId: userId,
        plan: SubscriptionPlan.free,
        status: SubscriptionStatus.active,
      );

  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final String? paystackCustomerCode;
  final String? paystackSubscriptionCode;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True when the user currently has valid premium entitlement. Mirrors the
  /// server `is_premium()` definition so the client and backend agree.
  bool get isPremiumActive {
    if (plan != SubscriptionPlan.premium) return false;
    if (!status.grantsAccessWhenPremium) return false;
    final end = currentPeriodEnd;
    return end == null || end.isAfter(DateTime.now());
  }

  /// True when premium is set to lapse at the end of the current period.
  bool get isCancelling =>
      plan == SubscriptionPlan.premium &&
      status == SubscriptionStatus.nonRenewing;

  @override
  List<Object?> get props => [
        id,
        userId,
        plan,
        status,
        paystackCustomerCode,
        paystackSubscriptionCode,
        currentPeriodStart,
        currentPeriodEnd,
        createdAt,
        updatedAt,
      ];
}
