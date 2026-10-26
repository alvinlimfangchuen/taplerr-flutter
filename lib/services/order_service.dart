import '../models/order.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

class CheckoutPrefill {
  final String name;
  final String email;
  final String address;
  final String city;
  final String state;
  final String postcode;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String csrfToken;

  CheckoutPrefill({
    required this.name,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
    required this.csrfToken,
  });
}

/// `/my-orders` and `/order-detail` are plain server-rendered HTML
/// (`.order-card`/`.item-row` structure confirmed via a live fetch);
/// `/checkout/apply-promo` is the one real JSON endpoint in this flow.
class OrderService {
  OrderService._internal();
  static final OrderService instance = OrderService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<Order>> getMyOrders() async {
    final res = await _client.get('/my-orders');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final orders = <Order>[];
    for (final card in doc.querySelectorAll('.order-card')) {
      final link = card.querySelector('a[href*="/order-detail?id="]')?.attributes['href'] ?? '';
      final idMatch = RegExp(r'id=(\d+)').firstMatch(link);
      final meta = ScrapeUtils.text(card.querySelector('.order-meta'));
      final metaParts = meta.split('·');
      final orderNumber = metaParts.isNotEmpty ? metaParts[0].trim().replaceFirst('#', '') : '';
      final totalText = ScrapeUtils.text(card.querySelector('.order-total'));
      final total = double.tryParse(totalText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final items = <OrderItem>[];
      for (final row in card.querySelectorAll('.item-row')) {
        final nameWithQty = ScrapeUtils.text(row.querySelector('.name'));
        final priceText = ScrapeUtils.text(row.querySelector('.price'));
        items.add(OrderItem(
          orderItemId: 0,
          productId: 0,
          productName: nameWithQty.replaceAll(RegExp(r'x\d+$'), '').trim(),
          productImage: row.querySelector('img')?.attributes['src'],
          quantity: int.tryParse(RegExp(r'x(\d+)').firstMatch(nameWithQty)?.group(1) ?? '1') ?? 1,
          itemPrice: double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
        ));
      }
      orders.add(Order(
        orderId: idMatch != null ? int.parse(idMatch.group(1)!) : 0,
        orderNumber: orderNumber,
        orderStatus: ScrapeUtils.text(card.querySelector('.order-status')),
        totalAmount: total,
        items: items,
      ));
    }
    return orders;
  }

  Future<Order?> getOrderDetail(int id) async {
    final res = await _client.get('/order-detail', queryParameters: {'id': id});
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final header = doc.querySelector('.order-card h2');
    if (header == null) return null;

    final orderNumber = ScrapeUtils.text(header).replaceFirst('Order #', '');
    final status = ScrapeUtils.text(doc.querySelector('.status'));
    final itemRows = doc.querySelectorAll('.item-row');
    final items = <OrderItem>[];
    double total = 0;
    for (final row in itemRows) {
      final spans = row.querySelectorAll('span');
      if (spans.length < 2) continue;
      final label = ScrapeUtils.text(spans[0]);
      final priceText = ScrapeUtils.text(spans[1]);
      final price = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      if (label.toLowerCase() == 'shipping' || label.toLowerCase() == 'total') {
        if (label.toLowerCase() == 'total') total = price;
        continue;
      }
      items.add(OrderItem(
        orderItemId: 0,
        productId: 0,
        productName: label,
        quantity: 1,
        itemPrice: price,
      ));
    }

    final shippingBlock = doc.querySelectorAll('.order-card').length > 1
        ? doc.querySelectorAll('.order-card')[1]
        : null;
    final shippingText = ScrapeUtils.text(shippingBlock?.querySelector('p'));

    return Order(
      orderId: id,
      orderNumber: orderNumber,
      orderStatus: status,
      totalAmount: total,
      shippingName: shippingText,
      items: items,
    );
  }

  Future<Map<String, dynamic>> applyPromo(String code) async {
    final res = await _client.post('/checkout/apply-promo', data: {'promo_code': code});
    return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {'ok': false};
  }

  Future<String?> submitCheckout({
    required String name,
    required String email,
    required String address,
    required String city,
    required String state,
    required String postcode,
    required String paymentMethod,
    required String csrfToken,
  }) async {
    final res = await _client.post('/checkout', data: {
      'name': name,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'postcode': postcode,
      'payment_method': paymentMethod,
      'csrf_token': csrfToken,
    });
    final location = res.headers.value('location') ?? '';
    return location.startsWith('http') ? location : null;
  }
}
