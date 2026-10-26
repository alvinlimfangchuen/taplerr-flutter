class OrderItem {
  final int orderItemId;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double itemPrice;
  final String? designConfigJson;
  final String? uploadedDesignPath;

  OrderItem({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.itemPrice,
    this.designConfigJson,
    this.uploadedDesignPath,
  });

  /// Mirrors helpers.php's describe_order_item_customization(): a flat
  /// {label, value} breakdown of the chosen customization.
  List<MapEntry<String, String>> describeCustomization() {
    if (uploadedDesignPath != null && uploadedDesignPath!.isNotEmpty) {
      return [const MapEntry('Design', 'Customer-uploaded design file')];
    }
    return const [];
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    return OrderItem(
      orderItemId: asInt(json['order_item_id']),
      productId: asInt(json['product_id']),
      productName: json['name']?.toString() ?? json['product_name']?.toString() ?? '',
      productImage: json['image_front']?.toString() ?? json['image']?.toString(),
      quantity: asInt(json['quantity']) == 0 ? 1 : asInt(json['quantity']),
      itemPrice: asDouble(json['item_price']),
      designConfigJson: json['design_config']?.toString(),
      uploadedDesignPath: json['uploaded_design_path']?.toString(),
    );
  }
}

class Order {
  final int orderId;
  final String orderNumber;
  final String orderStatus;
  final double totalAmount;
  final double shippingFee;
  final String? paymentMethod;
  final DateTime? createdAt;
  final String? shippingName;
  final String? shippingEmail;
  final String? shippingAddress;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPostcode;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.totalAmount,
    this.shippingFee = 0,
    this.paymentMethod,
    this.createdAt,
    this.shippingName,
    this.shippingEmail,
    this.shippingAddress,
    this.shippingCity,
    this.shippingState,
    this.shippingPostcode,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    final rawItems = json['items'];
    return Order(
      orderId: asInt(json['order_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      orderStatus: json['order_status']?.toString() ?? 'Pending',
      totalAmount: asDouble(json['total_amount']),
      shippingFee: asDouble(json['shipping_fee']),
      paymentMethod: json['payment_method']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      shippingName: json['shipping_name']?.toString(),
      shippingEmail: json['shipping_email']?.toString(),
      shippingAddress: json['shipping_address']?.toString(),
      shippingCity: json['shipping_city']?.toString(),
      shippingState: json['shipping_state']?.toString(),
      shippingPostcode: json['shipping_postcode']?.toString(),
      items: rawItems is List
          ? rawItems.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList()
          : const [],
    );
  }
}
