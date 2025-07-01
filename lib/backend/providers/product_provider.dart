import 'package:flutter/material.dart';
import 'package:vyaparhub/backend/firebase_services/product_service.dart';
import 'package:vyaparhub/backend/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product>? _products;
  List<Product>? _merchantProducts;
  bool _isLoading = false;

  List<Product>? get products => _products;
  List<Product>? get merchantProducts => _merchantProducts;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void fetchProducts() {
    setLoading(true);
    _productService.getProducts().listen((products) {
      _products = products;
      setLoading(false);
    });
  }

  void fetchMerchantProducts(String merchantId) {
    setLoading(true);
    _productService.getMerchantProducts(merchantId).listen((products) {
      _merchantProducts = products;
      setLoading(false);
    });
  }

  Future<void> addProduct(Product product) async {
    setLoading(true);
    try {
      await _productService.addProduct(product);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    setLoading(true);
    try {
      await _productService.deleteProduct(productId);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> updateProduct(Product product) async {
    setLoading(true);
    try {
      await _productService.updateProduct(product);
      // Optionally update local list if needed
      if (_products != null) {
        int index = _products!.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products![index] = product;
        }
      }
      if (_merchantProducts != null) {
        int index = _merchantProducts!.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _merchantProducts![index] = product;
        }
      }
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }
}
