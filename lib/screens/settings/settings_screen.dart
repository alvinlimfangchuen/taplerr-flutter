import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String _password = '';

  bool get _hasMinLength => _password.length >= 8 && _password.length <= 64;
  bool get _hasUpper => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _meetsPolicy => _hasMinLength && _hasUpper && _hasLower && _hasDigit;
  bool get _matches => _newPassword.text.isNotEmpty && _newPassword.text == _confirm.text;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() => _saving = true);
    try {
      final client = await ApiClient.instance.dio;
      final res = await client.post('/change-password', data: {
        'current_password': _current.text,
        'new_password': _newPassword.text,
        'confirm_password': _confirm.text,
      });
      final location = res.headers.value('location') ?? '';
      final success = res.statusCode == 302 && location.contains('/change-password');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Password changed.' : 'Current password incorrect or new password invalid.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        _current.clear();
        _newPassword.clear();
        _confirm.clear();
        setState(() => _password = '');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Your Account?',
      message:
          'This deactivates your account and card immediately. Your order history is kept, but this cannot be undone from here.',
      confirmLabel: 'Yes, Delete My Account',
    );
    if (!confirmed) return;

    final client = await ApiClient.instance.dio;
    await client.post('/delete-account', data: {'confirm_delete': '1'});
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Widget _policyItem(String label, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(met ? Icons.check_circle : Icons.circle_outlined, size: 14, color: met ? AppColors.success : AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: met ? AppColors.success : AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading('Change Password'),
                TextField(
                  controller: _current,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Current Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  onChanged: (v) => setState(() => _password = v),
                  decoration: const InputDecoration(hintText: 'New Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Confirm New Password'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _policyItem('8–64 characters', _hasMinLength),
                    _policyItem('Uppercase letter', _hasUpper),
                    _policyItem('Lowercase letter', _hasLower),
                    _policyItem('Number', _hasDigit),
                  ],
                ),
                if (_confirm.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _matches ? 'Passwords match' : 'Passwords do not match',
                      style: TextStyle(fontSize: 12, color: _matches ? AppColors.success : AppColors.error),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_meetsPolicy && _matches && _current.text.isNotEmpty && !_saving) ? _changePassword : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Update Password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error)),
                const SizedBox(height: 8),
                const Text(
                  'Deleting your account deactivates it immediately. This cannot be undone from here.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _deleteAccount,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  child: const Text('Delete My Account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
