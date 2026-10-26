import '../models/points_entry.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// `/points` embeds `const ALL_TRANSACTIONS = [...]` with keys `type`
/// (not `transaction_type`), `source`, `amount` (not `points_amount`),
/// `description`, `reference_id`, `created_at` — remapped to the model's
/// field names here. Balance/earned/redeemed are plain `.stat-value` text.
class PointsService {
  PointsService._internal();
  static final PointsService instance = PointsService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<PointsSummary> getPoints() async {
    final res = await _client.get('/points');
    final html = res.data is String ? res.data as String : '';

    int statValue(String label) {
      final match = RegExp(
        '<div class="stat-value">([+-]?[\\d,]+)</div>\\s*<div class="stat-label">${RegExp.escape(label)}</div>',
      ).firstMatch(html);
      final raw = match?.group(1)?.replaceAll(',', '').replaceAll('+', '');
      return raw == null ? 0 : int.tryParse(raw) ?? 0;
    }

    final raw = ScrapeUtils.extractJsLiteral(html, 'ALL_TRANSACTIONS');
    final history = <PointsEntry>[];
    if (raw is List) {
      for (final row in raw.whereType<Map<String, dynamic>>()) {
        history.add(PointsEntry.fromJson({
          'transaction_type': row['type'],
          'source': row['source'],
          'points_amount': row['amount'],
          'reference_id': row['reference_id'],
          'description': row['description'],
          'created_at': row['created_at'],
        }));
      }
    }

    return PointsSummary(
      balance: statValue('Current Balance'),
      totalEarned: statValue('Total Earned').abs(),
      totalRedeemed: statValue('Total Redeemed').abs(),
      history: history,
    );
  }
}
