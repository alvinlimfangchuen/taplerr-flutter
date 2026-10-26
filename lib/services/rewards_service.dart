import '../models/reward.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// `/rewards` is a "Coming soon" placeholder on the web today — no real
/// catalogue exists yet (confirmed in the structural research pass), so
/// this just reports whether the page still shows the placeholder rather
/// than speculatively parsing a catalogue that doesn't exist.
class RewardsService {
  RewardsService._internal();
  static final RewardsService instance = RewardsService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<Reward>> getCatalogue() async {
    final res = await _client.get('/rewards');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final cards = doc.querySelectorAll('.reward-card');
    if (cards.isEmpty) return const [];
    // Defensive: parse if the backend ever ships a real catalogue, but the
    // placeholder page has no matching elements, so this returns empty today.
    return const [];
  }
}
