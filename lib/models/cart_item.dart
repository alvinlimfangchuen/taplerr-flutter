class CartItem {
  final int index;
  final int productId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final String customizationType; // basic | upload | live
  final Map<String, dynamic> customizationData;

  CartItem({
    required this.index,
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    required this.customizationType,
    this.customizationData = const {},
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromJson(int index, Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    return CartItem(
      index: index,
      productId: asInt(json['product_id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      price: asDouble(json['price']),
      quantity: asInt(json['quantity']) == 0 ? 1 : asInt(json['quantity']),
      customizationType: json['customization_type']?.toString() ?? 'basic',
      customizationData: json['customization_data'] is Map<String, dynamic>
          ? json['customization_data'] as Map<String, dynamic>
          : const {},
    );
  }
}

class CartSummary {
  final List<CartItem> items;
  final double subtotal;

  CartSummary({required this.items, required this.subtotal});

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    final rawItems = json['cart'];
    final items = <CartItem>[];
    if (rawItems is List) {
      for (var i = 0; i < rawItems.length; i++) {
        final row = rawItems[i];
        if (row is Map<String, dynamic>) items.add(CartItem.fromJson(i, row));
      }
    }
    final subtotal = json['subtotal'];
    return CartSummary(
      items: items,
      subtotal: subtotal is num ? subtotal.toDouble() : double.tryParse('${subtotal ?? 0}') ?? 0,
    );
  }
}
