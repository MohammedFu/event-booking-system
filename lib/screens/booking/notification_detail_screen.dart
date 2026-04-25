import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/notification_localizations.dart';
import 'package:munasabati/models/booking_models.dart';
import 'package:munasabati/route/route_constants.dart';
import 'package:munasabati/services/api_service_real.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final ApiServiceReal _api = ApiServiceReal();
  bool _isOpeningBooking = false;
  bool _isOpeningService = false;

  NotificationModel get _notification => widget.notification;

  String? get _bookingId => _notification.data['bookingId']?.toString();
  String? get _serviceId => _notification.data['serviceId']?.toString();

  Future<void> _openBooking() async {
    final bookingId = _bookingId;
    if (bookingId == null || bookingId.isEmpty || _isOpeningBooking) {
      return;
    }

    setState(() => _isOpeningBooking = true);
    try {
      final response = await _api.getBookingById(bookingId);
      if (!mounted) return;

      if (!response.success || response.data == null) {
        _showOpenError(response.error);
        return;
      }

      Navigator.pushNamed(
        context,
        bookingDetailScreenRoute,
        arguments: response.data,
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningBooking = false);
      }
    }
  }

  Future<void> _openService() async {
    final serviceId = _serviceId;
    if (serviceId == null || serviceId.isEmpty || _isOpeningService) {
      return;
    }

    setState(() => _isOpeningService = true);
    try {
      final response = await _api.getServiceById(serviceId);
      if (!mounted) return;

      if (!response.success || response.data == null) {
        _showOpenError(response.error);
        return;
      }

      Navigator.pushNamed(
        context,
        serviceDetailScreenRoute,
        arguments: response.data,
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningService = false);
      }
    }
  }

  void _showOpenError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? context.tr('notification_target_open_error'),
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime dateTime) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatFullDate(dateTime);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: true,
    );
    return '$date - $time';
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _notification.presentation(context);
    final body = presentation.body?.trim();
    final iconColor = _notification.iconColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notification_details')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          Container(
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(defaultBorderRadious),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: iconColor.withOpacity(0.12),
                    child: Icon(
                      _notification.iconData,
                      color: iconColor,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  presentation.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('notification_received_on'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(context, _notification.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('notification_message'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  body == null || body.isEmpty
                      ? context.tr('notification_details_empty_message')
                      : body,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
          if ((_bookingId?.isNotEmpty ?? false) ||
              (_serviceId?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 20),
            if (_bookingId?.isNotEmpty ?? false)
              ElevatedButton(
                onPressed: _isOpeningBooking ? null : _openBooking,
                child: _isOpeningBooking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('open_booking')),
              ),
            if ((_bookingId?.isNotEmpty ?? false) &&
                (_serviceId?.isNotEmpty ?? false))
              const SizedBox(height: 12),
            if (_serviceId?.isNotEmpty ?? false)
              OutlinedButton(
                onPressed: _isOpeningService ? null : _openService,
                child: _isOpeningService
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('open_service')),
              ),
          ],
        ],
      ),
    );
  }
}
