import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/common_widgets.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await OrderService.instance.getMyOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {
      // Keep previous state.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [EmptyState(icon: Icons.receipt_long_outlined, message: 'No orders yet. Shop cards.')],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, i) {
                        final order = _orders[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.orderId))),
                            borderRadius: BorderRadius.circular(14),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w700))),
                                      StatusBadge(order.orderStatus),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...order.items.map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('${item.productName} ×${item.quantity}', style: const TextStyle(fontSize: 13)),
                                      )),
                                  const Divider(),
                                  Text('Order Total: RM ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
