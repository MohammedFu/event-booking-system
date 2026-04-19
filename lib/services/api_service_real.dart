import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'dio_client.dart';

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

  Future<ApiResponse<AuthTokens>> login({
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
        response.data['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<AuthTokens>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.post('/api/v1/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];

        // Save tokens
        await _client.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
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
        response.data['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.fail(e.toString());
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final refreshToken = await _client.getAccessToken();

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
    required String consumerId,
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
        'eventDate': eventDate.toIso8601String(),
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

  Future<ApiResponse<void>> markAllNotificationsRead(String userId) async {
    try {
      final response =
          await _client.patch('/api/v1/users/notifications/read-all');

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
  // PARSERS
  // ═══════════════════════════════════════════════════════════

  static ServiceModel _parseService(Map<String, dynamic> json) {
    final provider = json['provider'];
    return ServiceModel(
      id: json['id'],
      providerId: json['providerId'],
      title: json['title'],
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['serviceType'],
        orElse: () => ServiceType.hall,
      ),
      basePrice: (json['basePrice'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      attributes: _parseServiceAttributes(json['attributes'] ?? {}),
      maxCapacity: json['maxCapacity'],
      minDurationHours: json['minDurationHours']?.toDouble() ?? 1,
      maxDurationHours: json['maxDurationHours']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      provider: provider != null ? _parseProvider(provider) : null,
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
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['serviceType'],
        orElse: () => ServiceType.hall,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] ?? 0,
      city: json['city'],
      logoUrl: json['logoUrl'],
      coverUrl: json['coverUrl'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  static TimeSlot _parseTimeSlot(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      serviceId: json['serviceId'],
      date: DateTime.parse(json['date']),
      startTime: _parseTimeString(json['startTime']),
      endTime: _parseTimeString(json['endTime']),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  static BookingModel _parseBooking(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      consumerId: json['consumerId'],
      eventType: json['eventType'],
      eventDate: DateTime.parse(json['eventDate']),
      eventName: json['eventName'],
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
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
    return BookingItem(
      id: json['id'],
      bookingId: json['bookingId'],
      serviceId: json['serviceId'],
      providerId: json['providerId'],
      date: DateTime.parse(json['date']),
      startTime: _parseTimeOfDay(json['startTime']),
      endTime: _parseTimeOfDay(json['endTime']),
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: json['specialRequests'],
      service: json['service'] != null ? _parseService(json['service']) : null,
      provider:
          json['provider'] != null ? _parseProvider(json['provider']) : null,
    );
  }

  static PaymentModel _parsePayment(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      bookingId: json['bookingId'],
      amount: (json['amount'] as num).toDouble(),
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
      id: json['id'],
      bookingItemId: json['bookingItemId'],
      consumerId: json['consumerId'],
      providerId: json['providerId'],
      rating: json['rating'],
      comment: json['comment'],
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static NotificationModel _parseNotification(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      data: json['data'] ?? {},
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static PricingRuleModel _parsePricingRule(Map<String, dynamic> json) {
    return PricingRuleModel(
      id: json['id'],
      serviceId: json['serviceId'],
      ruleType: PricingRuleType.values.firstWhere(
        (e) => e.name.toUpperCase() == json['ruleType'],
        orElse: () => PricingRuleType.weekend,
      ),
      multiplier: (json['multiplier'] as num).toDouble(),
      fixedAdjustment: (json['fixedAdjustment'] as num?)?.toDouble() ?? 0,
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
      id: json['id'],
      serviceId: json['serviceId'],
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
              min: (budgetRange['min'] as num?)?.toDouble() ?? 0,
              max: (budgetRange['max'] as num?)?.toDouble() ?? double.infinity,
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
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static TimeOfDay _parseTimeOfDay(dynamic time) {
    if (time is String) {
      return _parseTimeString(time);
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
}
