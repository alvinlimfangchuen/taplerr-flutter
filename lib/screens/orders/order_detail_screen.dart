import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await OrderService.instance.getOrderDetail(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyState(icon: Icons.receipt_long_outlined, message: 'Could not load this order.'),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('#${order.orderNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                              StatusBadge(order.orderStatus),
                            ],
                          ),
                          if (order.paymentMethod != null) ...[
                            const SizedBox(height: 8),
                            Text('Payment Method: ${order.paymentMethod}', style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeading('Items'),
                          ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('${item.productName} ×${item.quantity}')),
                                    Text('RM ${item.itemPrice.toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('RM ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (order.shippingName != null) ...[
                      const SizedBox(height: 16),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeading('Shipping To'),
                            Text(order.shippingName!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
