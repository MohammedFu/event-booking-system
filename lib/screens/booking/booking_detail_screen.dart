import 'package:flutter/material.dart';
import 'package:munasabati/constants.dart';
import 'package:munasabati/l10n/app_localizations.dart';
import 'package:munasabati/l10n/model_localizations.dart';
import 'package:munasabati/models/booking_models.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(booking.eventName ?? context.tr('booking_details')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 24),
            _buildEventInfo(context),
            const SizedBox(height: 24),
            Text(
              context.tr('booked_services'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...booking.items.map((item) => _buildServiceItem(context, item)),
            const SizedBox(height: 24),
            _buildPaymentSummary(context),
            const SizedBox(height: 24),
            if (booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(context.tr('cancel_booking')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: booking.statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: booking.statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: booking.statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.status.label(context),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: booking.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  booking.status.message(context),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(context, Icons.calendar_today, context.tr('event_date'),
              '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}'),
          const Divider(height: 20),
          _infoRow(
            context,
            Icons.category,
            context.l10n.eventType,
            localizedEventType(context, booking.eventType),
          ),
          if (booking.eventName != null) ...[
            const Divider(height: 20),
            _infoRow(context, Icons.label, context.l10n.eventName,
                booking.eventName!),
          ],
          if (booking.specialRequests != null &&
              booking.specialRequests!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              context,
              Icons.note,
              context.l10n.specialRequests,
              booking.specialRequests!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, BookingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getServiceIcon(item.service?.serviceType),
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.service?.title ?? context.tr('service'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.date.day}/${item.date.month}/${item.date.year}  '
                  '${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')} - '
                  '${item.endTime.hour.toString().padLeft(2, '0')}:${item.endTime.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (item.provider != null)
                  Text(
                    item.provider!.businessName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.color
                              ?.withOpacity(0.6),
                        ),
                  ),
              ],
            ),
          ),
          Text(
            '\$${item.subtotal.toInt()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final deposit = booking.depositAmount;
    final remaining = booking.totalAmount - deposit;

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payment_summary'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('total_amount'),
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(formatPrice(booking.totalAmount),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('deposit_paid'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2ED573),
                      )),
              Text('\$${deposit.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2ED573),
                      )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('remaining'),
                  style: Theme.of(context).textTheme.bodySmall),
              Text('\$${remaining.toInt()}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('deposit_status'),
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                booking.depositPaid
                    ? context.tr('status_paid')
                    : context.tr('status_pending'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: booking.depositPaid
                          ? const Color(0xFF2ED573)
                          : const Color(0xFFFFBE21),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(ServiceType? type) {
    switch (type) {
      case ServiceType.hall:
        return Icons.domain;
      case ServiceType.car:
        return Icons.directions_car;
      case ServiceType.photographer:
        return Icons.camera_alt;
      case ServiceType.entertainer:
        return Icons.music_note;
      case null:
        return Icons.miscellaneous_services;
    }
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('cancel_booking')),
        content: Text(context.tr('cancel_booking_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('keep_booking')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('booking_cancellation_requested')),
                ),
              );
            },
            child: Text(context.tr('cancel_booking'),
                style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
