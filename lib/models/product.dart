class Product {
  final int productId;
  final String name;
  final String? imageFront;
  final String? imageBack;
  final double price;
  final String? tag;

  Product({
    required this.productId,
    required this.name,
    this.imageFront,
    this.imageBack,
    required this.price,
    this.tag,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    double asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    return Product(
      productId: asInt(json['product_id']),
      name: json['name']?.toString() ?? '',
      imageFront: json['image_front']?.toString() ?? json['image']?.toString(),
      imageBack: json['image_back']?.toString(),
      price: asDouble(json['price']),
      tag: json['tag']?.toString(),
    );
  }
}
