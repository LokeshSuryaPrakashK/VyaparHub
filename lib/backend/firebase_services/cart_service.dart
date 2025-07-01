import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addToCart(String userId, String productId) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    final cartDoc = await cartRef.get();
    List<CartItem> items = [];

    if (cartDoc.exists) {
      items = (cartDoc.data()!['items'] as List<dynamic>)
          .map((item) => CartItem.fromMap(item))
          .toList();
    }

    final existingItemIndex =
        items.indexWhere((item) => item.productId == productId);
    if (existingItemIndex >= 0) {
      items[existingItemIndex].quantity += 1;
    } else {
      items.add(CartItem(productId: productId, quantity: 1));
    }

    await cartRef.set({
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
    });
  }

  Future<void> removeFromCart(String userId, String productId) async {
    final cartRef = _firestore.collection('carts').doc(userId);
    final cartDoc = await cartRef.get();
    if (!cartDoc.exists) return;

    List<CartItem> items = (cartDoc.data()!['items'] as List<dynamic>)
        .map((item) => CartItem.fromMap(item))
        .toList();
    final existingItemIndex =
        items.indexWhere((item) => item.productId == productId);

    if (existingItemIndex >= 0) {
      items[existingItemIndex].quantity -= 1;
      if (items[existingItemIndex].quantity <= 0) {
        items.removeAt(existingItemIndex);
      }
      await cartRef.set({
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
      });
    }
  }

  Future<void> clearCart(String userId) async {
    await _firestore.collection('carts').doc(userId).delete();
  }

  Stream<List<CartItem>> getCartItems(String userId) {
    return _firestore.collection('carts').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      return (doc.data()!['items'] as List<dynamic>)
          .map((item) => CartItem.fromMap(item))
          .toList();
    });
  }
}
