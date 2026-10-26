import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/card/card_management_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../services/notifications_service.dart';
import '../theme/app_colors.dart';

/// The persistent post-login shell: bottom nav with the 5 primary
/// destinations (Dashboard/My Cards/Contacts/Analytics/Profile) plus a
/// notification bell in the app bar. Notifications/Points/Rewards/
/// Billing/Settings are reached from Profile's "more" list rather than
/// taking bottom-nav slots — see the plan's confirmed nav decision.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  static const _titles = ['Taplerr', 'My Cards', 'Contacts', 'Analytics', 'Profile'];

  static const _screens = [
    DashboardScreen(),
    CardManagementScreen(),
    ContactsScreen(),
    AnalyticsScreen(),
    ProfileEditScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: const [_NotificationBellButton()],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), activeIcon: Icon(Icons.credit_card), label: 'Cards'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts_outlined), activeIcon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _NotificationBellButton extends StatefulWidget {
  const _NotificationBellButton();

  @override
  State<_NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationsService.instance.getNotifications();
      if (mounted) setState(() => _unread = items.where((n) => !n.isRead).length);
    } catch (_) {
      // Non-critical — badge just stays at 0 if this fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            _load();
          },
        ),
        if (_unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_unread',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

/// Re-export for convenience so notification styling stays in one place.
typedef NotificationStyleRef = NotificationStyle;
