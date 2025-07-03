import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/firebase_services/auth_service.dart';
import 'package:vyaparhub/backend/models/address_model.dart';
import 'package:vyaparhub/backend/models/user_model.dart';

class CustomAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  UserModel? _userModel;
  List<Address> _addresses = [];

  UserModel? get userModel => _userModel;
  List<Address> get addresses => _addresses;
  bool get isAuthenticated => _userModel != null;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> fetchUserData(String uid) async {
    try {
      setLoading(true);
      _userModel = await _authService.fetchUserData(uid);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> fetchAddresses(String userId) async {
    try {
      setLoading(true);
      _authService.getAddresses(userId).listen((addresses) {
        // debugPrint(
        //     'Fetched ${addresses.length} addresses: ${addresses.map((a) => a.toMap()).toList()}');
        _addresses = addresses;
        setLoading(false);
        notifyListeners();
      }, onError: (e) {
        // debugPrint('Error in address stream: $e');
        _addresses = [];
        setLoading(false);
        notifyListeners();
      });
    } catch (e) {
      // debugPrint('Error fetching addresses: $e');
      _addresses = [];
      setLoading(false);
      notifyListeners();
      throw Exception('Failed to fetch addresses: $e');
    }
  }

  Future<void> addAddress(String userId, Address address) async {
    try {
      setLoading(true);
      await _authService.addAddress(userId, address);
      print('Address added: ${address.toMap()}');
      await fetchUserData(
          userId); // Refresh user data to update selectedAddressId
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> updateAddress(
      String userId, String addressId, Address address) async {
    try {
      setLoading(true);
      await _authService.updateAddress(userId, addressId, address);
      await fetchUserData(
          address.userId); // Refresh user data to update selectedAddressId
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      setLoading(true);
      await _authService.signIn(email, password);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> signUp(String email, String password, bool isUser) async {
    try {
      setLoading(true);
      await _authService.signUp(email, password);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _authService.createUser(user.uid, email, isUser);
      }
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      setLoading(true);
      await _authService.signOut();
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Stream<User?> get authStateChanges => _authService.authStateChanges;
}
