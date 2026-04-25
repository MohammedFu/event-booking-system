import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_cache_service.dart';
import 'package:munasabati/services/firebase_bootstrap_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.handleBackgroundRemoteMessage(message);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final ApiServiceReal _api = ApiServiceReal();
  final BookingCacheService _cache = BookingCacheService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  AuthProvider? _authProvider;
  String? _deviceToken;
  String? _syncedUserId;
  String? _syncedDeviceToken;
  bool _isInitialized = false;
  bool _isSyncingToken = false;

  void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<bool> ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    final options = FirebaseBootstrapOptions.currentPlatform;
    if (options == null && kIsWeb) {
      debugPrint(
        'FCM skipped: Firebase options are not configured for this build.',
      );
      return false;
    }

    try {
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } on FirebaseException catch (error) {
      final code = error.code.isEmpty ? 'unknown' : error.code;
      final message = error.message == null ? '' : ' ${error.message}';
      debugPrint(
        'FCM skipped: Firebase initialization failed ($code).$message',
      );
      return false;
    } catch (error) {
      debugPrint('FCM skipped: Firebase initialization failed. $error');
      return false;
    }
  }

  Future<void> initialize() async {
    registerBackgroundHandler();

    final isReady = await ensureFirebaseInitialized();
    if (!isReady || _isInitialized) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _deviceToken = await _messaging.getToken();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _deviceToken = token;
      unawaited(_syncTokenWithBackend());
    });

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_cacheIncomingMessage(message));
    });

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_cacheIncomingMessage(message));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _cacheIncomingMessage(initialMessage);
    }

    _isInitialized = true;
    await _syncTokenWithBackend();
  }

  void bindAuthProvider(AuthProvider authProvider) {
    if (identical(_authProvider, authProvider)) {
      return;
    }

    _authProvider?.removeListener(_handleAuthChange);
    _authProvider = authProvider;
    _authProvider?.addListener(_handleAuthChange);
    unawaited(_syncTokenWithBackend());
  }

  Future<void> refreshToken() async {
    if (!_isInitialized) {
      return;
    }

    _deviceToken = await _messaging.getToken();
    await _syncTokenWithBackend();
  }

  static Future<void> handleBackgroundRemoteMessage(
    RemoteMessage message,
  ) async {
    final isReady = await ensureFirebaseInitialized();
    if (!isReady) {
      return;
    }

    await instance._cacheIncomingMessage(message);
  }

  void _handleAuthChange() {
    if (!(_authProvider?.isAuthenticated ?? false)) {
      _syncedUserId = null;
      _syncedDeviceToken = null;
    }
    unawaited(_syncTokenWithBackend());
  }

  Future<void> _syncTokenWithBackend() async {
    if (!_isInitialized) {
      return;
    }

    final auth = _authProvider;
    final user = auth?.user;
    if (auth == null || user == null || !auth.isAuthenticated) {
      _syncedUserId = null;
      _syncedDeviceToken = null;
      return;
    }

    _deviceToken ??= await _messaging.getToken();
    final token = _deviceToken;
    if (token == null || token.isEmpty) {
      return;
    }

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'IOS',
      TargetPlatform.android => 'ANDROID',
      _ => null,
    };

    if (platform == null) {
      return;
    }

    if (_isSyncingToken ||
        (_syncedUserId == user.id && _syncedDeviceToken == token)) {
      return;
    }

    _isSyncingToken = true;
    try {
      final response = await _api.registerDeviceToken(
        token: token,
        platform: platform,
      );
      if (response.success) {
        _syncedUserId = user.id;
        _syncedDeviceToken = token;
      } else {
        debugPrint(
          'FCM token sync failed for user ${user.id}: ${response.error}',
        );
      }
    } finally {
      _isSyncingToken = false;
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_isInitialized) {
      return;
    }

    final token = _deviceToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _api.unregisterDeviceToken(token);
    _syncedUserId = null;
    _syncedDeviceToken = null;
  }

  Future<void> _cacheIncomingMessage(RemoteMessage message) async {
    final userId =
        message.data['userId']?.toString() ?? _authProvider?.user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final notification = _notificationFromMessage(message, userId);
    final existingNotifications = await _cache.getNotifications(userId) ?? [];

    final updatedNotifications = [
      notification,
      ...existingNotifications.where((item) => item.id != notification.id),
    ];

    await _cache.cacheNotifications(userId, updatedNotifications);
  }

  NotificationModel _notificationFromMessage(
    RemoteMessage message,
    String userId,
  ) {
    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    final type = message.data['type']?.toString() ?? 'system';
    final id = message.data['notificationId']?.toString() ??
        message.messageId ??
        'remote-${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.tryParse(
          message.data['createdAt']?.toString() ?? '',
        ) ??
        DateTime.now();

    return NotificationModel(
      id: id,
      userId: userId,
      type: type.toLowerCase().replaceAll('-', '_'),
      title: title,
      body: body,
      data: {
        ...message.data,
        'messageId': message.messageId,
      },
      isRead: false,
      createdAt: createdAt,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _authProvider?.removeListener(_handleAuthChange);
  }
}
