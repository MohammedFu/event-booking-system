import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:munasabati/services/push_notification_service.dart';

class AppAnalyticsService {
  AppAnalyticsService._();

  static final AppAnalyticsService instance = AppAnalyticsService._();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  List<NavigatorObserver> get navigatorObservers =>
      _observer == null ? const [] : [_observer!];

  Future<void> initialize() async {
    final isReady = await PushNotificationService.ensureFirebaseInitialized();
    if (!isReady) {
      return;
    }

    _analytics ??= FirebaseAnalytics.instance;
    _observer ??= FirebaseAnalyticsObserver(analytics: _analytics!);
  }

  Future<void> logServiceViewed(String serviceId, String serviceType) async {
    await logEvent(
      'service_viewed',
      parameters: {
        'service_id': serviceId,
        'service_type': serviceType,
      },
    );
  }

  Future<void> logServiceShared(String serviceId) async {
    await logEvent(
      'service_shared',
      parameters: {'service_id': serviceId},
    );
  }

  Future<void> logDeepLinkOpened(Uri uri) async {
    await logEvent(
      'deep_link_opened',
      parameters: {
        'scheme': uri.scheme,
        'host': uri.host,
        'path': uri.path,
      },
    );
  }

  Future<void> logBookingCreated({
    required String bookingId,
    required String eventType,
    required int itemCount,
    required double totalAmount,
  }) async {
    await logEvent(
      'booking_created',
      parameters: {
        'booking_id': bookingId,
        'event_type': eventType,
        'item_count': itemCount,
        'total_amount': totalAmount,
      },
    );
  }

  Future<void> logDepositPaid({
    required String bookingId,
    required double amount,
    required String currency,
  }) async {
    await logEvent(
      'deposit_paid',
      parameters: {
        'booking_id': bookingId,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  Future<void> logSearch(String query, int resultCount) async {
    await logEvent(
      'service_search',
      parameters: {
        'query_length': query.length,
        'results': resultCount,
      },
    );
  }

  Future<void> logBookmarkToggled(String serviceId, bool saved) async {
    await logEvent(
      'bookmark_toggled',
      parameters: {
        'service_id': serviceId,
        'saved': saved ? 1 : 0,
      },
    );
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    final analytics = _analytics;
    if (analytics == null) {
      return;
    }

    final payload = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) {
        return;
      }

      if (value is String || value is num || value is bool) {
        payload[key] = value;
        return;
      }

      payload[key] = value.toString();
    });

    await analytics.logEvent(name: name, parameters: payload);
  }
}
