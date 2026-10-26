import '../models/nfc_card.dart';
import '../models/profile.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

class CardActionResult {
  final bool success;
  final String? error;
  CardActionResult(this.success, [this.error]);
}

/// Card management (`/card-management`, `/bind-card`, `/relink`, `/unlink`)
/// plus public card lookups (`/card?slug=`, `/public-profile?uid=`). None of
/// these return JSON — the table and the public card page are both plain
/// server-rendered HTML, so results are scraped via the `html` DOM parser.
class CardService {
  CardService._internal();
  static final CardService instance = CardService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<NfcCard>> getBoundCards() async {
    final res = await _client.get('/card-management');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final rows = doc.querySelectorAll('table.nfc-table tbody tr');
    final cards = <NfcCard>[];
    for (final row in rows) {
      final serial = ScrapeUtils.text(row.querySelector('.nfc-serial'));
      if (serial.isEmpty) continue;
      final status = ScrapeUtils.text(row.querySelector('.badge-status'));
      cards.add(NfcCard(serialNumber: serial, cardStatus: status.isEmpty ? 'Inactive' : status));
    }
    return cards;
  }

  Future<CardActionResult> bindCard({required String serial, required String otp}) async {
    final res = await _client.post('/bind-card', data: {'serial': serial, 'otp': otp});
    final location = res.headers.value('location') ?? '';
    if (location.contains('status=success')) return CardActionResult(true);
    if (location.contains('error=invalid')) {
      return CardActionResult(false, 'Invalid serial number or OTP.');
    }
    return CardActionResult(false, 'Could not bind this card. Please try again.');
  }

  Future<CardActionResult> relink(String serial) async {
    final res = await _client.get('/relink', queryParameters: {'uid': serial});
    final location = res.headers.value('location') ?? '';
    return CardActionResult(
      location.contains('status=success'),
      location.contains('status=success') ? null : 'Could not re-enable this card.',
    );
  }

  Future<CardActionResult> unlink(String serial) async {
    final res = await _client.get('/unlink', queryParameters: {'uid': serial});
    final location = res.headers.value('location') ?? '';
    return CardActionResult(
      location.contains('status=success'),
      location.contains('status=success') ? null : 'Could not disable this card.',
    );
  }

  /// A visitor's view of someone else's card — `/card?slug=` (own-hosted
  /// profile, includes state/postcode) or `/public-profile?uid=` (NFC tap
  /// resolution). Both render the same fixed-markup template, scraped by
  /// CSS class since there is no JSON for this page (see public-profile.html
  /// research: `.identity h1`, `.identity .designation/.company`, `.bio`,
  /// `.banner img`, `.avatar img`, `.socials a`, `:root{--accent:...}`).
  Future<Profile?> getPublicCard({String? slug, String? uid}) async {
    assert(slug != null || uid != null);
    final path = slug != null ? '/card' : '/public-profile';
    final query = slug != null ? {'slug': slug} : {'uid': uid};
    final res = await _client.get(path, queryParameters: query);
    final html = res.data is String ? res.data as String : '';
    if (html.isEmpty) return null;

    final doc = ScrapeUtils.parseDocument(html);
    final name = ScrapeUtils.text(doc.querySelector('.identity h1'));
    if (name.isEmpty) return null;

    final accentMatch = RegExp(r'--accent:\s*(#[0-9a-fA-F]{6})').firstMatch(html);
    final bannerImg = doc.querySelector('.banner img')?.attributes['src'];
    final avatarImg = doc.querySelector('.avatar')?.attributes['src'];
    final bio = ScrapeUtils.text(doc.querySelector('.bio'));
    final designation = ScrapeUtils.text(doc.querySelector('.identity .designation'));
    final company = ScrapeUtils.text(doc.querySelector('.identity .company'));

    final phoneHref = doc.querySelector('.actions a.call')?.attributes['href'];
    final emailHref = doc.querySelector('.actions a.email')?.attributes['href'];
    final websiteLine = doc.querySelectorAll('.info-line').map(ScrapeUtils.text).toList();

    final socials = <SocialLink>[];
    for (final a in doc.querySelectorAll('.socials a')) {
      final href = a.attributes['href'];
      final onclick = a.attributes['onclick'] ?? '';
      final platformMatch = RegExp(r"trackClick\('(\w+)'\)").firstMatch(onclick);
      if (href != null && platformMatch != null) {
        socials.add(SocialLink(platform: platformMatch.group(1)!, link: href));
      }
    }

    final isCompact = doc.querySelector('.compact-footer') != null;

    return Profile(
      fullName: name,
      designation: designation,
      company: company,
      bio: bio,
      profilePicture: avatarImg,
      bannerImage: bannerImg,
      phone: phoneHref?.replaceFirst('tel:', '') ?? '',
      email: emailHref?.replaceFirst('mailto:', '') ?? '',
      website: websiteLine.firstWhere((l) => l.contains('.'), orElse: () => ''),
      socialLinks: socials,
      themeColor: accentMatch?.group(1) ?? '#A67C52',
      cardLayout: isCompact ? 'compact' : 'classic',
      showPhone: phoneHref != null,
      showEmail: emailHref != null,
      showSocial: socials.isNotEmpty,
      profileSlug: slug,
      shareValue: uid,
    );
  }

  /// Fire-and-forget link-tap analytics, mirrors the public card's
  /// `trackClick()` JS helper.
  Future<void> trackClick({required int profileId, required String field}) async {
    try {
      await _client.post('/track-click', data: {'profile_id': profileId, 'field': field});
    } catch (_) {
      // Analytics only — never block the UI action (tel:/mailto:/url_launcher) on this.
    }
  }

  Future<CardActionResult> addContact({String? uid, String? slug}) async {
    final res = await _client.post('/add-contact', data: {
      if (uid != null) 'uid': uid,
      if (slug != null) 'slug': slug,
    });
    final location = res.headers.value('location') ?? '';
    if (location.contains('/login')) {
      return CardActionResult(false, 'Please sign in to connect.');
    }
    return CardActionResult(true);
  }
}
