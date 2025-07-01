import 'package:flutter/material.dart';
import 'package:vyaparhub/backend/firebase_services/user_service.dart';
import 'package:vyaparhub/backend/models/address_model.dart';
import 'package:vyaparhub/backend/models/user_model.dart';

class UserModelProvider with ChangeNotifier {
  final UserService _userService = UserService();
  UserModel? _userModel;
  List<Address> _addresses = [];
  bool _isLoading = false;

  UserModel? get userModel => _userModel;
  List<Address> get addresses => _addresses;
  bool get isAuthenticated => _userModel != null;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchUserData(String uid) async {
    try {
      setLoading(true);
      _userModel = await _userService.fetchUserData(uid);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> fetchAddresses(String userId) async {
    try {
      setLoading(true);
      _userService.getAddresses(userId).listen((addresses) {
        _addresses = addresses;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      setLoading(false);
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<void> addAddress(String userId, Address address) async {
    try {
      setLoading(true);
      await _userService.addAddress(userId, address);
      await fetchUserData(
          userId); // Refresh user data to update selectedAddressId
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> updateAddress(String addressId, Address address) async {
    try {
      setLoading(true);
      await _userService.updateAddress(addressId, address);
      await fetchUserData(
          address.userId); // Refresh user data to update selectedAddressId
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }
}
