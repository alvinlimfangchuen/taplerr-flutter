/// A social link entry, e.g. {platform: 'facebook', link: 'https://...'}.
class SocialLink {
  final String platform;
  final String link;

  SocialLink({required this.platform, required this.link});

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      platform: json['platform']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }
}

/// Unified profile model covering both the owner's full `/profile` row and
/// the smaller public shapes returned by `/card` (slug) and
/// `/public-profile` (uid) — see flutter-documentation research: the uid
/// variant omits `state`/`postcode` and fills in defaults the slug variant
/// wouldn't need to.
class Profile {
  final int? profileId;
  final String fullName;
  final String preferredName;
  final String designation;
  final String bio;
  final String? profilePicture;
  final String? bannerImage;
  final String phone;
  final String email;
  final String company;
  final String website;
  final String address1;
  final String city;
  final String? state;
  final String? postcode;
  final List<SocialLink> socialLinks;
  final String themeColor;
  final String cardLayout; // 'classic' | 'compact'
  final bool showPhone;
  final bool showEmail;
  final bool showSocial;
  final bool showAddress;
  final String? profileSlug;
  final String? shareValue; // card_hash when accessed via /public-profile

  Profile({
    this.profileId,
    this.fullName = '',
    this.preferredName = '',
    this.designation = '',
    this.bio = '',
    this.profilePicture,
    this.bannerImage,
    this.phone = '',
    this.email = '',
    this.company = '',
    this.website = '',
    this.address1 = '',
    this.city = '',
    this.state,
    this.postcode,
    this.socialLinks = const [],
    this.themeColor = '#A67C52',
    this.cardLayout = 'classic',
    this.showPhone = true,
    this.showEmail = true,
    this.showSocial = true,
    this.showAddress = false,
    this.profileSlug,
    this.shareValue,
  });

  String get displayName => preferredName.isNotEmpty ? preferredName : fullName;

  factory Profile.fromJson(Map<String, dynamic> json) {
    List<SocialLink> links = const [];
    final rawLinks = json['social_links'];
    if (rawLinks is List) {
      links = rawLinks
          .whereType<Map<String, dynamic>>()
          .map(SocialLink.fromJson)
          .toList();
    }
    bool asBool(dynamic v) => v == true || v == 1 || v == '1';
    return Profile(
      profileId: json['profile_id'] is int
          ? json['profile_id'] as int
          : int.tryParse('${json['profile_id'] ?? ''}'),
      fullName: json['full_name']?.toString() ?? '',
      preferredName: json['preferred_name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      bannerImage: json['banner_image']?.toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      address1: json['address1']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString(),
      postcode: json['postcode']?.toString(),
      socialLinks: links,
      themeColor: json['theme_color']?.toString() ?? '#A67C52',
      cardLayout: json['card_layout']?.toString() ?? 'classic',
      showPhone: json.containsKey('show_phone') ? asBool(json['show_phone']) : true,
      showEmail: json.containsKey('show_email') ? asBool(json['show_email']) : true,
      showSocial: json.containsKey('show_social') ? asBool(json['show_social']) : true,
      showAddress: asBool(json['show_address']),
      profileSlug: json['profile_slug']?.toString() ?? json['slug']?.toString(),
      shareValue: json['share_value']?.toString(),
    );
  }
}
