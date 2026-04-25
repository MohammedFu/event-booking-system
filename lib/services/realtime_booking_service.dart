import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_cache_service.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:munasabati/services/dio_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class RealtimeBookingService {
  RealtimeBookingService._();

  static final RealtimeBookingService instance = RealtimeBookingService._();

  final BookingCacheService _cache = BookingCacheService();

  AuthProvider? _authProvider;
  BookingProvider? _bookingProvider;
  io.Socket? _socket;
  String? _connectedToken;
  bool _isRefreshingState = false;

  void bindProviders({
    required AuthProvider authProvider,
    required BookingProvider bookingProvider,
  }) {
    if (!identical(_authProvider, authProvider)) {
      _authProvider?.removeListener(_handleAuthChanged);
      _authProvider = authProvider;
      _authProvider?.addListener(_handleAuthChanged);
    }

    _bookingProvider = bookingProvider;
    unawaited(_syncConnection());
  }

  void _handleAuthChanged() {
    unawaited(_syncConnection());
  }

  Future<void> _syncConnection() async {
    final auth = _authProvider;
    final token = auth?.tokens?.accessToken;

    if (auth == null || !auth.isAuthenticated || token == null || token.isEmpty) {
      _disconnect();
      return;
    }

    if (_socket?.connected == true && _connectedToken == token) {
      return;
    }

    _disconnect();
    _connectedToken = token;

    final socket = io.io(
      DioClient.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableMultiplex()
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('Realtime connected');
    });
    socket.onConnectError((error) {
      debugPrint('Realtime connect error: $error');
    });
    socket.onError((error) {
      debugPrint('Realtime error: $error');
    });
    socket.onDisconnect((_) {
      debugPrint('Realtime disconnected');
    });

    socket.on('notification:new', (payload) {
      unawaited(_cacheNotification(payload));
    });

    for (final event in const [
      'booking:created',
      'booking:confirmed',
      'booking:cancelled',
      'payment:received',
    ]) {
      socket.on(event, (payload) {
        unawaited(_cacheNotification(payload));
        unawaited(_refreshRelevantState());
      });
    }

    _socket = socket;
    socket.connect();
  }

  Future<void> _cacheNotification(dynamic payload) async {
    final data = _payloadToMap(payload);
    if (data == null) {
      return;
    }

    final userId =
        data['userId']?.toString() ?? _authProvider?.user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final notification = NotificationModel(
      id: data['id']?.toString() ??
          data['notificationId']?.toString() ??
          'socket-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: (data['type']?.toString() ?? 'system')
          .toLowerCase()
          .replaceAll('-', '_'),
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString(),
      data: data,
      isRead: data['isRead'] == true,
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );

    final existing = await _cache.getNotifications(userId) ?? [];
    final updated = [
      notification,
      ...existing.where((item) => item.id != notification.id),
    ];
    await _cache.cacheNotifications(userId, updated);
  }

  Future<void> _refreshRelevantState() async {
    if (_isRefreshingState) {
      return;
    }

    final auth = _authProvider;
    final bookingProvider = _bookingProvider;
    if (auth == null || bookingProvider == null || !auth.isAuthenticated) {
      return;
    }

    _isRefreshingState = true;
    try {
      if (auth.user?.role == UserRole.provider) {
        await Future.wait([
          bookingProvider.fetchProviderDashboardData(),
          bookingProvider.fetchProviderBookings(),
        ]);
      } else {
        await bookingProvider.fetchBookings();
      }
    } finally {
      _isRefreshingState = false;
    }
  }

  Map<String, dynamic>? _payloadToMap(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  void _disconnect() {
    _connectedToken = null;
    _socket?.dispose();
    _socket = null;
  }

  Future<void> dispose() async {
    _authProvider?.removeListener(_handleAuthChanged);
    _disconnect();
  }
}
