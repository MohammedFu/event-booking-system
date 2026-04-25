import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'dio_client.dart';

/// Combined auth result with tokens and user data
class AuthResult {
  final AuthTokens tokens;
  final UserModel? user;

  const AuthResult({
    required this.tokens,
    this.user,
  });
}

/// Real API service using Dio HTTP client
/// Replaces the mock ApiService when backend is ready
class ApiServiceReal {
  static final DioClient _client = DioClient();

  // Initialize the Dio client
  static void initialize() {
    _client.initialize();
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post('/api/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        // Save tokens
        await _client.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );

        // Parse user data if available
        UserModel? user;
        if (data['user'] != null) {
          final userData = data['user'];
          user = UserModel(
            id: userData['id'],
            email: userData['email'],
            fullName: userData['fullName'],
            phone: userData['phone'],
            role: _parseUserRole(userData['role']),
            avatarUrl: userData['avatarUrl'],
            isVerified: userData['isVerified'] ?? false,
          );
        }

        return ApiResponse.ok(
          AuthResult(
            tokens: AuthTokens(
              accessToken: data['accessToken'],
              refreshToken: data['refreshToken'],
              expiresAt: DateTime.parse(data['expiresAt']),
            ),
            user: user,
          ),
        );
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<AuthResult>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole? role,
  }) async {
    try {
      final response = await _client.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'role': role?.name.toUpperCase(),
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];

        // Save tokens
        await _client.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );

        // Parse user data if available
        UserModel? user;
        if (data['user'] != null) {
          final userData = data['user'];
          user = UserModel(
            id: userData['id'],
            email: userData['email'],
            fullName: userData['fullName'],
            phone: userData['phone'],
            role: _parseUserRole(userData['role']),
            avatarUrl: userData['avatarUrl'],
            isVerified: userData['isVerified'] ?? false,
          );
        }

        return ApiResponse.ok(
          AuthResult(
            tokens: AuthTokens(
              accessToken: data['accessToken'],
              refreshToken: data['refreshToken'],
              expiresAt: DateTime.parse(data['expiresAt']),
            ),
            user: user,
          ),
        );
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final refreshToken = await _client.getRefreshToken();

      if (refreshToken != null) {
        await _client.post('/api/v1/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }

      await _client.clearTokens();
      return ApiResponse.ok(null);
    } catch (e) {
      await _client.clearTokens();
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    try {
      final response = await _client.get('/api/v1/auth/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(response.data['data']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get user',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<AuthTokens>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post('/api/v1/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];

        await _client.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresAt: data['expiresAt'],
        );

        return ApiResponse.ok(
          AuthTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            expiresAt: DateTime.parse(data['expiresAt']),
          ),
        );
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Token refresh failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final response =
          await _client.post('/api/v1/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to send reset email',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SERVICES
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<ServiceModel>>> getServices({
    ServiceType? type,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    String sortBy = 'rating',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
      };

      if (type != null) queryParams['type'] = type.name.toUpperCase();
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;

      final response =
          await _client.get('/api/v1/services', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final services = data.map((json) => _parseService(json)).toList();

        return ApiResponse.ok(
          services,
          meta: response.data['meta'],
        );
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get services',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<ServiceModel>> getServiceById(String id) async {
    try {
      final response = await _client.get('/api/v1/services/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseService(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Service not found',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<TimeSlot>>> getServiceAvailability(
    String serviceId,
    DateTime date,
  ) async {
    try {
      final response = await _client.get(
        '/api/v1/services/$serviceId/availability',
        queryParameters: {
          'date': date.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final slots = data.map((json) => _parseTimeSlot(json)).toList();
        return ApiResponse.ok(slots);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get availability',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<ServiceModel>>> searchServices(String query) async {
    try {
      final response = await _client.get(
        '/api/v1/services/search',
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final services = data.map((json) => _parseService(json)).toList();
        return ApiResponse.ok(services, meta: response.data['meta']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Search failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BOOKINGS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<BookingModel>> createBooking({
    required String eventType,
    required DateTime eventDate,
    String? eventName,
    required List<BookingCartItem> cartItems,
    String? specialRequests,
  }) async {
    try {
      final items = cartItems
          .map((item) => {
                'serviceId': item.service.id,
                'date': item.date.toIso8601String().split('T')[0],
                'startTime': _formatTime(item.startTime),
                'endTime': _formatTime(item.endTime),
                'durationHours': item.durationHours,
                'specialRequests': item.specialRequests,
              })
          .toList();

      final response = await _client.post('/api/v1/bookings', data: {
        'eventType': eventType.toUpperCase(),
        'eventDate': eventDate.toIso8601String().split('T')[0],
        'eventName': eventName,
        'items': items,
        'specialRequests': specialRequests,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse.ok(_parseBooking(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to create booking',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<BookingModel>>> getBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status.toUpperCase();

      final response =
          await _client.get('/api/v1/bookings', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final bookings = data.map((json) => _parseBooking(json)).toList();
        return ApiResponse.ok(bookings, meta: response.data['meta']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get bookings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<BookingModel>> getBookingById(String id) async {
    try {
      final response = await _client.get('/api/v1/bookings/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseBooking(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Booking not found',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> cancelBooking(String id, {String? reason}) async {
    try {
      final response = await _client.post('/api/v1/bookings/$id/cancel', data: {
        'reason': reason,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to cancel booking',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENTS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
  }) async {
    try {
      final response =
          await _client.post('/api/v1/payments/create-intent', data: {
        'amount': (amount * 100).round(), // Convert to cents
        'currency': currency,
        'bookingId': bookingId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(response.data['data']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to create payment intent',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<PaymentModel>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _client.post('/api/v1/payments/confirm', data: {
        'paymentIntentId': paymentIntentId,
        'paymentMethod': paymentMethod,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parsePayment(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Payment confirmation failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<ReviewModel>>> getServiceReviews(
    String serviceId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        '/api/v1/services/$serviceId/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final reviews = data.map((json) => _parseReview(json)).toList();
        return ApiResponse.ok(reviews, meta: response.data['meta']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get reviews',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<ReviewModel>> submitReview({
    required String bookingItemId,
    required String providerId,
    required int rating,
    String? comment,
    List<String>? images,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _client.post('/api/v1/users/reviews', data: {
        'bookingItemId': bookingItemId,
        'rating': rating,
        'comment': comment,
        'images': images,
        'isAnonymous': isAnonymous,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse.ok(_parseReview(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to submit review',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    String? userId, // Ignored - backend uses JWT
    bool? unreadOnly,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (unreadOnly == true) queryParams['unreadOnly'] = 'true';

      final response = await _client.get('/api/v1/users/notifications',
          queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final notifications =
            data.map((json) => _parseNotification(json)).toList();
        return ApiResponse.ok(notifications, meta: response.data['meta']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get notifications',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> markNotificationRead(String notificationId) async {
    try {
      final response = await _client
          .patch('/api/v1/users/notifications/$notificationId/read');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to mark notification as read',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      final response =
          await _client.post('/api/v1/users/notifications/read-all');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to mark all notifications as read',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      final response = await _client.post('/api/v1/users/device-tokens', data: {
        'token': token,
        'platform': platform,
      });

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to register device token',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> unregisterDeviceToken(String token) async {
    try {
      final response =
          await _client.delete('/api/v1/users/device-tokens', data: {
        'token': token,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to unregister device token',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<ServiceModel>>> getBookmarkedServices() async {
    try {
      final response = await _client.get('/api/v1/users/bookmarks');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final services = data.map((json) => _parseService(json)).toList();
        return ApiResponse.ok(services);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get bookmarks',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> addBookmark(String serviceId) async {
    try {
      final response = await _client.post('/api/v1/users/bookmarks', data: {
        'serviceId': serviceId,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to add bookmark',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> removeBookmark(String serviceId) async {
    try {
      final response =
          await _client.delete('/api/v1/users/bookmarks/$serviceId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to remove bookmark',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // USER PREFERENCES
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<UserPreferences>> getUserPreferences() async {
    try {
      final response = await _client.get('/api/v1/users/preferences');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          return ApiResponse.ok(const UserPreferences());
        }
        return ApiResponse.ok(_parseUserPreferences(data));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get preferences',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<UserPreferences>> updateUserPreferences(
      UserPreferences preferences) async {
    try {
      final response = await _client.put('/api/v1/users/preferences', data: {
        'preferredHallThemes': preferences.preferredHallThemes,
        'preferredCarTypes': preferences.preferredCarTypes,
        'preferredPhotographerStyles': preferences.preferredPhotographerStyles,
        'preferredEntertainerTypes': preferences.preferredEntertainerTypes,
        'budgetRange': {
          'min': preferences.budgetRange.min,
          'max': preferences.budgetRange.max,
        },
        'preferredCities': preferences.preferredCities,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseUserPreferences(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to update preferences',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PROVIDER METHODS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<ProviderDashboardStats>> getProviderDashboard() async {
    try {
      final response = await _client.get('/api/v1/provider/dashboard');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseProviderDashboard(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get provider dashboard',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<BookingModel>>> getProviderBookings({
    BookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status.name.toUpperCase();

      final response = await _client.get(
        '/api/v1/provider/bookings',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final bookings = data
            .map((json) => _parseProviderBooking(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.ok(bookings, meta: response.data['meta']);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get provider bookings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<BookingItem>> updateProviderBookingStatus({
    required String bookingItemId,
    required BookingStatus status,
  }) async {
    try {
      final response = await _client.patch(
        '/api/v1/provider/bookings/$bookingItemId/status',
        data: {
          'status': status.name.toUpperCase(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseBookingItem(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to update booking status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<ServiceModel>>> getProviderServices() async {
    try {
      final response = await _client.get('/api/v1/provider/services');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final services = data
            .map((json) => _parseService(json as Map<String, dynamic>))
            .toList();
        return ApiResponse.ok(services);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get provider services',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<AvailabilityTemplateModel>>> getAvailabilityTemplates(
      String serviceId) async {
    try {
      final response =
          await _client.get('/api/v1/provider/availability/$serviceId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final templates =
            data.map((json) => _parseAvailabilityTemplate(json)).toList();
        return ApiResponse.ok(templates);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get availability templates',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<AvailabilityTemplateModel>> updateAvailabilityTemplate(
    String serviceId,
    AvailabilityTemplateModel template,
  ) async {
    try {
      final response = await _client.put(
        '/api/v1/provider/availability/$serviceId',
        data: {
          'templates': [
            {
              'dayOfWeek': template.dayOfWeek,
              'startTime': _formatTime(template.startTime),
              'endTime': _formatTime(template.endTime),
              'isAvailable': template.isAvailable,
            }
          ],
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(
            _parseAvailabilityTemplate(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to update availability',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<List<PricingRuleModel>>> getPricingRules(
      String serviceId) async {
    try {
      final response =
          await _client.get('/api/v1/provider/pricing-rules/$serviceId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final rules = data.map((json) => _parsePricingRule(json)).toList();
        return ApiResponse.ok(rules);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to get pricing rules',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<PricingRuleModel>> createPricingRule({
    required String serviceId,
    required PricingRuleType ruleType,
    required double multiplier,
    double fixedAdjustment = 0,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfWeek,
    int? minAdvanceDays,
    int priority = 0,
  }) async {
    try {
      final response = await _client.post(
        '/api/v1/provider/pricing-rules',
        data: {
          'serviceId': serviceId,
          'ruleType': ruleType.name.toUpperCase(),
          'multiplier': multiplier,
          'fixedAdjustment': fixedAdjustment,
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'dayOfWeek': dayOfWeek,
          'minAdvanceDays': minAdvanceDays,
          'priority': priority,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse.ok(_parsePricingRule(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to create pricing rule',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PROVIDER SERVICE MANAGEMENT (with images)
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<ServiceModel>> createService({
    required String title,
    required ServiceType serviceType,
    required double basePrice,
    String? description,
    String currency = 'YER',
    PricingModel pricingModel = PricingModel.flat,
    List<String> images = const [],
    List<String> tags = const [],
    int? maxCapacity,
    double? minDurationHours,
    double? maxDurationHours,
    bool isAvailable = true,
    ServiceAttributes? attributes,
    CancellationPolicy? cancellationPolicy,
  }) async {
    try {
      final data = <String, dynamic>{
        'title': title,
        'serviceType': serviceType.name.toUpperCase(),
        'basePrice': basePrice,
        'currency': currency,
        'pricingModel': pricingModel.name.toUpperCase(),
        'images': images,
        'tags': tags,
        'isAvailable': isAvailable,
      };

      final trimmedDescription = description?.trim();
      if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
        data['description'] = trimmedDescription;
      }
      if (maxCapacity != null) data['maxCapacity'] = maxCapacity;
      if (minDurationHours != null) data['minDurationHours'] = minDurationHours;
      if (maxDurationHours != null) data['maxDurationHours'] = maxDurationHours;

      final serializedAttributes =
          attributes != null ? _serializeGenericAttributes(attributes) : null;
      if (serializedAttributes != null && serializedAttributes.isNotEmpty) {
        data['attributes'] = serializedAttributes;
      }

      final serializedCancellationPolicy =
          _serializeCancellationPolicy(cancellationPolicy);
      if (serializedCancellationPolicy != null) {
        data['cancellationPolicy'] = serializedCancellationPolicy;
      }

      final response = await _client.post(
        '/api/v1/provider/services',
        data: data,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse.ok(_parseService(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to create service',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<ServiceModel>> updateService({
    required String serviceId,
    String? title,
    String? description,
    double? basePrice,
    String? currency,
    PricingModel? pricingModel,
    List<String>? images,
    List<String>? tags,
    int? maxCapacity,
    double? minDurationHours,
    double? maxDurationHours,
    bool? isAvailable,
    ServiceAttributes? attributes,
    CancellationPolicy? cancellationPolicy,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (basePrice != null) data['basePrice'] = basePrice;
      if (currency != null) data['currency'] = currency;
      if (pricingModel != null) {
        data['pricingModel'] = pricingModel.name.toUpperCase();
      }
      if (images != null) data['images'] = images;
      if (tags != null) data['tags'] = tags;
      if (maxCapacity != null) data['maxCapacity'] = maxCapacity;
      if (minDurationHours != null) data['minDurationHours'] = minDurationHours;
      if (maxDurationHours != null) data['maxDurationHours'] = maxDurationHours;
      if (isAvailable != null) data['isAvailable'] = isAvailable;
      if (attributes != null) {
        // Need to determine service type - fetch existing service or pass it
        data['attributes'] = _serializeGenericAttributes(attributes);
      }
      final serializedCancellationPolicy =
          _serializeCancellationPolicy(cancellationPolicy);
      if (serializedCancellationPolicy != null) {
        data['cancellationPolicy'] = serializedCancellationPolicy;
      }

      final response = await _client.put(
        '/api/v1/provider/services/$serviceId',
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(_parseService(response.data['data']));
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to update service',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> deleteService(String serviceId) async {
    try {
      final response =
          await _client.delete('/api/v1/provider/services/$serviceId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.fail(
        response.data['message'] ?? 'Failed to delete service',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PARSERS
  // ═══════════════════════════════════════════════════════════

  static ProviderDashboardStats _parseProviderDashboard(
      Map<String, dynamic> json) {
    return ProviderDashboardStats(
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: _parseDouble(json['totalRevenue']),
      pendingBookings: json['pendingBookings'] ?? 0,
      averageRating: _parseDouble(json['averageRating']),
      completedBookings: json['completedBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      bookingsByServiceType:
          _parseProviderBookingsByType(json['bookingsByType']),
    );
  }

  static Map<String, int> _parseProviderBookingsByType(dynamic data) {
    if (data is! List) return const {};

    final result = <String, int>{};
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final key = (item['serviceId'] ?? item['serviceType'] ?? '').toString();
      if (key.isEmpty) continue;
      final countData = item['_count'];
      final count = countData is Map<String, dynamic> ? countData['id'] : null;
      result[key] = count is int ? count : 0;
    }
    return result;
  }

  static BookingModel _parseProviderBooking(Map<String, dynamic> json) {
    final bookingJson =
        (json['booking'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final consumerJson = (bookingJson['consumer'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final serviceJson =
        (json['service'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final bookingItem = BookingItem(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? bookingJson['id'] ?? '',
      serviceId: json['serviceId'] ?? serviceJson['id'] ?? '',
      providerId: json['providerId'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : (bookingJson['eventDate'] != null
              ? DateTime.parse(bookingJson['eventDate'])
              : DateTime.now()),
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
      durationHours: _parseDouble(json['durationHours'], defaultValue: 1),
      unitPrice: _parseDouble(json['unitPrice'] ?? json['subtotal']),
      subtotal: _parseDouble(json['subtotal'] ?? json['unitPrice']),
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] ?? '').toString(),
        orElse: () => BookingStatus.pending,
      ),
      specialRequests:
          json['specialRequests'] ?? bookingJson['specialRequests'],
      service: serviceJson.isNotEmpty
          ? ServiceModel(
              id: serviceJson['id'] ?? json['serviceId'] ?? '',
              providerId: json['providerId'] ?? '',
              title: serviceJson['title'] ?? '',
              description: serviceJson['description'],
              serviceType: ServiceType.values.firstWhere(
                (e) =>
                    e.name.toUpperCase() ==
                    (serviceJson['serviceType'] ?? '').toString(),
                orElse: () => ServiceType.hall,
              ),
              basePrice: _parseDouble(json['unitPrice'] ?? json['subtotal']),
              currency: bookingJson['currency'] ?? 'USD',
              attributes: const ServiceAttributes(),
              isAvailable: true,
            )
          : null,
    );

    final createdAt = json['createdAt'] ?? bookingJson['createdAt'];
    final updatedAt = json['updatedAt'] ?? bookingJson['updatedAt'];

    return BookingModel(
      id: bookingItem.id,
      consumerId: consumerJson['id'] ?? bookingJson['consumerId'] ?? '',
      eventType: bookingJson['eventType'] ?? 'event',
      eventDate: bookingJson['eventDate'] != null
          ? DateTime.parse(bookingJson['eventDate'])
          : bookingItem.date,
      eventName: bookingJson['eventName'] ?? serviceJson['title'],
      status: bookingItem.status,
      totalAmount: bookingItem.subtotal,
      currency: bookingJson['currency'] ?? 'USD',
      depositAmount: _parseDouble(bookingJson['depositAmount']),
      depositPaid: bookingJson['depositPaid'] ?? false,
      items: [bookingItem],
      notes: consumerJson['fullName'],
      specialRequests: bookingItem.specialRequests,
      createdAt: createdAt != null ? DateTime.parse(createdAt) : null,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
    );
  }

  static ServiceModel _parseService(Map<String, dynamic> json) {
    final provider = json['provider'];
    return ServiceModel(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['serviceType'],
        orElse: () => ServiceType.hall,
      ),
      basePrice: _parseDouble(json['basePrice']),
      currency: json['currency'] ?? 'USD',
      pricingModel: PricingModel.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['pricingModel'] ?? '').toString(),
        orElse: () => PricingModel.flat,
      ),
      images: DioClient.normalizeMediaUrls(json['images']),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      attributes: _parseServiceAttributes(json['attributes'] ?? {}),
      maxCapacity: json['maxCapacity'],
      minDurationHours: _parseDouble(json['minDurationHours'], defaultValue: 1),
      maxDurationHours: json['maxDurationHours'] != null
          ? _parseDouble(json['maxDurationHours'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      provider: provider != null ? _parseProvider(provider) : null,
      cancellationPolicy: _parseCancellationPolicy(json['cancellationPolicy']),
      pricingRules: (json['pricingRules'] as List<dynamic>?)
              ?.map((r) => _parsePricingRule(r))
              .toList() ??
          [],
    );
  }

  static ServiceAttributes _parseServiceAttributes(Map<String, dynamic> json) {
    return ServiceAttributes(
      capacity: json['capacity'],
      hasStage: json['hasStage'],
      hasParking: json['hasParking'],
      hasKitchen: json['hasKitchen'],
      theme: json['theme'],
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      carType: json['carType'],
      maxPassengers: json['maxPassengers'],
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      portfolioUrl: json['portfolioUrl'],
      specialties:
          (json['specialties'] as List<dynamic>?)?.cast<String>() ?? [],
      equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      editingIncluded: json['editingIncluded'],
      performerType: json['performerType'],
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      sampleVideoUrl: json['sampleVideoUrl'],
      groupSize: json['groupSize'],
    );
  }

  static ProviderModel _parseProvider(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      businessName: json['businessName'] ?? '',
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['serviceType'],
        orElse: () => ServiceType.hall,
      ),
      rating: _parseDouble(json['rating']),
      reviewCount: json['reviewCount'] ?? 0,
      city: json['city'],
      logoUrl: DioClient.normalizeMediaUrl(json['logoUrl']?.toString()),
      coverUrl: DioClient.normalizeMediaUrl(json['coverUrl']?.toString()),
      isVerified: json['isVerified'] ?? false,
    );
  }

  static TimeSlot _parseTimeSlot(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: _parseTimeString(json['startTime']),
      endTime: _parseTimeString(json['endTime']),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  static BookingModel _parseBooking(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      consumerId: json['consumerId'] ?? '',
      eventType: json['eventType'] ?? '',
      eventDate: DateTime.parse(json['eventDate']),
      eventName: json['eventName'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalAmount: _parseDouble(json['totalAmount']),
      currency: json['currency'] ?? 'USD',
      depositAmount: _parseDouble(json['depositAmount']),
      depositPaid: json['depositPaid'] ?? false,
      specialRequests: json['specialRequests'],
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => _parseBookingItem(i))
              .toList() ??
          const [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  static BookingItem _parseBookingItem(Map<String, dynamic> json) {
    final service =
        json['service'] != null ? _parseService(json['service']) : null;
    final provider = json['provider'] != null
        ? _parseProvider(json['provider'])
        : service?.provider;

    return BookingItem(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      providerId: json['providerId'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
      durationHours: _parseDouble(json['durationHours'], defaultValue: 1),
      unitPrice: _parseDouble(json['unitPrice']),
      subtotal: _parseDouble(json['subtotal']),
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: json['specialRequests'],
      service: service,
      provider: provider,
    );
  }

  static PaymentModel _parsePayment(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      amount: _parseDouble(json['amount']),
      currency: json['currency'] ?? 'USD',
      paymentMethod: json['paymentMethod'] ?? 'CARD',
      status: PaymentStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static ReviewModel _parseReview(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      bookingItemId: json['bookingItemId'],
      consumerId: json['consumerId'] ?? '',
      providerId: json['providerId'] ?? '',
      rating: json['rating'],
      comment: json['comment'],
      images: DioClient.normalizeMediaUrls(json['images']),
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static CancellationPolicy _parseCancellationPolicy(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const CancellationPolicy();
    }

    return CancellationPolicy(
      freeCancellationHours: data['freeCancellationHours'] ?? 72,
      partialRefundPercentage: _parseDouble(
        data['partialRefundPercentage'],
        defaultValue: 50,
      ),
      depositRefundable: data['depositRefundable'] ?? false,
      description: data['description'],
    );
  }

  static NotificationModel _parseNotification(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: _normalizeNotificationType(json['type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: rawData is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawData)
          : const {},
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static PricingRuleModel _parsePricingRule(Map<String, dynamic> json) {
    return PricingRuleModel(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      ruleType: PricingRuleType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['ruleType'],
        orElse: () => PricingRuleType.weekend,
      ),
      multiplier: _parseDouble(json['multiplier']),
      fixedAdjustment: _parseDouble(json['fixedAdjustment']),
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      dayOfWeek: json['dayOfWeek'],
      minAdvanceDays: json['minAdvanceDays'],
      minBookings: json['minBookings'],
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  static AvailabilityTemplateModel _parseAvailabilityTemplate(
      Map<String, dynamic> json) {
    return AvailabilityTemplateModel(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      dayOfWeek: json['dayOfWeek'],
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  static UserPreferences _parseUserPreferences(Map<String, dynamic> json) {
    final budgetRange = json['budgetRange'];
    return UserPreferences(
      preferredHallThemes:
          (json['preferredHallThemes'] as List<dynamic>?)?.cast<String>() ?? [],
      preferredCarTypes:
          (json['preferredCarTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      preferredPhotographerStyles:
          (json['preferredPhotographerStyles'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
      preferredEntertainerTypes:
          (json['preferredEntertainerTypes'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
      budgetRange: budgetRange != null
          ? BudgetRange(
              min: _parseDouble(budgetRange['min']),
              max: budgetRange['max'] != null
                  ? _parseDouble(budgetRange['max'])
                  : double.infinity,
            )
          : const BudgetRange(),
      preferredCities:
          (json['preferredCities'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  static TimeOfDay _parseTimeString(String timeStr) {
    final match = RegExp(r'(\d{2}):(\d{2})').firstMatch(timeStr);
    if (match == null) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  static TimeOfDay _parseTimeOfDay(dynamic time) {
    if (time is String) {
      return _parseTimeString(time);
    }
    if (time is DateTime) {
      return TimeOfDay(hour: time.hour, minute: time.minute);
    }
    if (time is Map<String, dynamic>) {
      return TimeOfDay(
        hour: time['hour'] ?? 0,
        minute: time['minute'] ?? 0,
      );
    }
    return const TimeOfDay(hour: 0, minute: 0);
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static UserRole _parseUserRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'provider':
        return UserRole.provider;
      case 'admin':
        return UserRole.admin;
      case 'consumer':
      default:
        return UserRole.consumer;
    }
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static String _normalizeNotificationType(dynamic value) {
    return value?.toString().toLowerCase().replaceAll('-', '_') ?? '';
  }

  // ═══════════════════════════════════════════════════════════
  // SERIALIZATION HELPERS (for sending data to backend)
  // ═══════════════════════════════════════════════════════════

  static Map<String, dynamic> _serializeGenericAttributes(
      ServiceAttributes attrs) {
    // Serialize all non-null attributes for updates
    final result = <String, dynamic>{};
    if (attrs.capacity != null) {
      result['capacity'] = attrs.capacity;
    }
    if (attrs.hasStage != null) {
      result['hasStage'] = attrs.hasStage;
    }
    if (attrs.hasParking != null) {
      result['hasParking'] = attrs.hasParking;
    }
    if (attrs.hasKitchen != null) {
      result['hasKitchen'] = attrs.hasKitchen;
    }
    if (attrs.theme != null) {
      result['theme'] = attrs.theme;
    }
    if (attrs.amenities.isNotEmpty) {
      result['amenities'] = attrs.amenities;
    }
    if (attrs.make != null) {
      result['make'] = attrs.make;
    }
    if (attrs.model != null) {
      result['model'] = attrs.model;
    }
    if (attrs.year != null) {
      result['year'] = attrs.year;
    }
    if (attrs.color != null) {
      result['color'] = attrs.color;
    }
    if (attrs.carType != null) {
      result['carType'] = attrs.carType;
    }
    if (attrs.maxPassengers != null) {
      result['maxPassengers'] = attrs.maxPassengers;
    }
    if (attrs.features.isNotEmpty) {
      result['features'] = attrs.features;
    }
    if (attrs.portfolioUrl != null) {
      result['portfolioUrl'] = attrs.portfolioUrl;
    }
    if (attrs.specialties.isNotEmpty) {
      result['specialties'] = attrs.specialties;
    }
    if (attrs.equipment.isNotEmpty) {
      result['equipment'] = attrs.equipment;
    }
    if (attrs.editingIncluded != null) {
      result['editingIncluded'] = attrs.editingIncluded;
    }
    if (attrs.performerType != null) {
      result['performerType'] = attrs.performerType;
    }
    if (attrs.genres.isNotEmpty) {
      result['genres'] = attrs.genres;
    }
    if (attrs.sampleVideoUrl != null) {
      result['sampleVideoUrl'] = attrs.sampleVideoUrl;
    }
    if (attrs.groupSize != null) {
      result['groupSize'] = attrs.groupSize;
    }
    return result;
  }

  static Map<String, dynamic>? _serializeCancellationPolicy(
      CancellationPolicy? policy) {
    if (policy == null) return null;

    final result = <String, dynamic>{
      'freeCancellationHours': policy.freeCancellationHours,
      'partialRefundPercentage': policy.partialRefundPercentage,
      'depositRefundable': policy.depositRefundable,
    };

    final description = policy.description?.trim();
    if (description != null && description.isNotEmpty) {
      result['description'] = description;
    }

    return result;
  }
}
