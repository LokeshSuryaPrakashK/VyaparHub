class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String merchantId;
  final String? productPhotoUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.merchantId,
    this.productPhotoUrl,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'merchantId': merchantId,
      'productPhotoUrl': productPhotoUrl,
      'category': category,
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
      productPhotoUrl: map['productPhotoUrl'] as String?,
      category: map['category'] as String? ?? 'General',
    );
  }
}
