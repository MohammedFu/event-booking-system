import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/booking_cache_service.dart';
import 'package:munasabati/services/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiServiceReal _api = ApiServiceReal();
  final BookingCacheService _cache = BookingCacheService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _user;
  UserModel? get user => _user;

  AuthTokens? _tokens;
  AuthTokens? get tokens => _tokens;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isAuthenticated => _tokens != null && _user != null;
  bool get hasValidAccessToken => _tokens != null && !_tokens!.isExpired;

  Future<void> initialize() async {
    await _loadStoredCredentials();
    if (_tokens == null) {
      return;
    }

    if (_tokens!.isExpiringSoon) {
      await refreshToken();
    }

    if (hasValidAccessToken) {
      await syncCurrentUser(silent: true);
    }
  }

  Future<void> _saveCredentials() async {
    if (_tokens == null || _user == null) return;
    await _saveTokens();
    await _secureStorage.write(key: 'user_id', value: _user!.id);
    await _secureStorage.write(key: 'user_email', value: _user!.email);
    await _secureStorage.write(key: 'user_fullName', value: _user!.fullName);
    await _secureStorage.write(key: 'user_phone', value: _user!.phone);
    await _secureStorage.write(key: 'user_avatarUrl', value: _user!.avatarUrl);
    await _secureStorage.write(key: 'user_role', value: _user!.role.name);
    await _secureStorage.write(
        key: 'user_isVerified', value: _user!.isVerified.toString());
  }

  Future<void> _loadStoredCredentials() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshTokenStr = await _secureStorage.read(key: 'refresh_token');
      final expiresAtStr = await _secureStorage.read(key: 'expires_at');

      if (accessToken != null &&
          refreshTokenStr != null &&
          expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        _tokens = AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshTokenStr,
          expiresAt: expiresAt,
        );

        final userId = await _secureStorage.read(key: 'user_id');
        final userEmail = await _secureStorage.read(key: 'user_email');
        final userFullName = await _secureStorage.read(key: 'user_fullName');

        if (userId != null && userEmail != null && userFullName != null) {
          _user = UserModel(
            id: userId,
            email: userEmail,
            fullName: userFullName,
            phone: await _secureStorage.read(key: 'user_phone'),
            avatarUrl: await _secureStorage.read(key: 'user_avatarUrl'),
            role: UserRole.values.byName(
              await _secureStorage.read(key: 'user_role') ?? 'consumer',
            ),
            isVerified:
                (await _secureStorage.read(key: 'user_isVerified')) == 'true',
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored credentials: $e');
    }
  }

  Future<void> _saveTokens() async {
    if (_tokens == null) return;

    await _secureStorage.write(
        key: 'access_token', value: _tokens!.accessToken);
    await _secureStorage.write(
      key: 'refresh_token',
      value: _tokens!.refreshToken,
    );
    await _secureStorage.write(
      key: 'expires_at',
      value: _tokens!.expiresAt.toIso8601String(),
    );
  }

  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'expires_at');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_fullName');
    await _secureStorage.delete(key: 'user_phone');
    await _secureStorage.delete(key: 'user_avatarUrl');
    await _secureStorage.delete(key: 'user_role');
    await _secureStorage.delete(key: 'user_isVerified');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

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
        final authResult = response.data!;
        final didApplyAuth = await _applyAuthenticatedState(authResult);
        _isLoading = false;
        notifyListeners();
        return didApplyAuth;
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
    UserRole role = UserRole.consumer,
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
        role: role,
      );
      if (response.success && response.data != null) {
        final authResult = response.data!;
        final didApplyAuth = await _applyAuthenticatedState(authResult);
        _isLoading = false;
        notifyListeners();
        return didApplyAuth;
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

  Future<bool> refreshToken() async {
    if (_tokens == null) return false;

    try {
      final response = await _api.refreshToken(_tokens!.refreshToken);
      if (response.success && response.data != null) {
        _tokens = response.data;
        await _saveTokens();
        notifyListeners();
        return true;
      }

      if (_isUnauthorizedStatus(response.statusCode)) {
        await _clearSession();
      }

      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  Future<void> forgotPassword(String email) async {
    await _api.forgotPassword(email);
  }

  Future<void> logout() async {
    final userId = _user?.id;
    try {
      await PushNotificationService.instance.unregisterCurrentToken();
      await _api.logout();
    } finally {
      await _clearSession(clearUserData: true, userIdOverride: userId);
    }
  }

  Future<void> syncCurrentUser({bool silent = false}) async {
    if (_tokens == null) return;

    if (_tokens?.isExpiringSoon ?? false) {
      final refreshed = await refreshToken();
      if (!refreshed && !hasValidAccessToken) {
        return;
      }
    }

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _api.getCurrentUser();
      if (response.success && response.data != null) {
        _user = _buildUserModel(response.data!, fallback: _user);
        await _saveCredentials();
        _error = null;
        await PushNotificationService.instance.refreshToken();
      } else if (_isUnauthorizedStatus(response.statusCode)) {
        await _clearSession();
      } else if (!silent) {
        _error = response.error ?? 'Failed to get user';
      }
    } catch (e) {
      if (!silent) {
        _error = e.toString();
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _clearSession({
    bool clearUserData = false,
    String? userIdOverride,
  }) async {
    final userId = userIdOverride ?? _user?.id;
    if (clearUserData && userId != null && userId.isNotEmpty) {
      await _cache.clearUserData(userId);
    }

    await _clearStoredCredentials();
    _user = null;
    _tokens = null;
    _error = null;
    notifyListeners();
  }

  bool _isUnauthorizedStatus(int? statusCode) {
    return statusCode == 401 || statusCode == 403;
  }

  Future<bool> _applyAuthenticatedState(AuthResult authResult) async {
    final resolvedUser = await _resolveAuthenticatedUser(authResult.user);
    if (resolvedUser == null) {
      await _clearStoredCredentials();
      _tokens = null;
      _user = null;
      _error = 'Authenticated successfully, but failed to load user profile.';
      return false;
    }

    _tokens = authResult.tokens;
    _user = resolvedUser;
    _error = null;
    await _saveCredentials();
    await PushNotificationService.instance.refreshToken();
    return true;
  }

  Future<UserModel?> _resolveAuthenticatedUser(UserModel? preferredUser) async {
    if (preferredUser != null && preferredUser.id.isNotEmpty) {
      return preferredUser;
    }

    final response = await _api.getCurrentUser();
    if (!response.success || response.data == null) {
      return null;
    }

    return _buildUserModel(response.data!, fallback: preferredUser);
  }

  UserModel _buildUserModel(
    Map<String, dynamic> userData, {
    UserModel? fallback,
  }) {
    final isVerifiedValue = userData['isVerified'];
    final isVerified = switch (isVerifiedValue) {
      bool value => value,
      String value => value.toLowerCase() == 'true',
      _ => fallback?.isVerified ?? false,
    };

    return UserModel(
      id: userData['id']?.toString() ?? fallback?.id ?? '',
      email: userData['email']?.toString() ?? fallback?.email ?? '',
      fullName: userData['fullName']?.toString() ?? fallback?.fullName ?? '',
      phone: userData['phone']?.toString() ?? fallback?.phone,
      avatarUrl: userData['avatarUrl']?.toString() ?? fallback?.avatarUrl,
      role: _parseUserRole(userData['role'] ?? fallback?.role.name),
      isVerified: isVerified,
    );
  }

  UserRole _parseUserRole(dynamic role) {
    switch (role?.toString().toLowerCase()) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'consumer':
      default:
        return UserRole.consumer;
    }
  }
}
