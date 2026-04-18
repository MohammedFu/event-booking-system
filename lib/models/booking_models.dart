import 'package:flutter/material.dart';

enum UserRole { consumer, provider, admin }

enum ServiceType { hall, car, photographer, entertainer }

enum BookingStatus {
  draft,
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  refunded
}

enum PaymentStatus { pending, processing, succeeded, failed, refunded }

enum PricingModel { flat, hourly, perEvent, tiered }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final UserPreferences? preferences;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.role = UserRole.consumer,
    this.isVerified = false,
    this.preferences,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserPreferences {
  final List<String> preferredHallThemes;
  final List<String> preferredCarTypes;
  final List<String> preferredPhotographerStyles;
  final List<String> preferredEntertainerTypes;
  final BudgetRange budgetRange;
  final List<String> preferredCities;

  const UserPreferences({
    this.preferredHallThemes = const [],
    this.preferredCarTypes = const [],
    this.preferredPhotographerStyles = const [],
    this.preferredEntertainerTypes = const [],
    this.budgetRange = const BudgetRange(),
    this.preferredCities = const [],
  });
}

class BudgetRange {
  final double min;
  final double max;

  const BudgetRange({this.min = 0, this.max = double.infinity});
}

class ProviderModel {
  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final ServiceType serviceType;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isActive;
  final String? address;
  final String? city;
  final String? country;
  final String? contactPhone;
  final String? contactEmail;

  const ProviderModel({
    required this.id,
    required this.userId,
    required this.businessName,
    this.description,
    this.logoUrl,
    this.coverUrl,
    required this.serviceType,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.isActive = true,
    this.address,
    this.city,
    this.country,
    this.contactPhone,
    this.contactEmail,
  });
}

class ServiceModel {
  final String id;
  final String providerId;
  final String title;
  final String? description;
  final ServiceType serviceType;
  final double basePrice;
  final String currency;
  final PricingModel pricingModel;
  final List<String> images;
  final List<String> tags;
  final ServiceAttributes attributes;
  final bool isAvailable;
  final int? maxCapacity;
  final double minDurationHours;
  final double? maxDurationHours;
  final ProviderModel? provider;
  final CancellationPolicy cancellationPolicy;
  final List<PricingRuleModel> pricingRules;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    this.description,
    required this.serviceType,
    required this.basePrice,
    this.currency = 'USD',
    this.pricingModel = PricingModel.flat,
    this.images = const [],
    this.tags = const [],
    required this.attributes,
    this.isAvailable = true,
    this.maxCapacity,
    this.minDurationHours = 1,
    this.maxDurationHours,
    this.provider,
    this.cancellationPolicy = const CancellationPolicy(),
    this.pricingRules = const [],
  });

  String get serviceTypeLabel {
    switch (serviceType) {
      case ServiceType.hall:
        return 'Event Hall';
      case ServiceType.car:
        return 'Car';
      case ServiceType.photographer:
        return 'Photographer';
      case ServiceType.entertainer:
        return 'Entertainer';
    }
  }

  IconData get serviceTypeIcon {
    switch (serviceType) {
      case ServiceType.hall:
        return Icons.domain;
      case ServiceType.car:
        return Icons.directions_car;
      case ServiceType.photographer:
        return Icons.camera_alt;
      case ServiceType.entertainer:
        return Icons.music_note;
    }
  }

  double getEffectivePrice({DateTime? date, int? advanceDays}) {
    if (pricingRules.isEmpty) return basePrice;

    double price = basePrice;
    for (final rule in pricingRules.where((r) => r.isActive)) {
      bool applies = false;

      if (rule.ruleType == PricingRuleType.weekend && date != null) {
        applies = date.weekday >= 6;
      } else if (rule.ruleType == PricingRuleType.seasonal &&
          date != null &&
          rule.startDate != null &&
          rule.endDate != null) {
        applies = date.isAfter(rule.startDate!) && date.isBefore(rule.endDate!);
      } else if (rule.ruleType == PricingRuleType.earlyBird &&
          advanceDays != null &&
          rule.minAdvanceDays != null) {
        applies = advanceDays >= rule.minAdvanceDays!;
      } else if (rule.ruleType == PricingRuleType.lastMinute &&
          advanceDays != null &&
          rule.minAdvanceDays != null) {
        applies = advanceDays < rule.minAdvanceDays!;
      }

      if (applies) {
        price = rule.applyTo(price);
      }
    }
    return price;
  }
}

class ServiceAttributes {
  // Hall attributes
  final int? capacity;
  final bool? hasStage;
  final bool? hasParking;
  final bool? hasKitchen;
  final String? theme;
  final List<String> amenities;

  // Car attributes
  final String? make;
  final String? model;
  final int? year;
  final String? color;
  final String? carType;
  final int? maxPassengers;
  final List<String> features;

  // Photographer attributes
  final String? portfolioUrl;
  final List<String> specialties;
  final List<String> equipment;
  final bool? editingIncluded;

  // Entertainer attributes
  final String? performerType;
  final List<String> genres;
  final String? sampleVideoUrl;
  final int? groupSize;

  const ServiceAttributes({
    this.capacity,
    this.hasStage,
    this.hasParking,
    this.hasKitchen,
    this.theme,
    this.amenities = const [],
    this.make,
    this.model,
    this.year,
    this.color,
    this.carType,
    this.maxPassengers,
    this.features = const [],
    this.portfolioUrl,
    this.specialties = const [],
    this.equipment = const [],
    this.editingIncluded,
    this.performerType,
    this.genres = const [],
    this.sampleVideoUrl,
    this.groupSize,
  });
}

class TimeSlot {
  final String id;
  final String serviceId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final double? price;

  const TimeSlot({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.price,
  });

  double get durationHours {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  String get timeLabel {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

class BookingModel {
  final String id;
  final String consumerId;
  final String eventType;
  final DateTime eventDate;
  final String? eventName;
  final BookingStatus status;
  final double totalAmount;
  final String currency;
  final double depositAmount;
  final bool depositPaid;
  final List<BookingItem> items;
  final String? notes;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.consumerId,
    this.eventType = 'wedding',
    required this.eventDate,
    this.eventName,
    this.status = BookingStatus.pending,
    this.totalAmount = 0,
    this.currency = 'USD',
    this.depositAmount = 0,
    this.depositPaid = false,
    this.items = const [],
    this.notes,
    this.specialRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusLabel {
    switch (status) {
      case BookingStatus.draft:
        return 'Draft';
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.refunded:
        return 'Refunded';
    }
  }

  Color get statusColor {
    switch (status) {
      case BookingStatus.draft:
        return Colors.grey;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.teal;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.refunded:
        return Colors.purple;
    }
  }

  BookingModel copyWith({
    String? id,
    String? consumerId,
    String? eventType,
    DateTime? eventDate,
    String? eventName,
    BookingStatus? status,
    double? totalAmount,
    String? currency,
    double? depositAmount,
    bool? depositPaid,
    List<BookingItem>? items,
    String? notes,
    String? specialRequests,
  }) {
    return BookingModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      eventName: eventName ?? this.eventName,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      depositAmount: depositAmount ?? this.depositAmount,
      depositPaid: depositPaid ?? this.depositPaid,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      specialRequests: specialRequests ?? this.specialRequests,
    );
  }
}

class BookingItem {
  final String id;
  final String bookingId;
  final String serviceId;
  final String providerId;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double durationHours;
  final double unitPrice;
  final double subtotal;
  final BookingStatus status;
  final String? specialRequests;
  final ServiceModel? service;
  final ProviderModel? provider;

  const BookingItem({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.providerId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.unitPrice,
    required this.subtotal,
    this.status = BookingStatus.pending,
    this.specialRequests,
    this.service,
    this.provider,
  });
}

class PaymentModel {
  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.currency = 'USD',
    this.paymentMethod = 'card',
    this.status = PaymentStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ReviewModel {
  final String id;
  final String bookingItemId;
  final String consumerId;
  final String providerId;
  final int rating;
  final String? comment;
  final List<String> images;
  final bool isAnonymous;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingItemId,
    required this.consumerId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.images = const [],
    this.isAnonymous = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

// ═══════════════════════════════════════════════════════════
// PRICING RULES (dynamic pricing, surge, discounts)
// ═══════════════════════════════════════════════════════════

enum PricingRuleType {
  seasonal,
  weekend,
  peak,
  earlyBird,
  lastMinute,
  bulkDiscount,
}

class PricingRuleModel {
  final String id;
  final String serviceId;
  final PricingRuleType ruleType;
  final double multiplier;
  final double fixedAdjustment;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? dayOfWeek;
  final int? minAdvanceDays;
  final int? minBookings;
  final int priority;
  final bool isActive;
  final DateTime createdAt;

  PricingRuleModel({
    required this.id,
    required this.serviceId,
    required this.ruleType,
    this.multiplier = 1.0,
    this.fixedAdjustment = 0,
    this.startDate,
    this.endDate,
    this.dayOfWeek,
    this.minAdvanceDays,
    this.minBookings,
    this.priority = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get ruleTypeLabel {
    switch (ruleType) {
      case PricingRuleType.seasonal:
        return 'Seasonal';
      case PricingRuleType.weekend:
        return 'Weekend';
      case PricingRuleType.peak:
        return 'Peak';
      case PricingRuleType.earlyBird:
        return 'Early Bird';
      case PricingRuleType.lastMinute:
        return 'Last Minute';
      case PricingRuleType.bulkDiscount:
        return 'Bulk Discount';
    }
  }

  IconData get ruleTypeIcon {
    switch (ruleType) {
      case PricingRuleType.seasonal:
        return Icons.wb_sunny;
      case PricingRuleType.weekend:
        return Icons.weekend;
      case PricingRuleType.peak:
        return Icons.trending_up;
      case PricingRuleType.earlyBird:
        return Icons.alarm;
      case PricingRuleType.lastMinute:
        return Icons.schedule;
      case PricingRuleType.bulkDiscount:
        return Icons.local_offer;
    }
  }

  double applyTo(double basePrice) {
    return (basePrice * multiplier) + fixedAdjustment;
  }
}

// ═══════════════════════════════════════════════════════════
// AVAILABILITY TEMPLATES
// ═══════════════════════════════════════════════════════════

class AvailabilityTemplateModel {
  final String id;
  final String serviceId;
  final int dayOfWeek; // 0=Sunday, 6=Saturday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  const AvailabilityTemplateModel({
    required this.id,
    required this.serviceId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.effectiveFrom,
    this.effectiveTo,
  });

  String get dayLabel {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[dayOfWeek];
  }

  String get timeLabel {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

// ═══════════════════════════════════════════════════════════
// CANCELLATION POLICY
// ═══════════════════════════════════════════════════════════

class CancellationPolicy {
  final int freeCancellationHours;
  final double partialRefundPercentage;
  final bool depositRefundable;
  final String? description;

  const CancellationPolicy({
    this.freeCancellationHours = 72,
    this.partialRefundPercentage = 50,
    this.depositRefundable = false,
    this.description,
  });

  String get summary {
    return 'Free cancellation up to $freeCancellationHours hours before. '
        '${partialRefundPercentage.toInt()}% refund after that. '
        'Deposit ${depositRefundable ? 'is' : 'is not'} refundable.';
  }
}

// ═══════════════════════════════════════════════════════════
// AUTH TOKENS
// ═══════════════════════════════════════════════════════════

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isExpiringSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));
}

// ═══════════════════════════════════════════════════════════
// API RESPONSE WRAPPER
// ═══════════════════════════════════════════════════════════

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.meta,
  });

  factory ApiResponse.ok(T data, {Map<String, dynamic>? meta}) =>
      ApiResponse(success: true, data: data, meta: meta);

  factory ApiResponse.fail(String error, {int? statusCode}) =>
      ApiResponse(success: false, error: error, statusCode: statusCode);
}

// ═══════════════════════════════════════════════════════════
// PROVIDER DASHBOARD STATS
// ═══════════════════════════════════════════════════════════

class ProviderDashboardStats {
  final int totalBookings;
  final double totalRevenue;
  final int pendingBookings;
  final double averageRating;
  final int completedBookings;
  final int cancelledBookings;
  final Map<String, double> revenueByMonth;
  final Map<String, int> bookingsByServiceType;

  const ProviderDashboardStats({
    this.totalBookings = 0,
    this.totalRevenue = 0,
    this.pendingBookings = 0,
    this.averageRating = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.revenueByMonth = const {},
    this.bookingsByServiceType = const {},
  });
}

// ═══════════════════════════════════════════════════════════
// BOOKING CART ITEM (used in booking workflow)
// ═══════════════════════════════════════════════════════════

class BookingCartItem {
  final ServiceModel service;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double durationHours;
  final String? specialRequests;

  const BookingCartItem({
    required this.service,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    this.specialRequests,
  });

  double get subtotal {
    if (service.pricingModel == PricingModel.hourly) {
      return service.basePrice * durationHours;
    }
    return service.basePrice;
  }

  String get timeLabel {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}
