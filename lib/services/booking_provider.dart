import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';

class BookingProvider extends ChangeNotifier {
  final ApiServiceReal _api = ApiServiceReal();

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

  // Cart total
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  int get cartItemCount => _cartItems.length;

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
  }

  void setEventType(String type) {
    _eventType = type;
    notifyListeners();
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
    notifyListeners();
  }

  void removeFromCart(String serviceId) {
    _cartItems.removeWhere((item) => item.service.id == serviceId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
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

  Future<bool> createBooking() async {
    if (_selectedEventDate == null || _cartItems.isEmpty) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.createBooking(
      consumerId: 'user-consumer-1', // TODO: Get from auth provider
      eventType: _eventType,
      eventDate: _selectedEventDate!,
      eventName: null,
      cartItems: _cartItems,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _bookings.insert(0, response.data!);
      _cartItems.clear();
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'error_create_booking';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchBookings({BookingStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getBookings(status: status?.name);

    _isLoading = false;

    if (response.success && response.data != null) {
      _bookings = response.data!;
    } else {
      _error = response.error ?? 'error_fetch_bookings';
    }
    notifyListeners();
  }

  Future<void> fetchProviderDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final dashboardResponse = await _api.getProviderDashboard();
    final bookingsResponse = await _api.getProviderBookings(limit: 20);

    _isLoading = false;

    if (dashboardResponse.success && dashboardResponse.data != null) {
      _providerDashboard = dashboardResponse.data!;
    } else {
      _error = dashboardResponse.error ?? 'error_fetch_bookings';
    }

    if (bookingsResponse.success && bookingsResponse.data != null) {
      _providerBookings = bookingsResponse.data!;
    } else {
      _error ??= bookingsResponse.error ?? 'error_fetch_bookings';
    }

    notifyListeners();
  }

  Future<void> fetchProviderBookings({BookingStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getProviderBookings(status: status);

    _isLoading = false;

    if (response.success && response.data != null) {
      _providerBookings = response.data!;
    } else {
      _error = response.error ?? 'error_fetch_bookings';
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
    } else {
      _error = response.error ?? 'error_fetch_services';
    }
    notifyListeners();
  }

  Future<void> fetchProviderServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _api.getProviderServices();

    _isLoading = false;

    if (response.success && response.data != null) {
      _providerServices = response.data!;
    } else {
      _error = response.error ?? 'error_fetch_services';
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

  void toggleBookmark(String serviceId) {
    if (_bookmarkedServiceIds.contains(serviceId)) {
      _bookmarkedServiceIds.remove(serviceId);
    } else {
      _bookmarkedServiceIds.add(serviceId);
    }
    notifyListeners();
  }

  bool isBookmarked(String serviceId) {
    return _bookmarkedServiceIds.contains(serviceId);
  }

  void updatePreferences(UserPreferences newPreferences) {
    _preferences = newPreferences;
    notifyListeners();
  }
}
