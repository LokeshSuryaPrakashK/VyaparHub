import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vyaparhub/backend/firebase_services/auth_service.dart';
import 'package:vyaparhub/backend/firebase_services/user_service.dart';

class CustomAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
        await _userService.createUser(user.uid, email, isUser);
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
