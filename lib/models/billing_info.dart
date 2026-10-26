import 'subscription_plan.dart';

class PaymentMethodInfo {
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;

  PaymentMethodInfo({
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return PaymentMethodInfo(
      brand: json['brand']?.toString() ?? 'card',
      last4: json['last4']?.toString() ?? '----',
      expMonth: asInt(json['exp_month']),
      expYear: asInt(json['exp_year']),
    );
  }
}

class BillingInfo {
  final SubscriptionPlan plan;
  final String billingCycle; // Monthly | Yearly
  final String? stripeSubscriptionStatus;
  final bool willCancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;
  final PaymentMethodInfo? paymentMethod;

  BillingInfo({
    required this.plan,
    required this.billingCycle,
    this.stripeSubscriptionStatus,
    this.willCancelAtPeriodEnd = false,
    this.currentPeriodEnd,
    this.paymentMethod,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    final me = json['me'] is Map<String, dynamic> ? json['me'] as Map<String, dynamic> : json;
    return BillingInfo(
      plan: SubscriptionPlan.fromJson(me),
      billingCycle: me['plan_billing_cycle']?.toString() ?? 'Monthly',
      stripeSubscriptionStatus: json['stripe_subscription_status']?.toString(),
      willCancelAtPeriodEnd: json['stripe_cancel_at_period_end'] == true,
      currentPeriodEnd: DateTime.tryParse(json['stripe_current_period_end']?.toString() ?? ''),
      paymentMethod: json['payment_method'] is Map<String, dynamic>
          ? PaymentMethodInfo.fromJson(json['payment_method'] as Map<String, dynamic>)
          : null,
    );
  }
}
