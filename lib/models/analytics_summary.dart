class TrendPoint {
  final String label;
  final int count;
  TrendPoint(this.label, this.count);

  factory TrendPoint.fromJson(Map<String, dynamic> json, {String labelKey = 'date'}) {
    final count = json['count'] ?? json['c'] ?? json['total'] ?? 0;
    return TrendPoint(
      json[labelKey]?.toString() ?? json['label']?.toString() ?? '',
      count is int ? count : int.tryParse('$count') ?? 0,
    );
  }
}

class NamedCount {
  final String name;
  final int count;
  NamedCount(this.name, this.count);
}

/// Full /analytics payload — see CardController::analytics().
class AnalyticsSummary {
  final int totalViews;
  final int totalClicks;
  final List<TrendPoint> trend;
  final List<NamedCount> clickBreakdown;
  final List<TrendPoint> peakHours;
  final int totalConnections;
  final int activeCards;
  final int unreadNotifications;
  final Map<String, int> contactBreakdown;
  final List<TrendPoint> contactGrowth;
  final List<NamedCount> cardStatus;
  final List<NamedCount> notificationActivity;
  final List<NamedCount> topCompanies;
  final List<WeeklyActivityCell> weeklyActivity;

  AnalyticsSummary({
    this.totalViews = 0,
    this.totalClicks = 0,
    this.trend = const [],
    this.clickBreakdown = const [],
    this.peakHours = const [],
    this.totalConnections = 0,
    this.activeCards = 0,
    this.unreadNotifications = 0,
    this.contactBreakdown = const {},
    this.contactGrowth = const [],
    this.cardStatus = const [],
    this.notificationActivity = const [],
    this.topCompanies = const [],
    this.weeklyActivity = const [],
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

    List<NamedCount> namedCounts(dynamic raw, String nameKey, String countKey) {
      if (raw is! List) return const [];
      return raw.whereType<Map<String, dynamic>>().map((row) {
        final count = row[countKey];
        return NamedCount(
          row[nameKey]?.toString() ?? 'Unknown',
          count is int ? count : int.tryParse('$count') ?? 0,
        );
      }).toList();
    }

    List<TrendPoint> trendPoints(dynamic raw, {String labelKey = 'date'}) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map((row) => TrendPoint.fromJson(row, labelKey: labelKey))
          .toList();
    }

    Map<String, int> breakdown = {};
    final rawBreakdown = json['contact_breakdown'];
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, value) {
        breakdown[key.toString()] = asInt(value);
      });
    }

    List<WeeklyActivityCell> weekly = const [];
    final rawWeekly = json['weekly_activity'];
    if (rawWeekly is List) {
      weekly = rawWeekly
          .whereType<Map<String, dynamic>>()
          .map(WeeklyActivityCell.fromJson)
          .toList();
    }

    return AnalyticsSummary(
      totalViews: asInt(json['total_views']),
      totalClicks: asInt(json['total_clicks']),
      trend: trendPoints(json['trend']),
      clickBreakdown: namedCounts(json['click_breakdown'], 'clicked_field', 'c'),
      peakHours: trendPoints(json['peak_hours'], labelKey: 'label'),
      totalConnections: asInt(json['total_connections']),
      activeCards: asInt(json['active_cards']),
      unreadNotifications: asInt(json['unread_notifications']),
      contactBreakdown: breakdown,
      contactGrowth: trendPoints(json['contact_growth']),
      cardStatus: namedCounts(json['card_status'], 'card_status', 'c'),
      notificationActivity: namedCounts(json['notification_activity'], 'notification_type', 'total'),
      topCompanies: namedCounts(json['top_companies'], 'company', 'c'),
      weeklyActivity: weekly,
    );
  }
}

class WeeklyActivityCell {
  final int dayOfWeek; // 0=Sun..6=Sat
  final int hour;
  final int count;

  WeeklyActivityCell({required this.dayOfWeek, required this.hour, required this.count});

  factory WeeklyActivityCell.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return WeeklyActivityCell(
      dayOfWeek: asInt(json['dow']),
      hour: asInt(json['hour']),
      count: asInt(json['c']),
    );
  }
}
