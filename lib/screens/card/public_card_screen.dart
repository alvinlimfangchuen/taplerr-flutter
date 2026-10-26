import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/profile.dart';
import '../../services/card_service.dart';
import '../../theme/app_colors.dart';

/// Renders a Taplerr digital card — classic or compact layout — from a
/// [Profile]. Used both for the owner's own live preview (profile already
/// in hand, no network call) and for visiting someone else's public card
/// (fetched via slug/uid, see loader constructor below).
class PublicCardScreen extends StatefulWidget {
  final Profile? profile;
  final String? slug;
  final String? uid;
  final int? profileId;

  const PublicCardScreen.fromProfile(this.profile, {super.key})
      : slug = null,
        uid = null,
        profileId = null;

  const PublicCardScreen.visit({super.key, this.slug, this.uid})
      : profile = null,
        profileId = null;

  @override
  State<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends State<PublicCardScreen> {
  Profile? _profile;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    if (_profile == null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await CardService.instance.getPublicCard(slug: widget.slug, uid: widget.uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _error = profile == null ? 'This card could not be found.' : null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load this card.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _track(String field) {
    return CardService.instance.trackClick(profileId: widget.profileId ?? 0, field: field);
  }

  Future<void> _connect() async {
    final result = await CardService.instance.addContact(uid: widget.uid, slug: widget.slug);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Connection request sent.' : (result.error ?? 'Could not connect.')),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Card')),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    final profile = _profile!;
    final accent = _parseColor(profile.themeColor);
    final isCompact = profile.cardLayout == 'compact';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: widget.profile == null ? AppBar(title: const Text('Card')) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      color: accent,
                      child: profile.bannerImage != null
                          ? Image.network(_resolveUrl(profile.bannerImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    Transform.translate(
                      offset: const Offset(0, -55),
                      child: Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: profile.profilePicture != null
                                  ? Image.network(_resolveUrl(profile.profilePicture!), fit: BoxFit.cover)
                                  : const Icon(Icons.person, size: 48, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.displayName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          if (profile.designation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(profile.designation, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          if (profile.company.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(profile.company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ),
                          if (profile.bio.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Text(
                                profile.bio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, height: 1.5),
                              ),
                            ),
                          const SizedBox(height: 8),
                          if (profile.showPhone && profile.phone.isNotEmpty || profile.showEmail && profile.email.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  if (profile.showPhone && profile.phone.isNotEmpty)
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.call,
                                        label: 'Call',
                                        color: accent,
                                        filled: true,
                                        onTap: () {
                                          _track('phone');
                                          launchUrl(Uri.parse('tel:${profile.phone}'));
                                        },
                                      ),
                                    ),
                                  if (profile.showPhone && profile.phone.isNotEmpty && profile.showEmail && profile.email.isNotEmpty)
                                    const SizedBox(width: 10),
                                  if (profile.showEmail && profile.email.isNotEmpty)
                                    Expanded(
                                      child: _ActionButton(
                                        icon: Icons.email_outlined,
                                        label: 'Email',
                                        color: Colors.black87,
                                        filled: false,
                                        onTap: () {
                                          _track('email');
                                          launchUrl(Uri.parse('mailto:${profile.email}'));
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (!isCompact && profile.website.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DETAILS', style: TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.placeholder)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      _track('website');
                                      launchUrl(Uri.parse(profile.website), mode: LaunchMode.externalApplication);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.link, size: 16, color: accent),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(profile.website, style: const TextStyle(fontSize: 14))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (profile.showSocial && profile.socialLinks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                children: profile.socialLinks.map((s) {
                                  return InkWell(
                                    onTap: () {
                                      _track(s.platform);
                                      launchUrl(Uri.parse(s.link), mode: LaunchMode.externalApplication);
                                    },
                                    borderRadius: BorderRadius.circular(21),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
                                      child: Icon(_socialIcon(s.platform), color: accent, size: 18),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Column(
                              children: [
                                if (widget.profile == null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _connect,
                                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                                      label: const Text('Connect Now'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const Text('Powered by Taplerr', style: TextStyle(color: AppColors.placeholder, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return AppColors.primary;
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _resolveUrl(String path) => path.startsWith('http') ? path : 'https://demo.taplerr.com$path';

  IconData _socialIcon(String platform) {
    switch (platform) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'linkedin':
        return Icons.business_center_outlined;
      case 'whatsapp':
        return Icons.chat_outlined;
      default:
        return Icons.link;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: filled ? Colors.white : Colors.black87),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: filled ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
