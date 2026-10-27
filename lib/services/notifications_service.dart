import '../models/notification_item.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// `/notifications` embeds `const ALL_NOTIFICATIONS = [...]` with the exact
/// json_encode() shape (verified via a live authenticated fetch): `id`
/// (not `notification_id` on this page — the server names it differently
/// here than in `/notifications/mark-read`'s matching field), `category`
/// already computed server-side, `icon`/`color` from helpers.php's
/// notification_icon(), `is_read` as a real bool, `created_at`.
class NotificationsService {
  NotificationsService._internal();
  static final NotificationsService instance = NotificationsService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<NotificationItem>> getNotifications() async {
    final html = await _client.getAuthedHtml('/notifications');
    final raw = ScrapeUtils.extractJsLiteral(html, 'ALL_NOTIFICATIONS');
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((row) {
      return NotificationItem.fromJson({
        'notification_id': row['id'],
        'category': row['category'],
        'icon': row['icon'],
        'color': row['color'],
        'title': row['title'],
        'message': row['message'],
        'is_read': row['is_read'],
        'created_at': row['created_at'],
      });
    }).toList();
  }

  Future<bool> markRead(int notificationId) async {
    final csrf = await _client.fetchCsrfToken('/notifications');
    if (csrf == null) return false;
    final res = await _client.post('/notifications/mark-read', data: {
      'notification_id': notificationId,
      'csrf_token': csrf,
    });
    return res.data is Map && res.data['ok'] == true;
  }

  Future<void> markAllRead() async {
    final csrf = await _client.fetchCsrfToken('/notifications');
    if (csrf == null) return;
    await _client.post('/notifications/mark-all-read', data: {'csrf_token': csrf});
  }
}
