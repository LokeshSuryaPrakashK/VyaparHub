class CartItem {
  final String productId;
  int quantity;

  CartItem({required this.productId, required this.quantity});

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      productId: data['productId'],
      quantity: data['quantity'],
    );
  }
}
