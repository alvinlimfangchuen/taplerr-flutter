class SubscriptionPlan {
  final int planId;
  final String planSlug;
  final String planName;
  final String? description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int yearlyDiscountPercent;
  final int maxProfiles;
  final List<String> features;

  SubscriptionPlan({
    required this.planId,
    required this.planSlug,
    required this.planName,
    this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    this.yearlyDiscountPercent = 0,
    this.maxProfiles = 1,
    this.features = const [],
  });

  bool get isFree => monthlyPrice <= 0;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    List<String> features = const [];
    final rawFeatures = json['plan_features'];
    if (rawFeatures is List) {
      features = rawFeatures.map((e) => e.toString()).toList();
    }
    return SubscriptionPlan(
      planId: asInt(json['plan_id']),
      planSlug: json['plan_slug']?.toString() ?? '',
      planName: json['plan_name']?.toString() ?? '',
      description: json['plan_description']?.toString(),
      monthlyPrice: asDouble(json['monthly_price']),
      yearlyPrice: asDouble(json['yearly_price']),
      yearlyDiscountPercent: asInt(json['yearly_discount_percent']),
      maxProfiles: asInt(json['max_profiles']) == 0 ? 1 : asInt(json['max_profiles']),
      features: features,
    );
  }
}
