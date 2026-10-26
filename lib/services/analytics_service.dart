import '../models/analytics_summary.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// `/analytics` has no single JSON blob — each Chart.js canvas gets its
/// `labels`/`data` arrays inlined directly in its own `new Chart({...})`
/// call (verified via a live authenticated fetch). Charts/sections with no
/// data simply don't render their canvas at all (e.g. no contacts yet means
/// no contact-growth/contact-status canvases exist) — treated as empty here.
class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<AnalyticsSummary> getAnalytics() async {
    final html = await _client.getAuthedHtml('/analytics');

    List<TrendPoint> series(String canvasId) {
      final labels = ScrapeUtils.extractArrayAfterAnchor(html, "getElementById('$canvasId')", 'labels');
      final data = ScrapeUtils.extractArrayAfterAnchor(html, "getElementById('$canvasId')", 'data');
      if (labels == null || data == null) return const [];
      final points = <TrendPoint>[];
      for (var i = 0; i < labels.length && i < data.length; i++) {
        final count = data[i];
        points.add(TrendPoint(labels[i].toString(), count is int ? count : int.tryParse('$count') ?? 0));
      }
      return points;
    }

    List<NamedCount> named(String canvasId) =>
        series(canvasId).map((p) => NamedCount(p.label, p.count)).toList();

    int statFrom(String label) {
      final match = RegExp(
        '<div class="num">([\\d,]+)</div><div class="label">${RegExp.escape(label)}</div>',
      ).firstMatch(html);
      final raw = match?.group(1)?.replaceAll(',', '');
      return raw == null ? 0 : int.tryParse(raw) ?? 0;
    }

    final rawHeatmap = ScrapeUtils.extractJsLiteral(html, 'raw');
    final weekly = <WeeklyActivityCell>[];
    if (rawHeatmap is List) {
      for (final row in rawHeatmap.whereType<Map<String, dynamic>>()) {
        weekly.add(WeeklyActivityCell.fromJson(row));
      }
    }

    return AnalyticsSummary(
      totalViews: statFrom('Profile Views'),
      totalClicks: statFrom('Link Clicks'),
      trend: series('trendChart'),
      peakHours: series('peakHoursChart'),
      clickBreakdown: named('clickBreakdownChart'),
      cardStatus: named('cardStatusChart'),
      notificationActivity: named('notificationActivityChart'),
      contactGrowth: series('contactGrowthChart'),
      topCompanies: named('topCompaniesChart'),
      totalConnections: statFrom('Connections'),
      activeCards: statFrom('Active Cards'),
      unreadNotifications: statFrom('Unread Notifications'),
      weeklyActivity: weekly,
    );
  }
}
