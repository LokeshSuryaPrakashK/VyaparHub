class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String merchantId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.merchantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'merchantId': merchantId,
    };
  }

  factory Product.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      merchantId: map['merchantId'] as String? ?? '',
    );
  }
}
