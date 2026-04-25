import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dio HTTP client with JWT authentication and interceptors
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  // API Configuration
  // For iOS Simulator: use localhost
  // For Android Emulator: use 10.0.2.2
  // For physical Android device: use your computer's WiFi IP (e.g., 192.168.1.xxx)
  //
  // IMPORTANT: Set this to your computer's actual IP address:
  static const String _computerIp = '10.42.0.249'; // <-- CHANGE THIS!

  static String get _baseUrl {
    if (kIsWeb) return 'http://$_computerIp:3000';

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // If using physical device, use your computer's IP
        return 'http://$_computerIp:3000';
      }
    } catch (e) {
      // Platform not available
    }

    return 'http://localhost:3000'; // iOS simulator or fallback
  }

  static String get baseUrl => _baseUrl;
  static Uri? get baseUri => Uri.tryParse(_baseUrl);

  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 10);
  static const int _maxRetryAttempts = 2;
  static const List<String> _rasterExtensions = [
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
  ];

  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';

  /// Initialize Dio client with interceptors
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _defaultTimeout,
      receiveTimeout: _receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_errorInterceptor());

    // Add logger in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ));
    }
  }

  /// Get Dio instance
  Dio get dio {
    return _dio;
  }

  /// Auth interceptor to add JWT token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for login/register endpoints
        if (_isAuthEndpoint(options.path)) {
          return handler.next(options);
        }

        // Get access token
        final token = await _secureStorage.read(key: _accessTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized - try to refresh token (only once)
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          final refreshed = await _refreshToken();
          _isRefreshing = false;

          if (refreshed) {
            // Retry original request with new token
            final token = await _secureStorage.read(key: _accessTokenKey);
            error.requestOptions.headers['Authorization'] = 'Bearer $token';

            final response = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );

            return handler.resolve(response);
          } else {
            // Token refresh failed, clear tokens
            await clearTokens();
          }
        }
        return handler.next(error);
      },
    );
  }

  /// Error interceptor for consistent error handling
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          try {
            final response = await _retryRequest(error);
            return handler.resolve(response);
          } catch (_) {
            // Fall through to the normalized error message below.
          }
        }

        String message = 'An unexpected error occurred';

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          message =
              'Connection timeout. Please check your internet connection.';
        } else if (error.type == DioExceptionType.connectionError) {
          message = 'No internet connection. Please try again later.';
        } else if (error.response != null) {
          final data = error.response?.data;
          if (data != null && data is Map<String, dynamic>) {
            message = data['message'] ?? data['error'] ?? message;
          }
        }

        // Create a new error with the formatted message
        final newError = DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: message,
        );

        return handler.next(newError);
      },
    );
  }

  bool _shouldRetry(DioException error) {
    final attempt = error.requestOptions.extra['retry_attempt'] as int? ?? 0;
    final method = error.requestOptions.method.toUpperCase();

    if (attempt >= _maxRetryAttempts || method != 'GET') {
      return false;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(DioException error) async {
    final requestOptions = error.requestOptions;
    final attempt = (requestOptions.extra['retry_attempt'] as int? ?? 0) + 1;
    requestOptions.extra['retry_attempt'] = attempt;

    await Future.delayed(Duration(milliseconds: 300 * attempt));
    return _dio.fetch<dynamic>(requestOptions);
  }

  /// Check if the endpoint is an auth endpoint (no token needed)
  bool _isAuthEndpoint(String path) {
    final authEndpoints = [
      '/api/v1/auth/login',
      '/api/v1/auth/register',
      '/api/v1/auth/forgot-password',
      '/api/v1/auth/reset-password',
      '/api/v1/auth/refresh',
    ];
    return authEndpoints.any((endpoint) => path.contains(endpoint));
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _dio.post('/api/v1/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  /// Save tokens to secure storage
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? expiresAt,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    if (expiresAt != null && expiresAt.isNotEmpty) {
      await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
    }

    // Also save to SharedPreferences for quick access (non-sensitive)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Update base URL (useful for switching between dev/prod)
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  static List<String> normalizeMediaUrls(dynamic values) {
    if (values is! Iterable) {
      return const [];
    }

    return values
        .map((value) => normalizeMediaUrl(value?.toString()))
        .whereType<String>()
        .toList(growable: false);
  }

  static String? normalizeMediaUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return trimmed;
    }

    if (_isUnsupportedPlaceholder(uri)) {
      return null;
    }

    final currentBaseUri = baseUri;
    if (currentBaseUri == null) {
      return trimmed;
    }

    if (!uri.hasScheme) {
      return currentBaseUri.resolveUri(uri).toString();
    }

    if (_isBackendHostedAsset(uri) &&
        (uri.scheme != currentBaseUri.scheme ||
            uri.host != currentBaseUri.host ||
            _effectivePort(uri) != _effectivePort(currentBaseUri))) {
      final rebasedUri = currentBaseUri.hasPort
          ? uri.replace(
              scheme: currentBaseUri.scheme,
              host: currentBaseUri.host,
              port: currentBaseUri.port,
            )
          : uri.replace(
              scheme: currentBaseUri.scheme,
              host: currentBaseUri.host,
            );
      return rebasedUri.toString();
    }

    return trimmed;
  }

  static bool _isBackendHostedAsset(Uri uri) {
    if (uri.path.contains('/uploads/')) {
      return true;
    }

    final host = uri.host.toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host == '0.0.0.0';
  }

  static bool _isUnsupportedPlaceholder(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!host.contains('placehold.co')) {
      return false;
    }

    final path = uri.path.toLowerCase();
    return !_rasterExtensions.any(path.endsWith) && !path.endsWith('/png');
  }

  static int _effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }

    return uri.scheme == 'https' ? 443 : 80;
  }

  // HTTP Methods
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}

// Global instance
final dioClient = DioClient();
