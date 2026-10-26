import 'package:flutter/material.dart';
import '../models/nfc_card.dart';
import '../services/card_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';
import 'card/card_management_screen.dart';
import 'contacts/contacts_screen.dart';
import 'analytics/analytics_screen.dart';
import 'subscription/subscription_screen.dart';

/// The web app's `/dashboard` is a marketing landing page (hero slider,
/// product carousel, FAQ, contact form, footer) that renders identically
/// for guest and logged-in users — `AccountController.php` confirms the
/// product/promo data is hardcoded empty today. None of that adds value
/// inside an already-authenticated mobile app, so this is a slim
/// functional home instead: quick links into the features that matter.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<NfcCard> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await CardService.instance.getBoundCards();
      if (mounted) setState(() => _cards = cards);
    } catch (_) {
      // Non-critical for the dashboard — the Cards tab shows full detail/errors.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCards = _cards.where((c) => c.cardStatus == 'Active').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(Icons.waving_hand_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        'Here’s a snapshot of your Taplerr account.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_loading)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: '$activeCards',
                    label: 'Active cards',
                    icon: Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    value: '${_cards.length}',
                    label: 'Total cards',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          const SectionHeading('Quick actions'),
          _QuickAction(
            icon: Icons.credit_card_outlined,
            title: 'Manage NFC cards',
            subtitle: 'Bind, enable, or disable your Taplerr cards',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CardManagementScreen()),
            ),
          ),
          _QuickAction(
            icon: Icons.contacts_outlined,
            title: 'Contacts',
            subtitle: 'See who has connected with you',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            ),
          ),
          _QuickAction(
            icon: Icons.bar_chart_outlined,
            title: 'Analytics',
            subtitle: 'Track profile views and engagement',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
          _QuickAction(
            icon: Icons.layers_outlined,
            title: 'Subscription',
            subtitle: 'Compare plans and manage billing',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SectionCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
