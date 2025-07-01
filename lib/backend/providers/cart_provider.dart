import 'package:flutter/material.dart';
import 'package:vyaparhub/backend/firebase_services/cart_service.dart';
import 'package:vyaparhub/backend/models/cart_model.dart';
import 'package:vyaparhub/backend/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void fetchCartItems(String userId) {
    setLoading(true);
    _cartService.getCartItems(userId).listen((items) {
      _items = items;
      setLoading(false);
    });
  }

  Future<void> addToCart(String userId, String productId) async {
    setLoading(true);
    try {
      await _cartService.addToCart(userId, productId);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> removeFromCart(String userId, String productId) async {
    setLoading(true);
    try {
      await _cartService.removeFromCart(userId, productId);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> clearCart(String userId) async {
    setLoading(true);
    try {
      await _cartService.clearCart(userId);
      _items = [];
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  double getTotalPrice(List<Product> products) {
    double total = 0;
    for (var item in _items) {
      final product = products.firstWhere((p) => p.id == item.productId,
          orElse: () => Product(
              id: '', name: '', price: 0, description: '', merchantId: ''));
      total += product.price * item.quantity;
    }
    return total;
  }
}
