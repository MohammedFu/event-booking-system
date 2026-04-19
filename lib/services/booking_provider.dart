import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/models/demo_booking_data.dart';

class BookingProvider extends ChangeNotifier {
  // Booking cart items
  final List<BookingCartItem> _cartItems = [];
  List<BookingCartItem> get cartItems => List.unmodifiable(_cartItems);

  // User bookings
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => List.unmodifiable(_bookings);

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

  // Cart total
  double get cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  int get cartItemCount => _cartItems.length;

  bool hasServiceTypeInCart(ServiceType type) {
    return _cartItems.any((item) => item.service.serviceType == type);
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

  Future<void> createBooking() async {
    if (_selectedEventDate == null || _cartItems.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final booking = BookingModel(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      consumerId: 'user-consumer-1',
      eventType: _eventType,
      eventDate: _selectedEventDate!,
      eventName: _eventType == 'wedding' ? 'Wedding Celebration' : 'Event',
      status: BookingStatus.pending,
      totalAmount: cartTotal,
      depositAmount: cartTotal * 0.25,
      items: _cartItems
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
    );

    _bookings.insert(0, booking);
    _cartItems.clear();
    _isLoading = false;
    notifyListeners();
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

  // Load demo bookings
  void loadDemoData() {
    _bookings = List.from(demoBookings);
    notifyListeners();
  }

  // Get services filtered by type and sorted
  List<ServiceModel> getServices({
    ServiceType? type,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    String sortBy = 'rating',
  }) {
    var services = type != null ? getServicesByType(type) : allDemoServices;

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

    return services;
  }

  // Get available time slots for a service on a given date
  List<TimeSlot> getAvailableSlots(String serviceId, DateTime date) {
    final service = allDemoServices.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw StateError('Service not found'),
    );

    // Generate demo slots
    final slots = <TimeSlot>[];
    for (int hour = 8; hour <= 20; hour++) {
      final isBooked = hour == 14 || hour == 16; // Simulate some booked slots
      slots.add(TimeSlot(
        id: 'slot-$serviceId-$date-$hour',
        serviceId: serviceId,
        date: date,
        startTime: TimeOfDay(hour: hour, minute: 0),
        endTime: TimeOfDay(hour: hour + 1, minute: 0),
        isAvailable: !isBooked,
        price: service.pricingModel == PricingModel.hourly
            ? service.basePrice
            : null,
      ));
    }
    return slots;
  }
}
