import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postcode = TextEditingController();
  final _promoCode = TextEditingController();
  String _paymentMethod = 'card';

  double _subtotal = 0;
  double _discount = 0;
  final double _shippingFee = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _applyingPromo = false;

  double get _total => (_subtotal - _discount + _shippingFee).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _address, _city, _state, _postcode, _promoCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cart = await ShopService.instance.getCart();
      if (mounted) setState(() => _subtotal = cart.subtotal);
    } catch (_) {
      // Keep defaults.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyPromo() async {
    if (_promoCode.text.trim().isEmpty) return;
    setState(() => _applyingPromo = true);
    final result = await OrderService.instance.applyPromo(_promoCode.text.trim());
    if (!mounted) return;
    setState(() => _applyingPromo = false);
    if (result['ok'] == true) {
      setState(() => _discount = (result['discount'] as num?)?.toDouble() ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo applied.'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Invalid promo code.'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _state.text.trim().isEmpty ||
        !RegExp(r'^\d{5}$').hasMatch(_postcode.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields — postcode must be 5 digits.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final csrf = await ApiClient.instance.fetchCsrfToken('/checkout');
      final url = await OrderService.instance.submitCheckout(
        name: _name.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        postcode: _postcode.text.trim(),
        paymentMethod: _paymentMethod,
        csrfToken: csrf ?? '',
      );
      if (!mounted) return;
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start checkout. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeading('Shipping Details'),
                      TextField(controller: _name, decoration: const InputDecoration(hintText: 'Full Name')),
                      const SizedBox(height: 12),
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
                      const SizedBox(height: 12),
                      TextField(controller: _address, decoration: const InputDecoration(hintText: 'Address')),
                      const SizedBox(height: 12),
                      TextField(controller: _city, decoration: const InputDecoration(hintText: 'City')),
                      const SizedBox(height: 12),
                      TextField(controller: _state, decoration: const InputDecoration(hintText: 'State')),
                      const SizedBox(height: 12),
                      TextField(controller: _postcode, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Postcode')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _paymentMethod,
                        items: const [
                          DropdownMenuItem(value: 'card', child: Text('Credit/Debit Card')),
                          DropdownMenuItem(value: 'fpx', child: Text('Online Banking (FPX)')),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v ?? 'card'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeading('Order Summary'),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _promoCode, decoration: const InputDecoration(hintText: 'Promo code'))),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _applyingPromo ? null : _applyPromo,
                            child: _applyingPromo
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Apply'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _row('Subtotal', _subtotal),
                      if (_discount > 0) _row('Discount', -_discount),
                      _row('Shipping', _shippingFee),
                      const Divider(),
                      _row('Total', _total, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Proceed to Payment'),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text('RM ${value.toStringAsFixed(2)}', style: style)],
      ),
    );
  }
}
