import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _authService.login(email, password);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future loadUser() async {
    if (_authService.currentUser != null) {
      _user = await _authService.getUserData(_authService.currentUser!.uid);
      notifyListeners();
    }
  }
}