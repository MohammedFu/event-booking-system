import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/booking_cache_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider() {
    unawaited(_restoreLocalState());
  }

  bool _notificationScheduled = false;

  @override
  void notifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer = phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks;

    if (!shouldDefer) {
      super.notifyListeners();
      return;
    }

    if (_notificationScheduled) {
      return;
    }

    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (hasListeners) {
        super.notifyListeners();
      }
    });
  }

  final ApiServiceReal _api = ApiServiceReal();
  final BookingCacheService _cache = BookingCacheService();
  AuthProvider? _authProvider;
  String? _boundUserId;

  // Booking cart items
  final List<BookingCartItem> _cartItems = [];
  List<BookingCartItem> get cartItems => List.unmodifiable(_cartItems);

  // User bookings
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  // Provider bookings
  List<BookingModel> _providerBookings = [];
  List<BookingModel> get providerBookings =>
      List.unmodifiable(_providerBookings);

  // Services from API
  List<ServiceModel> _services = [];
  List<ServiceModel> get services => List.unmodifiable(_services);

  // Provider services from API
  List<ServiceModel> _providerServices = [];
  List<ServiceModel> get providerServices =>
      List.unmodifiable(_providerServices);

  // Provider dashboard stats
  ProviderDashboardStats _providerDashboard = const ProviderDashboardStats();
  ProviderDashboardStats get providerDashboard => _providerDashboard;

  // Bookmarked services
  List<ServiceModel> _bookmarkedServices = [];
  List<ServiceModel> get bookmarkedServices =>
      List.unmodifiable(_bookmarkedServices);

  final Set<String> _bookmarkedServiceIds = {};
  Set<String> get bookmarkedServiceIds =>
      Set.unmodifiable(_bookmarkedServiceIds);

  // Selected event date
  DateTime? _selectedEventDate;
  DateTime? get selectedEventDate => _selectedEventDate;

  // Selected event type
  String _eventType = 'wedding';
  String get eventType => _eventType;

  // User preferences
  UserPreferences _preferences = const UserPreferences();
  UserPreferences get preferences => _preferences;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _error;
  String? get error => _error;

  BookingModel? _lastCreatedBooking;
  BookingModel? get lastCreatedBooking => _lastCreatedBooking;

  // Cart total
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  int get cartItemCount => _cartItems.length;

  bool get isAuthenticated => _authProvider?.isAuthenticated ?? false;

  void bindAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    final nextUserId =
        authProvider.isAuthenticated ? authProvider.user?.id : null;
    if (_boundUserId == nextUserId) return;

    _boundUserId = nextUserId;
    if (nextUserId == null) {
      _clearUserScopedState();
      return;
    }

    unawaited(refreshUserScopedState());
  }

  bool hasServiceTypeInCart(ServiceType type) {
    return _cartItems.any((item) => item.service.serviceType == type);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setEventDate(DateTime date) {
    _selectedEventDate = date;
    notifyListeners();
    unawaited(_persistCartState());
  }

  void setEventType(String type) {
    _eventType = type;
    notifyListeners();
    unawaited(_persistCartState());
  }

  void addToCart(BookingCartItem item) {
    // Check for conflicts
    final hasConflict =
        _cartItems.any((existing) => _hasTimeConflict(existing, item));

    if (hasConflict) {
      return; // Don't add conflicting items
    }

    // Replace if same service type and same service
    final existingIndex =
        _cartItems.indexWhere((e) => e.service.id == item.service.id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex] = item;
    } else {
      _cartItems.add(item);
    }

    _selectedEventDate ??= item.date;
    notifyListeners();
    unawaited(_persistCartState());
  }

  void removeFromCart(String serviceId) {
    _cartItems.removeWhere((item) => item.service.id == serviceId);
    _selectedEventDate = _cartItems.isEmpty ? null : _cartItems.first.date;
    notifyListeners();
    unawaited(_persistCartState());
  }

  void clearCart() {
    _cartItems.clear();
    _selectedEventDate = null;
    notifyListeners();
    unawaited(_persistCartState());
  }

  bool _hasTimeConflict(BookingCartItem a, BookingCartItem b) {
    if (a.date != b.date) return false;

    final aStart = a.startTime.hour * 60 + a.startTime.minute;
    final aEnd = a.endTime.hour * 60 + a.endTime.minute;
    final bStart = b.startTime.hour * 60 + b.startTime.minute;
    final bEnd = b.endTime.hour * 60 + b.endTime.minute;

    return aStart < bEnd && bStart < aEnd;
  }

  List<String> getCartConflicts(BookingCartItem newItem) {
    final conflicts = <String>[];
    for (final item in _cartItems) {
      if (_hasTimeConflict(item, newItem)) {
        conflicts.add('${item.service.title} (${item.timeLabel})');
      }
    }
    return conflicts;
  }

  Future<void> refreshUserScopedState() async {
    if (!isAuthenticated) {
      _clearUserScopedState();
      return;
    }

    await Future.wait([
      fetchBookmarks(silent: true),
      fetchUserPreferences(silent: true),
    ]);
  }

  Future<bool> createBooking({
    String? eventName,
    String? specialRequests,
  }) async {
    final user = _authProvider?.user;
    final eventDate = _selectedEventDate ??
        (_cartItems.isNotEmpty ? _cartItems.first.date : null);

    if (user == null || !isAuthenticated) {
      _error = 'Please sign in to continue.';
      notifyListeners();
      return false;
    }

    if (eventDate == null || _cartItems.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.createBooking(
      eventType: _eventType,
      eventDate: eventDate,
      eventName: eventName,
      cartItems: _cartItems,
      specialRequests: specialRequests,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _lastCreatedBooking = response.data!;
      _bookings.insert(0, response.data!);
      _cartItems.clear();
      _selectedEventDate = null;
      unawaited(_persistCartState());
      unawaited(
        _cache.cacheBookings(
          _cache.consumerBookingsKey(user.id),
          _bookings,
        ),
      );
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'error_create_booking';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchBookings({BookingStatus? status}) async {
    final userId = _authProvider?.user?.id;
    if (!isAuthenticated || userId == null) {
      _bookings = [];
      _error = 'Please sign in to view your bookings.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getBookings(status: status?.name);
    final cacheKey = _cache.consumerBookingsKey(userId, status: status);

    _isLoading = false;

    if (response.success && response.data != null) {
      _bookings = response.data!;
      _error = null;
      unawaited(_cache.cacheBookings(cacheKey, _bookings));
    } else {
      final cachedBookings = await _cache.getBookings(cacheKey);
      if (cachedBookings != null) {
        _bookings = cachedBookings;
        _error = null;
      } else {
        _error = response.error ?? 'error_fetch_bookings';
      }
    }
    notifyListeners();
  }

  Future<void> fetchProviderDashboardData() async {
    final userId = _authProvider?.user?.id;
    if (_authProvider?.user?.role != UserRole.provider || userId == null) {
      _providerDashboard = const ProviderDashboardStats();
      _providerBookings = [];
      _error = 'Provider access is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final dashboardResponse = await _api.getProviderDashboard();
    final bookingsResponse = await _api.getProviderBookings(limit: 20);

    _isLoading = false;
    String? nextError;

    if (dashboardResponse.success && dashboardResponse.data != null) {
      _providerDashboard = dashboardResponse.data!;
      unawaited(_cache.cacheDashboard(userId, _providerDashboard));
    } else {
      final cachedDashboard = await _cache.getDashboard(userId);
      if (cachedDashboard != null) {
        _providerDashboard = cachedDashboard;
      } else {
        nextError = dashboardResponse.error ?? 'error_fetch_bookings';
      }
    }

    if (bookingsResponse.success && bookingsResponse.data != null) {
      _providerBookings = bookingsResponse.data!;
      unawaited(
        _cache.cacheBookings(
          _cache.providerBookingsKey(userId),
          _providerBookings,
        ),
      );
    } else {
      final cachedBookings =
          await _cache.getBookings(_cache.providerBookingsKey(userId));
      if (cachedBookings != null) {
        _providerBookings = cachedBookings;
      } else {
        nextError ??= bookingsResponse.error ?? 'error_fetch_bookings';
      }
    }

    _error = nextError;
    notifyListeners();
  }

  Future<void> fetchProviderBookings({BookingStatus? status}) async {
    final userId = _authProvider?.user?.id;
    if (_authProvider?.user?.role != UserRole.provider || userId == null) {
      _providerBookings = [];
      _error = 'Provider access is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getProviderBookings(status: status);
    final cacheKey = _cache.providerBookingsKey(userId, status: status);

    _isLoading = false;

    if (response.success && response.data != null) {
      _providerBookings = response.data!;
      _error = null;
      unawaited(_cache.cacheBookings(cacheKey, _providerBookings));
    } else {
      final cachedBookings = await _cache.getBookings(cacheKey);
      if (cachedBookings != null) {
        _providerBookings = cachedBookings;
        _error = null;
      } else {
        _error = response.error ?? 'error_fetch_bookings';
      }
    }
    notifyListeners();
  }

  Future<void> fetchServices({
    ServiceType? type,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    String sortBy = 'rating',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cacheKey = _cache.serviceListKey(
      type: type,
      searchQuery: searchQuery,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      city: city,
      sortBy: sortBy,
    );
    final response = await _api.getServices(
      type: type,
      searchQuery: searchQuery,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
      city: city,
      sortBy: sortBy,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _services = response.data!;
      _error = null;
      unawaited(_cache.cacheServices(cacheKey, _services));
    } else {
      final cachedServices = await _cache.getServices(cacheKey);
      if (cachedServices != null) {
        _services = cachedServices;
        _error = null;
      } else {
        _error = response.error ?? 'error_fetch_services';
      }
    }
    notifyListeners();
  }

  Future<void> fetchProviderServices() async {
    final userId = _authProvider?.user?.id;
    if (_authProvider?.user?.role != UserRole.provider || userId == null) {
      _providerServices = [];
      _error = 'Provider access is required.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getProviderServices();
    final cacheKey = _cache.providerServicesKey(userId);

    _isLoading = false;

    if (response.success && response.data != null) {
      _providerServices = response.data!;
      _error = null;
      unawaited(_cache.cacheServices(cacheKey, _providerServices));
    } else {
      final cachedServices = await _cache.getServices(cacheKey);
      if (cachedServices != null) {
        _providerServices = cachedServices;
        _error = null;
      } else {
        _error = response.error ?? 'error_fetch_services';
      }
    }
    notifyListeners();
  }

  Future<bool> updateProviderBookingStatus({
    required String bookingItemId,
    required BookingStatus status,
  }) async {
    _error = null;
    notifyListeners();

    final response = await _api.updateProviderBookingStatus(
      bookingItemId: bookingItemId,
      status: status,
    );

    if (response.success) {
      return true;
    }

    _error = response.error ?? 'error_fetch_bookings';
    notifyListeners();
    return false;
  }

  Future<bool> updateProviderServiceAvailability({
    required String serviceId,
    required bool isAvailable,
  }) async {
    _error = null;
    notifyListeners();

    final response = await _api.updateService(
      serviceId: serviceId,
      isAvailable: isAvailable,
    );

    if (response.success && response.data != null) {
      _providerServices = _providerServices.map((service) {
        return service.id == serviceId ? response.data! : service;
      }).toList();
      if (_authProvider?.user?.id case final userId?) {
        unawaited(
          _cache.cacheServices(
            _cache.providerServicesKey(userId),
            _providerServices,
          ),
        );
      }
      notifyListeners();
      return true;
    }

    _error = response.error ?? 'error_fetch_services';
    notifyListeners();
    return false;
  }

  Future<bool> deleteProviderService(String serviceId) async {
    _error = null;
    notifyListeners();

    final response = await _api.deleteService(serviceId);

    if (!response.success) {
      _error = response.error ?? 'error_fetch_services';
      notifyListeners();
      return false;
    }

    await fetchProviderServices();
    return true;
  }

  Future<List<TimeSlot>> fetchAvailableSlots(
      String serviceId, DateTime date) async {
    final response = await _api.getServiceAvailability(serviceId, date);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      return [];
    }
  }

  Future<ServiceModel?> getServiceById(String id) async {
    final response = await _api.getServiceById(id);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      return null;
    }
  }

  Future<BookingModel?> refreshBookingById(String id) async {
    if (!isAuthenticated) {
      return null;
    }

    final response = await _api.getBookingById(id);
    if (!response.success || response.data == null) {
      _error = response.error ?? 'error_fetch_bookings';
      notifyListeners();
      return null;
    }

    updateBookingLocally(response.data!);
    return response.data!;
  }

  void updateBookingLocally(BookingModel booking) {
    final existingIndex = _bookings.indexWhere((item) => item.id == booking.id);
    if (existingIndex >= 0) {
      _bookings[existingIndex] = booking;
    } else {
      _bookings.insert(0, booking);
    }

    if (_lastCreatedBooking?.id == booking.id) {
      _lastCreatedBooking = booking;
    }

    if (_authProvider?.user?.id case final userId?) {
      unawaited(
        _cache.cacheBookings(
          _cache.consumerBookingsKey(userId),
          _bookings,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> fetchBookmarks({bool silent = false}) async {
    final userId = _authProvider?.user?.id;
    if (!isAuthenticated || userId == null) {
      _bookmarkedServices = [];
      _bookmarkedServiceIds.clear();
      if (!silent) notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    final response = await _api.getBookmarkedServices();

    if (!silent) {
      _isLoading = false;
    }

    if (response.success && response.data != null) {
      _bookmarkedServices = response.data!;
      _bookmarkedServiceIds
        ..clear()
        ..addAll(_bookmarkedServices.map((service) => service.id));
      unawaited(
        _cache.cacheServices(
          _cache.bookmarksKey(userId),
          _bookmarkedServices,
        ),
      );
      if (!silent) {
        _error = null;
      }
    } else {
      final cachedBookmarks =
          await _cache.getServices(_cache.bookmarksKey(userId));
      if (cachedBookmarks != null) {
        _bookmarkedServices = cachedBookmarks;
        _bookmarkedServiceIds
          ..clear()
          ..addAll(_bookmarkedServices.map((service) => service.id));
        _error = null;
      } else {
        _error = response.error ?? 'error_fetch_services';
      }
    }

    notifyListeners();
  }

  Future<void> fetchUserPreferences({bool silent = false}) async {
    final userId = _authProvider?.user?.id;
    if (!isAuthenticated || userId == null) {
      _preferences = const UserPreferences();
      if (!silent) notifyListeners();
      return;
    }

    final response = await _api.getUserPreferences();
    if (response.success && response.data != null) {
      _preferences = response.data!;
      _error = null;
      unawaited(_cache.cachePreferences(userId, _preferences));
      notifyListeners();
    } else {
      final cachedPreferences = await _cache.getPreferences(userId);
      if (cachedPreferences != null) {
        _preferences = cachedPreferences;
        _error = null;
      } else if (!silent) {
        _error = response.error ?? 'error_fetch_services';
      }
      notifyListeners();
    }
  }

  Future<bool> toggleBookmark(
    String serviceId, {
    ServiceModel? service,
  }) async {
    if (!isAuthenticated) {
      _error = 'Please sign in to save services.';
      notifyListeners();
      return false;
    }

    final wasBookmarked = _bookmarkedServiceIds.contains(serviceId);
    final previousIds = Set<String>.from(_bookmarkedServiceIds);
    final previousServices = List<ServiceModel>.from(_bookmarkedServices);
    final bookmarkService = service ?? _findServiceById(serviceId);

    if (wasBookmarked) {
      _bookmarkedServiceIds.remove(serviceId);
      _bookmarkedServices.removeWhere((item) => item.id == serviceId);
    } else {
      _bookmarkedServiceIds.add(serviceId);
      if (bookmarkService != null &&
          !_bookmarkedServices.any((item) => item.id == serviceId)) {
        _bookmarkedServices = [bookmarkService, ..._bookmarkedServices];
      }
    }

    _error = null;
    notifyListeners();

    final response = wasBookmarked
        ? await _api.removeBookmark(serviceId)
        : await _api.addBookmark(serviceId);

    if (!response.success) {
      _bookmarkedServiceIds
        ..clear()
        ..addAll(previousIds);
      _bookmarkedServices = previousServices;
      _error = response.error ?? 'error_fetch_services';
      notifyListeners();
      return false;
    }

    if (_authProvider?.user?.id case final userId?) {
      unawaited(
        _cache.cacheServices(
          _cache.bookmarksKey(userId),
          _bookmarkedServices,
        ),
      );
    }
    return true;
  }

  bool isBookmarked(String serviceId) {
    return _bookmarkedServiceIds.contains(serviceId);
  }

  void updatePreferences(UserPreferences newPreferences) {
    _preferences = newPreferences;
    notifyListeners();
    if (_authProvider?.user?.id case final userId?) {
      unawaited(_cache.cachePreferences(userId, newPreferences));
    }
  }

  ServiceModel? _findServiceById(String serviceId) {
    for (final collection in [
      _services,
      _providerServices,
      _bookmarkedServices
    ]) {
      for (final service in collection) {
        if (service.id == serviceId) {
          return service;
        }
      }
    }
    return null;
  }

  void _clearUserScopedState() {
    _bookings = [];
    _providerBookings = [];
    _providerServices = [];
    _providerDashboard = const ProviderDashboardStats();
    _bookmarkedServices = [];
    _bookmarkedServiceIds.clear();
    _preferences = const UserPreferences();
    _lastCreatedBooking = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _restoreLocalState() async {
    final cachedState = await _cache.getCartState();
    if (cachedState == null) return;

    _cartItems
      ..clear()
      ..addAll(cachedState.items);
    _selectedEventDate = cachedState.selectedEventDate;
    _eventType = cachedState.eventType;
    notifyListeners();
  }

  Future<void> _persistCartState() async {
    if (_cartItems.isEmpty &&
        _selectedEventDate == null &&
        _eventType == 'wedding') {
      await _cache.clearCartState();
      return;
    }

    await _cache.cacheCartState(
      cartItems: _cartItems,
      selectedEventDate: _selectedEventDate,
      eventType: _eventType,
    );
  }
}
