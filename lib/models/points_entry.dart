class PointsEntry {
  final String transactionType; // Earned | Redeemed
  final String source; // Purchase | Reward_Redemption | Referral | Admin_Action
  final int pointsAmount;
  final int? referenceId;
  final String? description;
  final DateTime? createdAt;

  PointsEntry({
    required this.transactionType,
    required this.source,
    required this.pointsAmount,
    this.referenceId,
    this.description,
    this.createdAt,
  });

  bool get isEarned => transactionType == 'Earned';

  factory PointsEntry.fromJson(Map<String, dynamic> json) {
    final amount = json['points_amount'];
    return PointsEntry(
      transactionType: json['transaction_type']?.toString() ?? 'Earned',
      source: json['source']?.toString() ?? 'Purchase',
      pointsAmount: amount is int ? amount : int.tryParse('${amount ?? 0}') ?? 0,
      referenceId: json['reference_id'] is int
          ? json['reference_id'] as int
          : int.tryParse('${json['reference_id'] ?? ''}'),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class PointsSummary {
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final List<PointsEntry> history;

  PointsSummary({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.history,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    final rawHistory = json['history'];
    return PointsSummary(
      balance: asInt(json['balance']),
      totalEarned: asInt(json['total_earned']),
      totalRedeemed: asInt(json['total_redeemed']),
      history: rawHistory is List
          ? rawHistory.whereType<Map<String, dynamic>>().map(PointsEntry.fromJson).toList()
          : const [],
    );
  }
}
