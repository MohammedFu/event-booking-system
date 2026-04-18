import 'package:flutter/material.dart';
import 'package:shop/models/booking_models.dart';
import 'package:shop/models/demo_booking_data.dart';

// API service layer with mock responses for development.
// When backend is ready, swap mock implementations with real Dio calls.

class ApiService {
  static const String baseUrl = 'https://api.eventbooker.com/v1';
  static const Duration defaultTimeout = Duration(seconds: 10);

  // Simulate network delay
  Future<T> _mockDelay<T>(T Function() callback) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return callback();
  }

  // ═══════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<AuthTokens>> login({
    required String email,
    required String password,
  }) async {
    return _mockDelay(() {
      if (email.isEmpty || password.isEmpty) {
        return ApiResponse.fail('Invalid credentials', statusCode: 401);
      }
      return ApiResponse.ok(AuthTokens(
        accessToken:
            'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock_refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
    });
  }

  Future<ApiResponse<AuthTokens>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return _mockDelay(() {
      return ApiResponse.ok(AuthTokens(
        accessToken: 'mock_access_token_new',
        refreshToken: 'mock_refresh_token_new',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
    });
  }

  Future<ApiResponse<AuthTokens>> refreshToken(String refreshToken) async {
    return _mockDelay(() {
      return ApiResponse.ok(AuthTokens(
        accessToken: 'mock_access_token_refreshed',
        refreshToken: refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ));
    });
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    return _mockDelay(() => ApiResponse.ok(null));
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
    return _mockDelay(() {
      var services = type != null
          ? allDemoServices.where((s) => s.serviceType == type).toList()
          : allDemoServices;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        services = services
            .where((s) =>
                s.title.toLowerCase().contains(query) ||
                s.description?.toLowerCase().contains(query) == true ||
                s.tags.any((t) => t.toLowerCase().contains(query)))
            .toList();
      }

      if (minPrice != null) {
        services = services.where((s) => s.basePrice >= minPrice).toList();
      }
      if (maxPrice != null) {
        services = services.where((s) => s.basePrice <= maxPrice).toList();
      }
      if (minRating != null) {
        services = services
            .where((s) => (s.provider?.rating ?? 0) >= minRating)
            .toList();
      }
      if (city != null) {
        services = services
            .where((s) => s.provider?.city?.toLowerCase() == city.toLowerCase())
            .toList();
      }

      switch (sortBy) {
        case 'price_low':
          services.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        case 'price_high':
          services.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        case 'rating':
          services.sort((a, b) =>
              (b.provider?.rating ?? 0).compareTo(a.provider?.rating ?? 0));
        case 'reviews':
          services.sort((a, b) => (b.provider?.reviewCount ?? 0)
              .compareTo(a.provider?.reviewCount ?? 0));
      }

      return ApiResponse.ok(services, meta: {
        'page': page,
        'limit': limit,
        'total': services.length,
      });
    });
  }

  Future<ApiResponse<ServiceModel>> getServiceById(String id) async {
    return _mockDelay(() {
      try {
        final service = allDemoServices.firstWhere((s) => s.id == id);
        return ApiResponse.ok(service);
      } catch (_) {
        return ApiResponse.fail('Service not found', statusCode: 404);
      }
    });
  }

  Future<ApiResponse<List<TimeSlot>>> getServiceAvailability(
    String serviceId,
    DateTime date,
  ) async {
    return _mockDelay(() {
      final slots = <TimeSlot>[];
      for (int hour = 8; hour <= 20; hour++) {
        final isBooked = hour == 14 || hour == 16;
        slots.add(TimeSlot(
          id: 'slot-$serviceId-$date-$hour',
          serviceId: serviceId,
          date: date,
          startTime: TimeOfDay(hour: hour, minute: 0),
          endTime: TimeOfDay(hour: hour + 1, minute: 0),
          isAvailable: !isBooked,
        ));
      }
      return ApiResponse.ok(slots);
    });
  }

  Future<ApiResponse<List<ServiceModel>>> searchServices(String query) async {
    return _mockDelay(() {
      final q = query.toLowerCase();
      final results = allDemoServices
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.description?.toLowerCase().contains(q) == true ||
              s.tags.any((t) => t.toLowerCase().contains(q)) ||
              s.serviceTypeLabel.toLowerCase().contains(q))
          .toList();
      return ApiResponse.ok(results);
    });
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
    await Future.delayed(const Duration(seconds: 2));

    final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    final booking = BookingModel(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      consumerId: consumerId,
      eventType: eventType,
      eventDate: eventDate,
      eventName: eventName ?? 'Event',
      status: BookingStatus.pending,
      totalAmount: totalAmount,
      depositAmount: totalAmount * 0.25,
      depositPaid: true,
      items: cartItems
          .map((item) => BookingItem(
                id: 'item-${DateTime.now().millisecondsSinceEpoch}-${item.service.id}',
                bookingId: 'booking-${DateTime.now().millisecondsSinceEpoch}',
                serviceId: item.service.id,
                providerId: item.service.providerId,
                date: item.date,
                startTime: item.startTime,
                endTime: item.endTime,
                durationHours: item.durationHours,
                unitPrice: item.service.basePrice,
                subtotal: item.subtotal,
                status: BookingStatus.pending,
                specialRequests: item.specialRequests,
                service: item.service,
                provider: item.service.provider,
              ))
          .toList(),
      specialRequests: specialRequests,
    );

    return ApiResponse.ok(booking);
  }

  Future<ApiResponse<List<BookingModel>>> getBookings({
    required String consumerId,
    BookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return _mockDelay(() {
      var bookings = List<BookingModel>.from(demoBookings);
      if (status != null) {
        bookings = bookings.where((b) => b.status == status).toList();
      }
      return ApiResponse.ok(bookings, meta: {
        'page': page,
        'limit': limit,
        'total': bookings.length,
      });
    });
  }

  Future<ApiResponse<BookingModel>> getBookingById(String id) async {
    return _mockDelay(() {
      try {
        final booking = demoBookings.firstWhere((b) => b.id == id);
        return ApiResponse.ok(booking);
      } catch (_) {
        return ApiResponse.fail('Booking not found', statusCode: 404);
      }
    });
  }

  Future<ApiResponse<void>> cancelBooking(String id) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }

  // ═══════════════════════════════════════════════════════════
  // PAYMENTS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
  }) async {
    return _mockDelay(() {
      return ApiResponse.ok({
        'client_secret':
            'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret',
        'payment_intent_id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': currency,
      });
    });
  }

  Future<ApiResponse<PaymentModel>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    return _mockDelay(() {
      return ApiResponse.ok(PaymentModel(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        bookingId: 'booking-1',
        amount: 3200,
        paymentMethod: paymentMethod,
        status: PaymentStatus.succeeded,
      ));
    });
  }

  // ═══════════════════════════════════════════════════════════
  // REVIEWS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<ReviewModel>>> getServiceReviews(
    String serviceId, {
    int page = 1,
    int limit = 20,
  }) async {
    return _mockDelay(() {
      final reviews = [
        ReviewModel(
          id: 'review-1',
          bookingItemId: 'item-1',
          consumerId: 'user-1',
          providerId: serviceId,
          rating: 5,
          comment:
              'Absolutely amazing service! Everything was perfect for our wedding.',
          isAnonymous: false,
        ),
        ReviewModel(
          id: 'review-2',
          bookingItemId: 'item-2',
          consumerId: 'user-2',
          providerId: serviceId,
          rating: 4,
          comment: 'Great experience overall. Very professional team.',
          isAnonymous: false,
        ),
        ReviewModel(
          id: 'review-3',
          bookingItemId: 'item-3',
          consumerId: 'user-3',
          providerId: serviceId,
          rating: 5,
          comment: 'Exceeded our expectations. Would definitely book again!',
          isAnonymous: true,
        ),
      ];
      return ApiResponse.ok(reviews);
    });
  }

  Future<ApiResponse<ReviewModel>> submitReview({
    required String bookingItemId,
    required String providerId,
    required int rating,
    String? comment,
    List<String>? images,
    bool isAnonymous = false,
  }) async {
    return _mockDelay(() {
      return ApiResponse.ok(ReviewModel(
        id: 'review-${DateTime.now().millisecondsSinceEpoch}',
        bookingItemId: bookingItemId,
        consumerId: 'user-consumer-1',
        providerId: providerId,
        rating: rating,
        comment: comment,
        images: images ?? [],
        isAnonymous: isAnonymous,
      ));
    });
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<NotificationModel>>> getNotifications({
    required String userId,
    bool? unreadOnly,
    int page = 1,
    int limit = 20,
  }) async {
    return _mockDelay(() {
      final notifications = [
        NotificationModel(
          id: 'notif-1',
          userId: userId,
          type: 'booking_confirmed',
          title: 'Booking Confirmed',
          body: 'Your booking for Grand Ballroom Palace has been confirmed!',
        ),
        NotificationModel(
          id: 'notif-2',
          userId: userId,
          type: 'payment_received',
          title: 'Payment Received',
          body: 'Deposit of \$3,200 received for your wedding booking.',
        ),
        NotificationModel(
          id: 'notif-3',
          userId: userId,
          type: 'reminder',
          title: 'Upcoming Event',
          body:
              'Your wedding event is in 7 days. Don\'t forget to confirm details!',
        ),
        NotificationModel(
          id: 'notif-4',
          userId: userId,
          type: 'review_request',
          title: 'Leave a Review',
          body:
              'How was your experience with Grand Ballroom Palace? Leave a review!',
          isRead: true,
        ),
        NotificationModel(
          id: 'notif-5',
          userId: userId,
          type: 'price_drop',
          title: 'Special Offer',
          body:
              'Weekend discount available on Luxury Limo! Book now and save 15%.',
        ),
      ];
      var filtered = notifications;
      if (unreadOnly == true) {
        filtered = filtered.where((n) => !n.isRead).toList();
      }
      return ApiResponse.ok(filtered);
    });
  }

  Future<ApiResponse<void>> markNotificationRead(String notificationId) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }

  Future<ApiResponse<void>> markAllNotificationsRead(String userId) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }

  // ═══════════════════════════════════════════════════════════
  // PROVIDER DASHBOARD
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<ProviderDashboardStats>> getProviderDashboard() async {
    return _mockDelay(() {
      return ApiResponse.ok(const ProviderDashboardStats(
        totalBookings: 48,
        totalRevenue: 24500,
        pendingBookings: 5,
        averageRating: 4.8,
        completedBookings: 38,
        cancelledBookings: 5,
        revenueByMonth: {
          'Jan': 1800,
          'Feb': 2200,
          'Mar': 3100,
          'Apr': 2800,
          'May': 3500,
          'Jun': 4200,
        },
        bookingsByServiceType: {
          'hall': 20,
          'car': 12,
          'photographer': 10,
          'entertainer': 6,
        },
      ));
    });
  }

  Future<ApiResponse<List<BookingModel>>> getProviderBookings({
    BookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return _mockDelay(() {
      var bookings = List<BookingModel>.from(demoBookings);
      if (status != null) {
        bookings = bookings.where((b) => b.status == status).toList();
      }
      return ApiResponse.ok(bookings);
    });
  }

  Future<ApiResponse<BookingItem>> updateBookingItemStatus({
    required String bookingItemId,
    required BookingStatus status,
  }) async {
    return _mockDelay(() {
      return ApiResponse.ok(BookingItem(
        id: bookingItemId,
        bookingId: 'booking-1',
        serviceId: 'hall-1',
        providerId: 'prov-1',
        date: DateTime.now(),
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 0),
        durationHours: 7,
        unitPrice: 5000,
        subtotal: 5000,
        status: status,
      ));
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BOOKMARKS
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<ServiceModel>>> getBookmarkedServices(
      String userId) async {
    return _mockDelay(() {
      return ApiResponse.ok(allDemoServices.take(3).toList());
    });
  }

  Future<ApiResponse<void>> addBookmark(String serviceId) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }

  Future<ApiResponse<void>> removeBookmark(String serviceId) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }

  // ═══════════════════════════════════════════════════════════
  // USER PREFERENCES
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<UserPreferences>> getUserPreferences() async {
    return _mockDelay(() {
      return ApiResponse.ok(const UserPreferences(
        preferredHallThemes: ['Modern', 'Classic'],
        preferredCarTypes: ['Luxury', 'Vintage'],
        preferredPhotographerStyles: ['Documentary', 'Traditional'],
        preferredEntertainerTypes: ['DJ', 'Live Band'],
        budgetRange: BudgetRange(min: 5000, max: 20000),
        preferredCities: ['New York', 'Los Angeles'],
      ));
    });
  }

  Future<ApiResponse<UserPreferences>> updateUserPreferences(
      UserPreferences preferences) async {
    return _mockDelay(() => ApiResponse.ok(preferences));
  }

  // ═══════════════════════════════════════════════════════════
  // AVAILABILITY TEMPLATES (Provider)
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<AvailabilityTemplateModel>>> getAvailabilityTemplates(
      String serviceId) async {
    return _mockDelay(() {
      return ApiResponse.ok([
        AvailabilityTemplateModel(
          id: 'avail-1',
          serviceId: serviceId,
          dayOfWeek: 1,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-2',
          serviceId: serviceId,
          dayOfWeek: 2,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-3',
          serviceId: serviceId,
          dayOfWeek: 3,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-4',
          serviceId: serviceId,
          dayOfWeek: 4,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-5',
          serviceId: serviceId,
          dayOfWeek: 5,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-6',
          serviceId: serviceId,
          dayOfWeek: 6,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 0),
        ),
        AvailabilityTemplateModel(
          id: 'avail-7',
          serviceId: serviceId,
          dayOfWeek: 0,
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 20, minute: 0),
          isAvailable: false,
        ),
      ]);
    });
  }

  Future<ApiResponse<AvailabilityTemplateModel>> updateAvailabilityTemplate(
      AvailabilityTemplateModel template) async {
    return _mockDelay(() => ApiResponse.ok(template));
  }

  // ═══════════════════════════════════════════════════════════
  // PRICING RULES (Provider)
  // ═══════════════════════════════════════════════════════════

  Future<ApiResponse<List<PricingRuleModel>>> getPricingRules(
      String serviceId) async {
    return _mockDelay(() {
      return ApiResponse.ok([
        PricingRuleModel(
          id: 'pr-1',
          serviceId: serviceId,
          ruleType: PricingRuleType.weekend,
          multiplier: 1.2,
          priority: 1,
        ),
        PricingRuleModel(
          id: 'pr-2',
          serviceId: serviceId,
          ruleType: PricingRuleType.seasonal,
          multiplier: 1.5,
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 9, 30),
          priority: 2,
        ),
        PricingRuleModel(
          id: 'pr-3',
          serviceId: serviceId,
          ruleType: PricingRuleType.earlyBird,
          multiplier: 0.9,
          minAdvanceDays: 60,
          priority: 3,
        ),
      ]);
    });
  }

  Future<ApiResponse<PricingRuleModel>> createPricingRule(
      PricingRuleModel rule) async {
    return _mockDelay(() => ApiResponse.ok(rule));
  }

  Future<ApiResponse<PricingRuleModel>> updatePricingRule(
      PricingRuleModel rule) async {
    return _mockDelay(() => ApiResponse.ok(rule));
  }

  Future<ApiResponse<void>> deletePricingRule(String ruleId) async {
    return _mockDelay(() => ApiResponse.ok(null));
  }
}
