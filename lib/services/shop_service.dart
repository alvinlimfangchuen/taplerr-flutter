import 'dart:io';
import 'package:dio/dio.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'scrape_utils.dart';

/// Products (`/products`), cart (`/cart`, `/cart/update-quantity`,
/// `/cart/remove`), and the three customize flows (`/customize/basic`,
/// `/customize/upload`, `/customize/live`) — all plain server-rendered
/// HTML except `/cart/update-quantity`, which is real JSON (see doc §3).
class ShopService {
  ShopService._internal();
  static final ShopService instance = ShopService._internal();

  final ApiClient _client = ApiClient.instance;

  static const Map<String, double> basicAddonPrices = {
    'name': 5.00,
    'position': 3.00,
    'level': 2.00,
  };
  static const double uploadCharge = 20.00;
  static const double liveEditorCharge = 50.00;

  Future<List<Product>> getProducts() async {
    final res = await _client.get('/products');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final products = <Product>[];
    for (final item in doc.querySelectorAll('.product-item')) {
      final href = item.querySelector('.btn-view')?.attributes['href'] ?? '';
      final idMatch = RegExp(r'product_id=(\d+)').firstMatch(href);
      if (idMatch == null) continue;
      final priceText = ScrapeUtils.text(item.querySelector('.price'));
      final price = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      products.add(Product(
        productId: int.parse(idMatch.group(1)!),
        name: ScrapeUtils.text(item.querySelector('h3')),
        imageFront: item.querySelector('.card-front img')?.attributes['src'],
        imageBack: item.querySelector('.card-back img')?.attributes['src'],
        price: price,
      ));
    }
    return products;
  }

  Future<CartSummary> getCart() async {
    final res = await _client.get('/cart');
    final html = res.data is String ? res.data as String : '';
    final doc = ScrapeUtils.parseDocument(html);
    final rows = doc.querySelectorAll('.cart-item');
    final items = <CartItem>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final priceText = ScrapeUtils.text(row.querySelector('.price'));
      final price = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      items.add(CartItem(
        index: i,
        productId: 0,
        name: ScrapeUtils.text(row.querySelector('.info h4')),
        image: row.querySelector('img')?.attributes['src'],
        price: price,
        quantity: int.tryParse(row.querySelector('input.qty-input')?.attributes['value'] ?? '1') ?? 1,
        customizationType: 'basic',
      ));
    }
    final subtotalEl = doc.querySelector('#cartSubtotal') ?? doc.querySelector('.cart-summary .subtotal');
    final subtotalText = ScrapeUtils.text(subtotalEl);
    final subtotal = double.tryParse(subtotalText.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        items.fold<double>(0.0, (sum, item) => sum + item.lineTotal);
    return CartSummary(items: items, subtotal: subtotal);
  }

  Future<Map<String, dynamic>> updateQuantity({required int index, required int quantity}) async {
    final res = await _client.post('/cart/update-quantity', data: {
      'index': index,
      'quantity': quantity,
    });
    return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : {'ok': false};
  }

  Future<void> removeFromCart(int index) async {
    await _client.get('/cart/remove', queryParameters: {'index': index});
  }

  Future<bool> addBasicCustomization({
    required int productId,
    String? name,
    String? position,
    String? level,
    int? editIndex,
  }) async {
    return _client.postExpectRedirectAwayFrom(
      '/customize/basic',
      {
        'product_id': productId,
        if (name != null && name.isNotEmpty) 'add_name': '1',
        if (name != null && name.isNotEmpty) 'text_name': name,
        if (position != null && position.isNotEmpty) 'add_position': '1',
        if (position != null && position.isNotEmpty) 'text_position': position,
        if (level != null && level.isNotEmpty) 'add_level': '1',
        if (level != null && level.isNotEmpty) 'text_level': level,
        if (editIndex != null) 'edit_index': editIndex,
      },
      awayFrom: '/customize/basic',
    );
  }

  Future<bool> addUploadCustomization({required int productId, required File designFile}) async {
    final dio = await _client.dio;
    final form = FormData.fromMap({
      'product_id': '$productId',
      'design_file': await MultipartFile.fromFile(designFile.path),
    });
    final res = await dio.post('/customize/upload', data: form);
    final location = res.headers.value('location') ?? '';
    return res.statusCode == 302 && !location.contains('/customize/upload');
  }

  Future<bool> addLiveCustomization({
    required int productId,
    required String theme,
    required List<Map<String, dynamic>> texts,
    File? logo,
  }) async {
    final textsJson = _encodeTexts(texts);
    if (logo != null) {
      final dio = await _client.dio;
      final form = FormData.fromMap({
        'product_id': '$productId',
        'theme': theme,
        'texts_json': textsJson,
        'logo': await MultipartFile.fromFile(logo.path),
      });
      final res = await dio.post('/customize/live', data: form);
      final location = res.headers.value('location') ?? '';
      return res.statusCode == 302 && !location.contains('/customize/live');
    }
    return _client.postExpectRedirectAwayFrom(
      '/customize/live',
      {'product_id': productId, 'theme': theme, 'texts_json': textsJson},
      awayFrom: '/customize/live',
    );
  }

  String _encodeTexts(List<Map<String, dynamic>> texts) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < texts.length; i++) {
      if (i > 0) buffer.write(',');
      final t = texts[i];
      buffer.write(
        '{"text":"${t['text']}","font":"${t['font']}","size":${t['size']},"color":"${t['color']}"}',
      );
    }
    buffer.write(']');
    return buffer.toString();
  }
}
