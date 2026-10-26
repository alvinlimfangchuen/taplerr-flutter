import 'package:flutter/material.dart';

/// Icon/color/category per `notification_type`, ported 1:1 from
/// `helpers.php`'s `notification_icon()`/`notification_category()` so the
/// Flutter list matches the web app exactly (FontAwesome icons mapped to
/// their closest Material equivalent).
class NotificationStyle {
  final IconData icon;
  final Color color;
  final String category; // activity | contacts | orders | security

  const NotificationStyle(this.icon, this.color, this.category);
}

const Map<String, NotificationStyle> _notificationStyles = {
  'contact_request': NotificationStyle(Icons.person_add, Color(0xFF2563EB), 'contacts'),
  'contact_accepted': NotificationStyle(Icons.how_to_reg, Color(0xFF059669), 'contacts'),
  'contact_rejected': NotificationStyle(Icons.person_off, Color(0xFF6B7280), 'contacts'),
  'contact_removed': NotificationStyle(Icons.person_remove, Color(0xFF6B7280), 'contacts'),
  'mutual_connection': NotificationStyle(Icons.people_alt, Color(0xFF059669), 'contacts'),
  'profile_view': NotificationStyle(Icons.visibility, Color(0xFFA67C52), 'activity'),
  'view_milestone': NotificationStyle(Icons.emoji_events, Color(0xFFCA8A04), 'activity'),
  'card_bound': NotificationStyle(Icons.badge, Color(0xFF2563EB), 'activity'),
  'card_status_change': NotificationStyle(Icons.credit_card, Color(0xFFA67C52), 'activity'),
  'security_alert': NotificationStyle(Icons.warning_amber, Color(0xFFDC2626), 'security'),
  'password_changed': NotificationStyle(Icons.vpn_key, Color(0xFFDC2626), 'security'),
  'system_announcement': NotificationStyle(Icons.campaign, Color(0xFFA67C52), 'activity'),
  'order_paid': NotificationStyle(Icons.check_circle, Color(0xFF059669), 'orders'),
  'payment_failed': NotificationStyle(Icons.error, Color(0xFFDC2626), 'orders'),
  'order_status_change': NotificationStyle(Icons.local_shipping, Color(0xFF2563EB), 'orders'),
  'subscription_activated': NotificationStyle(Icons.layers, Color(0xFF059669), 'orders'),
  'subscription_cancelled': NotificationStyle(Icons.layers_clear, Color(0xFF6B7280), 'orders'),
};

const NotificationStyle _defaultStyle = NotificationStyle(Icons.notifications, Color(0xFFA67C52), 'activity');

NotificationStyle styleForNotificationType(String type) => _notificationStyles[type] ?? _defaultStyle;

class NotificationItem {
  final int notificationId;
  final String notificationType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationItem({
    required this.notificationId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  NotificationStyle get style => styleForNotificationType(notificationType);
  String get category => style.category;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        notificationId: notificationId,
        notificationType: notificationType,
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
      notificationType: json['notification_type']?.toString() ?? '',
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
