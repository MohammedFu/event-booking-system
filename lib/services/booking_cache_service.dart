import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedCartState {
  final List<BookingCartItem> items;
  final DateTime? selectedEventDate;
  final String eventType;

  const CachedCartState({
    required this.items,
    required this.selectedEventDate,
    required this.eventType,
  });
}

class BookingCacheService {
  static final BookingCacheService _instance = BookingCacheService._internal();
  factory BookingCacheService() => _instance;
  BookingCacheService._internal();

  static const String _namespace = 'booking_cache_v1';

  String serviceListKey({
    ServiceType? type,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? city,
    required String sortBy,
  }) {
    final filters = <String, dynamic>{
      'type': type?.name,
      'searchQuery': searchQuery?.trim().toLowerCase(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'city': city?.trim().toLowerCase(),
      'sortBy': sortBy,
    };
    return '$_namespace:services:${_encodeKey(filters)}';
  }

  String consumerBookingsKey(String userId, {BookingStatus? status}) =>
      '$_namespace:user:$userId:bookings:${status?.name ?? 'all'}';

  String providerBookingsKey(String userId, {BookingStatus? status}) =>
      '$_namespace:user:$userId:provider_bookings:${status?.name ?? 'all'}';

  String providerServicesKey(String userId) =>
      '$_namespace:user:$userId:provider_services';

  String providerDashboardKey(String userId) =>
      '$_namespace:user:$userId:provider_dashboard';

  String bookmarksKey(String userId) => '$_namespace:user:$userId:bookmarks';

  String preferencesKey(String userId) =>
      '$_namespace:user:$userId:preferences';

  String notificationsKey(String userId) =>
      '$_namespace:user:$userId:notifications';

  String cartKey() => '$_namespace:cart';

  Future<void> cacheServices(String key, List<ServiceModel> services) async {
    await _writeJson(
      key,
      services.map(_BookingCacheCodec.serviceToJson).toList(),
    );
  }

  Future<List<ServiceModel>?> getServices(String key) async {
    final data = await _readJsonList(key);
    if (data == null) return null;

    return data
        .whereType<Map>()
        .map((item) =>
            _BookingCacheCodec.serviceFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cacheBookings(String key, List<BookingModel> bookings) async {
    await _writeJson(
      key,
      bookings.map(_BookingCacheCodec.bookingToJson).toList(),
    );
  }

  Future<List<BookingModel>?> getBookings(String key) async {
    final data = await _readJsonList(key);
    if (data == null) return null;

    return data
        .whereType<Map>()
        .map((item) =>
            _BookingCacheCodec.bookingFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cachePreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await _writeJson(
      preferencesKey(userId),
      _BookingCacheCodec.preferencesToJson(preferences),
    );
  }

  Future<UserPreferences?> getPreferences(String userId) async {
    final data = await _readJsonMap(preferencesKey(userId));
    if (data == null) return null;
    return _BookingCacheCodec.preferencesFromJson(data);
  }

  Future<void> cacheDashboard(
    String userId,
    ProviderDashboardStats dashboard,
  ) async {
    await _writeJson(
      providerDashboardKey(userId),
      _BookingCacheCodec.providerDashboardToJson(dashboard),
    );
  }

  Future<ProviderDashboardStats?> getDashboard(String userId) async {
    final data = await _readJsonMap(providerDashboardKey(userId));
    if (data == null) return null;
    return _BookingCacheCodec.providerDashboardFromJson(data);
  }

  Future<void> cacheNotifications(
    String userId,
    List<NotificationModel> notifications,
  ) async {
    await _writeJson(
      notificationsKey(userId),
      notifications.map(_BookingCacheCodec.notificationToJson).toList(),
    );
  }

  Future<List<NotificationModel>?> getNotifications(String userId) async {
    final data = await _readJsonList(notificationsKey(userId));
    if (data == null) return null;

    return data
        .whereType<Map>()
        .map((item) => _BookingCacheCodec.notificationFromJson(
            Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cacheCartState({
    required List<BookingCartItem> cartItems,
    required DateTime? selectedEventDate,
    required String eventType,
  }) async {
    await _writeJson(cartKey(), {
      'selectedEventDate': selectedEventDate?.toIso8601String(),
      'eventType': eventType,
      'items': cartItems.map(_BookingCacheCodec.cartItemToJson).toList(),
    });
  }

  Future<CachedCartState?> getCartState() async {
    final data = await _readJsonMap(cartKey());
    if (data == null) return null;

    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => _BookingCacheCodec.cartItemFromJson(
            Map<String, dynamic>.from(item)))
        .toList();

    return CachedCartState(
      items: items,
      selectedEventDate: data['selectedEventDate'] != null
          ? DateTime.tryParse(data['selectedEventDate'])
          : null,
      eventType: data['eventType']?.toString() ?? 'wedding',
    );
  }

  Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_namespace:user:$userId:';

    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> clearCartState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartKey());
  }

  Future<void> _writeJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<List<dynamic>?> _readJsonList(String key) async {
    final data = await _readJson(key);
    return data is List ? data : null;
  }

  Future<Map<String, dynamic>?> _readJsonMap(String key) async {
    final data = await _readJson(key);
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<dynamic> _readJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  String _encodeKey(Map<String, dynamic> data) {
    return base64UrlEncode(utf8.encode(jsonEncode(data)));
  }
}

class _BookingCacheCodec {
  static Map<String, dynamic> serviceToJson(ServiceModel service) {
    return {
      'id': service.id,
      'providerId': service.providerId,
      'title': service.title,
      'description': service.description,
      'serviceType': service.serviceType.name,
      'basePrice': service.basePrice,
      'currency': service.currency,
      'pricingModel': service.pricingModel.name,
      'images': service.images,
      'tags': service.tags,
      'attributes': serviceAttributesToJson(service.attributes),
      'isAvailable': service.isAvailable,
      'maxCapacity': service.maxCapacity,
      'minDurationHours': service.minDurationHours,
      'maxDurationHours': service.maxDurationHours,
      'provider':
          service.provider != null ? providerToJson(service.provider!) : null,
      'cancellationPolicy':
          cancellationPolicyToJson(service.cancellationPolicy),
      'pricingRules': service.pricingRules.map(pricingRuleToJson).toList(),
    };
  }

  static ServiceModel serviceFromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      serviceType: _serviceTypeFromName(json['serviceType']),
      basePrice: _toDouble(json['basePrice']),
      currency: json['currency']?.toString() ?? 'USD',
      pricingModel: _pricingModelFromName(json['pricingModel']),
      images: _stringList(json['images']),
      tags: _stringList(json['tags']),
      attributes: serviceAttributesFromJson(
        _map(json['attributes']),
      ),
      isAvailable: json['isAvailable'] != false,
      maxCapacity: _toIntOrNull(json['maxCapacity']),
      minDurationHours: _toDouble(
        json['minDurationHours'],
        fallback: 1,
      ),
      maxDurationHours: _toNullableDouble(json['maxDurationHours']),
      provider: json['provider'] is Map
          ? providerFromJson(_map(json['provider']))
          : null,
      cancellationPolicy: cancellationPolicyFromJson(
        _map(json['cancellationPolicy']),
      ),
      pricingRules: (json['pricingRules'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => pricingRuleFromJson(_map(item)))
          .toList(),
    );
  }

  static Map<String, dynamic> providerToJson(ProviderModel provider) {
    return {
      'id': provider.id,
      'userId': provider.userId,
      'businessName': provider.businessName,
      'description': provider.description,
      'logoUrl': provider.logoUrl,
      'coverUrl': provider.coverUrl,
      'serviceType': provider.serviceType.name,
      'rating': provider.rating,
      'reviewCount': provider.reviewCount,
      'isVerified': provider.isVerified,
      'isActive': provider.isActive,
      'address': provider.address,
      'city': provider.city,
      'country': provider.country,
      'contactPhone': provider.contactPhone,
      'contactEmail': provider.contactEmail,
    };
  }

  static ProviderModel providerFromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? '',
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      serviceType: _serviceTypeFromName(json['serviceType']),
      rating: _toDouble(json['rating']),
      reviewCount: _toInt(json['reviewCount']),
      isVerified: json['isVerified'] == true,
      isActive: json['isActive'] != false,
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      contactEmail: json['contactEmail']?.toString(),
    );
  }

  static Map<String, dynamic> serviceAttributesToJson(ServiceAttributes attrs) {
    return {
      'capacity': attrs.capacity,
      'hasStage': attrs.hasStage,
      'hasParking': attrs.hasParking,
      'hasKitchen': attrs.hasKitchen,
      'theme': attrs.theme,
      'amenities': attrs.amenities,
      'make': attrs.make,
      'model': attrs.model,
      'year': attrs.year,
      'color': attrs.color,
      'carType': attrs.carType,
      'maxPassengers': attrs.maxPassengers,
      'features': attrs.features,
      'portfolioUrl': attrs.portfolioUrl,
      'specialties': attrs.specialties,
      'equipment': attrs.equipment,
      'editingIncluded': attrs.editingIncluded,
      'performerType': attrs.performerType,
      'genres': attrs.genres,
      'sampleVideoUrl': attrs.sampleVideoUrl,
      'groupSize': attrs.groupSize,
    };
  }

  static ServiceAttributes serviceAttributesFromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceAttributes(
      capacity: _toIntOrNull(json['capacity']),
      hasStage: _toBoolOrNull(json['hasStage']),
      hasParking: _toBoolOrNull(json['hasParking']),
      hasKitchen: _toBoolOrNull(json['hasKitchen']),
      theme: json['theme']?.toString(),
      amenities: _stringList(json['amenities']),
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      year: _toIntOrNull(json['year']),
      color: json['color']?.toString(),
      carType: json['carType']?.toString(),
      maxPassengers: _toIntOrNull(json['maxPassengers']),
      features: _stringList(json['features']),
      portfolioUrl: json['portfolioUrl']?.toString(),
      specialties: _stringList(json['specialties']),
      equipment: _stringList(json['equipment']),
      editingIncluded: _toBoolOrNull(json['editingIncluded']),
      performerType: json['performerType']?.toString(),
      genres: _stringList(json['genres']),
      sampleVideoUrl: json['sampleVideoUrl']?.toString(),
      groupSize: _toIntOrNull(json['groupSize']),
    );
  }

  static Map<String, dynamic> cancellationPolicyToJson(
    CancellationPolicy policy,
  ) {
    return {
      'freeCancellationHours': policy.freeCancellationHours,
      'partialRefundPercentage': policy.partialRefundPercentage,
      'depositRefundable': policy.depositRefundable,
      'description': policy.description,
    };
  }

  static CancellationPolicy cancellationPolicyFromJson(
    Map<String, dynamic> json,
  ) {
    return CancellationPolicy(
      freeCancellationHours: _toInt(
        json['freeCancellationHours'],
        fallback: 72,
      ),
      partialRefundPercentage: _toDouble(
        json['partialRefundPercentage'],
        fallback: 50,
      ),
      depositRefundable: json['depositRefundable'] == true,
      description: json['description']?.toString(),
    );
  }

  static Map<String, dynamic> pricingRuleToJson(PricingRuleModel rule) {
    return {
      'id': rule.id,
      'serviceId': rule.serviceId,
      'ruleType': rule.ruleType.name,
      'multiplier': rule.multiplier,
      'fixedAdjustment': rule.fixedAdjustment,
      'startDate': rule.startDate?.toIso8601String(),
      'endDate': rule.endDate?.toIso8601String(),
      'dayOfWeek': rule.dayOfWeek,
      'minAdvanceDays': rule.minAdvanceDays,
      'minBookings': rule.minBookings,
      'priority': rule.priority,
      'isActive': rule.isActive,
      'createdAt': rule.createdAt.toIso8601String(),
    };
  }

  static PricingRuleModel pricingRuleFromJson(Map<String, dynamic> json) {
    return PricingRuleModel(
      id: json['id']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      ruleType: _pricingRuleTypeFromName(json['ruleType']),
      multiplier: _toDouble(json['multiplier'], fallback: 1),
      fixedAdjustment: _toDouble(json['fixedAdjustment']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      dayOfWeek: _toIntOrNull(json['dayOfWeek']),
      minAdvanceDays: _toIntOrNull(json['minAdvanceDays']),
      minBookings: _toIntOrNull(json['minBookings']),
      priority: _toInt(json['priority']),
      isActive: json['isActive'] != false,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static Map<String, dynamic> bookingToJson(BookingModel booking) {
    return {
      'id': booking.id,
      'consumerId': booking.consumerId,
      'eventType': booking.eventType,
      'eventDate': booking.eventDate.toIso8601String(),
      'eventName': booking.eventName,
      'status': booking.status.name,
      'totalAmount': booking.totalAmount,
      'currency': booking.currency,
      'depositAmount': booking.depositAmount,
      'depositPaid': booking.depositPaid,
      'items': booking.items.map(bookingItemToJson).toList(),
      'notes': booking.notes,
      'specialRequests': booking.specialRequests,
      'createdAt': booking.createdAt.toIso8601String(),
      'updatedAt': booking.updatedAt.toIso8601String(),
    };
  }

  static BookingModel bookingFromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      consumerId: json['consumerId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'wedding',
      eventDate: _parseDate(json['eventDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      eventName: json['eventName']?.toString(),
      status: _bookingStatusFromName(json['status']),
      totalAmount: _toDouble(json['totalAmount']),
      currency: json['currency']?.toString() ?? 'USD',
      depositAmount: _toDouble(json['depositAmount']),
      depositPaid: json['depositPaid'] == true,
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => bookingItemFromJson(_map(item)))
          .toList(),
      notes: json['notes']?.toString(),
      specialRequests: json['specialRequests']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static Map<String, dynamic> bookingItemToJson(BookingItem item) {
    return {
      'id': item.id,
      'bookingId': item.bookingId,
      'serviceId': item.serviceId,
      'providerId': item.providerId,
      'date': item.date.toIso8601String(),
      'startTime': _timeToString(item.startTime),
      'endTime': _timeToString(item.endTime),
      'durationHours': item.durationHours,
      'unitPrice': item.unitPrice,
      'subtotal': item.subtotal,
      'status': item.status.name,
      'specialRequests': item.specialRequests,
      'service': item.service != null ? serviceToJson(item.service!) : null,
      'provider': item.provider != null ? providerToJson(item.provider!) : null,
    };
  }

  static BookingItem bookingItemFromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      date: _parseDate(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      durationHours: _toDouble(json['durationHours'], fallback: 1),
      unitPrice: _toDouble(json['unitPrice']),
      subtotal: _toDouble(json['subtotal']),
      status: _bookingStatusFromName(json['status']),
      specialRequests: json['specialRequests']?.toString(),
      service: json['service'] is Map
          ? serviceFromJson(_map(json['service']))
          : null,
      provider: json['provider'] is Map
          ? providerFromJson(_map(json['provider']))
          : null,
    );
  }

  static Map<String, dynamic> preferencesToJson(UserPreferences preferences) {
    return {
      'preferredHallThemes': preferences.preferredHallThemes,
      'preferredCarTypes': preferences.preferredCarTypes,
      'preferredPhotographerStyles': preferences.preferredPhotographerStyles,
      'preferredEntertainerTypes': preferences.preferredEntertainerTypes,
      'budgetRange': budgetRangeToJson(preferences.budgetRange),
      'preferredCities': preferences.preferredCities,
    };
  }

  static UserPreferences preferencesFromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredHallThemes: _stringList(json['preferredHallThemes']),
      preferredCarTypes: _stringList(json['preferredCarTypes']),
      preferredPhotographerStyles:
          _stringList(json['preferredPhotographerStyles']),
      preferredEntertainerTypes: _stringList(json['preferredEntertainerTypes']),
      budgetRange: budgetRangeFromJson(_map(json['budgetRange'])),
      preferredCities: _stringList(json['preferredCities']),
    );
  }

  static Map<String, dynamic> budgetRangeToJson(BudgetRange budgetRange) {
    return {
      'min': budgetRange.min,
      'max': budgetRange.max.isFinite ? budgetRange.max : null,
    };
  }

  static BudgetRange budgetRangeFromJson(Map<String, dynamic> json) {
    return BudgetRange(
      min: _toDouble(json['min']),
      max: _toNullableDouble(json['max']) ?? double.infinity,
    );
  }

  static Map<String, dynamic> providerDashboardToJson(
    ProviderDashboardStats dashboard,
  ) {
    return {
      'totalBookings': dashboard.totalBookings,
      'totalRevenue': dashboard.totalRevenue,
      'pendingBookings': dashboard.pendingBookings,
      'averageRating': dashboard.averageRating,
      'completedBookings': dashboard.completedBookings,
      'cancelledBookings': dashboard.cancelledBookings,
      'revenueByMonth': dashboard.revenueByMonth,
      'bookingsByServiceType': dashboard.bookingsByServiceType,
    };
  }

  static ProviderDashboardStats providerDashboardFromJson(
    Map<String, dynamic> json,
  ) {
    return ProviderDashboardStats(
      totalBookings: _toInt(json['totalBookings']),
      totalRevenue: _toDouble(json['totalRevenue']),
      pendingBookings: _toInt(json['pendingBookings']),
      averageRating: _toDouble(json['averageRating']),
      completedBookings: _toInt(json['completedBookings']),
      cancelledBookings: _toInt(json['cancelledBookings']),
      revenueByMonth: _doubleMap(json['revenueByMonth']),
      bookingsByServiceType: _intMap(json['bookingsByServiceType']),
    );
  }

  static Map<String, dynamic> notificationToJson(
      NotificationModel notification) {
    return {
      'id': notification.id,
      'userId': notification.userId,
      'type': notification.type,
      'title': notification.title,
      'body': notification.body,
      'data': _jsonSafeMap(notification.data),
      'isRead': notification.isRead,
      'createdAt': notification.createdAt.toIso8601String(),
    };
  }

  static NotificationModel notificationFromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString(),
      data: _map(json['data']),
      isRead: json['isRead'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static Map<String, dynamic> cartItemToJson(BookingCartItem item) {
    return {
      'service': serviceToJson(item.service),
      'date': item.date.toIso8601String(),
      'startTime': _timeToString(item.startTime),
      'endTime': _timeToString(item.endTime),
      'durationHours': item.durationHours,
      'specialRequests': item.specialRequests,
    };
  }

  static BookingCartItem cartItemFromJson(Map<String, dynamic> json) {
    return BookingCartItem(
      service: serviceFromJson(_map(json['service'])),
      date: _parseDate(json['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      startTime: _timeFromJson(json['startTime']),
      endTime: _timeFromJson(json['endTime']),
      durationHours: _toDouble(json['durationHours'], fallback: 1),
      specialRequests: json['specialRequests']?.toString(),
    );
  }

  static Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> value) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(jsonEncode(value)) as Map<String, dynamic>,
      );
    } catch (_) {
      return const {};
    }
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static Map<String, double> _doubleMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), _toDouble(entry)),
    );
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, entry) => MapEntry(key.toString(), _toInt(entry)),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _toBoolOrNull(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _timeFromJson(dynamic value) {
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    if (value is Map) {
      return TimeOfDay(
        hour: _toInt(value['hour']),
        minute: _toInt(value['minute']),
      );
    }

    return const TimeOfDay(hour: 0, minute: 0);
  }

  static ServiceType _serviceTypeFromName(dynamic value) {
    return ServiceType.values.firstWhere(
      (type) => type.name == value?.toString(),
      orElse: () => ServiceType.hall,
    );
  }

  static PricingModel _pricingModelFromName(dynamic value) {
    return PricingModel.values.firstWhere(
      (model) => model.name == value?.toString(),
      orElse: () => PricingModel.flat,
    );
  }

  static PricingRuleType _pricingRuleTypeFromName(dynamic value) {
    return PricingRuleType.values.firstWhere(
      (type) => type.name == value?.toString(),
      orElse: () => PricingRuleType.weekend,
    );
  }

  static BookingStatus _bookingStatusFromName(dynamic value) {
    return BookingStatus.values.firstWhere(
      (status) => status.name == value?.toString(),
      orElse: () => BookingStatus.pending,
    );
  }
}
