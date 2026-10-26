import 'package:flutter/material.dart';
import '../../models/points_entry.dart';
import '../../services/points_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../rewards/rewards_screen.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  PointsSummary? _summary;
  bool _loading = true;
  String _tab = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await PointsService.instance.getPoints();
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PointsEntry> get _filtered {
    final history = _summary?.history ?? const [];
    if (_tab == 'Earned') return history.where((e) => e.isEarned).toList();
    if (_tab == 'Redeemed') return history.where((e) => !e.isEarned).toList();
    return history;
  }

  IconData _sourceIcon(String source) {
    switch (source) {
      case 'Purchase':
        return Icons.shopping_cart_outlined;
      case 'Reward_Redemption':
        return Icons.card_giftcard_outlined;
      case 'Referral':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Points'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
            icon: const Icon(Icons.card_giftcard, size: 18),
            label: const Text('Redeem'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(child: StatCard(value: '${_summary?.balance ?? 0}', label: 'Current Balance', icon: Icons.toll_outlined)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          value: '+${_summary?.totalEarned ?? 0}',
                          label: 'Total Earned',
                          icon: Icons.trending_up,
                          accentColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          value: '-${_summary?.totalRedeemed ?? 0}',
                          label: 'Total Redeemed',
                          icon: Icons.trending_down,
                          accentColor: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', 'Earned', 'Redeemed'].map((tab) {
                        final selected = tab == _tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tab),
                            selected: selected,
                            onSelected: (_) => setState(() => _tab = tab),
                            selectedColor: AppColors.primaryLight,
                            labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    const EmptyState(
                      icon: Icons.toll_outlined,
                      message: 'No point activity yet — shop to start earning, or check Rewards.',
                    )
                  else
                    ..._filtered.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SectionCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                  child: Icon(_sourceIcon(e.source), color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.description ?? e.source, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(
                                        e.createdAt != null ? '${e.createdAt}' : '',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${e.isEarned ? '+' : '-'}${e.pointsAmount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: e.isEarned ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Showing your most recent 50 transactions.', style: TextStyle(fontSize: 11, color: AppColors.placeholder)),
                  ),
                ],
              ),
            ),
    );
  }
}
