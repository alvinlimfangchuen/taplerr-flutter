import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import 'cart_screen.dart';

class CustomizeBasicScreen extends StatefulWidget {
  final Product product;
  const CustomizeBasicScreen({super.key, required this.product});

  @override
  State<CustomizeBasicScreen> createState() => _CustomizeBasicScreenState();
}

class _CustomizeBasicScreenState extends State<CustomizeBasicScreen> {
  bool _addName = false;
  bool _addPosition = false;
  bool _addLevel = false;
  final _name = TextEditingController();
  final _position = TextEditingController();
  final _level = TextEditingController();
  bool _submitting = false;

  double get _total {
    var total = widget.product.price;
    if (_addName) total += ShopService.basicAddonPrices['name']!;
    if (_addPosition) total += ShopService.basicAddonPrices['position']!;
    if (_addLevel) total += ShopService.basicAddonPrices['level']!;
    return total;
  }

  Future<void> _submit() async {
    if ((_addName && _name.text.trim().isEmpty) ||
        (_addPosition && _position.text.trim().isEmpty) ||
        (_addLevel && _level.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in the text for every addon you checked.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await ShopService.instance.addBasicCustomization(
      productId: widget.product.productId,
      name: _addName ? _name.text.trim() : null,
      position: _addPosition ? _position.text.trim() : null,
      level: _addLevel ? _level.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add to cart.'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _addonRow(String label, double price, bool value, ValueChanged<bool> onChanged, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: value,
          activeColor: AppColors.primary,
          onChanged: (v) => onChanged(v ?? false),
          title: Text('$label (+RM${price.toStringAsFixed(2)})'),
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(controller: controller, decoration: InputDecoration(hintText: 'Enter $label')),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Standard Personalization')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _addonRow('Name', ShopService.basicAddonPrices['name']!, _addName, (v) => setState(() => _addName = v), _name),
          _addonRow('Position', ShopService.basicAddonPrices['position']!, _addPosition, (v) => setState(() => _addPosition = v), _position),
          _addonRow('Member Level', ShopService.basicAddonPrices['level']!, _addLevel, (v) => setState(() => _addLevel = v), _level),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('RM ${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}
