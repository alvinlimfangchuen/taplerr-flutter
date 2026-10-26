/// `/rewards` is a placeholder page on the web today (no real catalogue
/// exists yet) — this model exists so the screen/service shape is ready
/// once the backend grows one, but RewardsScreen renders a "Coming soon"
/// state rather than a speculative full catalogue UI.
class Reward {
  final int rewardId;
  final String rewardName;
  final int pointsRequired;
  final int stockQuantity; // negative = unlimited (see OrderController.php)

  Reward({
    required this.rewardId,
    required this.rewardName,
    required this.pointsRequired,
    required this.stockQuantity,
  });

  bool get isUnlimited => stockQuantity < 0;
  bool get isOutOfStock => stockQuantity == 0;

  factory Reward.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return Reward(
      rewardId: asInt(json['reward_id']),
      rewardName: json['reward_name']?.toString() ?? '',
      pointsRequired: asInt(json['points_required']),
      stockQuantity: asInt(json['stock_quantity']),
    );
  }
}
