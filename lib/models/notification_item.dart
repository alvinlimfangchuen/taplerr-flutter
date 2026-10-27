import 'package:flutter/material.dart';

/// Material-icon equivalent per FontAwesome class, ported from
/// `helpers.php`'s `notification_icon()` map. The scraped `/notifications`
/// page already includes the server-computed `icon` (FontAwesome class)
/// and `color` (hex) per row — used directly here instead of re-guessing
/// from `notification_type`, which isn't even present on that page (only
/// the pre-computed `category` is).
const Map<String, IconData> _iconByFaClass = {
  'fa-solid fa-user-plus': Icons.person_add,
  'fa-solid fa-user-check': Icons.how_to_reg,
  'fa-solid fa-user-xmark': Icons.person_off,
  'fa-solid fa-user-minus': Icons.person_remove,
  'fa-solid fa-people-arrows': Icons.people_alt,
  'fa-solid fa-eye': Icons.visibility,
  'fa-solid fa-trophy': Icons.emoji_events,
  'fa-solid fa-id-card': Icons.badge,
  'fa-solid fa-id-card-clip': Icons.credit_card,
  'fa-solid fa-triangle-exclamation': Icons.warning_amber,
  'fa-solid fa-key': Icons.vpn_key,
  'fa-solid fa-bullhorn': Icons.campaign,
  'fa-solid fa-circle-check': Icons.check_circle,
  'fa-solid fa-circle-exclamation': Icons.error,
  'fa-solid fa-truck-fast': Icons.local_shipping,
  'fa-solid fa-layer-group': Icons.layers,
};

IconData iconForFaClass(String? faClass) => _iconByFaClass[faClass] ?? Icons.notifications;

Color parseHexColor(String? hex, {Color fallback = const Color(0xFFA67C52)}) {
  final clean = hex?.replaceFirst('#', '');
  if (clean == null || clean.length != 6) return fallback;
  final value = int.tryParse('FF$clean', radix: 16);
  return value != null ? Color(value) : fallback;
}

class NotificationItem {
  final int notificationId;
  final String category; // activity | contacts | orders | security
  final String iconClass;
  final String colorHex;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem({
    required this.notificationId,
    required this.category,
    required this.iconClass,
    required this.colorHex,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  IconData get icon => iconForFaClass(iconClass);
  Color get color => parseHexColor(colorHex);

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        notificationId: notificationId,
        category: category,
        iconClass: iconClass,
        colorHex: colorHex,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notification_id'] is int
          ? json['notification_id'] as int
          : int.tryParse('${json['notification_id'] ?? ''}') ?? 0,
      category: json['category']?.toString() ?? 'activity',
      iconClass: json['icon']?.toString() ?? '',
      colorHex: json['color']?.toString() ?? '#A67C52',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'] == '1',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// "3m ago" / "2h ago" / "5d ago", falling back to a plain date past a
/// week — mirrors helpers.php's time_ago().
String timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}
