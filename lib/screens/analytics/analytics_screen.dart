import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/analytics_summary.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsSummary? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AnalyticsService.instance.getAnalytics();
      if (mounted) setState(() => _data = data);
    } catch (_) {
      // Keep previous state; pull to retry.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final data = _data;
    if (data == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [EmptyState(icon: Icons.bar_chart_outlined, message: 'Could not load analytics. Pull to retry.')],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeading('Card Performance'),
          Row(
            children: [
              Expanded(child: StatCard(value: '${data.totalViews}', label: 'Profile Views', icon: Icons.visibility_outlined)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '${data.totalClicks}', label: 'Link Clicks', icon: Icons.touch_app_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Last 7 Days',
            child: data.trend.isEmpty
                ? const _ChartEmpty('No views recorded yet.')
                : _LineChart(points: data.trend),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Clicks by Link Type',
            child: data.clickBreakdown.isEmpty
                ? const _ChartEmpty('No link clicks recorded yet.')
                : _BreakdownList(items: data.clickBreakdown),
          ),
          const SizedBox(height: 24),
          const SectionHeading('Account Engagement'),
          Row(
            children: [
              Expanded(child: StatCard(value: '${data.totalConnections}', label: 'Connections', icon: Icons.people_outline)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '${data.activeCards}', label: 'Active Cards', icon: Icons.credit_card)),
              const SizedBox(width: 10),
              Expanded(child: StatCard(value: '${data.unreadNotifications}', label: 'Unread', icon: Icons.notifications_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Contact Growth (30 days)',
            child: data.contactGrowth.isEmpty
                ? const _ChartEmpty('No new connections in the last 30 days.')
                : _LineChart(points: data.contactGrowth),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Top Connections by Company',
            child: data.topCompanies.isEmpty
                ? const _ChartEmpty('No contact companies recorded yet.')
                : _RankedList(items: data.topCompanies),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Weekly Activity',
            child: data.weeklyActivity.isEmpty
                ? const _ChartEmpty('No activity in the last 7 days.')
                : _Heatmap(cells: data.weeklyActivity),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  final String message;
  const _ChartEmpty(this.message);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(child: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<TrendPoint> points;
  const _LineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(points[i].label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble())],
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppColors.primaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final List<NamedCount> items;
  const _BreakdownList({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.count);
    return Column(
      children: items.map((item) {
        final pct = total == 0 ? 0.0 : item.count / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                  Text('${item.count}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: AppColors.inputBackground,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RankedList extends StatelessWidget {
  final List<NamedCount> items;
  const _RankedList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.primaryLight,
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(items[i].name, style: const TextStyle(fontSize: 13))),
                Text('${items[i].count}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Heatmap extends StatelessWidget {
  final List<WeeklyActivityCell> cells;
  const _Heatmap({required this.cells});

  @override
  Widget build(BuildContext context) {
    // Backend's DAYOFWEEK() is 1=Sunday..7=Saturday; normalize to 0=Sun..6=Sat
    // to match the `days` label array below.
    final grid = <String, int>{};
    var max = 0;
    for (final cell in cells) {
      final zeroBasedDow = cell.dayOfWeek - 1;
      grid['$zeroBasedDow-${cell.hour}'] = cell.count;
      if (cell.count > max) max = cell.count;
    }
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var dow = 0; dow < 7; dow++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 32, child: Text(days[dow], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                for (var hour = 0; hour < 24; hour++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: max > 0 ? (0.12 + 0.88 * ((grid['$dow-$hour'] ?? 0) / max)) : 0.05,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
