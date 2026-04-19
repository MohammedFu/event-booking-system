import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';

class AuthProvider extends ChangeNotifier {
  final ApiServiceReal _api = ApiServiceReal();

  UserModel? _user;
  UserModel? get user => _user;

  AuthTokens? _tokens;
  AuthTokens? get tokens => _tokens;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _tokens != null && !_tokens!.isExpired;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(email: email, password: password);
      if (response.success && response.data != null) {
        _tokens = response.data;
        _user = UserModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: 'Demo User',
          role: UserRole.consumer,
          isVerified: true,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (response.success && response.data != null) {
        _tokens = response.data;
        _user = UserModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: fullName,
          phone: phone,
          role: UserRole.consumer,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshToken() async {
    if (_tokens == null) return;

    try {
      final response = await _api.refreshToken(_tokens!.refreshToken);
      if (response.success && response.data != null) {
        _tokens = response.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> forgotPassword(String email) async {
    await _api.forgotPassword(email);
  }

  void logout() {
    _user = null;
    _tokens = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
