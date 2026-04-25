import 'package:flutter/material.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/models/booking_models.dart';

class NotificationPresentation {
  final String title;
  final String? body;

  const NotificationPresentation({
    required this.title,
    this.body,
  });
}

extension NotificationLocalizationX on NotificationModel {
  NotificationPresentation presentation(BuildContext context) {
    return NotificationPresentation(
      title: _localizedTitle(context),
      body: _localizedBody(context),
    );
  }

  IconData get iconData {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      case 'reminder':
        return Icons.notifications_active;
      case 'review_request':
        return Icons.rate_review;
      case 'provider_message':
        return Icons.message;
      case 'price_drop':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'booking_confirmed':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      case 'payment_received':
        return Colors.blue;
      case 'reminder':
        return Colors.orange;
      case 'review_request':
        return Colors.purple;
      case 'provider_message':
        return const Color(0xFF7B61FF);
      case 'price_drop':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _localizedTitle(BuildContext context) {
    if (_isNewBookingRequest) {
      return context.tr('notification_title_new_booking_request');
    }

    if (_isBookingRequestSent) {
      return context.tr('booking_request_sent_title');
    }

    if (_isDepositReceived) {
      return context.tr('notification_title_deposit_received');
    }

    switch (type) {
      case 'booking_confirmed':
        return context.tr('notification_title_booking_confirmed');
      case 'booking_cancelled':
        return context.tr('notification_title_booking_cancelled');
      case 'payment_received':
        return context.tr('payment_received');
      default:
        final trimmed = title.trim();
        if (trimmed.isEmpty) {
          return context.tr('notifications');
        }
        return context.maybeTr(trimmed);
    }
  }

  String? _localizedBody(BuildContext context) {
    if (_isNewBookingRequest) {
      return context.tr(
        'notification_body_new_booking_request',
        params: {
          'subject': _resolvedSubject(context, fallbackKey: 'service'),
        },
      );
    }

    if (_isBookingRequestSent) {
      return context.tr(
        'notification_body_booking_request_sent',
        params: {
          'subject': _resolvedSubject(context, fallbackKey: 'event'),
        },
      );
    }

    if (_isDepositReceived) {
      return context.tr(
        _audience == 'provider'
            ? 'notification_body_deposit_received_provider'
            : 'notification_body_deposit_received_consumer',
      );
    }

    switch (type) {
      case 'booking_confirmed':
        return context.tr(
          _normalizedBody.contains('confirmed by the provider')
              ? 'notification_body_service_confirmed'
              : 'notification_body_booking_confirmed',
          params: {
            'subject':
                _resolvedSubject(context, fallbackKey: 'booking_details'),
          },
        );
      case 'booking_cancelled':
        final key = switch (_bookingCancellationVariant) {
          _NotificationCancellationVariant.provider =>
            'notification_body_provider_cancelled',
          _NotificationCancellationVariant.declined =>
            'notification_body_service_declined',
          _NotificationCancellationVariant.consumer =>
            'notification_body_booking_cancelled',
        };
        return context.tr(
          key,
          params: {
            'subject':
                _resolvedSubject(context, fallbackKey: 'booking_details'),
          },
        );
      default:
        final trimmed = body?.trim();
        if (trimmed == null || trimmed.isEmpty) {
          return null;
        }
        return context.maybeTr(trimmed);
    }
  }

  String _resolvedSubject(
    BuildContext context, {
    required String fallbackKey,
  }) {
    return _subjectFromData ??
        _subjectFromText(body) ??
        _subjectFromText(title) ??
        context.tr(fallbackKey);
  }

  String? get _subjectFromData {
    for (final key in const [
      'serviceTitle',
      'eventName',
      'serviceName',
      'subject',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _subjectFromText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final patterns = <RegExp>[
      RegExp(r'for (.+?) has been submitted\.?$', caseSensitive: false),
      RegExp(r'submitted for (.+?)\.?$', caseSensitive: false),
      RegExp(r'^(.+?) was confirmed by the provider\.?$', caseSensitive: false),
      RegExp(r'^(.+?) has been confirmed\.?$', caseSensitive: false),
      RegExp(r'^(.+?) was cancelled successfully\.?$', caseSensitive: false),
      RegExp(r'^a customer cancelled (.+?)\.?$', caseSensitive: false),
      RegExp(r'^(.+?) was declined by the provider\.?$', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value.replaceAll(RegExp(r'[`"\.]$'), '').trim();
      }
    }

    return null;
  }

  String get _normalizedTitle => title.trim().toLowerCase();
  String get _normalizedBody => body?.trim().toLowerCase() ?? '';

  bool get _isNewBookingRequest =>
      type == 'provider_message' || _normalizedTitle == 'new booking request';

  bool get _isBookingRequestSent =>
      _normalizedTitle == 'booking request sent' ||
      _normalizedBody.startsWith('your booking request for ') &&
          _normalizedBody.contains(' has been submitted');

  bool get _isDepositReceived =>
      _normalizedTitle == 'deposit received' ||
      _normalizedTitle == 'payment received' ||
      _normalizedBody == 'your deposit payment was received successfully.' ||
      _normalizedBody ==
          'a customer deposit was received for an upcoming booking.';

  String? get _audience => data['audience']?.toString().toLowerCase();

  _NotificationCancellationVariant get _bookingCancellationVariant {
    if (_normalizedBody.startsWith('a customer cancelled ')) {
      return _NotificationCancellationVariant.provider;
    }
    if (_normalizedBody.contains('declined by the provider')) {
      return _NotificationCancellationVariant.declined;
    }
    return _NotificationCancellationVariant.consumer;
  }
}

enum _NotificationCancellationVariant {
  consumer,
  provider,
  declined,
}
