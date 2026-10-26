import 'package:flutter/material.dart';
import '../../models/nfc_card.dart';
import '../../services/card_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CardManagementScreen extends StatefulWidget {
  const CardManagementScreen({super.key});

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  final _serialController = TextEditingController();
  final _otpController = TextEditingController();

  List<NfcCard> _cards = [];
  bool _loading = true;
  bool _binding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serialController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cards = await CardService.instance.getBoundCards();
      if (mounted) setState(() => _cards = cards);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your cards. Pull to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bindCard() async {
    if (_serialController.text.trim().isEmpty || _otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both the serial number and OTP.')),
      );
      return;
    }
    setState(() => _binding = true);
    final result = await CardService.instance.bindCard(
      serial: _serialController.text.trim(),
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _binding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'Card bound successfully.' : (result.error ?? 'Could not bind card.')),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
    if (result.success) {
      _serialController.clear();
      _otpController.clear();
      _load();
    }
  }

  Future<void> _toggleCard(NfcCard card) async {
    final enabling = card.cardStatus != 'Active';
    final confirmed = await showConfirmDialog(
      context,
      title: enabling ? 'Enable Card' : 'Disable Card',
      message: enabling
          ? 'Reactivate card ${card.serialNumber}? It will start working again immediately.'
          : 'Disable card ${card.serialNumber}? It will stop resolving until re-enabled.',
      confirmLabel: enabling ? 'Enable' : 'Disable',
      confirmColor: enabling ? AppColors.success : AppColors.error,
    );
    if (!confirmed) return;

    final result = enabling
        ? await CardService.instance.relink(card.serialNumber)
        : await CardService.instance.unlink(card.serialNumber);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Card ${enabling ? 'enabled' : 'disabled'}.'
            : (result.error ?? 'Action failed.')),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
    if (result.success) _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading('Pair New NFC Card'),
                const Text('Serial Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _serialController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'e.g. TEST-P8W4WR'),
                ),
                const SizedBox(height: 16),
                const Text('OTP Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(hintText: 'Enter OTP'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _binding ? null : _bindCard,
                  child: _binding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.link, size: 18), SizedBox(width: 8), Text('Activate Card')],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeading('My NFC Cards'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            FlashBanner(message: _error!, isError: true)
          else if (_cards.isEmpty)
            const EmptyState(icon: Icons.credit_card_off_outlined, message: 'No NFC cards paired yet.')
          else
            ..._cards.map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.credit_card, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.serialNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              StatusBadge(card.cardStatus),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _toggleCard(card),
                          style: TextButton.styleFrom(
                            foregroundColor: card.cardStatus == 'Active' ? AppColors.error : AppColors.success,
                          ),
                          child: Text(card.cardStatus == 'Active' ? 'Disable' : 'Enable'),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
