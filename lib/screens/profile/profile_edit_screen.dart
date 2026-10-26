import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../card/public_card_screen.dart';
import '../login_screen.dart';
import '../settings/settings_screen.dart';
import '../points/points_screen.dart';
import '../rewards/rewards_screen.dart';
import '../subscription/billing_screen.dart';
import '../shop/products_screen.dart';
import '../orders/my_orders_screen.dart';
import 'widgets/image_crop_modal.dart';

const _presetColors = ['#A67C52', '#0F2027', '#2563eb', '#059669', '#dc2626'];

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);
  final _picker = ImagePicker();

  Profile? _profile;
  bool _loading = true;
  bool _saving = false;

  final _fullName = TextEditingController();
  final _preferredName = TextEditingController();
  final _designation = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _linkedin = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _whatsapp = TextEditingController();
  final _bio = TextEditingController();
  final _address1 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postcode = TextEditingController();

  bool _showPhone = true;
  bool _showEmail = true;
  bool _showSocial = true;
  bool _showAddress = false;
  String _themeColor = '#A67C52';
  String _cardLayout = 'classic';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _fullName, _preferredName, _designation, _company, _email, _phone, _website,
      _linkedin, _facebook, _instagram, _whatsapp, _bio, _address1, _city, _state, _postcode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await ProfileService.instance.getProfile();
      _profile = profile;
      _fullName.text = profile.fullName;
      _preferredName.text = profile.preferredName;
      _designation.text = profile.designation;
      _company.text = profile.company;
      _email.text = profile.email;
      _phone.text = profile.phone;
      _website.text = profile.website;
      _bio.text = profile.bio;
      _address1.text = profile.address1;
      _city.text = profile.city;
      _state.text = profile.state ?? '';
      _postcode.text = profile.postcode ?? '';
      for (final link in profile.socialLinks) {
        switch (link.platform) {
          case 'linkedin':
            _linkedin.text = link.link;
            break;
          case 'facebook':
            _facebook.text = link.link;
            break;
          case 'instagram':
            _instagram.text = link.link;
            break;
          case 'whatsapp':
            _whatsapp.text = link.link;
            break;
        }
      }
      _showPhone = profile.showPhone;
      _showEmail = profile.showEmail;
      _showSocial = profile.showSocial;
      _showAddress = profile.showAddress;
      _themeColor = profile.themeColor;
      _cardLayout = profile.cardLayout;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your profile.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ProfileService.instance.updateProfile({
      'full_name': _fullName.text.trim(),
      'preferred_name': _preferredName.text.trim(),
      'designation': _designation.text.trim(),
      'company': _company.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'website': _website.text.trim(),
      'social_linkedin': _linkedin.text.trim(),
      'social_facebook': _facebook.text.trim(),
      'social_instagram': _instagram.text.trim(),
      'social_whatsapp': _whatsapp.text.trim(),
      'bio': _bio.text.trim(),
      'address1': _address1.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'postcode': _postcode.text.trim(),
      'show_phone': _showPhone ? '1' : '',
      'show_email': _showEmail ? '1' : '',
      'show_social': _showSocial ? '1' : '',
      'show_address': _showAddress ? '1' : '',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Profile saved.' : 'Could not save your profile.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _pickAndCropPhoto({required bool isAvatar}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !mounted) return;
    final dataUrl = await showImageCropModal(context, imageFile: File(picked.path), isCircle: isAvatar);
    if (dataUrl == null) return;
    final path = isAvatar
        ? await ProfileService.instance.uploadProfilePicture(dataUrl)
        : await ProfileService.instance.uploadBannerPicture(dataUrl);
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated.'), backgroundColor: AppColors.success),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _setThemeColor(String hex) async {
    setState(() => _themeColor = hex);
    await ProfileService.instance.updateThemeColor(hex);
  }

  Future<void> _setCardLayout(String layout) async {
    setState(() => _cardLayout = layout);
    await ProfileService.instance.updateCardLayout(layout);
  }

  Future<void> _toggle(String field, bool value, void Function(bool) apply) async {
    setState(() => apply(value));
    await ProfileService.instance.toggleVisibility(field: field, value: value);
  }

  void _showQrModal() {
    final uid = _profile?.shareValue;
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share NFC Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network('https://demo.taplerr.com/nfc-qr-download?uid=$uid', width: 220, height: 220),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PublicCardScreen.fromProfile(_profile)));
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Profile'),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverToBoxAdapter(child: _buildPhotoSection()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Contact'),
                  Tab(text: 'Socials'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            _buildContactTab(),
            _buildSocialsTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final profile = _profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: _parseColor(_themeColor),
                    child: profile?.bannerImage != null
                        ? Image.network(_resolveUrl(profile!.bannerImage!), fit: BoxFit.cover)
                        : null,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _circleButton(Icons.camera_alt, () => _pickAndCropPhoto(isAvatar: false)),
                ),
                Positioned(
                  left: 20,
                  bottom: -36,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: Colors.grey[200]),
                        child: ClipOval(
                          child: profile?.profilePicture != null
                              ? Image.network(_resolveUrl(profile!.profilePicture!), fit: BoxFit.cover)
                              : const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _circleButton(Icons.camera_alt, () => _pickAndCropPhoto(isAvatar: true), small: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {bool small = false}) {
    final size = small ? 28.0 : 34.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: small ? 14 : 16),
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Full Name', _fullName),
        _field('Preferred / Display Name', _preferredName),
        _field('Designation', _designation, hint: 'e.g. Software Engineer'),
        _field('Company Name', _company),
        const SizedBox(height: 16),
        const SectionHeading('Appearance'),
        const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          children: _presetColors.map((hex) {
            final selected = hex.toLowerCase() == _themeColor.toLowerCase();
            return GestureDetector(
              onTap: () => _setThemeColor(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(hex),
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('Public Card Layout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _layoutOption('classic', 'Classic', 'Action buttons, section labels')),
            const SizedBox(width: 12),
            Expanded(child: _layoutOption('compact', 'Compact', 'Minimal icon lines, no labels')),
          ],
        ),
        const SizedBox(height: 24),
        if (_profile?.shareValue != null)
          OutlinedButton.icon(
            onPressed: _showQrModal,
            icon: const Icon(Icons.qr_code),
            label: const Text('Share NFC Card'),
          ),
        const SizedBox(height: 24),
        _saveButton(),
        const SizedBox(height: 24),
        const Divider(),
        _moreList(),
      ],
    );
  }

  Widget _layoutOption(String value, String title, String subtitle) {
    final selected = _cardLayout == value;
    return GestureDetector(
      onTap: () => _setCardLayout(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.primary : AppColors.inputBorder, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('Email', _email, keyboardType: TextInputType.emailAddress),
        _field('Phone', _phone, keyboardType: TextInputType.phone),
        _field('Website', _website, hint: 'https://'),
        const SizedBox(height: 8),
        _toggleRow('Show phone on public card', _showPhone, (v) => _toggle('show_phone', v, (val) => _showPhone = val)),
        _toggleRow('Show email on public card', _showEmail, (v) => _toggle('show_email', v, (val) => _showEmail = val)),
        const SizedBox(height: 24),
        _saveButton(),
      ],
    );
  }

  Widget _buildSocialsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('LinkedIn', _linkedin, hint: 'https://linkedin.com/in/...'),
        _field('Facebook', _facebook, hint: 'https://facebook.com/...'),
        _field('Instagram', _instagram, hint: 'https://instagram.com/...'),
        _field('WhatsApp', _whatsapp, hint: 'wa.me/60...'),
        const SizedBox(height: 8),
        _toggleRow('Show social links on public card', _showSocial, (v) => _toggle('show_social', v, (val) => _showSocial = val)),
        const SizedBox(height: 24),
        _saveButton(),
      ],
    );
  }

  Widget _buildAboutTab() {
    final wordCount = _bio.text.trim().isEmpty ? 0 : _bio.text.trim().split(RegExp(r'\s+')).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Bio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _bio,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Tell people a bit about yourself'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('$wordCount / 200 words', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 20),
        const SectionHeading('Mailing Address'),
        _field('Address', _address1),
        _field('City', _city),
        _field('State', _state),
        _field('Postcode', _postcode, keyboardType: TextInputType.number),
        _toggleRow('Show address on public card', _showAddress, (v) => _toggle('show_address', v, (val) => _showAddress = val)),
        const SizedBox(height: 24),
        _saveButton(),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: _saving ? null : _save,
      child: _saving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
            )
          : const Text('Save Profile'),
    );
  }

  Widget _moreList() {
    Widget tile(IconData icon, String label, VoidCallback onTap) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
    }

    return Column(
      children: [
        tile(Icons.storefront_outlined, 'Shop', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
        tile(Icons.receipt_long_outlined, 'My Orders', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()))),
        tile(Icons.layers_outlined, 'Subscription & Billing', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()))),
        tile(Icons.toll_outlined, 'My Points', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()))),
        tile(Icons.card_giftcard_outlined, 'Rewards', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()))),
        tile(Icons.settings_outlined, 'Settings', () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Logout', style: TextStyle(color: AppColors.error)),
          onTap: _logout,
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length != 6) return AppColors.primary;
    return Color(int.parse('FF$clean', radix: 16));
  }

  String _resolveUrl(String path) => path.startsWith('http') ? path : 'https://demo.taplerr.com$path';
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
