import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../services/shop_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  CartSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final summary = await ShopService.instance.getCart();
      if (mounted) setState(() => _summary = summary);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    if (quantity < 1 || quantity > 10) return;
    await ShopService.instance.updateQuantity(index: item.index, quantity: quantity);
    _load();
  }

  Future<void> _remove(CartItem item) async {
    await ShopService.instance.removeFromCart(item.index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _summary?.items ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [EmptyState(icon: Icons.shopping_cart_outlined, message: 'Your cart is empty. Browse cards.')],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SectionCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        color: AppColors.inputBackground,
                                        child: item.image != null
                                            ? Image.network('https://demo.taplerr.com${item.image}', fit: BoxFit.cover)
                                            : const Icon(Icons.credit_card, color: AppColors.placeholder),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('RM ${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                                onPressed: () => _updateQuantity(item, item.quantity - 1),
                                              ),
                                              Text('${item.quantity}'),
                                              IconButton(
                                                visualDensity: VisualDensity.compact,
                                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                                onPressed: () => _updateQuantity(item, item.quantity + 1),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                                      onPressed: () => _remove(item),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 10),
                        SectionCard(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('RM ${(_summary?.subtotal ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                                child: const Text('Proceed to Checkout'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
