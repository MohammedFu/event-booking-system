import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/api_service_real.dart';
import 'package:munasabati/services/app_analytics_service.dart';
import 'package:munasabati/services/app_navigation.dart';
import 'package:munasabati/services/auth_provider.dart';
import 'package:munasabati/services/booking_provider.dart';
import 'package:share_plus/share_plus.dart';

class AppLinksService {
  AppLinksService._();

  static final AppLinksService instance = AppLinksService._();

  final AppLinks _appLinks = AppLinks();
  final ApiServiceReal _api = ApiServiceReal();

  StreamSubscription<Uri>? _linkSubscription;
  AuthProvider? _authProvider;
  BookingProvider? _bookingProvider;
  Uri? _pendingUri;
  bool _isInitialized = false;

  Uri buildServiceUri(String serviceId) {
    return Uri(scheme: 'munasabati', host: 'service', path: '/$serviceId');
  }

  Uri buildBookingUri(String bookingId) {
    return Uri(scheme: 'munasabati', host: 'booking', path: '/$bookingId');
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_queueOrHandle(uri));
    });

    _isInitialized = true;
  }

  void bindProviders({
    required AuthProvider authProvider,
    required BookingProvider bookingProvider,
  }) {
    _authProvider = authProvider;
    _bookingProvider = bookingProvider;
  }

  Future<void> processPendingLink() async {
    final uri = _pendingUri;
    if (uri == null) {
      return;
    }

    _pendingUri = null;
    await _handleUri(uri);
  }

  Future<void> shareService({
    required BuildContext context,
    required String serviceId,
    required String title,
  }) async {
    final uri = buildServiceUri(serviceId);
    final renderBox = context.findRenderObject() as RenderBox?;

    await SharePlus.instance.share(
      ShareParams(
        text: 'Check out $title on Munasabati: $uri',
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      ),
    );

    await AppAnalyticsService.instance.logServiceShared(serviceId);
  }

  Future<void> shareBooking({
    required BuildContext context,
    required String bookingId,
  }) async {
    final uri = buildBookingUri(bookingId);
    final renderBox = context.findRenderObject() as RenderBox?;

    await SharePlus.instance.share(
      ShareParams(
        text: 'Open booking details in Munasabati: $uri',
        sharePositionOrigin: renderBox == null
            ? null
            : renderBox.localToGlobal(Offset.zero) & renderBox.size,
      ),
    );
  }

  Future<void> _queueOrHandle(Uri uri) async {
    if (appNavigatorKey.currentState == null) {
      _pendingUri = uri;
      return;
    }

    await _handleUri(uri);
  }

  Future<void> _handleUri(Uri uri) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _pendingUri = uri;
      return;
    }

    await AppAnalyticsService.instance.logDeepLinkOpened(uri);

    final host = uri.host.toLowerCase();
    final pathSegments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final isHostedLink = host == 'munasabati.app' || host == 'www.munasabati.app';
    final target = isHostedLink
        ? (pathSegments.isEmpty ? null : pathSegments.first.toLowerCase())
        : host;
    final targetId = isHostedLink
        ? (pathSegments.length > 1 ? pathSegments[1] : null)
        : (pathSegments.isEmpty ? null : pathSegments.first);

    if (target == 'service') {
      final serviceId = targetId;
      if (serviceId == null) {
        return;
      }

      final response = await _api.getServiceById(serviceId);
      if (!response.success || response.data == null) {
        return;
      }

      _bookingProvider?.clearError();
      navigator.pushNamed(
        serviceDetailScreenRoute,
        arguments: response.data,
      );
      return;
    }

    if (target == 'booking') {
      final bookingId = targetId;
      if (bookingId == null) {
        return;
      }

      final auth = _authProvider;
      if (auth == null || !auth.isAuthenticated) {
        navigator.pushNamed(authScreenRoute);
        return;
      }

      final response = await _api.getBookingById(bookingId);
      if (!response.success || response.data == null) {
        return;
      }

      _bookingProvider?.clearError();
      navigator.pushNamed(
        bookingDetailScreenRoute,
        arguments: response.data,
      );
      return;
    }

    if (target == 'notifications') {
      navigator.pushNamed(bookingNotificationsScreenRoute);
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
  }
}
