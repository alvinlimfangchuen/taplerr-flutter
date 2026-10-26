import '../models/profile.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// `/profile` is a server-rendered edit form, not a JSON endpoint — the
/// current values live in each field's `value="..."` attribute. See
/// CardController::edit() (`CardController.php:12-106`) for the field list.
class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<Profile> getProfile() async {
    final res = await _client.get('/profile');
    final html = res.data is String ? res.data as String : '';
    String v(String field) => ScrapeUtils.extractInputValue(html, field);

    final socials = <SocialLink>[];
    for (final platform in ['facebook', 'instagram', 'linkedin', 'whatsapp']) {
      final link = v('social_$platform');
      if (link.isNotEmpty) socials.add(SocialLink(platform: platform, link: link));
    }

    bool checkboxPresent(String name) {
      // Rendered checkboxes carry `checked` with no value attribute when on.
      return RegExp(
        'name=["\']${RegExp.escape(name)}["\'][^>]*checked',
      ).hasMatch(html);
    }

    return Profile(
      fullName: v('full_name'),
      preferredName: v('preferred_name'),
      designation: v('designation'),
      company: v('company'),
      bio: _extractTextareaValue(html, 'bio'),
      phone: v('phone'),
      email: v('email'),
      website: v('website'),
      address1: v('address1'),
      city: v('city'),
      state: v('state'),
      postcode: v('postcode'),
      socialLinks: socials,
      themeColor: ScrapeUtils.extractCheckedRadioValue(html, 'theme_color') ?? '#A67C52',
      cardLayout: ScrapeUtils.extractCheckedRadioValue(html, 'card_layout') ?? 'classic',
      showPhone: checkboxPresent('show_phone'),
      showEmail: checkboxPresent('show_email'),
      showSocial: checkboxPresent('show_social'),
      showAddress: checkboxPresent('show_address'),
      shareValue: _extractCardHash(html),
    );
  }

  String? _extractCardHash(String html) {
    final match = RegExp(r'uid=([0-9a-f]{20,})').firstMatch(html);
    return match?.group(1);
  }

  String _extractTextareaValue(String html, String name) {
    final match = RegExp(
      'name=["\']${RegExp.escape(name)}["\'][^>]*>([\\s\\S]*?)</textarea>',
    ).firstMatch(html);
    return match?.group(1)?.trim() ?? '';
  }

  Future<bool> updateProfile(Map<String, String> fields) async {
    final data = <String, dynamic>{...fields};
    // Checkbox fields are only sent when "on" — mirrors a real HTML form.
    for (final key in ['show_phone', 'show_email', 'show_social', 'show_address']) {
      if (data[key] == '1') {
        data[key] = 'on';
      } else {
        data.remove(key);
      }
    }
    return _client.postExpectRedirectAwayFrom('/profile', data, awayFrom: '/login');
  }

  Future<bool> toggleVisibility({required String field, required bool value}) async {
    final res = await _client.post(
      '/profile/toggle-visibility',
      data: {'field': field, 'value': value ? '1' : ''},
    );
    return res.data is Map && res.data['success'] == true;
  }

  Future<bool> updateThemeColor(String hexColor) async {
    final res = await _client.post('/profile/update-theme-color', data: {'theme_color': hexColor});
    return res.data is Map && res.data['success'] == true;
  }

  Future<bool> updateCardLayout(String layout) async {
    final res = await _client.post('/profile/update-card-layout', data: {'card_layout': layout});
    return res.data is Map && res.data['success'] == true;
  }

  /// [croppedImageDataUrl] is a `data:image/...;base64,...` string produced
  /// by flattening the pan/zoom crop step client-side.
  Future<String?> uploadProfilePicture(String croppedImageDataUrl) async {
    final res = await _client.post(
      '/upload-profile-picture',
      data: {'croppedImageData': croppedImageDataUrl},
    );
    if (res.data is Map && res.data['success'] == true) {
      return res.data['path']?.toString();
    }
    return null;
  }

  Future<String?> uploadBannerPicture(String croppedImageDataUrl) async {
    final res = await _client.post(
      '/upload-banner-picture',
      data: {'croppedImageData': croppedImageDataUrl},
    );
    if (res.data is Map && res.data['success'] == true) {
      return res.data['path']?.toString();
    }
    return null;
  }

  Future<bool> removeBannerPicture() async {
    final res = await _client.post('/remove-banner-picture');
    return res.data is Map && res.data['success'] == true;
  }
}
