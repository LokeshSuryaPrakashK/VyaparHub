import 'package:flutter/material.dart';
import 'package:vyaparhub/backend/firebase_services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> placeOrder(
    String userId,
    Map<String, int> items,
    double total,
    String paymentMethod,
    String email, {
    required String shippingAddressId,
  }) async {
    try {
      setLoading(true);
      await _orderService.placeOrder(userId, items, total, email, paymentMethod,
          shippingAddressId: shippingAddressId);
      setLoading(false);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
}
