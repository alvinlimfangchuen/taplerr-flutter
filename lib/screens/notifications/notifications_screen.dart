import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

const _tabs = ['All', 'Unread', 'Activity', 'Contacts', 'Orders', 'Security'];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
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
      final items = await NotificationsService.instance.getNotifications();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Keep whatever was already loaded; list just won't refresh.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NotificationItem> get _filtered {
    switch (_tab) {
      case 'Unread':
        return _items.where((n) => !n.isRead).toList();
      case 'Activity':
      case 'Contacts':
      case 'Orders':
      case 'Security':
        return _items.where((n) => n.category == _tab.toLowerCase()).toList();
      default:
        return _items;
    }
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    setState(() {
      _items = _items.map((n) => n.notificationId == item.notificationId ? n.copyWith(isRead: true) : n).toList();
    });
    await NotificationsService.instance.markRead(item.notificationId);
  }

  Future<void> _markAllRead() async {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
    await NotificationsService.instance.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: hasUnread ? _markAllRead : null,
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: _tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final tab = _tabs[i];
                        final selected = tab == _tab;
                        return ChoiceChip(
                          label: Text(tab),
                          selected: selected,
                          onSelected: (_) => setState(() => _tab = tab),
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: EmptyState(icon: Icons.notifications_none, message: 'Nothing in this category.'),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final item = _filtered[i];
                              return _NotificationTile(item: item, onTap: () => _markRead(item));
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : AppColors.primaryLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(timeAgo(item.createdAt), style: const TextStyle(color: AppColors.placeholder, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
